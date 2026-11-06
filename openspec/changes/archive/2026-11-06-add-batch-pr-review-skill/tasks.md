## 1. Skill

- [x] 1.1 Write `agents/skills/batch-pr-review/SKILL.md`
- [x] 1.2 Write `references/REVIEWER-PROMPT.md`, `references/BEST-PRACTICES.md`, `references/ARTIFACT.md`
- [x] 1.3 Write `template.html` and `scripts/parse-refs.sh`
- [x] 1.4 Add `.github/skill-tests/test_batch_pr_review.sh`

## 2. Docs

- [x] 2.1 Update `README.md` skill count and table

## 3. Validation

- [x] 3.1 `go install ./...`
- [x] 3.2 `revive -set_exit_status ./...`
- [x] 3.3 `go test ./...`
- [x] 3.4 `bash .github/skill-tests/run_all.sh`
- [x] 3.5 `bash .github/lint-skills.sh`
- [x] 3.6 `qlty check --all --no-fix --level=high`
- [x] 3.7 `qlty smells --all --no-snippets`

## 4. Archive

- [x] 4.1 `openspec archive add-batch-pr-review-skill --yes`
- [x] 4.2 `openspec validate --strict`
