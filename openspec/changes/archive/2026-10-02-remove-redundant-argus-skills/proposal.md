# Change: Remove skills redundant with argus built-ins

## Why

Argus now embeds its task-lifecycle skills in its binary and serves them in every argus
sandbox. `agents/skills/archive` and `agents/skills/complete` are identical copies of the
built-in `argus-archive` and `argus-complete` (differing only in the `name` and
cross-reference text), so each session lists two skills for one action.

## What Changes

- Remove `agents/skills/archive/` and `agents/skills/complete/`; use the built-in
  `argus-archive` and `argus-complete` instead.
- Keep `agents/skills/argus-schedule/`: the dots copy carries fixes the built-in lacks
  (`.schedules[]` response shape, relative-time one-shots), so removing it would regress
  guidance. Revisit once those fixes land upstream.
- Update `README.md` skill count and skill table.

## Impact

- Affected specs: `agent-config-install`
- Affected code: `agents/skills/archive/`, `agents/skills/complete/`, `README.md`
