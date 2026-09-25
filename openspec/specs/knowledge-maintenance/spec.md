# knowledge-maintenance Specification

## Purpose
Dream's unattended KB maintenance ingests local agent sessions, extracts durable facts, and tracks which completed turns were handled.
## Requirements
### Requirement: Local Agent Session Discovery
Dream SHALL discover completed turns in local Claude Code and Codex JSONL transcripts. It SHALL use source, session ID, and turn number to avoid processing a completed turn twice, and SHALL check for pending turns before exiting because the KB change log is quiet.

#### Scenario: Session-only activity
- **WHEN** the KB change log has no new writes but a completed turn from either agent is pending
- **THEN** Dream runs ingestion and synthesis for that turn

#### Scenario: Resumed session
- **WHEN** an earlier turn has already been synthesized and a later turn completes in the same session
- **THEN** Dream ingests only the later turn

#### Scenario: Earlier turn fails
- **WHEN** an earlier turn fails KB handling but a later turn succeeds
- **THEN** the earlier turn remains pending for a later run

#### Scenario: Uncaptured Codex history
- **WHEN** an older Codex transcript contains a turn that was never processed
- **THEN** Dream keeps that turn eligible for discovery

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

### Requirement: Session Capture Privacy
Dream SHALL redact known credential formats before putting transcript text in the KB and SHALL exclude session working directories configured in the private Dream exclusion file. It SHALL skip transcripts without a working directory.

#### Scenario: Excluded working directory
- **WHEN** a transcript's working directory matches a configured path prefix or directory name
- **THEN** Dream does not ingest that transcript

#### Scenario: Credential in session text
- **WHEN** a user request or final response includes a recognized credential format
- **THEN** Dream replaces the credential before creating the inbox capture
