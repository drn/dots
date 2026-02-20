## ADDED Requirements

### Requirement: Explicit Installer Registration
The CLI SHALL register installer components via an explicit map rather than reflection, so that missing or misspelled components produce compile-time errors.

#### Scenario: Valid component name
- **WHEN** a user runs `dots install vim`
- **THEN** the installer map resolves `"vim"` to its handler and executes it

#### Scenario: Invalid component name
- **WHEN** a user runs `dots install nonexistent`
- **THEN** the CLI prints an error listing available components and exits with code 1

### Requirement: Error Propagation
Library packages (`pkg/*`, `cli/*`) SHALL return errors to callers instead of calling `os.Exit()` directly, so that callers can handle failures and tests can assert on errors.

#### Scenario: Command execution failure
- **WHEN** `pkg/run.Capture()` executes a command that fails
- **THEN** it returns the error to the caller instead of silently discarding it

### Requirement: Unit Test Coverage
Core packages (`pkg/cache`, `pkg/path`, `cli/is`, `cli/link`) SHALL have unit tests covering primary functionality.

#### Scenario: Cache TTL expiry
- **WHEN** a cache entry is written and read after TTL expires
- **THEN** `cache.Read()` returns empty string

### Requirement: Modern Go Stdlib Usage
The codebase SHALL use non-deprecated stdlib APIs (`os.ReadFile`, `os.ReadDir`) and target Go 1.21+ in `go.mod`.

#### Scenario: No deprecated ioutil usage
- **WHEN** the codebase is scanned for `ioutil.` references
- **THEN** zero matches are found

## MODIFIED Requirements

### Requirement: CI Pipeline
The CI pipeline SHALL include `go vet`, static analysis, and `go test` steps in addition to the existing `revive` linter and component integration tests.

#### Scenario: CI catches deprecated API
- **WHEN** a PR introduces usage of `ioutil.ReadFile`
- **THEN** the static analysis step fails the build
