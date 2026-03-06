#!/usr/bin/env bash
set -euo pipefail

# Test that all dynamic context commands in SKILL.md files execute successfully.
#
# Claude Code's skill loader runs !`command` expressions in a shell WITHOUT
# pipefail. A non-zero exit code from the LAST command in a pipeline breaks
# the skill loader. This test matches that behavior.
#
# Catches:
# - Commands where the last pipeline stage exits non-zero
# - Commands with syntax errors
# - Patterns that break the skill loader ($(), ||, &&)
#
# Usage: bash .github/skill-tests/test_dynamic_context.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILLS_DIR="$REPO_ROOT/agents/skills"

PASS=0
FAIL=0
SKIP=0
ERRORS=()

echo "Testing dynamic context commands..."
echo "  Skills dir: $SKILLS_DIR"
echo "  Repo root:  $REPO_ROOT"
echo ""

# Extract !`command` expressions from SKILL.md files, skipping fenced code blocks.
extract_commands() {
  local file="$1"
  awk '
    /^```/ { in_block = !in_block; next }
    !in_block {
      line = $0
      while (match(line, /!\x60[^\x60]+\x60/)) {
        cmd = substr(line, RSTART + 2, RLENGTH - 3)
        print cmd
        line = substr(line, RSTART + RLENGTH)
      }
    }
  ' "$file"
}

for skill_dir in "$SKILLS_DIR"/*/; do
  [ -d "$skill_dir" ] || continue
  skill_file="$skill_dir/SKILL.md"
  [ -f "$skill_file" ] || continue

  skill_name=$(basename "$skill_dir")

  while IFS= read -r cmd; do
    [ -z "$cmd" ] && continue

    # Skip commands that reference $ARGUMENTS or other runtime variables.
    if echo "$cmd" | grep -qE '\$[A-Z_]+'; then
      SKIP=$((SKIP + 1))
      continue
    fi

    # Run from repo root (matching Claude Code's behavior) WITHOUT pipefail.
    # The skill loader uses the pipeline's natural exit code (last command),
    # not pipefail semantics. We capture that exit code.
    exit_code=0
    output=$(cd "$REPO_ROOT" && bash -c "$cmd" 2>&1) || exit_code=$?

    if [ "$exit_code" -eq 0 ]; then
      PASS=$((PASS + 1))
    else
      FAIL=$((FAIL + 1))
      ERRORS+=("FAIL [$skill_name]: $cmd (exit $exit_code)")
      echo "  FAIL [$skill_name]: $cmd"
      echo "    exit=$exit_code output=$(echo "$output" | head -3)"
    fi
  done < <(extract_commands "$skill_file")
done

echo ""
echo "================================"
echo "Dynamic context commands: $((PASS + FAIL + SKIP)) total, ${PASS} passed, ${FAIL} failed, ${SKIP} skipped"

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "Failed commands:"
  for err in "${ERRORS[@]}"; do
    echo "  $err"
  done
  echo ""
  echo "Commands that exit non-zero break the skill loader."
  echo "Fix: pipe through '| head -N' to neutralize exit codes, or add 2>/dev/null."
  exit 1
fi

echo "All dynamic context commands passed."
