## MODIFIED Requirements

### Requirement: Hook Registration

The `agents` installer SHALL register hooks in `~/.claude/settings.json`: a
`PreToolUse` hook matching `Skill` (skill-usage tracking), a `SessionStart` hook
(Argus KB memory injection), and a `PostToolUse` hook matching
`mcp__argus.*__kb_ingest` (KB change tracking). Each hook SHALL invoke its
script under `agents/hooks/` via `bash`. The installer SHALL remove its legacy
`SessionEnd` inbox capture hook if present, while preserving unrelated
`SessionEnd` hooks.

#### Scenario: Skill tracking hook registered

- **WHEN** the `agents` installer runs against settings without the skill-tracking hook
- **THEN** a `PreToolUse` hook with matcher `Skill` running `agents/hooks/track-skill-use.sh` is added

#### Scenario: KB ingest matcher covers Argus server names

- **WHEN** the KB change tracking hook is registered
- **THEN** its `PostToolUse` matcher is `mcp__argus.*__kb_ingest`, covering both legacy and current Argus MCP server names

#### Scenario: Legacy session-end hook removed

- **WHEN** the `agents` installer runs against settings containing its old inbox capture hook and another `SessionEnd` hook
- **THEN** only the inbox capture hook is removed
