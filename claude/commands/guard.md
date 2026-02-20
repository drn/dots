---
description: Pre-commit safety check for secrets, security antipatterns, and test breakage
---

# Pre-commit Guard

Fast safety check before committing. Scans for secrets, security antipatterns, test breakage, and lint issues. Binary pass/fail output.

## Arguments

- `$ARGUMENTS` - Optional: `--strict` for zero-tolerance mode (warnings also fail)

## Context

- Staged files: !`git diff --cached --name-only`
- Unstaged changes: !`git diff --name-only`
- Project type: !`ls -1 go.mod Gemfile package.json Cargo.toml pyproject.toml 2>/dev/null | head -3`

## Instructions

Run these checks against all staged files (or all changed files if nothing is staged). Be fast -- this is a pre-commit gate, not a full review.

### Check 0: Gitignore Violations

Scan staged/changed files for common files that should not be committed:

- `.env`, `.env.*` files (environment/secrets)
- `node_modules/` contents
- Build artifacts (`dist/`, `build/`, `*.o`, `*.pyc`, `__pycache__/`)
- IDE files (`.idea/`, `.vscode/settings.json`)
- OS files (`.DS_Store`, `Thumbs.db`)
- Log files (`*.log`)
- Credential files (`credentials.json`, `*.pem`, `*.key`)

**Report:** WARNING if any found (FAIL in --strict mode).

### Check 1: Secrets Detection

Scan staged/changed files for:

- API keys, tokens, passwords (patterns: `password\s*=`, `api_key`, `secret`, `token\s*=`, `Bearer `)
- AWS credentials (`AKIA`, `aws_secret_access_key`)
- Private keys (`-----BEGIN.*PRIVATE KEY-----`)
- Connection strings with embedded credentials
- `.env` files being committed
- Hardcoded URLs with credentials (`https://user:pass@`)

**Report:** FAIL if any found, with file and line number.

### Check 2: Security Antipatterns

Scan for common dangerous patterns:

- `eval()` or `exec()` with variable input
- SQL string concatenation (instead of parameterized queries)
- `dangerouslySetInnerHTML` or equivalent
- Disabled SSL verification (`verify: false`, `VERIFY_NONE`)
- Overly permissive CORS (`Access-Control-Allow-Origin: *`)
- `chmod 777` or world-readable permissions
- `--no-verify` or security bypass flags in code

**Report:** FAIL if any found.

### Check 3: Test Breakage

Run a quick test check:

```
IF project has test framework:
  Run tests targeting changed files only (same mapping as /test)
  Report: PASS or FAIL with failure details
ELSE:
  Report: SKIP (no test framework detected)
```

Keep this fast -- targeted tests only, not the full suite.

### Check 4: Lint Check

```
IF go.mod exists: run `revive -set_exit_status ./...` or `go vet ./...`
IF package.json exists: run `npx eslint {changed files}` if eslint is configured
IF Gemfile exists: run `bundle exec rubocop {changed files} --force-exclusion` if rubocop is configured
IF pyproject.toml exists: run `ruff check {changed files}` if ruff is configured
IF Cargo.toml exists: run `cargo clippy -- -D warnings`
ELSE: SKIP
```

**Report:** FAIL if lint errors found.

### Output

```
IF --strict mode:
  FAIL if ANY check has warnings or failures
ELSE:
  FAIL if ANY check has failures (warnings are noted but pass)
```

Format:

```markdown
## Guard Check

| Check | Status | Details |
|-------|--------|---------|
| Gitignore | PASS/WARN | {brief or "Clean"} |
| Secrets | PASS/FAIL | {brief or "Clean"} |
| Security | PASS/FAIL | {brief or "Clean"} |
| Tests | PASS/FAIL/SKIP | {brief or "All passing"} |
| Lint | PASS/FAIL/SKIP | {brief or "Clean"} |

**Result: PASS / FAIL**

{If FAIL: list each issue with file and line number}
{If PASS: "Safe to commit."}
```

Keep the output concise. This should feel like a quick gate check, not a verbose report.
