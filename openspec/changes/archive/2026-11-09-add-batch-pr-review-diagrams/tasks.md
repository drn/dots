## 1. Skill

- [x] 1.1 Extend reviewer prompt output with flow, reading_order, test_confidence
- [x] 1.2 Update SKILL.md steps for file impact, dependency graph, and diagrams
- [x] 1.3 Update ARTIFACT.md and template.html
- [x] 1.4 Add best-practices section 13

## 2. Validation

- [x] 2.1 `go install ./...`
- [x] 2.2 `revive -set_exit_status ./...`
- [x] 2.3 `go test ./...`
- [x] 2.4 `bash .github/skill-tests/run_all.sh`
- [x] 2.5 `bash .github/lint-skills.sh`
- [x] 2.6 `qlty check --all --no-fix --level=high`
- [x] 2.7 `qlty smells --all --no-snippets`

## 3. Archive

- [x] 3.1 `openspec archive add-batch-pr-review-diagrams --yes`
