# Change: Remove skills redundant with argus built-ins

## Why

Argus now embeds its task-lifecycle skills in its binary and serves them in every argus
sandbox. `agents/skills/archive` and `agents/skills/complete` are identical copies of the
built-in `argus-archive` and `argus-complete` (differing only in the `name` and
cross-reference text), so each session lists two skills for one action.

## What Changes

- Remove `agents/skills/archive/` and `agents/skills/complete/`; use the built-in
  `argus-archive` and `argus-complete` instead.
- Remove `agents/skills/argus-schedule/` in favor of the built-in `argus-schedule`. The dots copy
  carried two fixes the built-in lacks (`.schedules[]` response shape, relative-time
  one-shots); port them upstream into argus.
- Update `README.md` skill count and skill table.

## Impact

- Affected specs: `agent-config-install`
- Affected code: `agents/skills/archive/`, `agents/skills/complete/`, `agents/skills/argus-schedule/`, `README.md`
