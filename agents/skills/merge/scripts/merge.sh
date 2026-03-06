#!/usr/bin/env bash
set -euo pipefail

# merge.sh — Merge current branch to master via GitHub PR
#
# Usage: merge.sh [--skip-rebase] "<title>" "<body>"
#
# Exit codes:
#   0 — success (merge completed or auto-merge enabled)
#   1 — general failure
#   2 — rebase conflict (needs manual resolution)
#   3 — no commits to merge

COAUTHOR="Co-Authored-By: Claude <noreply@anthropic.com>"

# --- Globals set during execution ---
TARGET=""
BRANCH=""
COMMIT_COUNT=""
PR_NUMBER=""
PR_URL=""
MERGE_METHOD=""
MERGE_STATUS="merged"
MASTER_COMMIT=""
DOTS_SYNCED=""

# --- Helpers ---

die() {
  local code="$1"; shift
  echo "Error: $*" >&2
  exit "$code"
}

info() {
  echo ":: $*" >&2
}

# --- Functions ---

determine_target() {
  if git remote | grep -q '^upstream$'; then
    TARGET="upstream"
  else
    TARGET="origin"
  fi
  info "Target remote: $TARGET"
}

get_branch() {
  BRANCH=$(git branch --show-current)
  [[ -z "$BRANCH" ]] && die 1 "Detached HEAD — cannot merge"
  [[ "$BRANCH" == "master" || "$BRANCH" == "main" ]] && die 1 "Already on $BRANCH — nothing to merge"
  info "Branch: $BRANCH"
}

check_commits() {
  local count
  count=$(git log "${TARGET}/master..HEAD" --oneline 2>/dev/null | wc -l | tr -d ' ')
  [[ "$count" -eq 0 ]] && die 3 "No commits ahead of ${TARGET}/master — nothing to merge"
  COMMIT_COUNT="$count"
  info "Commits to merge: $count"
}

do_rebase() {
  info "Fetching ${TARGET}..."
  git fetch "$TARGET"

  info "Rebasing onto ${TARGET}/master..."
  if ! git rebase "${TARGET}/master"; then
    echo "REBASE_CONFLICT" >&2
    git diff --name-only --diff-filter=U >&2 || true
    exit 2
  fi
}

do_push() {
  info "Pushing ${BRANCH} to ${TARGET}..."
  git push "$TARGET" "$BRANCH" --force-with-lease
}

ensure_pr() {
  local title="$1" body="$2"

  local existing
  existing=$(gh pr list --head "$BRANCH" --state open --json number,url --jq '.[0]' 2>/dev/null || echo "")

  if [[ -n "$existing" && "$existing" != "null" ]]; then
    PR_NUMBER=$(echo "$existing" | jq -r '.number')
    PR_URL=$(echo "$existing" | jq -r '.url')
    info "Updating existing PR #${PR_NUMBER}..."
    gh pr edit "$PR_NUMBER" --title "$title" --body "$body"
  else
    info "Creating PR..."
    PR_URL=$(gh pr create --base master --head "$BRANCH" --title "$title" --body "$body" 2>&1 | grep -o 'https://github.com/[^ ]*' | head -1)
    PR_NUMBER=$(echo "$PR_URL" | grep -o '[0-9]*$')
  fi
  info "PR: ${PR_URL}"
}

do_merge() {
  local title="$1" body="$2"

  info "Merging PR #${PR_NUMBER}..."

  # Attempt 1: squash merge
  if gh pr merge "$PR_NUMBER" --squash --subject "$title" --body "$body" 2>/dev/null; then
    MERGE_METHOD="squash"
    return 0
  fi

  info "Squash merge failed, trying auto-merge..."

  # Attempt 2: squash with auto-merge
  if gh pr merge "$PR_NUMBER" --squash --auto --subject "$title" --body "$body" 2>/dev/null; then
    MERGE_METHOD="squash (auto-merge)"
    MERGE_STATUS="auto-merge enabled"
    return 0
  fi

  info "Auto-merge failed, falling back to rebase merge..."

  # Attempt 3: rebase merge
  if gh pr merge "$PR_NUMBER" --rebase 2>/dev/null; then
    MERGE_METHOD="rebase"
    return 0
  fi

  die 1 "All merge strategies failed for PR #${PR_NUMBER}"
}

update_local_master() {
  if [[ "$MERGE_STATUS" != "merged" ]]; then
    return 0
  fi

  info "Updating local master..."

  if git checkout master 2>/dev/null; then
    git pull "$TARGET" master
    MASTER_COMMIT=$(git log -1 --oneline)
    git checkout "$BRANCH" 2>/dev/null || true
  else
    local worktree_path
    worktree_path=$(git worktree list | grep '\[master\]' | awk '{print $1}' || echo "")
    if [[ -n "$worktree_path" ]]; then
      info "Pulling master in worktree: ${worktree_path}"
      git -C "$worktree_path" pull "$TARGET" master 2>/dev/null || true
      MASTER_COMMIT=$(git -C "$worktree_path" log -1 --oneline 2>/dev/null || echo "")
    fi
  fi
}

sync_dots() {
  if [[ "${CONDUCTOR_ROOT_PATH:-}" != *"/.dots/"* && "${CONDUCTOR_ROOT_PATH:-}" != *"/.dots" ]]; then
    return 0
  fi

  local dots_home="$HOME/.dots"
  [[ ! -d "$dots_home" ]] && return 0

  info "Syncing ~/.dots..."
  git -C "$dots_home" fetch origin
  git -C "$dots_home" reset --hard origin/master
  DOTS_SYNCED=$(git -C "$dots_home" log -1 --oneline)
}

print_summary() {
  echo ""
  echo "status:   ${MERGE_STATUS}"
  echo "method:   ${MERGE_METHOD}"
  echo "pr:       ${PR_URL}"
  echo "branch:   ${BRANCH} → master"
  echo "commits:  ${COMMIT_COUNT}"
  [[ -n "${MASTER_COMMIT:-}" ]] && echo "commit:   ${MASTER_COMMIT}"
  [[ -n "${DOTS_SYNCED:-}" ]] && echo "~/.dots:  synced → ${DOTS_SYNCED}"
}

# --- Main ---

main() {
  local skip_rebase=false

  # Parse --skip-rebase flag
  if [[ "${1:-}" == "--skip-rebase" ]]; then
    skip_rebase=true
    shift
  fi

  local title="${1:?Usage: merge.sh [--skip-rebase] \"<title>\" \"<body>\"}"
  local body="${2:-}"

  # Append co-author line
  if [[ -n "$body" ]]; then
    body="${body}

${COAUTHOR}"
  else
    body="${COAUTHOR}"
  fi

  determine_target
  get_branch
  check_commits

  if [[ "$skip_rebase" == false ]]; then
    do_rebase
  fi

  do_push
  ensure_pr "$title" "$body"
  do_merge "$title" "$body"
  update_local_master
  sync_dots
  print_summary
}

main "$@"
