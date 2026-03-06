---
name: polish
description: Analyze codebase for code smells and refactor to drastically improve code quality. Expert in clean code, SOLID principles, Ruby patterns, service objects, and refactoring. Use for code quality audits, refactoring sessions, and cleaning up technical debt.
---

# Clean Code Expert

Analyze a codebase for code smells, SOLID violations, and anti-patterns, then refactor with surgical precision. Produces a prioritized finding report and applies fixes iteratively with test verification.

## Prerequisites

Agent teams must be enabled in Claude Code settings:

```
CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

If agent teams are not enabled, report: "Agent teams required. Add `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` to your Claude Code settings (env section)." and stop.

## Arguments

- `$ARGUMENTS` - Optional: scope to analyze (file path, directory, class name, or description like "the checkout flow"). Defaults to changed files on the current branch, or the full codebase if on the default branch.

## Context

- Current branch: !`git branch --show-current`
- Git status: !`git status --short`
- Project root: !`pwd`
- Project type: !`find . -maxdepth 1 \( -name go.mod -o -name Gemfile -o -name package.json -o -name Cargo.toml -o -name pyproject.toml -o -name setup.py -o -name requirements.txt -o -name pom.xml -o -name build.gradle -o -name Makefile \)`
- Test framework: !`find . -maxdepth 4 \( -name "*_test.*" -o -name "*.test.*" -o -name "*_spec.*" \)`
- Linter config: !`find . -maxdepth 1 \( -name .rubocop.yml -o -name .rubocop_todo.yml -o -name ".eslintrc*" -o -name ".prettierrc*" -o -name revive.toml \)`
- Recent commits: !`git log --oneline -5`
- Changes vs main: !`git diff --name-only origin/main...HEAD 2>/dev/null | head -50`
- Changes vs master: !`git diff --name-only origin/master...HEAD 2>/dev/null | head -50`

## Overview

You are the **lead architect** for a clean code analysis and refactoring session. Your job is to scope the analysis, assign specialized analyzers, consolidate findings into a prioritized plan, and orchestrate refactoring with test verification.

**Scope:** $ARGUMENTS

You do NOT analyze or refactor yourself. You coordinate the analysis team, prioritize findings, and manage the refactoring cycle.

---

## Phase 0: Scope and Setup

1. **Determine the scope:**

   ```
   IF $ARGUMENTS specifies files, directories, or classes:
     Use those as the analysis scope
   ELIF on a feature branch with changed files:
     Analyze changed files on this branch
   ELSE:
     Ask the user to specify a scope (analyzing everything is rarely useful)
   ```

2. **Detect language and tooling** from the Context section:
   - Language (Ruby, Go, Python, JS/TS, etc.)
   - Framework (Rails, Sinatra, Express, etc.)
   - Test runner (rspec, minitest, go test, jest, pytest, etc.)
   - Linter (rubocop, revive, eslint, ruff, etc.)

3. **Read the files in scope** to understand the codebase before spawning analyzers. Skim directory structure and key files. Identify patterns already in use (service objects, concerns, presenters, etc.).

4. **Present the analysis plan to the user:**

   ```
   # Clean Code Analysis Plan

   **Scope:** {files/directories}
   **Language:** {detected}
   **Lines of code:** ~{estimate from file count}

   **Analysis team:**
   1. Structure Analyzer — method/class size, parameter lists, data clumps
   2. Design Analyzer — SOLID violations, coupling, cohesion, abstraction issues
   3. Smell Detector — duplication, dead code, feature envy, naming, magic values
   4. Idiom Specialist — language-specific anti-patterns and missed opportunities

   Proceed? (y/n)
   ```

   Wait for user approval.

5. **Create the team:**
   ```
   TeamDelete() -- ignore if no existing team
   TeamCreate(team_name: "polish-session", description: "Polish: {brief scope}")
   ```

6. **Create the task list** with TaskCreate:
   - "Analyze: structure and size" -- for structure-analyzer
   - "Analyze: design and SOLID" -- for design-analyzer
   - "Analyze: smells and duplication" -- for smell-detector
   - "Analyze: language idioms" -- for idiom-specialist
   - "Consolidate findings" -- for lead, blocked by all 4 analysis tasks
   - "Refactor: batch 1" -- blocked by consolidation
   - "Verify: run tests" -- blocked by refactoring

7. **Spawn all 4 analyzers** in a single message with 4 Task tool calls. Use the agent briefings below. Use `model: "sonnet"` for all.

---

## Phase 1: Parallel Analysis

Send each analyzer their assignment via SendMessage. Include the full file contents for all files in scope. Read [references/ANALYZERS.md](references/ANALYZERS.md) for the detailed checklist prompts for each analyzer (structure, design, smells, idioms).

**Wait** for all 4 analyzers to report.

---

## Phase 2: Consolidation and Prioritization

After all analyzers report, consolidate findings. Read [references/SCORING.md](references/SCORING.md) for the scoring framework, batch grouping rules, and report template.

Wait for user direction. The user may approve all batches, select specific batches, pick individual items, or decline refactoring entirely (analysis-only mode).

If the user declines refactoring, skip to Phase 5 (summary).

---

## Phase 3: Refactoring

Execute refactoring in the order the user approved, one batch at a time.

```
max_batches = number of approved batches
current_batch = 1
```

For each approved batch:

1. **Create batch tasks:**
   - "Refactor: batch {N}" -- for the implementer
   - "Test: batch {N}" -- for the tester, blocked by refactoring

2. **Send refactoring instructions to the implementer:**

```
REFACTORING BATCH {N}: {batch name}

ITEMS TO REFACTOR:
{numbered list from the prioritized plan, with file, line, technique}

CURRENT FILE CONTENTS:
{full contents of files being modified}

RULES -- follow these strictly:
1. One refactoring at a time. Do not combine unrelated changes.
2. Preserve all existing behavior. Refactoring changes structure, not behavior.
3. Follow existing code style and conventions in the project.
4. If extracting a method/class, name it clearly -- the name IS the documentation.
5. Run the linter after each change if a linter is configured.
6. Do NOT add comments explaining the refactoring. The code should be self-explanatory.
7. Do NOT change public API signatures unless the finding specifically calls for it.
8. If a refactoring would require changes outside the approved scope, flag it but do not make it.

LANGUAGE-SPECIFIC RULES (Ruby/Rails):
- Extracted service objects go in app/services/ with a single public #call method
- Value objects go in app/models/ or app/values/ depending on project convention
- Form objects go in app/forms/
- Query objects go in app/queries/
- Use keyword arguments for methods with >2 parameters
- Prefer composition over inheritance
- Use modules for shared behavior, not for organizing unrelated methods

When done, message me (the lead) AND the tester with:
- List of files changed
- Summary of each refactoring applied
- Any items you chose to skip and why

Mark your task as completed.
```

3. **Send test instructions to the tester:**

```
The implementer is refactoring batch {N}. When they finish:

1. Run the FULL test suite -- not just tests for changed files.
2. Report: PASS or FAIL with details.
3. If tests fail, determine if the failure is:
   a. Caused by the refactoring (behavior change -- the implementer must fix)
   b. Pre-existing (flaky test or unrelated failure -- note but do not block)
4. Check that the refactored code still works as before. Look for subtle behavior changes:
   - Return value differences (nil vs empty array, string vs symbol)
   - Side effect changes (missing callbacks, changed execution order)
   - Exception type or message changes

Report to me (the lead). Mark your task as completed.
```

4. **Wait** for both to report.

5. **Evaluate results:**

   ```
   IF tests PASS:
     Log batch as complete, proceed to next batch

   IF tests FAIL due to refactoring:
     Send the failure details to the implementer:
     "Test failure caused by your refactoring. Fix or revert. Details: {failures}"
     Wait for fix, re-run tests (max 2 retries per batch)

   IF stuck after 2 retries:
     Revert the batch: "git checkout -- {files}" and note it in the summary
     Proceed to next batch
   ```

6. **Repeat** for each approved batch.

---

## Phase 4: Final Verification

After all batches complete:

1. **Run the full test suite** one final time (send to tester).

2. **Gather the complete diff:**
   ```bash
   git diff          # all changes
   git diff --stat   # summary
   ```

3. **Send final diff to a reviewer** (reassign one of the idle analyzers):

```
Review the complete refactoring for regressions:

DIFF:
{full git diff}

Check:
- [ ] No behavior changes (refactoring only -- structure changes, not logic)
- [ ] No accidentally deleted code
- [ ] No new code smells introduced by the refactoring
- [ ] All changes follow project conventions
- [ ] Public APIs unchanged (unless explicitly approved)

Report: CLEAN or list concerns.
```

**Wait** for both to report.

---

## Phase 5: Shutdown and Summary

1. **Shut down all teammates:**
   ```
   For each active agent:
     SendMessage(type: "shutdown_request", recipient: {name}, content: "Clean code session complete.")
   ```
   Wait for confirmations.

2. **Clean up the team** with TeamDelete.

3. **Produce the final report:**

```markdown
## Clean Code Report

### Scope
{files analyzed}

### Health Score: {before}/100 -> {after}/100

### Findings Summary
| Category | Found | Fixed | Deferred | Skipped |
|----------|-------|-------|----------|---------|
| Structure & Size | {n} | {n} | {n} | {n} |
| Design & SOLID | {n} | {n} | {n} | {n} |
| Smells & Duplication | {n} | {n} | {n} | {n} |
| Language Idioms | {n} | {n} | {n} | {n} |
| **Total** | **{n}** | **{n}** | **{n}** | **{n}** |

### Refactoring Applied

#### Batch 1: Quick Wins
| # | File | Refactoring | Status |
|---|------|------------|--------|
| 1 | path/to/file | Extract method: {name} | DONE |

#### Batch 2: Core Refactors
| # | File | Refactoring | Status |
|---|------|------------|--------|

### Test Results
- **Before refactoring:** {PASS/FAIL}
- **After refactoring:** {PASS/FAIL}
- **Regressions introduced:** {count, or "None"}

### Deferred Items
{Items not addressed in this session, with recommended next steps}

### Diff
{git diff --stat output}
```

---

## Agent Briefing Templates

When spawning agents in Phase 0, read [references/BRIEFINGS.md](references/BRIEFINGS.md) for the full prompts for each role (analyzer, implementer, tester).

---

## Analysis-Only Mode

If the user says "just analyze" or "report only" or "no refactoring":

1. Run Phase 0 and Phase 1 as normal
2. Run Phase 2 to produce the prioritized report
3. Skip Phase 3 and Phase 4
4. In Phase 5, produce the report without the refactoring sections

---

## Failure Handling

| Failure | Action |
|---------|--------|
| Agent fails to spawn | Retry once. Merge that analyzer's checklist into another. |
| Analyzer finds nothing | Valid result -- report "clean" for that category. |
| Tests fail before refactoring starts | Note pre-existing failures. Proceed with refactoring but do not blame new failures on refactoring without evidence. |
| Refactoring breaks tests (2 retries exhausted) | Revert that batch. Note in summary as "attempted but reverted." Proceed to next batch. |
| User wants to stop mid-refactoring | Stop immediately. Report what was completed and what remains. |
| No test suite exists | Warn the user: "No tests detected. Refactoring without tests is risky. Proceed anyway?" If yes, proceed but rely on linter and manual review only. |
| Scope too large (>50 files) | Suggest narrowing scope. If user insists, split files across analyzers by directory. |
| Team creation fails (teams not enabled) | Report the prerequisite and stop. |
