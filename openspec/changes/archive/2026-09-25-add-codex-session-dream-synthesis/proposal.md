# Change: Synthesize Claude Code and Codex JSONL sessions in Dream

## Why

Dream relies on a Claude Code session-end hook to fill its KB inbox. Codex does not run that hook, so Codex work never reaches Dream. Using both agents' local JSONL transcripts gives Dream one ingestion path. Dream's early exit on an unchanged KB must also account for new transcripts.

## What Changes

- Discover completed turns in local Claude Code and Codex JSONL transcripts.
- Extract bounded, useful session signal into one inbox synthesis flow, with source provenance and stable session/turn IDs.
- Consider pending turns from both agents before Dream's quiet-KB early exit; checkpoint each turn after successful synthesis, including when the inbox capture is deleted.
- Stop registering the Claude Code session-end capture hook and remove a previously registered copy on the next `dots install agents` run.
- Preserve unattended operation, dry-run behavior, and graceful handling of absent or malformed transcripts.
- Update the Dream instructions, focused skill tests, and README description.

## Impact

- Affected specs: `knowledge-maintenance` (new capability), `agent-config-install`
- Affected code: `agents/skills/dream/`, `cli/commands/install/agents.go`, `.github/skill-tests/`, `README.md`
- Local input: Claude Code JSONL transcripts under `~/.claude/projects/` and Codex JSONL transcripts under the configured Codex home (normally `~/.codex/sessions/`)
