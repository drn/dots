---
name: archive
description: Archive the current Argus task so it moves to the Archive section of the task list. Use at the end of a session when the work is done.
allowed-tools: mcp__argus__task_archive
---

# Archive Current Task

Mark the Argus task owning the current worktree as archived. Archiving moves the task into the Archive section of the task list and clears its waiting-for-review flag.

## Context

- Current directory: !`pwd`

## Your task

Call the `mcp__argus__task_archive` MCP tool with the working directory from the Context block above as the `cwd` argument, and `archived: true`:

```
mcp__argus__task_archive(cwd: "<pwd from context>", archived: true)
```

Argus resolves the task from `cwd` by matching it against task worktree paths — the agent process does not know its own task ID, so `cwd` is the required hand-off.

Do **not** pass `id` — the agent has no reliable way to know it.

After the call, report the tool's response verbatim in one line. If the tool errors (e.g. "no task matches cwd"), show the error and stop; do not retry with guessed arguments.

### Unarchiving

If `$ARGUMENTS` is the literal word `undo`, call with `archived: false` instead. Otherwise always pass `archived: true` — toggling from an unknown prior state is surprising.
