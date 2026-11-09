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

test_trailing_punctuation_and_slack_links() {
  local out
  out="$(printf '(https://github.com/acme/api/pull/12), <https://github.com/acme/web/pull/7|web 7>. and acme/db#3.' | bash "$PARSE")"
  assert_eq "$out" $'acme/api 12\nacme/web 7\nacme/db 3' "punctuation and slack link forms"
}

test_rejects_bad_repo() {
  local rc=0
  printf '#3' | bash "$PARSE" --repo 'a/b#c' >/dev/null 2>&1 || rc=$?
  assert_eq "$rc" "2" "repo with sed metacharacters is rejected"
  rc=0
  printf '#3' | bash "$PARSE" --repo acme >/dev/null 2>&1 || rc=$?
  assert_eq "$rc" "2" "slash-less repo is rejected"
  rc=0
  printf '#3' | bash "$PARSE" --repo >/dev/null 2>&1 || rc=$?
  assert_eq "$rc" "2" "missing repo value is rejected"
}

test_ignores_non_pr_paths() {
  local out
  out="$(printf 'https://github.com/acme/api/issues/7 https://github.com/acme/api/pull/12abc path/to/file#12' | bash "$PARSE")"
  assert_eq "$out" "" "issues, glued suffixes, and file anchors are not PRs"
}

test_empty_stdin() {
  local out
  out="$(printf '' | bash "$PARSE")"
  assert_eq "$out" "" "empty input yields empty output"
}

run_tests
