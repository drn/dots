---
name: debug
description: Multi-agent competing hypotheses debugging
---

# Competing Hypotheses Debugging

Spawn multiple investigators to debug a problem in parallel. Each pursues a different theory and they argue with each other to converge on the root cause.

## Prerequisites

Agent teams must be enabled in Claude Code settings:

```
CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

If agent teams are not enabled, report: "Agent teams required. Add `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` to your Claude Code settings (env section)." and stop.

## Arguments

- `$ARGUMENTS` - Required: description of the bug, failing test, error message, or unexpected behavior

If no arguments are provided, ask the user what they're debugging.

## Context

- Current branch: !`git branch --show-current`
- Git status: !`git status --short`
- Project root: !`pwd`
- Project type: !`ls -1 go.mod Gemfile package.json Cargo.toml pyproject.toml setup.py requirements.txt pom.xml build.gradle Makefile 2>/dev/null | head -5`
- Recent commits: !`git log --oneline -10`
- Test files: !`find . -maxdepth 4 -name "*_test.*" -o -name "*.test.*" -o -name "*_spec.*" 2>/dev/null | head -10`

## Overview

You are the **lead investigator** coordinating a debugging team. Your job is to formulate hypotheses, assign them to investigators, moderate the debate, and produce a root cause analysis.

**Problem to debug:** $ARGUMENTS

You do NOT investigate yourself. You formulate hypotheses, assign them, moderate debate, and synthesize findings.

**Why this works:** A single agent investigating a bug tends to anchor on the first plausible explanation. Multiple agents pursuing different theories in parallel, then actively trying to disprove each other, surface the actual root cause faster.

---

## Phase 0: Setup

1. **Clean working tree:** If there are uncommitted changes, commit them with message `"WIP: pre-debug-session state"` before proceeding.

2. **Analyze the problem** from `$ARGUMENTS` and the context above.

3. **Formulate 3 hypotheses** for what might be causing the bug. Each hypothesis should be:
   - Plausible given the symptoms
   - Distinct from the others (different root causes, not variations of the same idea)
   - Testable (there's a way to prove or disprove it)

   Present the hypotheses to the user before proceeding.

4. **Create the team** (clean up stale session first if needed):
   ```
   TeamDelete() -- ignore if no existing team
   TeamCreate(team_name: "debug-session", description: "Debug: {brief problem summary}")
   ```

5. **Create the task list** with TaskCreate:
   - "Investigate hypothesis 1: {brief}" -- for investigator-1
   - "Investigate hypothesis 2: {brief}" -- for investigator-2
   - "Investigate hypothesis 3: {brief}" -- for investigator-3

6. **Spawn 3 investigators** in a single message with 3 Task tool calls. Use the agent briefing below. Use `model: "sonnet"` for all investigators.

---

## Phase 1: Investigation

Send each investigator their assignment via SendMessage:

### To each investigator:

```
PROBLEM: {full problem description from $ARGUMENTS}

YOUR HYPOTHESIS: {the specific hypothesis assigned to this investigator}

OTHER HYPOTHESES BEING INVESTIGATED:
- investigator-1: {hypothesis 1}
- investigator-2: {hypothesis 2}
- investigator-3: {hypothesis 3}

INSTRUCTIONS:
1. Explore the codebase to gather evidence FOR your hypothesis.
2. Also look for evidence AGAINST your hypothesis -- be honest.
3. Try to reproduce the bug if possible.
4. Check git history for recent changes related to your hypothesis.
5. When you have findings, share them with ALL other investigators:
   - Message each investigator directly with your evidence.
   - Explain what you found and how it supports or undermines your theory.
6. Read and respond to other investigators' findings:
   - If their evidence contradicts your hypothesis, acknowledge it.
   - If you can poke holes in their theory, do so with evidence.
   - If you become convinced another hypothesis is correct, say so.

After investigation and debate, message me (the lead) with:
- Your verdict: CONFIRMED, DISPROVED, or INCONCLUSIVE
- Key evidence (file paths, line numbers, reproduction steps)
- Whether you now support a different hypothesis

Mark your task as completed.
```

**Wait** for all investigators to report. Allow time for peer debate -- don't rush this phase.

---

## Phase 2: Convergence

Collect all reports and assess:

```
IF investigators converged on a single root cause:
  → Proceed to Phase 3 with that cause

IF two or more theories remain plausible:
  → Send a tiebreaker prompt (see below)

IF all hypotheses disproved:
  → Formulate new hypotheses based on evidence gathered, return to Phase 1
     (max 2 total rounds)
```

### Tiebreaker prompt (send to all remaining investigators):

```
We have competing theories. Let's settle this.

REMAINING HYPOTHESES:
{list the hypotheses still standing with evidence for each}

INSTRUCTIONS:
1. Design a SPECIFIC test that would distinguish between these theories.
   (e.g., "If hypothesis A is correct, then X should happen when we do Y.
    If hypothesis B is correct, Z should happen instead.")
2. Run that test or trace through the code to determine the outcome.
3. Share your results with all other investigators.
4. Message me with your final verdict.
```

**Wait** for convergence.

---

## Phase 3: Fix

Once the root cause is identified:

1. **Create fix tasks:**
   - "Implement fix for: {root cause}" -- assign to the investigator who identified it (they have the most context)
   - "Verify fix" -- for a second investigator, blocked by fix
   - "Check for regressions" -- for the third investigator, blocked by fix

2. **Send fix request to the assigned investigator:**

```
ROOT CAUSE CONFIRMED: {description}

Implement a fix. Keep it minimal -- fix the bug, nothing more.
Run any related tests to verify.
When done, message me with your changes.
```

3. **Send verification request to the second investigator:**

```
{investigator name} is implementing a fix for: {root cause}

Once they finish, review their fix:
- Does it actually address the root cause?
- Could it introduce new issues?
- Run the relevant tests to confirm.

Message me with your verification results.
```

4. **Send regression check to the third investigator:**

```
{investigator name} is implementing a fix for: {root cause}

Once they finish, check for broader regressions:
- Run the full test suite (not just the targeted tests).
- Look for any code that depends on the behavior being changed.
- Check if similar patterns exist elsewhere that might have the same bug.

Message me with your regression analysis.
```

**Wait** for all three to complete.

---

## Phase 4: Shutdown and Summary

1. **Shut down all investigators:**
   ```
   For each investigator:
     SendMessage(type: "shutdown_request", recipient: {name}, content: "Investigation complete.")
   ```
   Wait for confirmations.

2. **Clean up the team** with TeamDelete.

3. **Produce the investigation report:**

```markdown
## Debug Report

### Problem
{original problem description}

### Root Cause
{1-2 sentences explaining the root cause}

### Investigation

| Hypothesis | Investigator | Verdict | Key Evidence |
|------------|-------------|---------|--------------|
| {hypothesis 1} | investigator-1 | CONFIRMED / DISPROVED | {1-line} |
| {hypothesis 2} | investigator-2 | CONFIRMED / DISPROVED | {1-line} |
| {hypothesis 3} | investigator-3 | CONFIRMED / DISPROVED | {1-line} |

### How It Was Found
{Brief narrative of how the team converged: which evidence was decisive, what disproved the wrong theories}

### Fix Applied
| File | Change | Description |
|------|--------|-------------|
| path/to/file | modified | brief description |

### Verification
- **Tests pass:** YES / NO
- **Verified by:** {investigator name}
- **Regression check:** {investigator name} -- {result}
- **Regression risk:** {low/medium/high with explanation}

### Diff
{git diff --stat output}
```

---

## Agent Briefing Template

When spawning investigators in Phase 0, use this prompt for all 3:

```
You are an INVESTIGATOR on a debugging team. You find root causes.

YOUR TEAMMATES:
- Lead: assigns hypotheses, moderates debate, synthesizes findings.
- Other investigators: pursuing different theories. You DEBATE with them.

YOUR APPROACH:
1. Gather evidence for AND against your hypothesis.
2. Share findings with other investigators via direct messages.
3. Challenge their theories with evidence. Accept challenges to yours.
4. If your theory is disproved, pivot -- help validate or disprove others.
5. Be specific: cite file paths, line numbers, and reproduction steps.
6. If you find the root cause, you may be asked to implement a fix, verify a fix, or check for regressions.

The goal is TRUTH, not winning. Abandon your hypothesis the moment
evidence disproves it.

Always use TaskUpdate to mark tasks completed.
```

---

## Failure Handling

| Failure | Action |
|---------|--------|
| Agent fails to spawn | Retry once. Proceed with 2 investigators if needed. |
| All hypotheses disproved (round 1) | Formulate new hypotheses based on gathered evidence. Run a second round. |
| All hypotheses disproved (round 2) | Produce report with evidence gathered. Suggest next steps for manual investigation. |
| Investigators can't converge | Lead makes a judgment call based on evidence weight. Note uncertainty in report. |
| Bug can't be reproduced | Document the investigation and evidence. Note reproduction difficulty in report. |
| Team creation fails (teams not enabled) | Report the prerequisite and stop. |
