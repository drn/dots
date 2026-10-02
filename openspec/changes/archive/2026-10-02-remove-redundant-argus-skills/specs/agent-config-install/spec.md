## ADDED Requirements

### Requirement: Skills Do Not Duplicate Argus Built-ins

The repository's `agents/skills/` SHALL NOT ship a skill whose behavior is already
provided identically by a skill built into argus. In particular, the Argus task
lifecycle skills are provided by the built-in `argus-archive` and `argus-complete`.

#### Scenario: Task lifecycle skills come from argus
- **WHEN** `dots install agents` links `agents/skills`
- **THEN** no `archive` or `complete` skill is installed from this repository
