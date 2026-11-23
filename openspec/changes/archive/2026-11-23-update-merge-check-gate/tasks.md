## 1. Implementation
- [x] 1.1 Add check-query helper that separates "no required checks" from "gh error"
- [x] 1.2 Fall back to all PR checks (excluding non-gating bots) when none are required
- [x] 1.3 Add grace period for checks that have not yet registered
- [x] 1.4 Block the --admin tier while any check is pending or failing
- [x] 1.5 Update merge and ship SKILL.md (Step 3, exit 5, Phase 5)

## 2. Tests
- [x] 2.1 Stubbed gh: no required checks, pending PR checks
- [x] 2.2 Stubbed gh: gh error
- [x] 2.3 Stubbed gh: no checks registered yet

## 3. Wrap-up
- [x] 3.1 Run the Pre-Completion Checklist
- [x] 3.2 Archive the change in the same PR
