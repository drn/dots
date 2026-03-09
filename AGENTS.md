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
│   ├── skills/               # Cross-agent skills (SKILL.md per skill)
│   └── custom/               # Custom agent types (.md per agent → ~/.claude/agents/)
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

4. **Testing**: All new Go code must include tests
   - Pure logic functions must have unit tests (`*_test.go` in the same package)
   - Skill scripts with testable logic should have bash tests in `.github/skill-tests/`
   - CI runs `go test ./...` and `bash .github/skill-tests/run_all.sh` — both must pass

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
| agents | Agent skills and custom agents (symlinks agents/skills → ~/.claude/skills + ~/.agents/skills, agents/custom → ~/.claude/agents) |

## Writing Skills / Slash Commands

All skills live in `agents/skills/<name>/SKILL.md` following the [Agent Skills](https://agentskills.io) open standard. This directory is symlinked to both `~/.claude/skills/` (for Claude Code) and `~/.agents/skills/` (for Codex) via `dots install agents`.

Each skill is a directory with a `SKILL.md` entrypoint. Add supporting files (scripts, templates, examples) alongside the SKILL.md when needed.

### Dynamic Context Rules

The `` !`command` `` syntax runs shell commands and injects output as context. **Critical restrictions:**

- **Avoid `$()` command substitution** inside dynamic context expressions. Use plain commands instead — Claude Code blocks `$()` in these expansions for security reasons.
- **Avoid `||` and `&&` operators** — use separate commands or pipes instead. Claude Code's permission system treats these as multiple operations and blocks them.
- **Always pipe through `| head -N`** after `2>/dev/null`. The `2>/dev/null` suppresses stderr but does not fix the exit code — a non-zero exit code breaks the skill loader. Piping through `head` neutralizes the exit code (pipeline exit code = last command = `head` = 0).
- **Never use `origin/HEAD`** in dynamic context — it doesn't exist in repos that weren't `git clone`'d or where the ref wasn't fetched. Detect the base branch with `git branch -r | grep -oE 'origin/(main|master)' | head -1`, or provide both `origin/main` and `origin/master` variants so one always has output.
- **Keep output bounded** with `| head -N` or `| grep` to avoid blowing up context.
- **No agent teams in Conductor.** Do not use `TeamCreate`, `TeamDelete`, `SendMessage`, or `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`. Use parallel `Task` tool calls with sub-agents instead.

```
# BAD — $() blocked by permission system
!`DEFAULT=$(gh repo view ...) && git log origin/$DEFAULT..HEAD`

# BAD — || treated as multiple operations
!`git log origin/main..HEAD --oneline 2>/dev/null || echo "None"`

# BAD — 2>/dev/null alone does not fix exit code, breaks skill loader
!`git log origin/main..HEAD --oneline 2>/dev/null`

# BAD — origin/HEAD doesn't exist in many repos, returns empty context
!`git log origin/HEAD..HEAD --oneline 2>/dev/null | head -50`

# GOOD — detect base branch portably (no custom tools)
- Base ref: !`git branch -r 2>/dev/null | grep -oE 'origin/(main|master)' | head -1`

# GOOD — provide both branches, one will have output
- Commits vs main: !`git log origin/main..HEAD --oneline 2>/dev/null | head -50`
- Commits vs master: !`git log origin/master..HEAD --oneline 2>/dev/null | head -50`
```

See `/write-skill` for the full skill-authoring guide.

### Agent Skills Spec Compliance

All skills must follow the [Agent Skills specification](https://agentskills.io/specification). Key rules enforced by CI:

- **`name`** must match the parent directory name (lowercase, hyphens only, no consecutive hyphens)
- **`description`** must say what the skill does AND when to use it — include a "Use when..." or "Use for..." clause with trigger keywords for auto-activation
- **SKILL.md** should be under 500 lines — extract detailed reference material to `references/` files
- **File references** use relative paths from the skill root, one level deep (e.g., `references/CHECKLIST.md`)
- **Progressive disclosure**: metadata (~100 tokens) loads at startup; full SKILL.md loads on activation; `references/` and `scripts/` load on demand

CI runs `agnix` for schema validation and `.github/lint-skills.sh` for best-practice checks (name/dir match, description quality, line count).

## Skill Auto-Activation

Claude Code auto-activates skills by matching keywords in each skill's `description` field against the user's message. Other agents (Codex, Copilot) do not have this mechanism, so use this routing table instead.

When the user's message matches a phrase below, read and follow the corresponding skill:

| Trigger Phrases | Skill |
|-----------------|-------|
| "last screenshot", "see screenshot", "recent screenshot", "show screenshot", "last N screenshots" | `agents/skills/screenshot/SKILL.md` |
| "investigate CI failures", "find flaky tests", "why is CI failing", "diagnose test flakiness", "flaky CI" | `agents/skills/ci-investigate/SKILL.md` |
| "create skill", "new skill", "write skill", "add a slash command", "improve skill" | `agents/skills/write-skill/SKILL.md` |
| "prioritize", "RICE score", "backlog grooming", "sprint planning", "rank items" | `agents/skills/prioritize/SKILL.md` |
| "swarm", "parallel agents", "agent team in conductor", "multi-agent", "spawn agents" | `agents/skills/swarm/SKILL.md` |
| "skill gap analysis", "missing skills", "missing agents", "equip project", "bootstrap skills from spec", "what skills do I need" | `agents/skills/equip/SKILL.md` |
| "write a plan", "implementation plan", "plan from PRD", "plan from spike", "break down this spec", "planning" | `agents/skills/plan/SKILL.md` |
| "slack", "channel history", "slack search", "slack messages", "find channel", "find user slack", any `#channel-name` reference (e.g. `#app-reviews`, `#rnd-leadership`, `#general`) | `agents/skills/slack/SKILL.md` |
| "email", "gmail", "search email", "read email", "inbox", "email labels" | `agents/skills/email/SKILL.md` |
| "notion", "read notion", "notion page", "notion database" | `agents/skills/notion/SKILL.md` |
| "speak to me", "read to me", "read this aloud", "say this", "speak the summary" | `agents/skills/tts/SKILL.md` |
| "loop", "poll", "recurring", "every N minutes", "babysit", "monitor periodically", "run on interval" | `agents/skills/loop/SKILL.md` |

## Public Repo Policy

This is a public repository. Skills and configuration checked in here must be generic and reusable by anyone.

**Never commit to tracked files:**
- Email addresses, usernames, account names, or other personal identifiers
- Company names, internal tool names, proprietary patterns, or org-specific conventions
- API keys, tokens, secrets, or credential paths that reveal identity
- Hardcoded account lists or user-specific configuration — use dynamic lookups instead (e.g., `gmail accounts` instead of a static table)

Put personal or org-specific knowledge in private project-local CLAUDE.md files, `~/.dots/sys/`, or gitignored directories instead.

## Skill Handoffs from ~/.dots

When receiving a handoff for `~/.dots` skill changes, apply them to this workspace under `agents/skills/`. This repo is the source of truth for skills — `~/.claude/skills/` is a symlink to `agents/skills/` via `dots install agents`.

## README Maintenance

When making changes that affect user-facing features — adding/removing skills, custom agents, CLI commands, components, or utilities — always update `README.md` to reflect those changes. Keep counts, tables, and the project structure tree accurate.

## Pre-Completion Checklist

Before considering any task complete, run the full test suite:

```bash
go install ./...                              # Build all binaries
revive -set_exit_status ./...                 # Run linter
go test ./...                                 # Run Go tests
bash .github/skill-tests/run_all.sh           # Run skill script tests
bash .github/lint-skills.sh                   # Run skill linter
```

Do not skip any of these steps. If any command fails, fix the issue before finishing. This applies to all tasks — feature work, bug fixes, skill changes, and documentation updates.

## Critical Notes

- Installation is destructive (no backups)
- Requires macOS, Homebrew, Go 1.15+
- Uses map-based dispatch for dynamic component installation
- CI runs on GitHub Actions (macOS, Go 1.19.5)