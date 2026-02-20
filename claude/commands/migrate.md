---
description: Multi-agent codebase migration with module ownership
---

# Multi-Agent Migration

Decompose a migration across modules, assign each to an agent, and let them coordinate interface changes directly with each other.

## Prerequisites

Agent teams must be enabled in Claude Code settings:

```
CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

If agent teams are not enabled, report: "Agent teams required. Add `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` to your Claude Code settings (env section)." and stop.

## Arguments

- `$ARGUMENTS` - Required: description of the migration (e.g., "upgrade from v2 to v3 of the API client", "migrate from callbacks to async/await", "replace ORM X with Y")

If no arguments are provided, ask the user what they want to migrate.

## Context

- Current branch: !`git branch --show-current`
- Git status: !`git status --short`
- Project root: !`pwd`
- Project type: !`ls -1 go.mod Gemfile package.json Cargo.toml pyproject.toml setup.py requirements.txt pom.xml build.gradle Makefile 2>/dev/null | head -5`
- Recent commits: !`git log --oneline -5`
- Directory structure: !`find . -maxdepth 2 -type d -not -path '*/\.*' -not -path '*/node_modules/*' -not -path '*/vendor/*' | head -30`

## Overview

You are the **lead coordinator** for a migration team. Your job is to decompose the migration into independent modules, assign each to an agent, and ensure agents coordinate interface changes directly with each other.

**Migration task:** $ARGUMENTS

You do NOT write code yourself. You decompose, assign, coordinate, and verify.

**Why teams:** When agent A changes an interface, it messages agents B and C who depend on it. They adapt in parallel rather than waiting for a sequential cascade through the lead. This peer-to-peer negotiation is why migrations benefit from teams over subagents.

---

## Phase 0: Analysis

1. **Clean working tree:** If there are uncommitted changes, commit them with message `"WIP: pre-migration state"` before proceeding.

2. **Understand the migration scope:**
   - Explore the codebase to identify all files/modules affected
   - Map dependencies between modules
   - Identify the migration pattern (what changes from old → new)

3. **Decompose into independent modules.** Each module should:
   - Be owned by a single agent
   - Have clear file boundaries (no overlapping files between agents)
   - Have identifiable dependencies on other modules

4. **Present the decomposition to the user:**

```markdown
## Migration Plan: {migration description}

### Modules
| Module | Owner | Files | Depends On |
|--------|-------|-------|------------|
| {name} | migrator-1 | {file list} | {other modules} |
| {name} | migrator-2 | {file list} | {other modules} |
| {name} | migrator-3 | {file list} | {other modules} |

### Migration Order
{Which modules should go first based on dependency direction}

### Interface Boundaries
{Key interfaces that will change and which modules are affected}
```

   Wait for user approval before proceeding.

5. **Create the team** (clean up stale session first if needed):
   ```
   TeamDelete() -- ignore if no existing team
   TeamCreate(team_name: "migration-session", description: "Migration: {brief summary}")
   ```

6. **Create the task list** with TaskCreate:
   - One task per module, with dependency ordering reflected in blockedBy
   - "Wave {N} test check" -- for tester, after each wave (not just at the end)
   - "Final verification" -- blocked by all module tasks

7. **Spawn agents:** One migrator per module, plus one tester. Use `model: "sonnet"` for all agents. Spawn all in a single message.

---

## Phase 1: Migration Waves

Migrations proceed in dependency order. Modules with no dependencies start first.

### Wave start

Send each ready migrator their assignment via SendMessage:

```
MIGRATION: {overall migration description}

YOUR MODULE: {module name}
YOUR FILES (you own these exclusively -- no other agent will touch them):
{file list}

MIGRATION PATTERN:
{what to change: old pattern → new pattern, with examples}

MODULES THAT DEPEND ON YOU:
{list of downstream modules and their owners}

MODULES YOU DEPEND ON:
{list of upstream modules and their owners}

INSTRUCTIONS:
1. Read all your files to understand current usage.
2. Apply the migration pattern to each file.
3. If you CHANGE AN INTERFACE (function signature, type, export, etc.):
   - Message each DOWNSTREAM module owner DIRECTLY with:
     "I changed {old interface} to {new interface} in {file}. You'll need to update your usage in {their files}."
   - Be specific: include the old and new signatures.
4. If you RECEIVE a message about an upstream interface change:
   - Update your code to match the new interface.
   - Acknowledge to the sender that you've adapted.
5. Run a basic sanity check (compile, lint) after changes.
6. When done, message me (the lead) with:
   - Files changed
   - Interfaces changed (and who you notified)
   - Any issues or uncertainties

Mark your task as completed.
```

### Between waves

After each wave completes:
1. Verify no files were modified by multiple agents (run `git diff --name-only` and check for conflicts)
2. If upstream modules changed interfaces, confirm downstream modules adapted
3. **Send the tester a wave check:**

```
WAVE {N} COMPLETE. Run targeted tests for the modules just migrated:

MIGRATED MODULES THIS WAVE:
{list of modules and their files}

INSTRUCTIONS:
1. Run tests related to the migrated files.
2. Report pass/fail to me (the lead).
3. If failures, identify which module caused the issue.

This is a quick check -- full suite runs at the end.
```

4. Start the next wave of modules (those whose dependencies are now complete)

---

## Phase 2: Final Verification

Once all modules are migrated:

1. **Send the tester the full scope:**

```
ALL WAVES COMPLETE. Run the FULL test suite.

ALL CHANGED FILES: {list from git diff --name-only}
FULL DIFF: {git diff}

INSTRUCTIONS:
1. Run the full test suite. Report pass/fail.
2. If tests fail, identify whether the failure is:
   - A migration error (agent missed something)
   - A pre-existing failure (not related to migration)
   - An interface mismatch (two modules disagree on an interface)
3. For interface mismatches, identify WHICH modules are mismatched and notify me.
4. Report results to me (the lead).

Mark your task as completed.
```

2. **If interface mismatches found:** Message the two mismatched module owners directly and ask them to negotiate the correct interface. Wait for resolution, then re-test.

3. **If migration errors found:** Message the responsible module owner with the specific fix needed. Wait for fix, then re-test.

4. **Repeat until tests pass** (max 3 fix rounds).

---

## Phase 3: Shutdown and Summary

1. **Shut down all teammates:**
   ```
   For each migrator and the tester:
     SendMessage(type: "shutdown_request", recipient: {name}, content: "Migration complete.")
   ```
   Wait for confirmations.

2. **Clean up the team** with TeamDelete.

3. **Produce the migration report:**

```markdown
## Migration Summary

### Migration
{original migration description}

### Modules Migrated
| Module | Owner | Files Changed | Interfaces Changed |
|--------|-------|---------------|-------------------|
| {name} | migrator-1 | {count} | {list or "None"} |
| {name} | migrator-2 | {count} | {list or "None"} |
| {name} | migrator-3 | {count} | {list or "None"} |

### Interface Negotiations
{List any interface changes that required coordination between agents}

### Test Results
- **Status:** PASS / FAIL
- **Wave checks:** {N} waves, all passed / issues found in wave {N}
- **Fix rounds:** {N}
- **Issues found:** {list or "None"}

### Remaining Items
{Any unresolved issues or "None -- all clear"}

### Diff
{git diff --stat output}
```

---

## Agent Briefing Templates

### Migrator

```
You are a MIGRATOR on a migration team. You own a specific set of files.

YOUR TEAMMATES:
- Lead: assigns modules, coordinates waves, verifies results.
- Other migrators: own different modules. You coordinate DIRECTLY with them on interface changes.
- Tester: runs tests between waves and at the end.

RULES:
1. ONLY modify files assigned to you. Never touch another migrator's files.
2. When you change an interface, message downstream owners DIRECTLY with the old and new signatures.
3. When an upstream owner messages you about an interface change, adapt your code and acknowledge.
4. Be specific in all communications: file paths, line numbers, function signatures.

Always use TaskUpdate to mark tasks completed.
```

### Tester

```
You are the TESTER on a migration team. You verify the migration is correct.

YOUR TEAMMATES:
- Lead: coordinates the migration.
- Migrators: each own a module. You test their combined work.

WORKFLOW:
1. After each wave completes, run targeted tests for the migrated modules.
2. After all waves complete, run the full test suite.
3. For failures, identify which module is responsible.
4. For interface mismatches, identify the two conflicting modules.
5. Report everything to the lead.

Be specific: report exact test names, failure messages, and line numbers.

Always use TaskUpdate to mark tasks completed.
```

---

## Failure Handling

| Failure | Action |
|---------|--------|
| Agent fails to spawn | Retry once. If still fails, reassign that module to another migrator. |
| File conflict detected | Identify which agents touched the same file. Reassign one agent's changes. |
| Interface negotiation stalls | Lead intervenes with a decision on the correct interface. Both agents adapt. |
| Tests fail after 3 fix rounds | Produce summary with remaining failures as TODOs. |
| Module too large for one agent | Split it into sub-modules and assign to additional agents. |
| Team creation fails (teams not enabled) | Report the prerequisite and stop. |
