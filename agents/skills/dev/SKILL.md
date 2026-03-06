---
name: dev
description: Multi-agent iterative development with parallel testing and code review. Use for building features, implementing changes, or coding tasks that need testing and review.
---

# Iterative Development with Agent Team

Orchestrate a team of agents to implement code, run tests, and review changes in parallel -- iterating until clean. Teammates communicate directly with each other for faster feedback loops.

## Prerequisites

Agent teams must be enabled in Claude Code settings:

```
CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

If agent teams are not enabled, report: "Agent teams required. Add `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` to your Claude Code settings (env section)." and stop.

## Arguments

- `$ARGUMENTS` - Required: description of the development task to implement

If no arguments are provided, ask the user what they want to build.

## Context

- Current branch: !`git branch --show-current`
- Git status: !`git status --short`
- Project root: !`pwd`
- Project type: !`find . -maxdepth 1 \( -name go.mod -o -name Gemfile -o -name package.json -o -name Cargo.toml -o -name pyproject.toml -o -name setup.py -o -name requirements.txt -o -name pom.xml -o -name build.gradle -o -name Makefile \) 2>/dev/null | head -5`
- Recent commits: !`git log --oneline -5`
- Test files: !`find . -maxdepth 4 -name "*_test.*" -o -name "*.test.*" -o -name "*_spec.*" 2>/dev/null | head -10`

## Overview

You are the **lead coordinator** for a multi-agent development team. Your job is to orchestrate an iterative cycle: plan, implement, test, review, iterate.

**Task to implement:** $ARGUMENTS

You do NOT write code yourself. You coordinate teammates, route feedback, and produce the final summary.

**Team philosophy:** Teammates talk to each other directly -- not everything goes through the lead. The reviewer validates the implementer's plan before coding starts. The reviewer asks the tester to verify suspected bugs. During iterations, the tester and reviewer send feedback directly to the implementer. The lead monitors, consolidates, and decides when to stop.

---

## Phase 0: Setup and Plan Approval

1. **Clean working tree:** If there are uncommitted changes, commit them with message `"WIP: pre-dev-session state"` before proceeding. This ensures clean diffs during the session.

2. **Parse the task** from `$ARGUMENTS`. If unclear, ask the user for clarification before proceeding.

3. **Detect the project context** from the Context section above:
   - Language/framework (Go, Ruby, Node, Python, Rust, Java, etc.)
   - Test framework (go test, rspec, jest, pytest, cargo test, etc.)
   - Build tool (go build, make, npm, bundle, etc.)
   - Linter (revive, rubocop, eslint, ruff, clippy, etc.)

4. **Explore the codebase** to understand relevant code, patterns, and conventions. Read key files related to the task. Understand the existing architecture before proposing changes.

5. **Present a plan to the user for approval.** Based on your exploration, write a concrete implementation plan and present it for the user to review. The plan must include:

   - **Goal:** One-sentence summary of the task.
   - **Approach:** How you intend to solve it (strategy, patterns to follow).
   - **Files to change:** List each file that will be created, modified, or deleted, with a brief description of the change.
   - **Testing strategy:** What tests will be added or run.
   - **Risks / trade-offs:** Anything the user should be aware of.

   **Wait for the user to approve the plan before proceeding.** If the user requests changes, revise and re-present until approved. Do NOT create the team or spawn agents until the user approves.

6. **Create the team** (clean up stale session first if needed):
   ```
   TeamDelete() -- ignore if no existing team
   TeamCreate(team_name: "dev-session", description: "Iterative dev: {brief task summary}")
   ```

7. **Create the task list** with TaskCreate:
   - "Plan: {task}" -- for implementer
   - "Validate plan" -- for reviewer, blocked by plan
   - "Implement: {task}" -- for implementer, blocked by plan validation
   - "Test implementation" -- for tester, blocked by implementation
   - "Code review" -- for reviewer, blocked by implementation

8. **Spawn all 3 teammates** in a single message with 3 Task tool calls. Use the agent briefings below for each teammate's prompt. Use `model: "sonnet"` for the tester. Include the approved plan in the implementer's briefing so they can skip redundant exploration.

9. **Initialize state:**
   ```
   iteration_round = 0
   max_rounds = 3
   ```

---

## Phase 1: Planning

Send the task and the user-approved plan to the implementer via SendMessage:

```
TASK: {full task description from $ARGUMENTS}

PROJECT CONTEXT:
- Language: {detected language}
- Framework: {detected framework}
- Test framework: {detected test framework}
- Build: {detected build tool}
- Lint: {detected linter}

APPROVED PLAN (already approved by the user):
{the plan approved in Phase 0, step 5}

INSTRUCTIONS:
1. Review the approved plan. You may refine implementation details, but the overall approach is set.
2. Send a brief implementation plan (specific code-level details) DIRECTLY to the reviewer for validation.
3. Wait for the reviewer's feedback before implementing.

Mark the "Plan" task as completed once your plan is sent.
```

**Wait** for the reviewer to validate the plan. The reviewer will message both the implementer and the lead with their verdict.

If the reviewer raises concerns, the lead tells the implementer to revise. Once the reviewer approves, proceed.

---

## Phase 2: Implementation

Send the go-ahead to the implementer via SendMessage:

```
Plan approved. Proceed with implementation.

INSTRUCTIONS:
1. Implement the changes following your approved plan.
2. Follow existing conventions.
3. Run a basic sanity check: compile, lint, or syntax check if applicable.
4. When done, message me (the lead) AND the tester with:
   - Files changed (created/modified/deleted)
   - Summary of your approach
   - Any concerns or trade-offs you chose

Mark the "Implement" task as completed when done.
```

While the implementer works, send the tester a heads-up:

```
The implementer is working on: {brief task summary}

Their plan: {approved plan summary}

While you wait, explore the existing test suite to understand patterns, frameworks, and conventions. Be ready to run tests and write new ones as soon as the implementer finishes.

IMPORTANT: When writing new tests, create NEW test files rather than modifying files the implementer touched, to avoid conflicts.
```

**Wait** for the implementer to report back before proceeding.

---

## Phase 3: Parallel Testing and Review

Once the implementer finishes:

1. **Gather the changes:**
   - Run `git diff` to capture the full diff
   - Run `git diff --name-only` to list changed files
   - Read each changed file for full context

2. **Send review requests to BOTH agents simultaneously** via SendMessage:

### To tester:

```
Implementation complete. Here are the changes:

CHANGED FILES: {list}
DIFF:
{full git diff}

INSTRUCTIONS:
1. Run the existing test suite. Report pass/fail.
2. If tests fail, report which tests and why.
3. Identify changed code paths that lack test coverage.
4. Write new tests in NEW files (don't modify files the implementer changed).
5. Run all tests again and report final results.
6. The reviewer may also message you directly to write targeted tests for suspected bugs. Prioritize those.

Report to me (the lead) with:
- Test results: PASS or FAIL (with details)
- New tests written (if any)
- Coverage observations

Mark your task as completed.
```

### To reviewer:

```
TASK DESCRIPTION: {task}

CHANGED FILES WITH CONTENTS:
{file contents}

DIFF:
{full git diff}

Review the changes against ALL checklists in references/CODE_REVIEW.md (security, architecture, clarity).

For each finding, classify as:
- BLOCKING: Must fix before this code ships
- WARNING: Should fix, real but lower risk
- INFO: Suggestion for improvement

IMPORTANT: If you suspect a specific bug (nil dereference, race condition, off-by-one, etc.), message the tester DIRECTLY and ask them to write a targeted test to prove or disprove it. Don't just flag it -- get evidence.

If no issues found, say so explicitly.

Report your findings to me (the lead). Mark your task as completed.
```

**Wait** for both agents to report back.

---

## Phase 4: Feedback Consolidation

Collect all reports and organize:

### BLOCKING Issues (must fix)
List each with: category (security/architecture/clarity), file, line/location, description.

### Test Results
- Status: PASS / FAIL
- Failures: list if any
- New tests: list if any

### WARNINGS (should address)
List each with: category, file, description.

### SUGGESTIONS (nice to have)
List each with: category, description.

### Decision Point

```
IF no BLOCKING issues AND tests PASS:
  IF diff is substantial (>50 lines changed OR touches auth/crypto/input-handling):
    → Proceed to Phase 6 (adversarial hardening)
  ELSE:
    → Skip to Phase 7 (done -- hardening unnecessary for small changes)

IF BLOCKING issues exist AND iteration_round < max_rounds:
  → Proceed to Phase 5 (iteration)

IF iteration_round >= max_rounds:
  → Proceed to Phase 4b (escalation)
```

---

## Phase 4b: Escalation (max rounds exhausted)

When `iteration_round >= max_rounds` with blocking issues remaining, present the user with escalation options:

```markdown
## Escalation: {max_rounds} rounds exhausted with blocking issues

### Unresolved Blocking Issues
{numbered list with category, file, line, description for each}

### Escalation Options
1. **Reassign** -- spawn a second implementer (`implementer-b`) with a different approach to the blocked issues
2. **Decompose** -- break the remaining work into smaller tasks and address them individually
3. **Defer** -- accept the current state and create TODO comments for unresolved issues
4. **Extend** -- grant {max_rounds} more rounds (reset iteration counter)

Which option? (default: defer)
```

**Wait for the user to choose.** Then:
- **Reassign:** Spawn `implementer-b` with fresh context. Send it ONLY the blocking issues and the current code state. Route through the same QA loop (tester + reviewer). Max 2 additional rounds.
- **Decompose:** Create new tasks for each blocking issue. Send each to the implementer one at a time with focused scope.
- **Defer:** Add `// TODO: {issue description}` comments at each flagged location. Note in the summary.
- **Extend:** Reset `iteration_round = 0` and return to Phase 5.

---

## Phase 5: Iteration

```
iteration_round += 1
```

1. **Create iteration tasks:**
   - "Address feedback (round {N})" -- for implementer
   - "Re-test (round {N})" -- for tester

2. **Send consolidated feedback directly to the implementer AND the tester simultaneously:**

### To implementer:

```
QA VERDICT: FAIL -- Round {N} of {max_rounds}

BLOCKING ISSUES (fix these -- each must be resolved to pass):
| # | Category | File | Line | Description | Fix Instruction |
|---|----------|------|------|-------------|-----------------|
{one row per blocking issue with a specific, actionable fix instruction}

WARNINGS (address if straightforward):
{numbered list}

TEST FAILURES:
{test name, failure message, and file:line for each}

INSTRUCTIONS:
1. Fix ONLY the issues listed above
2. Do NOT introduce new features or refactor unrelated code
3. When done, message me (the lead) AND the tester with your changes
4. This is attempt {N} of {max_rounds} -- if attempt {max_rounds} fails, the task escalates
```

### To tester:

```
ITERATION ROUND {N}: The implementer is fixing these issues:
{brief summary of blocking issues and test failures}

Wait for the implementer to finish, then re-run the full test suite.
Report results to me (the lead).
```

3. **After implementer completes and tester re-tests:** Gather the new diff.
   - Only re-run the reviewer if it had BLOCKING issues (skip if clean)

4. **Return to Phase 4.**

---

## Phase 6: Adversarial Hardening

This phase runs when tests pass, review is clean, AND the changes are substantial. Skip for trivial changes.

Send to the reviewer:

```
The implementation passed all tests and your initial review. Now switch to ADVERSARIAL mode.

Your job is to BREAK this code. Think like an attacker, a malicious user, or a chaotic system.

CHANGED FILES WITH CONTENTS:
{file contents}

Try to find:
- Edge cases: empty inputs, huge inputs, unicode, special characters
- Race conditions or concurrency issues
- Resource leaks (unclosed files, connections, goroutines)
- Error paths that aren't tested
- Assumptions that could be violated in production

For each attack vector you identify, message the tester DIRECTLY with a specific test case to write. For example:
"Write a test that passes an empty string to ParseConfig() -- I think it'll panic on line 42."

Report your attack vectors and results to me (the lead) when done.
```

Send to the tester:

```
ADVERSARIAL PHASE: The reviewer is trying to break the implementation. They will message you directly with specific test cases to write.

Write each test they suggest. Run it. Report back to the reviewer AND me (the lead) whether it passed or failed.

If a test fails (i.e., the reviewer found a real bug), report the details.
```

**Wait** for both to finish.

**If new bugs found:** Send them to the implementer as a final fix round, then re-run tests. If tests pass, proceed to Phase 7. If not, proceed to Phase 7 with remaining issues noted.

**If no bugs found:** Proceed to Phase 7.

---

## Phase 7: Shutdown and Summary

1. **Shut down all teammates:**
   ```
   For each of [implementer, tester, reviewer]:
     SendMessage(type: "shutdown_request", recipient: {name}, content: "Work complete. Shutting down.")
   ```
   Wait for confirmations.

2. **Clean up the team** with TeamDelete.

3. **Produce the final summary:**

```markdown
## Development Summary

### Task
{original task description}

### Changes Made
| File | Action | Description |
|------|--------|-------------|
| path/to/file | created/modified/deleted | brief description |

### Test Results
- **Status:** PASS / FAIL / N/A
- **New tests written:** {count} -- {brief descriptions}
- **Coverage notes:** {observations from tester}

### Review Sign-off

| Category | Status | Key Notes |
|----------|--------|-----------|
| Security | APPROVED / CONCERNS | {1-line summary} |
| Architecture | APPROVED / CONCERNS | {1-line summary} |
| Clarity | APPROVED / CONCERNS | {1-line summary} |

### Adversarial Hardening
- **Status:** PERFORMED / SKIPPED (change too small)
- **Attack vectors tested:** {count}
- **Bugs found:** {count} -- {brief descriptions, or "None"}

### Iterations
- **Rounds completed:** {N}
- **First-pass QA:** {PASS or FAIL} (did the first implementation pass without iteration?)
- **Key feedback addressed:** {brief summary of what changed between rounds}

### Remaining Items
{Any unresolved warnings/suggestions, or "None -- all clear"}

### Diff
{git diff --stat output}
```

---

## Agent Briefing Templates

When spawning teammates in Phase 0, read [references/BRIEFINGS.md](references/BRIEFINGS.md) for the full prompts for each role (implementer, tester, reviewer).

---

## Failure Handling

| Failure | Action |
|---------|--------|
| Agent fails to spawn | Retry once. If still fails, proceed without it and note in summary. |
| Tests not found / no test framework | Tester reports N/A. Lead marks test track as "No test framework detected." |
| Implementer stuck on same issue twice | Spawn a second implementer (`implementer-b`) with a different approach. Have the reviewer compare both solutions and pick the better one. Shut down the losing implementer. |
| Agent unresponsive | Send a follow-up message. If still no response after a second nudge, proceed without that agent's input and note in summary. |
| 3 rounds exhausted with blocking issues | Proceed to Phase 4b escalation -- present user with options: reassign, decompose, defer, or extend. |
| Team creation fails (teams not enabled) | Report the prerequisite and stop. |
