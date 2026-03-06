---
name: spike
description: Time-boxed technical investigation with structured findings document, tech spike, research spike, proof of concept. Use for time-boxed research, technical spikes, or proof of concept work.
---

# Technical Spike

Structured, time-boxed technical investigation that produces a findings document with clear recommendations.

## Arguments

- `$ARGUMENTS` - Required: the question, hypothesis, or topic to investigate

## Context

- Project type: !`find . -maxdepth 1 \( -name go.mod -o -name Gemfile -o -name package.json -o -name Cargo.toml -o -name pyproject.toml -o -name CLAUDE.md -o -name AGENTS.md \) 2>/dev/null | head -10`
- Directory structure: !`find . -maxdepth 2 -type d -not -path './.git/*' -not -path './node_modules/*' -not -path './vendor/*' 2>/dev/null | head -30`
- Recent commits: !`git log --oneline -10 2>/dev/null | head -10`
- Prior spikes: !`find .context/spikes -name "*.md" 2>/dev/null | head -10`

## Instructions

### Step 1: Define the investigation

Parse `$ARGUMENTS` to extract:
- **Question:** What are we trying to answer?
- **Hypothesis:** What do we expect to find? (if applicable)
- **Scope:** What parts of the codebase or external resources are relevant?

IF `$ARGUMENTS` is empty or unclear, ask the user to clarify before proceeding.

Present the investigation scope and ask for confirmation:

```markdown
**Question:** <parsed question>
**Hypothesis:** <if any>
**Scope:** <files, directories, or external resources to examine>
**Boundaries:** Max 50 files, 4 directory levels deep
```

### Step 2: Investigate

Explore the codebase and relevant resources systematically:

1. **Read existing code** — Search for relevant files, functions, and patterns. Use Glob and Grep to find related code.
2. **Trace dependencies** — Follow imports, function calls, and data flow.
3. **Check prior art** — Look at recent commits and prior spikes for related work.
4. **Prototype if needed** — Write small test scripts or code samples to validate assumptions. Keep prototypes minimal.

Track findings as you go. After each round of investigation, assess:
- Did this round produce new insights?
- Are there remaining unknowns?

IF 3 consecutive investigation rounds produce no new findings, move to Step 3 with what you have.

### Step 3: Write findings document

Create the findings document at `.context/spikes/<date>-<slug>.md` where `<date>` is today in YYYY-MM-DD format and `<slug>` is a short kebab-case summary.

Ensure `.context/spikes/` directory exists first (create if needed).

Use this format:

```markdown
# Spike: <title>

**Date:** <YYYY-MM-DD>
**Question:** <what we investigated>
**Status:** Complete

## Summary

<2-3 sentence executive summary of findings and recommendation>

## Background

<current state, why this investigation was needed, any prior art>

## Findings

### <Finding 1 heading>
<detailed findings with code references, file paths, and evidence>

### <Finding 2 heading>
<more findings>

## Recommendation

<clear recommendation based on findings: proceed, do not proceed, or needs more investigation>

**Confidence:** High / Medium / Low
**Effort estimate:** S / M / L / XL

## Open Questions

- <unresolved question 1>
- <unresolved question 2>

## Next Steps

- [ ] <concrete action item>
- [ ] <concrete action item>
```

### Step 4: Report

Print the findings summary and the file path where the full document was saved. Offer to:
1. Print the full document
2. Copy to clipboard
