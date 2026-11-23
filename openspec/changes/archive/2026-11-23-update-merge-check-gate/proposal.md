## Why

The /merge skill gated on GitHub-required checks only. On a repo with no required checks configured, or when the gh query errors, the gate counted zero checks and passed. The REVIEW_REQUIRED tier then merged with --admin while CI was still pending, violating repos that require every check to pass before merging.

## What Changes

- When no required checks are configured, the gate falls back to every check on the PR and waits on pending, failing, and cancelled ones.
- A gh error while reading checks is distinguished from "none configured" and no longer reads as zero.
- A short grace period covers the race right after PR creation, before any check has registered.
- Known non-gating bots (for example CodeRabbit) are ignored by the fallback.
- The --admin tier never runs while any PR check is pending or failing, unless --no-wait-checks was passed.
- SKILL.md for merge and ship document the new behavior.

## Impact

- Affected specs: merge-safety (new)
- Affected code: agents/skills/merge/scripts/merge.sh, agents/skills/merge/SKILL.md, agents/skills/ship/SKILL.md, .github/skill-tests/test_merge.sh
