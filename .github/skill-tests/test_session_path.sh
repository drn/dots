#!/usr/bin/env bash
source "$(dirname "$0")/harness.sh"

# Hook lives outside agents/skills, so SCRIPTS_DIR (which points at
# agents/skills) doesn't help — derive the hook path from the test file.
HOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../agents/hooks" && pwd)/session-start-path.sh"

# Build an isolated fake HOME with go/bin + asdf shims present (but not cargo)
# so we can assert which dirs the hook prepends. Returns the HOME path.
_setup_path_home() {
  local home
  home=$(mktemp -d "${TMPDIR:-/tmp}/skill-test-XXXXXX")
  _TMPDIRS+=("$home")
  mkdir -p "$home/go/bin" "$home/.asdf/shims"
  # Deliberately omit "$home/.cargo/bin" — the hook should skip missing dirs.
  echo "$home"
}

# Run the hook with a fresh CLAUDE_ENV_FILE and print that file's path.
# Args: <fake-home> <env-file>
_run_hook() {
  local home="$1" envfile="$2"
  # GOBIN unset so the hook falls back to $HOME/go/bin; HOME redirected.
  HOME="$home" GOBIN="" GOPATH="" CLAUDE_ENV_FILE="$envfile" \
    bash "$HOOK" </dev/null
}

test_prepends_existing_dev_dirs() {
  local home envfile
  home=$(_setup_path_home)
  envfile="$home/envfile"

  _run_hook "$home" "$envfile"

  local body
  body=$(cat "$envfile")
  assert_contains "$body" "export PATH=\"$home/go/bin:\$PATH\"" "go/bin should be prepended"
  assert_contains "$body" "export PATH=\"$home/.asdf/shims:\$PATH\"" "asdf shims should be prepended"
  assert_not_contains "$body" "$home/.cargo/bin" "missing cargo dir should be skipped"
}

test_gobin_is_frontmost_after_sourcing() {
  local home envfile
  home=$(_setup_path_home)
  envfile="$home/envfile"

  _run_hook "$home" "$envfile"

  # Source the env file from a clean PATH and confirm go/bin wins the front
  # slot (mirrors ~/.zshenv ordering so go binaries bypass the asdf shims).
  local resolved
  resolved=$(PATH=/usr/bin:/bin bash -c "source '$envfile'; echo \"\$PATH\"" | cut -d: -f1)
  assert_eq "$resolved" "$home/go/bin" "go/bin should be the frontmost PATH entry"
}

test_idempotent_across_repeated_fires() {
  local home envfile
  home=$(_setup_path_home)
  envfile="$home/envfile"

  # SessionStart can fire multiple times in one session; the env file persists,
  # so re-running must not duplicate export lines.
  _run_hook "$home" "$envfile"
  _run_hook "$home" "$envfile"

  # grep -cF counts matching LINES; each export is one line, so this is the
  # occurrence count. Exactly 1 = the second fire saw the line and skipped it.
  local gobin_lines
  gobin_lines=$(grep -cF "$home/go/bin:\$PATH" "$envfile")
  assert_eq "$gobin_lines" "1" "go/bin export should appear exactly once after two fires"
}

test_uses_gopath_fallback_when_gobin_unset() {
  local home envfile
  home=$(_setup_path_home)
  envfile="$home/envfile"
  mkdir -p "$home/custom-gopath/bin"

  # GOBIN unset but GOPATH set: the hook should derive $GOPATH/bin, not ~/go/bin.
  HOME="$home" GOBIN="" GOPATH="$home/custom-gopath" CLAUDE_ENV_FILE="$envfile" \
    bash "$HOOK" </dev/null

  local body
  body=$(cat "$envfile")
  assert_contains "$body" "export PATH=\"$home/custom-gopath/bin:\$PATH\"" "GOPATH/bin should be used when GOBIN is unset"
  assert_not_contains "$body" "$home/go/bin:\$PATH" "default ~/go/bin should not be used when GOPATH is set"
}

test_respects_custom_gobin() {
  local home envfile
  home=$(_setup_path_home)
  envfile="$home/envfile"
  mkdir -p "$home/custom-gobin"

  HOME="$home" GOBIN="$home/custom-gobin" GOPATH="" CLAUDE_ENV_FILE="$envfile" \
    bash "$HOOK" </dev/null

  local body
  body=$(cat "$envfile")
  assert_contains "$body" "export PATH=\"$home/custom-gobin:\$PATH\"" "custom GOBIN should be honored"
  assert_not_contains "$body" "$home/go/bin:\$PATH" "default go/bin should not be used when GOBIN is set"
}

test_noop_without_env_file() {
  local home
  home=$(_setup_path_home)

  # No CLAUDE_ENV_FILE (e.g. a hook event that doesn't provide one): the hook
  # must exit cleanly without writing anything.
  local out exit_code=0
  out=$(HOME="$home" CLAUDE_ENV_FILE="" bash "$HOOK" </dev/null 2>&1) || exit_code=$?
  assert_eq "$exit_code" "0" "hook should exit 0 when CLAUDE_ENV_FILE is unset"
  assert_eq "$out" "" "hook should produce no output when CLAUDE_ENV_FILE is unset"
}

run_tests
