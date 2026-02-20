---
description: Multi-agent parallel research with peer-challenged synthesis
---

# Parallel Research & Exploration

Spawn multiple researchers to investigate different angles of a question in parallel. They challenge each other's findings before the lead synthesizes a final report.

## Prerequisites

Agent teams must be enabled in Claude Code settings:

```
CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

If agent teams are not enabled, report: "Agent teams required. Add `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` to your Claude Code settings (env section)." and stop.

## Arguments

- `$ARGUMENTS` - Required: the question, topic, or codebase area to explore

If no arguments are provided, ask the user what they want to understand.

## Context

- Current branch: !`git branch --show-current`
- Project root: !`pwd`
- Project type: !`ls -1 go.mod Gemfile package.json Cargo.toml pyproject.toml setup.py requirements.txt pom.xml build.gradle Makefile 2>/dev/null | head -5`
- Directory structure: !`find . -maxdepth 2 -type d -not -path '*/\.*' -not -path '*/node_modules/*' -not -path '*/vendor/*' | head -30`

## Overview

You are the **lead researcher** coordinating an exploration team. Your job is to break a question into research angles, assign them, moderate peer review of findings, and synthesize a final report.

**Research question:** $ARGUMENTS

You do NOT research yourself. You decompose the question, assign angles, moderate challenges, and synthesize.

**Why teams:** Researchers share findings with each other and challenge weak conclusions. A researcher who found "the cache is in Redis" gets corrected by another who found "actually it's Memcached in this service." This peer-challenge step filters out wrong conclusions before they reach the final report.

---

## Phase 0: Setup

1. **Analyze the question** and break it into 3-4 distinct research angles. Each angle should:
   - Cover a different aspect of the question
   - Be independently investigable
   - Produce findings useful to the other researchers

   Example for "How does authentication work in this app?":
   - Angle 1: Auth flow (login, session management, token lifecycle)
   - Angle 2: Authorization model (roles, permissions, middleware)
   - Angle 3: Security posture (password hashing, CSRF, rate limiting)
   - Angle 4: Integration points (OAuth providers, SSO, API keys)

2. **Present the research angles to the user** before proceeding.

3. **Create the team** (clean up stale session first if needed):
   ```
   TeamDelete() -- ignore if no existing team
   TeamCreate(team_name: "explore-session", description: "Explore: {brief topic}")
   ```

4. **Create the task list** with TaskCreate:
   - One research task per angle (e.g., "Research: auth flow")
   - One peer review task PER researcher (e.g., "Peer review: researcher-1 findings"), each blocked by ALL research tasks
   - "Synthesize report" -- blocked by all peer review tasks

5. **Spawn researchers:** One per angle. Use `model: "sonnet"` for all. Spawn all in a single message.

---

## Phase 1: Independent Research

Send each researcher their assignment via SendMessage:

```
RESEARCH QUESTION: {overall question from $ARGUMENTS}

YOUR ANGLE: {specific angle assigned to this researcher}

OTHER ANGLES BEING RESEARCHED:
{list each angle and its researcher}

INSTRUCTIONS:
1. Explore the codebase thoroughly for your angle. Read relevant files, trace code paths, check configuration.
2. Document your findings with specific evidence:
   - File paths and line numbers
   - Code snippets that support your conclusions
   - How components connect and interact
3. Note any UNCERTAINTIES -- things you're not sure about.
4. Note any CONTRADICTIONS -- things that don't make sense or seem inconsistent.
5. When done, message me (the lead) with your findings.

DO NOT message other researchers yet -- save that for the peer review phase.

Mark your research task as completed.
```

**Wait** for all researchers to report.

---

## Phase 2: Peer Challenge

Once all researchers have reported, share everyone's findings with everyone:

Send to each researcher individually (customize with their findings):

```
All research is complete. Now CHALLENGE each other's findings.

YOUR FINDINGS:
{this researcher's own findings}

OTHER RESEARCHERS' FINDINGS:
{all other findings, attributed by researcher name}

INSTRUCTIONS:
1. Read every other researcher's findings carefully.
2. Look for:
   - CONTRADICTIONS between your findings and theirs
   - INCORRECT conclusions (you found evidence that disproves their claim)
   - GAPS in their research (they missed something you know about from your angle)
   - CONFIRMATIONS (your findings support theirs -- note this too)
3. Message each researcher DIRECTLY with your challenges or confirmations.
4. When another researcher challenges YOUR findings:
   - Re-investigate if needed
   - Acknowledge if they're right
   - Defend with evidence if you disagree
5. After debate, message me (the lead) with:
   - Corrections to your original findings (if any)
   - Corrections to others' findings (with evidence)
   - Your confidence level: HIGH / MEDIUM / LOW for each of your claims

Mark YOUR peer review task as completed (not someone else's).
```

**Wait** for the peer challenge to conclude. Allow time for back-and-forth debate.

### Decision Point

```
IF peer challenge revealed MAJOR GAPS (entire areas unresearched):
  → Create targeted follow-up tasks for the researchers who have capacity
  → Wait for follow-up, then proceed to Phase 3

IF findings are reasonably complete:
  → Proceed to Phase 3
```

---

## Phase 3: Synthesis and Summary

1. **Shut down all researchers:**
   ```
   For each researcher:
     SendMessage(type: "shutdown_request", recipient: {name}, content: "Research complete.")
   ```
   Wait for confirmations.

2. **Clean up the team** with TeamDelete.

3. **Synthesize the final report** from all findings, incorporating corrections from the peer challenge phase:

```markdown
## Research Report: {topic}

### Question
{original research question}

### Summary
{3-5 sentence executive summary answering the question}

### Findings by Angle

#### {Angle 1 name}
{Key findings with evidence. Note confidence level.}

**Key files:**
- `path/to/file:line` -- {what it does}

#### {Angle 2 name}
{Key findings with evidence.}

**Key files:**
- `path/to/file:line` -- {what it does}

#### {Angle 3 name}
{findings...}

#### {Angle 4 name} (if applicable)
{findings...}

### Corrections from Peer Review
{List any findings that were corrected during the challenge phase, with explanation}

### Open Questions
{Anything unresolved or uncertain, with pointers for further investigation}

### Architecture Diagram (if applicable)
{ASCII or markdown diagram showing how components connect}
```

---

## Agent Briefing Template

When spawning researchers in Phase 0, use this prompt for all:

```
You are a RESEARCHER on an exploration team. You investigate and document.

YOUR TEAMMATES:
- Lead: assigns research angles, moderates debate, synthesizes report.
- Other researchers: investigating different angles. You will CHALLENGE their findings and they will challenge yours.

YOUR APPROACH:
1. RESEARCH PHASE: Investigate your assigned angle thoroughly. Read files, trace code, document with evidence. Report to the lead.
2. PEER REVIEW PHASE: Read all other findings. Challenge wrong conclusions with evidence. Defend yours or correct them. Message other researchers directly.
3. Be specific: always cite file paths, line numbers, and code snippets.
4. Be honest: mark uncertainties as uncertain. Correct your own mistakes.

The goal is ACCURACY, not speed. One correct finding is worth more than ten unverified claims.

Always use TaskUpdate to mark tasks completed.
```

---

## Failure Handling

| Failure | Action |
|---------|--------|
| Agent fails to spawn | Retry once. Proceed with fewer researchers -- merge the missing angle into another researcher's scope. |
| Researcher finds nothing for their angle | That's a valid finding ("this codebase has no X"). Include in report. |
| Peer challenge reveals major gaps | Assign targeted follow-up research before synthesis. |
| Peer challenge reveals major contradictions | Lead investigates the specific contradiction directly (reads the files in question) to break the tie. |
| Researchers can't agree | Lead makes a judgment call based on evidence. Note the disagreement in the report. |
| Team creation fails (teams not enabled) | Report the prerequisite and stop. |
