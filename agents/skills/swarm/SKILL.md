---
name: swarm
description: Conductor-native multi-agent orchestration with real-time progress. Use for parallel agent swarm, multi-agent tasks, agent team, team coordination, parallel workers.
---

# Agent Swarm

Agent teams with automatic progress monitoring. The lead thread stays alive, polls task status, and reports progress -- you never have to re-prompt to check in.

## The Problem

When team-based skills (`/dev`, `/explore`, `/debug`, `/contest`) run in Conductor, the lead creates the team, sends initial assignments, and its turn ends. Agents work in the background, but the workspace appears idle. You have to manually re-prompt to check status.

## The Fix

This skill uses native agent teams (TeamCreate + SendMessage) for full inter-agent communication, then adds an **automatic monitoring loop** that polls TaskList every 20 seconds and outputs progress. The lead thread never returns until all tasks are complete.

## Arguments

- `$ARGUMENTS` - Required: description of the task. Can be any kind of parallel work: development, research, debugging, review, etc.

If no arguments are provided, ask the user what they want to accomplish.

## Context

- Current branch: !`git branch --show-current 2>/dev/null | head -1`
- Git status: !`git status --short 2>/dev/null | head -20`
- Project root: !`pwd`
- Project type: !`find . -maxdepth 1 \( -name go.mod -o -name Gemfile -o -name package.json -o -name Cargo.toml -o -name pyproject.toml -o -name setup.py -o -name requirements.txt \) 2>/dev/null | head -5`
- Recent commits: !`git log --oneline -5 2>/dev/null | head -5`
- Directory structure: !`find . -maxdepth 2 -type d -not -path '*/\.*' -not -path '*/node_modules/*' -not -path '*/vendor/*' 2>/dev/null | head -30`

## Overview

You are the **swarm coordinator**. You create an agent team, assign work, then **actively monitor progress** in a polling loop -- keeping the main thread alive and reporting status in real time.

**Task:** $ARGUMENTS

You coordinate, monitor, and synthesize. Agents do the work and communicate with each other.

**How the monitoring loop works:**
1. Create team with `TeamCreate`, spawn agents, send initial assignments via `SendMessage`
2. Create tasks with `TaskCreate` so agents can track progress via `TaskUpdate`
3. Enter the monitoring loop:
   - `Bash("sleep 20")` to block the thread (keeps it alive in Conductor)
   - `TaskList()` to check current task statuses
   - Output a progress table showing what changed since last check
   - Repeat until all tasks are `completed`
4. Break out, process any queued agent messages, synthesize results
5. Shut down team

Agents communicate freely via `SendMessage` during the work phase. The lead does not participate in agent-to-agent communication -- it monitors via TaskList.

---

## Phase 0: Analyze and Plan

1. **Parse the task.** Identify the type of work and what parallel structure makes sense:

   | Task Type | Parallel Structure |
   |-----------|-------------------|
   | Development | Implementer + reviewer + tester. Reviewer validates plan, then parallel test + review after implementation. |
   | Research | N researchers on different angles. Peer challenge phase after initial findings. |
   | Debugging | N investigators pursuing different hypotheses. Converge, then fix + verify. |
   | Review | N independent reviewers. Synthesize disagreements. |
   | Custom | Decompose into independent parallel units. |

2. **Explore the codebase** briefly. Read key files related to the task. Understand context before planning.

3. **Present the plan to the user:**

   ```
   ## Swarm Plan

   **Task:** {summary}

   **Agents:**
   | # | Name | Role | Assignment |
   |---|------|------|-----------|
   | 1 | {name} | {role} | {description} |
   | 2 | {name} | {role} | {description} |
   | 3 | {name} | {role} | {description} |

   **Phases:**
   1. {phase name} -- {which agents, what they do}
   2. {phase name} -- {which agents, what they do}

   **Deliverable:** {what the final output looks like}
   ```

   **Wait for user approval.** Revise if requested. Do NOT create the team until approved.

---

## Phase 1: Team Setup

1. **Clean up any stale team:**
   ```
   TeamDelete() -- ignore errors if no existing team
   ```

2. **Create the team:**
   ```
   TeamCreate(team_name: "swarm-session", description: "{brief task summary}")
   ```

3. **Create tasks** with `TaskCreate` for every work item. Set `activeForm` to present-continuous (e.g., "Implementing auth module"). Set up `addBlockedBy` for dependencies between phases.

4. **Spawn all agents** in a single message with parallel `Agent` tool calls. Each agent gets:
   - `team_name: "swarm-session"`
   - `subagent_type` matching their role
   - The agent briefing (see Agent Briefing Template below)

5. **Send initial assignments** to each agent via `SendMessage`:
   - Include the task description, project context, and their specific assignment
   - Tell agents to mark their tasks via `TaskUpdate` as they progress
   - Tell agents to message each other directly when collaboration is needed

6. **Output launch status:**

```
## Team launched -- {N} agents

| # | Agent | Role | Task |
|---|-------|------|------|
| 1 | {name} | {role} | {assignment} |
| 2 | {name} | {role} | {assignment} |
| 3 | {name} | {role} | {assignment} |

Entering monitoring loop...
```

---

## Phase 2: Monitoring Loop

This is the critical section that keeps the main thread alive in Conductor.

**Initialize tracking state:**
```
poll_count = 0
max_polls = 90          # 90 polls x 20s = 30 minutes max
last_task_states = {}   # task_id -> status mapping from last check
```

**Loop:**

1. **Block the thread:** `Bash("sleep 20")` -- this keeps the lead alive in Conductor. 20 seconds balances responsiveness with overhead.

2. **Check task progress:** Call `TaskList()` to get current statuses.

3. **Detect changes:** Compare current statuses against `last_task_states`. For each task that changed status since last check, note the change.

4. **Output progress update** (only when something changed OR every 5th poll as a heartbeat):

   If changes detected:
   ```
   ### Progress update ({elapsed time})

   | Task | Status | Changed |
   |------|--------|---------|
   | {task subject} | completed | NEW |
   | {task subject} | in_progress | -- |
   | {task subject} | pending | -- |

   **{completed_count}/{total_count}** tasks complete
   ```

   If no changes (heartbeat every 5th poll):
   ```
   Still working... {completed_count}/{total_count} tasks complete ({elapsed time})
   ```

5. **Check exit conditions:**

   ```
   IF all tasks are completed:
     → Break out of loop, proceed to Phase 3

   IF poll_count >= max_polls (30 minutes elapsed):
     → Output warning: "Monitoring timeout reached (30 min). {N} tasks still incomplete."
     → Break out of loop, proceed to Phase 3 with partial results

   IF no task has changed status in 10 consecutive polls (>3 minutes of no progress):
     → Output warning: "No progress detected for 3+ minutes. Agents may be stuck."
     → Continue monitoring (do not break -- agents may be doing long work)
   ```

6. **Increment:** `poll_count += 1`, update `last_task_states`, continue loop.

---

## Phase 3: Wrap Up and Synthesize

After exiting the monitoring loop:

1. **Process any queued messages.** Agent messages that arrived during the monitoring loop will auto-deliver now that the lead's turn is ending/restarting. Read and incorporate them.

2. **Gather results.** For each completed task, the agent should have reported findings via messages or task metadata. Read through all available context.

3. **If multi-phase work remains** (e.g., Wave 1 done, Wave 2 needed):
   - Send next-phase assignments to agents via `SendMessage`
   - Include relevant findings from the completed phase as context
   - Re-enter the monitoring loop (Phase 2)
   - Cap at 3 total phases to prevent infinite loops

4. **Produce the final report:**

```
## Swarm Complete

### Task
{original task description}

### Summary
{3-5 sentence executive summary of what was accomplished}

### Agent Contributions

| Agent | Role | Key Contribution |
|-------|------|-----------------|
| {name} | {role} | {1-line summary} |
| {name} | {role} | {1-line summary} |
| {name} | {role} | {1-line summary} |

### Detailed Results
{Organized by TOPIC, not by agent. Cross-reference findings from multiple agents where they overlap.}

### Changes Made
{If development: table of files created/modified/deleted with git diff --stat}
{If research: key discoveries organized by theme}
{If debugging: root cause analysis and fix}

### Open Items
{Unresolved issues, follow-up suggestions, or "None -- all clear."}

### Execution
- Agents: {N}
- Phases: {N}
- Monitoring duration: {elapsed time}
- Tasks completed: {N}/{total}
```

5. **Shut down all agents:**
   ```
   For each agent:
     SendMessage(type: "shutdown_request", recipient: {name}, content: "Work complete.")
   ```
   Wait for confirmations.

6. **Clean up:** `TeamDelete()`

---

## Agent Briefing Template

When spawning agents, use this as the base prompt (customize per role):

```
You are {ROLE_NAME} on a swarm team. You {role description}.

YOUR TEAMMATES:
- Lead (swarm coordinator): monitors progress, does NOT participate in work. Sends you assignments and phase transitions.
{- Other agent: {name} -- {role}. Message them directly when you need {what}.}

WORKFLOW:
1. You will receive an assignment from the lead via message.
2. Work on your assignment. Use TaskUpdate to mark your task in_progress when you start and completed when you finish.
3. Message other teammates directly when collaboration is needed.
4. When done, message the lead with your results summary.

TASK TRACKING (critical for progress monitoring):
- Call TaskUpdate(status: "in_progress") when you BEGIN work on a task.
- Call TaskUpdate(status: "completed") when you FINISH.
- The lead monitors via TaskList -- keeping tasks current is how progress gets reported.

Always use TaskUpdate to mark tasks as you work.
```

For code-writing agents, add:
```
CODING RULES:
- Follow existing codebase conventions.
- Run tests/linter before reporting done.
- If writing tests, create NEW test files rather than modifying existing ones (avoids conflicts with implementer).
```

---

## Adaptation Patterns

### Development Tasks

**Agents:** implementer, tester, reviewer

**Phase 1 (plan + implement):**
- Implementer explores and implements
- Reviewer validates plan before implementer codes (direct message)
- Tester explores test suite while waiting

**Phase 2 (validate):**
- Tester runs tests + writes new ones
- Reviewer does code review
- Both message implementer directly with issues found

**Phase 3 (fix -- if needed):**
- Implementer addresses blocking issues
- Tester re-runs tests

### Research Tasks

**Agents:** 3-4 researchers

**Phase 1 (investigate):** Each researcher explores a different angle.

**Phase 2 (peer challenge):** Researchers read each other's findings (relayed by lead) and challenge/confirm them.

### Debugging Tasks

**Agents:** 3 investigators

**Phase 1 (hypothesize):** Each investigator pursues a different theory, messages others to debate.

**Phase 2 (fix + verify):** One investigator fixes, another verifies.

### Review Tasks

**Agents:** 3 independent reviewers

**Single phase:** All review the same changes independently. Lead cross-references findings. No Phase 2 needed.

---

## Failure Handling

| Failure | Action |
|---------|--------|
| Agent fails to spawn | Retry once. Proceed with fewer agents. Note in summary. |
| No progress for 3+ minutes | Output warning but continue. Agents may be doing deep work. |
| 30-minute monitoring timeout | Break loop. Produce partial summary with remaining tasks listed. |
| Agent unresponsive to shutdown | Proceed with TeamDelete regardless. |
| All tasks stuck | After 10 minutes with zero completions, ask the user if they want to continue waiting or abort. |
| Team creation fails | Fall back to sequential work -- do the task directly without agents. |
