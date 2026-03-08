---
name: improve
description: Improve skills, capture context & knowledge. Use for skill iteration, capturing learnings, or upgrading agent context.
---
# Improve Skills, Capture Context & Knowledge

Analyze the current conversation to improve skills, fix codebase gaps, capture durable knowledge, and generate handoff prompts for skills managed outside this repository.

## When to Use

Run `/improve` at the end of any session where:
- Skills were invoked and required manual fixes or workarounds
- You discovered better patterns or approaches mid-conversation
- A skill produced output that needed multiple iterations to get right
- Technical assumptions in a skill turned out to be wrong
- You learned something that would make a skill work better next time
- You hit a codebase gap (missing docs, tests, error handling, or config)
- You learned new organizational context (people, roles, vendor contacts, processes)

## Context

- Current repo: !`git rev-parse --show-toplevel 2>/dev/null | head -1`
- Skills directory: !`find agents/skills -maxdepth 2 -name SKILL.md 2>/dev/null | head -30`
- Context directory exists: !`ls context/knowledge/index.md 2>/dev/null | head -1`
- Knowledge base index: !`cat context/knowledge/index.md 2>/dev/null | head -30`
- Context directory structure: !`find context -type f 2>/dev/null | head -20`
- Voice profile: !`find . -maxdepth 3 -name 'voice-profile.md' -o -name 'VOICE.md' -o -name 'voice.md' 2>/dev/null | head -5`

## Instructions

When `/improve` is invoked:

### Step 0: Ensure Context Directory Exists

Check whether the current repo has a `context/` directory at the repo root.

**If `context/` does not exist**, prompt the user:

> This repo has no `context/` directory. Want me to create one? This gives you a durable, gitignored place to store operational context, knowledge, research, and plans across sessions.
>
> I'll create:
> ```
> context/
> ├── knowledge/
> │   └── index.md          # Knowledge graph index
> ├── research/             # Investigation notes, spikes, evaluations
> └── plans/                # Strategic plans, proposals, roadmaps
> ```
>
> I'll also add a reference in CLAUDE.md. The `context/` directory is checked into git so it persists across clones.

If the user approves:

1. Create the directory structure above
2. Initialize `context/knowledge/index.md` with an empty knowledge table:
   ```markdown
   # Knowledge Index

   Structured knowledge for cross-session persistence. Each file covers a topic/domain.

   | File | Topic | Key Entities | Last Updated |
   |------|-------|-------------|-------------|

   ## Coverage Map

   Which context files are captured in knowledge:

   | Context File | Knowledge File(s) | Coverage |
   |-------------|-------------------|----------|
   ```
3. Add a `## Context Directory` section to CLAUDE.md (or the repo's agent guidance file) explaining:
   - `context/` is gitignored and stores durable cross-session knowledge
   - `context/knowledge/index.md` is the knowledge graph index
   - `context/research/` holds investigation notes and spike results
   - `context/plans/` holds strategic plans and proposals
   - Agents should read `context/knowledge/index.md` when they need project history or domain context

If the user declines, proceed without it — Steps 8B and 8C will be skipped (no knowledge base to update).

**If `context/` already exists**, proceed to Step 1.

### Step 1: Identify Skills Used

Scan the full conversation for:
- Explicit skill invocations (`/pdf`, `/review`, `/test`, etc.)
- Implicit skill-like patterns (e.g., PDF generation even without `/pdf`, data export workflows)
- CLAUDE.md or AGENTS.md instructions that were followed or should have been followed
- Recurring manual steps that could be codified into a skill

List each skill used with a brief note on what it did in this session.

**Note:** If improvements were already applied earlier in the same session (e.g., from manual fixes or a prior `/improve` run), skip those and only propose net-new changes.

### Step 2: Extract Learnings per Skill

For each skill identified, analyze:

1. **What worked well** — smooth execution, no issues
2. **Friction points** — where did the user need to iterate, correct, or re-run?
3. **Technical discoveries** — new knowledge about how the underlying tool/script works
4. **Incorrect assumptions** — anything the skill file says that turned out wrong
5. **Missing capabilities** — things the user asked for that the skill did not cover

### Step 3: Classify Each Skill by Location

For each skill with proposed changes, determine where it lives:

1. **Read the SKILL.md** — resolve its path (e.g., `~/.claude/skills/<name>/SKILL.md`)
2. **Check if it is inside the current git repo** — compare the SKILL.md real path against `git rev-parse --show-toplevel`
3. **Classify:**
   - **Local skill** — the SKILL.md is inside the current repo. Changes can be applied directly.
   - **External skill** — the SKILL.md lives in a different repo (e.g., `~/.dots/agents/skills/`). **Never edit external skills directly.** Always generate a handoff prompt instead.

**Default: local project.** All improvements and new skills target the current project unless there is a strong reason to modify an external skill. When an external skill needs changes, generate a handoff prompt (Step 5) — do not edit it even if you have write access.

### Step 4: Propose Improvements

For each skill with learnings, draft specific changes:

- **Fix factual errors** (e.g., wrong library name, outdated API)
- **Add learned patterns** (e.g., "when exporting tables, use proportional column widths")
- **Add missing instructions** (e.g., "can also accept `--input` flag for existing files")
- **Add troubleshooting tips** (e.g., "if tables show whitespace, check for multi_cell usage")
- **Flag new skill opportunities** — if a recurring pattern has no skill, note it here and detail it in Step 6

**Code-over-skills check:** Before proposing any change that adds inline scripts (bash, Ruby, Python, data transformations, API calls, or parsing logic) to a SKILL.md, check whether the project's CLAUDE.md has rules about where logic should live (e.g., "code over skills", "capture reusable logic in CLI commands"). If it does, do NOT add the script to the skill. Instead, route it to Step 7 (Fix Codebase Gaps) as a missing CLI command. The skill improvement becomes: "reference the new CLI command" rather than "embed the script."

Present each proposed change as a before/after diff for the user to review.

### Step 5: Apply or Hand Off

**For local skills (default path):**
1. Ask the user which changes to apply (default: all)
2. Edit the skill files in the current project with the approved changes
3. Summarize what was updated

**For external skills (handoff only — never edit directly):**
Generate a copy-pasteable handoff prompt for each external skill with changes. The prompt should:
- Be self-contained so another agent can apply it without this session's context
- Include the full file path and repo so the receiving agent knows where to work

Format:

```
## Skill Improvement Handoff: /<skill-name>

**Skill location:** <real path to SKILL.md>
**Source repo:** <git repo that owns the skill>

### Proposed Changes

1. **<change type>: <title>** — <description>
   - Before: <relevant excerpt>
   - After: <proposed replacement>

2. ...

### Context

<1-3 sentences explaining what session behavior motivated these changes>
```

Print each handoff prompt inside a fenced code block so the user can copy it into a session working in the skill's source repo.

### Step 6: Check for New Skill Opportunities

Review the full session for patterns that are **not covered by any existing skill** but would benefit from one. Look for:

- **Multi-step workflows done manually** — sequences of 3+ steps that followed a predictable pattern (e.g., "check CI, read logs, fix issue, re-push" repeated across sessions)
- **Recurring command sequences** — the same shell commands or tool calls issued in a consistent order
- **Integration patterns** — interactions with MCP tools, external APIs, or services that required domain knowledge to get right
- **User corrections that reveal a process** — when the user redirected you toward a specific workflow, that workflow might be a skill
- **Arguments passed to `/improve` itself** — if the user described a capability gap when invoking `/improve`, treat that as a direct signal

#### Threshold Test

Only propose a skill if it passes **at least two** of these criteria:
1. **Repeatable** — the workflow would likely recur in future sessions (not a one-off)
2. **Non-trivial** — it involves enough steps or domain knowledge that an agent without the skill would get it wrong or take significantly longer
3. **Self-contained** — it can be described as a clear input-to-output process with defined success criteria

#### Proposal Format

For each new skill opportunity, present:

```
**Proposed Skill: /<name>**
- **What it does:** <1-2 sentence description>
- **Trigger:** When would a user invoke this? What keywords or situations?
- **Key steps:** <numbered list of what the skill would instruct the agent to do>
- **Dynamic context needed:** <what live data the skill would inject, if any>
- **Cross-project or local?** <local (default) or cross-project with rationale>
```

#### Creating the Skill

After the user approves a proposal:
1. **If the skill is local (default):** invoke `/write-skill <name> — <description>` to create it following established patterns and validation rules. If `/write-skill` is not available, create the SKILL.md directly in the repo skills directory.
2. **If the skill is cross-project:** generate a handoff prompt (same format as Step 5) so it can be created in the source repo via `/write-skill` there.

**New skills default to the local project.** Only propose creating a skill in an external repo (like `~/.dots`) if the skill is clearly cross-project and not specific to the current codebase — and in that case, generate a handoff prompt instead of creating it directly.

### Step 7: Fix Codebase Gaps & Update Agent Guidance

Review the session for codebase gaps that were discovered or worked around but not fixed. These are issues in the project itself (not in skills):

- **Missing or outdated documentation** — CLAUDE.md, AGENTS.md, or README sections that are wrong, incomplete, or missing components that were used during the session
- **Missing tests** — code paths that were exercised manually but have no test coverage
- **Missing error handling** — failures that surfaced during the session because a code path had no guard
- **Configuration gaps** — env vars, CI steps, linter rules, or build config that caused friction
- **Undocumented patterns** — conventions the codebase follows implicitly that tripped up work during the session

For each gap found:
1. Describe the gap and how it caused friction
2. Propose a specific fix (as a diff when possible)
3. **Apply immediately by default** — straightforward fixes (missing CLI flags, error handling, docs, tests) should be implemented and committed without asking. Only pause for approval on risky changes (breaking API changes, large refactors, changes to shared interfaces).

Only fix gaps that were actually encountered during the session. Do not speculatively audit the codebase.

#### Agent Guidance Updates

After completing the gap analysis above, also review the learnings from Steps 2-6 for improvements that should be propagated into CLAUDE.md, AGENTS.md, or other agent guidance files. Skills capture *how to do a specific task*, but agent guidance captures *cross-cutting conventions, patterns, and rules* that affect all tasks.

Specifically, check whether any of these emerged during the session:

- **New conventions or patterns** — a workflow pattern, naming convention, or architectural constraint that was discovered or established and should guide future agent behavior across all tasks (not just within one skill)
- **Corrected assumptions** — something an agent would get wrong by default without explicit guidance (e.g., "always use X instead of Y", "never run Z without flag W")
- **Tool/infra quirks** — non-obvious behavior of the project's tools, CI, deploy pipeline, or dependencies that caused friction and would trip up agents again
- **Process rules** — ordering constraints, approval requirements, or safety checks that should be followed every time (e.g., "run linter before committing", "check with user before modifying shared config")

For each agent guidance update:
1. Identify the target file (CLAUDE.md, AGENTS.md, or a project-specific guidance file)
2. Identify the right section — add to an existing section if one fits, otherwise propose a new section
3. Draft the addition as a diff
4. **Apply directly for local files** — same apply-by-default rule as codebase gaps. For guidance files in external repos, generate a handoff prompt (same format as Step 5)

**Do NOT duplicate into agent guidance** anything that is already captured in a skill's SKILL.md. Only promote learnings that are cross-cutting — relevant beyond the scope of a single skill.

### Step 8: Capture Context & Knowledge

**Part A: Operational Context**

Review the session for extractable operational context:
- People mentioned (names, roles, responsibilities, reporting lines)
- Vendors/tools (active, deprecated, categories)
- Processes (who handles what, escalation paths)
- Policies and requirements (compliance, partnerships)
- Decisions made and their rationale

Update existing context files in `context/` directory as appropriate (requires `context/` to exist from Step 0):
- Create new files as needed for distinct topics (e.g., `context/research/`, `context/plans/`)
- Update CLAUDE.md if the context applies broadly across tasks
- **Never** write to `memory/`, `memory/memory.md`, or auto memory — all context goes in `context/`

**Part B: Knowledge Graph**

Check whether the current project has a knowledge base by looking for `context/knowledge/index.md` (shown in the Context section above).

**If no knowledge base exists** (and the user declined to create one in Step 0), **skip Part B entirely.** Do not fall back to auto memory or any alternative. Just move on.

**If a knowledge base exists**, review the session for durable knowledge worth preserving:
- Architectural decisions or constraints discovered during this session
- Project-specific patterns (naming conventions, API quirks, deploy procedures)
- Debugging insights (what caused a tricky bug, what the fix was)
- Tool/dependency behavior that was non-obvious
- People, entities, or relationships learned during the session

The knowledge base uses structured topic files with an index. To add knowledge:
1. Read `context/knowledge/index.md` to see existing topics and coverage
2. Identify which topic file the new knowledge belongs in (or propose a new topic file)
3. Propose additions as diffs to the relevant topic file(s) and index
4. Apply after user approval

**Part C: Knowledge Graph Gap Analysis**

Proactively identify knowledge graph gaps — entities, topic files, or categories the session revealed that don't yet exist. This goes beyond "capture what was discussed" to "suggest what *should* be tracked."

1. **Scan for uncaptured entities**: Compare entities mentioned in this session against the knowledge index. Flag any that were discussed substantively but have no entry (e.g., a merchant with GMV data, a new integration partner, a person with a defined role).

2. **Suggest new topic files**: If session content doesn't fit cleanly into existing knowledge files, propose a new topic file. Include:
   - Proposed filename and topic description
   - 2-3 seed entities that would go in it
   - Why existing files aren't the right home

3. **Identify missing entity types or relationship types**: The current taxonomy (from `/capture`) defines:
   - Entity types: `service`, `company`, `integration`, `system`, `process`, `policy`
   - Relationship types: `integrates_with`, `routes_through`, `hosted_on`, `owned_by`, `manages`, `replaces`, `depends_on`, `provides`, `consumes`

   If the session surfaced entities or relationships that don't fit these categories, propose additions to `/capture`'s taxonomy. Common gaps that have emerged in practice:
   - Entity types: `product` (a product offering), `strategy` (a strategic direction), `market_context` (competitive landscape), `partner` (vs generic company), `case_study` (customer success story with metrics)
   - Relationship types: `migrated_from`, `competes_with`, `evaluated_by`, `implemented_by`, `fills_gap_for`, `displaces`

   For each proposed addition, include the entity/relationship name, a one-line definition, and 2-3 examples from the session or knowledge base that demonstrate the need.

4. **Check coverage map staleness**: Scan the Coverage Map section of `index.md` for:
   - Context files that exist in `context/` but aren't listed in the coverage map
   - Context files listed in the coverage map that no longer exist
   - Knowledge files whose "Last Updated" date is >30 days old and were touched in this session

5. **Report as a "Knowledge Gaps" section** in the improvement report:

```
## Knowledge Gaps Identified

### Uncaptured Entities
- **[Entity Name]** — mentioned as [role/context], no knowledge entry exists
  - Suggested file: [existing-file.md] or [new-file.md]

### New Topic File Proposals
- **[filename.md]** — [description]. Seed entities: [list].
  - Why: [why existing files aren't the right home]

### Taxonomy Gaps
- New entity type: `[type]` — [definition]. Examples: [from session or KB]
- New relationship type: `[type]` — [definition]. Examples: [from session or KB]

### Stale Coverage
- `context/[file].md` — exists but not in coverage map
- `knowledge/[file].md` — last updated [date], touched in this session → update date
```

Only report gaps that are actionable and non-trivial. Don't flag every passing mention — focus on entities with enough substance to warrant a knowledge entry (verified facts, defined relationships, business significance).

**Do NOT capture:**
- Anything already in CLAUDE.md or AGENTS.md
- Session-specific transients (file paths being worked on, temp state)
- Operational items (todos, plans in progress)
- Speculative conclusions from a single observation
- Information that duplicates existing knowledge entries

**Part D: Voice Profile**

Check whether the repo has a voice profile by looking at the dynamic context above (Voice profile field). Common locations: `voice-profile.md`, `VOICE.md`, or `voice.md` at the repo root or in `context/`.

**If no voice profile exists, skip Part D entirely.** Do not suggest creating one.

**If a voice profile exists**, review the session for patterns that should refine it:

1. **Read the existing voice profile** to understand current guidelines
2. **Scan the session for voice/tone signals:**
   - User corrections to tone, wording, or style (e.g., "make it more direct", "too formal", "don't use jargon")
   - Consistent patterns in user-written text (sentence length, vocabulary level, use of contractions, humor)
   - Audience-specific language that was established (technical depth, abbreviations, domain terms)
   - Formatting preferences demonstrated through corrections (bullet vs. prose, heading style, emphasis patterns)
3. **Propose updates** as diffs to the voice profile. Only add patterns that were:
   - Explicitly corrected or requested by the user, OR
   - Consistently demonstrated across multiple messages (not a one-off phrasing)
4. **Apply after user approval**

Do not overwrite existing voice profile entries — add to or refine them. If a session observation contradicts an existing entry, flag the conflict for the user to resolve rather than silently changing it.

**Note:** The `/improve` skill itself is in scope for improvement. If this session revealed friction in the improve workflow, include it in the report.

## What NOT to Improve

- Do not add session-specific details (specific file paths, query results)
- Do not bloat skills with edge cases that will not recur
- Do not change the fundamental purpose or structure of a skill
- Do not add improvements based on speculation — only from actual session experience
- Do not create a knowledge base outside the `context/` directory pattern — use Step 0 to initialize
- **Never** save context or knowledge to `memory/`, `memory/memory.md`, or auto memory — always use `context/` directory

## Example Output

```
# Session Improvement Report

## Skills Used
1. `/review` — Ran code review on authentication refactor (2 iterations)
2. `/test` — Ran tests, discovered missing edge case coverage
3. `/pdf` — Exported summary to PDF

## Proposed Improvements

### /review — 1 change (local, applying directly)

1. **Add: Retry on lint timeout** — Review step stalled when linter timed out.
   Add a 60-second timeout with retry.

### /pdf — 2 changes (external: ~/.dots/agents/skills/pdf/)

Handoff prompt generated below.

### New Skill Proposal: /coverage-report

**Proposed Skill: /coverage-report**
- **What it does:** Run tests, parse coverage output, and highlight untested lines in changed files.
- **Trigger:** After writing code, when checking test coverage for a PR or branch.
- **Key steps:** 1. Identify changed files on branch. 2. Run test suite with coverage. 3. Parse coverage report. 4. Show untested lines in changed files only.
- **Dynamic context needed:** Changed files list, test runner config.
- **Cross-project or local?** Cross-project (handoff to ~/.dots).

Create with /write-skill? (y/n)

## Codebase Gaps Fixed

1. **AGENTS.md: Missing `agents` component** — `dots install agents`
   was used but not listed in the Component Reference table.
   Added row to the table.

## External Skill Handoffs

[copy-pasteable handoff prompt for /pdf]

## Knowledge Captured

Added to context/knowledge/thanx-infrastructure.md:
- Authentication service requires `X-Request-ID` header for all endpoints

Updated context/knowledge/index.md:
- thanx-infrastructure.md Last Updated → 2026-02-26

## Knowledge Gaps Identified

### Uncaptured Entities
- **[Customer Name]** — mentioned as case study with metrics, no entry
  - Suggested file: customer-accounts.md

### Taxonomy Gaps
- New entity type: `case_study` — A customer success story with quantified outcomes.
  Examples: [Customer A] (38% activation, 3x active members), [Customer B] ($125M+ loyalty revenue)

### Stale Coverage
- `context/thanx/ordering-positioning.md` — exists but not in coverage map

## Voice Profile Updated

Updated `voice-profile.md`:
- Added: Prefer short, direct sentences. Avoid hedging language ("might", "perhaps").
- Refined: Technical depth → "assume reader knows Ruby/Rails; skip basic explanations"

## Apply all? (y/n)
```

## Philosophy: Compounding Improvement

Each `/improve` run should leave the system measurably better than it found it. The goal is not just fixing today's friction — it is building a system that compounds: each session's learnings reduce friction in all future sessions.

- **Small bets, high frequency** — Prefer small, targeted changes applied often over large rewrites applied rarely
- **Escalate, do not patch forever** — If the same skill keeps getting patched, stop patching and restructure
- **Close the loop** — Check whether past improvements actually helped. Revert what did not.
- **Widen the surface** — Skills, codebase, knowledge, and the improve process itself are all in scope

## Guidelines

- Be specific about what changed and why
- Link improvements to actual friction in the session
- Every improvement should have a clear "this would have saved time because..."
- Always check skill location before editing — never edit skills outside the current repo; generate a handoff prompt instead
- Default all new skills and improvements to the local project — only target external repos via handoff prompts
