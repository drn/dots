# Change: Add batch-pr-review skill

## Why

Reviewing a set of related PRs (often listed in a chat thread, sometimes stacked) was done
ad hoc: fetch each PR, fan out reviewers, hand-build a summary page, and post reviews. The
workflow worked but nothing codified it, including the posting gotchas and the
review-quality practices (verified findings, delta review of stacks, severity taxonomy).

## What Changes

- Add `agents/skills/batch-pr-review/`: `SKILL.md`, `references/` (reviewer prompt, researched
  best practices with sources, artifact layout), `template.html`, and `scripts/parse-refs.sh`.
- The skill resolves a PR list from a Slack link, PR URLs, or repo plus numbers; detects stacks;
  fans out read-only reviewers; verifies findings with a skeptical second pass; checks
  consistency across PRs; publishes a private artifact with per-finding checkboxes; and posts
  COMMENT reviews only after explicit approval.
- Add `.github/skill-tests/test_batch_pr_review.sh` covering the ref parser.
- Update `README.md` skill count and table.

## Impact

- Affected specs: `batch-pr-review` (new capability)
- Affected code: `agents/skills/batch-pr-review/`, `.github/skill-tests/`, `README.md`
