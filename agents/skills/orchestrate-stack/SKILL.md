---
name: orchestrate-stack
description: Orchestrate a stack of dependent Argus tasks that produce a chain of stacked PRs. Use when the user has a multi-milestone plan that should land as N PRs where each branches off the previous. Decomposes the plan into sub-tasks, wires base_branch + depends_on, embeds the closing protocol in every sub-task prompt, and polls until the stack lands.
allowed-tools: Bash(curl *), Bash(cat *), Bash(jq *), Bash(test *), Bash(gh *), Bash(git *), Bash(pwd), Bash(basename *), mcp__argus__task_create, mcp__argus__task_get, mcp__argus__task_list, mcp__argus__task_set_result, mcp__argus__task_stop, mcp__argus__task_archive, mcp__argus__kb_search, mcp__argus__kb_read, mcp__argus__kb_ingest, mcp__argus__kb_list
---

# Orchestrate Stack — Stacked-PR DAG via Argus

You are the orchestrator agent. The user has a multi-milestone plan; your job is to translate it into a chain of Argus sub-tasks that produce a stack of dependent PRs. You do not write code in the sub-task worktrees — each sub-task is its own Claude/Codex session with its own scope, and you only observe their results.

## When to use

The user has a plan that decomposes into 2+ sequential PRs where each PR depends on the previous (scaffold → wire → polish; refactor → feature → tests; or any milestone breakdown). If the plan would fit in a single PR, decline and tell them to use `/dev` or do it directly.

Cross-plan orchestration is out of scope. One plan per invocation.

## Arguments

- `$ARGUMENTS` — One of:
  - A local file path to a plan markdown file (e.g. `context/plans/2026-05-11-my-plan.md`).
  - A KB handoff path (e.g. `memory/handoff/2026-05-11-some-orchestrator.md`) — read with `mcp__argus__kb_read`.
  - A Notion page URL — read via the Notion MCP tools if available; otherwise ask the user to paste the plan body.
  - A free-form description of the work, in which case ask the user to first save it to `context/plans/<slug>.md` and re-invoke.

If empty, ask the user for the plan and stop.

## Context

- Current directory: !`pwd`
- Repo root: !`git rev-parse --show-toplevel 2>/dev/null | head -1`
- Argus daemon liveness: !`curl -sS -m 2 http://localhost:7743/api/status 2>/dev/null | head -1`

If the daemon liveness probe is empty, tell the user "Argus daemon does not appear to be running on :7743" and stop.

## Argus primitives required

This skill depends on the Argus daemon supporting `base_branch`, `depends_on`, `upsert`, `task_set_result`, and `ARGUS_TASK_ID` in the agent worktree env. These shipped together. If `task_create` rejects `base_branch` as an unknown parameter, the daemon is older than required — tell the user to update Argus and stop.

## Pre-flight clarifications

Before creating any tasks, confirm with the user using `AskUserQuestion` (1–3 questions side by side):

1. **Project name** — must match an existing Argus project. Infer from the worktree if obvious; otherwise ask.
2. **Milestone boundaries** — propose your decomposition explicitly (e.g. "PR 1: extract config; PR 2: thread through API; PR 3: add tests"). Ask the user to confirm or adjust. Never just start spawning.
3. **Acceptance criteria per milestone** — a one-line "done means…" for each PR. This becomes part of the sub-task prompt.
4. **Final reviewer** — does the orchestrator hand back to the user, or merge the stack once green? Default: hand back. Merging without explicit consent is forbidden.

## Decomposition

A good sub-task is:

- **Self-contained** — completes in a single session without further user input.
- **Milestone-sized** — small enough to review as one PR, large enough to be meaningful work.
- **Independently testable** — has its own test plan.
- **Forward-only** — never asks the orchestrator to revisit earlier sub-tasks.

If you cannot decompose a milestone into a single sub-task because it spans 3+ files and conceptual layers, split it further. Bias toward more, smaller sub-tasks rather than one mega-sub-task.

## Sub-task prompt template

Every sub-task prompt MUST include these sections in this order. The closing protocol is the orchestrator's contract — without it the stack falls apart.

````markdown
## Task: {Milestone name} (PR {N} of {Total})

{1-2 sentence summary of what this PR does and why.}

## Scope

{Bullet list of in-scope changes. Be explicit about file paths.}

## Out of scope (handled by later PRs)

{Bullet list of things you might be tempted to do but MUST NOT — they belong to PR {N+1} or later. Include the task IDs of downstream sub-tasks so reviewers can see the rest of the plan.}

## Acceptance criteria

- {Specific testable outcome 1}
- {Specific testable outcome 2}
- All existing tests pass: `{the appropriate test command for this repo}`
- New tests added for new behaviour.

## Closing protocol (CRITICAL — read before you start)

When the work is complete and tests pass:

1. **Open the PR.** Title format: `{Milestone slug}: {summary}`. Body must include:
   - A "Stacked on: #{prev PR number}" line (skip for PR 1)
   - A "Blocks: #{next PR number}" line (orchestrator will fill these once known)
   - A test plan checklist

2. **Report the result back to the orchestrator** via the `task_set_result` MCP tool. Use:
   ```
   task_set_result(id: ENV["ARGUS_TASK_ID"], result: {
     "pr_url": "https://github.com/.../pull/N",
     "pr_number": N,
     "branch_sha": "<short SHA of the branch tip>",
     "milestone": "{milestone slug}"
   })
   ```
   `ARGUS_TASK_ID` is exported into your worktree environment — use it directly.

3. **Call `task_complete`** to flip your status. The orchestrator's depswatcher will then auto-start the next sub-task in the stack within a minute.

If the work cannot complete (blocker, design flaw, requirements gap), call `task_set_result` with:
```
{"failed": true, "reason": "<one-paragraph explanation>"}
```
then `task_complete`. The orchestrator will halt the stack and surface your reason to the user.

DO NOT merge your own PR. DO NOT rebase onto master. DO NOT touch files outside your scope.
````

## Stack creation

For each milestone in order:

1. **First sub-task (PR 1):** create with NO `base_branch` (defaults to project default — master/main) and NO `depends_on`. Save the returned `id` and `branch`.

2. **Subsequent sub-tasks (PR 2…N):** create with:
   - `base_branch`: the previous sub-task's branch (returned in the create response).
   - `depends_on`: `[<previous task ID>]`. Single-parent stack.
   - `name`: a stable slug derived from the plan slug + milestone (e.g. `myplan-m2-wire-api`) so an orchestrator restart finds the same row.
   - `upsert: true` on every create — if the sub-task already exists from a previous run, the existing one is returned unchanged.

Use `mcp__argus__task_create` for each. Capture each response into a state record (see "State persistence" below) before creating the next one.

## State persistence (crash recovery)

After every `task_create`, append a row to a KB doc at `memory/orchestrator-runs/<plan-slug>.md` recording: milestone slug, task id, branch, base_branch, dependency, and (once known) PR URL. Use `mcp__argus__kb_ingest` — overwrite the doc each time with the full current state.

On re-invocation with the same plan, `kb_read` the doc first. Combine with `mcp__argus__task_get` lookups to skip already-completed milestones and resume polling from the first non-complete one. `upsert: true` makes re-running `task_create` for already-created tasks a no-op.

## Polling and observation

Pick the cheapest available wait primitive:

1. **`Monitor` (preferred)** — register on `task_list` filtered to your project + the milestone task IDs. Events arrive on state transitions; the agent stays idle between them.
2. **`ScheduleWakeup`** — schedule a wakeup every 5–10 minutes that re-enters this skill with the same arguments. Cheap because the conversation stays warm in the prompt cache when wakeup < 5 min; for longer waits, expect a cache miss per wakeup.
3. **Sleep loop** — only if neither of the above is available. Sleep 60–270 seconds between polls (stay inside the prompt-cache TTL).

On each tick:

1. Call `task_get` on the first non-complete sub-task.
2. When it transitions to `complete`, read its `result`:
   - If `result.failed == true`, halt:
     - For each downstream sub-task whose status is **`in_progress`** (depswatcher already started it during the ~1-minute tick window after the dep completed), call `task_stop`.
     - For each downstream sub-task whose status is **`pending`** (still blocked), call `task_archive`. `task_stop` would error with session-not-found on a blocked task because no agent process is running yet.
     - Update the KB state doc and surface the failure to the user with the captured `reason`.
   - Otherwise read `result.pr_url` and `result.pr_number`. Record them in the state doc, cross-link PRs (next section), and move on to polling the next sub-task — the depswatcher will have already started it within a minute.
3. Repeat until the last sub-task reports complete.

While polling, stay quiet. A status update every 5+ minutes is appropriate; minute-by-minute commentary is noise.

## Cross-linking PRs

After every sub-task lands its PR URL via `task_set_result`, add the "Stacked on" / "Blocks" cross-links to the PR descriptions. If the agents wrote `<!-- stacked-on -->` placeholders into the PR body, this is a mechanical `gh pr edit --body`. Otherwise fetch the body, splice in the lines, and write it back. Do this after each sub-task completes, not at the end — reviewers checking PR 1 should see the chain from the start.

## Halt conditions

- **Failed result** on any sub-task → stop the rest of the stack (see polling section).
- **Wedged sub-task** — `in_progress` for >2 hours with no transition. Send a `PushNotification` to the user with the task id and last state. Do NOT auto-`task_stop`; the user decides.
- **Two failures on the same milestone** (sub-task re-fired after archive, fails again) → halt and notify. No third attempt.
- **User reply on a `PushNotification` with a directive** → pause and follow it.
- **User invokes** `/orchestrate-stack stop <plan-slug>` → graceful shutdown: stop firing new tasks, do not kill in-flight ones, write final state to the KB doc.

## Final report

When the stack lands (or fails), write a single summary to the user AND `kb_ingest` it to `memory/orchestrator-runs/<plan-slug>.md` (overwriting the live state doc with the final outcome):

```
Stack complete — N PRs landed:

  1. {milestone 1 slug}: #PR1  ({short SHA})
  2. {milestone 2 slug}: #PR2  ({short SHA})
  3. ...

Merge order: PR1 → PR2 → PR3.
Review approach: start at PR1 to see the foundation.
```

If a sub-task failed, include its reason verbatim and the IDs of any halted downstream tasks so the user can clean up.

## Anti-patterns (refuse these)

- **Single mega-sub-task that "does the whole plan."** Defeats the point of stacking. Decline; ask the user to split.
- **Cyclic deps** (B depends on A, A depends on B). Argus rejects these at create time via DFS cycle detection — if you see a `cycle detected` error, the plan is wrong, not the daemon.
- **Wide DAG with many siblings** (A → {B, C, D}). The orchestrator pattern this skill encodes is a chain, not a fan-out. If the user really wants a fan-out, build it yourself with raw `mcp__argus__task_create` calls and explicit polling — this skill is the linear case.
- **Auto-merge after polling shows green.** Even if CI is passing on every PR, hand back to the user for the merge sequence unless they explicitly said "merge them too."
- **Touching the sub-task worktrees from the orchestrator.** Each sub-task owns its branch and files. Reading another sub-task's worktree from this agent is a bug — use `task_get` and `task_set_result` exclusively.

## Skill mirroring (author note)

This skill is canonical at `agents/skills/orchestrate-stack/SKILL.md` in the dots repo. `dots install agents` symlinks it to `~/.claude/skills/orchestrate-stack/` and `~/.agents/skills/orchestrate-stack/` so it is reachable from any project.
