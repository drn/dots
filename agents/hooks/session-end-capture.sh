#!/usr/bin/env bash
# Hook: SessionEnd — captures a structured raw note into memory/inbox/ when
# the session shipped real work. Only writes when at least one commit was
# authored from the session's cwd. Tagged `commit-merged` (high-value) when
# any of those commits has landed on origin/main or origin/master.
#
# Why: gives /dream a steady stream of inbox captures it can synthesize into
# topical KB docs. Sessions that never produced a commit are skipped — the
# inbox stays focused on shipped work, not exploration.
#
# Fail-soft on every error path so a missing dep, broken transcript, or
# detached daemon never blocks session shutdown.
#
# Shell semantics:
#   `set -uo pipefail` (no `-e`) + `trap 'exit 0' ERR` is the fail-soft
#   mechanism. The ERR trap fires on any non-zero exit from a simple
#   command or pipeline (including SIGPIPE from `... | head -N`), so any
#   line that we *expect* to fail must end with `|| true` to suppress the
#   trap. Compare with peer hooks (track-kb-change.sh, session-start-memory.sh)
#   that use `set -euo pipefail` + named guards — same effect, different
#   ergonomics. We use the trap form here because the script has many
#   independent fail-soft branches and `|| true` per-call would be noisier.

set -uo pipefail
trap 'exit 0' ERR

# Tunables — limits keep the capture lean and bound the work the hook does
# at session shutdown. All centralized so a future tuner doesn't have to
# hunt through the body.
MAX_COMMITS=20
MAX_FILES=30
MAX_INTENT_CHARS=600

# stdin: { session_id, transcript_path, cwd, hook_event_name, ... }
INPUT=$(cat)
[ -n "$INPUT" ] || exit 0

command -v jq >/dev/null 2>&1 || exit 0
command -v argus >/dev/null 2>&1 || exit 0

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty')

[ -n "$SESSION_ID" ] || exit 0
[ -n "$CWD" ] || exit 0
[ -d "$CWD" ] || exit 0

# Only capture from git repos. Sessions in a scratch dir or $HOME aren't
# coding sessions worth preserving.
git -C "$CWD" rev-parse --git-dir >/dev/null 2>&1 || exit 0

# Session start: timestamp on the first transcript line. Falls back to
# transcript file mtime via BSD `stat -f` (macOS) or GNU `stat -c` (Linux).
SESSION_START=""
if [ -n "$TRANSCRIPT" ] && [ -r "$TRANSCRIPT" ]; then
  SESSION_START=$(head -1 "$TRANSCRIPT" 2>/dev/null | jq -r '.timestamp // empty' 2>/dev/null)
  if [ -z "$SESSION_START" ]; then
    if SS=$(stat -f %SB -t %Y-%m-%dT%H:%M:%SZ "$TRANSCRIPT" 2>/dev/null); then
      SESSION_START="$SS"
    elif SS=$(stat -c %y "$TRANSCRIPT" 2>/dev/null); then
      # GNU stat returns "2026-05-04 09:30:00.000000000 -0700"; reformat
      # to the same UTC ISO-8601 shape as the BSD branch.
      SESSION_START=$(date -u -d "$SS" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "")
    fi
  fi
fi
[ -n "$SESSION_START" ] || exit 0

# Commits authored in this cwd since the session started, by the local git
# user. Restricting to author dodges the case where a rebase sweeps in
# upstream commits authored by teammates. The `|| true` after `head` is
# required because head closes early on long output → git gets SIGPIPE 141
# → pipefail propagates → ERR trap kills the hook.
USER_EMAIL=$(git -C "$CWD" config user.email 2>/dev/null || echo "")
[ -n "$USER_EMAIL" ] || exit 0
COMMITS=$(git -C "$CWD" log --since="$SESSION_START" --format='%H|%s' --author="$USER_EMAIL" 2>/dev/null | head -"$MAX_COMMITS" || true)
[ -n "$COMMITS" ] || exit 0

# Refresh remote refs so merge-base is accurate. Failure is tolerable — we
# just won't see fresh merges. The `|| true` is required because the ERR
# trap above otherwise kills the hook on any non-zero exit (no `origin`
# remote, network down, etc.) and no inbox file gets written. We do not
# add a hard timeout because GNU `timeout` isn't on macOS by default; in
# practice git's own connect timeout bounds this within seconds.
git -C "$CWD" fetch --quiet --no-tags origin 2>/dev/null || true

# Pick the base remote that exists.
BASE_REMOTE=""
for branch in origin/main origin/master; do
  if git -C "$CWD" rev-parse --verify --quiet "$branch" >/dev/null 2>&1; then
    BASE_REMOTE="$branch"
    break
  fi
done

# Walk each commit, classify merged vs. wip. Build a markdown bullet list.
MERGED_COUNT=0
TOTAL_COUNT=0
COMMIT_LIST=""
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

# Tag selection. high-value when any commit landed; work-in-progress otherwise.
if [ "$MERGED_COUNT" -gt 0 ]; then
  TAGS='[session-capture, high-value, commit-merged]'
elif [ "$TOTAL_COUNT" -gt 0 ]; then
  TAGS='[session-capture, work-in-progress]'
else
  TAGS='[session-capture]'
fi

REPO=$(basename "$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null || echo "$CWD")")
BRANCH=$(git -C "$CWD" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

# First user prompt = the session intent. Truncate to keep the capture lean.
INTENT=""
if [ -n "$TRANSCRIPT" ] && [ -r "$TRANSCRIPT" ]; then
  INTENT=$(jq -rs '
    [.[] | select(.type == "user" and (.message.content | type) == "string")]
    | .[0].message.content // ""
  ' "$TRANSCRIPT" 2>/dev/null || echo "")
  INTENT="${INTENT:0:$MAX_INTENT_CHARS}"
fi

# Files touched: union across all session commits. Capped via $MAX_FILES so
# a big refactor doesn't blow up the capture. Using --pretty=format: +
# --name-only avoids needing each commit to have a parent — diff-style range
# fails when a session's first commit is the repo's root commit.
FILES_TOUCHED=$(git -C "$CWD" log --since="$SESSION_START" --author="$USER_EMAIL" \
  --name-only --pretty=format: 2>/dev/null | sort -u | grep -v '^$' | head -"$MAX_FILES" || true)

# Vault path. Bail if the daemon doesn't know where the vault lives — the
# hook has no other place to write.
VAULT=$(argus kb status 2>/dev/null | awk -F': *' '/^Vault/ {print $2; exit}')
[ -n "${VAULT:-}" ] || exit 0
[ -d "$VAULT" ] || exit 0

# Sanitize SESSION_ID before use in the filename. UUIDs from Claude Code are
# alphanumeric+hyphens by spec, but defense-in-depth blocks a hostile or
# malformed session_id from emitting `..` path components.
DATE=$(date -u +%Y-%m-%d)
SHORT_SESSION=$(printf '%s' "${SESSION_ID:0:8}" | tr -dc 'a-zA-Z0-9')
[ -n "$SHORT_SESSION" ] || SHORT_SESSION="anon"
# Build slug from REPO/BRANCH; strip leading/trailing hyphens after the
# character-class filter so "myrepo-" (empty branch) becomes "myrepo".
# Note on collisions: two sessions in the same repo+branch on the same date
# whose UUIDs share their first 8 chars would clobber. UUID collision odds
# at 8 hex chars are ~1 in 4 billion per day per repo+branch — acceptable
# for a best-effort capture system; /dream re-reads the file as the source
# of truth anyway.
SLUG=$(printf '%s-%s' "$REPO" "$BRANCH" \
  | tr '[:upper:]' '[:lower:]' \
  | tr '/_' '--' \
  | sed -e 's/[^a-z0-9-]//g' -e 's/^-*//' -e 's/-*$//' \
  | cut -c1-40)
[ -n "$SLUG" ] || SLUG="session"
INBOX_DIR="$VAULT/memory/inbox"
INBOX_FILE="$INBOX_DIR/$DATE-$SHORT_SESSION-$SLUG.md"
mkdir -p "$INBOX_DIR"

CAPTURED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)

{
  printf -- '---\n'
  printf 'title: "Session: %s @ %s"\n' "$REPO" "$BRANCH"
  printf 'tags: %s\n' "$TAGS"
  printf -- '---\n\n'
  printf 'Session shipped %d of %d commits from `%s` on branch `%s`.\n\n' \
    "$MERGED_COUNT" "$TOTAL_COUNT" "$REPO" "$BRANCH"
  printf '## Intent\n\n%s\n\n' "${INTENT:-<no user prompt captured>}"
  printf '## Commits\n\n%s\n' "$COMMIT_LIST"
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

exit 0
