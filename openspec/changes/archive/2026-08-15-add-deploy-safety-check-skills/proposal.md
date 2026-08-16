# Change: Add deploy-audit and deploy-validate skills

## Why

Deploy safety checks — auditing pending commits before a production deploy and
validating system health after one lands — are currently done ad hoc, re-derived
from scratch in conversation every time. The two-phase process (risk audit,
then post-deploy correlation against deploy timing) is well-defined and
repeatable but exists nowhere as a reusable skill.

## What Changes

- Add `agents/skills/deploy-audit/SKILL.md`: audits commits pending between a
  base branch and a deployed branch/tag, assessing migration safety, config
  wiring completeness, feature-flag defaults, and schema parity, then opens
  the GitHub compare diff.
- Add `agents/skills/deploy-validate/SKILL.md`: after a deploy, checks CI
  status, rollout health, error tracking, and monitoring/alerting, correlating
  findings against deploy start time to separate genuine regressions from
  pre-existing noise.
- Both skills are tool-agnostic: they describe what to check, not which vendor
  API/MCP tool to call, and instruct Claude to discover whatever tooling
  (MCP servers or CLIs) is available in the current project.

## Impact

- Affected specs: `deploy-safety` (new capability)
- Affected code: `agents/skills/deploy-audit/`, `agents/skills/deploy-validate/`,
  `README.md` (skill table/count)
