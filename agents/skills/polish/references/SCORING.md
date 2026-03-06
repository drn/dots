# Scoring and Prioritization Framework

Used in Phase 2 to consolidate and prioritize findings from all four analyzers.

## Scoring Axes

| Axis | Weight | Scoring |
|------|--------|---------|
| **Impact** | 3x | How much does this hurt readability, maintainability, or correctness? |
| **Frequency** | 2x | Is this a one-off or a pattern repeated throughout the codebase? |
| **Effort** | 1x | How hard is the fix? (Inverse: easy fixes score higher) |

Priority = (Impact x 3) + (Frequency x 2) + (Ease x 1)

## Refactoring Batches

```
Batch 1 (Quick Wins): HIGH impact + LOW effort
  → Naming fixes, magic value extraction, dead code removal, guard clauses
Batch 2 (Core Refactors): HIGH impact + MEDIUM effort
  → Extract Method, Extract Class, Introduce Service Object, fix SOLID violations
Batch 3 (Structural): HIGH impact + HIGH effort
  → Redesign class hierarchies, replace conditionals with polymorphism, split god objects
Batch 4 (Polish): LOW impact
  → Style improvements, minor idiom fixes, optional extractions
```

## Report Template

```markdown
# Clean Code Analysis Report

## Scope
{files analyzed, line count}

## Health Score: {X}/100
Based on: structure ({score}), design ({score}), smells ({score}), idioms ({score})

## Critical Findings ({count})
{Numbered list: file, line, issue, suggested fix -- CRITICAL severity only}

## Summary by Category

| Category | Findings | Critical | High | Medium | Low |
|----------|----------|----------|------|--------|-----|
| Structure & Size | {n} | {n} | {n} | {n} | {n} |
| Design & SOLID | {n} | {n} | {n} | {n} | {n} |
| Smells & Duplication | {n} | {n} | {n} | {n} | {n} |
| Language Idioms | {n} | {n} | {n} | {n} | {n} |

## Refactoring Plan

### Batch 1: Quick Wins ({count} items, ~{estimate} lines changed)
{Numbered list with file, line, issue, technique}

### Batch 2: Core Refactors ({count} items)
{Numbered list}

### Batch 3: Structural Changes ({count} items)
{Numbered list}

### Batch 4: Polish ({count} items)
{Numbered list}

## Proceed with refactoring? (all / batch N / specific items / none)
```
