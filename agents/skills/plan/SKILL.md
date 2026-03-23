---
name: plan
description: Generate an implementation plan from a PRD, tech spike, or feature spec and save it to context/plans/. Use for planning work, breaking down a PRD, or creating an implementation plan from a spec.
---

# Implementation Plan

Read a PRD, tech spike, or feature spec and produce a concrete implementation plan saved to `context/plans/`.

## Arguments

- `$ARGUMENTS` - Required: path to a PRD/spike/spec file, a URL, or inline description of what to plan

## Context

- Project type: !`find . -maxdepth 1 \( -name go.mod -o -name Gemfile -o -name package.json -o -name Cargo.toml -o -name pyproject.toml -o -name CLAUDE.md -o -name AGENTS.md \) 2>/dev/null | head -10`
- Directory structure: !`find . -maxdepth 2 -type d -not -path './.git/*' -not -path './node_modules/*' -not -path './vendor/*' 2>/dev/null | head -30`
- Recent commits: !`git log --oneline -10 2>/dev/null | head -10`
- Prior plans: !`find .context/plans -name "*.md" 2>/dev/null | head -10`
- Prior spikes: !`find context/spikes -name "*.md" 2>/dev/null | head -10`
- Phase artifacts: !`ls -t .context/phases/*.md 2>/dev/null | head -10`

## Phase Protocol

This skill participates in a phase chain. Read `~/.claude/skills/_shared/resources/phase-protocol.md` for the full protocol.

**Before starting:** Check `.context/phases/` for prior artifacts:
- If `critique-*.md` exists → read the latest critique. This is a **second pass** — incorporate the critique's concerns into a refined plan. Write output as `plan-{ts}.md`.
- If no critique exists → this is a **first pass** (thinking/exploration). Write output as `think-{ts}.md`.

**After completing Step 4:** Write the phase artifact to `.context/phases/`:

```bash
mkdir -p .context/phases
```

Use the artifact format from the phase protocol. The **Handoff** section should include: key decisions, implementation phases, open questions, and risks — everything `/dev` needs to start building.

## Instructions

### Step 1: Ingest the source material

Parse `$ARGUMENTS` to locate the input:

1. **File path** — Read the file directly.
2. **URL** — Fetch the content.
3. **Inline text** — Use the arguments as the spec.

IF `$ARGUMENTS` is empty or unclear, ask the user to provide a PRD, spike, or spec.

Extract from the source:
- **Goal:** What is being built or changed?
- **Requirements:** Functional and non-functional requirements, acceptance criteria.
- **Constraints:** Technical constraints, dependencies, timeline signals.
- **Open questions:** Anything unresolved in the source material.

Present a brief summary of what you understood and ask the user to confirm before proceeding.

### Step 2: Explore the codebase

Investigate the current codebase to ground the plan in reality:

1. **Find relevant code** — Search for files, modules, and patterns related to the requirements.
2. **Understand existing architecture** — Read key files to understand conventions, patterns, and boundaries.
3. **Identify integration points** — Where does the new work connect to existing code?
4. **Check for prior art** — Look at prior plans and spikes in `context/` for related work.

### Step 3: Write the plan

Ensure `context/plans/` directory exists (create if needed).

Save the plan to `context/plans/<date>-<slug>.md` where `<date>` is today in YYYY-MM-DD format and `<slug>` is a short kebab-case summary.

Use this format:

```markdown
# Plan: <title>

**Date:** <YYYY-MM-DD>
**Source:** <path or URL to the PRD/spike/spec>
**Status:** Draft
**Current Phase:** Phase 1

## Goal

<1-2 sentence summary of what this plan achieves>

## Background

<current state, why this work is needed, link to source material>

## Requirements

### Must Have
- <requirement with acceptance criteria>

### Should Have
- <requirement>

### Won't Do (this iteration)
- <explicitly excluded scope>

## Technical Approach

<high-level strategy: what patterns to follow, key design decisions>

## Decisions

| Decision | Rationale |
|----------|-----------|
| <what was decided> | <why — constraints, trade-offs, alternatives rejected> |

## Implementation Steps

### Phase 1: <name>
**Status:** pending

- [ ] <task> — `path/to/file` — <what to do>
- [ ] <task> — `path/to/file` — <what to do>

### Phase 2: <name>
**Status:** pending

- [ ] <task> — `path/to/file` — <what to do>

### Phase 3: <name> (if needed)
**Status:** pending

- [ ] <task> — `path/to/file` — <what to do>

## Testing Strategy

- <what tests to write, what to verify>
- <edge cases to cover>

## Risks & Open Questions

| Risk | Mitigation |
|------|------------|
| <risk> | <how to handle> |

- <open question from source material>
- <open question discovered during exploration>

## Dependencies

- <external dependency or prerequisite>

## Errors Encountered

| Error | Attempt | Resolution |
|-------|---------|------------|

## Estimated Scope

**Phases:** <N>
**Tasks:** <N>
**Files touched:** <N>
```

### Step 4: Report

Print the plan summary (goal, phases, task count) and the file path where the full plan was saved. Offer to:
1. Print the full plan
2. Start implementation (suggest `/dev` with the plan as input)

## Updating Progress

The plan is the single source of truth for progress. Any agent or session can pick up where the last one left off.

### Read before decide

At the start of each session, read the plan file. This refreshes goals and progress in your attention window. Check the `Current Phase` field and scan checkboxes to orient.

### Update after act

After completing a task:
1. Check off the task: `- [ ]` to `- [x]`
2. When all tasks in a phase are done, update its `**Status:**` from `pending` to `complete`
3. Update `**Current Phase:**` at the top to the next phase
4. Log any decisions made to the `Decisions` table with rationale
5. Log any errors hit to the `Errors Encountered` table — this prevents future sessions from repeating the same failures
