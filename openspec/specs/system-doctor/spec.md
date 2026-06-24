# system-doctor Specification

## Purpose

The `system-doctor` capability defines `dots doctor` — a read-only diagnostic that
checks key environment prerequisites and prints remediation commands for any that
fail, without changing the system.

This spec documents the behavior that ships today.

## Requirements

### Requirement: Diagnostic Checks

`dots doctor` SHALL check, in order: that the Xcode Command Line Tools are
installed, that ZSH is the default shell, that Homebrew is installed, and that
`/etc/zprofile` has been removed. Each passing check SHALL log a success message
and each failing check SHALL log an error.

#### Scenario: Default shell check passes

- **WHEN** `dots doctor` runs and the `SHELL` environment variable points at zsh
- **THEN** it logs that ZSH is the default shell

#### Scenario: Homebrew check fails

- **WHEN** `dots doctor` runs and `brew` is not installed
- **THEN** it logs an error that Homebrew is not installed

### Requirement: Resolution Suggestions

For each failing check, `dots doctor` SHALL print a suggested resolution as one or
more shell commands. `dots doctor` SHALL be read-only — it SHALL NOT apply any
fix itself.

#### Scenario: Failed check suggests remediation

- **WHEN** a diagnostic check fails
- **THEN** `dots doctor` prints the remediation commands for that check and makes no changes to the system
