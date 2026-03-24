#!/usr/bin/env bash
# Hook: PreToolUse for Skill tool — logs skill invocations to JSONL.
# Receives JSON on stdin from Claude Code with tool_input.skill.
set -euo pipefail

INPUT=$(cat)
SKILL=$(echo "$INPUT" | jq -r '.tool_input.skill // empty')
[ -n "$SKILL" ] || exit 0

SESSION=$(echo "$INPUT" | jq -r '.session_id // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

mkdir -p ~/.dots/sys
echo "{\"ts\":\"$TS\",\"skill\":\"$SKILL\",\"session_id\":\"$SESSION\",\"cwd\":\"$CWD\"}" >> ~/.dots/sys/skill-usage.jsonl
