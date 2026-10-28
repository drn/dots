# config-update Specification

## Purpose

The `config-update` capability defines `dots update` and `dots clean` — keeping an
already-installed environment current (pulling the dots repo, updating plugin
managers, packages, runtimes, and tools) and pruning stale package and editor
artifacts.

This spec documents the behavior that ships today.

## Requirements

### Requirement: Update Orchestration

`dots update` SHALL update the environment in sequence: pull and reinstall the
dots repository (`git fetch`, `git reset --hard origin/master`, `go install
./...`), update ZSH plugins via zinit (pruning broken completion symlinks),
update tmux plugins, update Homebrew and outdated packages, update Claude Code,
Devbox, pi.dev, and the solargraph gem, reshim asdf, and reinstall the `vim`
component. It SHALL set the tmux window title to `update` while running and
restore it afterward.

#### Scenario: Dots repo pulled and rebuilt

- **WHEN** `dots update` runs
- **THEN** it fetches and hard-resets the dots repo to `origin/master` and runs `go install ./...`

#### Scenario: Vim component reinstalled

- **WHEN** `dots update` runs
- **THEN** it invokes the `vim` installer as part of the update sequence

#### Scenario: pi.dev updated

- **WHEN** `dots update` runs and `pi` is on `PATH`
- **THEN** it runs `pi update` to self-update the pi.dev binary

### Requirement: Weekly Auto-Clean

`dots update` SHALL run the cleanup routine before updating only when the
`dots-clean` cache key is older than one week, refreshing that key afterward.
Within a week of the last clean, the cleanup step SHALL be skipped.

#### Scenario: Clean skipped when recently run

- **WHEN** `dots update` runs and the `dots-clean` cache key is less than a week old
- **THEN** the cleanup routine is skipped

#### Scenario: Clean run when stale

- **WHEN** `dots update` runs and the `dots-clean` cache key is older than a week or absent
- **THEN** the cleanup routine runs and the `dots-clean` key is refreshed

### Requirement: Conditional Tool Updates

`dots update` SHALL skip updating Claude Code, Devbox, and pi.dev when their
commands are not resolvable on `PATH`, logging that they are not installed
rather than failing.

#### Scenario: Missing tool skipped

- **WHEN** `dots update` runs and `devbox` is not on `PATH`
- **THEN** the Devbox update is skipped with an informational log and the update continues

#### Scenario: Missing pi.dev skipped

- **WHEN** `dots update` runs and `pi` is not on `PATH`
- **THEN** the pi.dev update is skipped with an informational log and the update continues

### Requirement: Cleanup Command

`dots clean` SHALL clean legacy artifacts: `brew cleanup -s` for Homebrew and
`PlugClean!` for Neovim plugins. It SHALL set the tmux window title to `clean`
while running and restore it afterward.

#### Scenario: Cleanup removes stale artifacts

- **WHEN** `dots clean` runs
- **THEN** it runs `brew cleanup -s` and removes uninstalled Neovim plugins
