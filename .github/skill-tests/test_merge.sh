#!/usr/bin/env bash
source "$(dirname "$0")/harness.sh"

MERGE="$SCRIPTS_DIR/merge/scripts/merge.sh"

# Source the script to get access to functions without running main
_source_merge() {
  eval "$(sed 's/^main "\$@"//' "$MERGE")"
}

test_determine_target_with_upstream() {
  make_test_repo >/dev/null
  add_test_remote "origin" >/dev/null
  add_test_remote "upstream" >/dev/null

  _source_merge
  determine_target

  assert_eq "$TARGET" "upstream" "should prefer upstream remote"
}

test_determine_target_without_upstream() {
  make_test_repo >/dev/null
  add_test_remote "origin" >/dev/null

  _source_merge
  determine_target

  assert_eq "$TARGET" "origin" "should fall back to origin"
}

test_get_branch_detached_head() {
  make_test_repo >/dev/null
  git checkout -q --detach HEAD

  _source_merge
  capture get_branch
  assert_eq "$_CAPTURED_EXIT" "1" "should exit 1 on detached HEAD"
  assert_contains "$_CAPTURED" "Detached HEAD" "should report detached HEAD"
}

test_get_branch_on_master() {
  make_test_repo >/dev/null

  _source_merge
  capture get_branch
  assert_eq "$_CAPTURED_EXIT" "1" "should exit 1 on default branch"
  assert_match "$_CAPTURED" "Already on (main|master)" "should report already on default branch"
}

test_get_branch_feature() {
  make_test_repo >/dev/null
  git checkout -q -b feature/test

  _source_merge
  get_branch 2>/dev/null

  assert_eq "$BRANCH" "feature/test" "should detect feature branch"
}

test_check_commits_zero() {
  make_test_repo >/dev/null
  add_test_remote "origin" >/dev/null
  git checkout -q -b feature/empty

  _source_merge
  TARGET="origin"
  DEFAULT_BRANCH="master"
  capture check_commits
  assert_eq "$_CAPTURED_EXIT" "3" "should exit 3 when no commits"
}

test_check_commits_nonzero() {
  make_test_repo >/dev/null
  add_test_remote "origin" >/dev/null
  git checkout -q -b feature/work
  git commit -q --allow-empty -m "work"

  _source_merge
  TARGET="origin"
  DEFAULT_BRANCH="master"
  check_commits 2>/dev/null

  assert_eq "$COMMIT_COUNT" "1" "should count 1 commit"
}

test_usage_no_args() {
  make_test_repo >/dev/null
  capture bash "$MERGE"
  assert_eq "$_CAPTURED_EXIT" "1" "should exit 1 with no args"
}

test_skip_rebase_flag() {
  make_test_repo >/dev/null
  add_test_remote "origin" >/dev/null
  git checkout -q -b feature/test
  git commit -q --allow-empty -m "work"

  # With --skip-rebase, the script should skip rebasing
  # It will still fail at push/PR stage, but should get past rebase
  capture bash "$MERGE" --skip-rebase "test title" "test body"
  # It will fail because gh is not set up, but should not fail at rebase
  assert_not_contains "$_CAPTURED" "REBASE_CONFLICT" "should not have rebase conflict"
}

test_squash_flag_accepted() {
  make_test_repo >/dev/null
  add_test_remote "origin" >/dev/null
  git checkout -q -b feature/test
  git commit -q --allow-empty -m "work"

  # --squash is a no-op (squash is already the default) but should not error
  capture bash "$MERGE" --squash "test title" "test body"
  # It will fail at push/PR stage, but should not fail at flag parsing
  assert_not_contains "$_CAPTURED" "Unknown flag" "should accept --squash without error"
}

test_method_rebase_flag_accepted() {
  make_test_repo >/dev/null
  add_test_remote "origin" >/dev/null
  git checkout -q -b feature/test
  git commit -q --allow-empty -m "work"

  # --rebase is the regression case for the bash 3.2 empty-array crash
  capture bash "$MERGE" --rebase "test title" "test body"
  assert_not_contains "$_CAPTURED" "Unknown flag" "should accept --rebase without error"
  assert_not_contains "$_CAPTURED" "unbound variable" "should not crash on empty subject_flags array under set -u"
}

test_method_merge_flag_accepted() {
  make_test_repo >/dev/null
  add_test_remote "origin" >/dev/null
  git checkout -q -b feature/test
  git commit -q --allow-empty -m "work"

  capture bash "$MERGE" --merge "test title" "test body"
  assert_not_contains "$_CAPTURED" "Unknown flag" "should accept --merge without error"
  assert_not_contains "$_CAPTURED" "unbound variable" "should not crash under set -u"
}

test_method_long_flag_accepted() {
  make_test_repo >/dev/null
  add_test_remote "origin" >/dev/null
  git checkout -q -b feature/test
  git commit -q --allow-empty -m "work"

  capture bash "$MERGE" --method rebase "test title" "test body"
  assert_not_contains "$_CAPTURED" "Unknown flag" "should accept --method rebase"
  assert_not_contains "$_CAPTURED" "unbound variable" "should not crash under set -u"
}

test_method_invalid_value_rejected() {
  make_test_repo >/dev/null
  add_test_remote "origin" >/dev/null
  git checkout -q -b feature/test
  git commit -q --allow-empty -m "work"

  capture bash "$MERGE" --method bogus "test title" "test body"
  assert_eq "$_CAPTURED_EXIT" "1" "should exit 1 on invalid --method value"
  assert_contains "$_CAPTURED" "Invalid --method" "should report the invalid value"
}

test_unknown_flag_rejected() {
  make_test_repo >/dev/null
  add_test_remote "origin" >/dev/null
  git checkout -q -b feature/test
  git commit -q --allow-empty -m "work"

  capture bash "$MERGE" --bogus "test title" "test body"
  assert_eq "$_CAPTURED_EXIT" "1" "should exit 1 on unknown flag"
  assert_contains "$_CAPTURED" "Unknown flag: --bogus" "should report the unknown flag"
}

test_coauthor_appended() {
  _source_merge
  # The COAUTHOR line should be defined
  assert_contains "$COAUTHOR" "Co-Authored-By:" "should define COAUTHOR"
  assert_contains "$COAUTHOR" "Claude" "should credit Claude"
}

test_summary_format() {
  _source_merge
  MERGE_STATUS="merged"
  MERGE_METHOD="squash"
  PR_URL="https://github.com/test/repo/pull/1"
  BRANCH="feature/test"
  DEFAULT_BRANCH="master"
  COMMIT_COUNT="3"
  MERGE_COMMIT="abc1234 Some commit"
  DOTS_SYNCED=""

  local output
  output=$(print_summary)

  assert_contains "$output" "status:   merged" "should show status"
  assert_contains "$output" "method:   squash" "should show method"
  assert_contains "$output" "pr:       https://github.com/test/repo/pull/1" "should show PR URL"
  assert_contains "$output" "branch:   feature/test → master" "should show branch arrow with default branch"
  assert_contains "$output" "commits:  3" "should show commit count"
  assert_contains "$output" "commit:   abc1234" "should show master commit"
  assert_not_contains "$output" "~/.dots:" "should not show dots when empty"
}

test_summary_format_rebase_method() {
  _source_merge
  MERGE_STATUS="merged"
  MERGE_METHOD="rebase"
  PR_URL="https://github.com/test/repo/pull/2"
  BRANCH="feature/rebase-only"
  DEFAULT_BRANCH="main"
  COMMIT_COUNT="2"
  MERGE_COMMIT=""
  DOTS_SYNCED=""

  local output
  output=$(print_summary)

  assert_contains "$output" "method:   rebase" "should surface rebase method in summary"
}

test_summary_format_merge_commit_method() {
  _source_merge
  MERGE_STATUS="merged"
  MERGE_METHOD="merge"
  PR_URL="https://github.com/test/repo/pull/3"
  BRANCH="feature/merge-only"
  DEFAULT_BRANCH="main"
  COMMIT_COUNT="4"
  MERGE_COMMIT=""
  DOTS_SYNCED=""

  local output
  output=$(print_summary)

  assert_contains "$output" "method:   merge" "should surface merge-commit method in summary"
}

test_detect_allowed_methods_fallback_when_probe_fails() {
  make_test_repo >/dev/null

  _source_merge
  # Stub gh to a no-op failure so the fallback path runs hermetically (no
  # network, no auth state). detect_allowed_methods must default to all three
  # methods in preference order.
  gh() { return 1; }
  REPO_SLUG="example-org/example-repo"
  detect_allowed_methods 2>/dev/null
  unset -f gh

  assert_eq "${#ALLOWED_METHODS[@]}" "3" "fallback should list all 3 methods"
  assert_eq "${ALLOWED_METHODS[*]}" "squash rebase merge" "fallback order should be squash → rebase → merge"
}

test_detect_allowed_methods_parses_probe() {
  make_test_repo >/dev/null

  _source_merge
  # Stub gh to return TSV: squash=false, rebase=true, merge=false.
  # detect_allowed_methods should pick only rebase.
  gh() { printf 'false\ttrue\tfalse\n'; }
  REPO_SLUG="example-org/rebase-only"
  detect_allowed_methods 2>/dev/null
  unset -f gh

  assert_eq "${#ALLOWED_METHODS[@]}" "1" "should pick only the allowed method"
  assert_eq "${ALLOWED_METHODS[0]}" "rebase" "should select rebase when only rebase is allowed"
}

test_detect_allowed_methods_requires_repo_slug() {
  _source_merge
  REPO_SLUG=""
  capture detect_allowed_methods
  assert_eq "$_CAPTURED_EXIT" "1" "should die if REPO_SLUG is unset"
  assert_contains "$_CAPTURED" "REPO_SLUG not set" "should report missing REPO_SLUG"
}

run_tests
