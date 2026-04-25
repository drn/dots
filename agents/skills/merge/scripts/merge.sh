#!/usr/bin/env bash
set -euo pipefail

# merge.sh — Merge current branch to the default branch via GitHub PR
#
# Usage: merge.sh [--skip-rebase] [--squash] "<title>" "<body>"
#
# Exit codes:
#   0 — success (merge completed or auto-merge enabled)
#   1 — general failure
#   2 — rebase conflict (needs manual resolution)
#   3 — no commits to merge
#   4 — PR blocked (review required / changes requested) and auto-merge unavailable

COAUTHOR="Co-Authored-By: Claude <noreply@anthropic.com>"

# --- Globals set during execution ---
TARGET=""
BRANCH=""
DEFAULT_BRANCH=""
COMMIT_COUNT=""
PR_NUMBER=""
PR_URL=""
REPO_SLUG=""
ALLOWED_METHODS=()
MERGE_METHOD=""
MERGE_STATUS="merged"
MERGE_COMMIT=""
DOTS_SYNCED=""
PR_MERGE_STATE=""
PR_REVIEW_DECISION=""
LAST_GH_ERR=""

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

detect_default_branch() {
  REPO_SLUG=$(git remote get-url "$TARGET" | sed 's|.*github.com[:/]||;s|\.git$||')

  # Primary: ask GitHub API for the actual default branch
  local api_default
  api_default=$(gh api "repos/${REPO_SLUG}" --jq '.default_branch' 2>/dev/null || echo "")
  if [[ -n "$api_default" ]]; then
    DEFAULT_BRANCH="$api_default"
    info "Default branch (from GitHub API): $DEFAULT_BRANCH"
    return 0
  fi

  # Fallback: detect from remote refs
  local ref
  ref=$(git branch -r 2>/dev/null | grep -oE "${TARGET}/(main|master)" | head -1 | sed "s|${TARGET}/||" || echo "")
  if [[ -n "$ref" ]]; then
    DEFAULT_BRANCH="$ref"
    info "Default branch (from remote refs): $DEFAULT_BRANCH"
    return 0
  fi

  # Last resort
  DEFAULT_BRANCH="master"
  info "Default branch (fallback): $DEFAULT_BRANCH"
}

repair_remote_head() {
  local current_head_ref
  current_head_ref=$(git symbolic-ref "refs/remotes/${TARGET}/HEAD" 2>/dev/null | sed "s|refs/remotes/${TARGET}/||" || echo "")
  if [[ -n "$current_head_ref" && "$current_head_ref" != "$DEFAULT_BRANCH" ]]; then
    info "Stale ${TARGET}/HEAD → ${current_head_ref} (expected ${DEFAULT_BRANCH}), repairing..."
    git remote set-head "$TARGET" "$DEFAULT_BRANCH" 2>/dev/null || true
  fi
}

get_branch() {
  BRANCH=$(git branch --show-current)
  [[ -z "$BRANCH" ]] && die 1 "Detached HEAD — cannot merge"
  [[ "$BRANCH" == "master" || "$BRANCH" == "main" ]] && die 1 "Already on $BRANCH — nothing to merge"
  info "Branch: $BRANCH"
}

check_commits() {
  local count
  count=$(git log "${TARGET}/${DEFAULT_BRANCH}..HEAD" --oneline 2>/dev/null | wc -l | tr -d ' ')
  [[ "$count" -eq 0 ]] && die 3 "No commits ahead of ${TARGET}/${DEFAULT_BRANCH} — nothing to merge"
  COMMIT_COUNT="$count"
  info "Commits to merge: $count"
}

do_fetch() {
  info "Fetching ${TARGET}..."
  git fetch "$TARGET"
}

do_rebase() {
  info "Rebasing onto ${TARGET}/${DEFAULT_BRANCH}..."
  if ! git rebase "${TARGET}/${DEFAULT_BRANCH}"; then
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
  [[ -z "$REPO_SLUG" ]] && die 1 "REPO_SLUG not set — detect_default_branch must run first"

  local existing
  existing=$(gh pr list --head "$BRANCH" --state open --repo "$REPO_SLUG" --json number,url --jq '.[0]' 2>/dev/null || echo "")

  if [[ -n "$existing" && "$existing" != "null" ]]; then
    PR_NUMBER=$(echo "$existing" | jq -r '.number')
    PR_URL=$(echo "$existing" | jq -r '.url')
    info "Updating existing PR #${PR_NUMBER}..."
    gh pr edit "$PR_NUMBER" --title "$title" --body "$body"
  else
    info "Creating PR against ${DEFAULT_BRANCH}..."
    PR_URL=$(gh pr create --base "$DEFAULT_BRANCH" --head "$BRANCH" --title "$title" --body "$body" 2>&1 | grep -o 'https://github.com/[^ ]*' | head -1)
    PR_NUMBER=$(echo "$PR_URL" | grep -o '[0-9]*$')
  fi
  # Guard against silent fall-through to gh's "current branch" PR detection if
  # parsing failed — every later gh call would otherwise target the wrong PR.
  [[ -z "$PR_NUMBER" ]] && die 1 "Could not determine PR number (PR_URL=${PR_URL:-<empty>})"
  info "PR: ${PR_URL}"
}

check_pr_state() {
  local json
  json=$(gh pr view "$PR_NUMBER" --repo "$REPO_SLUG" --json mergeStateStatus,reviewDecision 2>/dev/null || echo "")

  if [[ -n "$json" ]]; then
    PR_MERGE_STATE=$(echo "$json" | jq -r '.mergeStateStatus // empty')
    PR_REVIEW_DECISION=$(echo "$json" | jq -r '.reviewDecision // empty')
    info "PR state: ${PR_MERGE_STATE}, review: ${PR_REVIEW_DECISION}"
  fi
}

detect_allowed_methods() {
  [[ -z "$REPO_SLUG" ]] && die 1 "REPO_SLUG not set — detect_default_branch must run first"

  # Probe repo settings as TSV (squash<TAB>rebase<TAB>merge), each "true" or "false".
  # Preference order: squash → rebase → merge-commit.
  local probe
  probe=$(gh api "repos/${REPO_SLUG}" \
    --jq '[.allow_squash_merge,.allow_rebase_merge,.allow_merge_commit] | @tsv' \
    2>/dev/null || echo "")

  ALLOWED_METHODS=()
  if [[ -n "$probe" ]]; then
    local squash rebase merge_commit
    IFS=$'\t' read -r squash rebase merge_commit <<<"$probe"
    [[ "$squash"       == "true" ]] && ALLOWED_METHODS+=("squash")
    [[ "$rebase"       == "true" ]] && ALLOWED_METHODS+=("rebase")
    [[ "$merge_commit" == "true" ]] && ALLOWED_METHODS+=("merge")
  fi

  if [[ ${#ALLOWED_METHODS[@]} -eq 0 ]]; then
    # Probe failed or returned nothing — try every method in preference order.
    ALLOWED_METHODS=(squash rebase merge)
    info "Allowed merge methods unknown; will try: ${ALLOWED_METHODS[*]}"
  else
    info "Allowed merge methods: ${ALLOWED_METHODS[*]}"
  fi
}

_gh_merge() {
  # Run `gh pr merge` for the given method, optionally with --admin or --auto.
  # Returns gh's exit code; on failure, stderr is captured into LAST_GH_ERR so
  # the terminal die can surface the underlying error instead of silently
  # exhausting all methods × tiers.
  # --subject/--body apply to squash and merge-commit only; rebase keeps the
  # original commits and rejects those flags.
  local method="$1" extra="$2" title="$3" body="$4"

  local flag
  case "$method" in
    squash) flag="--squash" ;;
    rebase) flag="--rebase" ;;
    merge)  flag="--merge"  ;;
    *) return 99 ;;
  esac

  local args=("$PR_NUMBER" --repo "$REPO_SLUG" "$flag")
  [[ -n "$extra" ]] && args+=("$extra")
  [[ "$method" != "rebase" ]] && args+=(--subject "$title" --body "$body")

  local err_file rc
  err_file=$(mktemp)
  if gh pr merge "${args[@]}" 2>"$err_file"; then
    rc=0
  else
    rc=$?
    LAST_GH_ERR=$(cat "$err_file")
  fi
  rm -f "$err_file"
  return "$rc"
}

do_merge() {
  local title="$1" body="$2"
  local method

  info "Merging PR #${PR_NUMBER}..."

  # If review is blocking the merge, skip plain merge and try admin/auto.
  if [[ "$PR_REVIEW_DECISION" == "REVIEW_REQUIRED" || "$PR_REVIEW_DECISION" == "CHANGES_REQUESTED" ]]; then
    local reason="review required"
    [[ "$PR_REVIEW_DECISION" == "CHANGES_REQUESTED" ]] && reason="changes requested"
    info "PR blocked (${reason}) — trying admin merge..."

    for method in "${ALLOWED_METHODS[@]}"; do
      if _gh_merge "$method" "--admin" "$title" "$body"; then
        MERGE_METHOD="${method} (admin)"
        return 0
      fi
    done

    info "Admin merge failed, enabling auto-merge..."

    for method in "${ALLOWED_METHODS[@]}"; do
      if _gh_merge "$method" "--auto" "$title" "$body"; then
        MERGE_METHOD="${method} (auto-merge)"
        MERGE_STATUS="auto-merge enabled (${reason})"
        return 0
      fi
    done

    die 4 "PR #${PR_NUMBER} is blocked (${reason}) and auto-merge is not available on this repository${LAST_GH_ERR:+
  Last gh error: ${LAST_GH_ERR}}"
  fi

  # Tier 1: plain merge with each allowed method (preferred order).
  for method in "${ALLOWED_METHODS[@]}"; do
    if _gh_merge "$method" "" "$title" "$body"; then
      MERGE_METHOD="$method"
      return 0
    fi
  done

  info "Plain merge failed, trying admin merge..."

  # Tier 2: --admin (bypasses branch protection if the user has admin).
  for method in "${ALLOWED_METHODS[@]}"; do
    if _gh_merge "$method" "--admin" "$title" "$body"; then
      MERGE_METHOD="${method} (admin)"
      return 0
    fi
  done

  info "Admin merge failed, trying auto-merge..."

  # Tier 3: --auto (queues the merge for when checks pass).
  for method in "${ALLOWED_METHODS[@]}"; do
    if _gh_merge "$method" "--auto" "$title" "$body"; then
      MERGE_METHOD="${method} (auto-merge)"
      MERGE_STATUS="auto-merge enabled"
      return 0
    fi
  done

  die 1 "All merge strategies failed for PR #${PR_NUMBER} (tried: ${ALLOWED_METHODS[*]})${LAST_GH_ERR:+
  Last gh error: ${LAST_GH_ERR}}"
}

fetch_merge_commit() {
  if [[ "$MERGE_STATUS" != "merged" ]]; then
    return 0  # no merge commit yet for auto-merge
  fi

  local commit_line
  commit_line=$(gh pr view "$PR_NUMBER" --repo "$REPO_SLUG" --json mergeCommit \
    --jq '.mergeCommit | "\(.oid[0:7]) \(.messageHeadline)"' 2>/dev/null || echo "")
  if [[ -n "$commit_line" ]]; then
    MERGE_COMMIT="$commit_line"
  fi
}

update_local_master() {
  # MERGE_COMMIT is already set by fetch_merge_commit (called before this)
  if [[ "$MERGE_STATUS" != "merged" ]]; then
    return 0  # skip for auto-merge (not yet merged)
  fi

  info "Updating local ${DEFAULT_BRANCH}..."

  if git checkout "$DEFAULT_BRANCH" 2>/dev/null; then
    git pull "$TARGET" "$DEFAULT_BRANCH"
    git checkout "$BRANCH" 2>/dev/null || true
  else
    local worktree_path
    worktree_path=$(git worktree list | grep "\[${DEFAULT_BRANCH}\]" | awk '{print $1}' || echo "")
    if [[ -n "$worktree_path" ]]; then
      info "Pulling ${DEFAULT_BRANCH} in worktree: ${worktree_path}"
      git -C "$worktree_path" pull "$TARGET" "$DEFAULT_BRANCH" 2>/dev/null || true
    fi
  fi
}

sync_dots() {
  if [[ "${REPO_SLUG:-}" != */dots ]]; then
    return 0
  fi

  local dots_home="$HOME/.dots"
  [[ ! -d "$dots_home" ]] && return 0

  # ~/.dots uses the same default branch as the current repo (always drn/dots)
  info "Syncing ~/.dots..."
  git -C "$dots_home" fetch origin
  git -C "$dots_home" reset --hard "origin/${DEFAULT_BRANCH}"
  DOTS_SYNCED=$(git -C "$dots_home" log -1 --oneline)
}

print_summary() {
  echo ""
  echo "status:   ${MERGE_STATUS}"
  echo "method:   ${MERGE_METHOD}"
  echo "pr:       ${PR_URL}"
  echo "branch:   ${BRANCH} → ${DEFAULT_BRANCH}"
  echo "commits:  ${COMMIT_COUNT}"
  if [[ -n "${MERGE_COMMIT:-}" ]]; then echo "commit:   ${MERGE_COMMIT}"; fi
  if [[ -n "${DOTS_SYNCED:-}" ]]; then echo "~/.dots:  synced → ${DOTS_SYNCED}"; fi
}

# --- Main ---

main() {
  local skip_rebase=false

  # Parse flags
  while [[ "${1:-}" == --* ]]; do
    case "$1" in
      --skip-rebase) skip_rebase=true; shift ;;
      --squash)      shift ;;  # no-op: squash is the preferred method when allowed
      *)             die 1 "Unknown flag: $1 — usage: merge.sh [--skip-rebase] [--squash] \"<title>\" \"<body>\"" ;;
    esac
  done

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
  do_fetch
  detect_default_branch
  repair_remote_head
  check_commits

  if [[ "$skip_rebase" == false ]]; then
    do_rebase
  fi

  do_push
  ensure_pr "$title" "$body"
  check_pr_state
  detect_allowed_methods
  do_merge "$title" "$body"
  fetch_merge_commit       # must precede update_local_master (uses GitHub API, not local state)
  update_local_master
  sync_dots
  print_summary
}

main "$@"
