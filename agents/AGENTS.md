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
