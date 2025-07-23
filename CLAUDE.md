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
dots docker stop-all    # Stop all Docker containers
dots spinner            # Display spinner demos
```

### Linting
```bash
go install github.com/mgechev/revive@latest
revive -set_exit_status ./...
```

### Development Dependencies
- Go 1.19+ (go.mod specifies 1.15 but CI uses 1.19.5)
- Homebrew (for managing system dependencies)
- GOPATH and GOBIN properly configured

## Architecture

### Core Structure
- **`main.go`**: Entry point that delegates to `cli/commands.Execute()`
- **`cli/commands/`**: All CLI command implementations using Cobra framework
- **`cmd/`**: Individual utility commands that can be installed as standalone binaries
- **`pkg/`**: Shared utility packages (log, run, cache, path)
- **`cli/is/`**: Helper package for checking commands and files

### Key Components

#### CLI Commands (`cli/commands/`)
- **`root.go`**: Main Cobra command setup and execution
- **`install.go`**: Installation orchestration with interactive prompts
- **`install/`**: Individual installation modules for each component type
- **`update.go`**: Updates configuration
- **`clean.go`**: Cleans legacy configuration
- **`doctor.go`**: Runs system diagnostics:
  - Checks Xcode Command Line Tools
  - Verifies ZSH as default shell
  - Confirms Homebrew installation
  - Checks for /etc/zprofile removal
- **`docker.go`**: Docker command aliases
- **`spinner.go`**: CLI spinner utilities

#### Utility Commands (`cmd/`)
Contains 22 standalone utility commands including:
- Git utilities: `git-ancestor`, `git-canonical-branch`, `git-killme`, `git-masterme`, `git-rebase-master`
- System utilities: `battery-percent`, `cpu`, `gps`, `ip`, `router`, `ssid`
- Development tools: `search-github`, `home-scp`, `spotify`
- Tmux status components: `tmux-status/*`

#### Shared Packages (`pkg/`)
- **`log/`**: Logging utilities with different levels (Info, Action, Raw, Command)
- **`run/`**: Command execution utilities (Verbose, Silent, Capture, Execute)
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
- Use `cli/is` for checking command existence and file presence

### Environment Variables
- `DOTS`: Can specify the dots directory location (used in CI)
- `OPENSSL_CFLAGS`: May be needed for language installations on some systems

### Testing
The project uses integration testing through GitHub Actions CI/CD:
- Tests each installation component individually
- Verifies update command functionality
- No unit tests currently exist in the codebase