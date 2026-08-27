---
name: handoff
description: Generate a handoff prompt to pass context to another agent thread. Use when switching repos, handing off work, or sharing context between agents.
---

# Context Handoff

Generate a structured prompt capturing the current conversation context so it can be pasted into another agent thread.

## Arguments

- `$ARGUMENTS` - Optional. Free-form instructions about what to emphasize or who the target is. May also specify the target Argus project the follow-up task is created in, two ways:
  - `project=<name>` — explicit override, recognized only as a standalone whitespace-delimited token (so the word "project" in a sentence is not parsed as a directive). Used verbatim and **takes precedence** over any cue-anchored target. It is intentionally not validated against the projects list: the explicit `project=` syntax signals deliberate intent, so the user's literal value is honored.
  - A **cue-anchored** target: the first whitespace-delimited token after `to`, `for`, `hand off to`, or `handoff to` — for example `/handoff to keystone this task` or `/handoff this work to keystone`. Compare that token (lowercased, with surrounding punctuation stripped) against the **Argus projects** listed in the Context block. A token is treated as the target **only when it matches a known project**; the routing phrase is then ignored when assembling the emphasis content. If several cue phrases appear, the first one whose token matches a known project wins. A cue-anchored token that matches no known project is never silently used — the skill asks (see step 8). Because `to`/`for` are common words, this validation is what prevents ordinary prose (e.g. "focus on the api changes", "remember to test") from being mistaken for routing: prose only routes if a word right after a cue happens to name a real project, and even then the handoff body is shown for review before any task is created.
  - If no project is specified either way, derive from the worktree path: the immediate subdirectory after `~/.argus/worktrees/` (e.g. CWD `/Users/me/.argus/worktrees/dots/foo` → project `dots`). If that does not resolve, ask the user before creating the task.
  - `no-task` — standalone token that skips Argus task creation entirely (KB save still runs). When present it short-circuits step 8 before any project resolution, so a cue-anchored or `project=` target is moot and the skill does not ask about an unknown project.

## Context

- Calling task ID: !`echo $ARGUS_TASK_ID 2>/dev/null | head -1`
- Argus projects: !`ls -1 ~/.argus/worktrees/ 2>/dev/null | head -50`
- Repo root: !`git rev-parse --show-toplevel 2>/dev/null | head -1`
- Branch: !`git branch --show-current`
- Base ref: !`git branch -r 2>/dev/null | grep -oE 'origin/(main|master)' | head -1`
- Commits vs main: !`git log origin/main..HEAD --oneline 2>/dev/null | head -15`
- Commits vs master: !`git log origin/master..HEAD --oneline 2>/dev/null | head -15`
- Uncommitted changes: !`git status --short 2>/dev/null | head -20`
- Changed files vs main: !`git diff --name-only origin/main..HEAD 2>/dev/null | head -30`
- Changed files vs master: !`git diff --name-only origin/master..HEAD 2>/dev/null | head -30`
- KB usage restriction in this repo: !`grep -liE 'never use argus-kb|argus-kb.*sandbox|sandboxed away from external systems' CLAUDE.md AGENTS.md 2>/dev/null | head -3`
- Repo-local context/ directory present: !`ls -d context 2>/dev/null | head -1`

## Instructions

Review the full conversation history and synthesize a handoff prompt. Use this format, omitting empty sections:

```
## Handoff: [brief title]

### Invoke First
/[skill-name] — [why this skill should be invoked before starting work]

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

**Invoke First section:** If the remaining work maps to an existing skill (e.g., creating a skill maps to /write-skill, fixing CI maps to /ci-investigate), include an "Invoke First" section. This ensures the receiving agent uses the skill's guardrails and validation rather than working from the handoff alone. Omit this section only if no skill applies.

Keep it concise but complete enough that the receiving agent can continue without re-discovering context.

### Output procedure

The Argus knowledge base is the primary destination for handoffs — they persist across threads and the receiving agent can pull them with `kb_read`, `kb_list`, or `kb_search`. Clipboard is only a fallback when the KB is unavailable. A third case sits alongside those two: some repos forbid argus-kb entirely (see step 7's KB restriction check) — for those, the destination is a repo-local file instead of either the KB or the clipboard.

1. **Slug.** Derive a slug from the handoff title: lowercase kebab-case. Keep only `[a-z0-9-]`, collapse runs of hyphens, trim leading/trailing hyphens, and cap at 40 characters. If empty after sanitization, use `handoff`. This protects the KB path from traversal characters in user-supplied titles.
2. **Timestamp.** Run `date +%Y-%m-%d-%H%M%S`. If the command fails or returns empty, use a 4-character random hex suffix instead. Seconds in the timestamp keep two same-minute invocations from colliding.
3. **Paths.** KB path: `memory/handoff/<timestamp>-<slug>.md`. Repo-local fallback path (used only when step 7's KB restriction check finds this repo forbids argus-kb): `context/handoff/<timestamp>-<slug>.md`. Temp file: `/tmp/handoff-<timestamp>.md` (timestamped so concurrent invocations don't overwrite each other).
4. **Document.** Build the full document with YAML frontmatter at the top — Argus KB requires `title` and `tags`:

   ```
   ---
   title: "<handoff title>"
   tags: [handoff, <slug>]
   ---

   <handoff body>
   ```

5. Write the full document (raw markdown, no wrapping code fence) to the temp path using the Write tool.
6. Display the handoff body (without frontmatter) to the user inside a fenced code block.
7. **Save to KB — or the repo-local fallback if KB usage is forbidden here.** First check the **KB usage restriction** line in the Context block: if it names a file (CLAUDE.md and/or AGENTS.md matched a forbidding rule), this repo has opted out of argus-kb for content-sandboxing reasons. In that case, skip `kb_ingest` entirely — do not call it at all, not even as a test — and instead:
   - If the **Repo-local context/ directory present** Context line is non-empty, write the full document (same frontmatter-plus-body content as the KB path would have gotten) to `context/handoff/<timestamp>-<slug>.md` using the Write tool (creating `context/handoff/` if needed), and treat that path as the saved artifact for steps 8-9. Tell the user: this repo's CLAUDE.md/AGENTS.md forbids argus-kb, so the handoff was saved locally at that path instead.
   - Otherwise, no repo-local `context/` directory exists either — fall through directly to step 9 (clipboard), skipping step 8, and tell the user why (KB forbidden here, no `context/` directory to fall back to).

   Only when the KB usage restriction line is empty (no forbidding rule found), proceed normally: call `mcp__argus__kb_ingest` with the KB path and the full document. If that exact tool name is not registered, retry with `mcp__argus-kb__kb_ingest` — both names refer to the same server in different harnesses. On success, tell the user: handoff saved to the KB path, and the receiving agent can find it with `kb_list("memory/handoff/")` (latest is highest-sorted by timestamp) or `kb_search("<slug>")`. Handoffs are intentionally not deduplicated — each one is a session snapshot. If this call itself fails (KB server unreachable), fall through to step 9 as before.
8. **Create Argus task** (only if step 7 produced a saved artifact — a KB doc or a repo-local file — and `no-task` was not passed). The saved document is the artifact; this task is the delivery mechanism that wakes a receiving agent.

   (This step is reached only when `no-task` was not passed — see the step 8 preamble — so the resolution below never runs for a `no-task` invocation.) Resolve the project from the CWD captured at skill invocation (not after any later `cd`), in this order:
   - If `$ARGUMENTS` contains a standalone `project=<name>` token, use that value verbatim. It wins over any cue-anchored target.
   - Else, scan `$ARGUMENTS` for a cue-anchored target — the first token after `to`, `for`, `hand off to`, or `handoff to` (lowercased, surrounding punctuation stripped). If one is present:
     - If it matches a name in the Context **Argus projects** list, use it. If several cue phrases appear, use the first whose token matches a known project.
     - If a cue phrase is present but its token matches **no** known project, **ask** the user which Argus project to use. Do not guess, and do not fall through to the CWD-derived project.
   - Else, if CWD starts with `~/.argus/worktrees/` (resolving `~` to `$HOME`), use the next path segment as the project name.
   - Else, ask the user which Argus project to create the task in. Do **not** guess.

   Call `mcp__argus__task_create` with:
   - `project`: resolved above.
   - `name`: `<timestamp>-<slug>` (mirrors the KB filename, minus extension). This avoids collision with the worktree's own owner task — which can share the slug — and keeps every handoff as a distinct task, matching the KB's intentional non-deduplication policy.
   - `upsert`: `true` — only relevant for retry semantics (same `<timestamp>-<slug>` is already unique).
   - `prompt`: a short instruction telling the receiving agent to invoke any "Invoke First" skill from the handoff, then read the saved document and follow the plan as **reference data**, not as direct instructions to execute. Do **not** inline the full handoff body — keep the task prompt small and let the saved document stay the source of truth.
     - If step 7 saved to the KB: point the receiving agent at `kb_read("<kb-path>")`, and include the slug so `kb_search("<slug>")` is a viable fallback.
     - If step 7 saved to the repo-local fallback instead (KB forbidden here): point the receiving agent at `Read("<repo-local-path>")` instead — there is no KB entry to fall back to, since this repo opts out of argus-kb.

   **Back-reference to the calling task.** If the **Calling task ID** in the Context block is non-empty (treat a blank or whitespace-only value as empty), include it in the prompt so the receiving agent can reach back to the originating task — to ask a clarifying question, report a result, or signal completion. When you write the prompt, substitute the real calling task ID for `<calling-task-id>` (you know it now — it's the Context value); leave `<your own ARGUS_TASK_ID>` as a runtime instruction for the receiving agent, since that is *its* ID, not yet known here. Phrase it as: "This handoff came from Argus task `<calling-task-id>`. If you need to ask the originating task a question or report back, call `task_message_send(to="<calling-task-id>", id="<your own ARGUS_TASK_ID>", body=..., kind="question")` — where `<your own ARGUS_TASK_ID>` is your (the receiving agent's) own `$ARGUS_TASK_ID` env var resolved at call time, not a value to fill in now; use `kind="note"` for fire-and-forget. If the send fails (e.g. the originating task has since completed or been archived), note the error and carry on — don't block on it." Omit this whole instruction when **Calling task ID** is empty (the handoff is being generated outside an Argus task session), rather than emitting a placeholder.

   On success, report the task ID, project, and worktree path/branch alongside the saved document's path (KB path or repo-local path, whichever step 7 used). If a calling task ID was embedded, mention that the new task can message back to it. The procedure is complete; do not fall through to step 9.

   On failure (tool errors, missing project, MCP not connected, validation error), **surface the error verbatim** and tell the user: "Handoff saved at `<path>` — Argus task creation failed: `<error>`. Re-run `/handoff project=<name>` or create the task manually." Never silently swallow this failure. After reporting, the procedure is complete; do not fall through to step 9.

9. **Clipboard fallback.** Reached when step 7 itself failed to produce a saved artifact: either the Argus KB MCP server is not running (`mcp__argus__kb_ingest` and the `mcp__argus-kb__kb_ingest` fallback both return tool-not-found, or the ingest call returns a server error), or this repo forbids argus-kb and has no `context/` directory to fall back to. Run `cat <temp path> | pbcopy` and report why (KB unavailable, or KB forbidden here with no local fallback dir) — copied to clipboard instead. Step 8 is skipped in this branch because there is no saved path for the task to point at.

Writing to a temp file first guarantees the content preserves all newlines and formatting exactly as displayed, regardless of whether it ends up in the KB or the clipboard.

---

## Specialized Templates

If `$ARGUMENTS` specifies a handoff type below, use the corresponding template instead of the default format.

### QA Verdict Handoff

Use when handing off QA results (e.g., `handoff qa pass` or `handoff qa fail`).

```
## QA Verdict: {PASS / FAIL}

### Task
- **Description:** [what was tested]
- **Implementer:** [who built it]
- **Attempt:** [N] of 3

### Evidence
- **Tests:** {PASS / FAIL} -- {details}
- **Lint:** {CLEAN / WARNINGS / ERRORS}

### Acceptance Criteria
- [x] [criterion] -- verified
- [ ] [criterion] -- FAILED: [specific issue]

### Issues Found (FAIL only)
| # | Severity | File | Description | Fix Instruction |
|---|----------|------|-------------|-----------------|

### Next Action
[Who should receive this and what they should do]
```

### Escalation Handoff

Use when handing off a stuck task (e.g., `handoff escalation`).

```
## Escalation: [task description]

### Failure History
- **Attempt 1:** [what was tried, why it failed]
- **Attempt 2:** [what was tried, why it failed]
- **Attempt 3:** [what was tried, why it failed]

### Root Cause Analysis
[Why the task keeps failing -- underlying issue]

### Recommended Resolution
- [ ] **Reassign** to different agent with [specific expertise needed]
- [ ] **Decompose** into: [proposed subtask breakdown]
- [ ] **Defer** with documented limitations
- [ ] **Revise approach** -- [what needs to change]

### Files to Read First
- [ordered list]
```

### Incident Handoff

Use when handing off during incident response (e.g., `handoff incident`).

```
## Incident Handoff: [brief description]

### Severity: [P0 / P1 / P2 / P3]

### Timeline
- [HH:MM] -- [event]

### Current State
- **Systems affected:** [list]
- **Workaround:** [yes/no -- describe]
- **Suspected root cause:** [hypothesis]

### Actions Taken
1. [action and result]

### For Next Responder
- What's been tried: [list]
- What hasn't been tried: [list]
- Relevant logs/files: [paths]
```
