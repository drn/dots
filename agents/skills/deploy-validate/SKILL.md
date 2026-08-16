---
name: deploy-validate
description: Validate a deploy after it lands — CI status, rollout health, error tracking, and monitoring/alerting — correlating every finding against the deploy's start time to separate genuine regressions from pre-existing noise. Use when asked to validate a deploy, check post-deploy health, confirm a production rollout is healthy, or after a deploy finishes.
---

# Post-Deploy Health Validation

Validate that a deploy that has just landed is healthy: confirm it actually
shipped what was intended, then check CI, rollout, error tracking, and
monitoring — correlating every finding's timing against the deploy's start so
pre-existing issues are not mistaken for regressions.

Run this after the user confirms the deploy has finished (this skill does not
poll or wait for a deploy in progress).

## Arguments

- `$ARGUMENTS` - Optional: the deployed branch/tag/ref, and/or a deploy start
  timestamp. If omitted, detect the deployed ref the same way `deploy-audit`
  would and derive the start time from the deploy pipeline itself in Step 2.

## Context

- Remote: !`git remote get-url origin 2>/dev/null | head -1`
- Default branch: !`git branch -r 2>/dev/null | grep -oE 'origin/(main|master)' | head -1`
- Current HEAD: !`git rev-parse --short HEAD 2>/dev/null | head -1`
- Latest tag: !`git describe --tags --abbrev=0 2>/dev/null | head -1`

## Instructions

Work through the following steps in order — the timestamp correlation in
Step 4 is what makes this validation trustworthy rather than a generic
health-check dashboard.

### Step 1: Confirm the deploy landed

Determine the deployed ref (from `$ARGUMENTS` or by asking, mirroring
`deploy-audit`'s ref detection). Refs are treated as untrusted input for
shell purposes: if a ref contains characters outside `[A-Za-z0-9._/-]`, do
not interpolate it directly into a shell command — quote it and confirm with
the user first.

Fetch it and confirm it now points at the
commit/tag that was intended to ship — e.g. the deployed branch's SHA matches
the base branch's SHA at the time of the deploy, or a release tag was created
at the expected commit.

If the deployed ref does not match what was expected, stop and report this
first — nothing downstream matters if the wrong thing shipped.

### Step 2: Find the deploy pipeline and its start time

Use ToolSearch to find whatever CI/deploy tooling is available in this
project (search terms like "circleci", "github actions", "pipeline",
"deploy"). Find the pipeline/workflow run that performed this deploy and
record:

- Its status (success/failure/in-progress)
- Its start timestamp — this is the anchor for every correlation in later
  steps

If no CI tooling is discoverable, ask the user for the deploy start time
directly rather than guessing.

### Step 3: Check rollout health

Use ToolSearch for whatever deployment/orchestration platform the project
uses (e.g. terms like "ecs", "kubernetes", "k8s", "cloud run", "deployment").
For each service touched by the deploy, check:

- Running/healthy instance count matches desired count, with none pending
- The running image/version tag matches the new release

Query narrowly — one service at a time — rather than enumerating an entire
cluster in one call; a large cluster's full service list can exceed usable
output size. If a query risks returning a large amount of data, delegate the
enumeration to a subagent/fork and have it return only the summary.

### Step 4: Check error tracking, correlated by time

Use ToolSearch for whatever error-tracking tool is available (e.g. terms like
"sentry", "error tracking", "exception"). Query for issues first seen in a
window starting shortly before the deploy and continuing to now.

For every issue found, compare its first-seen timestamp against the deploy
start timestamp from Step 2:

- **First seen before deploy start** → pre-existing noise, not a regression,
  regardless of how alarming the error looks. Do not report it as caused by
  this deploy.
- **First seen at or after deploy start** → candidate regression. Investigate
  further (stack trace, affected endpoint/service) and include it in the
  report.

This timestamp correlation is the single most important step in this skill —
do not substitute keyword matching or severity alone for it.

### Step 5: Check monitoring and alerting, cross-checked against aggregates

Use ToolSearch for whatever monitoring/alerting tool is available (e.g. terms
like "datadog", "monitor", "alert", "metrics"). Find anything in an alerting
state for the affected service(s) since the deploy.

Before reporting an alert as a confirmed regression, cross-check it against
the underlying aggregate metric (e.g. error rate, latency) for the same
service and time window. A monitor tripping does not always mean a real
regression — percentile and anomaly-detection monitors can trip on a single
outlier. Only report it as a likely regression if the aggregate metric itself
shows a corresponding shift after the deploy start time; otherwise note the
discrepancy.

### Step 6: Re-verify flagged risks

If a prior `deploy-audit` pass flagged any new feature flags or config risks
for this deploy, re-check those specific items now that the deploy is live
(e.g. confirm a flag is still at its intended default). Skip this step if no
prior audit findings are available.

### Step 7: Report

Summarize:

```
## Deploy Validation Report

**Deployed ref:** <ref> (matches expected: yes/no)
**Deploy pipeline:** <status>, started <timestamp>

### Rollout
<per-service health>

### Error Tracking
- Pre-existing (filtered out): <count>
- Candidate regressions (first seen after deploy): <list with detail>

### Monitoring
- Alerts confirmed against aggregate metrics: <list>
- Alerts noted but not corroborated by aggregates: <list>

### Flags
<re-verified risk items, if any>

### Unverified categories
<any category skipped because no tooling was discoverable>

### Recommendation
<propose remediation only for genuine, deploy-caused findings; explicitly
state when the deploy looks healthy>
```

Do not propose remediation for anything classified as pre-existing noise.
