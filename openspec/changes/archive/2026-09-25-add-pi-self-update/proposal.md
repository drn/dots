# Change: Update pi.dev during `dots update`

## Why

`dots install pi` only installs `pi` when it's missing (`which pi` short-circuits the
installer) and is never called by `dots update`. Once installed, pi.dev's own binary never
gets refreshed by dots — the user has to remember to run `pi update` by hand. Every other
managed tool (Claude Code, Devbox, Homebrew, solargraph, asdf shims) is kept current by
`dots update`; pi.dev should be too.

## What Changes

- Add `updatePi()` to `cli/commands/update/root.go`, following the same
  skip-if-not-installed pattern as `updateClaude`/`updateDevbox`: log and skip when `pi` is
  not resolvable on `PATH`, otherwise run `pi update` (self-update only, matching the
  existing narrow scope of each per-tool update step).
- Call `updatePi()` from `Run()`'s update sequence.

## Impact

- Affected specs: `config-update`
- Affected code: `cli/commands/update/root.go`
