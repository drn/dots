# CLAUDE.md

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

## Critical Notes

- Installation is destructive (no backups)
- Requires macOS, Homebrew, Go 1.15+
- Uses reflection for dynamic component installation
- CI runs on GitHub Actions (macOS, Go 1.19.5)