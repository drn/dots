#!/usr/bin/env bash
# Lightweight test harness for skill scripts
#
# Usage: source this file in test scripts, then call run_tests
#
# Example:
#   source "$(dirname "$0")/harness.sh"
#   test_something() { assert_eq "a" "a" "values match"; }
#   run_tests

set -euo pipefail

_PASS=0
_FAIL=0
_TMPDIRS=()
_ORIG_DIR="$(pwd)"
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../agents/skills" && pwd)"

# Clean up all temp dirs on exit
_cleanup_all() {
  cd "$_ORIG_DIR" 2>/dev/null || true
  for d in "${_TMPDIRS[@]+"${_TMPDIRS[@]}"}"; do
    [[ -d "$d" ]] && rm -rf "$d"
  done
}
trap _cleanup_all EXIT

# --- Assertions ---

assert_eq() {
  local actual="$1" expected="$2" msg="${3:-assert_eq}"
  if [[ "$actual" == "$expected" ]]; then
    _PASS=$((_PASS + 1))
  else
    _FAIL=$((_FAIL + 1))
    echo "    FAIL: ${msg}"
    echo "      expected: $(echo "$expected" | head -3)"
    echo "      actual:   $(echo "$actual" | head -3)"
  fi
}

assert_contains() {
  local haystack="$1" needle="$2" msg="${3:-assert_contains}"
  if echo "$haystack" | grep -qF -- "$needle"; then
    _PASS=$((_PASS + 1))
  else
    _FAIL=$((_FAIL + 1))
    echo "    FAIL: ${msg}"
    echo "      looking for: $needle"
    echo "      in: $(echo "$haystack" | head -5)"
  fi
}

assert_not_contains() {
  local haystack="$1" needle="$2" msg="${3:-assert_not_contains}"
  if ! echo "$haystack" | grep -qF -- "$needle"; then
    _PASS=$((_PASS + 1))
  else
    _FAIL=$((_FAIL + 1))
    echo "    FAIL: ${msg}"
    echo "      should not contain: $needle"
  fi
}

assert_match() {
  local actual="$1" pattern="$2" msg="${3:-assert_match}"
  if echo "$actual" | grep -qE "$pattern"; then
    _PASS=$((_PASS + 1))
  else
    _FAIL=$((_FAIL + 1))
    echo "    FAIL: ${msg}"
    echo "      pattern: $pattern"
    echo "      actual:  $(echo "$actual" | head -3)"
  fi
}

# --- Test helpers ---

# Create a temporary git repo for testing
make_test_repo() {
  local dir
  dir=$(mktemp -d "${TMPDIR:-/tmp}/skill-test-XXXXXX")
  _TMPDIRS+=("$dir")
  cd "$dir"
  git init -q
  git config user.email "test@test.com"
  git config user.name "Test"
  git commit -q --allow-empty -m "initial commit"
  echo "$dir"
}

# Create a bare "remote" repo and add it as origin
add_test_remote() {
  local name="${1:-origin}"
  local remote_dir
  remote_dir=$(mktemp -d "${TMPDIR:-/tmp}/skill-remote-XXXXXX")
  _TMPDIRS+=("$remote_dir")
  git init -q --bare "$remote_dir"
  git remote add "$name" "$remote_dir" 2>/dev/null || true
  git push -q "$name" HEAD:master 2>/dev/null || true
  echo "$remote_dir"
}

# Reset to original directory between tests
reset_dir() {
  cd "$_ORIG_DIR"
}

# Capture stdout+stderr and exit code of a command
capture() {
  local _capture_exit=0
  _CAPTURED=$("$@" 2>&1) || _capture_exit=$?
  _CAPTURED_EXIT=$_capture_exit
}

# --- Runner ---

run_tests() {
  local test_file="${BASH_SOURCE[1]:-}"
  local test_name
  test_name=$(basename "$test_file" .sh)

  echo "=== $test_name ==="

  # Find all functions starting with test_
  local tests
  tests=$(declare -F | awk '{print $3}' | grep '^test_' | sort)

  if [[ -z "$tests" ]]; then
    echo "  No tests found"
    return 1
  fi

  while IFS= read -r func; do
    echo "  $func"
    # Run directly (no subshell) so assertions update counts
    "$func" || true
    reset_dir
  done <<< "$tests"

  echo ""
  echo "  $(((_PASS + _FAIL))) assertions, ${_PASS} passed, ${_FAIL} failed"

  [[ $_FAIL -gt 0 ]] && return 1
  return 0
}
