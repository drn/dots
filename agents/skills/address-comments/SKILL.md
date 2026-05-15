---
name: address-comments
allowed-tools: Read, Edit, Bash(gh api:*), Bash(gh pr:*), Bash(git add:*), Bash(git commit:*), Bash(git push:*), Bash(git status:*), Bash(git remote:*), Bash(git branch:*), Bash(git rev-parse:*), Bash(git diff:*), Bash(git log:*)
description: Walk every unresolved review thread on a PR, triage each one, reply with a rationale of whether or not the comment will be acted upon, make the code change if warranted, and mark the thread resolved. Use when the user asks to address only the open PR comments without re-running CI, respond to review feedback, resolve review threads, or clear bot comments on a PR.
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

Determine the target PR by applying these rules in order:

- `$ARGUMENTS` is a GitHub PR URL (`https://github.com/<owner>/<repo>/pull/<n>`) → parse owner/repo/number from the URL.
- `$ARGUMENTS` matches `^[0-9]+$` (pure digits) → run `gh pr view <args> --repo <upstream-slug> --json number` to verify it is a real PR. If that succeeds, treat as a PR number. If it fails, fall through to the branch-name rule (a branch literally named `42` should still resolve correctly).
- `$ARGUMENTS` is any other non-empty string → treat as a branch name and look up the PR for that branch.
- `$ARGUMENTS` is empty → use the current branch (`git branch --show-current`).

Pick the upstream repo slug: prefer the `upstream` remote if it exists, otherwise `origin`.

```bash
REPO_SLUG=$(git remote get-url upstream 2>/dev/null | sed -E 's|.*[:/]([^/]+/[^/.]+)(\.git)?$|\1|')
[ -z "$REPO_SLUG" ] && REPO_SLUG=$(git remote get-url origin | sed -E 's|.*[:/]([^/]+/[^/.]+)(\.git)?$|\1|')
```

Find the PR number with `gh pr list --repo <slug> --head '<branch>' --state open --json number,url`.

**Cross-fork PRs.** If `gh pr list --head '<branch>'` returns zero results AND an `upstream` remote exists, the branch may live on a fork. Resolve the fork owner from the `origin` remote and retry with the qualified `--head '<fork-owner>:<branch>'`:

```bash
FORK_OWNER=$(git remote get-url origin | sed -E 's|.*[:/]([^/]+)/[^/.]+(\.git)?$|\1|')
gh pr list --repo "$REPO_SLUG" --head "$FORK_OWNER:<branch>" --state open --json number,url
```

If no open PR is found after both attempts, stop and tell the user: `No open PR found for <branch>. Open one with /pr first.` Do not try to open one — that is `/pr`'s job.

### Step 2: Fetch every unresolved review thread

Use the GraphQL API to get all threads in one shot — REST does not expose `isResolved`. Two ID fields matter here and they are easy to confuse:

- `reviewThreads.nodes[].id` is the **thread node ID** (an opaque string). Used by the `resolveReviewThread` mutation in Step 3(f).
- `reviewThreads.nodes[].comments.nodes[].databaseId` is the **comment integer ID** (REST-style). Used by the reply endpoint in Step 3(e).

Do not swap them — the URL in Step 3(e) takes the comment's `databaseId`, not the thread's `id`.

```bash
gh api graphql -F owner=<owner> -F repo=<repo> -F number=<n> -f query='
  query($owner: String!, $repo: String!, $number: Int!, $after: String) {
    repository(owner: $owner, name: $repo) {
      pullRequest(number: $number) {
        reviewThreads(first: 100, after: $after) {
          pageInfo { hasNextPage endCursor }
          nodes {
            id
            isResolved
            isOutdated
            path
            line
            comments(first: 50) {
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

**Pagination.** If `pageInfo.hasNextPage` is true, the PR has more than 100 review threads. Re-issue the same query with `-F after=<endCursor>` (the `$after` variable is already declared in the signature above) and concatenate the pages before continuing. PRs with very large bot-comment volumes (e.g. a CodeRabbit pass on a sweeping refactor) hit this case; do not silently process only the first page.

### Step 3: Triage and act on each thread

For each unresolved thread, work through it in this order. Do not parallelize — review threads can suggest conflicting edits to the same lines, and you need to apply them sequentially with the latest file state in mind.

**(a) Read the code in context.** Open `path` and read the function or block that contains `line` — not just the diff hunk. Bot comments often miss surrounding context that changes the verdict.

**(b) Identify the author and decide whether to skip.**

- Capture the viewer login once at the start of Step 3 with `gh api user -q .login` (call it `VIEWER`).
- **First, check the thread author.** If the first comment's `author.login == VIEWER`, this is a thread the agent itself authored. Skip the thread entirely — no reply, no resolve. (Caveat: on a fork PR where the maintainer and the contributor are the same GitHub user, this can over-skip; if the agent is reviewing its own PR, that risk is acceptable.)
- Bot usernames typically end in `[bot]` (e.g. `coderabbitai[bot]`, `qltysh[bot]`, `github-actions[bot]`, `copilot-pull-request-review[bot]`). Bots produce a high false-positive rate — evaluate each suggestion on its merits, do not blindly apply.

**Idempotency guard.** Only run this check **after** the thread-author check above has passed (i.e. the thread was authored by someone else). Scan the remaining `comments.nodes[]` for any comment whose `author.login == VIEWER`. If one exists, the agent already replied on a previous run and the resolve mutation was the step that failed:

- Still perform classification (c) and apply the code change (d) if the original verdict was (1). The prior run may have replied "Fixed — …" before being interrupted, so the fix may never have been committed; re-running (c)/(d) ensures the working tree matches the previously-posted reply.
- Skip the reply in (e) — the prior reply is already on the thread.
- Go straight to resolving the thread in (f).
- For tally purposes, count this thread in whichever bucket (`fixed` / `left` / `acknowledged`) matches the classification from (c).

**(c) Classify.** Pick exactly one bucket:

- **(1) Valid fix** — Real bug, missing nil/error handling, correctness issue, security concern, or a clearly better readability/perf change consistent with the surrounding code.
- **(2) Intentional design** — The current code is deliberate. The suggestion conflicts with the existing pattern, a documented convention, or a decision visible elsewhere in the diff/file. No change.
- **(3) Informational** — Complexity metrics, "similar code" reports, stylistic preferences, questions, or speculative suggestions. No change.

Heuristics for bots:
- Linter complexity warnings (qlty, CodeClimate) on dispatch tables, parsers, and state machines are almost always **(3)** — the complexity is inherent to the shape of the problem. For a small utility function flagged as complex, the warning may be real **(1)**; judge by whether the function actually has multiple responsibilities or just a long switch.
- "Similar code detected" is **(3)** when the duplicates implement a shared interface or template pattern.
- "Possible nil dereference" inside code paths guarded by an earlier check is **(3)** — note the guard in the reply.
- CodeRabbit "consider extracting", "consider using", "consider naming" are usually **(2)** or **(3)** unless the suggestion genuinely improves correctness.
- Anything flagging a missing test, missing error path, or pointing at a real off-by-one is usually **(1)**.

**(d) If (1), make the code change.** Edit the file. Keep the change minimal — fix the specific issue, do not refactor surrounding code. If multiple threads point at the same code, batch the related edits before replying so the reply can reference the final state.

**(e) Reply with rationale.** Post the reply _before_ resolving so there is always an audit trail. The reply must state the verdict and the reasoning in one or two sentences. Do not write "Thanks for the feedback" or other filler.

Reply templates (use these structures, then **fill in every `<…>` placeholder before posting**):

- **(1):** `Fixed — <one line describing the change>. <path>:<line>.`
- **(2):** `Leaving as-is — <one-sentence reason rooted in the existing pattern or constraint>.`
- **(3):** `Acknowledged — <one-sentence reason this is informational and not actionable>.`

If you cannot fill in a placeholder (e.g. the fix touched several files and you cannot name one path:line, or the rationale needs context you do not have), stop and surface the thread to the user in the Step 5 summary instead of posting raw `<…>` placeholder text. Posted replies are visible to reviewers — a literal `<one line describing the change>` reply is worse than no reply. **This applies to every reply this skill posts, including the outdated-thread template referenced in the Notes section below.**

Post the reply with the REST endpoint (no native `gh` command exists, but `gh api` works). The path uses `<n>` (pull number) and the **comment's `databaseId`** — not the thread's `id`:

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
2. Stage the specific files you edited with `git add <path1> <path2> ...` — list paths explicitly, do not use `git add -A` or `git commit -a`. The agent may have unrelated dirty state in the working tree and the policy is to ship only the comment-driven edits.
3. Commit with a message scaled to the change set:
   - One thread fixed → `Address review: <short summary>`
   - Multiple threads fixed → `Address review comments` with a bullet list in the body, one bullet per fix.
4. `git push` (use `git push -u origin HEAD` if no upstream is set).

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
- **Outdated threads** (`isOutdated == true`): still reply and resolve. An outdated thread is often a sign the code already changed in a later commit; the reply should say `Already addressed in <sha or "a later commit"> — <one-line on what changed>.` then resolve. **Fill in both `<…>` placeholders before posting** — same rule as Step 3(e). If you cannot identify the commit or describe the change, escalate to the user instead of posting raw placeholder text.
- **Permission errors on resolve.** `resolveReviewThread` requires write access to the repo. If it fails with a permissions error on a fork PR, fall back to replying-only and tell the user the threads need to be resolved manually by a maintainer. (`resolveReviewThread` on an already-resolved thread is idempotent — it returns the thread with `isResolved: true` and no error — so a retry after a partial failure in Step 3(f) is safe.)
- **Loops.** Do not re-enter Step 2 after fixing. One pass is enough — if a reviewer posts new comments after this run, re-invoke the skill.
