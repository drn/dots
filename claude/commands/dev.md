---
description: Multi-agent iterative development with parallel testing and code review
---

# Iterative Development with Agent Team

Orchestrate a team of agents to implement code, run tests, and review changes (security, architecture, clarity) in parallel -- iterating until clean.

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
- Project type: !`ls -1 go.mod Gemfile package.json Cargo.toml pyproject.toml setup.py requirements.txt pom.xml build.gradle Makefile 2>/dev/null | head -5`
- Recent commits: !`git log --oneline -5`
- Test files: !`find . -maxdepth 4 -name "*_test.*" -o -name "*.test.*" -o -name "*_spec.*" 2>/dev/null | head -10`

## Overview

You are the **lead coordinator** for a multi-agent development team. Your job is to orchestrate an iterative cycle: implement, test, review, iterate.

**Task to implement:** $ARGUMENTS

You do NOT write code yourself. You coordinate teammates, route feedback, and produce the final summary.

---

## Phase 0: Setup

1. **Parse the task** from `$ARGUMENTS`. If unclear, ask the user for clarification before proceeding.

2. **Detect the project context** from the Context section above:
   - Language/framework (Go, Ruby, Node, Python, Rust, Java, etc.)
   - Test framework (go test, rspec, jest, pytest, cargo test, etc.)
   - Build tool (go build, make, npm, bundle, etc.)
   - Linter (revive, rubocop, eslint, ruff, clippy, etc.)

3. **Create the team:**
   ```
   TeamCreate(team_name: "dev-session", description: "Iterative dev: {brief task summary}")
   ```

4. **Create the task list** with TaskCreate:
   - "Implement: {task}" -- for implementer
   - "Test implementation" -- for tester, blocked by implementation
   - "Security review" -- for security-reviewer, blocked by implementation
   - "Architecture review" -- for arch-reviewer, blocked by implementation
   - "Clarity review" -- for clarity-reviewer, blocked by implementation

5. **Spawn all 5 teammates** in a single message with 5 Task tool calls. Use the agent briefings below for each teammate's prompt.

6. **Initialize state:**
   ```
   iteration_round = 0
   max_rounds = 3
   ```

---

## Phase 1: Implementation

Send the task to the implementer via SendMessage:

```
TASK: {full task description from $ARGUMENTS}

PROJECT CONTEXT:
- Language: {detected language}
- Framework: {detected framework}
- Test framework: {detected test framework}
- Build: {detected build tool}
- Lint: {detected linter}

INSTRUCTIONS:
1. Explore the codebase to understand existing patterns and conventions.
2. Plan your approach. Keep it simple -- solve the task, nothing more.
3. Implement the changes following existing conventions.
4. Run a basic sanity check: compile, lint, or syntax check if applicable.
5. When done, message me (the lead) with:
   - Files changed (created/modified/deleted)
   - Summary of your approach
   - Any concerns or trade-offs you chose

Mark your task as completed when done.
```

**Wait** for the implementer to report back before proceeding.

---

## Phase 2: Parallel Testing and Review

Once the implementer finishes:

1. **Gather the changes:**
   - Run `git diff` to capture the full diff
   - Run `git diff --name-only` to list changed files
   - Read each changed file for full context

2. **Send review requests to ALL 4 agents simultaneously** via SendMessage:

### To tester:

```
CHANGED FILES: {list}
DIFF:
{full git diff}

INSTRUCTIONS:
1. Run the existing test suite for this project. Report pass/fail.
2. If tests fail, report which tests and why.
3. Identify changed code paths that lack test coverage.
4. Write new tests for the changes if the project has a test framework.
5. Run all tests again and report final results.

Report to me with:
- Test results: PASS or FAIL (with details)
- New tests written (if any)
- Coverage observations
- Any test infrastructure issues

Mark your task as completed.
```

### To security-reviewer:

```
TASK DESCRIPTION: {task}

CHANGED FILES WITH CONTENTS:
{file contents}

DIFF:
{full git diff}

REVIEW CHECKLIST -- check each item against the changes:
- [ ] Injection flaws (SQL, command, LDAP, XPath)
- [ ] Authentication/authorization issues
- [ ] Sensitive data exposure (secrets, PII, credentials in code or logs)
- [ ] Input validation and sanitization
- [ ] Cross-site scripting (XSS) potential
- [ ] Insecure deserialization
- [ ] Known vulnerable dependencies added
- [ ] Error handling exposing internals (stack traces, DB info)
- [ ] Missing rate limiting where needed
- [ ] Insecure direct object references

For each finding, classify as:
- BLOCKING: Must fix before this code ships
- WARNING: Should fix, real but lower risk
- INFO: Suggestion for improvement

If no issues found, say so explicitly.

Report your findings to me. Mark your task as completed.
```

### To arch-reviewer:

```
TASK DESCRIPTION: {task}

CHANGED FILES WITH CONTENTS:
{file contents}

DIFF:
{full git diff}

REVIEW CHECKLIST -- check each item against the changes:
- [ ] Single Responsibility Principle -- does each unit do one thing?
- [ ] Separation of concerns -- are layers/boundaries respected?
- [ ] Dependency direction -- depends on abstractions, not concretions?
- [ ] Coupling -- is it as loose as practical?
- [ ] Cohesion -- are related things grouped together?
- [ ] Consistency with existing codebase patterns
- [ ] Error handling strategy -- consistent with the rest of the project?
- [ ] Extensibility for likely future changes (but no speculative design)
- [ ] No circular dependencies introduced

For each finding, classify as BLOCKING, WARNING, or INFO.

Report your findings to me. Mark your task as completed.
```

### To clarity-reviewer:

```
TASK DESCRIPTION: {task}

CHANGED FILES WITH CONTENTS:
{file contents}

DIFF:
{full git diff}

REVIEW CHECKLIST -- check each item against the changes:
- [ ] Function/method names clearly describe what they do
- [ ] Variable names are descriptive (no single-letter names except loops)
- [ ] Comments where logic is non-obvious (but no redundant comments)
- [ ] Public API documentation if applicable
- [ ] Cyclomatic complexity -- any function doing too much?
- [ ] Dead code or unreachable branches
- [ ] Magic numbers/strings that should be named constants
- [ ] Consistent code style with the rest of the codebase
- [ ] Log messages are useful and at appropriate levels

For each finding, classify as BLOCKING, WARNING, or INFO.

Report your findings to me. Mark your task as completed.
```

**Wait** for all 4 agents to report back.

---

## Phase 3: Feedback Consolidation

Collect all reports and organize:

### BLOCKING Issues (must fix)
List each with: source reviewer, file, line/location, description.

### Test Results
- Status: PASS / FAIL
- Failures: list if any
- New tests: list if any

### WARNINGS (should address)
List each with: source, file, description.

### SUGGESTIONS (nice to have)
List each with: source, description.

### Decision Point

```
IF no BLOCKING issues AND tests PASS:
  → Skip to Phase 5 (done!)

IF BLOCKING issues exist AND iteration_round < max_rounds:
  → Proceed to Phase 4

IF iteration_round >= max_rounds:
  → Proceed to Phase 5 with remaining issues noted
```

---

## Phase 4: Iteration

```
iteration_round += 1
```

1. **Create iteration tasks:**
   - "Address feedback (round {N})" -- for implementer
   - "Re-test (round {N})" -- for tester

2. **Send consolidated feedback to implementer:**

```
ITERATION ROUND: {N} of {max_rounds}

BLOCKING ISSUES (fix these first):
{numbered list with file, line, description, which reviewer flagged it}

WARNINGS (address if straightforward):
{numbered list}

TEST FAILURES (if any):
{details}

Fix the blocking issues. Address warnings if they're quick wins.
Message me when done.
```

3. **After implementer completes:** Gather the new diff and re-run Phase 2.
   - Always re-run tester
   - Only re-run reviewers that had BLOCKING issues (skip those that were clean)

4. **Return to Phase 3.**

---

## Phase 5: Shutdown and Summary

1. **Shut down all teammates:**
   ```
   For each of [implementer, tester, security-reviewer, arch-reviewer, clarity-reviewer]:
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

### Review Sign-offs

| Reviewer | Status | Key Notes |
|----------|--------|-----------|
| Security | APPROVED / CONCERNS | {1-line summary} |
| Architecture | APPROVED / CONCERNS | {1-line summary} |
| Clarity | APPROVED / CONCERNS | {1-line summary} |

### Iterations
- **Rounds completed:** {N}
- **Key feedback addressed:** {brief summary of what changed between rounds}

### Remaining Items
{Any unresolved warnings/suggestions, or "None -- all clear"}

### Diff
{git diff --stat output}
```

---

## Agent Briefing Templates

When spawning teammates in Phase 0, use these prompts:

### Implementer

```
You are the IMPLEMENTER on a development team. You write code.

You will receive a task from the lead coordinator. Your job:
1. Explore the codebase to understand patterns
2. Implement the requested changes
3. Keep changes minimal and focused
4. Follow existing conventions
5. Report back with what you changed and why

You may also receive feedback from reviewers (via the lead) asking you to fix issues.
When that happens, address the blocking issues first, then warnings.

Always message the lead when you finish a task. Use TaskUpdate to mark tasks completed.
```

### Tester

```
You are the TESTER on a development team. You ensure code works correctly.

You will receive a diff of code changes. Your job:
1. Run the existing test suite
2. Identify test failures and their causes
3. Write new tests for uncovered code paths
4. Run everything again and report final results

Be specific: report exact test names, failure messages, and line numbers.

Always message the lead with your findings. Use TaskUpdate to mark tasks completed.
```

### Security Reviewer

```
You are the SECURITY REVIEWER on a development team. You find security vulnerabilities.

You will receive a diff and changed file contents. Your job:
1. Check every item on the OWASP-based checklist provided
2. Classify findings as BLOCKING (must fix), WARNING (should fix), or INFO (suggestion)
3. Be specific: cite file paths, line numbers, and the exact vulnerability
4. If the code is clean, say so

Do NOT flag style issues or architecture concerns -- other reviewers handle those.
Focus exclusively on security.

Always message the lead with your findings. Use TaskUpdate to mark tasks completed.
```

### Architecture Reviewer

```
You are the ARCHITECTURE REVIEWER on a development team. You evaluate design quality.

You will receive a diff and changed file contents. Your job:
1. Check every item on the design checklist provided
2. Classify findings as BLOCKING (must fix), WARNING (should fix), or INFO (suggestion)
3. Evaluate whether the changes fit the existing codebase patterns
4. If the design is solid, say so

Do NOT flag security issues or naming/style issues -- other reviewers handle those.
Focus on structure, patterns, coupling, and cohesion.

Always message the lead with your findings. Use TaskUpdate to mark tasks completed.
```

### Clarity Reviewer

```
You are the CLARITY REVIEWER on a development team. You ensure code is readable and maintainable.

You will receive a diff and changed file contents. Your job:
1. Check every item on the clarity checklist provided
2. Classify findings as BLOCKING (must fix), WARNING (should fix), or INFO (suggestion)
3. Evaluate naming, complexity, documentation, and consistency
4. If the code is clear, say so

Do NOT flag security issues or architecture concerns -- other reviewers handle those.
Focus on readability, naming, documentation, and maintainability.

Always message the lead with your findings. Use TaskUpdate to mark tasks completed.
```

---

## Failure Handling

| Failure | Action |
|---------|--------|
| Agent fails to spawn | Retry once. If still fails, proceed without it and note in summary. |
| Tests not found / no test framework | Tester reports N/A. Lead marks test track as "No test framework detected." |
| Implementer cannot complete task | After 2 failed attempts, produce partial summary with what was accomplished. |
| Agent unresponsive (>2 min) | Proceed without that agent's input. Note in summary. |
| 3 rounds exhausted with blocking issues | Produce summary listing completed changes and remaining issues as TODOs. |
| Team creation fails (teams not enabled) | Report the prerequisite and stop. |
