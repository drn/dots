---
allowed-tools: Bash(git log:*), Bash(git diff:*), Bash(git show:*), Bash(git tag:*)
description: Generate an intelligent changelog from recent commits
---

## Context

- Current branch: !`git branch --show-current`
- Latest tag: !`git describe --tags --abbrev=0 2>/dev/null`
- Recent commits (last 7 days): !`git log --oneline --since="7 days ago" 2>/dev/null | head -20`

## Arguments

- `$ARGUMENTS` - Optional: time period to look back (e.g., "2 weeks", "since v1.2.0", "last 30 days", "2025-01-01..2025-02-01")

## Your task

Generate a well-organized, human-readable changelog from recent git history.

### Step 1: Determine the time range

If the user provided a time period in `$ARGUMENTS`, use it. Otherwise, **ask the user** what time period they want the changelog to cover. Suggest useful options based on the context above:

- Since a specific tag (if tags exist)
- Last N days/weeks
- A date range
- Since a specific commit

### Step 2: Gather commits

Run `git log` for the chosen time range with full commit messages:

```
git log --format="%H%n%s%n%b%n---END---" <range>
```

If there are merge commits, also look at what was merged:

```
git log --merges --format="%H %s" <range>
```

If there are very few commits, also inspect the diffs to understand what changed:

```
git diff --stat <range>
```

### Step 3: Analyze and categorize

Read through all commit messages and diffs. Group changes into categories. Use only categories that have entries — skip empty ones. Choose from:

- **Added** — new features, commands, tools, or capabilities
- **Changed** — modifications to existing behavior, UI updates, refactors
- **Fixed** — bug fixes
- **Removed** — deleted features, deprecated code removal
- **Infrastructure** — CI/CD, build system, dependency updates, tooling
- **Documentation** — README, docs, comments

### Step 4: Write the changelog

Write a changelog that is:

- **Grouped by category** with clear headers
- **Concise but meaningful** — each entry should explain *what* and *why*, not just parrot the commit message
- **Deduplicated** — combine related commits into a single entry (e.g., a feature + its follow-up fix = one entry)
- **Ordered by significance** within each category
- **Free of noise** — omit trivial changes like typo fixes or formatting unless nothing else happened

Format each entry as a bullet point. Include relevant context like file paths or component names only when it helps the reader understand the scope.

### Step 5: Present the changelog

Print the changelog in this format:

```
## Changelog: <description of range>

### Added
- Entry here

### Changed
- Entry here

### Fixed
- Entry here
```

After presenting, offer to:
1. Copy to clipboard (`pbcopy`)
2. Save to a file
