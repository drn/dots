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
  COMMIT_COUNT="3"
  MASTER_COMMIT="abc1234 Some commit"
  DOTS_SYNCED=""

  local output
  output=$(print_summary)

  assert_contains "$output" "status:   merged" "should show status"
  assert_contains "$output" "method:   squash" "should show method"
  assert_contains "$output" "pr:       https://github.com/test/repo/pull/1" "should show PR URL"
  assert_contains "$output" "commits:  3" "should show commit count"
  assert_contains "$output" "commit:   abc1234" "should show master commit"
  assert_not_contains "$output" "~/.dots:" "should not show dots when empty"
}

run_tests
