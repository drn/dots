#!/usr/bin/env bash
set -euo pipefail

# perf.sh — Before/after performance benchmarking with statistical analysis
#
# Usage: perf.sh "<command>" [--runs N] [--base <ref>]
#
# Exit codes:
#   0 — success (results printed)
#   1 — general failure
#   2 — benchmark command failed

# --- Globals ---
COMMAND=""
RUNS=5
BASE_REF=""
BRANCH=""
WORKTREE_PATH=".perf-base"

# --- Helpers ---

die() {
  local code="$1"; shift
  echo "Error: $*" >&2
  exit "$code"
}

info() {
  echo ":: $*" >&2
}

cleanup_worktree() {
  if [[ -d "$WORKTREE_PATH" ]]; then
    info "Cleaning up worktree..."
    git worktree remove "$WORKTREE_PATH" --force 2>/dev/null || true
  fi
}

# Compute stats from a space-separated list of numbers
# Usage: compute_stats "1.23 1.45 1.30 1.28 1.35"
# Outputs: min max mean median stddev (space-separated)
compute_stats() {
  local values="$1"
  awk -v vals="$values" 'BEGIN {
    n = split(vals, a, " ")
    if (n == 0) { print "0 0 0 0 0"; exit }

    # Sort (insertion sort)
    for (i = 2; i <= n; i++) {
      key = a[i]
      j = i - 1
      while (j > 0 && a[j] > key) {
        a[j+1] = a[j]
        j--
      }
      a[j+1] = key
    }

    min = a[1]
    max = a[n]

    sum = 0
    for (i = 1; i <= n; i++) sum += a[i]
    mean = sum / n

    if (n % 2 == 1)
      median = a[int(n/2) + 1]
    else
      median = (a[n/2] + a[n/2 + 1]) / 2

    sumsq = 0
    for (i = 1; i <= n; i++) sumsq += (a[i] - mean)^2
    stddev = sqrt(sumsq / n)

    printf "%.3f %.3f %.3f %.3f %.3f\n", min, max, mean, median, stddev
  }'
}

# Run a command and return the wall-clock time in seconds
time_command() {
  local cmd="$1" dir="${2:-.}"
  local output
  output=$( cd "$dir" && /usr/bin/time -p sh -c "$cmd" 2>&1 >/dev/null ) || true
  echo "$output" | grep '^real' | awk '{print $2}'
}

# Run benchmarks: warmup + N measured runs
# Usage: run_benchmarks "<command>" "<directory>" <N>
# Returns: space-separated times
run_benchmarks() {
  local cmd="$1" dir="$2" n="$3"
  local times=""

  # Warmup
  info "  Warmup run..."
  time_command "$cmd" "$dir" >/dev/null

  # Measured runs
  for i in $(seq 1 "$n"); do
    info "  Run $i/$n..."
    local t
    t=$(time_command "$cmd" "$dir")
    if [[ -z "$t" ]]; then
      die 2 "Benchmark command produced no timing output on run $i"
    fi
    if [[ -z "$times" ]]; then
      times="$t"
    else
      times="$times $t"
    fi
  done

  echo "$times"
}

# --- Main ---

parse_args() {
  COMMAND="${1:?Usage: perf.sh \"<command>\" [--runs N] [--base <ref>]}"
  shift

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --runs) RUNS="$2"; shift 2 ;;
      --base) BASE_REF="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  BRANCH=$(git branch --show-current)
  [[ -z "$BRANCH" ]] && die 1 "Detached HEAD — cannot benchmark"

  # Default base ref
  if [[ -z "$BASE_REF" ]]; then
    BASE_REF=$(git rev-parse --abbrev-ref origin/HEAD 2>/dev/null || echo "")
    [[ -z "$BASE_REF" || "$BASE_REF" == "origin/HEAD" ]] && die 1 "Could not determine base branch. Use --base <ref>."
  fi
}

main() {
  parse_args "$@"

  # Ensure clean state
  if [[ -n $(git status --short) ]]; then
    die 1 "Uncommitted changes detected. Commit or stash before benchmarking."
  fi

  trap cleanup_worktree EXIT

  info "Benchmark: $COMMAND"
  info "Runs: $RUNS (+ 1 warmup)"
  info "Current: $BRANCH"
  info "Base: $BASE_REF"
  echo ""

  # Benchmark current branch
  info "Benchmarking current branch ($BRANCH)..."
  local current_times
  current_times=$(run_benchmarks "$COMMAND" "." "$RUNS")

  # Set up base worktree
  info "Setting up base worktree ($BASE_REF)..."
  cleanup_worktree
  git worktree add "$WORKTREE_PATH" "$BASE_REF" 2>/dev/null \
    || die 1 "Failed to create worktree for $BASE_REF"

  # Benchmark base branch
  info "Benchmarking base ($BASE_REF)..."
  local base_times
  base_times=$(run_benchmarks "$COMMAND" "$WORKTREE_PATH" "$RUNS")

  # Clean up worktree
  cleanup_worktree
  trap - EXIT

  # Compute statistics
  local current_stats base_stats
  current_stats=$(compute_stats "$current_times")
  base_stats=$(compute_stats "$base_times")

  local c_min c_max c_mean c_median c_stddev
  read -r c_min c_max c_mean c_median c_stddev <<< "$current_stats"

  local b_min b_max b_mean b_median b_stddev
  read -r b_min b_max b_mean b_median b_stddev <<< "$base_stats"

  # Compute delta and percentage change
  local delta pct verdict
  delta=$(awk "BEGIN { printf \"%.3f\", $c_mean - $b_mean }")
  pct=$(awk "BEGIN { if ($b_mean == 0) print \"N/A\"; else printf \"%.1f\", (($c_mean - $b_mean) / $b_mean) * 100 }")

  if awk "BEGIN { exit !($c_mean > $b_mean * 1.05) }"; then
    verdict="REGRESSION"
  elif awk "BEGIN { exit !($c_mean < $b_mean * 0.95) }"; then
    verdict="IMPROVEMENT"
  else
    verdict="NEUTRAL"
  fi

  # Check for high variance
  local high_variance=""
  if awk "BEGIN { exit !($c_stddev > $c_mean * 0.20) }" 2>/dev/null; then
    high_variance="true"
  elif awk "BEGIN { exit !($b_stddev > $b_mean * 0.20) }" 2>/dev/null; then
    high_variance="true"
  fi

  # Print structured results
  echo ""
  echo "--- PERF RESULT ---"
  echo "command:  $COMMAND"
  echo "runs:     $RUNS (+ 1 warmup)"
  echo "base:     $BASE_REF"
  echo "current:  $BRANCH"
  echo ""
  echo "STATS:"
  echo "  metric    base       current    delta"
  echo "  min       ${b_min}s    ${c_min}s    $(awk "BEGIN { printf \"%.3f\", $c_min - $b_min }")s"
  echo "  max       ${b_max}s    ${c_max}s    $(awk "BEGIN { printf \"%.3f\", $c_max - $b_max }")s"
  echo "  mean      ${b_mean}s    ${c_mean}s    ${delta}s"
  echo "  median    ${b_median}s    ${c_median}s    $(awk "BEGIN { printf \"%.3f\", $c_median - $b_median }")s"
  echo "  stddev    ${b_stddev}s    ${c_stddev}s"
  echo ""
  echo "RAW:"
  echo "  base:     $base_times"
  echo "  current:  $current_times"
  echo ""
  echo "change:   ${pct}%"
  echo "verdict:  $verdict"
  [[ -n "$high_variance" ]] && echo "warning:  High variance detected — results may not be reliable. Consider increasing runs with --runs 10."
  echo "--- END ---"
}

main "$@"
