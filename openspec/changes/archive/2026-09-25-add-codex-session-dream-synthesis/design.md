## Context

Claude Code's session-end hook writes raw captures directly to the KB inbox. Codex stores local JSONL transcripts in date-partitioned directories. Claude Code also stores JSONL transcripts, so Dream can consume both sources directly. Dream currently skips all work when the KB change log is quiet, so transcript discovery must precede that shortcut.

## Decisions

- Use one local extractor for both JSONL formats. It reads user-facing messages, ignores reasoning and tool payloads, and bounds output size. Dream uses the extracted signal to create inbox captures and apply its existing synthesis rules.
- Checkpoint by source, session ID, and completed turn number after successful KB handling. This avoids reingestion after inbox deletion and permits later turns in resumed sessions.
- Check for pending completed turns before the quiet-KB shortcut. Missing transcript storage for either agent does not block the existing KB audit.
- Ignore incomplete turns and malformed transcript tails; never infer durable facts from incomplete data.
- Remove the legacy Claude Code capture hook registration during installation, while retaining its script temporarily so existing installations do not fail before they are updated.
- Honor `--dry-run` through discovery and reporting without writing inbox documents or processing state.

## Risks / Trade-offs

- Transcripts can contain sensitive or voluminous content. Extract only bounded, user-facing material needed for synthesis; do not copy raw tool output or private reasoning into the KB.
- Codex JSONL structure can evolve. Tolerate unknown record types and test the known session metadata, message, and completion records.
