# Change: Add log-level control; reconcile shipped code-quality work

## Why
The original "improve code quality" proposal predates a series of cleanups that have
since shipped on `master`. Most of what it proposed is already done: the installer
registry is an explicit `[]Component` slice (no reflection), `ioutil` and
`strings.Title` are gone, `go.mod` targets Go 1.21, `pkg/cache`/`pkg/path`/`cli/is`/
`cli/link` all have unit tests, file-I/O errors are logged instead of discarded, and
CI runs `go vet` + `staticcheck` + `go test`. The only spec-worthy item never
implemented is runtime log-level control, so this change ships that and reconciles
the proposal with reality.

## What Changes
- Add persistent `--verbose`/`-v` and `--quiet`/`-q` flags to the root command for log-level control
- Add level gating to `pkg/log` (quiet = warnings/errors only; verbose additionally emits a new `Debug` logger)

### Already shipped (verified against current code — no longer part of this change)
- Explicit installer registry — `install.Components()` returns an ordered `[]Component`
  slice of direct function references, no reflection (already documented in
  `specs/cli-framework` as "Component Registry and Dispatch")
- `ioutil` → `os`/`io` everywhere; `strings.Title` removed; `go.mod` bumped to Go 1.21
- Unit tests for `pkg/cache`, `pkg/path`, `cli/is`, `cli/link`
- File-I/O errors logged rather than swallowed; atomic cache writes (`CreateTemp` + `Rename`);
  Spotify device IDs read from `SPOTIFY_DEVICE_*` env vars
- CI runs `go vet`, `staticcheck`, and `go test`

### Intentionally dropped
- "Return errors instead of `os.Exit()`" and "`Capture` returns an error" — these
  contradict the shipped, now-spec'd "Process-Exit Error Model" and "Command
  Execution Helpers" requirements in `specs/cli-framework`. They are a redesign, not
  unfinished work; revisit via a separate proposal if the team wants to flip that model.

## Impact
- Affected specs: cli-framework (ADDED: Log Level Control)
- Affected code: `cli/commands/root.go`, `pkg/log/root.go`
