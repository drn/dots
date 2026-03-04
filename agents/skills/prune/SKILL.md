---
name: prune
allowed-tools: Bash(git branch:*), Bash(git log:*), Bash(git fetch:*), Bash(git for-each-ref:*), Bash(gh pr list:*)
description: Clean up merged and stale git branches, prune old local and remote branches safely
disable-model-invocation: true
---

# Branch Cleanup

Delete merged and stale local branches safely, with preview and confirmation.

## Arguments

- `$ARGUMENTS` - Optional: `--stale-days <N>` to override the 30-day stale threshold, `--remote` to also delete remote branches

## Context

- Current branch: !`git branch --show-current`
- Local branches with dates: !`git for-each-ref --sort=-committerdate --format='%(refname:short) %(committerdate:relative) %(upstream:short)' refs/heads/ 2>/dev/null | head -50`
- Remote: !`git remote 2>/dev/null | head -5`

## Instructions

### Step 0: Validate state

- Determine the current branch. This branch is PROTECTED and will never be deleted.
- Determine the default branch using `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null` (fallback to checking for origin/main, then origin/master).
- Build the protected branch list: current branch, default branch, `main`, `master`, `develop`, and any branch matching `release/*` or `staging`.

### Step 1: Fetch and sync

Run `git fetch --prune` to sync remote tracking references and remove stale remote-tracking branches.

### Step 2: Identify merged branches

List branches already merged into the default branch:

```
git branch --merged <default-branch>
```

Exclude all protected branches from this list.

### Step 3: Identify stale branches

Parse the stale threshold from `$ARGUMENTS` (default: 30 days).

For each non-merged, non-protected local branch, check the last commit date. Mark as stale if the last commit is older than the threshold.

### Step 4: Check for open PRs

For each branch identified for deletion (merged or stale), check if it has an open PR:

```
gh pr list --head <branch-name> --state open
```

If a branch has an open PR, remove it from the deletion list and flag it in the preview.

### Step 5: Preview

Show a table of what will be deleted:

```markdown
## Branch Cleanup Preview

### Merged (safe to delete)
| Branch | Last Commit | Merged Into |
|--------|------------|-------------|
| feature/foo | 2 weeks ago | main |

### Stale (no commits in <N> days)
| Branch | Last Commit | Open PR? |
|--------|------------|----------|
| old-experiment | 3 months ago | No |

### Skipped
| Branch | Reason |
|--------|--------|
| release/2.0 | Protected (release/*) |
| feature/bar | Has open PR #42 |
```

IF no branches qualify for deletion, report "All branches are current." and stop.

### Step 6: Confirm and delete

Ask the user to confirm before deleting. Accept "all", specific branch names, or "none".

For confirmed branches:
- Delete local branch: `git branch -d <name>` (use `-D` only for stale unmerged branches)
- If `--remote` flag was provided, also delete remote branch: `git push origin --delete <name>`

### Step 7: Report

Print a summary of what was deleted and what was kept.
