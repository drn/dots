# Tasks: Improve code quality

## 1. Replace reflection-based installer dispatch
- [ ] 1.1 Replace `reflect.ValueOf` dispatch in `cli/commands/install/root.go` with an explicit `map[string]func(*Install)` — removes runtime panics, enables IDE navigation, eliminates deprecated `strings.Title`
- [ ] 1.2 Remove `strings.Title` import and replace with `golang.org/x/text/cases` or eliminate entirely via the map approach

## 2. Fix silent error swallowing
- [ ] 2.1 Handle `os.Mkdir` error in `cli/commands/install/vim.go:28` — log warning on failure
- [ ] 2.2 Handle `ioutil.ReadDir` errors in `home.go`, `fonts.go`, `bin.go`, `git.go` — log warning instead of discarding with `_`
- [ ] 2.3 Handle `os.Remove` error in `cli/link/root.go` — log warning on failure
- [ ] 2.4 Return error from `pkg/run.Capture()` instead of discarding the exec error
- [ ] 2.5 Handle `ioutil.ReadFile` and `os.Create` errors in `pkg/cache/root.go`

## 3. Replace deprecated APIs
- [ ] 3.1 Replace all `ioutil.ReadFile` → `os.ReadFile` across the codebase
- [ ] 3.2 Replace all `ioutil.ReadDir` → `os.ReadDir` across the codebase
- [ ] 3.3 Replace all `ioutil.WriteFile` → `os.WriteFile` if present
- [ ] 3.4 Bump `go.mod` from `go 1.15` to `go 1.21` (minimum for `slog`, modern stdlib)

## 4. Improve error propagation
- [ ] 4.1 Refactor `pkg/run` functions to return `(string, error)` instead of `bool`
- [ ] 4.2 Update callers of `pkg/run` to handle returned errors
- [ ] 4.3 Replace direct `os.Exit(1)` calls in library packages (`pkg/*`, `cli/*`) with error returns — keep `os.Exit` only in command handlers

## 5. Add unit tests
- [ ] 5.1 Add tests for `pkg/cache` — TTL expiry, read/write roundtrip, missing cache file
- [ ] 5.2 Add tests for `pkg/path` — `Dots()`, `FromDots()`, `Pretty()`, `Home()`
- [ ] 5.3 Add tests for `cli/is` — `File()`, `Command()` with temp files
- [ ] 5.4 Add tests for `cli/link` — `Soft()`, `Hard()` with temp directories

## 6. Strengthen CI
- [ ] 6.1 Add `go vet ./...` step to GitHub Actions workflow
- [ ] 6.2 Add `staticcheck` or `golangci-lint` step to catch deprecated API usage
- [ ] 6.3 Add `go test ./...` step (once tests exist)

## 7. Minor improvements
- [ ] 7.1 Make `pkg/cache.Write` atomic — write to temp file then rename
- [ ] 7.2 Add `--verbose`/`--quiet` flags to root command for log level control
- [ ] 7.3 Move hardcoded Spotify device IDs in `cmd/spotify/root.go` to environment variables
