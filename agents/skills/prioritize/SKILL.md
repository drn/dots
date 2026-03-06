---
name: prioritize
description: "RICE-scored backlog prioritization. Use for sprint planning, feature prioritization, or backlog grooming."
---

# Backlog Prioritization

Score and rank a list of work items using the RICE framework, then produce a prioritized backlog ready for sprint planning.

## Arguments

- `$ARGUMENTS` - Required: list of items to prioritize, OR a path to a file containing them, OR "backlog" to pull from git issues/PRs

If no arguments provided, ask the user what items to prioritize.

## Context

- Repo: !`git rev-parse --show-toplevel 2>/dev/null | grep -oE '[^/]+$' | head -1`
- Open issues: !`gh issue list --limit 20 --state open 2>/dev/null | head -20`
- Open PRs: !`gh pr list --limit 10 --state open 2>/dev/null | head -10`

## Instructions

### Step 1: Gather Items

Parse the input into a list of discrete work items. Each item needs:
- **Title**: short description
- **Source**: where it came from (user input, issue #, PR #, etc.)

If `$ARGUMENTS` is "backlog", pull from open GitHub issues and PRs.

If fewer than 3 items, ask the user if they want to add more -- RICE works best with 5+ items to compare.

### Step 2: Score Each Item (RICE)

For each item, estimate:

| Factor | Scale | How to Estimate |
|--------|-------|-----------------|
| **Reach** | Number of users/devs affected per quarter | Ask: who benefits? How many? |
| **Impact** | 0.25 (minimal), 0.5 (low), 1 (medium), 2 (high), 3 (massive) | Ask: how much does this move the needle? |
| **Confidence** | 50%, 80%, or 100% | How certain are these estimates? Use 80% as default. |
| **Effort** | Person-days (0.5 = half day, 1 = one day, etc.) | How long to implement, test, and ship? |

**RICE Score** = (Reach x Impact x Confidence) / Effort

When estimating, be conservative:
- Default Confidence to 80% unless there's strong evidence either way
- Round Effort UP (optimistic estimates are the #1 cause of missed deadlines)
- If you can't estimate Reach, ask the user -- don't guess

### Step 3: Classify (MoSCoW)

After scoring, classify each item:
- **Must** -- blocking other work or critical for users. Non-negotiable.
- **Should** -- high value, should be in this sprint if capacity allows.
- **Could** -- nice to have. Only if there's leftover capacity.
- **Won't** -- explicitly out of scope. Saying "won't" prevents scope creep.

### Step 4: Capacity Check

Ask the user:
- **Sprint duration** (default: 2 weeks)
- **Available capacity** in person-days (default: 10 per developer)

Apply the **15% buffer rule**: reserve 15% of capacity for unexpected work. Available capacity = stated capacity x 0.85.

Allocate the **20% tech debt rule**: at least 20% of sprint capacity should go to tech debt, bugs, or maintenance -- not just new features.

### Step 5: Produce the Prioritized Backlog

```markdown
## Prioritized Backlog

### Sprint Capacity
- **Duration:** {N} weeks
- **Available:** {N} person-days (after 15% buffer)
- **Tech debt allocation:** {N} person-days (20%)
- **Feature allocation:** {N} person-days (80%)

### Ranked Items

| Rank | Item | RICE | R | I | C | E | MoSCoW | Fits Sprint? |
|------|------|------|---|---|---|---|--------|--------------|
| 1 | ... | ... | . | . | . | . | Must | Yes |

### Sprint Recommendation
**Include in sprint:**
{items that fit within capacity, prioritized by RICE score, Must items first}

**Deferred:**
{items that don't fit, with brief reason}

**Won't (out of scope):**
{items explicitly excluded}

### Assumptions
{list any assumptions made during estimation}
```

Print the backlog so the user can review and adjust scores.

If the user disagrees with any score, adjust and re-rank. The user's domain knowledge overrides model estimates.
