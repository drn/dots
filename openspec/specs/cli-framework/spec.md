# cli-framework Specification

## Purpose

The `cli-framework` capability defines how the `dots` binary is structured: the
Cobra-based entry point and command tree, how installable components are
registered and dispatched, the process-exit error model, and the shared support
packages (`pkg/run`, `pkg/path`, `pkg/cache`, `cli/is`, `cli/link`) that every
command builds on.

This spec documents the behavior that ships today.
## Requirements
### Requirement: CLI Entry Point

The `dots` binary SHALL start from `main.go`, which calls
`cli/commands.Execute()`. `Execute()` SHALL register all top-level commands on a
Cobra root command named `dots` and then run it. Invoking `dots` with no
subcommand SHALL print the help text.

#### Scenario: Bare invocation prints help

- **WHEN** a user runs `dots` with no arguments
- **THEN** the root command's `Run` handler invokes `cmd.Help()` and exits 0

#### Scenario: Root execution failure exits non-zero

- **WHEN** `root.Execute()` returns an error
- **THEN** `Execute()` prints the error and calls `os.Exit(1)`

### Requirement: Command Tree

The CLI SHALL register the following top-level commands on the root: `install`,
`update` (alias `up`), `clean`, `doctor`, `spinner`, and `docker` (alias
`dock`). Each command SHALL delegate to its package handler or print help when it
is a grouping command with no direct action.

#### Scenario: Update alias resolves

- **WHEN** a user runs `dots up`
- **THEN** the CLI resolves the `up` alias to the `update` command and runs `update.Run()`

#### Scenario: Docker stop-all alias

- **WHEN** a user runs `dots docker stop` or `dots docker stop-all`
- **THEN** the CLI runs `docker stop $(docker ps -a -q)` to stop all running containers

#### Scenario: Spinner subcommands

- **WHEN** a user runs `dots spinner braille`, `dots spinner dots`, `dots spinner circles`, or `dots spinner console`
- **THEN** the corresponding spinner animation runs

### Requirement: Component Registry and Dispatch

Installable components SHALL be declared in a single ordered slice returned by
`install.Components()`, each entry holding a `Name`, `Description`, optional
`Alias`, and an installer function `Fn`. `install.Call(name)` SHALL dispatch by
performing a linear name match over that slice and invoking the matched `Fn`.

#### Scenario: Named dispatch

- **WHEN** `install.Call("vim")` is invoked
- **THEN** the registry resolves `"vim"` to the `Vim` installer and runs it

#### Scenario: Unmatched dispatch is a no-op

- **WHEN** `install.Call(name)` is invoked with a name absent from the registry
- **THEN** no installer runs and the call returns without error

### Requirement: Process-Exit Error Model

Command and installer code SHALL surface fatal failures by calling `os.Exit(1)`
rather than returning errors to a central handler. The `install.exec()` helper
SHALL run a command via `pkg/run.Verbose` and call `os.Exit(1)` if it fails.

#### Scenario: Installer command failure aborts

- **WHEN** a command run through `install.exec()` returns a non-zero exit
- **THEN** the process exits with code 1

### Requirement: Command Execution Helpers

`pkg/run` SHALL execute shell commands through `zsh -c` with `fmt`-style
formatting of the command string. It SHALL provide `Verbose` (logs then runs,
streams stdout/stderr), `Silent` (runs without logging the command), `Execute`
(logs raw then runs), `Capture` (returns trimmed combined output, logs a warning
on failure), `CaptureClean` (captures with stderr suppressed and surrounding
quotes trimmed), and `OSA` (runs an `osascript -e` command and captures output).

#### Scenario: Capture returns trimmed output

- **WHEN** `run.Capture` runs a command that prints output
- **THEN** it returns the combined stdout/stderr with surrounding whitespace trimmed

#### Scenario: Capture warns on failure

- **WHEN** the captured command exits non-zero
- **THEN** `run.Capture` logs a warning containing the command and error, and still returns the captured output

### Requirement: Path Resolution

`pkg/path` SHALL resolve the dots directory from the `DOTS` environment variable,
defaulting to `~/.dots` when unset. It SHALL provide `Dots()`, `Home()`,
`FromDots(format, args...)`, `FromHome(format, args...)`, `Cache()` (resolving to
`~/.dots/sys/cache`), `FromCache(...)`, and `Pretty()` (which abbreviates the
dots path to `$DOTS` and the home path to `~`).

#### Scenario: DOTS override

- **WHEN** the `DOTS` environment variable is set to a custom directory
- **THEN** `path.Dots()` returns that directory instead of `~/.dots`

#### Scenario: Default dots location

- **WHEN** the `DOTS` environment variable is unset
- **THEN** `path.Dots()` returns `<home>/.dots`

### Requirement: Symlink Management

`cli/link` SHALL create soft links via `link.Soft` (using `os.Symlink`) and hard
links via `link.Hard` (using `os.Link`). Before creating a link, it SHALL remove
any existing file or link at the target path. This overwrite is destructive and
makes no backup.

#### Scenario: Existing target is replaced

- **WHEN** `link.Soft(from, to)` is called and a file already exists at `to`
- **THEN** the existing entry is removed and a new symlink to `from` is created in its place

### Requirement: TTL Cache

`pkg/cache` SHALL provide file-based caching under `~/.dots/sys/cache`, keyed by
filename. `Warm(key, ttlMinutes)` SHALL return true only when the cache file
exists and its modification time is within the TTL. `Read` SHALL return the
file's contents when within TTL and empty string otherwise. `Touch` SHALL write
an empty value to refresh the key.

#### Scenario: Warm within TTL

- **WHEN** a cache key was written less than its TTL ago
- **THEN** `cache.Warm(key, ttl)` returns true

#### Scenario: Cold past TTL

- **WHEN** a cache key's file is older than the TTL or does not exist
- **THEN** `cache.Warm(key, ttl)` returns false

### Requirement: Environment Predicates

`cli/is` SHALL provide boolean environment checks: `File(path)` (path exists),
`Command(name)` (executable resolvable on `PATH`), `Tmux()` (running inside
tmux), and `Osx()` (operating system is darwin).

#### Scenario: Command presence check

- **WHEN** `is.Command("brew")` is called and `brew` is on `PATH`
- **THEN** it returns true

### Requirement: Log Level Control

The root command SHALL accept persistent `--verbose`/`-v` and `--quiet`/`-q` flags
that set the active `pkg/log` level before any subcommand runs. `pkg/log` SHALL gate
output by level: `Error` and `Warning` are always emitted; `Action`, `Info`,
`Success`, `Command`, and `Raw` are emitted at the normal level and above; `Debug`
is emitted only at the verbose level. When both flags are supplied, `--quiet` SHALL
take precedence.

#### Scenario: Quiet suppresses informational output

- **WHEN** a command runs with `--quiet`
- **THEN** `log.Info`, `log.Action`, `log.Success`, `log.Command`, and `log.Raw` produce no output, while `log.Warning` and `log.Error` still print

#### Scenario: Verbose enables debug output

- **WHEN** a command runs with `--verbose`
- **THEN** `log.Debug` output is emitted in addition to the normal-level output

#### Scenario: Default level

- **WHEN** a command runs with neither flag
- **THEN** the log level is normal: informational output prints and `log.Debug` output is suppressed

#### Scenario: Conflicting flags

- **WHEN** a command runs with both `--quiet` and `--verbose`
- **THEN** the quiet level wins and informational output is suppressed

