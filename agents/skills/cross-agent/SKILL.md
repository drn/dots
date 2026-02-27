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
- Existing .codex/skills: !`find .codex/skills -maxdepth 2 -name SKILL.md 2>/dev/null | head -30`
- .codex/skills type: !`file .codex/skills 2>/dev/null | head -1`
- AGENTS.md exists: !`find . -maxdepth 1 -name AGENTS.md 2>/dev/null | head -1`
- CLAUDE.md type: !`file CLAUDE.md 2>/dev/null | head -1`
- claude.md (lowercase) exists: !`find . -maxdepth 1 -type f 2>/dev/null | grep '/claude\.md$' | head -1`
- Copilot instructions: !`find .github -maxdepth 1 -name copilot-instructions.md 2>/dev/null | head -1`
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
4. `.codex/skills/*/SKILL.md` (Codex mirror — should be a symlink, not a copy)

Also check for a lowercase `claude.md` — Claude Code requires `CLAUDE.md` (uppercase) for discovery. Use `ls -1 | grep '^claude\.md$'` to detect the wrong casing (a plain `test -f` is unreliable on case-insensitive filesystems).

Classify the repo:

- **GREENFIELD**: No skills anywhere. Create infrastructure only.
- **CLAUDE-ONLY**: Skills in `.claude/` but no `.agents/skills/`. Full migration needed.
- **PARTIAL**: `.agents/skills/` exists but missing infrastructure (no AGENTS.md, no Copilot instructions, no sync scripts).
- **COMPLETE**: `.agents/skills/` exists with all infrastructure. Run validation only.

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
- [ ] .codex/skills symlink to .agents/skills
- [ ] .github/copilot-instructions.md
- [ ] scripts/skills/sync-cross-agent-skills.sh
- [ ] .github/workflows/skills-sync.yml

Proceed? (waiting for confirmation)
```

Wait for confirmation before making changes.

### Step 3: Create Directory Structure

Create directories if they do not exist:
- `.agents/skills/`
- `scripts/skills/`
- `.github/workflows/` (if not present)

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

### Step 5: Set Up Agent Discovery Symlinks

Both `.claude/skills/` and `.codex/skills/` should be symlinks to `.agents/skills/` so all agents discover the same canonical skills.

#### `.claude/skills`

Claude Code discovers skills from `.claude/skills/`. After migration, the original `.claude/commands/` and `.claude/skills/` should point to `.agents/skills/`.

**If `.claude/skills` is a symlink**: update it to point to `.agents/skills`
**If `.claude/skills` is a directory with content**: the content was already migrated in Step 4. Replace the directory with a symlink to `.agents/skills/`.
**If `.claude/skills` does not exist**: create a symlink `.claude/skills` pointing to `.agents/skills`

Remove `.claude/commands/` if it was fully migrated (all files moved to `.agents/skills/`). If some files remain that were not migrated, leave them.

#### `.codex/skills`

Codex discovers skills from `.codex/skills/`. This should also be a symlink to `.agents/skills/`, not a separate copy.

**If `.codex/skills` is a symlink**: update it to point to `.agents/skills`
**If `.codex/skills` is a directory with content**: the content was already migrated in Step 4. Replace the directory with a symlink to `.agents/skills/`.
**If `.codex/skills` does not exist**: create `.codex/` if needed, then create a symlink `.codex/skills` pointing to `.agents/skills`

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
| OpenAI Codex | `.codex/skills/` | Symlink to `.agents/skills/` |
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

### Step 9: Generate Sync Script

Create `scripts/skills/sync-cross-agent-skills.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

mode="apply"
if [[ "${1:-}" == "--check" ]]; then
  mode="check"
fi

[[ -d ".agents/skills" ]] || { echo "Missing .agents/skills"; exit 1; }

fail=0

# Verify every canonical skill has name: in frontmatter
for skill_file in .agents/skills/*/SKILL.md; do
  skill="$(basename "$(dirname "$skill_file")")"
  if ! grep -q "^name:" "$skill_file" 2>/dev/null; then
    echo "MISSING name: field in $skill_file"
    fail=1
  fi
done

# Verify .claude/skills points to .agents/skills
if [[ -L ".claude/skills" ]]; then
  target="$(readlink .claude/skills)"
  if [[ "$target" != ".agents/skills" && "$target" != "./agents/skills" && "$target" != "./.agents/skills" ]]; then
    echo "WRONG SYMLINK: .claude/skills points to $target (expected .agents/skills)"
    fail=1
  fi
elif [[ -d ".claude/skills" ]]; then
  echo "NOT A SYMLINK: .claude/skills is a directory (should be symlink to .agents/skills)"
  fail=1
fi

# Verify .codex/skills points to .agents/skills
if [[ -L ".codex/skills" ]]; then
  target="$(readlink .codex/skills)"
  if [[ "$target" != ".agents/skills" && "$target" != "./agents/skills" && "$target" != "./.agents/skills" && "$target" != "../.agents/skills" ]]; then
    echo "WRONG SYMLINK: .codex/skills points to $target (expected .agents/skills)"
    fail=1
  fi
elif [[ -d ".codex/skills" ]]; then
  echo "NOT A SYMLINK: .codex/skills is a directory (should be symlink to .agents/skills)"
  fail=1
fi

# Verify AGENTS.md exists
[[ -f "AGENTS.md" ]] || { echo "MISSING: AGENTS.md"; fail=1; }

# Detect lowercase claude.md (wrong casing — Claude Code requires CLAUDE.md)
if ls -1 | grep -q '^claude\.md$' 2>/dev/null; then
  echo "WRONG CASING: claude.md exists (should be CLAUDE.md)"
  if [[ "$mode" == "apply" ]]; then
    git mv claude.md CLAUDE.md 2>/dev/null || mv claude.md CLAUDE.md
    echo "FIXED: Renamed claude.md to CLAUDE.md"
  else
    fail=1
  fi
fi

# Verify CLAUDE.md is a symlink to AGENTS.md
if [[ -L "CLAUDE.md" ]]; then
  target="$(readlink CLAUDE.md)"
  if [[ "$target" != "AGENTS.md" ]]; then
    echo "WRONG SYMLINK: CLAUDE.md points to $target (expected AGENTS.md)"
    fail=1
  fi
elif [[ -f "CLAUDE.md" ]]; then
  echo "NOT A SYMLINK: CLAUDE.md is a regular file (should be symlink to AGENTS.md)"
  fail=1
else
  echo "MISSING: CLAUDE.md"
  fail=1
fi

# Verify Copilot instructions exist
[[ -f ".github/copilot-instructions.md" ]] || { echo "MISSING: .github/copilot-instructions.md"; fail=1; }

# Update Copilot instructions skill list if in apply mode
if [[ "$mode" == "apply" && -f ".github/copilot-instructions.md" ]]; then
  skill_table="| Skill | Description |\n|-------|-------------|"
  for skill_file in .agents/skills/*/SKILL.md; do
    skill="$(basename "$(dirname "$skill_file")")"
    desc=$(sed -n '/^description:/s/^description: *//p' "$skill_file" | head -1)
    skill_table="$skill_table\n| $skill | $desc |"
  done
  # Replace skill list placeholder or update existing table
  if grep -q "\[LIST_OF_SKILLS\]" ".github/copilot-instructions.md" 2>/dev/null; then
    sed -i '' "s|\[LIST_OF_SKILLS\]|$(echo -e "$skill_table")|" ".github/copilot-instructions.md"
  fi
fi

if [[ $fail -ne 0 ]]; then
  echo "Cross-agent sync FAILED"
  exit 1
fi

echo "Cross-agent sync ${mode} complete"
```

Make the script executable: `chmod +x scripts/skills/sync-cross-agent-skills.sh`

### Step 10: Generate CI Workflow

Create `.github/workflows/skills-sync.yml`:

```yaml
name: Cross-Agent Skills Sync

on:
  pull_request:
    paths:
      - 'AGENTS.md'
      - 'CLAUDE.md'
      - '.agents/skills/**'
      - '.claude/skills'
      - '.codex/skills'
      - '.github/copilot-instructions.md'
      - 'scripts/skills/**'
      - '.github/workflows/skills-sync.yml'
  push:
    branches: [main, master]
    paths:
      - 'AGENTS.md'
      - 'CLAUDE.md'
      - '.agents/skills/**'
      - '.claude/skills'
      - '.codex/skills'
      - '.github/copilot-instructions.md'
      - 'scripts/skills/**'
      - '.github/workflows/skills-sync.yml'

jobs:
  verify-skills:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Verify cross-agent skill sync
        run: bash scripts/skills/sync-cross-agent-skills.sh --check
```

### Step 11: Run Validation

Execute the sync script in check mode:

```bash
bash scripts/skills/sync-cross-agent-skills.sh --check
```

Report results. If any checks fail, explain what needs fixing and offer to fix it.

### Step 12: Summary Report

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
- [x] .codex/skills symlink
- [x] .github/copilot-instructions.md
- [x] scripts/skills/sync-cross-agent-skills.sh
- [x] .github/workflows/skills-sync.yml

### Agent Compatibility
| Agent | Discovery | Status |
|-------|-----------|--------|
| Claude Code | .claude/skills/ symlink | Ready |
| Codex | .codex/skills/ symlink | Ready |
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
