# Change: Manage scalar `~/.claude/settings.json` keys via `dots install agents`

## Why

Darren wants `cleanupPeriodDays` (local session transcript retention) set to
1095 days (3 years) and kept that way across machines, the same way `dots
install agents` already manages hooks and the status line. Today the
installer only knows how to mutate `settings.hooks` and `settings.statusLine`
— there's no primitive for a bare top-level scalar key, so this was set by
hand instead of through dots.

## What Changes

- Add a generic `ensureScalarSetting(key, value, successMsg)` helper to the
  `agents` installer, alongside the existing `mutateSettings` /
  `registerMatcherHook` / `registerSessionHook` helpers. It sets
  `settings[key] = value` when absent or different, and is a no-op when the
  value already matches (compared via JSON marshaling, so `1095` and
  `1095.0` are treated as equal).
- Use it to set `cleanupPeriodDays` to `1095` on every `dots install agents`
  run.

## Impact

- Affected specs: `agent-config-install`
- Affected code: `cli/commands/install/agents.go`,
  `cli/commands/install/agents_test.go`
