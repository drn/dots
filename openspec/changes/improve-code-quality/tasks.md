# Tasks: Improve code quality

## 1. Replace reflection-based installer dispatch
- [x] 1.1 Replace `reflect.ValueOf` dispatch in `cli/commands/install/root.go` with an explicit `map[string]func()` — removes runtime panics, enables IDE navigation, eliminates deprecated `strings.Title`
- [x] 1.2 Remove `strings.Title` import and replace with `golang.org/x/text/cases` or eliminate entirely via the map approach

## 2. Fix silent error swallowing
- [x] 2.1 Handle `os.Mkdir` error in `cli/commands/install/vim.go` — log warning on failure
- [x] 2.2 Handle `ioutil.ReadDir` errors in `home.go`, `fonts.go`, `vim.go` — log warning instead of discarding with `_`
- [x] 2.3 Handle `os.Remove` error in `cli/link/root.go` — log warning on failure
- [x] 2.4 Return error from `pkg/run.Capture()` instead of discarding the exec error
- [x] 2.5 Handle `ioutil.ReadFile` and `os.Create` errors in `pkg/cache/root.go`

## 3. Replace deprecated APIs
- [x] 3.1 Replace all `ioutil.ReadFile` → `os.ReadFile` across the codebase
- [x] 3.2 Replace all `ioutil.ReadDir` → `os.ReadDir` across the codebase
- [x] 3.3 Replace all `ioutil.WriteFile` → `os.WriteFile` if present
- [x] 3.4 Bump `go.mod` from `go 1.15` to `go 1.21` (minimum for `slog`, modern stdlib)

## 4. Improve error propagation
- [x] 4.1 Refactor `pkg/run` functions to return `error` instead of `bool`
- [x] 4.2 Update callers of `pkg/run` to handle returned errors
- [x] 4.3 Replace direct `os.Exit(1)` calls in library packages (`pkg/*`, `cli/*`) with error returns — keep `os.Exit` only in command handlers

## 5. Add unit tests
- [x] 5.1 Add tests for `pkg/cache` — TTL expiry, read/write roundtrip, missing cache file
- [x] 5.2 Add tests for `pkg/path` — `Dots()`, `FromDots()`, `Pretty()`, `Home()`
- [x] 5.3 Add tests for `cli/is` — `File()`, `Command()` with temp files
- [x] 5.4 Add tests for `cli/link` — `Soft()`, `Hard()` with temp directories

## 6. Strengthen CI
- [x] 6.1 Add `go vet ./...` step to GitHub Actions workflow
- [x] 6.2 Add `staticcheck` or `golangci-lint` step to catch deprecated API usage
- [x] 6.3 Add `go test ./...` step (once tests exist)

## 7. Minor improvements
- [x] 7.1 Make `pkg/cache.Write` atomic — write to temp file then rename
- [x] 7.2 Add `--verbose`/`--quiet` flags to root command for log level control
- [x] 7.3 Move hardcoded Spotify device IDs in `cmd/spotify/root.go` to environment variables
