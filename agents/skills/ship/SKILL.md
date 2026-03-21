---
name: ship
description: "Review, address findings, improve, address improvements, then merge. Full ship pipeline: /review + fix + /improve + fix + /merge in one command."
disable-model-invocation: true
---

# Ship Pipeline

Run the full review-fix-improve-fix-merge pipeline to ship the current branch.

## Arguments

- `$ARGUMENTS` - Optional: flags to customize the pipeline (e.g., "skip-improve" to skip the improve phase)

## Context

- Current branch: !`git branch --show-current`
- Base ref: !`git branch -r 2>/dev/null | grep -oE 'origin/(main|master)' | head -1`
- Git status: !`git status --short`
- Changes vs main: !`git diff --stat HEAD...origin/main 2>/dev/null | head -50`
- Changes vs master: !`git diff --stat HEAD...origin/master 2>/dev/null | head -50`

## Overview

You orchestrate a 5-phase pipeline to take the current branch from "done coding" to "merged into master." Each phase must complete before advancing to the next.

**Phases:**
1. **Review** — run `/review` to get findings
2. **Address review** — fix blocking issues and warnings
3. **Improve** — run `/improve` to capture learnings and fix gaps
4. **Address improvements** — apply approved improvements
5. **Merge** — run `/merge` to land the branch

If any phase has nothing to do (no findings, no improvements), skip it and move on.

---

## Phase 1: Review

Invoke the `/review` skill to analyze the current branch changes. Wait for the full report.

If the review returns **no blocking issues and no warnings**, print:

> Review clean — skipping to Phase 3.

And skip directly to Phase 3.

## Phase 2: Address Review Findings

Work through the review report systematically:

### 2a: Fix BLOCKING issues

For each blocking issue in the review report:
1. Read the referenced file and understand the issue
2. Make the minimal fix
3. Commit with a message describing the fix

If there are no blocking issues, skip to 2b.

### 2b: Fix WARNING issues

For each warning in the review report:
1. Read the referenced file and evaluate the warning
2. If it is a real issue, fix it and commit
3. If it is a false positive or intentional design choice, skip it

### 2c: Verify fixes

After addressing findings, run the test suite to confirm nothing broke:
- Detect test runner from project type (go.mod, package.json, Gemfile, Cargo.toml, pyproject.toml)
- Run the tests
- If tests fail, diagnose and fix before proceeding

Print a summary of what was addressed:

> Phase 2 complete: fixed N blocking issues, N warnings. Tests passing.

## Phase 3: Improve

Check if `$ARGUMENTS` contains "skip-improve". If so, skip to Phase 5.

Invoke the `/improve` skill. This will analyze the session for skill improvements, codebase gaps, and knowledge updates.

**Important:** When `/improve` asks for approval on changes, auto-approve all changes EXCEPT:
- New skill creation (let the user decide)
- External skill handoffs (present to user)
- Large refactors or breaking changes (present to user)

For straightforward fixes (docs, missing error handling, agent guidance updates, knowledge captures), apply them directly.

## Phase 4: Address Improvements

If `/improve` produced code changes (codebase gaps, agent guidance updates):
1. Verify the changes compile/pass tests
2. Commit any uncommitted improvement changes with descriptive messages

If `/improve` produced no code changes, skip this phase.

Print a summary:

> Phase 4 complete: applied N improvements. Tests passing.

## Phase 5: Merge

Invoke the `/merge` skill to land the branch into master.

Handle merge script exit codes as documented in the `/merge` skill (conflicts, nothing to merge, review blocked, errors).

---

## Abort Conditions

- **No changes on branch:** If there are no commits ahead of master and no uncommitted changes, stop immediately: "Nothing to ship — no changes on this branch."
- **Tests fail after 3 fix attempts:** Stop and report: "Tests are failing after 3 fix attempts. Manual intervention needed."
- **Merge blocked by required review:** Report the PR URL and stop: "PR requires review approval before merging."

## Summary Format

After the pipeline completes (or aborts), print:

```
# Ship Summary: {branch name}

| Phase | Status | Details |
|-------|--------|---------|
| Review | {done/skipped} | {N blocking, N warnings found} |
| Address Review | {done/skipped} | {N fixed, N skipped} |
| Improve | {done/skipped} | {N improvements applied} |
| Address Improvements | {done/skipped} | {N commits} |
| Merge | {done/blocked/failed} | {PR URL or error} |
```
