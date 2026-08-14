# agent-config-install Specification

## Purpose

The `agent-config-install` capability defines `dots install agents` — how the
repository's reusable skills, custom agent types, and hooks are wired into Claude
Code and Codex by symlinking directories and mutating `~/.claude/settings.json`.

This spec documents the behavior that ships today.
## Requirements
### Requirement: Skill and Agent Symlinking

The `agents` installer SHALL ensure `~/.claude` and `~/.agents` exist, then
soft-link `agents/skills` into both `~/.claude/skills` and `~/.agents/skills`,
soft-link `agents/custom` into `~/.claude/agents`, and soft-link
`agents/AGENTS.md` into `~/.claude/CLAUDE.md`. If a required parent directory
cannot be created, the installer SHALL abort the remaining work.

#### Scenario: Skills linked for both agents

- **WHEN** the `agents` installer runs
- **THEN** `agents/skills` is soft-linked to both `~/.claude/skills` and `~/.agents/skills`

#### Scenario: Custom agents and global instructions linked

- **WHEN** the `agents` installer runs
- **THEN** `agents/custom` is linked to `~/.claude/agents` and `agents/AGENTS.md` is linked to `~/.claude/CLAUDE.md`

### Requirement: Hook Registration

The `agents` installer SHALL register hooks in `~/.claude/settings.json`: a
`PreToolUse` hook matching `Skill` (skill-usage tracking), a `SessionStart` hook
(Argus KB memory injection), a `SessionEnd` hook (raw inbox capture), and a
`PostToolUse` hook matching `mcp__argus.*__kb_ingest` (KB change tracking). Each
hook SHALL invoke its script under `agents/hooks/` via `bash`.

#### Scenario: Skill tracking hook registered

- **WHEN** the `agents` installer runs against settings without the skill-tracking hook
- **THEN** a `PreToolUse` hook with matcher `Skill` running `agents/hooks/track-skill-use.sh` is added

#### Scenario: KB ingest matcher covers Argus server names

- **WHEN** the KB change tracking hook is registered
- **THEN** its `PostToolUse` matcher is `mcp__argus.*__kb_ingest`, covering both legacy and current Argus MCP server names

### Requirement: Idempotent Hook Registration

Hook registration SHALL be idempotent. Matcher-style hooks (`PreToolUse`,
`PostToolUse`) SHALL be deduplicated by their `matcher` value; session-style
hooks (`SessionStart`, `SessionEnd`) SHALL be deduplicated by their inner command
string. A hook already present SHALL NOT be added a second time.

#### Scenario: Re-running does not duplicate hooks

- **WHEN** the `agents` installer runs a second time
- **THEN** no duplicate hook entries are added to `settings.json`

### Requirement: Status Line Registration

The `agents` installer SHALL set `statusLine` in `~/.claude/settings.json` to run
`agents/hooks/statusline.sh` via `bash`, replacing it only when the configured
command differs from the existing one.

#### Scenario: Status line set when absent or different

- **WHEN** the `agents` installer runs and the configured status line command is not already present
- **THEN** `settings.statusLine` is set to the statusline script command

#### Scenario: Status line unchanged when identical

- **WHEN** the `agents` installer runs and `settings.statusLine` already matches the configured command
- **THEN** `settings.json` is left unchanged for the status line

### Requirement: Settings File Handling

Settings mutation SHALL read `~/.claude/settings.json`, treat a missing file as
an empty object, preserve existing keys, and write the result back as indented
JSON. When the file does not yet exist, it SHALL be created with mode `0600`;
when it exists, its current mode SHALL be preserved.

#### Scenario: Missing settings file treated as empty

- **WHEN** settings mutation runs and `~/.claude/settings.json` does not exist
- **THEN** mutation proceeds against an empty object and writes a new file with mode 0600

#### Scenario: Existing keys preserved

- **WHEN** settings mutation adds a hook to a file with unrelated keys
- **THEN** the unrelated keys are retained in the written file

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

### Requirement: Scalar Setting Management

The `agents` installer SHALL provide a generic mechanism to ensure a
top-level scalar key in `~/.claude/settings.json` matches a configured value.
The mechanism SHALL set the key when absent, overwrite it when the existing
value differs, and leave `settings.json` unwritten when the existing value
already matches the configured value (compared by JSON-marshaled
representation, so equivalent numeric encodings such as `1095` and `1095.0`
count as matching).

#### Scenario: Key absent is set

- **WHEN** the configured key is not present in `settings.json`
- **THEN** it is added with the configured value

#### Scenario: Drifted value is overwritten

- **WHEN** the configured key is present with a value different from the configured value
- **THEN** `settings.json` is rewritten with the configured value

#### Scenario: Matching value is left untouched

- **WHEN** the configured key already holds a JSON-equal value
- **THEN** `settings.json` is not rewritten

### Requirement: Local Transcript Retention Configuration

The `agents` installer SHALL set `cleanupPeriodDays` to `1095` (3 years) in
`~/.claude/settings.json` using the scalar setting management mechanism, so
local Claude Code session transcript retention is consistently configured on
every machine where `dots install agents` runs.

#### Scenario: Retention period configured

- **WHEN** the `agents` installer runs against settings without `cleanupPeriodDays`
- **THEN** `cleanupPeriodDays` is set to `1095`

#### Scenario: Re-running is idempotent

- **WHEN** the `agents` installer runs again with `cleanupPeriodDays` already `1095`
- **THEN** `settings.json` is left unchanged for that key

