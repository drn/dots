# Tasks: Add log-level control; reconcile shipped work

## 1. Log level control (the genuinely-remaining work)
- [x] 1.1 Add a `Level` type, `SetLevel`/`GetLevel`, and per-function level gating to `pkg/log`
- [x] 1.2 Add a `Debug` logger emitted only at the verbose level
- [x] 1.3 Add persistent `--verbose`/`--quiet` flags to the root command via `PersistentPreRun` (quiet wins on conflict)
- [x] 1.4 Add unit tests for level gating in `pkg/log`

## 2. Reconcile the proposal with shipped reality
- [x] 2.1 Rewrite `proposal.md` Why/What — stop claiming reflection/ioutil/no-tests; list what already shipped
- [x] 2.2 Reduce the `cli-framework` delta to the one new requirement (Log Level Control); drop requirements already present in the base spec
- [x] 2.3 Drop the error-model items ("return errors instead of os.Exit", "Capture returns error") that conflict with the backfilled base spec
- [x] 2.4 `openspec validate improve-code-quality --strict` passes

## 3. Archive within this PR
- [x] 3.1 Merge the delta into `openspec/specs/cli-framework/spec.md` and move the change to `openspec/changes/archive/`

## Verified already shipped on master (no action needed)
- [x] Explicit installer registry (`[]Component` slice, no reflection)
- [x] `ioutil` → `os`/`io`; `strings.Title` removed; `go.mod` → Go 1.21
- [x] Unit tests for `pkg/cache`, `pkg/path`, `cli/is`, `cli/link`
- [x] File-I/O errors logged not swallowed; atomic cache writes; Spotify device IDs via env
- [x] CI runs `go vet`, `staticcheck`, `go test`
