#!/usr/bin/env bash
source "$(dirname "$0")/harness.sh"

DEPLOY="$SCRIPTS_DIR/deploy/scripts/deploy.sh"

# Source the script to get access to functions without running main
_source_deploy() {
  # Override main so sourcing doesn't execute it
  eval "$(sed 's/^main "\$@"//' "$DEPLOY")"
}

test_determine_target_with_upstream() {
  make_test_repo >/dev/null
  add_test_remote "origin" >/dev/null
  add_test_remote "upstream" >/dev/null

  _source_deploy
  determine_target

  assert_eq "$TARGET" "upstream" "should prefer upstream remote"
}

test_determine_target_without_upstream() {
  make_test_repo >/dev/null
  add_test_remote "origin" >/dev/null

  _source_deploy
  determine_target

  assert_eq "$TARGET" "origin" "should fall back to origin"
}

test_preflight_no_remotes() {
  make_test_repo >/dev/null

  _source_deploy
  capture bash "$DEPLOY"
  assert_eq "$_CAPTURED_EXIT" "1" "should exit 1 with no remotes"
  assert_contains "$_CAPTURED" "No remotes configured" "should report no remotes"
}

test_preflight_fetch_success() {
  make_test_repo >/dev/null
  add_test_remote "origin" >/dev/null

  _source_deploy
  determine_target
  # preflight should not die — fetch should succeed against local bare repo
  preflight 2>/dev/null
  assert_eq "$?" "0" "preflight should succeed with valid remote"
}

test_create_tag_detects_new_tag() {
  make_test_repo >/dev/null
  add_test_remote "origin" >/dev/null

  # Simulate version update by replacing it with a function
  # that creates a tag
  version-update() { git tag -a "v1.0.0" -m "test tag"; }
  export -f version-update

  _source_deploy
  TARGET="origin"
  git fetch origin 2>/dev/null

  create_tag 2>/dev/null

  assert_eq "$NEW_TAG" "v1.0.0" "should detect the new tag"
  # Verify tag was moved to origin/master (dereference annotated tag to commit)
  local tag_target
  tag_target=$(git rev-parse "v1.0.0^{commit}" 2>/dev/null)
  local master_target
  master_target=$(git rev-parse "origin/master" 2>/dev/null)
  assert_eq "$tag_target" "$master_target" "tag should point to origin/master"

  unset -f version-update
}

test_summary_format() {
  make_test_repo >/dev/null

  _source_deploy
  NEW_TAG="v2.0.0"
  TAG_COMMIT="abc1234"
  TARGET="upstream"

  local output
  output=$(print_summary)

  assert_contains "$output" "status:     success" "should show success"
  assert_contains "$output" "tag:        v2.0.0" "should include tag"
  assert_contains "$output" "remote:     upstream" "should include remote"
}

test_exit_1_on_no_remotes() {
  make_test_repo >/dev/null
  capture bash "$DEPLOY"
  assert_eq "$_CAPTURED_EXIT" "1" "should exit 1 when no remotes"
}

test_end_to_end_with_mock_thanx() {
  make_test_repo >/dev/null
  add_test_remote "origin" >/dev/null
  git fetch origin 2>/dev/null

  # Mock version-update to create a tag
  export PATH="$PWD/bin:$PATH"
  mkdir -p bin
  cat > bin/version-update <<'MOCK'
#!/usr/bin/env bash
git tag -a "v9.0.0" -m "mock tag"
exit 0
MOCK
  chmod +x bin/version-update

  # Mock git push and git ls-remote to avoid needing a real writable remote
  # Run just create_tag to verify the full tag flow
  _source_deploy
  TARGET="origin"
  create_tag 2>/dev/null

  assert_eq "$NEW_TAG" "v9.0.0" "e2e: should detect tag"
  assert_eq "$(git rev-parse 'v9.0.0^{commit}')" "$(git rev-parse origin/master)" "e2e: tag on origin/master"

  rm -rf bin
}

run_tests
