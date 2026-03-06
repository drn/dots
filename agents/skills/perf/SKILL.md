---
name: perf
description: Before/after performance benchmarking comparing current branch against base, with statistical analysis. Use for benchmarking, profiling, or measuring performance impact.
disable-model-invocation: true
allowed-tools: Bash(bash ~/.claude/skills/perf/scripts/perf.sh:*), Bash(bash agents/skills/perf/scripts/perf.sh:*)
---

# Performance Benchmark

Run a command multiple times on the current branch and the base branch, then compare with statistical analysis.

## Arguments

- `$ARGUMENTS` - Required: the command to benchmark (e.g., "go test -bench=. ./pkg/..." or "npm run build"). Optional: `--runs <count>` for number of runs (default 5), `--base <ref>` to override base branch.

## Context

- Current branch: !`git branch --show-current`
- Base ref: !`git branch -r 2>/dev/null | grep -oE 'origin/(main|master)' | head -1`
- Git status: !`git status --short`

## Your task

Run before/after benchmarks comparing the current branch against the base branch.

### Step 1: Parse arguments and run the benchmark script

Extract the benchmark command and optional flags (`--runs N`, `--base <ref>`) from `$ARGUMENTS`.

IF no command is provided, ask: "What command should I benchmark?"

Resolve the script path — use the first that exists:
1. `~/.claude/skills/perf/scripts/perf.sh` (deployed via symlink)
2. `agents/skills/perf/scripts/perf.sh` (repo-relative, for development/workspaces)

```
bash <script-path> "<command>" [--runs N] [--base <ref>]
```

Handle the exit code:

- **Exit 0** — Format the output as the report below and show it as your final response.
- **Exit 1** — Report the error from stderr.
- **Exit 2** — Report: "Benchmark command failed. Verify the command works: `<command>`"

### Step 2: Format the report

Parse the script's structured output and present it as:

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

If the script output includes a high-variance warning, append it after the verdict.
