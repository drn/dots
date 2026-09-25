## ADDED Requirements

### Requirement: Local Agent Session Discovery
Dream SHALL discover completed turns in local Claude Code and Codex JSONL transcripts. It SHALL use source, session ID, and turn number to avoid processing a completed turn twice, and SHALL check for pending turns before exiting because the KB change log is quiet.

#### Scenario: Session-only activity
- **WHEN** the KB change log has no new writes but a completed turn from either agent is pending
- **THEN** Dream runs ingestion and synthesis for that turn

#### Scenario: Resumed session
- **WHEN** an earlier turn has already been synthesized and a later turn completes in the same session
- **THEN** Dream ingests only the later turn

#### Scenario: Unavailable or incomplete transcript
- **WHEN** an agent's session storage is absent or a transcript has an incomplete or malformed tail
- **THEN** Dream continues with other available sources and does not synthesize the incomplete turn

### Requirement: Local Agent Session Synthesis
Dream SHALL extract bounded user requests and final responses from completed Claude Code and Codex turns into inbox captures and apply its existing session triage and topical synthesis rules. Captures SHALL include source and stable session/turn identity, and SHALL exclude reasoning and tool payloads. Dream SHALL checkpoint a turn only after successful KB handling, and SHALL perform no writes in dry-run mode.

#### Scenario: Durable decision in an agent session
- **WHEN** a completed turn contains a durable decision
- **THEN** Dream merges the decision into the relevant topical KB document and records its provenance in the report

#### Scenario: Low-signal agent session
- **WHEN** a completed turn has no durable facts
- **THEN** Dream discards its inbox capture and records the turn as processed

#### Scenario: Dry run
- **WHEN** Dream runs with `--dry-run` and discovers completed turns
- **THEN** it reports proposed ingest and synthesis without writing to the KB or changing processed-turn state
