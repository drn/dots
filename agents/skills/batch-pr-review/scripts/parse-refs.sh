#!/usr/bin/env bash
# Extract unique GitHub PR references from text on stdin.
# Recognizes full URLs (https://github.com/o/r/pull/N), short refs (o/r#N),
# and bare #N when --repo owner/repo is given.
# Output: one "owner/repo N" line per PR, in first-seen order.
set -euo pipefail

default_repo=""
if [[ "${1:-}" == "--repo" ]]; then
  default_repo="${2:-}"
fi

text="$(cat)"

{
  printf '%s\n' "$text" \
    | grep -oE 'github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+/pull/[0-9]+' \
    | sed -E 's#github\.com/([^/]+/[^/]+)/pull/([0-9]+)#\1 \2#' || true
  printf '%s\n' "$text" \
    | sed -E 's#https?://[^ ]*##g' \
    | grep -oE '[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+#[0-9]+' \
    | sed -E 's#^(.*)\#([0-9]+)$#\1 \2#' || true
  if [[ -n "$default_repo" ]]; then
    printf '%s\n' "$text" \
      | sed -E 's#https?://[^ ]*##g; s#[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+\#[0-9]+##g' \
      | grep -oE '(^|[^A-Za-z0-9_])#[0-9]+' \
      | grep -oE '[0-9]+' \
      | sed "s#^#${default_repo} #" || true
  fi
} | awk '!seen[$0]++'
