#!/bin/bash
# PostToolUse hook: Auto-format files after Write/Edit
# Runs the appropriate formatter based on file extension

if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

case "$FILE_PATH" in
  *.go)
    command -v gofmt >/dev/null 2>&1 && gofmt -w "$FILE_PATH" 2>/dev/null
    ;;
  *.js|*.jsx|*.ts|*.tsx|*.css|*.scss|*.json|*.yaml|*.yml)
    # Only run prettier if installed locally in the project
    PROJECT_DIR=$(git -C "$(dirname "$FILE_PATH")" rev-parse --show-toplevel 2>/dev/null)
    if [ -n "$PROJECT_DIR" ] && [ -f "$PROJECT_DIR/node_modules/.bin/prettier" ]; then
      "$PROJECT_DIR/node_modules/.bin/prettier" --write "$FILE_PATH" 2>/dev/null
    fi
    ;;
  *.rb)
    # Only run rubocop if configured in the project (safe autocorrect only)
    PROJECT_DIR=$(git -C "$(dirname "$FILE_PATH")" rev-parse --show-toplevel 2>/dev/null)
    if [ -n "$PROJECT_DIR" ] && [ -f "$PROJECT_DIR/.rubocop.yml" ]; then
      command -v rubocop >/dev/null 2>&1 && rubocop -a --force-exclusion "$FILE_PATH" 2>/dev/null
    fi
    ;;
  *.py)
    command -v ruff >/dev/null 2>&1 && ruff format "$FILE_PATH" 2>/dev/null
    ;;
esac

exit 0
