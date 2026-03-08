#!/bin/bash
# PreToolUse hook: Block writes to sensitive files
# Exit 2 = block with feedback to Claude

if ! command -v jq >/dev/null 2>&1; then
  echo "Hook error: jq is required but not installed" >&2
  exit 2
fi

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

BASENAME=$(basename "$FILE_PATH")

# Protected file patterns
case "$BASENAME" in
  .env|.env.*)
    echo "Blocked: cannot write to environment file '$FILE_PATH'" >&2
    exit 2
    ;;
  *.pem|*.p12|*.pfx)
    echo "Blocked: cannot write to certificate file '$FILE_PATH'" >&2
    exit 2
    ;;
  id_rsa*|id_ed25519*|id_ecdsa*)
    echo "Blocked: cannot write to SSH key file '$FILE_PATH'" >&2
    exit 2
    ;;
esac

exit 0
