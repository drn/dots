---
allowed-tools: Bash(git add:*), Bash(git commit:*), Bash(git checkout:*), Bash(git pull:*), Bash(git merge:*), Bash(git push:*), Bash(git branch:*), Bash(git fetch:*), Bash(git log:*), Bash(git diff:*), Bash(git reset:*)
description: Merge current branch to upstream/master with squashed commits
---

## Context

- Current branch: !`git branch --show-current`
- Git status: !`git status --short`
- Remote tracking: !`git remote -v | grep upstream || echo "No upstream remote configured"`
- Commits on this branch: !`git log upstream/master..HEAD --oneline 2>/dev/null || echo "Unable to determine commits"`
- Full diff from upstream/master: !`git diff upstream/master..HEAD --stat 2>/dev/null || echo "Unable to determine diff"`

## Your task

Merge the current branch into upstream/master with squashed commits:

1. **Commit any uncommitted changes:**
   - If there are uncommitted changes, stage and commit them with an appropriate message
   - Use the commit skill or create a commit directly based on the changes

2. **Store the current branch name:**
   - Save the current branch name for the merge

3. **Analyze all commits and changes:**
   - Review ALL commits on the branch since it diverged from upstream/master
   - Review the full diff to understand what the branch accomplishes
   - Determine a clear, concise summary for the squashed commit based on the overall purpose

4. **Fetch and checkout upstream/master:**
   - Run `git fetch upstream`
   - Run `git checkout master`
   - Run `git pull upstream master` to ensure master is up to date

5. **Squash merge the feature branch:**
   - Run `git merge --squash <branch-name>` to stage all changes as a single commit
   - Create a new commit with a well-crafted message that:
     - Summarizes the overall purpose of all changes (not individual commits)
     - Is written in imperative mood
     - Includes `Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>` at the end

6. **Push to upstream:**
   - Run `git push upstream master` to push the merged changes

7. **Report the result:**
   - Confirm the squash merge was successful
   - Show the final commit message
   - Show which files were changed

Execute all steps in sequence. If any step fails, stop and report the error.
