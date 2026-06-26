## ADDED Requirements

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
