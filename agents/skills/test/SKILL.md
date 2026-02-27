---
name: test
description: Intelligent test runner that targets changed code and identifies coverage gaps
---

# Smart Test Runner

Analyze recent changes, run targeted tests, identify coverage gaps, and optionally write missing tests.

## Arguments

- `$ARGUMENTS` - Optional: `--full` for full test suite, `--write` to auto-write missing tests, or a specific file/directory to test

## Context

- Project type: !`find . -maxdepth 1 \( -name go.mod -o -name Gemfile -o -name package.json -o -name Cargo.toml -o -name pyproject.toml -o -name setup.py -o -name requirements.txt -o -name pom.xml -o -name build.gradle -o -name Makefile \) 2>/dev/null | head -5`
- Changed files: !`git diff --name-only HEAD~1 2>/dev/null | head -50`
- Test files: !`find . -maxdepth 4 \( -name "*_test.*" -o -name "*.test.*" -o -name "*_spec.*" -o -name "test_*" \) 2>/dev/null | head -20`
- Git status: !`git status --short`

## Instructions

### Step 1: Detect Test Framework

From the project type context above, determine:

| Indicator | Framework | Run Command |
|-----------|-----------|-------------|
| `go.mod` | Go test | `go test ./...` |
| `Gemfile` | RSpec or Minitest | `bundle exec rspec` or `bundle exec rake test` |
| `package.json` | Jest, Vitest, or Mocha | `npm test` or `npx jest` or `npx vitest` |
| `pyproject.toml` / `requirements.txt` | pytest or unittest | `pytest` or `python -m pytest` |
| `Cargo.toml` | cargo test | `cargo test` |
| `pom.xml` / `build.gradle` | JUnit | `mvn test` or `gradle test` |

If you can't detect a test framework, tell the user and ask how to run tests.

### Step 2: Determine Test Scope

```
IF $ARGUMENTS contains "--full":
  Run the full test suite

ELSE IF $ARGUMENTS contains a specific file or directory:
  Run tests for that target only

ELSE:
  Analyze changed files and map them to test files:
  1. For each changed file, look for corresponding test file:
     - Go: foo.go → foo_test.go
     - Ruby: app/models/user.rb → spec/models/user_spec.rb
     - JS/TS: src/utils.ts → src/utils.test.ts or __tests__/utils.test.ts
     - Python: module.py → test_module.py or tests/test_module.py
     - Rust: src/lib.rs → tests in same file or tests/ directory
  2. Run only the mapped test files
  3. If no test files map to the changes, run the full suite
```

### Step 3: Run Tests

Run the determined tests. Capture output including:
- Pass/fail status for each test
- Failure messages with file and line numbers
- Total counts: passed, failed, skipped

If tests fail, read the failing test files and the source files they test to understand the failures.

### Step 4: Measure and Analyze Coverage

First, try to use the project's coverage tool if available:

| Framework | Coverage Command |
|-----------|-----------------|
| Go | `go test -coverprofile=coverage.out ./... && go tool cover -func=coverage.out` |
| pytest | `pytest --cov --cov-report=term-missing` |
| Jest | `npx jest --coverage` |
| RSpec | Coverage via `simplecov` (runs automatically if in Gemfile) |
| cargo | `cargo tarpaulin` (if installed) |

If a coverage tool ran, report the coverage percentage and uncovered lines.

If no coverage tool is available, fall back to manual analysis. Read each changed file and its corresponding test file (if any). Identify:

1. **Untested functions/methods** -- changed code with no corresponding test
2. **Missing edge cases** -- tests exist but don't cover error paths, boundary values, or nil/empty inputs
3. **New code without tests** -- newly created files with no test file

Report each gap with: file, function/method, what's missing.

### Step 5: Write Tests (if requested)

```
IF $ARGUMENTS contains "--write" OR user confirms:
  For each coverage gap identified:
  1. Write a test following existing test patterns in the project
  2. Use the same test framework, naming conventions, and style
  3. Run the new test to verify it passes
  4. Report what was written
```

### Step 6: Report

```markdown
## Test Results

### Run Summary
- **Framework:** {detected framework}
- **Scope:** {targeted / full suite}
- **Status:** PASS / FAIL
- **Passed:** {N} | **Failed:** {N} | **Skipped:** {N}

### Failures (if any)
| Test | File | Error |
|------|------|-------|
| {test name} | {file:line} | {brief error} |

### Coverage Gaps
| Source File | Function/Method | Gap |
|-------------|-----------------|-----|
| {file} | {function} | {what's missing} |

### New Tests Written (if --write)
| Test File | Tests Added | Covers |
|-----------|-------------|--------|
| {file} | {N} | {what it tests} |

### Recommendation
{1-2 sentences: overall health and what to do next}
```
