#!/bin/bash
# SessionStart hook (compact): Re-inject critical context after compaction
# Stdout from this hook is added as system context

if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

# Check for project-level context file
CWD=$(cat | jq -r '.cwd // empty')
if [ -n "$CWD" ]; then
  CONTEXT_FILE="$CWD/.claude/compact-context.md"
  if [ -f "$CONTEXT_FILE" ]; then
    cat "$CONTEXT_FILE"
    exit 0
  fi
fi

# Fallback: inject user-level context
USER_CONTEXT="$HOME/.claude/compact-context.md"
if [ -f "$USER_CONTEXT" ]; then
  cat "$USER_CONTEXT"
fi

exit 0
