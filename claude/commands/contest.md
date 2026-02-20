---
description: Competing implementations with judge evaluation
---

# Competing Implementations

Spawn multiple implementers to build different solutions to the same problem. A judge evaluates and picks the best one.

## Prerequisites

Agent teams must be enabled in Claude Code settings:

```
CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

If agent teams are not enabled, report: "Agent teams required. Add `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` to your Claude Code settings (env section)." and stop.

## Arguments

- `$ARGUMENTS` - Required: the problem to solve, ideally with evaluation criteria (e.g., "optimize the search function -- prioritize readability over raw speed")

If no arguments are provided, ask the user what they want implemented.

## Context

- Current branch: !`git branch --show-current`
- Git status: !`git status --short`
- Default branch: !`git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "master"`
- Project root: !`pwd`
- Project type: !`ls -1 go.mod Gemfile package.json Cargo.toml pyproject.toml setup.py requirements.txt pom.xml build.gradle Makefile 2>/dev/null | head -5`
- Recent commits: !`git log --oneline -5`
- Test files: !`find . -maxdepth 4 -name "*_test.*" -o -name "*.test.*" -o -name "*_spec.*" 2>/dev/null | head -10`

## Overview

You are the **contest coordinator**. Your job is to frame the problem, assign it to multiple implementers working in separate worktrees, and have a judge pick the winner.

**Problem:** $ARGUMENTS

You do NOT implement or judge yourself. You coordinate the contest.

**Why this works:** For design problems with multiple valid solutions (performance optimization, API design, architecture choices), building 2-3 options and comparing is faster and more reliable than debating hypothetical trade-offs.

---

## Phase 0: Setup

1. **Clean working tree:** If there are uncommitted changes, commit them with message `"WIP: pre-contest state"` before proceeding.

2. **Analyze the problem** and define evaluation criteria. If the user didn't specify criteria, propose them:
   - Correctness (tests pass)
   - Readability / maintainability
   - Performance (if relevant)
   - Simplicity (fewer lines, fewer dependencies)
   - Consistency with existing codebase

   Present criteria to the user for approval.

3. **Define 2-3 distinct approaches.** Each should be:
   - A genuinely different solution strategy (not minor variations)
   - Viable given the codebase and constraints

   Present approaches to the user before proceeding.

4. **Create worktrees** for each contestant (avoids branch checkout conflicts):
   ```bash
   git worktree add /tmp/contest-approach-1 -b contest/approach-1
   git worktree add /tmp/contest-approach-2 -b contest/approach-2
   git worktree add /tmp/contest-approach-3 -b contest/approach-3  # if 3 approaches
   ```

5. **Create the team** (clean up stale session first if needed):
   ```
   TeamDelete() -- ignore if no existing team
   TeamCreate(team_name: "contest-session", description: "Contest: {brief problem summary}")
   ```

6. **Create the task list** with TaskCreate:
   - "Implement approach 1: {brief}" -- for contestant-1
   - "Implement approach 2: {brief}" -- for contestant-2
   - "Implement approach 3: {brief}" -- for contestant-3 (if applicable)
   - "Judge implementations" -- for judge, blocked by all implementation tasks

7. **Spawn all agents** in a single message. Use `model: "sonnet"` for contestants.

---

## Phase 1: Implementation

Send each contestant their assignment via SendMessage:

```
PROBLEM: {full problem description from $ARGUMENTS}

YOUR APPROACH: {the specific approach assigned to this contestant}
YOUR WORKTREE: /tmp/contest-approach-{N}

OTHER APPROACHES (for awareness -- do NOT look at their code):
{list the other approaches and their contestants}

EVALUATION CRITERIA (in priority order):
{numbered list of criteria}

INSTRUCTIONS:
1. Work ONLY in your worktree directory: /tmp/contest-approach-{N}
2. Explore the codebase to understand the current state.
3. Implement your approach. Keep it focused.
4. Run existing tests to ensure nothing breaks.
5. Write new tests for your implementation.
6. Run a sanity check (compile, lint).
7. Commit your changes on your branch.
8. When done, message me (the lead) with:
   - Summary of your approach
   - Trade-offs you chose
   - Test results
   - Why you think your approach is best

DO NOT look at other contestants' worktrees or branches.

Mark your task as completed.
```

**Wait** for all contestants to finish.

---

## Phase 2: Judging

Once all contestants complete:

1. **Gather all implementations:**
   For each branch, run:
   ```bash
   git diff {default branch}...contest/approach-{N}
   git diff {default branch}...contest/approach-{N} --stat
   ```
   Read the changed files on each branch.

2. **Send the judge all implementations:**

```
PROBLEM: {full problem description}

EVALUATION CRITERIA (in priority order):
{numbered list}

IMPLEMENTATION A ({approach-1 name}, by contestant-1):
Branch: contest/approach-1
Diff:
{full diff}

Changed files:
{file contents}

Test results: {pass/fail from contestant-1's report}

---

IMPLEMENTATION B ({approach-2 name}, by contestant-2):
Branch: contest/approach-2
Diff:
{full diff}

Changed files:
{file contents}

Test results: {pass/fail from contestant-2's report}

---

{IMPLEMENTATION C if applicable}

---

INSTRUCTIONS:
1. Review each implementation against EVERY evaluation criterion.
2. Score each criterion 1-5 for each implementation.
3. Identify the WINNER and explain why.
4. Note any ideas worth cherry-picking from losing implementations.
5. Message each contestant DIRECTLY with feedback on their approach:
   - What was strong
   - What was weak
   - What you'd change

Report your full evaluation to me (the lead).

Mark your task as completed.
```

**Wait** for the judge to finish. Allow time for judge-contestant discussion.

---

## Phase 3: Finalization

1. **Apply the winning implementation:**
   ```bash
   git checkout {original branch}
   git merge contest/{winning-approach} --no-ff
   ```

2. **Cherry-pick from losers** if the judge recommended specific ideas:
   - Apply targeted changes manually
   - Run tests to verify

3. **Clean up worktrees and branches:**
   ```bash
   git worktree remove /tmp/contest-approach-1
   git worktree remove /tmp/contest-approach-2
   git worktree remove /tmp/contest-approach-3  # if applicable
   git branch -d contest/approach-1
   git branch -d contest/approach-2
   git branch -d contest/approach-3  # if applicable
   ```

---

## Phase 4: Shutdown and Summary

1. **Shut down all agents:**
   ```
   For each of [contestant-1, contestant-2, contestant-3 (if applicable), judge]:
     SendMessage(type: "shutdown_request", recipient: {name}, content: "Contest complete.")
   ```
   Wait for confirmations.

2. **Clean up the team** with TeamDelete.

3. **Produce the contest report:**

```markdown
## Contest Report

### Problem
{original problem description}

### Evaluation Criteria
{numbered list with priority}

### Implementations

| Approach | Contestant | Lines Changed | Tests | Verdict |
|----------|-----------|---------------|-------|---------|
| {name} | contestant-1 | {count} | PASS/FAIL | WINNER / runner-up |
| {name} | contestant-2 | {count} | PASS/FAIL | WINNER / runner-up |
| {name} | contestant-3 | {count} | PASS/FAIL | WINNER / runner-up |

### Scorecard

| Criterion | Approach 1 | Approach 2 | Approach 3 |
|-----------|-----------|-----------|-----------|
| {criterion} | {1-5} | {1-5} | {1-5} |
| **Total** | **{sum}** | **{sum}** | **{sum}** |

### Winner: {approach name}
{Judge's explanation of why this approach won}

### Key Trade-offs
{What each approach sacrificed and gained}

### Cherry-picked from Losers
{Any ideas incorporated from non-winning implementations, or "None"}

### Diff (final)
{git diff --stat output}
```

---

## Agent Briefing Templates

### Contestant

```
You are a CONTESTANT in a coding contest. You implement one approach to a problem.

YOUR TEAMMATES:
- Lead: coordinates the contest. Assigns your approach.
- Other contestants: implementing different approaches. Do NOT look at their code.
- Judge: will evaluate all implementations after you finish.

RULES:
1. Work ONLY in your assigned worktree directory.
2. Do NOT look at other contestants' worktrees or branches.
3. Implement the BEST version of your assigned approach.
4. Write tests. Run existing tests.
5. Commit to your branch when done.
6. After judging, the judge may message you with feedback. Respond if asked.

Always use TaskUpdate to mark tasks completed.
```

### Judge

```
You are the JUDGE in a coding contest. You evaluate implementations fairly.

YOUR TEAMMATES:
- Lead: coordinates the contest. Sends you all implementations.
- Contestants: each implemented a different approach. You evaluate their work.

YOUR APPROACH:
1. Review each implementation against every evaluation criterion.
2. Score fairly -- no bias toward complexity or simplicity.
3. Pick a WINNER with clear justification.
4. Message each contestant DIRECTLY with constructive feedback.
5. Note any ideas worth cherry-picking from losing implementations.

Be specific: cite file paths, line numbers, and concrete examples.

Always use TaskUpdate to mark tasks completed.
```

---

## Failure Handling

| Failure | Action |
|---------|--------|
| Agent fails to spawn | Retry once. Proceed with 2 contestants minimum. |
| Contestant's tests fail | Note in judge's input. Judge can still evaluate the approach even if tests fail. |
| Contestant stuck | Give a nudge. If still stuck after a second nudge, proceed with remaining contestants. |
| Judge can't decide | Lead asks the judge to re-evaluate with tiebreaker criteria. If still tied, present both options to the user. |
| Worktree creation fails | Fall back to sequential implementation on branches (contestants take turns). |
| Branch conflict on merge | Resolve conflicts manually and re-run tests. |
| Team creation fails (teams not enabled) | Report the prerequisite and stop. |
