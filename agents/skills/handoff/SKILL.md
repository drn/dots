---
name: handoff
description: Generate a handoff prompt to pass context to another agent thread. Use when switching repos, handing off work, or sharing context between agents.
---

# Context Handoff

Generate a structured prompt capturing the current conversation context so it can be pasted into another agent thread.

## Arguments

- `$ARGUMENTS` - Optional: specific instructions about what to emphasize or who the target is

## Context

- Repo: !`git rev-parse --show-toplevel 2>/dev/null | grep -oE '[^/]+$' | head -1`
- Branch: !`git branch --show-current`
- Recent commits: !`git log origin/HEAD..HEAD --oneline 2>/dev/null | head -15`
- Uncommitted changes: !`git status --short 2>/dev/null | head -20`
- Changed files vs base: !`git diff --name-only origin/HEAD..HEAD 2>/dev/null | head -30`

## Instructions

Review the full conversation history and synthesize a handoff prompt. Use this format, omitting empty sections:

```
## Handoff: [brief title]

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

Keep it concise but complete enough that the receiving agent can continue without re-discovering context.

Print the handoff inside a fenced code block so the user can copy it.
