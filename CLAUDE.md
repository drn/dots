# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Go-based dotfiles management system that provides a CLI tool called `dots` for managing development environment configuration. The system is designed to install and manage various development tools, configurations, and environment settings across macOS systems.

## Build and Development Commands

### Building the Project
```bash
go install ./...
```

### Running the CLI
```bash
dots                    # Show help and available commands
dots install all        # Install all configuration components
dots install <component> # Install specific component (bin, git, home, zsh, fonts, homebrew, npm, languages, vim, hammerspoon, osx)
dots update             # Update configuration
dots clean              # Clean legacy configuration
dots doctor             # Run system diagnostics
```

### Development Dependencies
- Go 1.15+
- Homebrew (for managing system dependencies)
- GOPATH and GOBIN properly configured

## Architecture

### Core Structure
- **`main.go`**: Entry point that delegates to `cli/commands.Execute()`
- **`cli/commands/`**: All CLI command implementations using Cobra framework
- **`cmd/`**: Individual utility commands that can be installed as standalone binaries
- **`pkg/`**: Shared utility packages (log, run, cache, path)

### Key Components

#### CLI Commands (`cli/commands/`)
- **`root.go`**: Main Cobra command setup and execution
- **`install.go`**: Installation orchestration with interactive prompts
- **`install/`**: Individual installation modules for each component type
- **`update.go`**, **`clean.go`**, **`doctor.go`**: Other main commands
- **`spinner.go`**: CLI spinner utilities

#### Utility Commands (`cmd/`)
Contains standalone utility commands like:
- Git utilities: `git-ancestor`, `git-canonical-branch`, `git-killme`, `git-masterme`, `git-rebase-master`
- System utilities: `battery-percent`, `cpu`, `gps`, `ip`, `router`, `ssid`
- Development tools: `search-github`, `home-scp`, `spotify`
- Tmux status components: `tmux-status/*`

#### Shared Packages (`pkg/`)
- **`log/`**: Logging utilities with different levels (Info, Action, etc.)
- **`run/`**: Command execution utilities (Verbose, Silent modes)
- **`cache/`**: Caching functionality
- **`path/`**: Path manipulation utilities

### Installation System
The install system uses reflection to dynamically call install methods based on component names. Each component (bin, git, home, etc.) has its own installation logic in `cli/commands/install/`.

### Command Execution Pattern
Most functionality uses the `pkg/run` package for executing shell commands with proper error handling and output formatting.

## Development Notes

### Adding New Components
1. Add component to the `commands` slice in `cli/commands/install.go`
2. Create corresponding method in `cli/commands/install/` (e.g., `func (i *Install) Newcomponent()`)
3. Use `exec()` helper for command execution with proper error handling

### Adding New Utility Commands
1. Create new directory under `cmd/` with `root.go`
2. Follow existing patterns using Cobra for command structure
3. Commands are automatically built when running `go install ./...`

### Code Patterns
- Use `pkg/log` for consistent logging across components
- Use `pkg/run.Verbose()` for commands that should show output
- Use `pkg/run.Silent()` for commands that should run quietly
- Use `exec()` helper in install modules for commands that must succeed