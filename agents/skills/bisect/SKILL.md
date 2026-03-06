---
name: bisect
allowed-tools: Bash(git bisect:*), Bash(git log:*), Bash(git status:*), Bash(git diff:*), Bash(git show:*), Bash(git rev-parse:*), Bash(git stash:*)
description: Find which commit introduced a bug using git bisect with automatic test verification. Use when tracking down which commit introduced a bug.
disable-model-invocation: true
---

# Git Bisect

Find the exact commit that introduced a bug using binary search with automatic test verification.

## Arguments

- `$ARGUMENTS` - Required: a test command to verify the bug (e.g., "go test ./pkg/..." or "npm test"), or a description of the bug to investigate manually

## Context

- Current branch: !`git branch --show-current`
- Git status: !`git status --short`
- Recent commits (50): !`git log --oneline -50 2>/dev/null | head -50`
- Test framework: !`find . -maxdepth 1 \( -name go.mod -o -name Gemfile -o -name package.json -o -name Cargo.toml -o -name pyproject.toml \) 2>/dev/null | head -5`
- Latest tag: !`git describe --tags --abbrev=0 2>/dev/null | head -1`

## Instructions

### Step 0: Validate state

- IF `git status --short` shows uncommitted changes, offer to stash them with `git stash push -m "bisect: stashing before bisect"`. If the user declines, stop and tell them to commit or stash first.
- IF `$ARGUMENTS` is empty, ask the user: "What test command should I run to detect the bug? Or describe the bug and I will check each commit manually."

### Step 1: Determine boundaries

The "bad" commit is HEAD (current state where the bug exists).

For the "good" commit, ask the user or infer:
- IF the user provides a known-good commit or tag, use it.
- IF a latest tag exists, suggest it as the good commit: "Is the bug present in <tag>? If not, I will use it as the good boundary."
- OTHERWISE, suggest a commit from the recent history (e.g., 20 commits back) and ask the user to confirm.

### Step 2: Start bisect

```
git bisect start
git bisect bad HEAD
git bisect good <good-commit>
```

Report how many commits are in the range and the estimated number of steps (log2).

IF the range exceeds 1000 commits, warn the user: "This is a large range (<N> commits, ~<steps> steps). Consider narrowing the boundaries."

### Step 3: Run bisect

IF the user provided a test command:
- Use `git bisect run <test-command>` for automatic bisection.
- The test command should exit 0 for "good" (bug not present) and non-zero for "bad" (bug present).
- Monitor the output. IF the test command exits with 125 (skip), report that the commit could not be tested and bisect will skip it.

IF the user described the bug (manual mode):
- At each bisect step, read the relevant code or run the described check.
- Mark each commit as `git bisect good` or `git bisect bad` based on findings.
- Report progress: "Step N/~M: testing commit <hash> (<subject>)..."
- Limit to 20 steps maximum. IF exceeded, run `git bisect reset`, report "Bisect exceeded 20 steps — likely inconclusive. Consider narrowing the range." and stop.

### Step 4: Present the result

Once bisect identifies the offending commit:

1. Record the commit hash from bisect output.
2. Run `git bisect reset` to restore the original state.
3. IF changes were stashed in Step 0, run `git stash pop`.
4. Show the offending commit details:

```
git show <hash> --stat
git show <hash>
```

5. Check if the commit is associated with a PR:

```
git log --merges --ancestry-path <hash>..HEAD --oneline
```

6. Present a summary:

```markdown
## Bisect Result

**Offending commit:** <hash>
**Author:** <name> (<date>)
**Subject:** <commit message>

### Changed files
<list of files changed>

### Diff
<relevant diff excerpts>

### Related
- Merge commit: <if found>
- PR: <if identifiable from merge commit message>
```

### Step 5: Cleanup

Verify that bisect state is fully cleaned up:
- `git bisect reset` (if not already done)
- Restore stashed changes (if applicable)
- Confirm the user is back on the original branch
