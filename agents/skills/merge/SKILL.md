---
name: merge
allowed-tools: Bash(git add:*), Bash(git commit:*), Bash(git checkout:*), Bash(git pull:*), Bash(git push:*), Bash(git branch:*), Bash(git fetch:*), Bash(git log:*), Bash(git diff:*), Bash(git reset:*), Bash(git rebase:*), Bash(gh pr:*), Bash(gh pr list:*), Bash(gh pr create:*), Bash(gh pr edit:*), Bash(gh pr merge:*), Bash(git -C:*)
description: Merge current branch to master via GitHub PR merge
---

## Context

- Current branch: !`git branch --show-current`
- Git status: !`git status --short`
- Remotes: !`git remote -v 2>/dev/null | head -10`
- Commits (upstream): !`git log upstream/master..HEAD --oneline 2>/dev/null | head -50`
- Commits (origin): !`git log origin/master..HEAD --oneline 2>/dev/null | head -50`
- Diff stat (upstream): !`git diff upstream/master..HEAD --stat 2>/dev/null | head -50`
- Diff stat (origin): !`git diff origin/master..HEAD --stat 2>/dev/null | head -50`

## Your task

Merge the current branch into master via GitHub PR merge. This preserves PR association so the commit on master links back to the PR.

**Important:** An existing open PR is NOT required. If no PR exists, one will be created. If there are uncommitted changes, they will be committed first. The only requirement is that the branch has something to merge (commits diverging from master).

0. **Determine the target remote (CRITICAL — use this for all subsequent steps):**
   - Check which remotes exist using `git remote`
   - If an `upstream` remote exists, set **TARGET=upstream**
   - Otherwise, set **TARGET=origin**
   - All references to `{TARGET}` below must use the determined remote

1. **Commit any uncommitted changes:**
   - If there are uncommitted changes, stage and commit them with an appropriate message

2. **Store the current branch name:**
   - Save the current branch name for the merge

3. **Analyze all commits and changes:**
   - Review ALL commits on the branch since it diverged from `{TARGET}/master`
   - If there are no prior commits (only the changes just committed in step 1), base the summary on that commit
   - Review the full diff to understand what the branch accomplishes
   - Determine a clear, concise summary for the squashed commit based on the overall purpose

4. **Rebase on {TARGET}/master:**
   - Run `git fetch {TARGET}`
   - Run `git rebase {TARGET}/master`
   - If there are conflicts, resolve them and continue the rebase

5. **Force-push the rebased branch to {TARGET}:**
   - Run `git push {TARGET} <branch-name> --force-with-lease`

6. **Ensure a PR exists with a good title and description:**
   - Craft a PR title and body based on your analysis from step 3:
     - **Title**: concise imperative summary of what the branch accomplishes (not individual commits)
     - **Body**: a short description of the changes, followed by `Co-Authored-By: Claude <noreply@anthropic.com>`
   - Check if a PR already exists:
     ```
     gh pr list --head <branch> --state open --json number,url
     ```
   - If a PR exists, update it:
     ```
     gh pr edit <number> --title "..." --body "..."
     ```
   - If no PR exists, create one:
     ```
     gh pr create --base master --head <branch> --title "..." --body "..."
     ```

7. **Squash merge via GitHub:**
   - Use the same title and body from step 6 as the squash commit message
   - Squash merge the PR:
     ```
     gh pr merge <number> --squash --subject "..." --body "..."
     ```
   - If squash merge fails (e.g. branch protection), try with `--auto` flag to enable auto-merge when checks pass
   - If that also fails, fall back to rebase merge: `gh pr merge <number> --rebase`
   - This merges through GitHub so the PR shows as "Merged" and the commit links to the PR

8. **Update local master:**
   - Run `git checkout master`
   - Run `git pull {TARGET} master`

9. **Report the result:**
   - Confirm the merge was successful
   - Show the PR URL (so the user can verify the "Merged" status)
   - Show the final commit on master

10. **Sync ~/.dots checkout (dots repo only):**
    - Skip this step unless `$CONDUCTOR_ROOT_PATH` equals `/Users/darrencheng/.dots`
    - If it matches, automatically run:
      ```
      git -C /Users/darrencheng/.dots fetch origin
      git -C /Users/darrencheng/.dots reset --hard origin/master
      ```
    - Report the updated commit in `~/.dots`

Execute all steps in sequence. If any step fails, stop and report the error.
