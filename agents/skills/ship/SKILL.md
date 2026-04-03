---
name: ship
description: "Full ship pipeline: /review + fix + /improve + fix + /merge in one command. Use when ready to ship a branch end-to-end."
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

You orchestrate a 6-phase pipeline to take the current branch from "done coding" to "merged into master." Each phase must complete before advancing to the next.

**Phases:**
0. **Commit** — commit any uncommitted changes so downstream phases see them
1. **Review** — run `/review` to get findings
2. **Address review** — fix blocking issues and warnings
3. **Improve** — run `/improve` to capture learnings and fix gaps
4. **Address improvements** — apply approved improvements
5. **Merge** — run `/merge` to land the branch

If any phase has nothing to do (no findings, no improvements), skip it and move on.

---

## Phase 0: Commit Uncommitted Changes

Before running review, ensure all changes are committed. The review phase uses `git diff origin/master...HEAD` which only sees committed changes — uncommitted work would be invisible to the reviewer.

Check `git status --short`. If there are staged or unstaged changes to tracked files (or untracked files that are clearly part of the work):

1. Stage the relevant changes: `git add` the modified/new files
2. Craft a concise commit message summarizing the changes
3. Commit

If there are uncommitted changes AND existing commits ahead of master, commit the uncommitted changes as a separate commit to preserve the existing commit history.

If the working tree is clean, skip this phase.

Print:

> Phase 0: committed uncommitted changes. (or "Phase 0: working tree clean — skipped.")

## Phase 1: Review

Invoke the `/review` skill to analyze the current branch changes. Wait for the full report.

If the review returns **no blocking issues, no warnings, and no suggestions**, print:

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
1. Read the referenced file and understand the warning
2. Make the minimal fix and commit
3. Do NOT skip warnings — treat every warning as actionable and fix it

### 2c: Fix SUGGESTION / INFO issues

For each suggestion or INFO-level finding in the review report:
1. Read the referenced file and understand the suggestion
2. Apply the improvement and commit
3. Do NOT skip suggestions — apply all of them

### 2d: Verify fixes

After addressing all findings (blocking, warnings, and suggestions), run the test suite to confirm nothing broke:
- Detect test runner from project type (go.mod, package.json, Gemfile, Cargo.toml, pyproject.toml)
- Run the tests
- If tests fail, diagnose and fix before proceeding

Print a summary of what was addressed:

> Phase 2 complete: fixed N blocking issues, N warnings, N suggestions. Tests passing.

## Phase 3: Improve

Check if `$ARGUMENTS` contains "skip-improve". If so, skip to Phase 5.

Invoke the `/improve` skill. This will analyze the session for skill improvements, codebase gaps, and knowledge updates.

**Important:** Auto-apply ALL changes from `/improve` without asking for approval. This includes:
- Skill improvements (local skills only — external handoffs are still presented to user)
- Codebase gap fixes
- Agent guidance updates
- Knowledge captures
- New skill creation proposals

Do NOT pause for confirmation. Apply everything directly and commit. The only exception is external skill handoffs (different repo), which are printed as handoff prompts for the user.

**CRITICAL: After `/improve` completes, DO NOT stop or wait for user input. Immediately proceed to Phase 4 and then Phase 5. The entire pipeline must complete in a single uninterrupted flow unless an abort condition is hit.** The `/improve` skill returns a report — treat that report as input to the next phase, not as the end of the conversation.

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
| Commit | {done/skipped} | {committed N files / working tree clean} |
| Review | {done/skipped} | {N blocking, N warnings, N suggestions found} |
| Address Review | {done/skipped} | {N blocking fixed, N warnings fixed, N suggestions applied} |
| Improve | {done/skipped} | {N improvements applied} |
| Address Improvements | {done/skipped} | {N commits} |
| Merge | {done/blocked/failed} | {PR URL or error} |
```
