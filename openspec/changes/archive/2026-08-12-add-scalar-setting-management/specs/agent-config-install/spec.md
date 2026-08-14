## ADDED Requirements

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
