# deploy-safety Specification

## Purpose

The `deploy-safety` capability defines two reusable skills for auditing deploy
risk before a production deploy ships and validating system health after it
lands: `deploy-audit` and `deploy-validate`. Both are tool-agnostic — they
describe what to check, and rely on Claude discovering whatever MCP
tools/CLIs are available in the current project to perform each check.

## Requirements

### Requirement: Pre-Deploy Risk Audit Skill

The repository SHALL provide a `deploy-audit` skill that, given a base branch
(default `master`/`main`) and a deployed branch or tag (default detected from
common deploy-branch names or asked of the user), enumerates every commit
pending between them and produces a per-change risk assessment before the
user opens a PR or ships a deploy.

The audit SHALL cover, for each pending commit or the diff as a whole:
- Database migration safety (additive vs. destructive, backfill requirements)
- Schema parity across any mirrored/generated schema copies the project
  maintains
- Configuration/secret wiring completeness — for any new environment variable
  or secret, tracing that it is threaded through every layer of the project's
  config chain (e.g. IaC variable definitions through to the running
  task/service config), not just that the secret exists in a vault
- Feature-flag defaults for any newly introduced flags
- The full commit log and diff stat between the two refs

The skill SHALL open the GitHub compare diff for the two refs in the browser,
deriving the org/repo from `git remote get-url origin` rather than a
hardcoded value.

The skill SHALL be tool-agnostic: it SHALL describe each check as a category
of risk to investigate, and instruct Claude to use whatever MCP tools, CLIs,
or file inspection are available in the current project to perform it, rather
than hardcoding a specific vendor's tool names.

#### Scenario: Auditing pending commits before a deploy

- **WHEN** a user invokes `deploy-audit` in a git repository with a base and
  deployed branch/tag
- **THEN** Claude lists every pending commit and file changed between the two
  refs, assesses migration/config/flag/schema risk, and opens the GitHub
  compare diff link for the user to review

#### Scenario: No tooling available for a risk category

- **WHEN** a risk category (e.g. feature-flag defaults) has no discoverable
  MCP tool or CLI in the current project
- **THEN** the skill SHALL note that category as skipped/unverified rather
  than silently omitting it from the summary

### Requirement: Post-Deploy Health Validation Skill

The repository SHALL provide a `deploy-validate` skill that, after a deploy
has landed, checks CI status, deployment/rollout health, error tracking, and
monitoring/alerting for the deployed service(s), and correlates any findings
against the deploy's start timestamp to distinguish genuine regressions from
pre-existing noise.

The skill SHALL:
- Confirm the deployed ref matches what was intended to ship
- Check CI/deploy pipeline status for the deploy
- Check rollout health (e.g. running vs. desired task/instance counts, image
  version match) for whatever deployment platform the project uses
- Query error tracking for issues first seen after the deploy's start time,
  treating anything first seen before that time as pre-existing noise
- Cross-check any alerting/monitor state against the underlying aggregate
  metrics for the same service/window before treating an alert as a real
  regression
- Re-verify feature-flag defaults for anything flagged as a risk during the
  corresponding `deploy-audit` pass, if available
- Be tool-agnostic in the same manner as `deploy-audit`, discovering available
  MCP tools/CLIs rather than assuming a specific vendor stack
- Default to narrow, per-service/per-window queries rather than broad
  enumerations, to avoid unbounded tool output

#### Scenario: Validating a deploy that introduced no regressions

- **WHEN** a user invokes `deploy-validate` after a deploy has finished
- **THEN** Claude checks CI, rollout, error tracking, and monitoring, and
  reports the deploy healthy when every discovered issue's first-seen
  timestamp predates the deploy start

#### Scenario: Distinguishing a real regression from pre-existing noise

- **WHEN** an error-tracking issue's first-seen timestamp is after the
  deploy's start timestamp
- **THEN** the skill SHALL flag it as a candidate regression rather than
  filtering it out as noise

#### Scenario: Monitor alert without a corresponding metric anomaly

- **WHEN** a monitor/alert is in an alerting state but the underlying
  aggregate metric for the same service/window shows no corresponding
  anomaly
- **THEN** the skill SHALL note the discrepancy rather than reporting the
  alert as a confirmed regression
