## 1. Skills

- [x] 1.1 Write `agents/skills/deploy-audit/SKILL.md`
- [x] 1.2 Write `agents/skills/deploy-validate/SKILL.md`

## 2. Docs

- [x] 2.1 Update `README.md` skill table and count

## 3. Validation

- [x] 3.1 `go install ./...`
- [x] 3.2 `revive -set_exit_status ./...`
- [x] 3.3 `go test ./...`
- [x] 3.4 `bash .github/skill-tests/run_all.sh`
- [x] 3.5 `bash .github/lint-skills.sh`
- [x] 3.6 `qlty check --all --no-fix --level=high`
- [x] 3.7 `qlty smells --all --no-snippets`

## 4. Archive

- [x] 4.1 `openspec archive add-deploy-safety-check-skills --skip-specs --yes` (base spec created by hand — see commit)
- [x] 4.2 `openspec validate --strict`
