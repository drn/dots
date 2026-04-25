---
name: pr
description: Open a PR, wait for CI to pass, fix failures, address review comments, and loop until fully green. Use when opening a PR, fixing CI, or addressing review feedback.
---

## Context

- Current branch: !`git branch --show-current`
- Git status: !`git status --short`

## Phase Protocol

This skill participates in a phase chain. Read `~/.claude/skills/_shared/resources/phase-protocol.md` for the full protocol.

**Before creating the PR:** Check `.context/phases/` for prior artifacts. If any exist, use them to enrich the PR description:
- `plan-*.md` or `think-*.md` → use the goal/summary for PR context
- `build-*.md` → use the changes summary and deviations
- `review-*.md` → reference review findings and their resolution
- `test-*.md` → include test results and coverage metrics

**After the PR is created and green:** Write a `ship-{ts}.md` artifact to `.context/phases/` (create with `mkdir -p .context/phases`). The **Detail** section should include the PR URL, CI status, and any fixes applied. The **Handoff** section should note the PR number for `/merge`.

## Your task

Open a PR for the current branch, then loop until CI is fully green and all review comments are addressed. Do not return until the PR is in a mergeable, green state.

**If a PR already exists for this branch, skip straight to Step 3** — even if there are no local changes or commits. Your job is to get the PR to a green, mergeable state, not just to open it. Never abort when a PR exists.

### Step 0: Check for existing PR

Determine the upstream repo slug (owner/name) — use `upstream` remote if it exists, otherwise `origin`. Use `gh pr list --repo <owner/repo> --head '<fork-owner>:<branch>' --state open --json number,url` to check if a PR already exists. If one exists, note the PR number and skip to Step 3.

### Step 1: Commit any uncommitted changes

If there are uncommitted changes (check git status), stage and commit them with an appropriate message before proceeding. **Do this before anything else** — uncommitted changes are work the user wants shipped.

**Abort condition (only when NO PR exists):** After committing any uncommitted changes, if there are STILL no commits ahead of the default branch, stop and tell the user: "Nothing to ship — no PR exists and there are no commits on this branch."

### Step 2: Push the branch

#### 2a: Pre-push markdown formatting check

If the pending push touches any `.md` files, run `prettier --check` against them first. Markdown table edits (e.g., adding a row to one table) often force prettier to realign column widths in *other* tables in the same file, which trips `qlty fmt` in CI. Catching it before push avoids burning a CI cycle.

```bash
md_files=$(git diff --name-only "$base_branch"...HEAD | grep -E '\.md$' || true)
if [ -n "$md_files" ]; then
  if ! npx --yes prettier@3.3.3 --check $md_files; then
    echo ":: prettier reformatted markdown — running --write and re-staging"
    npx --yes prettier@3.3.3 --write $md_files
    git add $md_files
    git commit -m "Format markdown via prettier"
  fi
fi
```

The check is cheap (~2s for a typical PR) and catches the most common qlty fmt failure mode. Skip if no `.md` files are in the diff.

#### 2b: Push

Push the current branch to origin. Use `git push -u origin HEAD` if no upstream is set. If there is nothing new to push, that is fine — continue to Step 3.

### Step 3: Open a PR (or use existing one)

- If a PR already exists for this branch, use it. Print the PR URL on its own line as `PR: <url>` and skip to Step 4.
- Otherwise, create a PR following Steps 3a–3d below.

#### 3a: Analyze the diff

Determine the base ref (use `git branch -r` to find `origin/main` or `origin/master`) (e.g., `origin/master`). Run `git diff <base>...HEAD` and `git log <base>..HEAD --oneline` to understand what changed. Classify the change complexity:

- **Simple** (rename, typo, config change, dependency bump): skip to 3c.
- **Medium** (single-file logic change): do 3b lightly — read the changed file in full.
- **Complex** (bug fix across multiple components, deletions of non-obvious code, changes where the diff alone doesn't explain *why*): do 3b thoroughly.

#### 3b: Trace change context

For each modified file, read the full file (not just the diff hunk) to understand the surrounding code.

**For deleted or removed code:** This is the most important case — reviewers need to understand why the code shouldn't exist. For each deletion:
- Identify what the removed code was doing.
- Trace where else that method/class is called (use Grep) to find the other code path that now handles the responsibility.
- Read those files to confirm the duplication or explain why the deletion is safe.

**For bug fixes:** Trace the interaction between components that caused the bug. Read the files that call into or are called by the changed code. Identify the specific mechanism of failure (e.g., a race condition, a duplicated side effect, an incorrect assumption).

#### 3c: Gather conversation context

Scan the conversation history for context that should flow into the PR description:

- **Triggering links** — CI failure URLs, Jira tickets, Sentry errors, PagerDuty incidents that motivated the work.
- **Production impact data** — If the conversation contains query results or impact numbers, summarize them.
- **Root cause analysis** — If the conversation contains a diagnosis, capture the key insight.

#### 3d: Write the PR and create it

Use `gh pr create --repo <owner/repo> --base master --head <branch>`. Keep the title under 70 characters.

Scale the body to match complexity:

**Simple changes:** title + 1–2 bullet summary.

**Medium changes:**
```
## Summary
- [What changed and why]

## Test plan
- [How to verify]
```

**Complex changes (bug fixes, cross-file interactions, deletions):**
```
## Summary
- [What changed]

## Root cause
[Explain the interaction between components that caused the issue.
Include brief code references — e.g., "create_transaction.rb:34 already
calls CreateTransactionEvent, so the explicit call in reverse_transaction.rb
created a duplicate." Show the mechanism, not just the symptom.]

## Production impact
[Only if the conversation contains impact data — e.g., "1,208 duplicate
events in the last 30 days." Omit this section if no data is available.]

## Test plan
- [How to verify]

[Link to triggering CI failure, Jira ticket, or Sentry error if available]
```

Print the PR URL on its own line, formatted exactly as:

```
PR: <url>
```

### Step 4: Wait for CI and address feedback (loop)

Repeat the following until CI is fully green **and** there are no unresolved review comments:

#### 4a: Check CI status and unresolved threads

- Use `gh pr checks <number> --repo <owner/repo>` to see the current state of all checks.
- If checks are still running, poll `gh pr checks` with exponential backoff: wait 60s, then 120s, then 240s, capping at 300s between polls. Stop after 30 minutes total and report to the user.
- If all checks pass, proceed to 4c to check for unresolved review threads. Only go to Step 5 when CI is green **and** 4c confirms zero unresolved threads.
- If any checks have failed, proceed to 4b immediately — do not wait.

#### 4b: If CI fails — diagnose and fix

- Use `gh pr checks <number> --repo <owner/repo>` to see which checks failed.
- For each failed check:
  - Use `mcp__github__get_job_logs` with `failed_only: true` and the workflow `run_id` to read the failure logs.
  - Analyze the failure. Read the relevant source files to understand the issue.
  - Fix the code. Make the minimal change needed to resolve the failure.
  - Stage and commit the fix with a clear message describing what was fixed and why.
- Push all fixes with `git push`.

#### 4c: Check for and resolve ALL review threads

This step handles both human and automated bot comments (CodeRabbit, qlty, Copilot, GitHub Actions, etc.). Every unresolved thread blocks mergeability.

**Fetch unresolved threads** using `gh api graphql`:

```
gh api graphql -f query='
  query {
    repository(owner: "<owner>", name: "<repo>") {
      pullRequest(number: <number>) {
        reviewThreads(first: 100) {
          nodes {
            id
            isResolved
            comments(first: 10) {
              nodes {
                body
                author { login }
                path
                line
              }
            }
          }
        }
      }
    }
  }'
```

Filter to threads where `isResolved` is false. If there are zero unresolved threads, this step is done — return to 4a (which will proceed to Step 5 if CI is also green).

**For each unresolved thread, classify and respond:**

1. **Identify the author.** Check the first comment author login. Bot usernames typically end in `[bot]` (e.g., `coderabbitai[bot]`, `qltysh[bot]`, `github-actions[bot]`, `copilot-pull-request-review[bot]`).

2. **Triage the comment.** Read the comment body and the referenced code. Classify as one of:
   - **(a) Valid fix needed** — The comment identifies a real bug, missing error handling, or correctness issue. Make the code change.
   - **(b) Intentional design choice** — The comment suggests a change that conflicts with the existing pattern, project conventions, or was a deliberate decision. No code change needed.
   - **(c) Informational or stylistic** — The comment flags metrics (complexity scores, similar code), asks a question, or suggests a cosmetic change that is not worth addressing. No code change needed.

   For bot comments specifically: bot suggestions are frequently false positives or conflict with project conventions. Do not blindly apply every suggestion. Evaluate each on its merits. Complexity warnings from linter bots (qlty, CodeClimate) are almost always informational — the complexity is inherent to the function. Similar-code detection is usually informational when the code implements a shared interface pattern.

3. **Reply to the thread.** Always reply before resolving, so there is an audit trail:
   - **(a)** Reply confirming what you changed (e.g., "Fixed — added nil check at line 42").
   - **(b)** Reply explaining why no change was made (e.g., "This complexity is inherent to the dispatch logic — extracting sub-functions would hurt readability without reducing actual complexity").
   - **(c)** Reply with a brief acknowledgment (e.g., "Acknowledged — these implement the same abstract interface, so the similarity is expected").

   Use `mcp__github__create_pull_request_review_comment_reply` to reply to the thread, passing the first comment ID as `comment_id`.

4. **Resolve the thread** via GraphQL mutation:

```
gh api graphql -f query='
  mutation {
    resolveReviewThread(input: {threadId: "<thread_node_id>"}) {
      thread { isResolved }
    }
  }'
```

**After addressing all threads:** if any code changes were made, stage, commit, and push them before looping back.

#### 4d: Loop back to 4a

After pushing fixes or addressing comments, loop back to wait for CI again. Continue until CI is fully green and no unresolved comments remain.

**Important:** If you are stuck in a loop (same failure 3+ times), stop and report the situation to the user rather than retrying the same fix.

### Step 5: Report success

When CI is green and all comments are addressed:

- Print the PR URL on its own line as `PR: <url>`.
- Summarize what happened: how many CI fix cycles, how many comments addressed.
- Confirm the PR is ready for merge.
