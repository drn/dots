---
description: "Re-review with fresh eyes. Zero regressions. Go slow and analyze everything."
---

# Fresh-Eyes Re-Review

Re-review all branch changes from scratch with independent competing reviewers. Designed for when you need absolute confidence before merging -- no regressions, no blind spots.

## Arguments

- `$ARGUMENTS` - Optional: branch or commit range to review (defaults to current branch vs main/master)

## Context

- Current branch: !`git branch --show-current`
- Default branch ref: !`git rev-parse --abbrev-ref origin/HEAD 2>/dev/null | grep -v '^origin/HEAD$' | head -1`
- Git status: !`git status --short`
- Project type: !`ls -1 go.mod Gemfile package.json Cargo.toml pyproject.toml 2>/dev/null | head -5`
- Test framework: !`find . -maxdepth 4 -name "*_test.*" -o -name "*.test.*" -o -name "*_spec.*" 2>/dev/null | head -10`
- Changes: !`git diff --stat HEAD...origin/HEAD 2>/dev/null | head -50`

## Overview

You are the **lead coordinator** for a fresh-eyes re-review. Your job:

1. Gather every change on the branch
2. Run the full test suite to establish a regression baseline
3. Launch 3 independent reviewer sub-agents in parallel -- they do NOT see each other's findings
4. Synthesize their reports, surface disagreements, and produce a final verdict

**Core principle:** This is a slow, paranoid review. Speed does not matter. Thoroughness does. Every changed line must be analyzed. Every behavior change must be justified. If there is any doubt about a regression, it is flagged as BLOCKING.

You do NOT review code yourself. You coordinate and synthesize.

---

## Phase 0: Gather Everything

1. **Determine review scope:**

```
IF $ARGUMENTS contains a branch name or commit range:
  Use that as the review scope
ELSE:
  Review current branch changes vs the default branch (main/master)
```

2. **Collect the full diff and all changed files:**

```bash
git diff {base}...HEAD                    # full diff
git diff {base}...HEAD --name-only        # changed file list
git log --oneline {base}...HEAD           # all commits on this branch
```

3. **Read every changed file in its entirety.** Not just the diff -- the full file. Reviewers need surrounding context to catch regressions.

4. **For each changed file, also identify and read its callers/dependents.** Use Grep to find other files that import, require, or reference the changed files. Read those too. The reviewers need to understand what might break.

If there are no changes to review, tell the user and stop.

---

## Phase 1: Regression Baseline

Before launching reviewers, establish the current test state:

1. **Detect the test framework** from project type:
   - `go.mod` → `go test ./...`
   - `package.json` → `npm test` or `npx jest`
   - `Gemfile` → `bundle exec rspec` or `bundle exec rake test`
   - `Cargo.toml` → `cargo test`
   - `pyproject.toml` → `pytest`

2. **Run the full test suite.** Record the result: PASS, FAIL, or N/A (no tests).

3. **If tests fail:** Note which tests fail. These are pre-existing failures, not regressions. Reviewers need this context.

4. **Run the linter** if available:
   - `go.mod` → `revive -set_exit_status ./...` or `go vet ./...`
   - `package.json` → `npx eslint .` if configured
   - `Gemfile` → `bundle exec rubocop --force-exclusion` if configured
   - `Cargo.toml` → `cargo clippy -- -D warnings`
   - `pyproject.toml` → `ruff check .` if configured

Record lint result: CLEAN, WARNINGS, or ERRORS.

---

## Phase 2: Launch Independent Reviewers

**Launch all 3 reviewers in a single message with 3 parallel Task tool calls.** Each reviewer gets the SAME data but works independently. They MUST NOT see each other's findings.

Use `subagent_type="general-purpose"` and `model: "sonnet"` for all reviewers.

Each Task call should use the reviewer briefing template below, with only the reviewer name changed (ALPHA, BRAVO, CHARLIE).

### Reviewer Briefing Template

```
You are REVIEWER {ALPHA / BRAVO / CHARLIE} performing an independent fresh-eyes code review.

You are one of three independent reviewers. You do NOT see the others' findings. Your analysis must be completely independent.

MANDATE: This review exists to guarantee ZERO REGRESSIONS. Go slow. Analyze everything. When in doubt, flag it.

BRANCH: {branch name}
COMMITS:
{git log output}

FULL DIFF:
{full git diff}

CHANGED FILES (full contents):
{for each changed file, include filename and full contents}

DEPENDENT FILES (files that reference changed code):
{for each dependent file, include filename and full contents}

TEST BASELINE:
- Test suite result: {PASS / FAIL / N/A}
- Pre-existing failures: {list or "None"}
- Lint result: {CLEAN / WARNINGS / ERRORS}

---

Perform ALL of the following analyses. Do not skip any. Take your time.

### Analysis 1: Behavior Change Audit

For EVERY function, method, type, or exported symbol that was modified:

1. What was the old behavior?
2. What is the new behavior?
3. Is this change intentional and justified by the commits?
4. Could any caller of this code break due to the change?
5. Are default values, return types, error conditions, or side effects altered?

If you find ANY behavior change that is not obviously intentional, classify it as BLOCKING.

### Analysis 2: Regression Risk Assessment

For each changed file, answer:

1. What other code depends on this file? (Check the dependent files provided.)
2. Could the change break any dependent code path?
3. Are there edge cases in the old behavior that the new code might not handle?
4. Were any error handling paths changed? Could errors now propagate differently?
5. Were any concurrency patterns (mutexes, channels, locks, async) changed?

### Analysis 3: Security Audit

Check every item -- do not skip any:

- [ ] Injection flaws (SQL, command, LDAP, XPath, template)
- [ ] Authentication/authorization changes
- [ ] Sensitive data exposure (secrets, PII, credentials in code or logs)
- [ ] Input validation and sanitization
- [ ] Cross-site scripting (XSS) potential
- [ ] Insecure deserialization
- [ ] Known vulnerable dependencies added or updated
- [ ] Error handling exposing internals (stack traces, DB info)
- [ ] Missing rate limiting where needed
- [ ] Insecure direct object references
- [ ] Cryptographic misuse (weak algorithms, hardcoded keys, bad randomness)
- [ ] Path traversal possibilities
- [ ] SSRF potential
- [ ] Open redirect potential

### Analysis 4: Architecture and Design

Check every item:

- [ ] Single Responsibility Principle
- [ ] Separation of concerns
- [ ] Dependency direction (abstractions over concretions)
- [ ] Coupling level (as loose as practical?)
- [ ] Cohesion (related things grouped together?)
- [ ] Consistency with existing codebase patterns
- [ ] Error handling strategy consistent with project conventions
- [ ] No circular dependencies introduced
- [ ] No unnecessary complexity added
- [ ] API contracts preserved (function signatures, interfaces, types)

### Analysis 5: Line-by-Line Diff Review

Go through the diff line by line. For each hunk:

1. Is the removed code actually safe to remove? Could anything depend on it?
2. Is the added code correct? Trace the logic manually.
3. Are there off-by-one errors, nil/null pointer risks, or type mismatches?
4. Are boundary conditions handled (empty inputs, zero values, max values)?

### Analysis 6: Test Coverage Gaps

1. Are the behavior changes covered by existing tests?
2. What test cases are missing for the new code?
3. Are error paths tested?
4. Are edge cases tested?

---

## Output Format

Classify every finding as:
- **BLOCKING**: Must fix before merging. Includes: any unintentional behavior change, any regression risk without test coverage, any security issue, any broken API contract.
- **WARNING**: Should fix. Real risk but lower severity.
- **INFO**: Improvement suggestion.

Structure your report EXACTLY as follows:

## Reviewer {ALPHA/BRAVO/CHARLIE} Report

### Behavior Changes Found
| # | File | Symbol/Function | Old Behavior | New Behavior | Intentional? | Verdict |
|---|------|-----------------|--------------|--------------|--------------|---------|
{one row per behavior change, or "No behavior changes detected."}

### Regression Risks
{Numbered list of specific regression risks with file, line, and explanation. Or "None identified."}

### Security Findings
{Numbered list with severity, file, line, description. Or "No security issues found."}

### Architecture Findings
{Numbered list with severity, file, description. Or "Architecture is sound."}

### Line-by-Line Issues
{Numbered list of specific code issues with file, line, description. Or "No line-level issues."}

### Missing Test Coverage
{Numbered list of test gaps. Or "Coverage appears adequate."}

### Summary
- **BLOCKING count:** {N}
- **WARNING count:** {N}
- **INFO count:** {N}
- **Regression confidence:** HIGH / MEDIUM / LOW
  (HIGH = confident no regressions; MEDIUM = some uncertainty; LOW = significant regression risk)
- **Overall verdict:** APPROVE / REQUEST CHANGES / REJECT

Do NOT rush. Analyze every changed line. If you are uncertain about something, flag it -- false positives are acceptable, false negatives are not.
```

**Wait for all 3 reviewer sub-agents to return their reports.**

---

## Phase 3: Synthesis

After all 3 reviewers report, produce the final consolidated report.

### Step 1: Cross-Reference Findings

Compare the three reports:

1. **Unanimous findings** -- flagged by all 3 reviewers. These are high-confidence.
2. **Majority findings** -- flagged by 2 of 3. High confidence, but note the dissenter.
3. **Solo findings** -- flagged by only 1 reviewer. Could be a genuine catch the others missed OR a false positive. Include these with a note.

### Step 2: Identify Disagreements

Where reviewers disagree on severity or verdict:
- Note the disagreement explicitly
- Apply the most conservative (strictest) assessment

### Step 3: Final Verdict Logic

```
IF any reviewer found a BLOCKING issue:
  Final verdict = REQUEST CHANGES
  (even if the other two approved)

IF all three approve with no BLOCKING issues:
  IF any WARNING exists:
    Final verdict = APPROVE WITH WARNINGS
  ELSE:
    Final verdict = APPROVE

Regression confidence = LOWEST of the three reviewers' confidence ratings
```

### Step 4: Produce Final Report

```markdown
# Fresh-Eyes Re-Review: {branch name}

## Verdict: {APPROVE / APPROVE WITH WARNINGS / REQUEST CHANGES}
**Regression confidence:** {HIGH / MEDIUM / LOW}

## Reviewer Agreement
| Reviewer | Blocking | Warnings | Infos | Verdict | Confidence |
|----------|----------|----------|-------|---------|------------|
| Alpha    | {N}      | {N}      | {N}   | {verdict} | {conf}   |
| Bravo    | {N}      | {N}      | {N}   | {verdict} | {conf}   |
| Charlie  | {N}      | {N}      | {N}   | {verdict} | {conf}   |

## Test & Lint Baseline
- **Tests:** {PASS / FAIL / N/A} {details if failures}
- **Lint:** {CLEAN / WARNINGS / ERRORS}

## Behavior Changes
{Consolidated table from all reviewers. Note agreement level for each.}

## Blocking Issues
{Numbered list. Each item notes which reviewers flagged it (e.g., "[All 3]", "[Alpha, Bravo]", "[Charlie only]").}
{Or "None -- all reviewers agree the changes are safe."}

## Warnings
{Numbered list with reviewer attribution.}
{Or "None."}

## Suggestions
{Numbered list with reviewer attribution.}
{Or "None."}

## Disagreements
{Where reviewers differed on severity or verdict. Explain each and note which conservative assessment was applied.}
{Or "All reviewers agreed."}

## Missing Test Coverage
{Consolidated list from all reviewers.}
{Or "Coverage appears adequate."}

## Files Reviewed
{git diff --stat output}

## Commits Reviewed
{git log --oneline output}
```

If the verdict is REQUEST CHANGES: "Address the blocking issues before merging."
If APPROVE WITH WARNINGS: "Safe to merge, but consider addressing the warnings."
If APPROVE: "All three independent reviewers agree: changes are safe, no regressions detected."

---

## Failure Handling

| Failure | Action |
|---------|--------|
| Sub-agent fails to spawn | Retry once. Proceed with 2 reviewers if a third can't start. Note reduced coverage in report. |
| Sub-agent returns empty or malformed report | Note in summary. Proceed with available reports. |
| Test suite fails to run | Note in report. Flag as increased regression risk in the synthesis. |
| No changes to review | Tell the user and stop. |
