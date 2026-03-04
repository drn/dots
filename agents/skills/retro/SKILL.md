---
name: retro
description: Run a structured retrospective or post-incident review with optional knowledge base capture
---

# Retrospective

Structured retrospective for projects, sprints, or incidents. Captures learnings and optionally persists them to the knowledge base.

## Arguments

- `$ARGUMENTS` - Optional: `--incident` for post-incident template, or a topic/project name

## Context

- Recent commits: !`git log --oneline -20 2>/dev/null | head -20`
- Merged PRs: !`gh pr list --state merged --limit 10 2>/dev/null | head -10`
- Knowledge base: !`cat context/knowledge/index.md 2>/dev/null | head -30`
- Current branch: !`git branch --show-current`

## Instructions

### Step 1: Choose template

IF `--incident` is in `$ARGUMENTS`, use the **Incident template**.
OTHERWISE, use the **Standard template**.

### Step 2: Gather context

Review the recent commits and merged PRs from the context above. Summarize the scope of work that this retro covers. If the user provided a topic, focus on that.

### Step 3: Present and collaborate

#### Standard Template

```markdown
## Retrospective: <topic or date>

### What Went Well
- <positive outcomes, wins, good patterns>

### What Did Not Go Well
- <pain points, friction, mistakes>

### Action Items
- [ ] <concrete next step with owner if applicable>

### Key Learnings
- <insights to carry forward>
```

#### Incident Template

```markdown
## Post-Incident Review: <incident name>

### Timeline
| Time | Event |
|------|-------|
| | <what happened> |

### Impact
- **Users affected:**
- **Duration:**
- **Severity:**

### Root Cause
<what actually caused the issue>

### What Went Well
- <effective response actions>

### What Did Not Go Well
- <gaps in detection, response, or prevention>

### Action Items
- [ ] <concrete remediation with owner and deadline>

### Follow-ups
- [ ] <longer-term improvements>
```

Present the template pre-filled with whatever you can infer from the git context. Ask the user to fill in, correct, or expand each section. Iterate until the user is satisfied.

### Step 4: Knowledge capture (optional)

IF a knowledge base exists (check context above for `context/knowledge/index.md`):
- Propose adding key learnings as a new topic or updating an existing topic
- Only add durable, reusable insights — not session-specific details
- Follow the format in `/knowledge` (bold entity names, standalone facts, date-stamp volatile info)

IF no knowledge base exists, skip this step entirely. Do not suggest creating one.

### Step 5: Save

Offer to:
1. Copy to clipboard
2. Save to `.context/retros/<date>-<slug>.md`
3. Both
