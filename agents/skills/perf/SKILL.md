---
name: perf
description: Before/after performance benchmarking comparing current branch against base, with statistical analysis
disable-model-invocation: true
---

# Performance Benchmark

Run a command multiple times on the current branch and the base branch, then compare with statistical analysis.

## Arguments

- `$ARGUMENTS` - Required: the command to benchmark (e.g., "go test -bench=. ./pkg/..." or "npm run build"). Optional: `-n <count>` for number of runs (default 5), `--base <ref>` to override base branch.

## Context

- Current branch: !`git branch --show-current`
- Base branch: !`git rev-parse --abbrev-ref origin/HEAD 2>/dev/null | head -1`
- Git status: !`git status --short`

## Instructions

### Step 0: Validate state

- IF `git status --short` shows uncommitted changes, stop: "Uncommitted changes detected. Commit or stash before benchmarking — the base comparison requires a clean working tree."
- Parse `$ARGUMENTS` for:
  - **Command:** the benchmark command to run
  - **N:** number of runs (default 5, parse from `-n <count>`)
  - **Base:** base ref for comparison (default: the base branch from context, override with `--base <ref>`)

IF no command is provided, ask: "What command should I benchmark?"

### Step 1: Benchmark current branch

Report: "Benchmarking current branch (<branch>): <command> x <N> runs"

Run 1 warmup execution (discard the result — accounts for caching, compilation, etc.).

Then run the command N times, capturing wall-clock time for each run using:

```
/usr/bin/time -p <command>
```

Record the `real` time from each run. Store results as an array.

### Step 2: Set up base comparison

Create a worktree for the base branch:

```
git worktree add .perf-base <base-ref>
```

Change to the worktree directory for the base runs.

### Step 3: Benchmark base branch

Report: "Benchmarking base (<base-ref>): <command> x <N> runs"

Run 1 warmup execution (discard), then N measured runs in the worktree directory. Record `real` time for each.

### Step 4: Clean up worktree

Remove the worktree:

```
git worktree remove .perf-base --force
```

IF cleanup fails, report the issue but continue to Step 5 with the data collected.

### Step 5: Analyze results

Compute for each branch:
- **Min** — fastest run
- **Max** — slowest run
- **Mean** — average
- **Median** — middle value
- **Stddev** — standard deviation

Compute the comparison:
- **Delta:** mean(current) - mean(base)
- **Change:** percentage change from base
- **Verdict:**
  - Regression: >5% slower
  - Improvement: >5% faster
  - Neutral: within 5%

### Step 6: Report

```markdown
## Benchmark Results

**Command:** `<command>`
**Runs:** <N> (+ 1 warmup)

### Timing

| Metric | Base (<ref>) | Current (<branch>) | Delta |
|--------|-------------|-------------------|-------|
| Min | <X>s | <Y>s | <diff> |
| Max | <X>s | <Y>s | <diff> |
| Mean | <X>s | <Y>s | <diff> |
| Median | <X>s | <Y>s | <diff> |
| Stddev | <X>s | <Y>s | — |

### Raw Data

**Base:** <comma-separated times>
**Current:** <comma-separated times>

### Verdict: <REGRESSION / IMPROVEMENT / NEUTRAL>

<1-2 sentence explanation>
```

IF the stddev is high relative to the mean (>20%), add a warning: "High variance detected — results may not be reliable. Consider increasing the number of runs with `-n 10`."
