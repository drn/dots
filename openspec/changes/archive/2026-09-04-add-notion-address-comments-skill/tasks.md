## 1. Skill

- [x] 1.1 Write `agents/skills/notion-address-comments/SKILL.md`
- [x] 1.2 Add cross-reference line in `agents/skills/notion/SKILL.md`

## 2. Docs

- [x] 2.1 Update `README.md` skill count

## 3. Validation

- [x] 3.1 `go install ./...`
- [x] 3.2 `revive -set_exit_status ./...`
- [x] 3.3 `go test ./...`
- [x] 3.4 `bash .github/skill-tests/run_all.sh`
- [x] 3.5 `bash .github/lint-skills.sh`
- [x] 3.6 `qlty check --all --no-fix --level=high`
- [x] 3.7 `qlty smells --all --no-snippets`

## 4. Archive

- [x] 4.1 `openspec archive add-notion-address-comments-skill --yes`
- [x] 4.2 `openspec validate --strict`
