# merge-safety Specification

## Purpose
TBD - created by archiving change update-merge-check-gate. Update Purpose after archive.
## Requirements
### Requirement: Merge CI Gate Fails Closed

The merge skill SHALL NOT merge a PR while any of its checks are pending, failing, or cancelled, whether or not the repository configures GitHub-required checks. When no required checks are configured, the gate SHALL evaluate every check on the PR, ignoring known non-gating bots.

#### Scenario: No required checks, pending PR checks
- **WHEN** the repo has no required checks and the PR has pending checks
- **THEN** the script waits until they resolve or the timeout elapses (exit 5)

#### Scenario: Failing check without required checks
- **WHEN** the repo has no required checks and a PR check is failing
- **THEN** the script exits 5 without merging

### Requirement: Check Query Errors Are Distinguished

The gate SHALL distinguish "no required checks configured" from a gh error. A gh error SHALL NOT be treated as zero checks.

#### Scenario: gh errors while reading checks
- **WHEN** the check query fails for a reason other than no required checks
- **THEN** the gate retries within the wait window and exits 5 on timeout

### Requirement: Check Registration Grace Period

The gate SHALL wait for at least one check to register, up to a short grace period, before concluding a PR has no checks.

#### Scenario: Checks not yet registered
- **WHEN** the PR was just created and has no checks
- **THEN** the gate polls through the grace period before proceeding

### Requirement: Admin Bypass Does Not Bypass CI

The --admin merge tier SHALL NOT run while any PR check is pending or failing, unless the user passed --no-wait-checks.

#### Scenario: Review required with pending CI
- **WHEN** review is required and checks are pending
- **THEN** no --admin merge is attempted

