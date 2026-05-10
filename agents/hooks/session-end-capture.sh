#!/usr/bin/env bash
# Hook: SessionEnd — captures a structured raw note into memory/inbox/ for
# every Claude Code session. /dream is the filter; the hook is the firehose.
#
# Tag taxonomy (drives dream's processing order in Phase 3):
#   [session-capture, high-value, commit-merged]  — commit landed on origin/main|master
#   [session-capture, work-in-progress]           — has commits, none merged
#   [session-capture, no-commit]                  — exploration / research / Q&A
#
# A debug log at ~/.dots/sys/session-end-capture.log records every fire (one
# line per invocation: timestamp, session_id, status, inbox path or reason).
# This is the ONLY way to observe the hook from outside — the trap below
# swallows ERR exits silently to keep session shutdown fail-soft.
#
# Shell semantics:
#   `set -uo pipefail` (no `-e`) + `trap '...' ERR` for fail-soft. The ERR
#   trap fires on any non-zero exit from a simple command or pipeline
#   (including SIGPIPE from `... | head -N`), so any line we *expect* to
#   fail must end with `|| true` to suppress it.

set -uo pipefail

# Tunables — limits keep the capture lean and bound the work the hook does
# at session shutdown.
MAX_COMMITS=20
MAX_FILES=30
MAX_INTENT_CHARS=600
MAX_RECENT_PROMPTS=3
MAX_RECENT_PROMPT_CHARS=400
# Long-running sessions (12h+ of heavy tool use) can produce transcripts in
# the tens of MB. `jq -rs` slurps the entire file into memory; cap so a
# pathological transcript doesn't OOM the shutdown path. Above the cap, we
# still capture the session (metadata, commits) but skip prompt extraction.
MAX_TRANSCRIPT_BYTES=$((50 * 1024 * 1024))

LOG_FILE="$HOME/.dots/sys/session-end-capture.log"
LOG_MAX_LINES=10000
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true

# Best-effort log rotation. When the log exceeds LOG_MAX_LINES, keep the
# most recent half. Failure is silent — log rotation never blocks capture.
if [ -f "$LOG_FILE" ]; then
  _line_count=$(wc -l < "$LOG_FILE" 2>/dev/null | tr -d ' ' || echo 0)
  if [ "${_line_count:-0}" -gt "$LOG_MAX_LINES" ] 2>/dev/null; then
    _keep=$((LOG_MAX_LINES / 2))
    tail -n "$_keep" "$LOG_FILE" > "$LOG_FILE.tmp" 2>/dev/null && \
      mv -f "$LOG_FILE.tmp" "$LOG_FILE" 2>/dev/null || true
  fi
fi

# Strip credential-format substrings from a string. Patterns mirror the
# Thanx security policy's credential format list. The vault syncs to iCloud,
# so anything written to inbox docs leaves the local machine; redacting
# raises the bar against accidentally syncing pasted-in tokens to Apple.
# Returns the redacted string on stdout.
_redact() {
  local s="$1"
  printf '%s' "$s" | sed -E \
    -e 's/AKIA[0-9A-Z]{16}/[REDACTED-AWS]/g' \
    -e 's/gh[pso]_[A-Za-z0-9]{20,}/[REDACTED-GH]/g' \
    -e 's/sk-ant-[A-Za-z0-9_-]{20,}/[REDACTED-ANTHROPIC]/g' \
    -e 's/sk-[A-Za-z0-9_-]{20,}/[REDACTED-OPENAI]/g' \
    -e 's/xox[bpars]-[A-Za-z0-9-]{10,}/[REDACTED-SLACK]/g' \
    -e 's/SG\.[A-Za-z0-9_-]{16,}\.[A-Za-z0-9_-]{16,}/[REDACTED-SENDGRID]/g' \
    -e 's/ntn_[A-Za-z0-9]{20,}/[REDACTED-NOTION]/g' \
    -e 's/sntrys_[A-Za-z0-9_]{20,}/[REDACTED-SENTRY]/g' \
    -e 's/dd[a-z][a-z0-9]{20,}/[REDACTED-DATADOG]/g' \
    -e 's/pdkey_[A-Za-z0-9]{16,}/[REDACTED-PAGERDUTY]/g' \
    -e 's/-----BEGIN [A-Z ]*PRIVATE KEY-----/[REDACTED-PRIVKEY]/g'
}

# Status tracker for the trap. The trap reads $STATUS to log a final line on
# any exit path. Default is "skip:unknown" so a crash before the first
# explicit set still leaves a useful breadcrumb.
STATUS="skip:unknown"
SESSION_ID="?"
INBOX_FILE=""

_log() {
  local ts safe_id
  ts=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "?")
  # Strip control chars (including tab/newline) from session_id before
  # writing — a hostile or malformed UUID could otherwise forge log lines.
  safe_id=$(printf '%s' "$SESSION_ID" | tr -d '\t\n\r' | tr -dc '[:print:]' \
    | cut -c1-64)
  printf '%s\t%s\t%s\t%s\n' "$ts" "${safe_id:-?}" "$STATUS" "$INBOX_FILE" \
    >> "$LOG_FILE" 2>/dev/null || true
}
trap '_log; exit 0' EXIT
trap 'exit 0' ERR

# stdin: { session_id, transcript_path, cwd, hook_event_name, reason }
INPUT=$(cat)
[ -n "$INPUT" ] || { STATUS="skip:no-input"; exit 0; }

command -v jq >/dev/null 2>&1 || { STATUS="skip:no-jq"; exit 0; }
command -v argus >/dev/null 2>&1 || { STATUS="skip:no-argus"; exit 0; }

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty')
[ -n "$SESSION_ID" ] || { STATUS="skip:no-session-id"; exit 0; }
[ -n "$CWD" ] || { STATUS="skip:no-cwd"; exit 0; }
[ -d "$CWD" ] || { STATUS="skip:cwd-missing"; exit 0; }

# A session with no readable transcript is dead weight — there's no intent,
# no excerpt, nothing to distill. Skip rather than write an empty stub.
[ -n "$TRANSCRIPT" ] || { STATUS="skip:no-transcript-path"; exit 0; }
[ -r "$TRANSCRIPT" ] || { STATUS="skip:transcript-unreadable"; exit 0; }

# Session start: timestamp on the first transcript line. Falls back to
# transcript file mtime via BSD `stat -f` (macOS) or GNU `stat -c` (Linux).
SESSION_START=$(head -1 "$TRANSCRIPT" 2>/dev/null | jq -r '.timestamp // empty' 2>/dev/null)
if [ -z "$SESSION_START" ]; then
  if SS=$(stat -f %SB -t %Y-%m-%dT%H:%M:%SZ "$TRANSCRIPT" 2>/dev/null); then
    SESSION_START="$SS"
  elif SS=$(stat -c %y "$TRANSCRIPT" 2>/dev/null); then
    SESSION_START=$(date -u -d "$SS" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "")
  fi
fi
[ -n "$SESSION_START" ] || { STATUS="skip:no-session-start"; exit 0; }

# Bound jq's memory: skip prompt extraction on pathologically large
# transcripts. Stat is portable BSD/GNU; failure = treat as small.
TRANSCRIPT_BYTES=$(stat -f%z "$TRANSCRIPT" 2>/dev/null \
  || stat -c%s "$TRANSCRIPT" 2>/dev/null \
  || echo 0)
TRANSCRIPT_TOO_LARGE=0
if [ "${TRANSCRIPT_BYTES:-0}" -gt "$MAX_TRANSCRIPT_BYTES" ] 2>/dev/null; then
  TRANSCRIPT_TOO_LARGE=1
fi

# Intent = first user prompt; LAST_PROMPTS = last few user prompts. Both
# filter to text-content user messages (skip tool_use_result arrays etc.)
# Slurp the transcript once and drive both queries off the same array.
USER_PROMPTS="[]"
PROMPT_COUNT=0
if [ "$TRANSCRIPT_TOO_LARGE" -eq 0 ]; then
  USER_PROMPTS=$(jq -rs '
    [.[] | select(.type == "user"
      and (.message.content | type) == "string"
      and (.message.content | length) > 0)
    | .message.content]
  ' "$TRANSCRIPT" 2>/dev/null || echo "[]")
  PROMPT_COUNT=$(echo "$USER_PROMPTS" | jq 'length' 2>/dev/null || echo "0")
fi

# A transcript with zero user prompts (or a transcript too large to parse)
# still gets captured — but with a placeholder intent and no excerpt. We do
# not bail here; metadata + commits remain valuable signal for /dream.
INTENT=""
RECENT_PROMPTS=""
if [ "$PROMPT_COUNT" -gt 0 ] 2>/dev/null; then
  INTENT=$(echo "$USER_PROMPTS" | jq -r '.[0] // ""' 2>/dev/null || echo "")
  INTENT="${INTENT:0:$MAX_INTENT_CHARS}"
  INTENT=$(_redact "$INTENT")

  # Last N prompts excluding the first (the first IS the intent). If there
  # are <= 1 prompts total, the recent list is empty.
  if [ "$PROMPT_COUNT" -gt 1 ] 2>/dev/null; then
    RECENT_PROMPTS=$(echo "$USER_PROMPTS" | jq -r --argjson n "$MAX_RECENT_PROMPTS" --argjson max "$MAX_RECENT_PROMPT_CHARS" '
      .[1:]
      | (if length > $n then .[(length - $n):] else . end)
      | map(if length > $max then .[0:$max] + "…" else . end)
      | map("- " + (gsub("\n"; " ⏎ ")))
      | join("\n")
    ' 2>/dev/null || echo "")
    RECENT_PROMPTS=$(_redact "$RECENT_PROMPTS")
  fi
fi

# Git context: optional. Sessions outside a git repo still get captured
# (researching docs, drafting in $HOME, etc.) — they just have no commits.
IS_GIT=0
REPO=$(basename "$CWD")
BRANCH=""
COMMIT_LIST=""
FILES_TOUCHED=""
TOTAL_COUNT=0
MERGED_COUNT=0
if git -C "$CWD" rev-parse --git-dir >/dev/null 2>&1; then
  IS_GIT=1
  REPO=$(basename "$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null || echo "$CWD")")
  BRANCH=$(git -C "$CWD" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

  # Author identity. Restricting to the local git user.email dodges the
  # case where a rebase sweeps in upstream commits authored by teammates.
  USER_EMAIL=$(git -C "$CWD" config user.email 2>/dev/null || echo "")
  if [ -n "$USER_EMAIL" ]; then
    # The `|| true` after `head` is required because head closes early on
    # long output → git gets SIGPIPE 141 → pipefail propagates → ERR trap.
    COMMITS=$(git -C "$CWD" log --since="$SESSION_START" --format='%H|%s' \
      --author="$USER_EMAIL" 2>/dev/null | head -"$MAX_COMMITS" || true)

    if [ -n "$COMMITS" ]; then
      # Refresh remote refs so merge-base is accurate. Failure is tolerable.
      # No hard timeout because GNU `timeout` isn't on macOS by default; in
      # practice git's own connect timeout bounds this within seconds.
      git -C "$CWD" fetch --quiet --no-tags origin 2>/dev/null || true

      BASE_REMOTE=""
      for branch in origin/main origin/master; do
        if git -C "$CWD" rev-parse --verify --quiet "$branch" >/dev/null 2>&1; then
          BASE_REMOTE="$branch"
          break
        fi
      done

      while IFS='|' read -r sha subject; do
        [ -n "$sha" ] || continue
        TOTAL_COUNT=$((TOTAL_COUNT + 1))
        status="wip"
        if [ -n "$BASE_REMOTE" ] && git -C "$CWD" merge-base --is-ancestor "$sha" "$BASE_REMOTE" 2>/dev/null; then
          status="merged"
          MERGED_COUNT=$((MERGED_COUNT + 1))
        fi
        COMMIT_LIST+="- ${sha:0:10} [$status] $subject"$'\n'
      done <<< "$COMMITS"

      # Files touched: union across all session commits. Capped via
      # $MAX_FILES so a big refactor doesn't blow up the capture.
      FILES_TOUCHED=$(git -C "$CWD" log --since="$SESSION_START" --author="$USER_EMAIL" \
        --name-only --pretty=format: 2>/dev/null | sort -u | grep -v '^$' | head -"$MAX_FILES" || true)
    fi
  fi
fi

# Tag selection.
if [ "$MERGED_COUNT" -gt 0 ]; then
  TAGS='[session-capture, high-value, commit-merged]'
elif [ "$TOTAL_COUNT" -gt 0 ]; then
  TAGS='[session-capture, work-in-progress]'
else
  TAGS='[session-capture, no-commit]'
fi

# Vault path. Bail if the daemon doesn't know where the vault lives — the
# hook has no other place to write.
VAULT=$(argus kb status 2>/dev/null | awk -F': *' '/^Vault/ {print $2; exit}')
[ -n "${VAULT:-}" ] || { STATUS="skip:no-vault"; exit 0; }
[ -d "$VAULT" ] || { STATUS="skip:vault-missing"; exit 0; }

# Sanitize SESSION_ID before use in the filename. UUIDs from Claude Code are
# alphanumeric+hyphens by spec, but defense-in-depth blocks a hostile or
# malformed session_id from emitting `..` path components.
DATE=$(date -u +%Y-%m-%d)
SHORT_SESSION=$(printf '%s' "${SESSION_ID:0:8}" | tr -dc 'a-zA-Z0-9')
[ -n "$SHORT_SESSION" ] || SHORT_SESSION="anon"
# Build slug from REPO/BRANCH (or just REPO when not in git); strip
# leading/trailing hyphens after the character-class filter so "myrepo-"
# (empty branch) becomes "myrepo".
SLUG_INPUT="$REPO"
[ -n "$BRANCH" ] && SLUG_INPUT="$REPO-$BRANCH"
SLUG=$(printf '%s' "$SLUG_INPUT" \
  | tr '[:upper:]' '[:lower:]' \
  | tr '/_' '--' \
  | sed -e 's/[^a-z0-9-]//g' -e 's/^-*//' -e 's/-*$//' \
  | cut -c1-40)
[ -n "$SLUG" ] || SLUG="session"
INBOX_DIR="$VAULT/memory/inbox"
INBOX_FILE="$INBOX_DIR/$DATE-$SHORT_SESSION-$SLUG.md"
mkdir -p "$INBOX_DIR"

CAPTURED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Build the doc. Sections render only when their data exists — a no-commit
# capture won't have a Commits or Files Touched header.
{
  printf -- '---\n'
  if [ "$IS_GIT" -eq 1 ] && [ -n "$BRANCH" ]; then
    printf 'title: "Session: %s @ %s"\n' "$REPO" "$BRANCH"
  else
    printf 'title: "Session: %s"\n' "$REPO"
  fi
  printf 'tags: %s\n' "$TAGS"
  printf -- '---\n\n'

  if [ "$IS_GIT" -eq 1 ] && [ "$TOTAL_COUNT" -gt 0 ]; then
    printf 'Session shipped %d of %d commits from `%s` on branch `%s`.\n\n' \
      "$MERGED_COUNT" "$TOTAL_COUNT" "$REPO" "$BRANCH"
  elif [ "$IS_GIT" -eq 1 ]; then
    printf 'Session in `%s` on branch `%s` — no commits authored.\n\n' "$REPO" "$BRANCH"
  else
    printf 'Session in `%s` — non-git working directory.\n\n' "$REPO"
  fi

  printf '## Intent\n\n%s\n\n' "${INTENT:-<no user prompt captured>}"

  if [ -n "$RECENT_PROMPTS" ]; then
    printf '## Recent prompts\n\n%s\n\n' "$RECENT_PROMPTS"
  fi

  if [ -n "$COMMIT_LIST" ]; then
    printf '## Commits\n\n%s\n' "$COMMIT_LIST"
  fi

  if [ -n "$FILES_TOUCHED" ]; then
    printf '\n## Files Touched\n\n'
    while IFS= read -r f; do
      [ -n "$f" ] && printf -- '- `%s`\n' "$f"
    done <<< "$FILES_TOUCHED"
  fi

  printf '\n## Metadata\n\n'
  printf -- '- Session ID: `%s`\n' "$SESSION_ID"
  printf -- '- CWD: `%s`\n' "$CWD"
  printf -- '- Started: %s\n' "$SESSION_START"
  printf -- '- Captured: %s\n' "$CAPTURED_AT"
  printf -- '- User prompts: %s\n' "$PROMPT_COUNT"
} > "$INBOX_FILE"

# Mirror the write to the changes log so the next /dream sees the new
# inbox doc without a full rescan.
mkdir -p ~/.dots/sys/kb-changes
jq -nc \
  --arg ts "$CAPTURED_AT" \
  --arg path "memory/inbox/$DATE-$SHORT_SESSION-$SLUG.md" \
  --arg session_id "$SESSION_ID" \
  --arg cwd "$CWD" \
  '{ts:$ts,path:$path,session_id:$session_id,cwd:$cwd,source:"session-end-capture"}' \
  >> ~/.dots/sys/kb-changes/changes.jsonl

# Captured: classify by tag for the log so we can grep "captured:no-commit"
# vs "captured:commit-merged" to see the firehose distribution.
if [ "$MERGED_COUNT" -gt 0 ]; then
  STATUS="captured:commit-merged"
elif [ "$TOTAL_COUNT" -gt 0 ]; then
  STATUS="captured:work-in-progress"
else
  STATUS="captured:no-commit"
fi
exit 0
