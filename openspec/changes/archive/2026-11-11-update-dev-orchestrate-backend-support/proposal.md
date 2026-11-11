# Change: Make dev and orchestrate backend-neutral

## Why
The dev skill requires Claude Code experimental Teams and stops when they are unavailable.
The orchestrate skill assumes a Workflow tool and Claude-specific model names. These
requirements block other harnesses even though the development cycle can run in one session.

## What Changes
- Select execution mode from tools actually available and permitted by the current harness
  and project, not the model vendor, harness name, or an environment variable.
- Prefer supported native delegation when available; otherwise execute the same plan,
  implementation, testing, review, and bounded repair cycle sequentially in the current session.
- Remove the mandatory Claude Teams setup prompt and coordinator-only restrictions that
  prevent inline execution. Do not require users to enable experimental features.
- Treat Workflow and Claude model names as optional adapters, not universal prerequisites.
  Use configured/available model mappings where supported; retain the current model when
  model selection is unavailable.
- Preserve approval gates, file ownership, verification, bounded retries, and honest reporting.
  If delegation fails, inspect partial changes before continuing unfinished work inline.
- Use portable skill-relative references and explain how to collect context when the harness
  does not expand dynamic context.
- Update README descriptions and add regression checks for both skills.

## Impact
- Affected specs: development-workflows (new capability).
- Affected files: agents/skills/dev/SKILL.md, agents/skills/orchestrate/SKILL.md,
  optional extracted reference files, README.md, .github/skill-tests/.
- No new runtime dependencies, backend integrations, or automatic harness configuration.
- Implementation is pending proposal approval.
