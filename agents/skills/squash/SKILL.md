---
name: squash
allowed-tools: Bash(git *), Bash(gh pr view:*), Bash(gh pr edit:*)
description: Squash all branch commits into one and update open PRs. Use when squashing commits, cleaning up history, or condensing branch commits before merge.
disable-model-invocation: true
---

## Context

- Current branch: !`git branch --show-current`
- Git status: !`git status --short 2>/dev/null | head -20`
- Base ref: !`git branch -r 2>/dev/null | grep -oE 'origin/(main|master)' | head -1`
- Commits vs main: !`git log origin/main..HEAD --oneline 2>/dev/null | head -50`
- Commits vs master: !`git log origin/master..HEAD --oneline 2>/dev/null | head -50`
- Open PR: !`gh pr view --json number,url,title,headRefName 2>/dev/null | head -10`
- Remote tracking: !`git rev-parse --abbrev-ref @{upstream} 2>/dev/null | head -1`
- Arguments: $ARGUMENTS

## Your task

Squash all commits on the current branch (since it diverged from the default branch) into a single commit, then force-push to update any open PR.

### Step 0: Validate state

- If HEAD is detached, stop: "Cannot squash in detached HEAD state."
- If the working tree has uncommitted changes (`git status --porcelain`), stop: "Working tree is dirty. Commit or stash changes first."
- Determine the current branch. If it is the default branch (main/master), stop: "Cannot squash commits on the default branch."

### Step 1: Determine the base branch

- If `upstream` remote exists, use it. Otherwise use `origin`.
- Detect the default branch: try `git symbolic-ref refs/remotes/<remote>/HEAD`, then `<remote>/main`, then `<remote>/master`.
- If none work, stop: "Could not determine the default branch."

### Step 2: Count commits

- Run `git log <remote>/<default-branch>..HEAD --oneline` to list branch commits.
- If there are 0 commits, stop: "No commits to squash."
- If there is exactly 1 commit, stop: "Only one commit on this branch. Nothing to squash."
- Report: "Found N commits to squash."

### Step 3: Draft the squash commit message

Read the full diffs and all individual commit messages:

```
git log <remote>/<default-branch>..HEAD --format="%s%n%n%b"
git diff <remote>/<default-branch>..HEAD --stat
```

Write a single commit message that:
- Has an imperative subject line under 72 characters summarizing the overall change
- Has a body explaining what changed and why (if non-trivial)
- Preserves any Co-Authored-By trailers from the original commits
- If `$ARGUMENTS` contains specific instructions for the message, incorporate them

### Step 4: Squash

- Find the merge base: `git merge-base <remote>/<default-branch> HEAD`
- Run `git reset --soft <merge-base>` to unstage all commits while keeping changes staged.
- Create the new squashed commit with the drafted message using a HEREDOC:

```bash
git commit -m "$(cat <<'EOF'
Subject line here

Body here.

Co-Authored-By: ...
EOF
)"
```

### Step 5: Force push (conditional)

- Check if a remote tracking branch exists: `git rev-parse --abbrev-ref @{upstream} 2>/dev/null`
- Check for an open PR: `gh pr view --json number,url 2>/dev/null`
- **If there is an open PR or a remote tracking branch:**
  - Run `git push --force-with-lease` to update the remote.
  - Report which PR was updated if applicable.
- **If no remote tracking branch exists:**
  - Skip the push.
  - Report: "No remote tracking branch. Skipped push."

### Step 6: Report summary

Print a concise summary:
- How many commits were squashed into one
- The new commit subject line
- Whether the branch was pushed
- The PR URL if one was updated
