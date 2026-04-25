---
name: cross-agent
description: Set up cross-agent skill infrastructure so skills work across Claude Code, OpenAI Codex, and GitHub Copilot. Use for multi-agent compatibility, skill migration, cross-agent sync.
disable-model-invocation: true
---

# Cross-Agent Skill Setup

Migrate a repository's skills to the Agent Skills open standard so they work across Claude Code, Codex, and Copilot.

## Arguments

- `$ARGUMENTS` - Optional: path to target repo (defaults to current working directory)

## Context

- Existing .agents/skills: !`find .agents/skills -maxdepth 2 -name SKILL.md 2>/dev/null | head -30`
- Existing .claude/commands: !`find .claude/commands -maxdepth 1 -name "*.md" 2>/dev/null | head -30`
- Existing .claude/skills: !`find .claude/skills -maxdepth 2 -name SKILL.md 2>/dev/null | head -30`
- AGENTS.md exists: !`find . -maxdepth 1 -name AGENTS.md 2>/dev/null | head -1`
- CLAUDE.md type: !`file CLAUDE.md 2>/dev/null | head -1`
- claude.md (lowercase) exists: !`find . -maxdepth 1 -type f 2>/dev/null | grep '/claude\.md$' | head -1`
- Copilot instructions: !`find .github -maxdepth 1 -name copilot-instructions.md 2>/dev/null | head -1`
- Subtree CLAUDE.md files: !`find . -mindepth 2 -maxdepth 4 -name CLAUDE.md -not -path './.git/*' 2>/dev/null | head -20`
- Subtree AGENTS.md files: !`find . -mindepth 2 -maxdepth 4 -name AGENTS.md -not -path './.git/*' 2>/dev/null | head -20`
- Git root: !`git rev-parse --show-toplevel 2>/dev/null | head -1`

## Instructions

### Step 0: Pre-flight

Verify this is a git repository. If not, stop and report.

If `$ARGUMENTS` contains a path, cd to it first.

### Step 1: Discover Repo State

Scan for existing skills in all locations:

1. `.agents/skills/*/SKILL.md` (already canonical)
2. `.claude/commands/*.md` (Claude flat commands)
3. `.claude/skills/*/SKILL.md` (Claude directory skills)
Also check for a lowercase `claude.md` — Claude Code requires `CLAUDE.md` (uppercase) for discovery. Use `ls -1 | grep '^claude\.md$'` to detect the wrong casing (a plain `test -f` is unreliable on case-insensitive filesystems).

Classify the repo:

- **GREENFIELD**: No skills anywhere. Create infrastructure only.
- **CLAUDE-ONLY**: Skills in `.claude/` but no `.agents/skills/`. Full migration needed.
- **PARTIAL**: `.agents/skills/` exists but missing infrastructure (no AGENTS.md, no Copilot instructions, no sync scripts).
- **COMPLETE**: `.agents/skills/` exists with all infrastructure. Run validation only.

#### Subtree scan (monorepos)

Also scan for subtree-level `CLAUDE.md` / `AGENTS.md` files (any depth ≥ 2 inside the repo, excluding `.git`). For each subtree directory, classify:

- **CLAUDE-only** — only `CLAUDE.md` exists → `git mv` to `AGENTS.md` and add `CLAUDE.md` symlink
- **AGENTS-only** — only `AGENTS.md` exists → add `CLAUDE.md` symlink
- **Both, identical** — `cmp -s CLAUDE.md AGENTS.md` returns 0 → drop `CLAUDE.md`, replace with symlink
- **Both, divergent** — content differs → **merge required** (see Step 7 validation rules)
- **Symlink already** — `CLAUDE.md` is a symlink to `AGENTS.md` → skip

Treat subtrees as a first-class migration target, not an "out of scope" observation. The user expects `cross-agent` to migrate the entire monorepo in one pass.

### Step 2: Present Migration Plan

Show the user:

```
## Cross-Agent Migration Plan

State: [GREENFIELD/CLAUDE-ONLY/PARTIAL/COMPLETE]

### Skills to migrate
| Source | Name | Destination |
|--------|------|-------------|
| .claude/commands/review.md | review | .agents/skills/review/SKILL.md |
| .claude/skills/pdf/ | pdf | .agents/skills/pdf/ |

### Infrastructure to create
- [ ] .agents/skills/ directory
- [ ] AGENTS.md (cross-agent contract)
- [ ] CLAUDE.md symlink to AGENTS.md
- [ ] .claude/skills symlink to .agents/skills
- [ ] .github/copilot-instructions.md

### Per-Subtree Migration (omit this section if no subtree CLAUDE.md / AGENTS.md found)
| Subtree | State | Action |
|---|---|---|
| `nucleus/`        | CLAUDE-only        | git mv CLAUDE.md AGENTS.md; symlink CLAUDE.md → AGENTS.md |
| `services/admin/` | Both, divergent    | merge CLAUDE.md + AGENTS.md → AGENTS.md (verify both); symlink CLAUDE.md |
| `services/api/`   | Both, identical    | rm CLAUDE.md; symlink CLAUDE.md → AGENTS.md |
| `services/web/`   | AGENTS-only        | symlink CLAUDE.md → AGENTS.md |

Proceed? (waiting for confirmation)
```

Wait for confirmation before making changes. The subtree table must show the **action** per subtree, not a passive observation. The user should be able to approve subtree migration in one step alongside the root migration.

### Step 3: Create Directory Structure

Create directories if they do not exist:
- `.agents/skills/`

### Step 4: Migrate Skills

#### From `.claude/commands/<name>.md` (flat commands)

For each file:

1. Create `.agents/skills/<name>/` directory
2. Read the source file
3. If the file has YAML frontmatter (starts with `---`):
   - Add `name: <name>` after the opening `---` if not already present
   - Preserve all existing frontmatter fields
4. If the file has no frontmatter:
   - Add frontmatter with `name:` and `description:` (derive description from the first heading or paragraph)
5. Write to `.agents/skills/<name>/SKILL.md`

#### From `.claude/skills/<name>/` (directory skills)

For each directory:

1. Copy the entire directory to `.agents/skills/<name>/`
2. Read `SKILL.md` and add `name: <name>` to frontmatter if missing
3. Preserve all supporting files (scripts, templates, etc.)

#### Already in `.agents/skills/`

For each existing canonical skill:

1. Read `SKILL.md` and verify `name:` field exists in frontmatter
2. If missing, add it
3. Do not modify the body

### Step 4.5: Apply Per-Subtree Migration

If the Step 1 subtree scan found any subtree-level CLAUDE.md / AGENTS.md files, walk each entry from the approved per-subtree table and apply the action. **Use `git mv` for tracked files** so history is preserved. Always create a **relative** symlink within the subtree (e.g., `cd nucleus/ && ln -s AGENTS.md CLAUDE.md`).

Per-state actions:

- **CLAUDE-only** — `git mv <subtree>/CLAUDE.md <subtree>/AGENTS.md`, then create symlink `<subtree>/CLAUDE.md → AGENTS.md`.
- **AGENTS-only** — create symlink `<subtree>/CLAUDE.md → AGENTS.md`.
- **Both, identical** — `git rm <subtree>/CLAUDE.md`, then create symlink `<subtree>/CLAUDE.md → AGENTS.md`.
- **Both, divergent** — merge both into `<subtree>/AGENTS.md` (apply the Step 7 "Validation: divergent-content merge" rules), then `git rm <subtree>/CLAUDE.md` and create symlink `<subtree>/CLAUDE.md → AGENTS.md`.
- **Symlink already** — verify it points to `AGENTS.md`; otherwise repair it.

After processing all subtrees, sanity-check that every former CLAUDE.md location now resolves to its AGENTS.md sibling: `find . -name CLAUDE.md -not -path './.git/*' -exec test -L {} \; -exec readlink {} \; -print`.

### Step 5: Set Up Agent Discovery Symlinks

`.claude/skills/` should be a symlink to `.agents/skills/` so Claude Code discovers the canonical skills. Codex discovers skills directly from `.agents/skills/` — no additional symlink needed.

#### `.claude/skills`

Claude Code discovers skills from `.claude/skills/`. After migration, the original `.claude/commands/` and `.claude/skills/` should point to `.agents/skills/`.

**If `.claude/skills` is a symlink**: update it to point to `.agents/skills`
**If `.claude/skills` is a directory with content**: the content was already migrated in Step 4. Replace the directory with a symlink to `.agents/skills/`.
**If `.claude/skills` does not exist**: create `.claude/` directory if it does not exist, then create a symlink `.claude/skills` pointing to `../.agents/skills`

Remove `.claude/commands/` if it was fully migrated (all files moved to `.agents/skills/`). If some files remain that were not migrated, leave them.

### Step 6: Create AGENTS.md

If `AGENTS.md` does not exist at the repo root, create it:

```markdown
# AGENTS.md

Project-level instructions for AI coding agents.

## Cross-Agent Skills

Skills in this repository follow the [Agent Skills](https://agentskills.io) open standard.

### Canonical Source

All skill logic lives in `.agents/skills/<name>/SKILL.md`.

### Agent Discovery

| Agent | Discovery Path | Mechanism |
|-------|---------------|-----------|
| Claude Code | `.claude/skills/` | Symlink to `.agents/skills/` |
| OpenAI Codex | `.agents/skills/` | Direct (scans `.agents/skills` from CWD to repo root) |
| GitHub Copilot | `.github/copilot-instructions.md` | Routing file |
```

If `AGENTS.md` already exists, read it. If it does not contain a "Cross-Agent Skills" section, append one.

### Step 7: Handle CLAUDE.md

The goal is for `CLAUDE.md` to be a symlink to `AGENTS.md` so both Claude Code and Codex share the same instructions. Claude Code requires uppercase `CLAUDE.md` for discovery — lowercase `claude.md` will not be found.

**If `claude.md` (lowercase) exists**: rename it to `CLAUDE.md` first (`git mv claude.md CLAUDE.md` if tracked, otherwise `mv`). Then proceed with the checks below.

**If CLAUDE.md does not exist**: create a symlink `CLAUDE.md` pointing to `AGENTS.md`.

**If CLAUDE.md exists and is already a symlink to AGENTS.md**: skip.

**If CLAUDE.md exists with content (not a symlink)**:
1. Read both CLAUDE.md and AGENTS.md
2. Merge CLAUDE.md content into AGENTS.md (append sections that are not already present)
3. Replace CLAUDE.md with a symlink to AGENTS.md
4. Report what was merged so the user can review

#### Validation: divergent-content merge

When **both** CLAUDE.md and AGENTS.md exist with different content (not just one missing), the merge MUST preserve the substantive content of both files. Naive section-level appending can silently drop content if a section header matches but the body diverges (e.g., one file says `try devbox first → fallback to bundle exec`, the other just says `bundle exec rubocop`).

Before committing the merged AGENTS.md and replacing CLAUDE.md with a symlink:

1. Extract non-trivial content lines from each source file. A useful heuristic: every header (lines starting with `#`), every fenced code block, and every sentence longer than ~30 characters that isn't pure boilerplate.
2. Run `grep -F` for each extracted snippet against the merged AGENTS.md. Any snippet that does not appear in the merged file indicates content was dropped.
3. If anything is missing, re-merge to include it (or escalate to the user with the specific snippets that were dropped).
4. Only after the grep verification passes, replace CLAUDE.md with the symlink.

Apply the same validation when merging subtree CLAUDE.md / AGENTS.md pairs (Step 4 / Step 1 subtree scan classified as "Both, divergent").

### Step 8: Generate Copilot Instructions

Create `.github/copilot-instructions.md` if it does not exist:

```markdown
# Copilot Instructions

## Repository Contract

Read AGENTS.md at the repository root for project-wide instructions.

## Skill Routing

When a user invokes a skill (e.g., "run the review skill", "use /calendar"):

1. Look in .agents/skills/<name>/SKILL.md for the skill definition.
2. Read the full SKILL.md and execute its instructions.
3. If the skill is missing, list available skills and ask the user to choose.

## Available Skills

[LIST_OF_SKILLS]
```

Replace `[LIST_OF_SKILLS]` with a table of all skill names and descriptions from the `.agents/skills/` directory.

If the file already exists, check if it has a "Skill Routing" section. If not, append one.

### Step 9: Run Validation

Verify the setup by checking:

1. Every skill in `.agents/skills/*/SKILL.md` has a `name:` field in frontmatter
2. `.claude/skills` is a symlink pointing to `.agents/skills`
3. `AGENTS.md` exists
4. `CLAUDE.md` is a symlink to `AGENTS.md`
5. `.github/copilot-instructions.md` exists
6. No lowercase `claude.md` exists
7. **Subtrees:** every subtree `CLAUDE.md` (any depth ≥ 2) is a symlink resolving to a sibling `AGENTS.md`. Run: `find . -name CLAUDE.md -not -path './.git/*' -not -path './CLAUDE.md'` and verify each is `-L` (symlink) with `readlink` returning `AGENTS.md`.
8. **Divergent merges:** for each subtree where Step 1 classified as "Both, divergent", confirm the post-merge `grep -F` snippet check (Step 7 validation) was applied. If unsure, re-run the grep against the source content captured before the merge.

Report results. If any checks fail, explain what needs fixing and offer to fix it.

### Step 10: Summary Report

Present a final summary:

```
## Cross-Agent Setup Complete

### Skills Migrated
| Skill | Source | Status |
|-------|--------|--------|
| review | .claude/commands/ | Migrated |
| pdf | .claude/skills/ | Migrated |
| ... | ... | ... |

### Infrastructure
- [x] .agents/skills/ (N skills)
- [x] AGENTS.md
- [x] CLAUDE.md symlink
- [x] .claude/skills symlink
- [x] .github/copilot-instructions.md

### Agent Compatibility
| Agent | Discovery | Status |
|-------|-----------|--------|
| Claude Code | .claude/skills/ symlink | Ready |
| Codex | .agents/skills/ (direct) | Ready |
| Copilot | .github/copilot-instructions.md | Ready |

### Next Steps
- Review AGENTS.md for project-specific instructions
- Commit the changes
- Add new skills to .agents/skills/<name>/SKILL.md
```

## Edge Cases

- **No skills at all (GREENFIELD)**: Skip migration. Create infrastructure. Report "No skills to migrate. Add skills to .agents/skills/<name>/SKILL.md."
- **Already fully set up (COMPLETE)**: Run validation only. Report pass/fail.
- **CLAUDE.md has significant content**: Merge into AGENTS.md before symlinking. Show the user what was merged.
- **Mixed state**: Some skills in .agents/skills/, some in .claude/commands/. Migrate only the ones not already canonical.
- **Skill name collision**: If a skill exists in both .claude/commands/ and .agents/skills/ with different content, warn the user and skip. Do not overwrite canonical skills.
- **Lowercase `claude.md`**: Claude Code requires uppercase `CLAUDE.md`. If `claude.md` exists, rename it (`git mv` if tracked, `mv` otherwise) before proceeding with Step 7. Use `ls -1 | grep '^claude\.md$'` for detection — `test -f` is unreliable on case-insensitive filesystems (macOS default).
