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
- Branch changes: !`git diff --name-only origin/HEAD...HEAD`

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

Send each analyzer their assignment via SendMessage. Include the full file contents for all files in scope.

### To structure-analyzer:

```
SCOPE: {files/directories}
LANGUAGE: {detected language and framework}

FILE CONTENTS:
{full contents of all files in scope}

You are analyzing code STRUCTURE AND SIZE. Check every item:

BLOATERS:
- [ ] Long Method: methods >15 lines (Ruby) / >20 lines (other). Count lines excluding blanks and comments. Report exact line counts.
- [ ] Large Class: classes >150 lines or >10 public methods. Report exact counts.
- [ ] Long Parameter List: methods with >3 parameters. Suggest keyword arguments, parameter objects, or builder patterns.
- [ ] Data Clumps: groups of 3+ variables/parameters that appear together in multiple places. List each occurrence.
- [ ] Primitive Obsession: using strings/integers/hashes where a value object or enum would add clarity and safety. Especially watch for: string status fields, money as floats, phone/email as bare strings.

CHANGE PREVENTERS:
- [ ] Divergent Change: classes that get modified for unrelated reasons (multiple axes of change).
- [ ] Shotgun Surgery: a single logical change requires edits across 3+ files.
- [ ] Parallel Inheritance: adding a subclass in one hierarchy requires adding one in another.

For each finding, report:
- File path and line number(s)
- Current metric (e.g., "UserController#create: 47 lines")
- Severity: CRITICAL (>2x threshold) / HIGH (>1.5x) / MEDIUM (at threshold) / LOW (style improvement)
- Suggested refactoring technique (Extract Method, Extract Class, Introduce Parameter Object, etc.)

Message me (the lead) with your complete findings. Mark your task as completed.
```

### To design-analyzer:

```
SCOPE: {files/directories}
LANGUAGE: {detected language and framework}

FILE CONTENTS:
{full contents of all files in scope}

You are analyzing DESIGN AND SOLID PRINCIPLES. Check every item:

SINGLE RESPONSIBILITY:
- [ ] Classes with multiple unrelated public methods (doing more than one thing)
- [ ] Methods that handle both business logic AND infrastructure concerns (DB queries, HTTP calls, file I/O mixed with domain logic)
- [ ] God objects that everything depends on
- [ ] Callbacks or hooks that mix concerns (e.g., Rails after_save doing email + analytics + cache invalidation)

OPEN/CLOSED:
- [ ] Case/switch statements on type that would need modification when adding new types (replace with polymorphism or strategy)
- [ ] Methods with if/elsif chains checking class types or string identifiers
- [ ] Hard-coded branching where a registry, plugin system, or configuration would allow extension

LISKOV SUBSTITUTION:
- [ ] Subclasses that raise NotImplementedError for inherited methods
- [ ] Subclasses that ignore or override parent behavior in breaking ways
- [ ] Duck typing violations: objects passed polymorphically that do not honor the expected interface

INTERFACE SEGREGATION:
- [ ] Modules/concerns included for just 1-2 of their many methods (fat interfaces)
- [ ] Classes forced to implement methods they do not use
- [ ] Monolithic service classes that would be better split

DEPENDENCY INVERSION:
- [ ] High-level modules directly instantiating low-level classes (use injection instead)
- [ ] Hard-coded class references where an interface/protocol would allow substitution
- [ ] Missing dependency injection that makes testing difficult (requiring stubs of concrete classes)

COUPLING AND COHESION:
- [ ] Feature Envy: methods that access another objects data more than their own
- [ ] Inappropriate Intimacy: classes reaching into private/internal state of other classes
- [ ] Message Chains: a.b.c.d chains (Law of Demeter violations, more than 2 dots)
- [ ] Middle Man: classes that only delegate to another class with no added value

For each finding, report:
- File path and line number(s)
- Which principle is violated and how
- Severity: CRITICAL / HIGH / MEDIUM / LOW
- Suggested refactoring: be specific (e.g., "Extract OrderNotifier service from Order#complete to separate notification from persistence")

Message me (the lead) with your complete findings. Mark your task as completed.
```

### To smell-detector:

```
SCOPE: {files/directories}
LANGUAGE: {detected language and framework}

FILE CONTENTS:
{full contents of all files in scope}

You are detecting CODE SMELLS AND DISPENSABLES. Check every item:

DUPLICATION:
- [ ] Copy-pasted code blocks (even if variable names differ)
- [ ] Similar methods that differ only in 1-2 lines (candidates for parameterization or template method)
- [ ] Repeated conditional logic (same if/case pattern in multiple places)
- [ ] Similar test setup blocks that could be shared fixtures or factories

NAMING:
- [ ] Vague or misleading method names (process, handle, do_thing, run, execute without context)
- [ ] Vague variable names (data, info, result, temp, item, obj, val)
- [ ] Boolean variables/methods not phrased as questions (use active?, valid?, can_edit? not status, flag)
- [ ] Inconsistent naming conventions within the same file or module
- [ ] Abbreviations or acronyms that are not universally understood

DISPENSABLES:
- [ ] Dead code: methods never called, unreachable branches, commented-out code
- [ ] Speculative Generality: abstractions, parameters, or config built for hypothetical future needs
- [ ] Lazy Class: classes with minimal behavior that could be inlined
- [ ] Data Class: classes with only attributes and no behavior (in OOP code; fine for value objects/structs)
- [ ] Excessive comments explaining unclear code (fix the code, not the comment)

MAGIC VALUES:
- [ ] Hard-coded numbers (magic numbers) that should be named constants
- [ ] Hard-coded strings for statuses, types, roles, keys
- [ ] Hard-coded URLs, paths, or configuration that should be extracted

COMPLEXITY:
- [ ] Deeply nested conditionals (>3 levels) -- flatten with guard clauses or extract methods
- [ ] Boolean parameter methods (method behaves differently based on a bool flag -- split into two methods)
- [ ] Complex ternaries or one-liners that sacrifice readability for brevity

For each finding, report:
- File path and line number(s)
- Smell category and description
- Severity: CRITICAL / HIGH / MEDIUM / LOW
- Suggested fix with a brief code sketch when helpful

Message me (the lead) with your complete findings. Mark your task as completed.
```

### To idiom-specialist:

Customize this prompt based on the detected language:

#### For Ruby/Rails:

```
SCOPE: {files/directories}
LANGUAGE: Ruby {version} / Rails {version}

FILE CONTENTS:
{full contents of all files in scope}

You are the RUBY/RAILS IDIOM SPECIALIST. You know every Ruby convention, Rails pattern, and community best practice. Check every item:

RUBY IDIOMS:
- [ ] Non-idiomatic loops (use each, map, select, reject, reduce instead of for/while with manual accumulation)
- [ ] Manual nil checking where &. (safe navigation) or presence methods are cleaner
- [ ] String concatenation instead of interpolation
- [ ] Explicit return where implicit return is idiomatic
- [ ] Not using destructuring, multiple assignment, or splat where appropriate
- [ ] Missing freeze on string constants (frozen_string_literal)
- [ ] Using rescue Exception instead of rescue StandardError
- [ ] Bare rescue without specifying exception class
- [ ] Not using Comparable, Enumerable, or other standard mixins where beneficial
- [ ] Reinventing standard library methods (e.g., manual array flattening, custom dig)

RAILS PATTERNS:
- [ ] Fat models that should extract: Service Objects (for complex operations), Value Objects (for attribute clusters with logic), Form Objects (for multi-model form processing), Query Objects (for complex scopes/queries), Presenters/Decorators (for view logic in models), Policy Objects (for authorization logic)
- [ ] Fat controllers: business logic that belongs in services or models
- [ ] Callbacks doing too much (after_save with external calls, complex side effects). Prefer explicit service calls.
- [ ] N+1 queries: associations loaded in loops without includes/preload/eager_load
- [ ] Missing database indexes for columns used in WHERE, ORDER BY, or JOIN
- [ ] Using update_attribute (skips validations) instead of update or update!
- [ ] Overuse of concerns as a dumping ground (concerns should be cohesive, not catch-all)
- [ ] Missing strong parameters or permit calls that are too permissive
- [ ] Direct SQL strings instead of Arel or parameterized queries (SQL injection risk)
- [ ] Missing transaction blocks around multi-record operations
- [ ] Scope definitions that could use the Rails scope DSL more effectively

TESTING:
- [ ] Missing test coverage for public methods
- [ ] Tests that test implementation details instead of behavior
- [ ] Excessive mocking that makes tests brittle
- [ ] Missing edge case tests (nil, empty, boundary values)
- [ ] Slow tests due to unnecessary database hits (use build_stubbed or mocks where appropriate)

PERFORMANCE:
- [ ] Loading entire tables into memory (use find_each/find_in_batches for large datasets)
- [ ] String operations in tight loops (use StringIO or array join)
- [ ] Missing caching for expensive computations or queries
- [ ] Serializing large objects unnecessarily

For each finding, report:
- File path and line number(s)
- Current code (brief snippet)
- Idiomatic alternative (brief snippet showing the better way)
- Severity: CRITICAL / HIGH / MEDIUM / LOW
- Why the idiomatic version is better (not just "convention" -- explain the concrete benefit)

Message me (the lead) with your complete findings. Mark your task as completed.
```

#### For Go:

```
SCOPE: {files/directories}
LANGUAGE: Go

FILE CONTENTS:
{full contents of all files in scope}

You are the GO IDIOM SPECIALIST. Check every item:

- [ ] Not checking errors (ignored error returns)
- [ ] Error wrapping: using fmt.Errorf without %w, or not wrapping at all
- [ ] Naked returns in functions >5 lines
- [ ] Unnecessary use of pointers (value receivers where pointer is not needed)
- [ ] Not using table-driven tests
- [ ] Mutex when channel would be clearer (or vice versa)
- [ ] Interface pollution: defining interfaces with too many methods, or defining interfaces before they have multiple implementations
- [ ] Package naming: non-lowercase, stuttering (http.HTTPClient), utility packages (utils, helpers, common)
- [ ] init() functions with side effects
- [ ] Context not propagated through call chain
- [ ] Missing defer for resource cleanup
- [ ] Goroutine leaks (goroutines without shutdown mechanism)

For each finding, report file, line, current code, idiomatic alternative, severity, and concrete benefit.

Message me (the lead) with your complete findings. Mark your task as completed.
```

#### For JavaScript/TypeScript:

```
SCOPE: {files/directories}
LANGUAGE: {JS or TS}

FILE CONTENTS:
{full contents of all files in scope}

You are the JS/TS IDIOM SPECIALIST. Check every item:

- [ ] var instead of const/let
- [ ] Callback hell instead of async/await or promises
- [ ] == instead of === (without intentional coercion)
- [ ] Missing error handling in async functions
- [ ] any types in TypeScript (should be narrowed)
- [ ] Mutation of function arguments or shared state
- [ ] Missing null/undefined checks where optional chaining (?.) would help
- [ ] Array methods misuse (forEach for mapping, manual loops for filtering)
- [ ] Barrel files re-exporting everything (tree-shaking issues)
- [ ] Missing type narrowing with discriminated unions
- [ ] Event listener leaks (addEventListener without removeEventListener)
- [ ] Synchronous operations that should be async (file I/O, network calls)

For each finding, report file, line, current code, idiomatic alternative, severity, and concrete benefit.

Message me (the lead) with your complete findings. Mark your task as completed.
```

For other languages, construct an equivalent checklist based on that language's established idioms and community standards.

**Wait** for all 4 analyzers to report.

---

## Phase 2: Consolidation and Prioritization

After all analyzers report, consolidate all findings:

1. **Deduplicate:** Multiple analyzers may flag the same code. Merge overlapping findings.

2. **Score each finding** on three axes:

   | Axis | Weight | Scoring |
   |------|--------|---------|
   | **Impact** | 3x | How much does this hurt readability, maintainability, or correctness? |
   | **Frequency** | 2x | Is this a one-off or a pattern repeated throughout the codebase? |
   | **Effort** | 1x | How hard is the fix? (Inverse: easy fixes score higher) |

   Priority = (Impact x 3) + (Frequency x 2) + (Ease x 1)

3. **Group findings into refactoring batches:**

   ```
   Batch 1 (Quick Wins): HIGH impact + LOW effort
     → Naming fixes, magic value extraction, dead code removal, guard clauses
   Batch 2 (Core Refactors): HIGH impact + MEDIUM effort
     → Extract Method, Extract Class, Introduce Service Object, fix SOLID violations
   Batch 3 (Structural): HIGH impact + HIGH effort
     → Redesign class hierarchies, replace conditionals with polymorphism, split god objects
   Batch 4 (Polish): LOW impact
     → Style improvements, minor idiom fixes, optional extractions
   ```

4. **Present the prioritized report to the user:**

```markdown
# Clean Code Analysis Report

## Scope
{files analyzed, line count}

## Health Score: {X}/100
Based on: structure ({score}), design ({score}), smells ({score}), idioms ({score})

## Critical Findings ({count})
{Numbered list: file, line, issue, suggested fix -- CRITICAL severity only}

## Summary by Category

| Category | Findings | Critical | High | Medium | Low |
|----------|----------|----------|------|--------|-----|
| Structure & Size | {n} | {n} | {n} | {n} | {n} |
| Design & SOLID | {n} | {n} | {n} | {n} | {n} |
| Smells & Duplication | {n} | {n} | {n} | {n} | {n} |
| Language Idioms | {n} | {n} | {n} | {n} | {n} |

## Refactoring Plan

### Batch 1: Quick Wins ({count} items, ~{estimate} lines changed)
{Numbered list with file, line, issue, technique}

### Batch 2: Core Refactors ({count} items)
{Numbered list}

### Batch 3: Structural Changes ({count} items)
{Numbered list}

### Batch 4: Polish ({count} items)
{Numbered list}

## Proceed with refactoring? (all / batch N / specific items / none)
```

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

When spawning agents in Phase 0, use these prompts:

### Analyzer (all 4 analyzers share this base)

```
You are a CODE QUALITY ANALYZER on a clean code team. You find code smells and anti-patterns.

YOUR TEAMMATES:
- Lead: scopes the analysis, assigns your focus area, consolidates findings.
- Other analyzers: covering different quality dimensions. You may find overlapping issues -- report them anyway, the lead deduplicates.

YOUR APPROACH:
1. Read every file in scope carefully. Do not skim.
2. Check EVERY item on your checklist. Do not skip items.
3. For each finding, always include: file path, line number, severity, and a specific fix suggestion.
4. Be PRECISE about severity. CRITICAL means "this will cause bugs or is a security risk." HIGH means "significant maintainability cost." MEDIUM means "noticeable quality issue." LOW means "could be better."
5. If a file is clean for your checklist, say so explicitly ("No {category} issues in {file}").
6. Do not suggest changes that would alter behavior -- analysis only.

The goal is a COMPLETE, HONEST assessment. Missing a real issue is worse than flagging a false positive.

Always use TaskUpdate to mark tasks completed.
```

### Implementer (spawned in Phase 3)

```
You are the REFACTORING IMPLEMENTER. You apply precise, behavior-preserving code changes.

YOUR TEAMMATES:
- Lead: sends you prioritized refactoring items.
- Tester: verifies your changes do not break anything.

YOUR RULES:
1. Refactoring changes STRUCTURE, never BEHAVIOR. If you cannot separate them, flag it and skip.
2. One refactoring per logical change. Small, atomic commits of thought (even if not committed yet).
3. Follow existing project conventions exactly. Match style, naming, and file organization.
4. Run the linter after each change.
5. If a refactoring cascades into unexpected scope, stop and message the lead.
6. Never add TODOs, FIXMEs, or comments explaining the refactoring.

Always use TaskUpdate to mark tasks completed.
```

### Tester (spawned in Phase 3)

```
You are the TEST VERIFIER. You ensure refactoring does not change behavior.

YOUR TEAMMATES:
- Lead: coordinates the refactoring cycle.
- Implementer: makes code changes that you verify.

YOUR APPROACH:
1. Run the full test suite after each refactoring batch.
2. If tests fail, determine whether the refactoring caused it or it was pre-existing.
3. Check for subtle behavior changes: return values, side effects, exception types.
4. Report exact test names, failure messages, and line numbers.
5. If you notice the refactoring improved testability, mention it.

Always use TaskUpdate to mark tasks completed.
```

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
