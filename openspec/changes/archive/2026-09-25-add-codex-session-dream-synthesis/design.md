## Context

Claude Code's session-end hook writes raw captures directly to the KB inbox. Codex stores local JSONL transcripts in date-partitioned directories. Claude Code also stores JSONL transcripts, so Dream can consume both sources directly. Dream currently skips all work when the KB change log is quiet, so transcript discovery must precede that shortcut.

## Decisions

- Use one local extractor for both JSONL formats. It reads user-facing messages, ignores reasoning and tool payloads, and bounds output size. Dream uses the extracted signal to create inbox captures and apply its existing synthesis rules.
- Checkpoint each completed turn independently by source and session ID after successful KB handling. Cache fully processed transcript mtimes to avoid reparsing unchanged files.
- Discover all Codex transcripts because no prior hook captured them. Start Claude discovery near the last Dream run because the prior hook already captured older Claude sessions.
- Read private working-directory exclusions from `~/.dots/sys/dream-session-excludes`, rather than checking personal project names into the public repository.
- Check for pending completed turns before the quiet-KB shortcut. Missing transcript storage for either agent does not block the existing KB audit.
- Ignore incomplete turns and malformed transcript tails; never infer durable facts from incomplete data.
- Remove the legacy Claude Code capture hook registration during installation, while retaining its script temporarily so existing installations do not fail before they are updated.
- Honor `--dry-run` through discovery and reporting without writing inbox documents or processing state.

## Risks / Trade-offs

- Transcripts can contain sensitive or voluminous content. Stream large files, extract only bounded user-facing material, and redact known credential formats before creating inbox notes. Do not copy raw tool output or private reasoning into the KB.
- Codex JSONL structure can evolve. Tolerate unknown record types and test the known session metadata, message, and completion records.
