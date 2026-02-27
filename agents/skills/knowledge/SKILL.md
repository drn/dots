---
name: knowledge
description: Initialize or update a project knowledge base for durable cross-session knowledge capture
---
# Knowledge Base

Manage a structured knowledge base at `context/knowledge/` for capturing durable facts, entities, and patterns across sessions.

## Arguments

- `$ARGUMENTS` - Subcommand: `init`, `add <topic>`, `update <topic>`, or omit for status

## Context

- Knowledge index: !`cat context/knowledge/index.md 2>/dev/null | head -50`
- Knowledge files: !`ls -1 context/knowledge/*.md 2>/dev/null | head -20`
- Project root: !`git rev-parse --show-toplevel 2>/dev/null | head -1`
- CLAUDE.md exists: !`ls CLAUDE.md AGENTS.md 2>/dev/null | head -2`

## Instructions

### Subcommand: init

Create the knowledge base directory and seed it with an index file.

1. Create `context/knowledge/` directory
2. Write `context/knowledge/index.md` with this template:

```markdown
# Knowledge Index

Structured knowledge for future knowledge graph ingestion. Each file covers a topic/domain.

| File | Topic | Key Entities | Last Updated |
|------|-------|-------------|-------------|

## Coverage Map

Which context files are captured in knowledge:

| Context File | Knowledge File(s) | Coverage |
|-------------|-------------------|----------|
```

3. If the project has a `.gitignore`, verify `context/knowledge/` is not ignored
4. Report the path created and suggest initial topics based on what is visible in the repo (CLAUDE.md, AGENTS.md, README, directory structure)

### Subcommand: add <topic>

Create a new topic file and register it in the index.

1. Read the existing index to avoid duplicates
2. Ask what entities and facts to capture if not obvious from conversation context
3. Create `context/knowledge/<topic>.md` with a heading and structured content
4. Update `context/knowledge/index.md` — add a row to the index table with the file name, topic description, key entities, and today's date
5. Report what was added

### Subcommand: update <topic>

Update an existing topic file with new knowledge.

1. Read `context/knowledge/index.md` to find the topic file
2. Read the topic file
3. Propose additions or corrections as diffs
4. Apply after user approval
5. Update the Last Updated date in `context/knowledge/index.md`

### Subcommand: (no args) — status

Show the current state of the knowledge base:
- Number of topic files and total coverage
- Topics with the oldest Last Updated dates
- Coverage gaps (context files or CLAUDE.md sections not yet captured)

## Knowledge File Format

Each topic file should follow this pattern:

```markdown
# Topic Name

Brief description of what this file covers.

## Section

- **Entity**: Description or fact
- **Entity**: Description or fact

## Section

...
```

Guidelines for content:
- Use bold for entity names and key terms
- Group related facts under clear section headings
- Include specific values, names, versions — not vague summaries
- Each fact should stand alone (no "as mentioned above" references)
- Date-stamp volatile facts (pricing, team composition, versions)

## What Belongs in Knowledge

- People, roles, org structure
- Technical infrastructure and architecture decisions
- Product features, business logic, domain concepts
- Integration partners, vendors, external services
- Debugging insights that will recur
- Non-obvious tool or dependency behavior

## What Does NOT Belong in Knowledge

- Operational items (todos, plans, schedules)
- Session-specific transients
- Information already in CLAUDE.md or AGENTS.md
- Speculation or unverified claims
- Full documents (link to them instead, capture key facts)
