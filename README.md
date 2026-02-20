<p align="center">
  <img src="favicon.svg" width="120" alt="Dots logo">
</p>

# Dots

> Obsessively curated dotfiles managed by a robust, extensible Go CLI.

[![Github](https://github.com/drn/dots/actions/workflows/main.yml/badge.svg?branch=master)](https://github.com/drn/dots/actions?query=branch%3Amaster)
[![Go Report Card](https://goreportcard.com/badge/github.com/drn/dots)](https://goreportcard.com/report/github.com/drn/dots)
[![Maintainability](https://api.codeclimate.com/v1/badges/8ab4197b56ac54ce9321/maintainability)](https://codeclimate.com/github/drn/dots/maintainability)

![](screenshot.png)

## Overview

Dots is a comprehensive development environment management system built in Go. It provides a CLI tool for installing, updating, and managing your development configuration including:

- Shell configurations (ZSH)
- Development tools and binaries
- Git extensions and configuration
- Vim/Neovim setup
- Homebrew packages
- Programming language environments (via asdf)
- macOS system preferences
- Custom utility commands
- Font management
- Hammerspoon configuration

## System Requirements

- macOS (optimized for macOS systems)
- [Homebrew](https://brew.sh/) package manager
- [Go](https://golang.org/) 1.15+ (recommended: 1.19+)
- ZSH shell (will be set as default)

## Installation

### Prerequisites

1. Install Homebrew:
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. Install Go via Homebrew:
   ```bash
   brew install go
   ```

3. Configure Go environment:
   ```bash
   export GOPATH=$HOME/go
   export PATH=$GOPATH/bin:$PATH
   ```

### Install Dots

```bash
git clone https://github.com/drn/dots ~/.dots
cd ~/.dots
go install ./...
dots install all
```

⚠️ **Warning**: This installation process will overwrite existing configuration files without creating backups. It's recommended to backup your current dotfiles before proceeding.

## Usage

### Primary Commands

```bash
dots                    # Show help and available commands
dots install all        # Install all configuration components
dots install <component> # Install specific component
dots update             # Update configuration
dots clean              # Clean legacy configuration
dots doctor             # Run system diagnostics
dots docker stop-all    # Stop all Docker containers
dots spinner            # Display spinner demos
```

### Installation Components

The `dots install` command supports the following components:

| Component | Description | What it installs |
|-----------|-------------|------------------|
| `all` | Runs all install scripts | Complete environment setup |
| `bin` | Binary utilities | Custom CLI tools in ~/bin |
| `git` | Git configuration | .gitconfig, .gitignore_global, git extensions |
| `home` | Home directory configs | Various .* configuration files |
| `zsh` | ZSH configuration | .zshrc, .zshenv, custom ZSH setup |
| `fonts` | System fonts | Developer fonts via Homebrew Cask |
| `homebrew` | Homebrew packages | System dependencies and tools |
| `npm` | NPM packages | Global Node.js packages |
| `languages` | Programming languages | asdf version manager and language runtimes |
| `vim` | Vim configuration | .vimrc and Vim plugins |
| `hammerspoon` | Hammerspoon config | Window management and automation |
| `osx` | macOS settings | System preferences and defaults |

### System Diagnostics

The `dots doctor` command performs system health checks:

- Xcode Command Line Tools installation
- ZSH as default shell
- Homebrew installation status
- System configuration validation

## Project Structure

```
~/.dots/
├── main.go                 # Entry point
├── go.mod                  # Go module definition
├── cli/                    # CLI implementation
│   ├── commands/          # Command implementations
│   │   ├── root.go        # Main command setup
│   │   ├── install.go     # Install orchestration
│   │   ├── install/       # Component installers
│   │   │   ├── bin.go
│   │   │   ├── git.go
│   │   │   ├── home.go
│   │   │   └── ...
│   │   ├── update.go
│   │   ├── clean.go
│   │   ├── doctor.go
│   │   ├── docker.go
│   │   └── spinner.go
│   └── is/                # Helper utilities
├── cmd/                   # Standalone utilities
│   ├── battery-percent/
│   ├── git-ancestor/
│   ├── git-killme/
│   ├── spotify/
│   ├── tmux-status/
│   └── ...
├── pkg/                   # Shared packages
│   ├── cache/            # Caching utilities
│   ├── log/              # Logging framework
│   ├── path/             # Path utilities
│   └── run/              # Command execution
└── home/                  # Dotfile templates

```

## Custom Utilities

The project includes 22+ custom command-line utilities that are installed to `~/bin`:

### Git Utilities
- `git-ancestor` - Find common ancestor between branches
- `git-canonical-branch` - Get canonical branch name
- `git-killme` - Delete current branch and switch to master
- `git-masterme` - Rebase current branch onto master
- `git-rebase-master` - Interactive rebase onto master
- `git-reset-hard-master` - Hard reset to master

### System Utilities
- `battery-percent` - Display battery percentage
- `battery-state` - Show battery charging state
- `cpu` - CPU usage information
- `router` - Router IP address
- `ssid` - Current WiFi SSID
- `ip` - IP address utilities (local, external, home)

### Development Tools
- `search-github` - Search GitHub repositories
- `spotify` - Spotify control and authentication
- `weather` - Weather information
- `tmux-status/*` - Tmux status bar components

## Development

### Building from Source

```bash
go install ./...
```

### Running Linting

```bash
go install github.com/mgechev/revive@latest
revive -set_exit_status ./...
```

### Adding New Components

1. Add component to the `commands` slice in `cli/commands/install.go`
2. Create installation method in `cli/commands/install/<component>.go`
3. Implement using the `exec()` helper for error handling
4. Use `pkg/run` for command execution

### Adding New Utilities

1. Create directory under `cmd/<utility-name>/`
2. Implement command using Cobra framework in `root.go`
3. Build with `go install ./...`

### Code Conventions

- Use `pkg/log` for consistent logging
- Use `pkg/run.Verbose()` for visible command output
- Use `pkg/run.Silent()` for quiet execution
- Follow existing patterns for error handling
- Maintain consistent code style

## Environment Variables

- `DOTS` - Override dots directory location (default: ~/.dots)
- `GOPATH` - Go workspace (required)
- `GOBIN` - Go binary installation directory

## CI/CD

The project uses GitHub Actions for continuous integration:
- Runs on macOS latest
- Tests each installation component
- Validates update functionality
- Scheduled runs twice daily

## Troubleshooting

### Common Issues

1. **Command not found: dots**
   - Ensure `$GOPATH/bin` is in your PATH
   - Run `go install ./...` from the dots directory

2. **Installation failures**
   - Run `dots doctor` to check system requirements
   - Ensure Homebrew is properly installed
   - Check for sufficient disk space

3. **Permission errors**
   - Some commands may require sudo access
   - Ensure you own the directories being modified

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes following existing patterns
4. Ensure linting passes
5. Submit a pull request

## License

This project is licensed under the [MIT License](LICENSE.md)