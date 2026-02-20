# Change: Improve code quality, error handling, and testability

## Why
The codebase has no unit tests, silently swallows errors in file operations, uses deprecated APIs (`ioutil`, `strings.Title`), and dispatches installers via reflection — making it fragile, hard to debug in CI, and resistant to safe refactoring.

## What Changes
- Replace reflection-based installer dispatch with an explicit map
- Return errors from functions instead of calling `os.Exit()` inline
- Stop discarding errors from file I/O (`ioutil.ReadFile`, `os.Mkdir`, etc.)
- Replace deprecated `ioutil` with `os`/`io` equivalents
- Replace deprecated `strings.Title` with `cases.Title`
- Add unit tests for `pkg/cache`, `pkg/path`, `cli/is`, `cli/link`
- Bump `go.mod` to Go 1.21+ to access modern stdlib
- Add `go vet` and `staticcheck` to CI

## Impact
- Affected specs: cli-framework
- Affected code: `cli/commands/install/root.go`, `pkg/run/root.go`, `pkg/cache/root.go`, `cli/link/root.go`, `cli/commands/install/*.go`, `go.mod`, `.github/workflows/main.yml`
