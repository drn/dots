---
allowed-tools: Bash(git add:*), Bash(git commit:*), Bash(git checkout:*), Bash(git pull:*), Bash(git merge:*), Bash(git push:*), Bash(git branch:*), Bash(git fetch:*), Bash(git log:*), Bash(git diff:*), Bash(git reset:*), Bash(git rebase:*)
description: Merge current branch to upstream/master with squashed commits
---

## Context

- Current branch: !`git branch --show-current`
- Git status: !`git status --short`
- Remote tracking: !`git remote -v 2>/dev/null | grep upstream`
- Target remote: !`git remote 2>/dev/null | grep upstream`
- Commits from upstream: !`git log upstream/master..HEAD --oneline 2>/dev/null`
- Diff from upstream: !`git diff upstream/master..HEAD --stat 2>/dev/null`

## Your task

Merge the current branch into upstream/master with squashed commits. The branch must be rebased and force-pushed first so the PR auto-closes on GitHub.

0. **Determine the target remote:**
   - If an `upstream` remote exists, use it as the target remote.
   - Otherwise, use `origin` as the target remote.
   - Use this target remote in place of `upstream` in all subsequent steps.

1. **Commit any uncommitted changes:**
   - If there are uncommitted changes, stage and commit them with an appropriate message
   - Use the commit skill or create a commit directly based on the changes

2. **Store the current branch name:**
   - Save the current branch name for the merge

3. **Analyze all commits and changes:**
   - Review ALL commits on the branch since it diverged from upstream/master
   - Review the full diff to understand what the branch accomplishes
   - Determine a clear, concise summary for the squashed commit based on the overall purpose

4. **Rebase on upstream/master:**
   - Run `git fetch upstream`
   - Run `git rebase upstream/master`
   - If there are conflicts, resolve them and continue the rebase

5. **Force-push the rebased branch to origin:**
   - Run `git push origin <branch-name> --force-with-lease`
   - This updates the PR branch so GitHub can auto-close it after the merge

6. **Checkout and update master:**
   - Run `git checkout master`
   - Run `git pull upstream master` to ensure master is up to date

7. **Squash merge the feature branch:**
   - Run `git merge --squash <branch-name>` to stage all changes as a single commit
   - Create a new commit with a well-crafted message that:
     - Summarizes the overall purpose of all changes (not individual commits)
     - Is written in imperative mood
     - Includes `Co-Authored-By: Claude <noreply@anthropic.com>` at the end

8. **Push to upstream:**
   - Run `git push upstream master` to push the merged changes

9. **Clean up the remote branch:**
   - Run `git push origin --delete <branch-name>` to delete the remote branch
   - This ensures the PR is closed on GitHub

10. **Report the result:**
    - Confirm the squash merge was successful
    - Show the final commit message
    - Show which files were changed

Execute all steps in sequence. If any step fails, stop and report the error.
