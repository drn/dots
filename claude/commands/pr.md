---
description: Open a PR, wait for CI to pass, fix failures, address review comments, and loop until fully green
---

## Context

- Current branch: !`git branch --show-current`
- Git status: !`git status --short`
- Default branch: !`gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null || echo "unknown"`
- Commits on branch: !`git log origin/master..HEAD --oneline 2>/dev/null || git log origin/main..HEAD --oneline 2>/dev/null || echo "Unable to determine commits"`
- Existing PR: !`gh pr view --json number,url,state,title 2>/dev/null || echo "No existing PR"`

## Your task

Open a PR for the current branch, then loop until CI is fully green and all review comments are addressed. Do not return until the PR is in a mergeable, green state.

**Important:** If a PR already exists for this branch, skip straight to Step 3 — even if there are no local changes. Your job is to get the PR to a green, mergeable state, not just to open it.

**Abort condition:** If there is no existing PR for this branch AND there are no commits ahead of the default branch AND there are no uncommitted changes, stop and tell the user: "Nothing to ship — no PR exists and there are no commits on this branch." Do not silently exit.

### Step 1: Commit any uncommitted changes

If there are uncommitted changes, stage and commit them with an appropriate message before proceeding.

### Step 2: Push the branch

Push the current branch to origin. Use `git push -u origin HEAD` if no upstream is set. If there is nothing new to push, that is fine — continue to Step 3.

### Step 3: Open a PR (or use existing one)

- If a PR already exists for this branch, use it. Print the PR URL and skip to Step 4.
- Otherwise, create a PR with `gh pr create`.
  - Analyze all commits on the branch to write a clear title and description.
  - Keep the title under 70 characters.
  - Include a summary section and test plan in the body.
- Print the PR URL.

### Step 4: Wait for CI and address feedback (loop)

Repeat the following until CI is fully green **and** there are no unresolved review comments:

#### 4a: Check CI status

- Run `gh pr checks <pr-number>` to see the current state of all checks.
- If checks are still running, run `timeout 1800 gh pr checks <pr-number> --watch --fail-fast` to wait (30 minute timeout). If the timeout is hit, report to the user and stop.
- If all checks pass and there are no pending review comments, you are done — go to Step 5.
- If any checks have failed, proceed to 4b immediately — do not wait.

#### 4b: If CI fails — diagnose and fix

- Run `gh pr checks <pr-number>` to see which checks failed.
- For each failed check:
  - Get the failed run ID and use `gh run view <run-id> --log-failed` to read the failure logs.
  - Analyze the failure. Read the relevant source files to understand the issue.
  - Fix the code. Make the minimal change needed to resolve the failure.
  - Stage and commit the fix with a clear message describing what was fixed and why.
- Push all fixes with `git push`.

#### 4c: Check for PR review comments

- Fetch review comments: `gh api repos/{owner}/{repo}/pulls/<pr-number>/reviews` and `gh api repos/{owner}/{repo}/pulls/<pr-number>/comments`.
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
