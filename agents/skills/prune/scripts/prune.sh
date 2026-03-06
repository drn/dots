#!/usr/bin/env bash
set -euo pipefail

# prune.sh — Clean up merged and stale git branches
#
# Usage:
#   prune.sh preview [--stale-days N]
#   prune.sh delete [--remote] <branch1> [branch2 ...]
#
# Exit codes:
#   0 — success
#   1 — general failure
#   3 — nothing to prune

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

get_default_branch() {
  local ref
  ref=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null || echo "")
  if [[ -n "$ref" ]]; then
    echo "${ref#refs/remotes/origin/}"
    return
  fi
  if git rev-parse --verify origin/main &>/dev/null; then
    echo "main"
    return
  fi
  if git rev-parse --verify origin/master &>/dev/null; then
    echo "master"
    return
  fi
  die 1 "Could not determine default branch"
}

is_protected() {
  local branch="$1" current="$2" default="$3"
  case "$branch" in
    "$current"|"$default"|main|master|develop|staging) return 0 ;;
    release/*) return 0 ;;
    *) return 1 ;;
  esac
}

has_open_pr() {
  local branch="$1"
  local result
  result=$(gh pr list --head "$branch" --state open --json number --jq '.[0].number' 2>/dev/null || echo "")
  if [[ -n "$result" && "$result" != "null" ]]; then
    echo "$result"
    return 0
  fi
  return 1
}

do_preview() {
  local stale_days=30

  # Parse --stale-days
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --stale-days) stale_days="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  local current default
  current=$(git branch --show-current)
  default=$(get_default_branch)

  info "Current branch: $current"
  info "Default branch: $default"
  info "Stale threshold: ${stale_days} days"

  # Fetch and prune remote tracking refs
  info "Fetching and pruning..."
  git fetch --prune 2>/dev/null || true

  # Find merged branches
  local merged=()
  while IFS= read -r branch; do
    branch=$(echo "$branch" | sed 's/^[* ]*//' | xargs)
    [[ -z "$branch" ]] && continue
    is_protected "$branch" "$current" "$default" && continue
    merged+=("$branch")
  done < <(git branch --merged "$default" 2>/dev/null)

  # Find stale branches (not merged, not protected, older than threshold)
  local stale=()
  local stale_cutoff
  stale_cutoff=$(date -v-"${stale_days}"d +%s 2>/dev/null || date -d "${stale_days} days ago" +%s 2>/dev/null)

  while IFS= read -r line; do
    local branch date_rel
    branch=$(echo "$line" | awk '{print $1}')
    [[ -z "$branch" ]] && continue
    is_protected "$branch" "$current" "$default" && continue

    # Skip if already in merged list
    local already_merged=false
    for m in "${merged[@]+"${merged[@]}"}"; do
      [[ "$m" == "$branch" ]] && { already_merged=true; break; }
    done
    "$already_merged" && continue

    # Check commit age
    local commit_epoch
    commit_epoch=$(git log -1 --format="%ct" "$branch" 2>/dev/null || echo "0")
    if [[ "$commit_epoch" -lt "$stale_cutoff" ]]; then
      stale+=("$branch")
    fi
  done < <(git branch --format='%(refname:short) %(committerdate:relative)' 2>/dev/null)

  # Check for open PRs and build output
  local merged_output=()
  local stale_output=()
  local skipped_output=()

  for branch in "${merged[@]+"${merged[@]}"}"; do
    local pr_num
    if pr_num=$(has_open_pr "$branch"); then
      skipped_output+=("$branch|Has open PR #${pr_num}")
    else
      local last_commit
      last_commit=$(git log -1 --format="%cr" "$branch" 2>/dev/null || echo "unknown")
      merged_output+=("$branch|$last_commit|$default")
    fi
  done

  for branch in "${stale[@]+"${stale[@]}"}"; do
    local pr_num
    if pr_num=$(has_open_pr "$branch"); then
      skipped_output+=("$branch|Has open PR #${pr_num}")
    else
      local last_commit
      last_commit=$(git log -1 --format="%cr" "$branch" 2>/dev/null || echo "unknown")
      stale_output+=("$branch|$last_commit")
    fi
  done

  # Check if anything to prune
  if [[ ${#merged_output[@]} -eq 0 && ${#stale_output[@]} -eq 0 ]]; then
    die 3 "All branches are current — nothing to prune"
  fi

  # Print structured output
  echo "--- PRUNE PREVIEW ---"
  echo "default:    $default"
  echo "stale_days: $stale_days"
  echo ""

  if [[ ${#merged_output[@]} -gt 0 ]]; then
    echo "MERGED:"
    for entry in "${merged_output[@]}"; do
      echo "  $entry"
    done
    echo ""
  fi

  if [[ ${#stale_output[@]} -gt 0 ]]; then
    echo "STALE:"
    for entry in "${stale_output[@]}"; do
      echo "  $entry"
    done
    echo ""
  fi

  if [[ ${#skipped_output[@]} -gt 0 ]]; then
    echo "SKIPPED:"
    for entry in "${skipped_output[@]}"; do
      echo "  $entry"
    done
    echo ""
  fi

  echo "--- END ---"
}

do_delete() {
  local delete_remote=false
  local branches=()

  # Parse args
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --remote) delete_remote=true; shift ;;
      *) branches+=("$1"); shift ;;
    esac
  done

  [[ ${#branches[@]} -eq 0 ]] && die 1 "No branches specified for deletion"

  local current default
  current=$(git branch --show-current)
  default=$(get_default_branch)

  local deleted=()
  local failed=()

  for branch in "${branches[@]}"; do
    # Safety check
    if is_protected "$branch" "$current" "$default"; then
      failed+=("$branch|Protected branch")
      continue
    fi

    # Try -d first (safe delete), fall back to -D for unmerged stale branches
    if git branch -d "$branch" 2>/dev/null; then
      deleted+=("$branch|local")
    elif git branch -D "$branch" 2>/dev/null; then
      deleted+=("$branch|local (force)")
    else
      failed+=("$branch|Delete failed")
      continue
    fi

    # Delete remote if requested
    if "$delete_remote"; then
      if git push origin --delete "$branch" 2>/dev/null; then
        deleted+=("$branch|remote")
      fi
    fi
  done

  # Print summary
  echo "--- PRUNE RESULT ---"

  if [[ ${#deleted[@]} -gt 0 ]]; then
    echo "DELETED:"
    for entry in "${deleted[@]}"; do
      echo "  $entry"
    done
  fi

  if [[ ${#failed[@]} -gt 0 ]]; then
    echo "FAILED:"
    for entry in "${failed[@]}"; do
      echo "  $entry"
    done
  fi

  echo "--- END ---"
}

# --- Main ---

main() {
  local mode="${1:-}"
  shift || true

  case "$mode" in
    preview) do_preview "$@" ;;
    delete)  do_delete "$@" ;;
    *)       die 1 "Usage: prune.sh preview [--stale-days N] | prune.sh delete [--remote] <branch1> [...]" ;;
  esac
}

main "$@"
