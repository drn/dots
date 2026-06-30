#!/usr/bin/env bash
# Hook: SessionStart — make dev-tool bin dirs resolve in the Bash tool.
#
# Claude Code builds the Bash tool's PATH from the process that launched Claude
# Code (often a daemon such as Argus), NOT from the user's interactive shell.
# At session start it sources ~/.zshrc only to capture aliases, functions, and
# shell options — PATH exports there (and in ~/.zshenv) are dropped. So
# go-installed binaries like `tts` fail to resolve by bare name in the
# non-interactive Bash tool shell, even though they run fine by absolute path.
#
# The supported fix (per Claude Code docs) is to append `export` lines to the
# file named by $CLAUDE_ENV_FILE, which Claude Code sources before every
# subsequent Bash command. Because the file is sourced, `$PATH` expands and the
# inherited PATH is preserved — we prepend dev-tool dirs, never clobber it.
#
#   https://code.claude.com/docs/en/tools  (Bash tool behavior)
#   https://code.claude.com/docs/en/hooks  (persist environment variables)
set -euo pipefail

# Drain stdin (Claude Code sends a JSON envelope we don't need here).
cat >/dev/null

# Only meaningful when Claude Code provides the env file (SessionStart, Setup,
# CwdChanged, FileChanged hooks). Fail soft otherwise so the hook is a no-op.
[ -n "${CLAUDE_ENV_FILE:-}" ] || exit 0

# Dev-tool bin dirs to prepend, in SOURCE order. The file is sourced top to
# bottom and every line does `export PATH="$dir:$PATH"`, so the LAST line wins
# the frontmost slot. Ordering mirrors ~/.zshenv, where $GOBIN sits ahead of
# the asdf shims so go-installed binaries bypass the shims.
gobin="${GOBIN:-${GOPATH:-$HOME/go}/bin}"
dirs=(
  "$HOME/.cargo/bin"   # rust (cargo install)
  "$HOME/.asdf/shims"  # asdf-managed runtimes
  "$gobin"             # go install targets (tts, etc.) — frontmost
)

for dir in "${dirs[@]}"; do
  # Skip dirs that don't exist so we never add dead PATH entries on machines
  # without that toolchain installed.
  [ -d "$dir" ] || continue
  # `$PATH` stays literal so it expands when the env file is sourced, not now.
  line="export PATH=\"$dir:\$PATH\""
  # Idempotent across repeated SessionStart fires within one session: the env
  # file persists, so only append an export the file doesn't already have.
  if ! grep -qF -- "$line" "$CLAUDE_ENV_FILE" 2>/dev/null; then
    printf '%s\n' "$line" >> "$CLAUDE_ENV_FILE"
  fi
done
