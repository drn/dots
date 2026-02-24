---
allowed-tools: Bash(git fetch:*), Bash(git rebase:*), Bash(git push:*), Bash(git log:*), Bash(git diff:*), Bash(git branch:*), Bash(git rev-parse:*), Bash(git symbolic-ref:*), Bash(git merge-base:*), mcp__github__list_pull_requests
description: Rebase current branch onto latest upstream default branch and force-push to update PR
disable-model-invocation: true
---

## Context

- Current branch: !`git branch --show-current`
- Git status: !`git status --short`
- Remotes: !`git remote -v 2>/dev/null | head -10`
- HEAD ref: !`git rev-parse --abbrev-ref HEAD 2>/dev/null | head -1`
- Open PR: !`gh pr view --json number,url,headRefName 2>/dev/null | head -10`
- Commits on branch: !`git log origin/HEAD..HEAD --oneline 2>/dev/null | head -20`
- Arguments: $ARGUMENTS

## Your task

Rebase the current branch onto the latest upstream default branch and force-push to update the remote PR branch.

### Step 0: Validate state

- If HEAD is detached (not on a named branch), stop and tell the user: "Cannot rebase in detached HEAD state."
- Determine the current branch name.

### Step 1: Determine the target remote

- Run `git remote` to list remotes.
- If `upstream` exists, use **upstream** as the target remote.
- Otherwise, use **origin**.

### Step 2: Determine the default branch

If the user passed `--onto <branch>` in the arguments, use that branch as the rebase target instead of the default branch. Otherwise:

- Run `git symbolic-ref refs/remotes/<remote>/HEAD 2>/dev/null` (where remote is from Step 1) and extract the branch name.
- If that fails, check if `<remote>/main` exists with `git rev-parse --verify <remote>/main 2>/dev/null`.
- If that fails, check if `<remote>/master` exists with `git rev-parse --verify <remote>/master 2>/dev/null`.
- If none work, stop and tell the user: "Could not determine the default branch. Use --onto <branch> to specify."

**If the current branch IS the default branch, stop and tell the user: "You are on the default branch. Rebase is not needed."**

### Step 3: Fetch

- Run `git fetch <remote> <default-branch>`.
- Report: "Fetching <remote>/<default-branch>..."

### Step 4: Check if rebase is needed

- Run `git merge-base --is-ancestor <remote>/<default-branch> HEAD` to check if already up to date.
- If the branch is already up to date (exit code 0 from the above), report "Already up to date with <remote>/<default-branch>." and skip to Step 6.

### Step 5: Rebase

- Count the commits to be rebased: `git log <remote>/<default-branch>..HEAD --oneline`
- Report: "Rebasing N commits onto <remote>/<default-branch>..."
- Run `git rebase <remote>/<default-branch>`.
- **If conflicts arise:**
  - Show the user which files have conflicts (use `git diff --name-only --diff-filter=U`).
  - Resolve each conflict. Read the conflicting files, understand both sides, and make the correct resolution.
  - After resolving each file, run `git add <file>`.
  - Run `git rebase --continue`.
  - If further conflicts arise, repeat the process.
  - Report each conflict and how it was resolved.
  - **If a conflict cannot be resolved confidently**, run `git rebase --abort`, report the issue, and stop. Do not guess at resolutions that could lose work.
- Report: "Rebased successfully."

### Step 6: Force push (conditional)

- Check if the current branch has a remote tracking branch by running `git rev-parse --abbrev-ref @{upstream} 2>/dev/null`.
- Use `mcp__github__list_pull_requests` (with `head` set to `<owner>:<branch>`, `state: "open"`) to check if there is an open PR.
- **If there is an open PR:**
  - Run `git push --force-with-lease` to update the PR branch.
  - Report: "Force pushed to origin/<branch> (open PR #N)."
- **If there is no open PR but there IS a remote tracking branch:**
  - Run `git push --force-with-lease` to update the remote branch.
  - Report: "Force pushed to origin/<branch> (no open PR)."
- **If there is no remote tracking branch:**
  - Skip the push.
  - Report: "No remote tracking branch. Skipped push."
- **If the MCP GitHub tools are not available**, skip the PR check, and only push if there is a remote tracking branch.

### Step 7: Report summary

Print a concise summary of what happened:
- How many commits were rebased (or "already up to date")
- Whether conflicts were resolved and in which files
- Whether the branch was pushed and to where
- The PR URL if one exists
