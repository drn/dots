#!/usr/bin/env bash
# Claude Code status line — context usage, compaction proximity, and rate limits
set -euo pipefail
set -f  # disable glob expansion for safe JSON handling

input=$(cat)

# Guard: empty input
if [ -z "$input" ]; then
  printf "Claude"
  exit 0
fi

# ── Colors (24-bit true color) ──────────────────────────
green='\033[38;2;0;175;80m'
orange='\033[38;2;255;176;85m'
yellow='\033[38;2;230;200;0m'
red='\033[38;2;255;85;85m'
blue='\033[38;2;0;153;255m'
white='\033[38;2;220;220;220m'
dim='\033[2m'
reset='\033[0m'

sep=" ${dim}│${reset} "
default_context_size=200000

# ── Helpers ─────────────────────────────────────────────
format_tokens() {
  local num=$1
  if [ "$num" -ge 1000000 ] 2>/dev/null; then
    awk -v n="$num" 'BEGIN {printf "%.1fm", n / 1000000}'
  elif [ "$num" -ge 1000 ] 2>/dev/null; then
    awk -v n="$num" 'BEGIN {printf "%.0fk", n / 1000}'
  else
    printf "%d" "$num"
  fi
}

color_for_pct() {
  local pct=$1
  if [ "$pct" -ge 90 ] 2>/dev/null; then printf "%b" "$red"
  elif [ "$pct" -ge 70 ] 2>/dev/null; then printf "%b" "$yellow"
  elif [ "$pct" -ge 50 ] 2>/dev/null; then printf "%b" "$orange"
  else printf "%b" "$green"
  fi
}

build_bar() {
  local pct=$1 width=$2
  [ "$pct" -lt 0 ] 2>/dev/null && pct=0
  [ "$pct" -gt 100 ] 2>/dev/null && pct=100

  local filled=$(( pct * width / 100 ))
  local empty=$(( width - filled ))
  local bar_color
  bar_color=$(color_for_pct "$pct")

  local filled_str="" empty_str=""
  if [ "$filled" -gt 0 ]; then
    printf -v filled_str "%${filled}s"
    filled_str="${filled_str// /▓}"
  fi
  if [ "$empty" -gt 0 ]; then
    printf -v empty_str "%${empty}s"
    empty_str="${empty_str// /░}"
  fi

  printf "%b%s%b%s%b" "$bar_color" "$filled_str" "$dim" "$empty_str" "$reset"
}

# ── Extract data ────────────────────────────────────────
model=$(echo "$input" | jq -r '.model.display_name // "Claude"')

size=$(echo "$input" | jq -r ".context_window.context_window_size // $default_context_size")
[ "$size" -eq 0 ] 2>/dev/null && size=$default_context_size
input_tokens=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // 0')
cache_create=$(echo "$input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0')
cache_read=$(echo "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')
current=$(( input_tokens + cache_create + cache_read ))

raw_pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
pct=$(echo "$raw_pct" | cut -d. -f1)
pct=${pct//[^0-9]/}
pct=${pct:-0}
[ "$pct" -gt 100 ] 2>/dev/null && pct=100

remaining=$((100 - pct))

# ── Line 1: Model │ Context bar % │ Tokens │ Compaction ─
ctx_bar=$(build_bar "$pct" 10)
pct_color=$(color_for_pct "$pct")
used_fmt=$(format_tokens "$current")
total_fmt=$(format_tokens "$size")

line1="${blue}${model}${reset}"
line1+="${sep}"
line1+="${ctx_bar} ${pct_color}${pct}%${reset}"
line1+="${sep}"
line1+="${dim}${used_fmt}/${total_fmt}${reset}"
line1+="${sep}"
line1+="${white}${remaining}% until compaction${reset}"

# ── Line 2: Rate limits (if available) ──────────────────
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
seven_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

rate_line=""
if [ -n "$five_pct" ] && [ "$five_pct" != "null" ]; then
  five_int=$(echo "$five_pct" | cut -d. -f1)
  five_int=${five_int//[^0-9]/}
  five_int=${five_int:-0}
  five_bar=$(build_bar "$five_int" 8)
  five_color=$(color_for_pct "$five_int")
  rate_line+="${white}5h${reset} ${five_bar} ${five_color}${five_int}%${reset}"
fi

if [ -n "$seven_pct" ] && [ "$seven_pct" != "null" ]; then
  seven_int=$(echo "$seven_pct" | cut -d. -f1)
  seven_int=${seven_int//[^0-9]/}
  seven_int=${seven_int:-0}
  seven_bar=$(build_bar "$seven_int" 8)
  seven_color=$(color_for_pct "$seven_int")
  [ -n "$rate_line" ] && rate_line+="${sep}"
  rate_line+="${white}7d${reset} ${seven_bar} ${seven_color}${seven_int}%${reset}"
fi

# ── Output ──────────────────────────────────────────────
printf "%b" "$line1"
[ -n "$rate_line" ] && printf "\n%b" "$rate_line"

exit 0
