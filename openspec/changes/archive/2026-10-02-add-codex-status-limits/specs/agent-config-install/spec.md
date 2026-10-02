## ADDED Requirements
### Requirement: Codex Status Line Limit Configuration
The `agents` installer SHALL configure Codex's native TUI status line in `$CODEX_HOME/config.toml` (default `~/.codex/config.toml`) to include model, context remaining, 5-hour usage, and weekly usage items, matching the information shown by the Claude status line. It SHALL preserve unrelated Codex configuration and existing status-line items. Codex SHALL render the items using its native status-line appearance.

#### Scenario: Usage limits are configured
- **WHEN** the `agents` installer runs and the Codex status line does not include both usage-limit items
- **THEN** `tui.status_line` includes `model-with-reasoning`, `context-remaining`, `five-hour-limit`, and `weekly-limit`

#### Scenario: Existing Codex configuration is preserved
- **WHEN** the `agents` installer updates the Codex status line
- **THEN** unrelated Codex configuration and existing status-line items remain present

#### Scenario: Re-running does not duplicate items
- **WHEN** the `agents` installer runs when both usage-limit items are already configured
- **THEN** the Codex configuration is left unchanged

#### Scenario: Custom Codex home is respected
- **WHEN** `CODEX_HOME` points to a custom Codex home directory
- **THEN** status-line items are written to that directory's `config.toml`
