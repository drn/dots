# development-workflows Specification

## Purpose
Define portable development workflows for the dev and orchestrate skills, using permitted
native delegation when available and equivalent single-agent execution otherwise.

## Requirements
### Requirement: Capability-based execution
The dev and orchestrate skills SHALL select execution using delegation tools actually
available and permitted in the active harness and project. Neither skill SHALL require
Claude Teams, a Claude-specific environment variable, Workflow, or a particular model vendor.
Neither skill SHALL prompt users to enable experimental Teams as a prerequisite.

#### Scenario: Native delegation is available
- **WHEN** the harness exposes a permitted native delegation tool
- **THEN** the skill uses that tool with scoped responsibilities and file ownership
- **AND** tools prohibited by project instructions are not used

#### Scenario: Delegation is unavailable
- **WHEN** no permitted delegation tool is available
- **THEN** the skill announces single-agent execution briefly and continues in the current session
- **AND** it does not stop to request harness configuration or experimental Teams enablement

### Requirement: Equivalent single-agent development cycle
In single-agent mode, both skills SHALL execute planning, implementation, verification,
review, and bounded repair sequentially in the current session. Applicable approval gates,
dependency ordering, and project verification requirements SHALL remain in effect.
Review SHALL be reported as self-review rather than independent review when no independent
agent ran.

#### Scenario: Dev without subagents
- **WHEN** dev runs in a harness with only file and command tools
- **THEN** the session obtains required plan approval, implements, tests, self-reviews, and reports results

#### Scenario: Orchestrate without Workflow
- **WHEN** orchestrate runs without the Workflow tool
- **THEN** it uses another permitted native delegation tool if available
- **AND** otherwise executes work items inline in dependency order with bounded repair and final whole-tree verification

### Requirement: Optional backend-specific optimizations
Both skills SHALL treat model selection, team messaging, Workflow scripting, and dynamic
context expansion as optional capabilities. They SHALL use configured model mappings where
supported and SHALL retain the available session/default model when explicit selection is
unsupported. They SHALL use portable references and gather equivalent context with available
tools when dynamic expansion is unsupported.

#### Scenario: Non-Claude model or no model selector
- **WHEN** the active backend does not expose Claude model names or explicit model selection
- **THEN** work proceeds with supported configured models or the available session/default model
- **AND** the skill does not request unavailable Claude models or claim that tiering occurred

#### Scenario: Harness does not expand dynamic context
- **WHEN** context commands are not automatically expanded
- **THEN** the skill collects relevant context with the available command and file tools

### Requirement: Safe fallback after delegation failure
Both skills SHALL inspect completed results and partial edits before falling back after
delegation becomes unavailable. They SHALL continue only unfinished work, avoid duplicating
active writers, and report incomplete work and verification failures honestly.

#### Scenario: Delegation fails after partial progress
- **WHEN** delegation fails after a work item has made changes
- **THEN** the session reconciles those changes and ensures no delegate is still writing before continuing inline
- **AND** it reports the fallback and any remaining blockers without relaunching completed work blindly

