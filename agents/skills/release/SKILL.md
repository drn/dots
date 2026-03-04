---
name: release
allowed-tools: Bash(git tag:*), Bash(git log:*), Bash(git fetch:*), Bash(git diff:*), Bash(git status:*), Bash(git rev-parse:*), Bash(git symbolic-ref:*), Bash(gh release:*)
description: Create a versioned release with changelog generation, git tag, and GitHub release
disable-model-invocation: true
---

# Release

Create a versioned release: bump version, generate changelog, create git tag, and publish a GitHub release.

## Arguments

- `$ARGUMENTS` - Required: version bump type (`major`, `minor`, `patch`) or an explicit version (e.g., `v2.1.0`). Optional: `--dry-run` to preview without creating anything.

## Context

- Current branch: !`git branch --show-current`
- Git status: !`git status --short`
- Latest tag: !`git describe --tags --abbrev=0 2>/dev/null | head -1`
- Commits since last tag: !`git log --oneline 2>/dev/null | head -30`
- Remotes: !`git remote -v 2>/dev/null | head -10`
- Default branch ref: !`git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | head -1`

## Instructions

### Step 0: Validate state

- IF `git status --short` shows uncommitted changes, stop: "Uncommitted changes detected. Commit or stash before releasing."
- Determine the default branch using `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null`. Fallback to checking for `origin/main`, then `origin/master`.
- IF the current branch is not the default branch and does not match `release/*`, warn: "You are on <branch>, not the default branch. Releases are typically made from <default>. Proceed anyway?" Wait for confirmation.

### Step 1: Determine version

Parse `$ARGUMENTS` for the version:

- IF an explicit version is given (e.g., `v2.1.0`), use it directly.
- IF a bump type is given (`major`, `minor`, `patch`):
  - Parse the latest tag from context. IF no tags exist, start from `v0.0.0`.
  - Apply the bump. Examples: `v1.2.3` + patch = `v1.2.4`, + minor = `v1.3.0`, + major = `v2.0.0`.
  - Preserve the tag prefix (if existing tags use `v`, keep `v`; if bare numbers, use bare numbers).

Report: "Version: <current> -> <new>"

### Step 2: Generate changelog

Fetch commits since the last tag (or all commits if no prior tag):

```
git log <last-tag>..HEAD --format="%H%n%s%n%b%n---END---"
```

Categorize using the same approach as `/changelog`:
- **Added** — new features, commands, capabilities
- **Changed** — modifications to existing behavior
- **Fixed** — bug fixes
- **Removed** — deleted features, deprecated code
- **Infrastructure** — CI/CD, build, dependencies
- **Documentation** — docs, README

Write concise, meaningful entries. Deduplicate related commits. Skip trivial changes. Only include categories that have entries.

### Step 3: Preview

Present the release preview:

```markdown
## Release Preview: <new-version>

### Changelog
<categorized entries from Step 2>

### Tag
`<new-version>` on commit `<HEAD short hash>`

### GitHub Release
Title: <new-version>
Body: <changelog>
```

IF `--dry-run` is in `$ARGUMENTS`, stop here: "Dry run complete. No changes made."

Otherwise, ask for confirmation: "Create this release?"

### Step 4: Create tag

```
git tag -a <new-version> -m "<new-version>

<changelog summary>"
```

Push the tag:

```
git push origin <new-version>
```

### Step 5: Create GitHub release

```
gh release create <new-version> --title "<new-version>" --notes "<changelog>"
```

### Step 6: Report

```markdown
## Release Complete

**Version:** <new-version>
**Tag:** <new-version> on <commit hash>
**GitHub Release:** <URL from gh release create output>
**Changelog:** <N> entries across <M> categories
```
