---
name: dev
description: Iterative development with testing and code review using available native agents or single-agent execution. Use for building features, implementing changes, or coding tasks that need testing and review in any agent harness.
---

# Iterative Development

Implement, test, review, and iterate using the capabilities of the current harness. Delegation is an optimization, not a prerequisite. These instructions apply to Claude and non-Claude backends alike.

## Arguments

- `$ARGUMENTS` — description of the development task. If absent, use the task supplied in the conversation; if neither exists, ask what to build and stop.

## Context

- Current branch: !`git branch --show-current 2>/dev/null | head -1`
- Git status: !`git status --short 2>/dev/null | head -20`
- Project root: !`pwd`
- Project type: !`find . -maxdepth 1 \( -name go.mod -o -name Gemfile -o -name package.json -o -name Cargo.toml -o -name pyproject.toml -o -name setup.py -o -name requirements.txt -o -name pom.xml -o -name build.gradle -o -name Makefile \) 2>/dev/null | head -10`
- Recent commits: !`git log --oneline -5 2>/dev/null | head -5`
- Test files: !`find . -maxdepth 4 \( -name "*_test.*" -o -name "*.test.*" -o -name "*_spec.*" \) 2>/dev/null | head -10`

If the harness does not expand dynamic context, run the relevant commands with its command tool and read files with its file tool. Do not treat unexpanded expressions as results.

## Execution Mode

1. Inspect the tools exposed by the current harness and the project instructions. Select only tools that are available and permitted; do not infer capabilities from a model vendor, harness name, or environment variable.
2. **Native delegation:** If a permitted native subagent tool exists, use it for scoped implementation, testing, and review. Team messaging and task-list tools are optional: pass prompts and collect returned results through the coordinator instead. Do not require a team API.
3. **Single-agent execution:** If no permitted delegation tool exists, announce this mode briefly and perform every phase sequentially in the current session. You are the implementer, tester, and self-reviewer, not a coordinator waiting for absent agents.
4. Use configured model mappings when the dispatch tool supports them (including project archetype resolution when required). Otherwise use the supported session/default model. Explicit model selection and Claude model names are not prerequisites; never send an unsupported model identifier.
5. Do not request experimental Teams enablement, change harness settings, or stop because delegation is missing. Respect project prohibitions on team tools even if those tools are exposed.

### Delegation failure

If delegation is unavailable or fails, inspect returned results, git diff, and partial edits before continuing. Confirm delegates have finished or cancel them and wait for confirmation before taking over their files. If an active writer cannot be stopped or its state is unknown, report the blocker and stop affected work rather than racing it. Keep completed work and continue only unfinished work inline. Report the fallback; never blindly rerun the full task.

## Phase Artifacts

Read [the phase protocol](../_shared/resources/phase-protocol.md) if available. Before starting, read the latest plan or think artifact in `.context/phases/` when present. Reuse its decisions and testing strategy. A missing optional protocol or prior artifact is not a blocker.

After the summary, write `.context/phases/build-{ts}.md` using the protocol format, or headings Summary, Detail, and Handoff if the protocol is unavailable. Include files changed, decisions, deviations, verification results, and review concerns.

## Phase 0: Setup and Plan Approval

1. Inspect the working tree. Preserve existing user changes; do not automatically commit, reset, or stash them. Establish a baseline so the final diff distinguishes prior work from this task.
2. Read project instructions and relevant code. Identify language, framework, build, lint, and test commands.
3. Present a concrete plan: goal, approach, files to change, testing strategy, risks, and chosen execution mode.
4. **Wait for user approval before implementation or spawning agents.** Reuse explicit approval already given for the same plan. Follow any project spec/proposal approval gates as well.
5. Track work items and dependencies with available task tools or a plain checklist. Set a maximum of 3 repair rounds.

## Phase 1: Validate the Plan

Review the approved plan for missing wiring, test gaps, and scope errors before coding. With delegation, ask a read-only reviewer to validate the implementation details and return concerns to you. Without delegation, perform this check yourself. Resolve concerns within the approved approach; seek approval again for material scope changes.

## Phase 2: Implement

Implement the approved changes following existing conventions and file boundaries. With delegation, use [references/BRIEFINGS.md](references/BRIEFINGS.md) as optional role templates and give each implementer a self-contained prompt: task, approved plan, relevant paths, file ownership, conventions, success criteria, and sanity-check command. Avoid concurrent writers to the same files.

Run a basic compile, lint, or syntax check. Record files changed, approach, and concerns. A tester may inspect the suite while implementation proceeds, but must not edit implementation-owned files concurrently.

## Phase 3: Test and Review

1. Read the complete task diff and changed files, including newly created files.
2. Run the project test suite and identify coverage gaps. Add tests that would catch plausible regressions, then rerun tests. If no test framework exists, report N/A and describe manual checks; do not claim a pass.
3. Review against [references/CODE_REVIEW.md](references/CODE_REVIEW.md): security, architecture, clarity, error paths, and compatibility with the plan. Classify findings as BLOCKING, WARNING, or INFO with file locations and actionable fixes.
4. Prove or disprove suspected bugs with targeted tests where feasible.

With delegation, testing and read-only review may run in parallel after implementation finishes. Assign any new test files explicit ownership and serialize tests that share databases, ports, or fixtures. Without delegation, test first and then self-review; do not claim independent review occurred.

## Phase 4: Consolidate Feedback

Collect blocking findings, warnings, test failures, coverage observations, and suggestions. Proceed when tests pass (or an explicit N/A limitation is recorded) and no blocking issue remains. For blocking issues or failing checks, enter the repair cycle.

## Phase 5: Bounded Repair

Perform at most 3 repair rounds. In each round:

1. Fix only the reported issues; do not add unrelated features.
2. Rerun affected tests and the required project suite.
3. Review the new diff and verify each blocking finding is resolved.

Use the same execution mode rules for repair. If blockers remain after 3 rounds, stop and report them with options to decompose, reassign if available, defer explicitly, or extend with user approval. Do not silently accept unresolved blockers or reset the counter.

## Phase 6: Adversarial Hardening

For substantial changes (more than 50 changed lines, cross-cutting behavior, or security-sensitive inputs), attempt to break the implementation: empty/large/unicode inputs, concurrency, leaks, failure paths, and violated assumptions. Add targeted tests where appropriate. Use an independent reviewer if available, otherwise label this self-review.

Allow one final hardening fix round and re-test. If problems remain, report them as unresolved; never start an unbounded loop. Skip this phase for trivial changes and explain why.

## Phase 7: Cleanup and Summary

Wait for or stop only the delegates created by this invocation using supported lifecycle tools; never delete unrelated teams or sessions. In single-agent mode there is no team cleanup.

Report:
- Task, execution mode, any fallback, and files changed.
- Build/lint/test commands and actual PASS, FAIL, or N/A results.
- Tests added, coverage gaps, and manual checks.
- Review source (independent review or self-review), findings, and hardening results.
- Repair rounds, unresolved blockers, and warnings.
- Task diff summary, excluding unrelated prior edits.

Write the build artifact described above. Do not commit or push unless requested.

## Stop Conditions

- No task or unresolved requirements → ask for clarification.
- Required plan/spec approval missing → wait for approval.
- Required command/tool access unavailable → report the limitation; do not claim checks ran.
- Delegate still writing or unknown state → stop affected work until ownership is safe.
- Repair budget exhausted → report blockers and await direction.
- Missing delegation alone → continue single-agent execution, not a setup prompt.
