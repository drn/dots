---
description: Multi-reviewer code review panel for current branch changes
---

# Code Review Panel

Run three specialized reviewers (security, architecture, clarity) in parallel against your current changes. Produces a consolidated review report.

## Arguments

- `$ARGUMENTS` - Optional: branch or commit range to review (defaults to current branch vs main/master)

## Context

- Current branch: !`git branch --show-current`
- Default branch: !`git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "master"`
- Changes: !`git diff --stat HEAD...$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "master") 2>/dev/null || git diff --stat`

## Instructions

You are running a 3-reviewer code review panel. You coordinate the reviewers and produce a consolidated report.

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

Read the full content of each changed file for context. The reviewers need to see the code around the changes, not just the diff.

### Step 3: Launch 3 Reviewers in Parallel

Use 3 Task tool calls in a single message, each with `subagent_type="general-purpose"`:

#### Security Reviewer

```
Review the following code changes for security vulnerabilities.

DIFF:
{full diff}

CHANGED FILES:
{full file contents}

CHECK EACH:
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

Classify each finding as:
- BLOCKING: Must fix before merging
- WARNING: Should fix, real risk
- INFO: Improvement suggestion

If no issues: explicitly state "No security issues found."

Output your findings in this format:
## Security Review
{findings or "No security issues found."}
```

#### Architecture Reviewer

```
Review the following code changes for design and architecture quality.

DIFF:
{full diff}

CHANGED FILES:
{full file contents}

CHECK EACH:
- Single Responsibility Principle
- Separation of concerns
- Dependency direction (abstractions over concretions)
- Coupling level
- Cohesion
- Consistency with existing codebase patterns
- Error handling strategy
- Extensibility for likely changes
- Circular dependencies

Classify findings as BLOCKING, WARNING, or INFO.
If the design is solid, say so.

Output format:
## Architecture Review
{findings or "Design looks solid."}
```

#### Clarity Reviewer

```
Review the following code changes for readability and maintainability.

DIFF:
{full diff}

CHANGED FILES:
{full file contents}

CHECK EACH:
- Function/method naming clarity
- Variable naming
- Comments where logic is non-obvious
- Public API documentation
- Cyclomatic complexity
- Dead code or unreachable branches
- Magic numbers/strings
- Consistent code style
- Log message quality

Classify findings as BLOCKING, WARNING, or INFO.
If the code is clear, say so.

Output format:
## Clarity Review
{findings or "Code is clear and well-written."}
```

### Step 4: Produce Consolidated Report

After all 3 reviewers complete, consolidate into:

```markdown
# Code Review: {branch name}

## Summary
{1-2 sentences: what the changes do and overall assessment}

## Blocking Issues
{Numbered list with reviewer source, file, line, description -- or "None"}

## Warnings
{Numbered list -- or "None"}

## Suggestions
{Numbered list -- or "None"}

## Reviewer Verdicts
| Reviewer | Verdict | Key Notes |
|----------|---------|-----------|
| Security | PASS / CONCERNS | {1-line} |
| Architecture | PASS / CONCERNS | {1-line} |
| Clarity | PASS / CONCERNS | {1-line} |

## Files Reviewed
{git diff --stat output}
```

If there are blocking issues, note: "Address the blocking issues before merging."
If clean: "Changes look good across all three review dimensions."
