<!-- OPENSPEC:START -->
# OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:
- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:
- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->

# AGENTS.md

This file provides essential context for AI assistants working with the dots repository.

## Quick Start

Build and run the CLI:
```bash
go install ./...
dots
```

## Essential Commands for Development

### Building & Testing
```bash
go install ./...                              # Build all binaries
revive -set_exit_status ./...                # Run linter
```

### Core CLI Commands
```bash
dots install all                              # Full system setup
dots install <component>                      # Install specific component
dots update                                   # Update configuration
dots doctor                                   # Run diagnostics
```

## Repository Structure

```
/Users/darrencheng/.dots/
├── main.go                    # Entry point → cli/commands.Execute()
├── cli/commands/              # All CLI commands (Cobra framework)
│   ├── install.go            # Install orchestration
│   └── install/              # Component installers
├── agents/
│   └── skills/               # Cross-agent skills (SKILL.md per skill)
├── cmd/                      # 22 standalone utilities
└── pkg/                      # Shared utilities (log, run, cache, path)
```

## Key Development Patterns

1. **Command Execution**: Use `pkg/run` package
   - `run.Verbose()` - Show output
   - `run.Silent()` - Hide output
   - `exec()` helper in installers for error handling

2. **Adding Components**: 
   - Add to `commands` slice in `cli/commands/install.go`
   - Create method in `cli/commands/install/<component>.go`

3. **Logging**: Use `pkg/log` for consistent output

## Component Reference

| Component | Installs |
|-----------|----------|
| bin | ~/bin utilities |
| git | Git configuration |
| home | Dotfiles in ~/ |
| zsh | ZSH configuration |
| fonts | Developer fonts |
| homebrew | System packages |
| npm | Global NPM packages |
| languages | asdf & runtimes |
| vim | Vim configuration |
| hammerspoon | Window management |
| osx | macOS defaults |
| claude | Claude Code skills (symlinks agents/skills → ~/.claude/skills) |
| codex | Codex skills (symlinks agents/skills → ~/.agents/skills) |

## Writing Skills / Slash Commands

All skills live in `agents/skills/<name>/SKILL.md` following the [Agent Skills](https://agentskills.io) open standard. This directory is symlinked to both `~/.claude/skills/` (for Claude Code) and `~/.agents/skills/` (for Codex) via `dots install claude` and `dots install codex`.

Each skill is a directory with a `SKILL.md` entrypoint. Add supporting files (scripts, templates, examples) alongside the SKILL.md when needed.

### Dynamic Context Rules

The `` !`command` `` syntax runs shell commands and injects output as context. **Critical restrictions:**

- **Avoid `$()` command substitution** inside dynamic context expressions. Use plain commands instead — Claude Code blocks `$()` in these expansions for security reasons.
- **Avoid `||` and `&&` operators** — use separate commands or pipes instead. Claude Code's permission system treats these as multiple operations and blocks them.
- **Always pipe through `| head -N`** after `2>/dev/null`. The `2>/dev/null` suppresses stderr but does not fix the exit code — a non-zero exit code breaks the skill loader. Piping through `head` neutralizes the exit code (pipeline exit code = last command = `head` = 0).
- **Use `origin/HEAD`** instead of hardcoding `origin/main` or `origin/master` for default branch references.
- **Keep output bounded** with `| head -N` or `| grep` to avoid blowing up context.
- **No agent teams in Conductor.** Do not use `TeamCreate`, `TeamDelete`, `SendMessage`, or `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`. Use parallel `Task` tool calls with sub-agents instead.

```
# BAD — $() blocked by permission system
!`DEFAULT=$(gh repo view ...) && git log origin/$DEFAULT..HEAD`

# BAD — || treated as multiple operations
!`git log origin/main..HEAD --oneline 2>/dev/null || echo "None"`

# BAD — 2>/dev/null alone does not fix exit code, breaks skill loader
!`git log origin/HEAD..HEAD --oneline 2>/dev/null`

# GOOD — pipe neutralizes exit code, empty output on failure is fine
!`git log origin/HEAD..HEAD --oneline 2>/dev/null | head -50`
```

See `/write-skill` for the full skill-authoring guide.

## Critical Notes

- Installation is destructive (no backups)
- Requires macOS, Homebrew, Go 1.15+
- Uses reflection for dynamic component installation
- CI runs on GitHub Actions (macOS, Go 1.19.5)