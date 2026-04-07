## Skill Routing

**Always check available skills FIRST before trying CLI commands, sub-agents, or MCP tool workarounds.**

- **Slack**: Use the `/slack` skill. The `slack` CLI is a standalone system binary, NOT part of any project CLI.
- **Email**: Use the `/email` skill for reading Gmail. MCP tools (`mcp__gmail__*`) also work.
- **Notion**: MCP tools (`mcp__notion__*`) work for reading. Use the `/notion` skill for writing/updating pages.
- **General rule**: If a task matches an available skill, invoke `Skill("<name>")` before attempting any other approach.

## TTS Notifications

**ALWAYS speak aloud when completing ANY task or waiting for user input.**

After finishing work, generate a task-specific summary (6 words max) and speak it:
```bash
tts -s 1.1 "<SUMMARY>"           # default
tts -s 1.1 -v alloy "<SUMMARY>"  # for thanx repos (git remote contains "thanx")
```

## Memory

Built-in auto-memory is disabled. Use **argus-kb** MCP tools for all memory operations.

### Tools

| Operation | Tool | Example |
|-----------|------|---------|
| Save | `mcp__argus-kb__kb_ingest(path, content)` | `kb_ingest("memory/user/preferences.md", "Prefers concise output...")` |
| Search | `mcp__argus-kb__kb_search(query)` | `kb_search("user coding preferences")` |
| Read | `mcp__argus-kb__kb_read(path)` | `kb_read("memory/user/preferences.md")` |
| List | `mcp__argus-kb__kb_list(prefix)` | `kb_list("memory/")` |

### Path Convention

Store memories at `memory/<type>/<name>.md`:

- **user** — Personal preferences, communication style, workflow habits
- **feedback** — Corrections and "don't do X" instructions from the user
- **project** — Project-specific context, architecture decisions, conventions
- **reference** — Reusable facts, lookup tables, environment details

### When to Save

- User states a preference or corrects your behavior → `memory/feedback/`
- User shares personal/workflow context ("I prefer...", "I always...") → `memory/user/`
- You learn a project convention or architecture detail → `memory/project/`
- User provides reference data (accounts, endpoints, etc.) → `memory/reference/`

### When to Recall

- Start of a new conversation → `kb_list("memory/user/")` and `kb_list("memory/feedback/")` to load preferences
- Working in a specific project → `kb_search("<project name> conventions")`
- Uncertain about a past decision or preference → `kb_search("<topic>")`
