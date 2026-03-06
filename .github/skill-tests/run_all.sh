#!/usr/bin/env bash
set -euo pipefail

# Run all skill script tests
#
# Usage: bash .github/skill-tests/run_all.sh

DIR="$(cd "$(dirname "$0")" && pwd)"
PASS=0
FAIL=0

echo "Running skill script tests..."
echo ""

for test_file in "$DIR"/test_*.sh; do
  if bash "$test_file"; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
  fi
  echo ""
done

echo "================================"
echo "Suites: $((PASS + FAIL)) total, ${PASS} passed, ${FAIL} failed"

[[ $FAIL -gt 0 ]] && exit 1
exit 0
