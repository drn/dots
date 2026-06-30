# Tasks: Add dev-tool PATH hook

## 1. Hook script
- [x] 1.1 Add `agents/hooks/session-start-path.sh` that appends `export PATH="$dir:$PATH"` to `$CLAUDE_ENV_FILE` for `$GOBIN`/`~/go/bin`, `~/.cargo/bin`, `~/.asdf/shims`
- [x] 1.2 Skip dirs that don't exist; honor a custom `$GOBIN`/`$GOPATH`; order so `go/bin` is frontmost
- [x] 1.3 Make it idempotent across repeated SessionStart fires (no duplicate lines) and a no-op when `$CLAUDE_ENV_FILE` is unset

## 2. Installer registration
- [x] 2.1 Add `registerSessionStartPathHook()` in `cli/commands/install/agents.go` and call it from `Agents()`
- [x] 2.2 Reuse `registerSessionHook` so registration is deduped by inner command string and coexists with the memory hook

## 3. Tests
- [x] 3.1 Go tests: hook registered once, idempotent on re-run, coexists with memory hook, correct command shape (`cli/commands/install/agents_test.go`)
- [x] 3.2 Skill test: prepends existing dirs, skips missing cargo, go/bin frontmost after sourcing, idempotent, honors custom `$GOBIN`, no-op without env file (`.github/skill-tests/test_session_path.sh`)

## 4. Docs + validation
- [x] 4.1 Update `README.md` agents-component description to mention the SessionStart PATH hook
- [x] 4.2 `openspec validate add-dev-tool-path-hook --strict` passes

## 5. Archive within this PR
- [ ] 5.1 Merge the delta into `openspec/specs/agent-config-install/spec.md` and move the change to `openspec/changes/archive/<date>-add-dev-tool-path-hook/`
