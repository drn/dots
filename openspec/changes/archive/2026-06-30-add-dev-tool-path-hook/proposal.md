# Change: Add dev-tool PATH hook for Claude Code's Bash tool

## Why
Bare `tts` (and other go-installed binaries) fail with `command not found` inside
Claude Code's Bash tool, even though `/Users/<user>/go/bin/tts` runs fine by absolute
path. The global `~/.claude/CLAUDE.md` TTS convention (`tts -s 1.1 "<summary>"`)
assumes bare `tts` resolves, so it breaks in every Bash-tool call.

Root cause: Claude Code builds the Bash tool's PATH from the process that launched it
(often a daemon such as Argus, whose PATH lacks `go/bin`), NOT from the user's
interactive shell. Per the Claude Code docs, at session start it sources `~/.zshrc`
only to capture **aliases, functions, and shell options** — PATH exports there (and in
`~/.zshenv`) are dropped. So the existing `~/.zshenv` `go/bin` export (shipped in
commit `95ac7d4`) cannot reach the Bash tool.

Two non-fixes were ruled out:
- **`settings.json` `env.PATH`** *replaces* PATH wholesale and performs no `$PATH`
  expansion, so it would clobber the inherited PATH (including Claude Code's plugin
  bin dirs). Not viable.
- **`~/.zshenv` / `~/.zshrc`** additions are not captured for the Bash tool (see above).

The supported mechanism is `$CLAUDE_ENV_FILE`: a SessionStart hook appends `export`
lines to it, and Claude Code sources that file before every subsequent Bash command.
Because it is sourced, `$PATH` expands and the inherited PATH is preserved.

## What Changes
- Add `agents/hooks/session-start-path.sh`: a SessionStart hook that prepends existing
  dev-tool bin dirs (`$GOBIN`/`~/go/bin`, `~/.cargo/bin`, `~/.asdf/shims`) onto PATH by
  appending `export PATH="$dir:$PATH"` lines to `$CLAUDE_ENV_FILE`. It skips dirs that
  don't exist, is idempotent across repeated SessionStart fires, and orders entries so
  `go/bin` lands frontmost (mirroring `~/.zshenv`, where `$GOBIN` precedes the asdf
  shims).
- Register the hook in `dots install agents` via a new `registerSessionStartPathHook()`,
  reusing the existing idempotent `registerSessionHook` machinery.

## Impact
- Affected specs: `agent-config-install` (ADDED: Dev-Tool PATH Hook Registration)
- Affected code: `cli/commands/install/agents.go`, `agents/hooks/session-start-path.sh`
- Tests: `cli/commands/install/agents_test.go` (registration + idempotency),
  `.github/skill-tests/test_session_path.sh` (hook script behavior)
- No change to credential handling; the hook only prepends directories that already
  exist on the machine and never writes secrets.
