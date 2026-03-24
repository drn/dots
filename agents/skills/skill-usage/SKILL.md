---
name: skill-usage
description: >
  Show skill usage statistics, charts, and suggestions for pruning unused skills.
  Use when the user asks "skill usage", "which skills do I use", "unused skills",
  "skill stats", or "skill suggestions".
---

# Skill Usage

Show usage analytics for Claude Code skills.

## Arguments

- `$ARGUMENTS` — Optional: period (`day`, `week`, `month`, `all`) or `suggest`

## Instructions

### Default: Usage Chart

Run the `skill-usage` CLI to show a bar chart of skill usage:

```bash
skill-usage --period week
```

- Default period is `week` unless the user specifies otherwise
- Use `--period day`, `--period month`, or `--period all` as requested
- Use `--limit N` to restrict the chart to the top N skills

### Suggest Mode

When the user asks about unused skills, which skills to remove, or skill suggestions:

```bash
skill-usage suggest --period month
```

This shows the highest-leverage skills, never-used skills, and rarely-used skills.

### JSON Output

For programmatic analysis, add `--json`:

```bash
skill-usage --json --period all
skill-usage suggest --json --period month
```

### Presentation

- Present the CLI output directly — it already has colored formatting
- If the user asks follow-up questions about specific skills, explain what each skill does based on your knowledge
- When suggesting removals, note that removing a skill means deleting its directory from `agents/skills/`
