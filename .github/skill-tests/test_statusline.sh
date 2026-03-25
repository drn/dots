#!/usr/bin/env bash
source "$(dirname "$0")/harness.sh"

STATUSLINE="$(cd "$(dirname "$0")/../../agents/hooks" && pwd)/statusline.sh"

# Helper: run statusline with given fields, strip ANSI codes
run_statusline() {
  local pct="$1"
  local model="${2:-Claude}"
  local json
  json=$(jq -nc --arg pct "$pct" --arg model "$model" '{
    model: {display_name: $model},
    context_window: {
      used_percentage: ($pct | tonumber),
      context_window_size: 200000,
      current_usage: {input_tokens: 50000, cache_creation_input_tokens: 0, cache_read_input_tokens: 0}
    }
  }')
  echo "$json" | bash "$STATUSLINE" 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g'
}

test_empty_input() {
  local out
  out=$(echo "" | bash "$STATUSLINE" 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g')
  assert_eq "$out" "Claude" "empty input should return Claude"
}

test_zero_percent() {
  local out
  out=$(run_statusline 0)
  assert_contains "$out" "0%" "should show 0%"
  assert_contains "$out" "100% until compaction" "should show 100% remaining"
  assert_contains "$out" "░░░░░░░░░░" "bar should be all empty"
}

test_fifty_percent() {
  local out
  out=$(run_statusline 50)
  assert_contains "$out" "50%" "should show 50%"
  assert_contains "$out" "50% until compaction" "should show 50% remaining"
  assert_contains "$out" "▓▓▓▓▓░░░░░" "bar should be half filled"
}

test_hundred_percent() {
  local out
  out=$(run_statusline 100)
  assert_contains "$out" "100%" "should show 100%"
  assert_contains "$out" "0% until compaction" "should show 0% remaining"
  assert_contains "$out" "▓▓▓▓▓▓▓▓▓▓" "bar should be all filled"
}

test_decimal_truncation() {
  local out
  out=$(run_statusline 75.8)
  assert_contains "$out" "75%" "should truncate decimal to 75%"
  assert_contains "$out" "25% until compaction" "remaining should be 25%"
}

test_model_name_display() {
  local out
  out=$(run_statusline 50 "Opus 4.6")
  assert_contains "$out" "Opus 4.6" "should display model name"
}

test_clamp_over_100() {
  local out
  out=$(run_statusline 150)
  assert_contains "$out" "100%" "should clamp to 100%"
  assert_contains "$out" "0% until compaction" "remaining should be 0%"
}

test_token_display() {
  local out
  out=$(run_statusline 25)
  assert_contains "$out" "50k/200k" "should show human-readable token counts"
}

test_missing_fields_fallback() {
  local out
  out=$(echo '{}' | bash "$STATUSLINE" 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g')
  assert_contains "$out" "Claude" "should fall back to Claude model name"
  assert_contains "$out" "0%" "should default to 0%"
}

test_color_green_under_50() {
  local raw
  raw=$(jq -nc '{model:{display_name:"Claude"},context_window:{used_percentage:30,context_window_size:200000,current_usage:{input_tokens:0,cache_creation_input_tokens:0,cache_read_input_tokens:0}}}' | bash "$STATUSLINE" 2>/dev/null)
  assert_contains "$raw" $'\033[38;2;0;175;80m' "should use green at 30%"
}

test_color_yellow_at_70() {
  local raw
  raw=$(jq -nc '{model:{display_name:"Claude"},context_window:{used_percentage:75,context_window_size:200000,current_usage:{input_tokens:0,cache_creation_input_tokens:0,cache_read_input_tokens:0}}}' | bash "$STATUSLINE" 2>/dev/null)
  assert_contains "$raw" $'\033[38;2;230;200;0m' "should use yellow at 75%"
}

test_color_red_at_90() {
  local raw
  raw=$(jq -nc '{model:{display_name:"Claude"},context_window:{used_percentage:95,context_window_size:200000,current_usage:{input_tokens:0,cache_creation_input_tokens:0,cache_read_input_tokens:0}}}' | bash "$STATUSLINE" 2>/dev/null)
  assert_contains "$raw" $'\033[38;2;255;85;85m' "should use red at 95%"
}

test_rate_limits_displayed() {
  local json out
  json=$(jq -nc '{
    model:{display_name:"Claude"},
    context_window:{used_percentage:50,context_window_size:200000,current_usage:{input_tokens:0,cache_creation_input_tokens:0,cache_read_input_tokens:0}},
    rate_limits:{five_hour:{used_percentage:25},seven_day:{used_percentage:10}}
  }')
  out=$(echo "$json" | bash "$STATUSLINE" 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g')
  assert_contains "$out" "5h" "should show 5h rate limit"
  assert_contains "$out" "7d" "should show 7d rate limit"
  assert_contains "$out" "25%" "should show 5h percentage"
  assert_contains "$out" "10%" "should show 7d percentage"
}

test_separators_present() {
  local raw
  raw=$(run_statusline 50)
  assert_contains "$raw" "│" "should have dim pipe separators"
}

run_tests
