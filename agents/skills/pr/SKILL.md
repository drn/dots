---
name: pr
description: Open a PR, wait for CI to pass, fix failures, address review comments, and loop until fully green
---

## Context

- Current branch: !`git branch --show-current`
- Git status: !`git status --short`

## Your task

Open a PR for the current branch, then loop until CI is fully green and all review comments are addressed. Do not return until the PR is in a mergeable, green state.

**If a PR already exists for this branch, skip straight to Step 3** — even if there are no local changes or commits. Your job is to get the PR to a green, mergeable state, not just to open it. Never abort when a PR exists.

### Step 0: Check for existing PR

Determine the repository owner and name from `git remote get-url origin`. Use `mcp__github__list_pull_requests` (with `head` set to `<owner>:<branch>`, `state: "open"`) to check if a PR already exists. If one exists, note the PR number and skip to Step 3.

### Step 1: Commit any uncommitted changes

If there are uncommitted changes (check git status), stage and commit them with an appropriate message before proceeding. **Do this before anything else** — uncommitted changes are work the user wants shipped.

**Abort condition (only when NO PR exists):** After committing any uncommitted changes, if there are STILL no commits ahead of the default branch, stop and tell the user: "Nothing to ship — no PR exists and there are no commits on this branch."

### Step 2: Push the branch

Push the current branch to origin. Use `git push -u origin HEAD` if no upstream is set. If there is nothing new to push, that is fine — continue to Step 3.

### Step 3: Open a PR (or use existing one)

- If a PR already exists for this branch, use it. Print the PR URL and skip to Step 4.
- Otherwise, create a PR following Steps 3a–3d below.

#### 3a: Analyze the diff

Run `git diff origin/HEAD...HEAD` and `git log origin/HEAD..HEAD --oneline` to understand what changed. Classify the change complexity:

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

Use `mcp__github__create_pull_request`. Keep the title under 70 characters.

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

Print the PR URL.

### Step 4: Wait for CI and address feedback (loop)

Repeat the following until CI is fully green **and** there are no unresolved review comments:

#### 4a: Check CI status

- Use `mcp__github__get_pull_request_status` to see the current state of all checks.
- If checks are still running, poll `mcp__github__get_pull_request_status` with exponential backoff: wait 60s, then 120s, then 240s, capping at 300s between polls. Stop after 30 minutes total and report to the user.
- If all checks pass and there are no pending review comments, you are done — go to Step 5.
- If any checks have failed, proceed to 4b immediately — do not wait.

#### 4b: If CI fails — diagnose and fix

- Use `mcp__github__get_pull_request_status` to see which checks failed.
- For each failed check:
  - Use `mcp__github__get_job_logs` with `failed_only: true` and the workflow `run_id` to read the failure logs.
  - Analyze the failure. Read the relevant source files to understand the issue.
  - Fix the code. Make the minimal change needed to resolve the failure.
  - Stage and commit the fix with a clear message describing what was fixed and why.
- Push all fixes with `git push`.

#### 4c: Check for PR review comments

- Fetch reviews with `mcp__github__get_pull_request_reviews` and comments with `mcp__github__get_pull_request_comments`.
- For each unresolved comment thread:
  - Read and understand the feedback.
  - If the comment requests a code change, make the change, then reply confirming what you changed.
  - If the comment is a question or discussion point, reply thoughtfully.
  - If you disagree with a suggestion, reply explaining your reasoning rather than silently ignoring it.
- After addressing all comments, stage, commit, and push the changes.

#### 4d: Loop back to 4a

After pushing fixes or addressing comments, loop back to wait for CI again. Continue until CI is fully green and no unresolved comments remain.

**Important:** If you are stuck in a loop (same failure 3+ times), stop and report the situation to the user rather than retrying the same fix.

### Step 5: Report success

When CI is green and all comments are addressed:

- Print the PR URL.
- Summarize what happened: how many CI fix cycles, how many comments addressed.
- Confirm the PR is ready for merge.
