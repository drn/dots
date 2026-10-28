# Change: Add ~/.local/bin to the dev-tool PATH hook

## Why
User-installed CLIs under `~/.local/bin` (XDG user bin dir) resolve in an interactive
shell but intermittently fail with `command not found` in Claude Code's Bash tool.
Whether `~/.local/bin` is on the Bash tool PATH depends on how the Claude Code process
was launched (daemon-started vs resumed), because PATH exports in `~/.zshenv` are not
captured. The existing dev-tool PATH hook already solves this for go/cargo/asdf; it just
omits `~/.local/bin`.

## What Changes
- `agents/hooks/session-start-path.sh` also prepends `~/.local/bin` (skipped when absent).
  It sits behind `go/bin`, so go binaries still win the frontmost slot.

## Impact
- Affected specs: `agent-config-install` (MODIFIED: Dev-Tool PATH Hook Registration)
- Affected code: `agents/hooks/session-start-path.sh`
- Tests: `.github/skill-tests/test_session_path.sh`
