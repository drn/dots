---
name: scaffold
description: Bootstrap new components, files, or modules matching existing repo conventions and patterns
---

# Scaffold

Create boilerplate files matching the conventions of the current repository. Analyzes existing patterns before generating anything.

## Arguments

- `$ARGUMENTS` - Required: what to scaffold (e.g., "go command", "installer", "test for pkg/cache", "react component", "api endpoint")

## Context

- Project type: !`find . -maxdepth 1 \( -name go.mod -o -name Gemfile -o -name package.json -o -name Cargo.toml -o -name pyproject.toml -o -name CLAUDE.md -o -name AGENTS.md \) 2>/dev/null | head -10`
- Top-level structure: !`find . -maxdepth 1 -type d -not -name '.*' 2>/dev/null | head -20`
- Source files: !`find . -maxdepth 3 -type f \( -name "*.go" -o -name "*.rb" -o -name "*.ts" -o -name "*.tsx" -o -name "*.py" -o -name "*.rs" \) -not -path './vendor/*' -not -path './node_modules/*' 2>/dev/null | head -30`

## Instructions

### Step 0: Check for skill redirect

IF `$ARGUMENTS` mentions "skill", "slash command", or "agent skill", tell the user: "Use `/write-skill` for creating agent skills — it has specialized knowledge for that." and stop.

### Step 1: Parse request

Extract from `$ARGUMENTS`:
- **What:** The type of thing to scaffold (command, component, test, endpoint, module, etc.)
- **Name:** The name for the new thing
- **Location:** Where it should go (infer from conventions if not specified)

IF the request is unclear, ask the user to clarify before proceeding.

### Step 2: Analyze existing patterns

Find 2-3 existing examples of the same type in the codebase:

1. Use Glob to find files matching the pattern (e.g., for "go command", look at `cmd/*/main.go` or `cli/commands/*.go`).
2. Read the examples to extract:
   - File naming convention (snake_case, camelCase, kebab-case)
   - Directory structure (flat, nested, grouped)
   - Import patterns and boilerplate
   - Common patterns (interfaces implemented, base classes extended, hooks used)
   - Test file location and naming

IF no existing examples are found, ask the user: "I could not find existing examples of <type> in this repo. Can you point me to an example to follow, or describe the convention?"

### Step 3: Plan the scaffold

Present the planned file tree before creating anything:

```markdown
## Scaffold Plan: <name>

Based on existing patterns (analyzed: <example1>, <example2>):

### Files to create
- `<path/to/file1>` — <purpose>
- `<path/to/file2>` — <purpose>
- `<path/to/test>` — <purpose>

### Convention notes
- Naming: <convention observed>
- Structure: <pattern observed>
- Boilerplate: <what will be included>
```

Wait for user confirmation before creating files.

### Step 4: Generate files

Create each file following the conventions extracted in Step 2:

- Match the exact style of existing files (indentation, import ordering, comment style)
- Include TODO comments for sections the user needs to fill in
- Include the test file with a basic structure matching existing test patterns
- Do NOT add features or complexity beyond what the user asked for

### Step 5: Report

List the files created and suggest next steps:

```markdown
## Created

| File | Purpose |
|------|---------|
| <path> | <brief> |

### Next steps
- [ ] Fill in TODO sections
- [ ] Run tests: `<test command>`
- [ ] <any registration or wiring step needed>
```
