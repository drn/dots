#!/bin/bash
# Lint Claude Code skill files for dynamic context patterns that are blocked
# by the permission system: ||, &&, $(), and pipes to unapproved commands
# inside !`command` expressions.
#
# Usage: .github/lint-skills.sh [directory...]
# Defaults to claude/commands/ and claude/skills/ if no args given.

set -euo pipefail

dirs=("${@:-claude/commands claude/skills}")
errors=0
warnings=0

# Pipe targets known to be approved by Claude Code's permission system.
# Commands not in this list will trigger a warning.
APPROVED_PIPE_TARGETS="head|tail|grep|wc|sort|uniq|cut|tr"

for dir in ${dirs[@]}; do
  [ -d "$dir" ] || continue

  for file in "$dir"/*.md "$dir"/*/*.md; do
    [ -f "$file" ] || continue

    # Extract dynamic context lines: lines containing !` (outside code blocks).
    # Use awk to skip triple-backtick fenced code blocks.
    while IFS= read -r match; do
      lineno="${match%%:*}"
      line="${match#*:}"

      # Check for || operator
      if echo "$line" | grep -q '||'; then
        echo "ERROR: $file:$lineno: || operator in dynamic context"
        echo "  $line"
        errors=$((errors + 1))
      fi

      # Check for && operator
      if echo "$line" | grep -q '&&'; then
        echo "ERROR: $file:$lineno: && operator in dynamic context"
        echo "  $line"
        errors=$((errors + 1))
      fi

      # Check for $() command substitution
      if echo "$line" | grep -qE '\$\('; then
        echo "ERROR: $file:$lineno: \$() command substitution in dynamic context"
        echo "  $line"
        errors=$((errors + 1))
      fi

      # Check for 2>/dev/null without a trailing pipe (exit code not neutralized).
      # When the command fails, 2>/dev/null suppresses stderr but the non-zero
      # exit code still breaks the skill loader. Piping through head/tail/etc
      # makes the pipeline exit 0 regardless.
      if echo "$line" | grep -qE '2>/dev/null\s*`'; then
        echo "WARNING: $file:$lineno: 2>/dev/null without pipe — non-zero exit code will break skill loading"
        echo "  Fix: add '| head -N' after 2>/dev/null to neutralize the exit code"
        echo "  $line"
        warnings=$((warnings + 1))
      fi

      # Check for pipes to unapproved commands
      if echo "$line" | grep -qE '\|[^|]'; then
        # Extract pipe targets (commands after |)
        pipe_targets=$(echo "$line" | grep -oE '\|\s*[a-z]+' | sed 's/|[[:space:]]*//' || true)
        for target in $pipe_targets; do
          if ! echo "$target" | grep -qE "^($APPROVED_PIPE_TARGETS)$"; then
            echo "WARNING: $file:$lineno: pipe to '$target' may be blocked by permission system"
            echo "  $line"
            warnings=$((warnings + 1))
          fi
        done
      fi

    done < <(awk '
      /^```/ { in_block = !in_block; next }
      !in_block && /!\x60/ { print NR ":" $0 }
    ' "$file")
  done
done

if [ "$errors" -gt 0 ]; then
  echo ""
  echo "Found $errors error(s) and $warnings warning(s)."
  echo "Dynamic context lines must not use ||, &&, or \$()."
  echo "See CLAUDE.md \"Dynamic Context Rules\" for details."
  exit 1
fi

if [ "$warnings" -gt 0 ]; then
  echo ""
  echo "Found $warnings warning(s). Pipes to unknown commands may be blocked."
  echo "Approved pipe targets: ${APPROVED_PIPE_TARGETS//|/, }"
fi

echo "Skill lint passed ($warnings warning(s))."
