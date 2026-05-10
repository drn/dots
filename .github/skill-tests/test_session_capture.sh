#!/usr/bin/env bash
source "$(dirname "$0")/harness.sh"

# Hook lives outside agents/skills, so SCRIPTS_DIR (which points at
# agents/skills) doesn't help — derive the hook path from the test file.
HOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../agents/hooks" && pwd)/session-end-capture.sh"

# Build an isolated test environment:
#   - fresh git repo as cwd
#   - bare "remote" so origin/master exists
#   - synthetic transcript JSONL
#   - fake argus(1) on PATH that returns the temp vault path
#   - HOME redirected to keep ~/.dots/sys writes contained
# Returns: prints VAULT path on stdout
_setup_session_env() {
  # make_test_repo / add_test_remote rely on `cd` taking effect in the
  # caller's shell — so they must be called WITHOUT `$()` wrapping.
  # Capture the resulting cwd via pwd after the cd lands.
  make_test_repo >/dev/null
  add_test_remote "origin" >/dev/null
  local repo
  repo=$(pwd)

  # SAFETY: refuse to proceed if cd-to-temp-dir didn't take effect. Without
  # this guard, downstream `git push -q origin master` runs against the
  # caller's real remote (`add_test_remote` silently leaves the existing
  # `origin` URL when `git remote add` collides). A previous version of this
  # test pushed junk commits to GitHub master before the bug was caught.
  case "$repo" in
    *"/skill-test-"*) ;;
    *)
      echo "FATAL: test setup did not cd into a temp dir (cwd=$repo). Aborting to avoid pushing to a real remote." >&2
      exit 1
      ;;
  esac
  # Belt-and-suspenders: explicitly point origin at the temp bare repo
  # regardless of whatever `add_test_remote` did. If `git remote set-url`
  # fails (e.g. cwd is not a git repo at all), bail.
  local temp_remote
  temp_remote=$(git remote get-url origin 2>/dev/null)
  case "$temp_remote" in
    *"/skill-remote-"*) ;;
    *)
      echo "FATAL: origin URL is not a temp bare repo (got: $temp_remote). Aborting." >&2
      exit 1
      ;;
  esac

  # Author identity is required by the hook (filters commits by author).
  git config user.email "test@test.com"

  # Make a session-eligible commit on master so origin/master is non-empty
  # and the hook's merge-base check has a target. Push it so origin has it.
  # Ensure local branch is `master` regardless of the host's `init.defaultBranch`
  # so the hook's `origin/master` lookup hits.
  git branch -M master 2>/dev/null
  echo "seed" > seed.txt
  git add seed.txt
  git commit -q -m "seed commit"
  git push -q origin master

  # Vault dir under the temp tree so cleanup happens automatically.
  local vault="$repo/.test-vault"
  mkdir -p "$vault/memory"
  _TEST_VAULT="$vault"

  # Transcript: timestamp captured AFTER seed setup so the seed isn't picked
  # up as a session commit. The 1-second sleep ensures the seed commit's
  # committer date is strictly LESS than this timestamp (git's --since uses
  # second-level granularity, so same-second commits are inclusive).
  sleep 1
  local ts
  ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  local transcript="$repo/.test-transcript.jsonl"
  printf '{"type":"user","timestamp":"%s","message":{"role":"user","content":"fix the bug"}}\n' "$ts" \
    > "$transcript"
  _TEST_TRANSCRIPT="$transcript"
  _TEST_TS="$ts"

  # Stub argus(1) with a tiny shell wrapper that satisfies the hook's only
  # call: `argus kb status`. Place it on PATH ahead of the real argus.
  local stub_dir="$repo/.test-bin"
  mkdir -p "$stub_dir"
  cat > "$stub_dir/argus" <<EOF
#!/usr/bin/env bash
if [ "\$1" = "kb" ] && [ "\$2" = "status" ]; then
  echo "Vault     : $vault"
  exit 0
fi
exit 0
EOF
  chmod +x "$stub_dir/argus"
  _TEST_PATH="$stub_dir:$PATH"

  # Redirect HOME so ~/.dots/sys/kb-changes lands in the temp tree.
  _TEST_HOME="$repo/.test-home"
  mkdir -p "$_TEST_HOME"

  echo "$vault"
}

# Build the JSON the hook reads on stdin.
_session_input() {
  local session_id="$1"
  local cwd="$2"
  jq -nc \
    --arg sid "$session_id" \
    --arg cwd "$cwd" \
    --arg tp "$_TEST_TRANSCRIPT" \
    '{session_id:$sid,cwd:$cwd,transcript_path:$tp,hook_event_name:"SessionEnd"}'
}

# Find the inbox file created by the hook (slug is dynamic on repo basename).
_find_inbox_file() {
  local vault="$1"
  find "$vault/memory/inbox" -name '*.md' 2>/dev/null | head -1
}

test_captures_session_with_no_commits() {
  _setup_session_env >/dev/null
  local cwd
  cwd=$(pwd)

  # No new commits past the seed; the hook should still capture, tagged
  # `no-commit` so dream can downrank it during synthesis.
  local input
  input=$(_session_input "test-no-commit-1" "$cwd")

  HOME="$_TEST_HOME" PATH="$_TEST_PATH" bash "$HOOK" <<< "$input" || true

  local file
  file=$(_find_inbox_file "$_TEST_VAULT")
  assert_match "$file" '\.md$' "inbox file should be created even with no commits"

  if [ -n "$file" ]; then
    local body
    body=$(cat "$file")
    assert_contains "$body" "no-commit" "no-commit session should tag no-commit"
    assert_contains "$body" "fix the bug" "user intent should still be captured"
    assert_not_contains "$body" "commit-merged" "no-commit session should not tag commit-merged"
    assert_not_contains "$body" "work-in-progress" "no-commit session should not tag work-in-progress"
    assert_not_contains "$body" "## Commits" "no-commit session should not render Commits section"
  fi
}

test_captures_session_outside_git_repo() {
  local non_repo
  non_repo=$(mktemp -d "${TMPDIR:-/tmp}/skill-test-XXXXXX")
  _TMPDIRS+=("$non_repo")

  # Set up a vault and stub argus, but point cwd at a non-repo dir.
  local vault="$non_repo/.test-vault"
  mkdir -p "$vault/memory"
  local stub_dir="$non_repo/.test-bin"
  mkdir -p "$stub_dir"
  cat > "$stub_dir/argus" <<EOF
#!/usr/bin/env bash
if [ "\$1" = "kb" ] && [ "\$2" = "status" ]; then
  echo "Vault     : $vault"
fi
EOF
  chmod +x "$stub_dir/argus"

  local transcript="$non_repo/transcript.jsonl"
  printf '%s\n' '{"type":"user","timestamp":"1970-01-01T00:00:00Z","message":{"role":"user","content":"research markdown formats"}}' > "$transcript"

  local input
  input=$(jq -nc --arg sid "no-repo" --arg cwd "$non_repo" --arg tp "$transcript" \
    '{session_id:$sid,cwd:$cwd,transcript_path:$tp}')

  HOME="$non_repo/.home" PATH="$stub_dir:$PATH" bash "$HOOK" <<< "$input" || true

  local file
  file=$(find "$vault/memory/inbox" -name '*.md' 2>/dev/null | head -1)
  assert_match "$file" '\.md$' "inbox file should be created even outside a git repo"

  if [ -n "$file" ]; then
    local body
    body=$(cat "$file")
    assert_contains "$body" "no-commit" "non-git session should tag no-commit"
    assert_contains "$body" "research markdown formats" "intent should be captured"
    assert_contains "$body" "non-git working directory" "doc should mark cwd as non-git"
  fi
}

test_skips_session_with_no_transcript() {
  _setup_session_env >/dev/null
  local cwd
  cwd=$(pwd)

  # transcript_path empty — no intent, no excerpt, nothing to distill.
  local input
  input=$(jq -nc --arg sid "no-transcript" --arg cwd "$cwd" \
    '{session_id:$sid,cwd:$cwd,transcript_path:"",hook_event_name:"SessionEnd"}')

  HOME="$_TEST_HOME" PATH="$_TEST_PATH" bash "$HOOK" <<< "$input" || true

  local file
  file=$(_find_inbox_file "$_TEST_VAULT")
  assert_eq "$file" "" "no inbox file when transcript_path is empty"

  local log="$_TEST_HOME/.dots/sys/session-end-capture.log"
  assert_contains "$(cat "$log" 2>/dev/null || echo "")" "skip:no-transcript-path" \
    "debug log should record the skip reason"
}

test_captures_with_commit_merged_to_master() {
  _setup_session_env >/dev/null
  local cwd
  cwd=$(pwd)

  # Sleep 1s so the new commit is strictly after the transcript timestamp.
  # `git log --since` uses second-level granularity and treats same-second
  # commits as inclusive, so without the sleep, the seed commit could be
  # picked up alongside this test's commit. Don't remove this sleep without
  # also reworking the timestamp strategy. (Same applies to the other
  # `sleep 1` calls in this file.)
  sleep 1
  echo "feature" > feature.txt
  git add feature.txt
  git commit -q -m "ship feature foo"
  git push -q origin master

  local input
  input=$(_session_input "merged-session" "$cwd")

  HOME="$_TEST_HOME" PATH="$_TEST_PATH" bash "$HOOK" <<< "$input" || true

  local file
  file=$(_find_inbox_file "$_TEST_VAULT")
  assert_match "$file" '\.md$' "inbox file should be created"

  if [ -n "$file" ]; then
    local body
    body=$(cat "$file")
    assert_contains "$body" "high-value" "merged commit should tag high-value"
    assert_contains "$body" "commit-merged" "merged commit should tag commit-merged"
    assert_contains "$body" "ship feature foo" "commit subject should appear in body"
    assert_contains "$body" "[merged]" "commit status should be merged"
    assert_contains "$body" "fix the bug" "user intent from transcript should be captured"
    assert_contains "$body" "feature.txt" "files touched should appear"
    assert_not_contains "$body" "work-in-progress" "merged commit should not tag work-in-progress"
    assert_not_contains "$body" "no-commit" "merged commit should not tag no-commit"
  fi
}

test_captures_recent_prompts_excerpt() {
  _setup_session_env >/dev/null
  local cwd
  cwd=$(pwd)

  # Append two more user prompts so the hook has a "recent prompts" pool
  # to render. The first prompt (from _setup_session_env) is the intent;
  # the next two should appear under "Recent prompts".
  local extra_ts
  extra_ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  printf '{"type":"user","timestamp":"%s","message":{"role":"user","content":"actually try a different approach"}}\n' "$extra_ts" \
    >> "$_TEST_TRANSCRIPT"
  printf '{"type":"user","timestamp":"%s","message":{"role":"user","content":"ship it"}}\n' "$extra_ts" \
    >> "$_TEST_TRANSCRIPT"

  sleep 1
  echo "more" > more.txt
  git add more.txt
  git commit -q -m "add more"

  local input
  input=$(_session_input "excerpt-session" "$cwd")

  HOME="$_TEST_HOME" PATH="$_TEST_PATH" bash "$HOOK" <<< "$input" || true

  local file
  file=$(_find_inbox_file "$_TEST_VAULT")
  assert_match "$file" '\.md$' "inbox file should be created"

  if [ -n "$file" ]; then
    local body
    body=$(cat "$file")
    assert_contains "$body" "## Recent prompts" "recent prompts section should render when >1 prompt exists"
    assert_contains "$body" "actually try a different approach" "later prompts should appear in excerpt"
    assert_contains "$body" "ship it" "final prompt should appear in excerpt"
  fi
}

test_captures_wip_commit_not_on_master() {
  _setup_session_env >/dev/null
  local cwd
  cwd=$(pwd)

  # Branch off master and commit there so the commit is NOT on origin/master.
  sleep 1
  git checkout -q -b wip-branch
  echo "wip" > wip.txt
  git add wip.txt
  git commit -q -m "draft work in progress"

  local input
  input=$(_session_input "wip-session" "$cwd")

  HOME="$_TEST_HOME" PATH="$_TEST_PATH" bash "$HOOK" <<< "$input" || true

  local file
  file=$(_find_inbox_file "$_TEST_VAULT")
  assert_match "$file" '\.md$' "inbox file should be created for wip commits"

  if [ -n "$file" ]; then
    local body
    body=$(cat "$file")
    assert_contains "$body" "work-in-progress" "unmerged commit should tag work-in-progress"
    assert_not_contains "$body" "high-value" "unmerged commit should not be high-value"
    assert_not_contains "$body" "commit-merged" "unmerged commit should not be commit-merged"
    assert_contains "$body" "[wip]" "commit status should be wip"
  fi
}

test_logs_captured_status_on_success() {
  _setup_session_env >/dev/null
  local cwd
  cwd=$(pwd)

  sleep 1
  echo "logged" > logged.txt
  git add logged.txt
  git commit -q -m "commit for log status test"
  git push -q origin master

  local input
  input=$(_session_input "log-status-session" "$cwd")

  HOME="$_TEST_HOME" PATH="$_TEST_PATH" bash "$HOOK" <<< "$input" || true

  local log="$_TEST_HOME/.dots/sys/session-end-capture.log"
  assert_contains "$(cat "$log" 2>/dev/null || echo "")" "captured:commit-merged" \
    "debug log should record captured:commit-merged on successful merged capture"
}

test_redacts_credential_patterns_from_intent() {
  _setup_session_env >/dev/null
  local cwd
  cwd=$(pwd)

  # Replace the intent prompt with one containing a fake AWS-format key.
  # The redactor should mask it before the prompt lands in the inbox doc.
  local fake_key="AKIAIOSFODNN7EXAMPLE"
  : > "$_TEST_TRANSCRIPT"
  printf '{"type":"user","timestamp":"%s","message":{"role":"user","content":"deploy with %s now"}}\n' \
    "$_TEST_TS" "$fake_key" >> "$_TEST_TRANSCRIPT"

  sleep 1
  echo "redact" > redact.txt
  git add redact.txt
  git commit -q -m "redact test commit"

  local input
  input=$(_session_input "redact-session" "$cwd")

  HOME="$_TEST_HOME" PATH="$_TEST_PATH" bash "$HOOK" <<< "$input" || true

  local file
  file=$(_find_inbox_file "$_TEST_VAULT")
  assert_match "$file" '\.md$' "inbox file should still be created with redacted intent"

  if [ -n "$file" ]; then
    local body
    body=$(cat "$file")
    assert_contains "$body" "[REDACTED-AWS]" "AKIA-format key should be redacted"
    assert_not_contains "$body" "$fake_key" "raw AKIA-format key must not appear in inbox doc"
  fi
}

test_logs_change_to_kb_changes_file() {
  _setup_session_env >/dev/null
  local cwd
  cwd=$(pwd)

  sleep 1
  echo "ship" > ship.txt
  git add ship.txt
  git commit -q -m "another ship"
  git push -q origin master

  local input
  input=$(_session_input "logged-session" "$cwd")

  HOME="$_TEST_HOME" PATH="$_TEST_PATH" bash "$HOOK" <<< "$input" || true

  local log="$_TEST_HOME/.dots/sys/kb-changes/changes.jsonl"
  assert_match "$(cat "$log" 2>/dev/null || echo "")" "session-end-capture" "kb-changes log should record the capture"
}

run_tests
