# Improve Skills & Commands

Analyze the current conversation to identify learnings, friction points, and improvements for all skills and commands that were used during the session.

## When to Use

Run `/improve` at the end of any session where:
- Skills were invoked and required manual fixes or workarounds
- You discovered better patterns or approaches mid-conversation
- A skill's output needed multiple iterations to get right
- Technical assumptions in a skill turned out to be wrong
- You learned something that would make a skill work better next time

## Instructions

When `/improve` is invoked:

### Step 1: Identify Skills Used

Scan the full conversation for:
- Explicit skill invocations (`/pdf`, `/capture`, `/slack`, etc.)
- Implicit skill-like patterns (e.g., PDF generation even without `/pdf`, data export workflows)
- CLAUDE.md instructions that were followed or should have been followed
- Recurring manual steps that could be codified into a skill

List each skill used with a brief note on what it did in this session.

**Note:** If improvements were already applied earlier in the same session (e.g., from manual fixes or a prior `/improve` run), skip those and only propose net-new changes.

### Step 2: Extract Learnings per Skill

For each skill identified, analyze:

1. **What worked well** — smooth execution, no issues
2. **Friction points** — where did the user need to iterate, correct, or re-run?
3. **Technical discoveries** — new knowledge about how the underlying tool/script works
4. **Incorrect assumptions** — anything the skill file says that turned out wrong
5. **Missing capabilities** — things the user asked for that the skill didn't cover

### Step 3: Propose Improvements

For each skill with learnings, draft specific changes:

- **Fix factual errors** (e.g., wrong library name, outdated API)
- **Add learned patterns** (e.g., "when exporting tables, use proportional column widths")
- **Add missing instructions** (e.g., "can also accept `--input` flag for existing files")
- **Add troubleshooting tips** (e.g., "if tables show whitespace, check for multi_cell usage")
- **Suggest new skills** if a recurring pattern doesn't have one yet

### Step 4: Present Changes

Show each proposed change as a before/after diff for the user to review:

```
## /pdf — 3 improvements

### 1. Fix library name (factual error)
Technical Notes says "weasyprint" but script uses "fpdf2"

### 2. Add --input flag documentation (missing capability)
Add note that existing markdown files can be passed directly

### 3. Add table rendering notes (learned pattern)
Document proportional column widths and link rendering
```

### Step 5: Apply Approved Changes

After presenting all proposals:
1. Ask the user which changes to apply (default: all)
2. Edit the skill files with the approved changes
3. Summarize what was updated

### Step 6: Check for New Skill Opportunities

Look for patterns in the session that aren't covered by any existing skill:
- Multi-step workflows that were done manually
- Data export/analysis patterns
- Integration patterns with MCP tools

If found, propose a new skill with a brief description of what it would do.

## What NOT to Improve

- Don't add session-specific details (specific file paths, query results)
- Don't bloat skills with edge cases that won't recur
- Don't change the fundamental purpose or structure of a skill
- Don't add improvements based on speculation — only from actual session experience

## Example Output

```
# Session Improvement Report

## Skills Used
1. `/pdf` — Exported clawback analysis to PDF (3 iterations)
2. `/capture` — Captured org context and knowledge graph facts

## Proposed Improvements

### /pdf — 3 changes

1. **Fix: Library name** — Technical Notes says "weasyprint" → should be "fpdf2"
2. **Add: Input file flag** — Document `--input` for existing markdown files
3. **Add: Table tips** — Note about proportional widths for wide tables

### /capture — 1 change

1. **Add: Merchant knowledge pattern** — When capturing merchant-specific
   facts, check merchant-accounts.md first

### New Skill Proposal: /export-csv

Recurring pattern: query production replica, aggregate data, export CSV
to ~/Downloads. Would standardize column naming, add verification step.

## Apply all? (y/n)
```

## Guidelines

- Be specific about what changed and why
- Link improvements to actual friction in the session
- Prefer small, targeted changes over rewrites
- Every improvement should have a clear "this would have saved time because..."
