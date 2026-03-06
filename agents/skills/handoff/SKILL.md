---
name: handoff
description: Generate a handoff prompt to pass context to another agent thread. Use when switching repos, handing off work, or sharing context between agents.
---

# Context Handoff

Generate a structured prompt capturing the current conversation context so it can be pasted into another agent thread.

## Arguments

- `$ARGUMENTS` - Optional: specific instructions about what to emphasize or who the target is

## Context

- Repo root: !`git rev-parse --show-toplevel 2>/dev/null | head -1`
- Branch: !`git branch --show-current`
- Base ref: !`git branch -r 2>/dev/null | grep -oE 'origin/(main|master)' | head -1`
- Commits vs main: !`git log origin/main..HEAD --oneline 2>/dev/null | head -15`
- Commits vs master: !`git log origin/master..HEAD --oneline 2>/dev/null | head -15`
- Uncommitted changes: !`git status --short 2>/dev/null | head -20`
- Changed files vs main: !`git diff --name-only origin/main..HEAD 2>/dev/null | head -30`
- Changed files vs master: !`git diff --name-only origin/master..HEAD 2>/dev/null | head -30`

## Instructions

Review the full conversation history and synthesize a handoff prompt. Use this format, omitting empty sections:

```
## Handoff: [brief title]

### Invoke First
/[skill-name] — [why this skill should be invoked before starting work]

### Background
[1-3 sentences on what was being worked on and why]

### What Was Done
- [Completed work with specific file paths]

### Current State
[Branch state, what is working, what is not]

### Key Decisions
- [Decision]: [Rationale]

### Remaining Work
- [ ] [Specific actionable items]

### Important Context
- [Gotchas, constraints, or patterns the next agent needs]
- [Specific file paths, function names, code patterns]

### Files to Read First
- [Ordered list of files to get up to speed]
```

**Invoke First section:** If the remaining work maps to an existing skill (e.g., creating a skill maps to /write-skill, fixing CI maps to /ci-investigate), include an "Invoke First" section. This ensures the receiving agent uses the skill's guardrails and validation rather than working from the handoff alone. Omit this section only if no skill applies.

Keep it concise but complete enough that the receiving agent can continue without re-discovering context.

Print the handoff inside a fenced code block so the user can copy it.

---

## Specialized Templates

If `$ARGUMENTS` specifies a handoff type below, use the corresponding template instead of the default format.

### QA Verdict Handoff

Use when handing off QA results (e.g., `handoff qa pass` or `handoff qa fail`).

```
## QA Verdict: {PASS / FAIL}

### Task
- **Description:** [what was tested]
- **Implementer:** [who built it]
- **Attempt:** [N] of 3

### Evidence
- **Tests:** {PASS / FAIL} -- {details}
- **Lint:** {CLEAN / WARNINGS / ERRORS}

### Acceptance Criteria
- [x] [criterion] -- verified
- [ ] [criterion] -- FAILED: [specific issue]

### Issues Found (FAIL only)
| # | Severity | File | Description | Fix Instruction |
|---|----------|------|-------------|-----------------|

### Next Action
[Who should receive this and what they should do]
```

### Escalation Handoff

Use when handing off a stuck task (e.g., `handoff escalation`).

```
## Escalation: [task description]

### Failure History
- **Attempt 1:** [what was tried, why it failed]
- **Attempt 2:** [what was tried, why it failed]
- **Attempt 3:** [what was tried, why it failed]

### Root Cause Analysis
[Why the task keeps failing -- underlying issue]

### Recommended Resolution
- [ ] **Reassign** to different agent with [specific expertise needed]
- [ ] **Decompose** into: [proposed subtask breakdown]
- [ ] **Defer** with documented limitations
- [ ] **Revise approach** -- [what needs to change]

### Files to Read First
- [ordered list]
```

### Incident Handoff

Use when handing off during incident response (e.g., `handoff incident`).

```
## Incident Handoff: [brief description]

### Severity: [P0 / P1 / P2 / P3]

### Timeline
- [HH:MM] -- [event]

### Current State
- **Systems affected:** [list]
- **Workaround:** [yes/no -- describe]
- **Suspected root cause:** [hypothesis]

### Actions Taken
1. [action and result]

### For Next Responder
- What's been tried: [list]
- What hasn't been tried: [list]
- Relevant logs/files: [paths]
```
