---
name: standup
allowed-tools: Bash(git log:*), Bash(git branch:*), Bash(git status:*), Bash(gh pr list:*), Bash(gh pr view:*)
description: Generate a daily standup summary from recent git activity, commits, open PRs, and current work in progress
---

# Daily Standup

Generate a quick summary of recent work for standups or status updates.

## Arguments

- `$ARGUMENTS` - Optional: `--team` to include all authors, or a custom time range (e.g., "3 days")

## Context

- Current branch: !`git branch --show-current`
- Git user email: !`git config user.email 2>/dev/null | head -1`
- Git user name: !`git config user.name 2>/dev/null | head -1`
- Commits since yesterday: !`git log --all --oneline --since="yesterday" 2>/dev/null | head -30`
- Open PRs: !`gh pr list --author @me --state open 2>/dev/null | head -20`
- Uncommitted changes: !`git status --short 2>/dev/null | head -10`
- Recent branches: !`git for-each-ref --sort=-committerdate --format='%(refname:short) %(committerdate:relative)' refs/heads/ 2>/dev/null | head -10`

## Instructions

### Step 1: Determine scope

- If `--team` is in `$ARGUMENTS`, include all authors. Otherwise filter to the current user (match against the git user email and name from context).
- If a custom time range is provided, use it instead of "since yesterday".

### Step 2: Gather activity

Run `git log` filtered to the appropriate author and time range:

```
git log --all --oneline --author="<email>" --since="<range>"
```

Also check for any PRs merged in the time range:

```
gh pr list --author @me --state merged --limit 10
```

### Step 3: Format the standup

Print in this format:

```markdown
## Standup — <date>

### Yesterday
- <commit summary grouped by branch/feature>
- <PRs merged>

### Today
- <inferred from current branch name and uncommitted changes>
- <open PRs that need attention>

### Open PRs
- #<number>: <title> (<status/checks>)
```

If there is no activity for "Yesterday", say "No commits found" rather than omitting the section.

For "Today", infer from:
- The current branch name (what feature/fix is in progress)
- Any uncommitted changes (what is being worked on now)
- Open PRs awaiting review

### Step 4: Offer actions

After presenting the standup, offer to:
1. Copy to clipboard (`pbcopy`)
2. Adjust the time range and regenerate
