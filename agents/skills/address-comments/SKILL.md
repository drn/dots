---
name: address-comments
description: Walk every unresolved review thread on a PR, triage each one, reply with a rationale of whether or not the comment will be acted upon, make the code change if warranted, and mark the thread resolved. Use when the user asks to address PR comments, respond to review feedback, resolve review threads, or clear bot comments on a PR.
---

## Arguments

- `$ARGUMENTS` — Optional. PR number, PR URL, or branch name. Defaults to the PR for the current branch.

## Context

- Current branch: !`git branch --show-current`
- Git status: !`git status --short`
- Base ref: !`git branch -r 2>/dev/null | grep -oE 'origin/(main|master)' | head -1`
- Default remote: !`git remote 2>/dev/null | head -5`

## Your task

Walk every **unresolved review thread** on the target PR. For each thread: read the comment in context, decide whether to act on it, make the code change if warranted, post a reply explaining the rationale, then resolve the thread. End with a clean PR (zero unresolved threads) and a one-paragraph summary of what was done.

This skill does not push the branch into CI babysitting or merge it — use `/pr` or `/merge` for that. The focused job here is _comment hygiene_.

### Step 1: Identify the PR

Determine the target PR:

- If `$ARGUMENTS` looks like a number (e.g. `123`) → that PR number on the upstream repo.
- If `$ARGUMENTS` looks like a URL (`https://github.com/<owner>/<repo>/pull/<n>`) → parse owner/repo/number from the URL.
- If `$ARGUMENTS` is a branch name → look up the PR for that branch.
- Otherwise → use the current branch.

Pick the upstream repo slug: prefer the `upstream` remote if it exists, otherwise `origin`.

```bash
REPO_SLUG=$(git remote get-url upstream 2>/dev/null | sed -E 's|.*[:/]([^/]+/[^/.]+)(\.git)?$|\1|')
[ -z "$REPO_SLUG" ] && REPO_SLUG=$(git remote get-url origin | sed -E 's|.*[:/]([^/]+/[^/.]+)(\.git)?$|\1|')
```

Find the PR number with `gh pr list --repo <slug> --head '<branch>' --state open --json number,url` (or `--head '<fork-owner>:<branch>'` when the branch lives on a fork).

If no open PR is found, stop and tell the user: `No open PR found for <branch>. Open one with /pr first.` Do not try to open one — that is `/pr`'s job.

### Step 2: Fetch every unresolved review thread

Use the GraphQL API to get all threads in one shot — REST does not expose `isResolved`:

```bash
gh api graphql -F owner=<owner> -F repo=<repo> -F number=<n> -f query='
  query($owner: String!, $repo: String!, $number: Int!) {
    repository(owner: $owner, name: $repo) {
      pullRequest(number: $number) {
        reviewThreads(first: 100) {
          nodes {
            id
            isResolved
            isOutdated
            path
            line
            comments(first: 20) {
              nodes {
                databaseId
                body
                author { login }
                path
                line
                originalLine
                diffHunk
              }
            }
          }
        }
      }
    }
  }'
```

Filter to threads where `isResolved == false`. If there are zero, stop and report: `No unresolved review threads on PR #<n>.`

### Step 3: Triage and act on each thread

For each unresolved thread, work through it in this order. Do not parallelize — review threads can suggest conflicting edits to the same lines, and you need to apply them sequentially with the latest file state in mind.

**(a) Read the code in context.** Open `path` and read the function or block that contains `line` — not just the diff hunk. Bot comments often miss surrounding context that changes the verdict.

**(b) Identify the author.** Bot usernames typically end in `[bot]` (e.g. `coderabbitai[bot]`, `qltysh[bot]`, `github-actions[bot]`, `copilot-pull-request-review[bot]`). Bots produce a high false-positive rate — evaluate each suggestion on its merits, do not blindly apply.

**(c) Classify.** Pick exactly one bucket:

- **(1) Valid fix** — Real bug, missing nil/error handling, correctness issue, security concern, or a clearly better readability/perf change consistent with the surrounding code.
- **(2) Intentional design** — The current code is deliberate. The suggestion conflicts with the existing pattern, a documented convention, or a decision visible elsewhere in the diff/file. No change.
- **(3) Informational** — Complexity metrics, "similar code" reports, stylistic preferences, questions, or speculative suggestions. No change.

Heuristics for bots:
- Linter complexity warnings (qlty, CodeClimate) are almost always **(3)** — the complexity is inherent to a dispatch/parser/state-machine. Don't extract sub-functions purely to lower a score.
- "Similar code detected" is **(3)** when the duplicates implement a shared interface or template pattern.
- "Possible nil dereference" inside code paths guarded by an earlier check is **(3)** — note the guard in the reply.
- CodeRabbit "consider extracting", "consider using", "consider naming" are usually **(2)** or **(3)** unless the suggestion genuinely improves correctness.
- Anything flagging a missing test, missing error path, or pointing at a real off-by-one is usually **(1)**.

**(d) If (1), make the code change.** Edit the file. Keep the change minimal — fix the specific issue, don't refactor surrounding code. If multiple threads point at the same code, batch the related edits before replying so the reply can reference the final state.

**(e) Reply with rationale.** Post the reply _before_ resolving so there is always an audit trail. The reply must state the verdict and the reasoning in one or two sentences. Do not write "Thanks for the feedback" or other filler.

Reply templates (pick verbatim, then fill in specifics):

- **(1):** `Fixed — <one line describing the change>. <path>:<line>.`
- **(2):** `Leaving as-is — <one-sentence reason rooted in the existing pattern or constraint>.`
- **(3):** `Acknowledged — <one-sentence reason this is informational and not actionable>.`

Post the reply with the REST endpoint (no native `gh` command exists, but `gh api` works):

```bash
gh api -X POST \
  "/repos/<owner>/<repo>/pulls/<n>/comments/<first_comment_databaseId>/replies" \
  -f body="<reply text>"
```

**(f) Resolve the thread** via GraphQL mutation:

```bash
gh api graphql -F threadId=<thread node id> -f query='
  mutation($threadId: ID!) {
    resolveReviewThread(input: {threadId: $threadId}) {
      thread { isResolved }
    }
  }'
```

Track a running tally as you go: `fixed`, `left`, `acknowledged`.

### Step 4: Commit and push code changes

If any files changed during Step 3:

1. `git status --short` to confirm only the expected files were touched.
2. Stage and commit with a message scaled to the change set:
   - One thread fixed → `Address review: <short summary>`
   - Multiple threads fixed → `Address review comments` with a bullet list in the body, one bullet per fix.
3. `git push` (use `git push -u origin HEAD` if no upstream is set).

If no files changed, skip this step entirely. Do not create an empty commit.

### Step 5: Report

Print a tight summary the user can scan:

```
PR: <url>
Addressed N threads — F fixed, L left as-is, A acknowledged.
<one-line per fix referencing path:line, if F > 0>
```

If anything blocked progress (a thread you could not classify, a file you could not edit, a push that was rejected), surface it explicitly instead of silently finishing.

## Notes and edge cases

- **Top-level PR comments** (the conversation tab, not inline review threads) have no resolved state. Skip them — this skill is scoped to review threads. If a top-level comment clearly demands action, mention it in the Step 5 summary so the user can handle it.
- **Outdated threads** (`isOutdated == true`): still reply and resolve. An outdated thread is often a sign the code already changed in a later commit; the reply should say `Already addressed in <sha or "a later commit"> — <one-line on what changed>.` then resolve.
- **Threads you authored.** Skip your own threads — replying to and resolving them is noise. Detect via the first comment's author login matching the GitHub viewer (`gh api user -q .login`).
- **Permission errors on resolve.** `resolveReviewThread` requires write access to the repo. If it fails with a permissions error on a fork PR, fall back to replying-only and tell the user the threads need to be resolved manually by a maintainer.
- **Loops.** Do not re-enter Step 2 after fixing. One pass is enough — if a reviewer posts new comments after this run, re-invoke the skill.
