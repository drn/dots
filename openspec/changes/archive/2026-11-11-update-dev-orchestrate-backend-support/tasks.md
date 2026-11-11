## 1. Implementation (approved)
- [x] 1.1 Refactor dev to select supported delegation or single-agent execution without requiring Teams.
- [x] 1.2 Refactor orchestrate to make Workflow/model tiering optional and preserve dependency ordering inline.
- [x] 1.3 Keep references and context collection portable across harnesses; update README descriptions.
- [x] 1.4 Add skill regression checks for capability routing, fallback, and contradictory mandatory instructions.

## 2. Verification and closeout
- [x] 2.1 Trace instruction scenarios for native delegation, no delegation, no model selection, and partial delegation failure; check their static contracts.
- [ ] 2.2 Obtain a passing full-repository qlty check after its Ruby provisioning dependencies are available (environment blocker below).
- [x] 2.3 Review the diff and test checks using the repository review methodology.
- [x] 2.4 Archive the approved change and merge its requirements into base specs before merge.

## Verification notes

- Build, revive, Go tests, all 13 skill test suites, and skill lint passed. Skill lint has four unrelated existing warnings.
- qlty fmt and fix checks reported no issues; smells and metrics completed with existing repository findings.
- Full qlty check was attempted but Ruby provisioning failed because Homebrew dependencies were unavailable and metadata lock writes were sandbox-denied. Retrying without Homebrew API refresh still reported a missing OpenSSL dependency. This is not a passing quality gate.
- Self-review used hera-review and its test-adversary lens. A stale optional briefing file still required team messaging/task APIs; it was rewritten and regression-checked. No unresolved implementation findings were identified.
- Tests validate instruction text and reject mutations that remove guards or restore legacy prerequisites. They do not prove that every model/harness will follow those instructions; no live multi-backend agent execution was performed.
