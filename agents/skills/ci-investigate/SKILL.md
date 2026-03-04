---
name: ci-investigate
description: Investigate flaky CI failures across multiple workflow runs to identify patterns, categorize root causes, and propose fixes. Use when asked to investigate CI failures, find flaky tests, diagnose test flakiness, or understand why CI is failing repeatedly.
---

# CI Failure Investigator

Investigate flaky CI failures across multiple workflow runs to identify patterns, categorize root causes, and propose targeted fixes.

## Arguments

- `$ARGUMENTS` - Optional: job name filter, number of runs to check, or branch name. Examples: "test-core-rspec", "--runs 10", "master"

If no arguments are provided, investigate the most recent failing workflow on the current branch.

## Context

- Current branch: !`git branch --show-current`
- Repo remote: !`git remote get-url origin 2>/dev/null | head -1`
- CI config: !`find . -maxdepth 2 \( -name ".circleci" -o -name ".github" \) -type d 2>/dev/null | head -5`
- CircleCI config snippet: !`head -30 .circleci/config.yml 2>/dev/null | head -30`

## Instructions

Investigate CI failures by fetching multiple workflow runs, extracting test results, and categorizing failure patterns.

### Step 1: Determine Scope

Parse `$ARGUMENTS` for:
- **Job name filter** (e.g., "test-core-rspec") -- only analyze jobs matching this name
- **Run count** (e.g., "--runs 10") -- how many recent runs to check (default: 5, max: 15)
- **Branch** -- which branch to investigate (default: current branch from context above)

Derive the project slug from the git remote URL. For GitHub repos, format is "gh/org/repo".

Report the scope to the user before proceeding:
- Project slug
- Branch
- Job filter (if any)
- Number of runs to fetch

### Step 2: Fetch Recent Workflow Runs

Detect the CI provider from the context above and use the appropriate tools.

**CircleCI** (if .circleci/ exists):
Use ToolSearch to find available CircleCI MCP tools (search "circleci"). Then:
1. Fetch recent pipelines for the project slug and branch
2. For each pipeline, get its workflows
3. For each workflow, get jobs and their statuses
4. Filter to failed jobs (and optionally by job name from Step 1)

**GitHub Actions** (if .github/workflows/ exists):
Use the gh CLI:
1. `gh run list --branch {branch} --limit {N}` to get recent runs
2. `gh run view {run_id}` to get job details
3. `gh run view {run_id} --log-failed` to get failure output

Collect up to the target number of failed runs. If a workflow has no failures, skip it but note it as a passing run (useful for calculating flake rate).

Track:
- Total workflow runs examined
- Number with failures vs passing
- Which specific jobs failed in each run

### Step 3: Extract Failure Details

For each failed job found in Step 2:

**CircleCI:**
1. Fetch test results for the failed job (with artifacts and logs if the MCP tools support it)
2. If 0 test failures but non-zero exit code, fetch raw job logs. Flag as **infrastructure failure**.

**GitHub Actions:**
1. Use `gh run view {run_id} --log-failed` to get failure output
2. Parse test framework output (JUnit XML, RSpec, Jest, etc.) for structured results

For each failure, extract:
- Test file path
- Test name
- Error message and stack trace
- Node/container number (for parallel test splitting issues)

Use parallel Task tool calls to fetch test results for multiple jobs simultaneously when possible.

### Step 4: Categorize Failures

Group failures by test file + test name. For each group, classify the root cause:

| Category | Signals | Common Fix |
|----------|---------|------------|
| **Deterministic** | Fails every run, same error | Fix the test or code -- this is a real bug |
| **Timing flake** | Intermittent, error involves time comparison, values differ by milliseconds | Freeze time in tests, use tolerance matchers |
| **Parallel collision** | Hard-coded IDs, PK violations, "Duplicate entry" | Use sequences/auto-increment, avoid hard-coded IDs |
| **Test isolation** | Order-dependent failures, shared mutable state between tests | Reset state between tests, avoid global side effects |
| **Infrastructure** | 0 test failures + exit code 1, OOM killed, container timeout | Retry or investigate resource limits |
| **External dependency** | Timeout connecting to external service, API errors | Add retry logic or stub external calls in tests |

If a failure does not clearly fit one category, mark it as **Unclassified** and include the full error for manual review.

### Step 5: Report Findings

Present the findings in this format:

```
## CI Investigation Report

**Scope:** {project} / {branch} / {job filter or "all jobs"}
**Runs analyzed:** {N} ({pass_count} passed, {fail_count} failed)
**Overall flake rate:** {fail_count/N * 100}%

### Failure Groups (by frequency)

#### 1. {test_file}:{test_name} -- {category}
- **Frequency:** {X}/{N} runs ({percentage}%)
- **Error:** {1-2 line error summary}
- **Affected nodes:** {node numbers if relevant}
- **Root cause:** {explanation}
- **Proposed fix:**
  {specific code change or strategy}

#### 2. ...

### Infrastructure Failures
{List any jobs that failed with 0 test failures}

### Cross-Repo Issues
{Flag any fixes needed in shared gems (Nucleus, etc.) or CI configuration}

### Recommended Priority
1. {highest frequency flake} -- affects X% of runs
2. ...
```

### Step 6: Offer Next Steps

After presenting the report, ask the user if they want to:
1. **Fix a specific flake** -- implement the proposed fix for a chosen failure group
2. **Investigate deeper** -- fetch more runs or drill into a specific failure
3. **Export the report** -- save findings to a file for reference
