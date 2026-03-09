---
name: loop
description: Run a prompt on a recurring interval using a blocking sleep loop. Use for polling CI, babysitting deploys, monitoring logs, periodic checks, or scheduled task execution.
---

# Loop

Run a prompt repeatedly at a fixed interval. The main thread stays alive by sleeping between executions, spawning a background agent each cycle to do the work.

## Arguments

- `$ARGUMENTS` - interval and prompt, or a management command (list, cancel)

**Syntax:**

```
/loop <interval> <prompt or /skill>
/loop list
/loop cancel <id>
/loop cancel all
```

**Examples:**

```
/loop 5m check if CI is green on this PR
/loop 20m /review-pr 1234
/loop 2h check for new Sentry errors in the payments service
/loop 30s tail the deploy logs and report status
/loop list
/loop cancel 2
```

## Context

- Current branch: !`git branch --show-current 2>/dev/null | head -1`
- Git status: !`git status --short 2>/dev/null | head -10`
- Working directory: !`pwd`

## Instructions

### Step 1: Parse the Arguments

Parse `$ARGUMENTS` to determine the action:

**Management commands:**
- `list` - Show all active loops with their ID, interval, prompt, and execution count. If no loops are active, say so.
- `cancel <id>` - Mark the specified loop as cancelled. On the next sleep cycle, the loop will detect the cancellation and stop.
- `cancel all` - Mark all loops as cancelled.

**New loop:**
- Extract the interval token (first argument matching the pattern below)
- Everything after the interval is the prompt to execute

**Interval parsing:**
- `Ns` or `Nsec` - N seconds (minimum 30 seconds, round up if less)
- `Nm` or `Nmin` - N minutes
- `Nh` or `Nhr` - N hours
- `Nd` - N days
- No interval specified - default to 10 minutes
- Convert to seconds for the sleep command

If the prompt is empty after parsing, ask the user what they want to run.

### Step 2: Confirm and Initialize

Present the loop configuration:

```
## Loop configured

**Interval:** {human-readable interval}
**Prompt:** {the prompt to execute}
**Loop ID:** {sequential integer, starting at 1}

Starting now. First execution is immediate. Use /loop list to check status or /loop cancel {id} to stop.
```

Initialize tracking state:

```
loop_id = {next sequential ID}
interval_seconds = {parsed interval in seconds}
prompt = {the prompt to execute}
execution_count = 0
max_executions = 500
cancelled = false
```

### Step 3: Execute the First Iteration Immediately

Spawn a background agent to execute the prompt:

```
Agent(
  prompt: "{prompt}\n\nThis is execution #{execution_count + 1} of a recurring loop (ID {loop_id}). Report your findings concisely.",
  run_in_background: true,
  description: "Loop {loop_id} run {execution_count + 1}"
)
```

Increment `execution_count`.

If the prompt starts with `/`, invoke it as a skill via the Skill tool inside the agent prompt instructions.

### Step 4: Enter the Sleep Loop

This is the critical section that keeps the thread alive.

**Loop:**

1. **Block the thread:**
   ```
   Bash("sleep {interval_seconds}")
   ```
   This keeps the lead thread alive in Conductor.

2. **Check cancellation:** If the loop has been marked cancelled (via a `/loop cancel` command in another message, or by tracking state), output:
   ```
   Loop {loop_id} cancelled after {execution_count} executions.
   ```
   Stop looping and exit.

3. **Check limits:**
   - If `execution_count >= max_executions`, stop and report.
   - If the agent that ran the previous iteration reported a terminal condition (e.g., "CI is green", "deploy complete"), ask the user if they want to continue or stop.

4. **Spawn the next execution** as a background agent (same as Step 3).

5. **Output a heartbeat** every 3rd execution:
   ```
   Loop {loop_id}: execution #{execution_count} complete ({elapsed time} elapsed). Next in {interval}.
   ```

6. **Increment and repeat.**

### Step 5: Completion

When the loop ends (cancelled, max reached, or terminal condition), output:

```
## Loop {loop_id} finished

**Executions:** {count}
**Duration:** {total elapsed time}
**Reason:** {cancelled | max executions reached | terminal condition}
**Last result:** {brief summary of last execution output}
```

## Failure Handling

| Failure | Action |
|---------|--------|
| Background agent fails to spawn | Retry once. If still fails, report error and continue to next iteration. |
| Prompt execution errors | Log the error in heartbeat output. Continue looping -- transient errors are expected for monitoring tasks. |
| Sleep interrupted | Re-enter the sleep for remaining time. |
| User sends a new message | The loop may pause. Resume on next turn. Note: in Conductor, user messages may interrupt the sleep loop. The loop resumes when control returns. |

## Design Notes

This skill uses the same blocking-sleep pattern as /swarm to keep the main thread alive in Conductor. Unlike the built-in /loop (which uses CronCreate/CronDelete), this version:

- Dies when the workspace session ends (session-scoped)
- Runs the prompt via background agents so the lead can continue monitoring
- Tracks state in-memory rather than via cron infrastructure
- Works in any environment that supports the Agent and Bash tools
