# Project Context

## Purpose
`dots` is a personal dotfiles manager and system bootstrapper for macOS. It provides a CLI (`dots`) to install, configure, and maintain development environment components (shell, editor, fonts, languages, homebrew packages, etc.) from a single repository.

## Tech Stack
- Go 1.24.10 (module target: 1.15)
- Cobra CLI framework
- macOS (Homebrew, ZSH, Neovim, Hammerspoon)
- asdf for language runtime management
- GitHub Actions CI

## Project Conventions

### Code Style
- Go standard formatting (`gofmt`)
- Linted with `revive`
- Minimal abstractions — prefer direct shell execution via `pkg/run`
- Component installers are methods on an `Install` struct in `cli/commands/install/`

### Architecture Patterns
- Entry point: `main.go` → `cli/commands.Execute()` (Cobra)
- Shared utilities in `pkg/` (log, run, path, cache)
- CLI helpers in `cli/` (is, link, config, tmux)
- Standalone utilities in `cmd/` (git helpers, system info, tmux status)
- Dynamic installer dispatch via reflection on method names

### Testing Strategy
- No unit tests currently exist
- Integration testing via GitHub Actions (each component tested in isolation)
- `revive` linter in CI

### Git Workflow
- Branch from master, prefix with `drn/`
- Squash-merge PRs

## Domain Context
This is a personal developer tooling repository. "Installation" means symlinking config files, running brew commands, and setting macOS defaults. Components are independent and idempotent.

## Important Constraints
- macOS only (uses Homebrew, AppleScript, macOS defaults)
- Installation is destructive (overwrites existing configs, no backups)
- Go 1.15 module minimum in go.mod (should be bumped)

## External Dependencies
- Homebrew (package management)
- asdf (language runtime management)
- GitHub Actions (CI/CD)
- Spotify API (cmd/spotify utility)
