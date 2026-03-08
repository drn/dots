#!/usr/bin/env bash
set -euo pipefail

# deploy.sh — Deploy latest master to production with a version tag
#
# Usage: deploy.sh
#
# Exit codes:
#   0 — success (tag created and pushed to production)
#   1 — general failure

# --- Globals set during execution ---
TARGET=""
NEW_TAG=""
TAG_COMMIT=""

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

preflight() {
  local remotes
  remotes=$(git remote)
  [[ -z "$remotes" ]] && die 1 "No remotes configured"

  info "Fetching ${TARGET}..."
  git fetch "$TARGET" || die 1 "Failed to fetch ${TARGET}"
}

create_tag() {
  # Record tags before so we can detect the new one
  local tags_before
  tags_before=$(git tag --sort=-v:refname | head -20)

  local version_cmd="${VERSION_CMD:-version-update}"
  info "Running ${version_cmd}..."
  $version_cmd || die 1 "${version_cmd} failed"

  # Find the new tag by comparing before/after
  local tags_after
  tags_after=$(git tag --sort=-v:refname | head -20)

  # grep -Fxv doesn't require sorted input (unlike comm)
  NEW_TAG=$(grep -Fxv -f <(echo "$tags_before") <(echo "$tags_after") | head -1)
  [[ -z "$NEW_TAG" ]] && die 1 "Could not identify new tag from ${version_cmd}"

  info "New tag: $NEW_TAG"

  # Move the tag from HEAD to TARGET/master
  info "Moving tag to ${TARGET}/master..."
  git tag -d "$NEW_TAG"
  git tag -a "$NEW_TAG" "${TARGET}/master" -m ''

  TAG_COMMIT=$(git rev-parse --short "${TARGET}/master")
  info "Tag $NEW_TAG now points to ${TARGET}/master ($TAG_COMMIT)"
}

push_production() {
  # Single atomic push to avoid race condition where CircleCI fetches
  # before GitHub has indexed the new version tag
  info "Pushing $NEW_TAG and ${TARGET}/master to production..."
  git push "$TARGET" "$NEW_TAG" "${TARGET}/master:refs/heads/production" \
    || die 1 "Failed to push tag and production branch"
}

verify() {
  info "Verifying tag on remote..."
  local remote_tag
  remote_tag=$(git ls-remote --tags "$TARGET" "$NEW_TAG" 2>/dev/null)
  [[ -z "$remote_tag" ]] && die 1 "Tag $NEW_TAG not found on remote ${TARGET}"
  info "Verified: tag exists on ${TARGET}"
}

print_summary() {
  echo ""
  echo "status:     success"
  echo "tag:        ${NEW_TAG}"
  echo "commit:     ${TAG_COMMIT}"
  echo "remote:     ${TARGET}"
  echo "production: ${TARGET}/master → production"
}

# --- Main ---

main() {
  determine_target
  preflight
  create_tag
  push_production
  verify
  print_summary
}

main "$@"
