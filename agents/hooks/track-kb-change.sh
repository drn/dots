#!/usr/bin/env bash
# Hook: PostToolUse — logs Argus kb_ingest writes to JSONL so /dream can
# triage incrementally instead of re-scanning the whole vault.
# Receives JSON on stdin from Claude Code with tool_name and tool_input.path.
set -euo pipefail

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Match both current (mcp__argus__) and legacy (mcp__argus-kb__) names.
case "$TOOL" in
  mcp__argus__kb_ingest|mcp__argus-kb__kb_ingest) ;;
  *) exit 0 ;;
esac

KB_PATH=$(echo "$INPUT" | jq -r '.tool_input.path // empty')
[ -n "$KB_PATH" ] || exit 0

SESSION=$(echo "$INPUT" | jq -r '.session_id // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

mkdir -p ~/.dots/sys/kb-changes
jq -nc --arg ts "$TS" --arg path "$KB_PATH" --arg session_id "$SESSION" --arg cwd "$CWD" \
  '{ts:$ts,path:$path,session_id:$session_id,cwd:$cwd}' \
  >> ~/.dots/sys/kb-changes/changes.jsonl
