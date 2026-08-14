## 1. Implementation

- [x] 1.1 Add `ensureScalarSetting(key string, value any, successMsg string)` to `cli/commands/install/agents.go`, built on `mutateSettings`, comparing existing vs. target value via `json.Marshal` equality
- [x] 1.2 Add `registerCleanupPeriod()` calling `ensureScalarSetting("cleanupPeriodDays", 1095, ...)` and call it from `Agents()`
- [x] 1.3 Add unit tests in `cli/commands/install/agents_test.go`: sets when absent, overwrites when different, no-op (no write) when already matching
- [x] 1.4 Run `go install ./...`, `revive`, `go test ./...`, `qlty check --fix --level=low`, `qlty smells --all --no-snippets`
