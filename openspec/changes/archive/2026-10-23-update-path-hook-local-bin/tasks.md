# Tasks: Add ~/.local/bin to the PATH hook

## 1. Hook + tests
- [x] 1.1 Prepend `~/.local/bin` in `agents/hooks/session-start-path.sh`, behind `go/bin`
- [x] 1.2 Extend `.github/skill-tests/test_session_path.sh` (present dir prepended, absent dir skipped, go/bin still frontmost)

## 2. Docs + validation
- [x] 2.1 Update the `agents` row in `README.md`
- [x] 2.2 `openspec validate update-path-hook-local-bin --strict` passes

## 3. Archive within this PR
- [x] 3.1 Merge the delta into `openspec/specs/agent-config-install/spec.md` and archive the change
