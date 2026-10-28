## 1. Implementation

- [x] 1.1 Add `updatePi()` to `cli/commands/update/root.go`: skip with an informational log when `which pi` fails, otherwise run `pi update` via `run.Verbose`
- [x] 1.2 Call `updatePi()` from `Run()`'s update sequence, alongside `updateClaude()`/`updateDevbox()`
- [x] 1.3 Update `README.md`'s `pi` component description if it documents install-only behavior (not needed — `dots update`'s per-tool steps aren't enumerated in README)
- [x] 1.4 Run `go install ./...`, `revive -set_exit_status ./...`, `go test ./...`, `bash .github/skill-tests/run_all.sh`, `bash .github/lint-skills.sh`, `qlty check --all --no-fix --level=high`, `qlty smells --all --no-snippets`
