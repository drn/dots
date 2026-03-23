# Phase Protocol

Skills in the development sprint chain write and read **phase artifacts** so downstream skills have full context from prior phases. This protocol defines the convention.

## Phase Chain

```
think → critique → plan → build → review → test → ship → land
```

| Phase | Skill | Reads (latest of each) | Writes |
|-------|-------|------------------------|--------|
| `think` | `/plan` | — | `think-{ts}.md` |
| `critique` | `/devils-advocate` | `think-*.md` | `critique-{ts}.md` |
| `plan` | `/plan` | `think-*.md`, `critique-*.md` | `plan-{ts}.md` |
| `build` | `/dev` | `plan-*.md` | `build-{ts}.md` |
| `review` | `/review` | `plan-*.md`, `build-*.md` | `review-{ts}.md` |
| `test` | `/test` | `build-*.md` | `test-{ts}.md` |
| `ship` | `/pr` | all prior artifacts | `ship-{ts}.md` |
| `land` | `/merge` | `ship-*.md` | `land-{ts}.md` |

## Artifact Directory

```
.context/phases/
```

Create with `mkdir -p .context/phases` before writing. This directory is per-worktree and gitignored.

## Naming Convention

```
{phase}-{YYYYMMDD-HHmmss}.md
```

Example: `think-20260322-143022.md`, `plan-20260322-150530.md`

Generate timestamp with: `date +%Y%m%d-%H%M%S`

## Reading Prior Artifacts

To find the latest artifact for a phase:

```bash
ls -t .context/phases/{phase}-*.md 2>/dev/null | head -1
```

If no artifact exists for an upstream phase, skip it — phase context is **additive, never mandatory**. Every skill must work standalone without prior artifacts.

## Writing Artifacts

Every phase artifact uses this format:

```markdown
# Phase: {phase_name}
**Skill:** /{skill-name}
**Branch:** {branch}
**Timestamp:** {YYYY-MM-DD HH:mm:ss}
**Prior artifacts:** {comma-separated list of files consumed, or "none"}

---

## Summary
{1-3 sentences: what this phase produced}

## Detail
{Full phase output — plan content, review findings, test results, etc.}

## Handoff
{What downstream phases need to know — key decisions, open questions, blockers}
```

The **Handoff** section is critical — it distills what the next phase needs, reducing context window noise. Write it as if briefing a colleague who hasn't seen any of your work.

## Iteration

The system supports natural iteration. If `/review` says "needs changes," run `/dev` again — it writes a new `build-{ts}.md` with a later timestamp. The next `/review` picks up the latest. No special loop logic needed.

## Archive (optional)

After `/merge` completes, optionally move artifacts to preserve history:

```bash
mkdir -p .context/phases/archive/{branch}-{ts}
mv .context/phases/*.md .context/phases/archive/{branch}-{ts}/
```
