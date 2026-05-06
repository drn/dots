---
name: argus-complete
description: Mark the current Argus task as complete. Use when the work for the current worktree is done and the user wants the task to transition to the "complete" status.
allowed-tools: mcp__argus__task_complete
---

# Mark Current Task Complete

Mark the Argus task owning the current worktree as `complete`. This sets the task's status to `complete` and stamps `EndedAt`. It does **not** stop a running agent session — if an agent is still attached, the user should stop it separately first.

This skill is **not** the same as `/archive`. `/archive` moves the task into the Archive section (a visibility flag, independent of status). `/argus-complete` transitions the workflow status to `complete`. Use `/argus-complete` when the work is finished; use `/archive` (separately, optionally) if you also want it removed from the active task list.

## Context

- Current directory: !`pwd`

## Your task

Call the `mcp__argus__task_complete` MCP tool with the working directory from the Context block above as the `cwd` argument:

```
mcp__argus__task_complete(cwd: "<pwd from context>")
```

Argus resolves the task from `cwd` by matching it against task worktree paths — the agent process does not know its own task ID, so `cwd` is the required hand-off.

Do **not** pass `id` — the agent has no reliable way to know it.

After the call, report the tool's response verbatim in one line. If the tool errors (e.g. "no task matches cwd"), show the error and stop; do not retry with guessed arguments. If the response says the task is already complete, surface that as-is and stop.
