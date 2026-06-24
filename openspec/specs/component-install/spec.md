# component-install Specification

## Purpose

The `component-install` capability defines `dots install` — how a user selects
components, how `install all` orchestrates a full bootstrap, and the
behavior of each individual component installer (shell, editor, fonts, packages,
languages, macOS defaults, developer tools, and the pi.dev agent).

The `agents` component has its own behavior documented in the
`agent-config-install` capability.

This spec documents the behavior that ships today, including its destructive,
no-backup nature.

## Requirements

### Requirement: Component Selection

`dots install` with no arguments SHALL present an interactive selection menu
listing `all` followed by every registered component name. `dots install all`
SHALL install every component. `dots install <component>` SHALL install only the
named component. Running `dots install` with stray positional arguments SHALL
print help and exit 1.

#### Scenario: Interactive selection of a component

- **WHEN** a user runs `dots install` and selects a component name from the prompt
- **THEN** that component's installer runs

#### Scenario: Interactive selection of all

- **WHEN** a user runs `dots install` and selects `all`
- **THEN** the full install-all orchestration runs

#### Scenario: Direct named install

- **WHEN** a user runs `dots install vim`
- **THEN** only the `vim` installer runs

### Requirement: Component Registry and Aliases

The installable components SHALL be, in order: `bin`, `git`, `home`, `zsh`,
`fonts`, `homebrew` (alias `brew`), `npm`, `languages`, `vim`, `hammerspoon`
(alias `hs`), `tools`, `osx`, `agents`, and `pi`. Each registered component name
and alias SHALL be exposed as a Cobra subcommand of `install`.

#### Scenario: Alias resolves to component

- **WHEN** a user runs `dots install brew`
- **THEN** the `homebrew` installer runs

#### Scenario: Hammerspoon alias

- **WHEN** a user runs `dots install hs`
- **THEN** the `hammerspoon` installer runs

### Requirement: Install-All Orchestration

`dots install all` SHALL first prime `sudo` access by running a `sudo` echo
command, exiting 1 if it fails, then invoke each component installer in registry
order.

#### Scenario: Sudo priming precedes installs

- **WHEN** `dots install all` runs
- **THEN** it requests sudo access before running any component installer, and exits 1 if sudo access cannot be obtained

### Requirement: Symlink-Based Config Installation

The `bin`, `git`, `home`, and `hammerspoon` components SHALL install by creating
soft links from the dots repository into the home directory; `fonts` SHALL
install via hard links into `~/Library/Fonts`. These links overwrite existing
targets without backup. The `home` component SHALL link each entry under
`home/` to `~/.<entry>`; `hammerspoon` SHALL additionally reload Hammerspoon via
AppleScript after linking.

#### Scenario: Home dotfiles linked with leading dot

- **WHEN** the `home` installer runs
- **THEN** each entry under `home/` is soft-linked to `~/.<entry>`

#### Scenario: Fonts hard-linked

- **WHEN** the `fonts` installer runs
- **THEN** each font under `fonts/` is hard-linked into `~/Library/Fonts/`

#### Scenario: Hammerspoon reload

- **WHEN** the `hammerspoon` installer finishes linking `~/.hammerspoon`
- **THEN** it triggers `hs.reload()` in the Hammerspoon application via AppleScript

### Requirement: Package Installation

The `homebrew` component SHALL run `brew update`, `brew bundle` against the
repository `Brewfile`, start the `mysql@8.0` and `postgresql@16` services, and
ensure `~/.z` exists. The `npm` component SHALL install a fixed list of global
packages, skipping any already present in the global package list.

#### Scenario: Homebrew bundle from Brewfile

- **WHEN** the `homebrew` installer runs
- **THEN** it runs `brew bundle` against the repository `Brewfile` and starts the MySQL and PostgreSQL services

#### Scenario: npm skips installed packages

- **WHEN** the `npm` installer runs and a target package is already in the global package list
- **THEN** that package is not reinstalled

### Requirement: Language Runtime Installation

The `languages` component SHALL ensure `asdf` is installed, then add plugins and
install pinned versions for Ruby, Python (2 and 3), Terraform, Node.js, and Go,
setting each as the active version. It SHALL also install editor support gems and
pip packages (neovim, pynvim, flake8, wakatime) and link `flake8` into `~/bin`.

#### Scenario: Pinned runtime versions installed

- **WHEN** the `languages` installer runs
- **THEN** it installs and activates each language at its pinned version (e.g. Ruby 3.4.7, Go 1.24.10, Node.js 24.2.0) via asdf

### Requirement: macOS Defaults

The `osx` component SHALL apply a set of macOS `defaults` and finish by
restarting `Dock`, `Finder`, and `SystemUIServer`. It SHALL refuse to run on a
non-darwin machine, exiting 1.

#### Scenario: Refuses on non-darwin

- **WHEN** the `osx` installer runs on a non-darwin operating system
- **THEN** it logs an error and exits 1 without applying any defaults

#### Scenario: Defaults applied on macOS

- **WHEN** the `osx` installer runs on macOS
- **THEN** it writes the configured `defaults` and restarts Dock, Finder, and SystemUIServer

### Requirement: Shell Environment Setup

The `zsh` component SHALL remove `/etc/zprofile` when present, install the tmux
plugin manager (tpm) and the zinit plugin manager, cloning each idempotently.

#### Scenario: zprofile removed when present

- **WHEN** the `zsh` installer runs and `/etc/zprofile` exists
- **THEN** it removes `/etc/zprofile`

#### Scenario: Plugin managers installed

- **WHEN** the `zsh` installer runs
- **THEN** it ensures tpm and zinit are cloned and updated to their latest master

### Requirement: Editor Setup

The `vim` component SHALL link all `vim/` configuration into `~/.vim`, create
Neovim compatibility links (`~/.config/nvim`, `~/.nvim`, `~/.nvimrc`,
`~/.config/nvim/init.vim`), install `vim-plug` if missing, and update plugins.

#### Scenario: Neovim compatibility links created

- **WHEN** the `vim` installer runs
- **THEN** it links `~/.vim` to `~/.config/nvim` and `~/.nvim`, and `~/.vimrc` to the Neovim init paths

#### Scenario: vim-plug bootstrapped when missing

- **WHEN** the `vim` installer runs and `~/.vim/autoload/plug.vim` does not exist
- **THEN** it downloads `vim-plug` to that path

### Requirement: Developer Tool Installation

The `tools` component SHALL install Devbox, Claude Code, and Codex, skipping each
when the corresponding command is already resolvable on `PATH`.

#### Scenario: Already-installed tool skipped

- **WHEN** the `tools` installer runs and `claude` is already on `PATH`
- **THEN** Claude Code is not reinstalled

#### Scenario: Missing tool installed

- **WHEN** the `tools` installer runs and `devbox` is not on `PATH`
- **THEN** it installs Devbox via its install script

### Requirement: pi.dev Agent Installation

The `pi` component SHALL install the pi.dev CLI when `pi` is not on `PATH`,
always reconcile the `~/.pi/agent/models.json` symlink to the repository copy,
and seed `defaultProvider` and `defaultModel` into `~/.pi/agent/settings.json`.
The settings seed SHALL merge into any existing content, be idempotent when both
fields already match, and write atomically via a tempfile rename. `auth.json` and
`sessions/` SHALL be left untouched.

#### Scenario: Config symlink reconciled even when installed

- **WHEN** the `pi` installer runs and `pi` is already on `PATH`
- **THEN** it still re-creates the `~/.pi/agent/models.json` symlink and seeds settings

#### Scenario: Idempotent settings seed

- **WHEN** the `pi` installer runs and `defaultProvider` and `defaultModel` already match the seeded values
- **THEN** `settings.json` is left unchanged

#### Scenario: Settings merge preserves other keys

- **WHEN** the `pi` installer seeds settings into an existing `settings.json` with other keys
- **THEN** the other keys are preserved and the file is written atomically
