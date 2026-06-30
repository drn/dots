## ADDED Requirements

### Requirement: Dev-Tool PATH Hook Registration

The `agents` installer SHALL register a `SessionStart` hook running
`agents/hooks/session-start-path.sh` via `bash`, so that go-installed and other
dev-tool binaries resolve by bare name in Claude Code's Bash tool. The hook SHALL
append `export PATH="<dir>:$PATH"` lines to the file named by `$CLAUDE_ENV_FILE`
for each of `$GOBIN` (falling back to `$GOPATH/bin`, then `~/go/bin`),
`~/.cargo/bin`, and `~/.asdf/shims`. The hook SHALL skip directories that do not
exist, SHALL order entries so `go/bin` is the frontmost PATH entry after the file
is sourced, SHALL be idempotent across repeated SessionStart fires within a
session, and SHALL be a no-op when `$CLAUDE_ENV_FILE` is unset. Registration SHALL
reuse the idempotent session-hook machinery, deduplicating by inner command string
so it coexists with the existing memory hook.

#### Scenario: Dev-tool PATH hook registered

- **WHEN** the `agents` installer runs against settings without the dev-tool PATH hook
- **THEN** a `SessionStart` hook running `agents/hooks/session-start-path.sh` is added, alongside any existing `SessionStart` hooks

#### Scenario: Existing dev-tool dirs prepended

- **WHEN** the hook runs with `$CLAUDE_ENV_FILE` set and `~/go/bin` and `~/.asdf/shims` present but `~/.cargo/bin` absent
- **THEN** the env file gains `export PATH="…/go/bin:$PATH"` and `export PATH="…/.asdf/shims:$PATH"` lines, no `~/.cargo/bin` line, and after sourcing the file `go/bin` is the frontmost PATH entry

#### Scenario: Idempotent across repeated fires

- **WHEN** the hook runs twice against the same `$CLAUDE_ENV_FILE`
- **THEN** each dev-tool `export PATH` line appears exactly once

#### Scenario: No env file is a no-op

- **WHEN** the hook runs without `$CLAUDE_ENV_FILE` set
- **THEN** it exits 0 and writes nothing
