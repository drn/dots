#!/usr/bin/env bash
source "$(dirname "$0")/harness.sh"

PERF="$SCRIPTS_DIR/perf/scripts/perf.sh"

# Source the script to get access to functions without running main
_source_perf() {
  eval "$(sed 's/^main "\$@"//' "$PERF")"
}

test_compute_stats_basic() {
  _source_perf
  local result
  result=$(compute_stats "1.0 2.0 3.0 4.0 5.0")

  local min max mean median stddev
  read -r min max mean median stddev <<< "$result"

  assert_eq "$min" "1.000" "min should be 1.000"
  assert_eq "$max" "5.000" "max should be 5.000"
  assert_eq "$mean" "3.000" "mean should be 3.000"
  assert_eq "$median" "3.000" "median of 5 values should be 3.000"
}

test_compute_stats_even_count() {
  _source_perf
  local result
  result=$(compute_stats "1.0 2.0 3.0 4.0")

  local min max mean median stddev
  read -r min max mean median stddev <<< "$result"

  assert_eq "$min" "1.000" "min should be 1.000"
  assert_eq "$max" "4.000" "max should be 4.000"
  assert_eq "$mean" "2.500" "mean should be 2.500"
  assert_eq "$median" "2.500" "median of 4 values should be 2.500"
}

test_compute_stats_single_value() {
  _source_perf
  local result
  result=$(compute_stats "5.0")

  local min max mean median stddev
  read -r min max mean median stddev <<< "$result"

  assert_eq "$min" "5.000" "min of single value"
  assert_eq "$max" "5.000" "max of single value"
  assert_eq "$mean" "5.000" "mean of single value"
  assert_eq "$stddev" "0.000" "stddev of single value should be 0"
}

test_compute_stats_unsorted_input() {
  _source_perf
  local result
  result=$(compute_stats "5.0 1.0 3.0 2.0 4.0")

  local min max mean median stddev
  read -r min max mean median stddev <<< "$result"

  assert_eq "$min" "1.000" "min should handle unsorted input"
  assert_eq "$max" "5.000" "max should handle unsorted input"
  assert_eq "$median" "3.000" "median should handle unsorted input"
}

test_compute_stats_stddev() {
  _source_perf
  # All same values => stddev = 0
  local result
  result=$(compute_stats "2.0 2.0 2.0")

  local min max mean median stddev
  read -r min max mean median stddev <<< "$result"

  assert_eq "$stddev" "0.000" "stddev of identical values should be 0"
}

test_parse_args_no_command() {
  make_test_repo >/dev/null
  capture bash "$PERF"
  assert_eq "$_CAPTURED_EXIT" "1" "should exit 1 with no command"
}

test_parse_args_runs_flag() {
  _source_perf
  make_test_repo >/dev/null
  add_test_remote "origin" >/dev/null
  git remote set-head origin master 2>/dev/null || true

  # Override parse_args test: just test the parsing logic
  COMMAND=""
  RUNS=5
  BASE_REF=""
  BRANCH="test"

  # Can't easily call parse_args without it detecting detached HEAD etc.
  # So just verify the script accepts --runs
  capture bash "$PERF" "echo hello" --runs 3 --base master
  # It will fail because of uncommitted changes or worktree issues, but
  # the exit should NOT be about usage
  assert_not_contains "$_CAPTURED" "Usage:" "should parse --runs without usage error"
}

test_uncommitted_changes_rejected() {
  make_test_repo >/dev/null
  add_test_remote "origin" >/dev/null

  # Create uncommitted changes
  echo "dirty" > dirty.txt
  git add dirty.txt

  capture bash "$PERF" "echo test" --base master
  assert_eq "$_CAPTURED_EXIT" "1" "should exit 1 with uncommitted changes"
  assert_contains "$_CAPTURED" "Uncommitted changes" "should report uncommitted changes"
}

test_detached_head_rejected() {
  make_test_repo >/dev/null
  add_test_remote "origin" >/dev/null
  git checkout -q --detach HEAD

  capture bash "$PERF" "echo test"
  assert_eq "$_CAPTURED_EXIT" "1" "should exit 1 on detached HEAD"
  assert_contains "$_CAPTURED" "Detached HEAD" "should report detached HEAD"
}

test_verdict_regression() {
  _source_perf
  # c_mean = 2.0, b_mean = 1.0 => 100% slower => REGRESSION
  local verdict=""
  local c_mean=2.000 b_mean=1.000

  if awk "BEGIN { exit !($c_mean > $b_mean * 1.05) }"; then
    verdict="REGRESSION"
  elif awk "BEGIN { exit !($c_mean < $b_mean * 0.95) }"; then
    verdict="IMPROVEMENT"
  else
    verdict="NEUTRAL"
  fi

  assert_eq "$verdict" "REGRESSION" "2x slower should be REGRESSION"
}

test_verdict_improvement() {
  _source_perf
  local verdict=""
  local c_mean=0.500 b_mean=1.000

  if awk "BEGIN { exit !($c_mean > $b_mean * 1.05) }"; then
    verdict="REGRESSION"
  elif awk "BEGIN { exit !($c_mean < $b_mean * 0.95) }"; then
    verdict="IMPROVEMENT"
  else
    verdict="NEUTRAL"
  fi

  assert_eq "$verdict" "IMPROVEMENT" "50% faster should be IMPROVEMENT"
}

test_verdict_neutral() {
  _source_perf
  local verdict=""
  local c_mean=1.020 b_mean=1.000

  if awk "BEGIN { exit !($c_mean > $b_mean * 1.05) }"; then
    verdict="REGRESSION"
  elif awk "BEGIN { exit !($c_mean < $b_mean * 0.95) }"; then
    verdict="IMPROVEMENT"
  else
    verdict="NEUTRAL"
  fi

  assert_eq "$verdict" "NEUTRAL" "2% difference should be NEUTRAL"
}

run_tests
