---
name: deps
description: Audit outdated dependencies, check for vulnerabilities, and upgrade with test verification. Use for dependency audits, security checks, or upgrading packages.
---

# Dependency Audit & Upgrade

Audit outdated dependencies, check for known vulnerabilities, and upgrade with automatic test verification. Rolls back any upgrade that breaks tests.

## Arguments

- `$ARGUMENTS` - Optional: `audit` (check only, no changes), `upgrade` (apply upgrades), or a specific package name to focus on

## Context

- Project type: !`find . -maxdepth 1 \( -name go.mod -o -name Gemfile -o -name package.json -o -name Cargo.toml -o -name pyproject.toml \) 2>/dev/null | head -5`
- Lockfiles: !`find . -maxdepth 1 \( -name go.sum -o -name Gemfile.lock -o -name package-lock.json -o -name yarn.lock -o -name pnpm-lock.yaml -o -name Cargo.lock -o -name poetry.lock -o -name uv.lock \) 2>/dev/null | head -5`

## Instructions

### Step 1: Detect package manager

Based on the context above, identify the package manager:

| File | Package Manager | Outdated Command |
|------|----------------|-----------------|
| `go.mod` | Go modules | `go list -m -u all` |
| `Gemfile` | Bundler | `bundle outdated` |
| `package.json` | npm/yarn/pnpm | `npm outdated` or `yarn outdated` |
| `Cargo.toml` | Cargo | `cargo outdated` (if installed) |
| `pyproject.toml` | pip/poetry/uv | `pip list --outdated` or `poetry show --outdated` |

IF no recognized package manager is found, report "No supported package manager detected." and stop.

IF multiple are found, process each in order.

### Step 2: Audit outdated dependencies

Run the appropriate outdated command. Parse the output into a table:

```markdown
| Package | Current | Latest | Type |
|---------|---------|--------|------|
| foo | 1.2.3 | 2.0.0 | Major |
| bar | 1.0.0 | 1.1.0 | Minor |
| baz | 1.0.0 | 1.0.1 | Patch |
```

Classify each as Major, Minor, or Patch based on semver difference.

### Step 3: Check for vulnerabilities

Run the appropriate audit command:

| Package Manager | Audit Command |
|----------------|--------------|
| Go | `govulncheck ./...` (if installed, otherwise skip) |
| Bundler | `bundle audit check` (if installed, otherwise skip) |
| npm | `npm audit` |
| Cargo | `cargo audit` (if installed, otherwise skip) |
| pip | `pip-audit` (if installed, otherwise skip) |

Report any known vulnerabilities with severity level.

### Step 4: Report (audit mode)

IF `$ARGUMENTS` is `audit` or empty, present the combined report and stop:

```markdown
## Dependency Report

### Outdated (<N> packages)
<table from Step 2>

### Vulnerabilities (<N> found)
<table of vulnerabilities with severity>

### Recommendation
- <N> critical/high vulnerabilities to fix immediately
- <N> major updates to evaluate
- <N> minor/patch updates safe to apply
```

### Step 5: Upgrade (upgrade mode)

IF `$ARGUMENTS` is `upgrade` or a specific package name, proceed with upgrades.

Order of operations:
1. **Patch updates first** — lowest risk
2. **Minor updates second** — moderate risk
3. **Major updates last** — highest risk, one at a time

For each upgrade:

1. Apply the upgrade using the appropriate command:
   - Go: `go get <package>@latest`
   - Bundler: `bundle update <gem>`
   - npm: `npm install <package>@latest`
   - Cargo: update version in `Cargo.toml`, run `cargo update -p <package>`
   - pip: `pip install --upgrade <package>`

2. Run the test suite (detect framework same as `/test` skill):
   - Go: `go test ./...`
   - Ruby: `bundle exec rspec`
   - Node: `npm test`
   - Rust: `cargo test`
   - Python: `pytest`

3. IF tests pass: keep the upgrade, move to next package.
4. IF tests fail: revert the change (`git checkout -- <lockfile> <manifest>`), report the failure, and move to next package.

### Step 6: Summary

```markdown
## Upgrade Summary

| Package | From | To | Status |
|---------|------|----|--------|
| foo | 1.0.0 | 1.0.1 | Upgraded |
| bar | 1.0.0 | 2.0.0 | Failed (test: <brief reason>) |
| baz | 1.0.0 | 1.1.0 | Skipped (user declined) |

**Tests:** All passing after upgrades.
```
