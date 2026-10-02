# Change: Display Codex usage limits in the status bar

## Why
Codex exposes current 5-hour and weekly plan usage in its native TUI status line, but `dots install agents` does not configure those items.

## What Changes
- Configure Codex's native TUI status line to display the model, context remaining, 5-hour usage, and weekly usage, matching the information shown by the Claude status line.
- Preserve unrelated Codex configuration and existing status-line items, and make installation idempotent.
- Codex retains its native visual rendering; its status line does not support the custom bars and colors used by the Claude hook.

## Impact
- Affected specs: `agent-config-install`
- Affected code: `cli/commands/install/agents.go` and Codex config mutation helpers/tests
