#!/bin/bash
# Lint Claude Code skill files for dynamic context patterns that are blocked
# by the permission system: ||, &&, $(), and pipes to unapproved commands
# inside !`command` expressions.
#
# Usage: .github/lint-skills.sh [directory...]
# Defaults to agents/skills/ if no args given.

set -euo pipefail

dirs=("${@:-agents/skills}")
errors=0
warnings=0

# Pipe targets known to be approved by Claude Code's permission system.
# Commands not in this list will trigger a warning.
APPROVED_PIPE_TARGETS="head|tail|grep|wc|sort|uniq|cut|tr"

# Git subcommands known to be auto-approved by Claude Code's permission
# system. When a dynamic context line pipes a git command (making it
# "multiple operations"), the permission system checks each side of the
# pipe independently. Git subcommands NOT in this list will be flagged.
APPROVED_GIT_SUBCMDS="status|branch|log|diff|rev-parse|remote|show|ls-files|tag|stash|config|shortlog|describe"

for dir in ${dirs[@]}; do
  [ -d "$dir" ] || continue

  # --- Agent Skills spec checks on SKILL.md files ---
  for skill_dir in "$dir"/*/; do
    [ -d "$skill_dir" ] || continue
    skill_file="$skill_dir/SKILL.md"
    [ -f "$skill_file" ] || continue
    dir_name=$(basename "$skill_dir")

    # Check name matches directory
    fm_name=$(awk '/^---/{n++; next} n==1 && /^name:/{print $2; exit}' "$skill_file")
    if [ -n "$fm_name" ] && [ "$fm_name" != "$dir_name" ]; then
      echo "ERROR: $skill_file: name '$fm_name' does not match directory '$dir_name'"
      errors=$((errors + 1))
    fi

    # Check description includes "when to use" guidance.
    # Handles single-line, quoted, and multiline (> or |) YAML descriptions.
    fm_desc=$(awk '
      /^---/ { n++; next }
      n==1 && /^description:/ {
        sub(/^description: */, "")
        if ($0 ~ /^[>|]$/) { ml=1; next }  # multiline indicator
        gsub(/^"/, ""); gsub(/"$/, "")
        print; exit
      }
      n==1 && ml && /^  / { sub(/^ +/, ""); buf = buf " " $0; next }
      n==1 && ml { print buf; exit }
    ' "$skill_file")
    if [ -n "$fm_desc" ]; then
      if ! echo "$fm_desc" | grep -qiE 'Use (when|for|to) '; then
        echo "WARNING: $skill_file: description lacks 'Use when/for/to' guidance for discoverability"
        warnings=$((warnings + 1))
      fi
    fi

    # Check SKILL.md line count (spec recommends <500)
    line_count=$(wc -l < "$skill_file")
    if [ "$line_count" -gt 500 ]; then
      echo "WARNING: $skill_file: $line_count lines exceeds 500-line recommendation — extract to references/"
      warnings=$((warnings + 1))
    fi
  done

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

      # Check for origin/HEAD in dynamic context — doesn't exist in many repos.
      # Use git branch -r | grep or provide both origin/main and origin/master variants.
      if echo "$line" | grep -q 'origin/HEAD'; then
        echo "ERROR: $file:$lineno: origin/HEAD in dynamic context — doesn't exist in repos without 'git clone'"
        echo "  Fix: use 'git branch -r | grep -oE origin/(main|master) | head -1', or provide both origin/main and origin/master variants"
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

      # Check for pipes to unapproved commands.
      # Strip single-quoted strings first to avoid matching | inside regex args
      # (e.g., grep -oE 'origin/(main|master)' has a literal |, not a pipe).
      stripped_line=$(echo "$line" | sed "s/'[^']*'//g")
      if echo "$stripped_line" | grep -qE '\|[^|]'; then
        # Extract pipe targets (commands after |)
        pipe_targets=$(echo "$stripped_line" | grep -oE '\|\s*[a-z]+' | sed 's/|[[:space:]]*//' || true)
        for target in $pipe_targets; do
          if ! echo "$target" | grep -qE "^($APPROVED_PIPE_TARGETS)$"; then
            echo "WARNING: $file:$lineno: pipe to '$target' may be blocked by permission system"
            echo "  $line"
            warnings=$((warnings + 1))
          fi
        done
      fi

      # Check for git subcommands that aren't auto-approved.
      # Pipes make Claude Code treat the command as "multiple operations"
      # and check each side independently. Unapproved git subcommands on
      # the source side will block skill loading even if the pipe target
      # (e.g. head) is approved.
      # Skip lines with || or && — those are already caught as separate errors.
      if echo "$stripped_line" | grep -qE '\|[^|]' && ! echo "$stripped_line" | grep -q '||'; then
        git_subcmd=$(echo "$line" | grep -oE 'git [a-z-]+' | head -1 | awk '{print $2}' || true)
        if [ -n "$git_subcmd" ]; then
          if ! echo "$git_subcmd" | grep -qE "^($APPROVED_GIT_SUBCMDS)$"; then
            echo "ERROR: $file:$lineno: 'git $git_subcmd' in pipe is not auto-approved — will block skill loading"
            echo "  Pipes trigger multi-operation detection. 'git $git_subcmd' requires separate approval."
            echo "  Fix: use an approved git subcommand (approved: ${APPROVED_GIT_SUBCMDS//|/, })"
            echo "  $line"
            errors=$((errors + 1))
          fi
        fi
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
  echo "Dynamic context lines must not use ||, &&, \$(), or unapproved git subcommands in pipes."
  echo "See CLAUDE.md \"Dynamic Context Rules\" for details."
  exit 1
fi

if [ "$warnings" -gt 0 ]; then
  echo ""
  echo "Found $warnings warning(s). Pipes to unknown commands may be blocked."
  echo "Approved pipe targets: ${APPROVED_PIPE_TARGETS//|/, }"
fi

echo "Skill lint passed ($warnings warning(s))."
