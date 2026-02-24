---
description: Code review panel for current branch changes
---

# Code Review Panel

Run a comprehensive code review (security, architecture, clarity) against your current changes.

## Arguments

- `$ARGUMENTS` - Optional: branch or commit range to review (defaults to current branch vs main/master)

## Context

- Current branch: !`git branch --show-current`
- Default branch ref: !`git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | head -1`
- Changes: !`git diff --stat HEAD...origin/HEAD 2>/dev/null | head -50`

## Instructions

You run a code review and produce a consolidated report.

### Step 1: Determine Review Scope

```
IF $ARGUMENTS contains a branch name or commit range:
  Use that as the review scope
ELSE:
  Review current branch changes vs the default branch (main/master)
```

Gather the diff:
```bash
git diff {base}...HEAD        # full diff
git diff {base}...HEAD --name-only  # changed files
```

If there are no changes to review, tell the user and stop.

### Step 2: Read Changed Files

Read the full content of each changed file for context. The reviewer needs to see the code around the changes, not just the diff.

### Step 3: Launch Reviewer

Use 1 Task tool call with `subagent_type="general-purpose"`, `model: "sonnet"`:

```
Review the following code changes for security, architecture, and clarity.

DIFF:
{full diff}

CHANGED FILES:
{full file contents}

CHECK EACH -- SECURITY:
- Injection flaws (SQL, command, LDAP, XPath)
- Authentication/authorization issues
- Sensitive data exposure (secrets, PII, credentials in code or logs)
- Input validation and sanitization
- XSS potential
- Insecure deserialization
- Vulnerable dependencies added
- Error handling exposing internals
- Missing rate limiting
- Insecure direct object references

CHECK EACH -- ARCHITECTURE:
- Single Responsibility Principle
- Separation of concerns
- Dependency direction (abstractions over concretions)
- Coupling level
- Cohesion
- Consistency with existing codebase patterns
- Error handling strategy
- Extensibility for likely changes
- Circular dependencies

CHECK EACH -- CLARITY:
- Function/method naming clarity
- Variable naming
- Comments where logic is non-obvious
- Public API documentation
- Cyclomatic complexity
- Dead code or unreachable branches
- Magic numbers/strings
- Consistent code style
- Log message quality

Classify each finding as:
- BLOCKING: Must fix before merging
- WARNING: Should fix, real risk
- INFO: Improvement suggestion

Tag each finding with its category: [security], [architecture], or [clarity].
If no issues in a category: explicitly state so.

Output your findings grouped by severity (BLOCKING first, then WARNING, then INFO).
```

### Step 4: Produce Consolidated Report

After the reviewer completes, consolidate into:

```markdown
# Code Review: {branch name}

## Summary
{1-2 sentences: what the changes do and overall assessment}

## Blocking Issues
{Numbered list with category tag, file, line, description -- or "None"}

## Warnings
{Numbered list -- or "None"}

## Suggestions
{Numbered list -- or "None"}

## Verdicts
| Category | Verdict | Key Notes |
|----------|---------|-----------|
| Security | PASS / CONCERNS | {1-line} |
| Architecture | PASS / CONCERNS | {1-line} |
| Clarity | PASS / CONCERNS | {1-line} |

## Files Reviewed
{git diff --stat output}
```

If there are blocking issues, note: "Address the blocking issues before merging."
If clean: "Changes look good across all review dimensions."
