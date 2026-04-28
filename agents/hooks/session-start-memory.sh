#!/usr/bin/env bash
# Hook: SessionStart — injects Argus KB user prefs, feedback, and an index
# listing into every Claude Code session via hookSpecificOutput.additionalContext.
#
# Reads from the Obsidian vault on disk (cheap), so it works even when the
# argus daemon is down. Fails silent on any error so a missing KB never
# blocks a session.
set -euo pipefail

# Emit a valid empty SessionStart envelope without depending on jq, since
# this is the fail-soft path and jq may be missing.
emit_empty() {
  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":""}}\n'
  exit 0
}

# Drain stdin (Claude Code sends JSON we don't need to parse here)
cat >/dev/null

command -v argus >/dev/null 2>&1 || emit_empty
command -v jq >/dev/null 2>&1 || emit_empty

VAULT=$(argus kb status 2>/dev/null | awk -F': *' '/^Vault/ {print $2; exit}')
[ -n "${VAULT:-}" ] || emit_empty
[ -d "$VAULT" ] || emit_empty

dump_folder() {
  local folder="$1"
  local label="$2"
  local dir="$VAULT/$folder"
  [ -d "$dir" ] || return 0

  local files
  files=$(find "$dir" -maxdepth 1 -name '*.md' -type f 2>/dev/null | sort)
  [ -n "$files" ] || return 0

  printf '\n## %s\n\n' "$label"
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    local rel
    rel="${f#$VAULT/}"
    printf '### %s\n\n' "$rel"
    cat "$f"
    printf '\n'
  done <<< "$files"
}

CONTEXT_FILE=$(mktemp)
trap 'rm -f "$CONTEXT_FILE"' EXIT

{
  printf '# Argus KB — Auto-Loaded Memory\n\n'
  printf 'Your preferences and corrections are loaded below. The full KB is searchable via `mcp__argus__kb_search` / `mcp__argus__kb_read` / `mcp__argus__kb_list`.\n'

  dump_folder "memory/user" "User Preferences (memory/user/)"
  dump_folder "memory/feedback" "Corrections & Feedback (memory/feedback/)"

  printf '\n## KB Index (search for details)\n\n```\n'
  # 200 paths fits within typical context budget even with long folder
  # nesting; agents can still reach more via kb_list with a prefix.
  argus kb list 2>/dev/null | head -200
  printf '```\n'
} > "$CONTEXT_FILE"

# 50 KB cap protects the context budget. SessionStart fires every session,
# so a runaway dump (large vault, deep memory tree) would otherwise consume
# input tokens before any user prompt.
MAX_BYTES=51200
if [ "$(wc -c < "$CONTEXT_FILE")" -gt "$MAX_BYTES" ]; then
  # Truncate at the last newline before the byte cap so we never split a
  # multi-byte UTF-8 character in half (Obsidian notes routinely contain
  # em-dashes, smart quotes, emoji, CJK).
  awk -v max="$MAX_BYTES" '
    { len += length($0) + 1; if (len > max) exit; print }
  ' "$CONTEXT_FILE" > "${CONTEXT_FILE}.trim"
  printf '\n\n[truncated — KB exceeds 50KB budget; use kb_search for the rest]\n' >> "${CONTEXT_FILE}.trim"
  mv "${CONTEXT_FILE}.trim" "$CONTEXT_FILE"
fi

jq -nc --rawfile ctx "$CONTEXT_FILE" \
  '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$ctx}}'
