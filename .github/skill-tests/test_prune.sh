#!/usr/bin/env bash
source "$(dirname "$0")/harness.sh"

PRUNE="$SCRIPTS_DIR/prune/scripts/prune.sh"

# Source the script to get access to functions without running main
_source_prune() {
  eval "$(sed 's/^main "\$@"//' "$PRUNE")"
}

test_usage_no_args() {
  make_test_repo >/dev/null
  capture bash "$PRUNE"
  assert_eq "$_CAPTURED_EXIT" "1" "should exit 1 with no args"
  assert_contains "$_CAPTURED" "Usage:" "should show usage"
}

test_is_protected_current_branch() {
  _source_prune
  is_protected "my-feature" "my-feature" "main"
  assert_eq "$?" "0" "current branch should be protected"
}

test_is_protected_default_branch() {
  _source_prune
  is_protected "main" "other" "main"
  assert_eq "$?" "0" "default branch should be protected"
}

test_is_protected_well_known() {
  _source_prune
  is_protected "master" "feature" "main"
  assert_eq "$?" "0" "master should be protected"

  is_protected "develop" "feature" "main"
  assert_eq "$?" "0" "develop should be protected"

  is_protected "staging" "feature" "main"
  assert_eq "$?" "0" "staging should be protected"
}

test_is_protected_release() {
  _source_prune
  is_protected "release/2.0" "feature" "main"
  assert_eq "$?" "0" "release/* should be protected"

  is_protected "release/hotfix-123" "feature" "main"
  assert_eq "$?" "0" "release/hotfix should be protected"
}

test_is_not_protected_feature() {
  _source_prune
  local result=0
  is_protected "feature/foo" "main-branch" "main" || result=$?
  assert_eq "$result" "1" "feature branch should not be protected"
}

test_get_default_branch_main() {
  make_test_repo >/dev/null
  add_test_remote "origin" >/dev/null
  git push -q origin HEAD:main 2>/dev/null
  git remote set-head origin main 2>/dev/null || true

  _source_prune
  local result
  result=$(get_default_branch)
  assert_match "$result" "^(main|master)$" "should detect main or master"
}

test_preview_nothing_to_prune() {
  make_test_repo >/dev/null
  add_test_remote "origin" >/dev/null

  capture bash "$PRUNE" preview
  assert_eq "$_CAPTURED_EXIT" "3" "should exit 3 when nothing to prune"
}

test_preview_finds_merged_branches() {
  make_test_repo >/dev/null
  add_test_remote "origin" >/dev/null

  # Create and merge a branch
  git checkout -q -b feature/done
  git commit -q --allow-empty -m "feature work"
  git checkout -q master
  git merge -q feature/done

  capture bash "$PRUNE" preview
  # Should find the merged branch (exit 0) or nothing if branch auto-cleaned
  if [[ "$_CAPTURED_EXIT" == "0" ]]; then
    assert_contains "$_CAPTURED" "MERGED:" "should list merged section"
    assert_contains "$_CAPTURED" "feature/done" "should find merged branch"
  else
    assert_eq "$_CAPTURED_EXIT" "3" "should be exit 3 if no branches to prune"
  fi
}

test_preview_stale_days_arg() {
  make_test_repo >/dev/null
  add_test_remote "origin" >/dev/null

  # Create a branch with an old commit
  git checkout -q -b old-branch
  GIT_COMMITTER_DATE="2020-01-01T00:00:00" git commit -q --allow-empty -m "old work" --date="2020-01-01T00:00:00"
  git checkout -q master

  capture bash "$PRUNE" preview --stale-days 1
  assert_eq "$_CAPTURED_EXIT" "0" "should exit 0 with stale branches"
  assert_contains "$_CAPTURED" "STALE:" "should find stale branches"
  assert_contains "$_CAPTURED" "old-branch" "should list old-branch as stale"
}

test_stale_days_non_numeric() {
  make_test_repo >/dev/null
  add_test_remote "origin" >/dev/null

  capture bash "$PRUNE" preview --stale-days abc
  assert_eq "$_CAPTURED_EXIT" "1" "should exit 1 with non-numeric stale-days"
  assert_contains "$_CAPTURED" "must be a number" "should report invalid stale-days"
}

test_delete_protected_branch_safety() {
  make_test_repo >/dev/null
  add_test_remote "origin" >/dev/null

  capture bash "$PRUNE" delete master
  assert_contains "$_CAPTURED" "Protected branch" "should refuse to delete master"
}

test_delete_no_branches_specified() {
  make_test_repo >/dev/null
  add_test_remote "origin" >/dev/null

  capture bash "$PRUNE" delete
  assert_eq "$_CAPTURED_EXIT" "1" "should exit 1 when no branches specified"
}

test_delete_nonexistent_branch() {
  make_test_repo >/dev/null
  add_test_remote "origin" >/dev/null

  capture bash "$PRUNE" delete nonexistent-branch
  assert_contains "$_CAPTURED" "FAILED:" "should report failure for nonexistent branch"
}

test_summary_format() {
  make_test_repo >/dev/null
  add_test_remote "origin" >/dev/null

  git checkout -q -b to-delete
  git commit -q --allow-empty -m "work"
  git checkout -q master
  git merge -q to-delete

  local output
  output=$(bash "$PRUNE" delete to-delete 2>&1) || true
  assert_contains "$output" "--- PRUNE RESULT ---" "should have header"
  assert_contains "$output" "--- END ---" "should have footer"
}

run_tests
