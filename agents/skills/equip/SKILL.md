---
name: equip
description: Analyze a spec, PRD, or codebase to identify missing skills and agents, propose them, then write them. Use for skill gap analysis, agent gap analysis, bootstrapping agent capabilities from a spec, or equipping a project with skills.
---

# Skill & Agent Gap Analysis

Analyze a specification document, PRD, RFC, codebase, or set of requirements against the existing skill and agent inventory. Identify gaps, propose new skills or agents to fill them, then write the approved ones.

## Arguments

- `$ARGUMENTS` - Required: path to a spec/PRD file, URL, codebase directory, or a description of the requirements to analyze

If no arguments are provided, ask the user what to analyze.

## Context

- Project root: !`pwd`
- Existing skills: !`ls agents/skills/ 2>/dev/null | head -40`
- Custom agents: !`ls agents/custom/ 2>/dev/null | head -20`
- Skill descriptions: !`grep -r "^description:" agents/skills/*/SKILL.md 2>/dev/null | head -40`
- Agent descriptions: !`grep "^description:" agents/custom/*.md 2>/dev/null | head -20`
- Project type: !`find . -maxdepth 1 \( -name go.mod -o -name Gemfile -o -name package.json -o -name Cargo.toml -o -name pyproject.toml \) 2>/dev/null | head -3`

## Instructions

### Step 1: Load the Source

Determine the input source from `$ARGUMENTS`:

- **File path** — Read the file directly
- **URL** — Fetch and extract the content
- **Notion page** — Use Notion MCP tools if available, otherwise fetch the URL
- **Directory path** — Scan the codebase for workflows, patterns, and integration points
- **Pasted text** — If the user pasted requirements inline, use that
- **Description** — If the user described the requirements conversationally, extract the capabilities from their description

If the source cannot be loaded, report the error and stop.

### Step 2: Extract Capabilities

Parse the source material and extract a structured list of **capabilities** — the distinct things the product needs to do. For each capability, note:

1. **Name** — short label (e.g., "user onboarding flow", "webhook retry logic")
2. **Type** — one of: workflow, integration, automation, analysis, content generation, data pipeline, monitoring, deployment
3. **Actors** — who or what performs it (human, agent, system, CI)
4. **Triggers** — what initiates it (user command, schedule, event, manual)
5. **Complexity** — low / medium / high (based on number of steps, external dependencies, error handling needed)

Present the capability list to the user in a table before proceeding.

### Step 3: Map Against Existing Inventory

For each extracted capability, check whether an existing skill or agent already covers it:

- **Fully covered** — an existing skill/agent handles this capability well
- **Partially covered** — an existing skill/agent handles part of it but has gaps
- **Not covered** — no existing skill or agent addresses this capability

Use the skill descriptions from the Context section above. Read the full SKILL.md for any skill that seems like a partial match to confirm coverage.

Present a coverage matrix:

```
| Capability | Coverage | Existing Skill/Agent | Gap |
|------------|----------|---------------------|-----|
| ... | Full / Partial / None | skill-name or -- | description of what is missing |
```

### Step 4: Propose New Skills and Agents

For each gap (Partial or None coverage), determine the right solution:

**Create a SKILL when:**
- The capability is a repeatable workflow invoked by a user or triggered by an event
- It follows a predictable sequence of steps
- It benefits from dynamic context injection

**Create a CUSTOM AGENT when:**
- The capability defines a specialized role or persona (e.g., "security reviewer", "data analyst")
- It will be spawned by other skills as a teammate
- It needs a specific checklist or evaluation framework rather than a workflow

**Extend an existing skill when:**
- The gap is small and fits naturally into an existing skill's scope
- Adding a step or section to an existing skill is cleaner than creating a new one

For each proposal, present:

```
## Proposal {N}: {skill or agent name}

- **Type:** New skill / New agent / Extend existing {name}
- **Covers capabilities:** {list from Step 2}
- **Description:** {1-2 sentences — what it does and when to use it}
- **Key steps:** {numbered list of what the skill/agent would do}
- **Dynamic context needed:** {what live data it would inject}
- **Dependencies:** {other skills/agents it would invoke or coordinate with}
- **Priority:** High / Medium / Low — {rationale}
```

Sort proposals by priority (high first).

### Step 5: User Approval

Present all proposals and ask the user which ones to create. Options:

1. **All** — create everything proposed
2. **Select** — user picks specific proposals by number
3. **Modify** — user wants changes to a proposal before creation
4. **None** — skip creation, keep the analysis as a reference

Wait for the user to choose before proceeding.

### Step 6: Write Approved Skills and Agents

For each approved proposal:

**For new skills:**
1. Create `agents/skills/{name}/SKILL.md`
2. Follow the skill authoring rules from CLAUDE.md:
   - YAML frontmatter with `name` and `description` (description must include trigger keywords)
   - Dynamic context section with bounded, error-safe commands
   - Numbered step-by-step instructions
   - No `$()`, no `||`/`&&` in dynamic context
   - Error-prone commands use `2>/dev/null | head -N`
   - No inline backticks in prose, no contractions
   - No company-specific content (this is a public repo)
3. If the skill references supporting material, create `references/` files alongside the SKILL.md

**For new custom agents:**
1. Create `agents/custom/{name}.md`
2. Follow the existing agent format (YAML frontmatter with `name` and `description`, role definition, approach, output format, principles)

**For extending existing skills:**
1. Read the existing SKILL.md
2. Apply the minimal changes needed to cover the gap
3. Present the diff to the user before applying

### Step 7: Validate

After writing, validate each created file:

**For skills:**
- [ ] `name` in frontmatter matches directory name
- [ ] `description` includes "Use when..." or "Use for..." trigger clause
- [ ] No `$()` in dynamic context lines
- [ ] No `||` or `&&` in dynamic context lines
- [ ] Error-prone commands use `2>/dev/null | head -N`
- [ ] No bare `2>/dev/null` without trailing pipe
- [ ] No inline backticks in prose
- [ ] No contractions
- [ ] No company-specific content
- [ ] SKILL.md is under 500 lines

**For agents:**
- [ ] `name` in frontmatter matches filename (without .md)
- [ ] `description` includes usage context
- [ ] Role and approach are clearly defined
- [ ] Output format is specified

Report validation results for each file.

### Step 8: Update Documentation

After all files are created:

1. Check if the skill routing table in CLAUDE.md needs new entries for auto-activation
2. Check if README.md needs updates (skill counts, tables, etc.)
3. Present any documentation updates needed — apply after user approval

### Step 9: Summary

Present a final report:

```
## Equip Summary

### Source Analyzed
{title, file path, URL, or description of what was analyzed}

### Capabilities Identified
{count} total — {covered} fully covered, {partial} partially covered, {gaps} gaps

### Created
| Type | Name | Covers |
|------|------|--------|
| Skill | /name | capability-1, capability-2 |
| Agent | name | capability-3 |

### Extended
| Skill/Agent | Change | Covers |
|-------------|--------|--------|
| /existing | added step for X | capability-4 |

### Skipped
{list of proposals not created, with reason}

### Next Steps
{any follow-up work identified — testing, integration, dependencies to resolve}
```

## Guidelines

- Prefer fewer, well-scoped skills over many narrow ones — a skill that covers 2-3 related capabilities is better than 3 single-purpose skills
- Do not propose skills for one-off tasks that will not recur
- Do not propose agents unless the role genuinely needs a persistent persona with a checklist
- Keep proposals grounded in what the source actually requires — do not speculatively add "nice to have" skills
- When in doubt about scope, propose the smaller version and note what could be added later
- All created skills and agents must be generic and reusable (public repo policy)
