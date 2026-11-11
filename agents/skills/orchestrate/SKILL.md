---
name: orchestrate
description: Plan and execute a dependency-aware build using available native delegation and optional model tiering, with single-agent fallback. Use when orchestrating a build, dynamic workflow, model-tiered build, fable workflow, or tiered agents in any harness.
---

# Orchestrate: Planning + Implementation

Plan in the current session, delegate bounded work when supported, and integrate and verify the result. Workflow and model tiering are optional optimizations, not prerequisites. This skill supports Claude and non-Claude backends.

## Arguments

- `$ARGUMENTS` — feature/change description or path to a plan/spec. If absent, use the task supplied in the conversation; if neither exists, ask what to build and stop.

## Context

- Current branch: !`git branch --show-current 2>/dev/null | head -1`
- Git status: !`git status --short 2>/dev/null | head -20`
- Project type: !`find . -maxdepth 1 \( -name go.mod -o -name package.json -o -name Cargo.toml -o -name pyproject.toml -o -name Gemfile -o -name Makefile \) 2>/dev/null | head -6`
- Recent commits: !`git log --oneline -5 2>/dev/null | head -5`

If the harness does not expand dynamic context, collect equivalent context with its command and file tools. Do not treat unexpanded expressions as results.

## Step 0: Select Execution Mode

Inspect tools actually exposed by the harness and permitted by project instructions. Do not infer capabilities from the model vendor, harness name, or an environment variable.

1. **Workflow:** If a permitted Workflow tool is available, it may manage the work-item groups below. Invoking this skill opts into Workflow use, subject to project rules.
2. **Other native delegation:** Otherwise, use a permitted native subagent tool if available. A Workflow API, team messaging, and task-list tools are not required: dispatch scoped prompts and collect results in the main session.
3. **Single-agent execution:** If neither is available, announce this mode briefly and implement the ordered work items in the current session, including verification, self-review, and bounded repair. You are not limited to coordinating other agents.

Do not request experimental Teams enablement, change harness settings, or stop because delegation is missing. Project prohibitions take precedence over exposed team tools.

### Model selection

Planning uses the current session model; do not require a model switch. Classify implementation work as routine or complex:

| Work class | Examples |
|------------|----------|
| Routine | Tests, docs, boilerplate, renames, configuration, bounded endpoints |
| Complex | Cross-cutting design, tricky algorithms, concurrency, public APIs, error strategy |

When supported, resolve configured model mappings (including project archetype resolution when required) and select an available model appropriate to that work class. Sonnet for routine work and Opus for complex work are optional Claude-specific examples, not universal identifiers. Without explicit model selection or a supported mapping, use the available session/default model and report that tiering was not used. Never pass an unsupported model name or claim a switch occurred.

## Step 1: Plan in the Main Session

1. Read project instructions, relevant code, and any supplied plan/spec. Preserve existing user edits; establish a baseline and do not automatically commit, stash, or reset them. Use read-only scouting agents only when permitted and useful.
2. Decompose the work into items with **id**, **self-contained prompt**, **work class**, **owned files**, **dependencies**, and **success criteria**. Include relevant conventions and a compile/lint sanity check in each prompt.
3. Group by file ownership. Items touching the same files run sequentially; only independent groups may run in parallel. Dependencies take precedence over parallelism: do not start a consumer before its producer is ready. Include ownership of both sides of new cross-cutting symbols (environment variables, columns, config keys, exported functions) so wiring cannot silently be omitted.
4. Keep items small enough for one response. Split large or uncertain items; when structured output is supported, omit its schema for risky items or isolate them so one failure cannot abort unrelated work.
5. Present a short plan table: id, work class, files, dependencies/group, and execution mode. Resolve ambiguity and satisfy project plan/spec approval gates before implementation. Do not bypass an approval gate because delegation is unavailable.

If fewer than 2 work items are needed, implement inline without delegation, then still perform Step 3 verification and reporting.

## Step 2: Execute the Plan

Maintain a checklist of pending, active, completed, failed, and skipped items with available tools or plain text.

### Common execution contract

- Execute dependencies first; serialize shared-file writers. Use parallelism only for independent work.
- Give delegates explicit file ownership, success criteria, and the relevant plan. Require summaries, files changed, actual check results, and concerns.
- In single-agent mode, perform each item yourself in dependency order and record the same evidence. Do not wait for absent agents or simulate dispatch calls.
- Verify each group with the project build/test command. Allow exactly one targeted fix round and one re-verify for a failing group. Mark persistent failures and blocked dependents; independent groups can finish.
- If tests share databases, ports, or fixtures, verify serially at a barrier after implementation instead of concurrently per group.
- Respect an explicit user budget where the harness exposes budget information. Report skipped work; do not invent budget measurements.

### Optional Workflow adapter

Use these rules only when the active harness exposes a permitted Workflow API with these semantics. Adapt to its documented interface rather than calling nonexistent APIs in other harnesses.

- Pass plan arguments on every invocation, including resumes: arguments may not persist across runs.
- Normalize string arguments before access, for example:
  ```javascript
  const A = typeof args === 'string' ? JSON.parse(args) : args
  ```
- Run sequential items within a group and independent groups in parallel. Pass explicit resolved models only when supported; otherwise use the tool default.
- A null result may be retried once. After two null results, mark the item incomplete and reconcile any partial edits before continuing unfinished work inline. Do not treat a null result as success or unblock its dependents.
- A structured-output retry-cap exception may abort an entire sequential group. Inspect results to identify later items that never ran; reconcile partial edits and finish only unfinished work in the main session when safe.
- Resume with the supported run identifier and the same arguments rather than relaunching the entire workflow and duplicating completed work.

### Delegation failure and fallback

When dispatch fails or becomes unavailable, inspect returned results, git diff, newly created files, and partial edits. Confirm delegates have finished or cancel them and wait for confirmation before taking over their files. If an active writer cannot be stopped or its state is unknown, stop affected work and report the blocker. Keep completed work; continue only unfinished items inline, in dependency order, with the same verification and repair limits. Report the fallback. Never blindly relaunch the whole plan.

## Step 3: Integrate, Review, and Report

1. Inspect all results and the complete task diff, including new files. Reconcile failed, skipped, and never-started items explicitly. For a failed group, permit at most one additional integration fix pass in the main session; unresolved failures remain blockers.
2. Run the full required project verification suite (build, lint, tests) against the integrated tree, even if group checks passed. Report unavailable checks as limitations, not passes.
3. Review for correctness, missing producer/consumer wiring, untested error paths, and ownership gaps. For high-stakes or cross-cutting changes, use an independent read-only reviewer if available; otherwise perform and label self-review. Test suspected regressions rather than trusting a green suite. Review findings share the one integration fix pass, not a new unbounded repair loop. Rerun required verification after any fixes.
4. Summarize work item, work class, actual model if selected, status, and files changed. Include execution mode, any fallback, verification results, review source, concerns, and remaining blockers. Do not claim independent review or model tiering when it did not occur.
5. Do not commit or push unless requested. Clean up only delegates created by this invocation using supported lifecycle tools; there is no team cleanup in single-agent mode.

## Stop Conditions

- No task → ask what to build.
- Required approval missing or ambiguous requirements → wait for clarification/approval.
- Missing delegation alone → continue single-agent execution without a setup prompt.
- Fewer than 2 items → implement inline, then verify and report.
- Group still fails after its fix round → mark failed and block dependents; continue independent groups.
- Null twice or structured-output exception → reconcile partial progress, finish only unfinished work when safe, and report it.
- Active delegate state unknown → stop affected work until ownership is safe.
- Integration fix pass exhausted → report unresolved blockers and await direction; never reset the retry budget silently.
