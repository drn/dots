#!/bin/bash
# Tests for lint-skills.sh — exercises both PASS and FAIL paths.
# Run: .github/lint-skills-test.sh

set -euo pipefail

LINTER=".github/lint-skills.sh"
PASS=0
FAIL=0
dir=$(mktemp -d)
trap "rm -rf $dir" EXIT

assert_pass() {
  local name="$1" content="$2"
  echo "$content" > "$dir/test.md"
  if $LINTER "$dir" > /dev/null 2>&1; then
    PASS=$((PASS + 1))
  else
    echo "FAIL: expected PASS: $name"
    FAIL=$((FAIL + 1))
  fi
}

assert_error() {
  local name="$1" content="$2"
  echo "$content" > "$dir/test.md"
  if $LINTER "$dir" > /dev/null 2>&1; then
    echo "FAIL: expected ERROR: $name"
    FAIL=$((FAIL + 1))
  else
    PASS=$((PASS + 1))
  fi
}

assert_error_count() {
  local name="$1" content="$2" expected="$3"
  echo "$content" > "$dir/test.md"
  local output
  output=$($LINTER "$dir" 2>&1 || true)
  local actual
  actual=$(echo "$output" | grep -c '^ERROR:' || true)
  if [ "$actual" -eq "$expected" ]; then
    PASS=$((PASS + 1))
  else
    echo "FAIL: $name — expected $expected error(s), got $actual"
    echo "  Output: $output"
    FAIL=$((FAIL + 1))
  fi
}

# --- Approved git subcommands pass ---
assert_pass "git rev-parse in pipe" \
  '!`git rev-parse --abbrev-ref origin/HEAD 2>/dev/null | head -1`'

assert_pass "git log in pipe" \
  '!`git log --oneline -5 2>/dev/null | head -10`'

assert_pass "git diff in pipe" \
  '!`git diff --stat HEAD...origin/HEAD 2>/dev/null | head -50`'

assert_pass "git branch in pipe" \
  '!`git branch --show-current 2>/dev/null | head -1`'

assert_pass "git status (no pipe)" \
  '!`git status --short`'

# --- Unapproved git subcommands error ---
assert_error "git symbolic-ref in pipe" \
  '!`git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | head -1`'

assert_error "git fetch in pipe" \
  '!`git fetch origin 2>/dev/null | head -1`'

assert_error "git checkout in pipe" \
  '!`git checkout main 2>/dev/null | head -1`'

# --- Non-git piped lines pass the git check ---
assert_pass "ls piped to head (no git)" \
  '!`ls -1 go.mod Gemfile 2>/dev/null | head -5`'

assert_pass "find piped to head (no git)" \
  '!`find . -name "*.go" 2>/dev/null | head -10`'

# --- || lines produce exactly 1 error (not double) ---
assert_error_count "|| with git symbolic-ref — single error only" \
  '!`git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null || echo none`' \
  1

# --- Other operator checks still work ---
assert_error "&& operator" \
  '!`git log 2>/dev/null && echo done | head -1`'

assert_error '$(  ) substitution' \
  '!`echo $(git branch) | head -1`'

# --- Code blocks are excluded ---
assert_pass "git symbolic-ref inside code block" \
  '```
!`git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | head -1`
```'

assert_warning_count() {
  local name="$1" expected="$2"
  # Runs the linter on $dir (already populated by caller) and counts WARNINGs
  local output
  output=$($LINTER "$dir" 2>&1 || true)
  local actual
  actual=$(echo "$output" | grep -c '^WARNING:' || true)
  if [ "$actual" -eq "$expected" ]; then
    PASS=$((PASS + 1))
  else
    echo "FAIL: $name — expected $expected warning(s), got $actual"
    echo "  Output: $output"
    FAIL=$((FAIL + 1))
  fi
}

# --- Agent Skills spec checks ---

# name/directory mismatch
spec_dir=$(mktemp -d)
trap "rm -rf $dir $spec_dir" EXIT
mkdir -p "$spec_dir/my-skill"
cat > "$spec_dir/my-skill/SKILL.md" << 'HEREDOC'
---
name: wrong-name
description: Test skill. Use when testing.
---
# Test
HEREDOC
output=$($LINTER "$spec_dir" 2>&1 || true)
if echo "$output" | grep -q "does not match directory"; then
  PASS=$((PASS + 1))
else
  echo "FAIL: name/directory mismatch not detected"
  FAIL=$((FAIL + 1))
fi

# description missing "Use when/for/to" triggers warning
mkdir -p "$spec_dir/good-skill"
cat > "$spec_dir/good-skill/SKILL.md" << 'HEREDOC'
---
name: good-skill
description: Does something. Use when you need it.
---
# Good
HEREDOC
mkdir -p "$spec_dir/bad-desc"
cat > "$spec_dir/bad-desc/SKILL.md" << 'HEREDOC'
---
name: bad-desc
description: Does something without guidance.
---
# Bad
HEREDOC
output=$($LINTER "$spec_dir" 2>&1 || true)
if echo "$output" | grep -q "bad-desc.*lacks.*Use when"; then
  PASS=$((PASS + 1))
else
  echo "FAIL: missing 'Use when' warning not detected for bad-desc"
  echo "  Output: $output"
  FAIL=$((FAIL + 1))
fi
if echo "$output" | grep -q "good-skill.*lacks"; then
  echo "FAIL: false positive 'Use when' warning for good-skill"
  FAIL=$((FAIL + 1))
else
  PASS=$((PASS + 1))
fi

# line count >500 triggers warning
mkdir -p "$spec_dir/long-skill"
{ echo '---'; echo 'name: long-skill'; echo 'description: Long skill. Use for testing.'; echo '---'; seq 1 501; } > "$spec_dir/long-skill/SKILL.md"
output=$($LINTER "$spec_dir" 2>&1 || true)
if echo "$output" | grep -q "long-skill.*exceeds 500"; then
  PASS=$((PASS + 1))
else
  echo "FAIL: line count >500 warning not detected"
  echo "  Output: $output"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
