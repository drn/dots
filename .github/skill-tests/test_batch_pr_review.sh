#!/usr/bin/env bash
source "$(dirname "$0")/harness.sh"

PARSE="$SCRIPTS_DIR/batch-pr-review/scripts/parse-refs.sh"

test_parses_urls() {
  local out
  out="$(printf 'see https://github.com/acme/api/pull/12 and https://github.com/acme/web/pull/7/files' | bash "$PARSE")"
  assert_eq "$out" $'acme/api 12\nacme/web 7' "full URLs resolve to repo and number"
}

test_parses_short_refs() {
  local out
  out="$(printf 'acme/api#5, acme/web#9' | bash "$PARSE")"
  assert_eq "$out" $'acme/api 5\nacme/web 9' "short refs resolve"
}

test_dedupes() {
  local out
  out="$(printf 'https://github.com/acme/api/pull/12 acme/api#12' | bash "$PARSE")"
  assert_eq "$out" "acme/api 12" "duplicates collapse"
}

test_bare_numbers_need_repo() {
  local out
  out="$(printf 'fix #3 and #4' | bash "$PARSE")"
  assert_eq "$out" "" "bare numbers ignored without --repo"
  out="$(printf 'fix #3 and #4' | bash "$PARSE" --repo acme/api)"
  assert_eq "$out" $'acme/api 3\nacme/api 4' "bare numbers use default repo"
}

test_bare_does_not_double_count_short_refs() {
  local out
  out="$(printf 'acme/web#9 and #3' | bash "$PARSE" --repo acme/api)"
  assert_eq "$out" $'acme/web 9\nacme/api 3' "short ref not re-read as bare number"
}

test_no_refs() {
  local out
  out="$(printf 'nothing here' | bash "$PARSE")"
  assert_eq "$out" "" "no refs yields empty output"
}

run_tests
