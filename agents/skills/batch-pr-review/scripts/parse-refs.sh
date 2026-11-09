#!/usr/bin/env bash
# Extract unique GitHub PR references from text on stdin.
# Recognizes full URLs (https://github.com/o/r/pull/N), short refs (o/r#N),
# and bare #N when --repo owner/repo is given.
# Output: one "owner/repo N" line per PR, grouped by form (URLs, then short
# refs, then bare numbers), first-seen order within each group, exact-case dedupe.
set -euo pipefail

default_repo=""
if [[ "${1:-}" == "--repo" ]]; then
  default_repo="${2:-}"
  if [[ ! "$default_repo" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
    echo "parse-refs: --repo must look like owner/repo" >&2
    exit 2
  fi
fi

text="$(cat)"

{
  printf '%s\n' "$text" \
    | grep -oE 'github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+/pull/[0-9]+([^0-9A-Za-z]|$)' \
    | sed -E 's#github\.com/([^/]+/[^/]+)/pull/([0-9]+).*#\1 \2#' || true
  printf '%s\n' "$text" \
    | sed -E 's#https?://[^ ]*##g' \
    | grep -oE '(^|[^A-Za-z0-9_./-])[A-Za-z0-9_-][A-Za-z0-9_.-]*/[A-Za-z0-9_.-]+#[0-9]+' \
    | sed -E 's#^[^A-Za-z0-9_-]##; s#^(.*)\#([0-9]+)$#\1 \2#' || true
  if [[ -n "$default_repo" ]]; then
    printf '%s\n' "$text" \
      | sed -E 's#https?://[^ ]*##g; s#[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+\#[0-9]+##g' \
      | grep -oE '(^|[^A-Za-z0-9_])#[0-9]+' \
      | grep -oE '[0-9]+' \
      | awk -v r="$default_repo" '{print r, $0}' || true
  fi
} | awk '!seen[$0]++'
