---
name: dream
description: Scheduled KB maintenance — ingest yesterday's meetings + session captures, synthesize raw notes into existing topical docs (decisions, people changes, conventions), resolve conflicts, age out stale entries, fix frontmatter and links. Translates raw data into knowledge. Runs unattended; never asks for confirmation. Use for KB maintenance, knowledge base cleanup, dream consolidation, memory hygiene, or as a scheduled daily KB pass.
allowed-tools: mcp__argus__kb_list, mcp__argus__kb_read, mcp__argus__kb_ingest, mcp__argus__kb_delete, mcp__argus-kb__kb_list, mcp__argus-kb__kb_read, mcp__argus-kb__kb_ingest, mcp__argus-kb__kb_delete, mcp__argus__kb_search, mcp__argus-kb__kb_search, mcp__granola__list_meetings, mcp__granola__get_meetings, mcp__granola__query_granola_meetings, mcp__claude_ai_Notion__notion-query-meeting-notes, mcp__claude_ai_Notion__notion-search, mcp__notion__notion-query-meeting-notes
---

# Dream — Scheduled Knowledge Base Maintenance

Audit the argus-kb knowledge base, then **apply every fix** without confirmation: ingest yesterday's meetings and session captures into the inbox, distill those raw captures into knowledge inside existing topical docs, resolve conflicting facts in favor of the most recent, archive entries that have aged out, and fix schema/link/naming violations. Dream is a scheduled task — it must never block on user input.

**Translate raw data into knowledge.** A session transcript or meeting summary is signal, not knowledge. Dream's job is to extract the durable facts (decisions, people changes, conventions, gotchas) and merge them into the topical docs that already track each subject. Filing the raw note is a fallback when nothing distillable was captured — not the goal.

## Operating principle

**Decide and apply.** Dream runs unattended. There is no human in the loop, no confirmation prompt, no "flag for manual review" backstop. When a fix is ambiguous, make the best-available judgment, apply it, and log the decision in the report. The report is the audit trail; the KB itself is the result.

The only escape hatch is `--dry-run` for previewing what dream *would* do.

## Arguments

- `$ARGUMENTS` — Optional flags and scoping:
  - `--dry-run` — report all proposed actions without applying them (the only mode that does not write to the KB)
  - A path prefix (no leading `--`) to scope the audit (e.g. `work/`)

## Context

- Argus KB available: !`command -v argus 2>/dev/null | head -1`
- Recent changes since last dream run: !`tail -100 ~/.dots/sys/kb-changes/changes.jsonl 2>/dev/null | head -100`
- Last dream run: !`ls -t ~/.dots/sys/dream-runs 2>/dev/null | head -1`
- Today's date: !`date +%Y-%m-%d`

## MCP tool naming

The Argus KB MCP server is registered as `argus` (current) or `argus-kb` (legacy). Use whichever tool name the harness exposes — try `mcp__argus__*` first, fall back to `mcp__argus-kb__*` if the first returns tool-not-found.

## Instructions

Run the eight phases below in order. Apply every fix. Never prompt for confirmation.

- If `$ARGUMENTS` contains `--dry-run`, replace every "apply" step with "report what would change." This is the only short-circuit on writes.
- If the change log (`~/.dots/sys/kb-changes/changes.jsonl`) shows no writes since the timestamp of the last successful dream run (latest file under `~/.dots/sys/dream-runs/`), exit immediately with an empty report — saves work when the KB is quiet.
- If `$ARGUMENTS` contains a bare path prefix, pass it to `kb_list` as the prefix filter to scope the audit. The triage and decay phases still scan their respective folders (`memory/inbox/`, full vault) regardless.

### Phase 0: Ingest (Meetings + Sessions)

Pull yesterday's signal into `memory/inbox/` so the rest of dream can synthesize it. Skip silently when an upstream is unavailable — meetings are best-effort signal, not a hard dependency.

1. **Granola meetings.** If `mcp__granola__list_meetings` is available, call it with `time_range: "last_day"`. If the result is empty for a day you know had meetings, retry with `this_week` — Granola's `query_granola_meetings` regularly false-negatives on same-day captures, so `list_meetings` is the more reliable discovery primitive. If the tool returns tool-not-found, skip silently. For each meeting:
   - Skip if `memory/inbox/` already contains a doc with the meeting ID in the slug (idempotent on re-runs).
   - Fetch summary + AI notes via `get_meetings(meeting_ids=[id])`.
   - Write a raw inbox doc at `memory/inbox/<YYYY-MM-DD>-meeting-<short-id>-<slug>.md` with:
     - `tags: [meeting-capture, granola, <project-or-person-tag>]`
     - Body: meeting title, attendees, AI notes, any decisions/action items the AI surfaced.
2. **Notion meeting notes.** If `mcp__claude_ai_Notion__notion-query-meeting-notes` (or the cortex Notion equivalent) is available, query for yesterday's meeting notes. Same dedupe + write pattern, tag with `meeting-capture, notion`. If the tool returns tool-not-found, skip silently and proceed to step 3.
3. **Session captures already in inbox.** The `session-end-capture` hook writes session summaries directly into `memory/inbox/` as Claude Code sessions wrap up. Don't re-fetch — these are already on disk before dream starts and will be processed in Phase 3.
4. Don't synthesize here. Phase 0's only job is to land raw captures in the inbox so Phase 3 can distill them. If meeting fetch fails entirely (no MCP, network down, daemon offline), proceed without it; subsequent phases still run on whatever is already in the inbox.

### Phase 1: Orient

1. Call `kb_list` (with prefix filter if provided) to get all document paths.
2. Group paths by top-level folder.
3. Note the total document count for the summary.
4. Collect every filename (basename without `.md`) into a map for the duplicate-filename check used in Phase 2.

### Phase 2: Gather Signal

Read every document with `kb_read` and check each against these rules. If the vault has more than 50 documents, warn the user and process in batches of 20, reporting progress after each batch.

Rules from the kb_ingest schema:

**Frontmatter (required)**
- Has YAML frontmatter between `---` fences
- Has `title` field (non-empty string)
- Has `tags` field (non-empty array of lowercase strings)

**Content structure**
- Leads with a key insight sentence (first line after frontmatter is not a heading)
- Uses `## H2` for subtopics (not H1 or H3 as top-level sections)
- Bolds key terms in bullet lists (flag for manual attention if missing — do not auto-fix)

**Size and scope**
- Word count is between 50 and 500 words (body only, excluding frontmatter)
- Covers one topic per document (flag if multiple unrelated H2 sections suggest distinct topics)

**Path conventions**
- Filename is kebab-case (lowercase, hyphens, no spaces or underscores)
- Organized in a topic folder (not at vault root)
- Folder nesting is at most 2 levels deep

**Internal links**
- Cross-references to other KB docs use Obsidian wikilinks, not markdown links or bold paths
- Valid: `[[filename]]`, `[[filename|display text]]`, `[[filename#heading]]`, `[[filename#heading|display text]]`
- Invalid: `[text](folder/file.md)`, `**folder/file.md**`, bare `folder/file.md` references to other KB docs
- Wikilinks omit the file extension and folder path — Obsidian resolves by filename if unique
- Embeds (`![[filename]]`) are valid for embedding another doc's content

**Tag hygiene**
- All tags must be in YAML frontmatter `tags: [...]` array only
- No inline `#hashtags` in the document body — these fragment tag management and break search
- Tags must be lowercase kebab-case (e.g. `engineering`, `tech-stack`, not `TechStack` or `tech_stack`)

**Vault integrity**
- No duplicate filenames across the vault — duplicates cause ambiguous wikilink resolution (collect all filenames during Phase 1 and flag collisions)
- No orphan notes — every doc should have at least one outgoing wikilink OR at least one incoming wikilink from another doc (build a link graph during Phase 2 by tracking all wikilink targets)

**Redirects**
- If tags contain "redirect", skip all other checks EXCEPT: internal links, tag hygiene, and vault integrity — redirects must still use wikilinks, have clean tags, and not be orphaned

Record each violation with: document path, rule violated, current value, and suggested fix.

### Phase 3: Triage & Synthesize Inbox

The inbox holds raw captures from `/improve`, the `session-end-capture` hook (committed work), and Phase 0's meeting ingest. Goal: **extract durable knowledge into existing topical docs**, not just file the raw note.

**Process order** (highest synthesis value first):
1. Captures tagged `high-value, commit-merged` — work that shipped to main/master. These had verified outcomes; their facts have the highest credibility.
2. Captures tagged `meeting-capture` — decisions, people changes, action items.
3. Captures tagged `session-capture, work-in-progress` — record intent + files touched, but discount unverified claims.
4. Everything else (legacy `/improve` captures).

For each inbox doc:

1. The full content is already in memory from Phase 2 — re-read via `kb_read` only if truncated.
2. Run `kb_search` on the doc's key entities (project names, people, tools, file paths, decisions) to surface candidate target docs.
3. **Synthesize first.** Walk the body and extract durable items into one of these shapes:
   - **Decision** ("we decided to use X for Y") → merge into the relevant project doc as a `## Decision: <topic>` section, with a one-line rationale. If a previous decision on the same topic exists, mark it superseded (Phase 4 mechanics) and link to the new one.
   - **People fact** (role change, joined team, scope shift, area of ownership) → update the relevant `<org>/people-*` or `memory/people/` doc. Add `Previously: <old> — superseded <date>` if it overrides existing data.
   - **Convention / pattern** (a way the team does something, a gotcha, a workflow rule) → merge into `patterns/` or the closest existing convention doc. Cross-link with `[[wikilinks]]`.
   - **Action item** with a clear owner + deadline → if it's a recurring task or a follow-up that maps to an existing project doc, append a `## Open Action Items` section. Otherwise skip — action items rot fast and a stale "follow up next week" entry is noise.
   - **Tool / vendor evaluation** → merge into the existing `vendor-evaluations` (or equivalent) doc, or the tool's dedicated doc. Use `[[wikilinks]]` for cross-references.
4. **For each fact merged, run a conflict check** before writing: does this contradict an existing fact in the target doc? If yes, apply the supersession pattern from Phase 4 (canonical = newest, mark prior as historical).
5. After synthesis is done, decide what to do with the raw inbox capture:
   - **All durable content distilled** (most session-capture and meeting-capture docs) → `kb_delete` the inbox source. The knowledge survives in topical docs; the raw inbox note was scaffolding. The original Claude Code session transcript at `transcript_path` (typically `~/.claude/projects/<project-slug>/<session-id>.jsonl`) is unaffected and remains the ground-truth recovery path if synthesis later turns out to have missed something.
   - **Some content distilled, some narrative left** (long meeting with backstory worth preserving) → re-file the raw to `memory/archive/meetings/<date>-<slug>.md` instead of deleting; the topical docs cite back to it via wikilink.
   - **Nothing distillable** (genuinely raw observation that needs a home but doesn't update an existing topic) → fall through to the routing rules below and re-file as a new topical doc.
   - **Too degraded to classify** (empty body, malformed frontmatter that can't be salvaged) → **Hold** in inbox, note path in the report.

**Routing rules** (when synthesis didn't apply and the doc needs a new home — apply in order, first match wins):
1. Frontmatter `tags` contain a clear domain tag matching an existing top-level folder (e.g. `homelab`, `tools`, `patterns`, `health`, `home`, `personal`, or any user-defined domain folder) → match that folder.
2. Tags include `user` / `preference` → `memory/user/<topic>.md`.
3. Tags include `feedback` / `correction` → `memory/feedback/<topic>.md`.
4. Tags include `project` or title references a project name → `memory/project/<topic>.md`.
5. Tags include `reference` / `lookup` → `memory/reference/<topic>.md`.
6. Otherwise: pick the topical folder whose existing docs best match (by tag overlap or kb_search neighborhood) — when in doubt, default to `memory/reference/`.

When choosing a filename, follow the existing schema (kebab-case, 2-3 words, topic noun). Strip the date prefix from inbox filenames before re-filing.

Apply every triage and synthesis decision immediately. Do not batch and confirm. The "Hold" path is the rare escape hatch for unsalvageable docs; in normal operation every inbox doc either contributes facts to existing docs (and is deleted) or becomes a new topical doc.

**Be ruthless about discarding low-signal content.** A session capture that just says "edited a few files" with no decision, no convention, no people fact contributes nothing durable — delete the raw without re-filing. The inbox shouldn't become a graveyard of low-value captures.

### Phase 4: Conflict Detection & Supersession

Find docs that contradict each other and reconcile in favor of the most recently modified entry. Uses the link graph and clusters from Phase 2.

1. Build clusters of related docs:
   - Group by tag overlap (≥2 shared tags AND same top-level folder).
   - Within each cluster, scan bodies for **contradicting facts** — same entity/topic with different values (e.g. one doc says "X uses Postgres", another says "X uses MySQL"; one lists a role as "engineer", another as "manager").
2. For each conflict:
   - Identify the **canonical** doc — the one most recently modified (use the `Modified` line in the doc body or YAML, fall back to `kb_list` modification timestamp).
   - Identify the **superseded** doc(s).
3. Reconciliation strategy:
   - If the conflict is a **fact update** (e.g. role changed, version changed, vendor switched): update the canonical doc to mention the prior value as historical context (`Previously: <old value> — superseded <date>`), then mark the superseded doc with a `superseded_by: [[canonical-doc]]` field in frontmatter and add the `redirect` tag (existing dream rules already handle redirects).
   - If the conflict is a **near-duplicate** (same topic, slightly different framing): merge content into the canonical doc, mark the other as redirect.
   - If unsure whether two docs actually conflict (different scopes, complementary not contradictory): **do not merge** — flag in the report for manual review.

Apply every reconciliation. For unambiguous contradictions (same key, different value) use the fact-update or near-duplicate strategy directly. For ambiguous cases (different scopes, complementary framing, unclear which is canonical), pick the most recently modified doc as canonical, integrate any non-overlapping content from the older doc into it, mark the older as redirect, and note the merge in the report. Don't leave conflicts on the floor — picking one is better than picking neither.

### Phase 5: Decay & Archive

Age out entries that are stale and add little ongoing value. Uses the link graph from Phase 2 and the supersession data from Phase 4.

1. For every doc not in `memory/archive/` and not tagged `redirect`:
   - Compute age = today − Modified date.
   - Look up incoming wikilinks from the Phase 2 link graph.
   - Look up outgoing wikilinks from the Phase 2 link graph.
2. Decay decision tree (apply first match):
   - Age > 365 days AND zero incoming wikilinks AND no entry in `~/.dots/sys/kb-changes/changes.jsonl` for this path in the last 90 days (i.e. not written to recently — read activity is not tracked) → **archive**.
   - Age > 180 days AND superseded by a newer doc (from Phase 4) → **archive** (the supersession redirect remains as a pointer).
   - Age > 180 days AND tagged with a project that has been closed/migrated (heuristic: project name appears in `memory/archive/` already) → **archive**.
   - Otherwise → keep.
3. To archive: move the doc to `memory/archive/<original-path-without-memory-prefix>` via `kb_ingest` at the new path + `kb_delete` at the old path. Preserve all frontmatter and content; add an `archived: <date>` line to the body.
4. **Never delete outright** — archive only. Archive is recoverable; deletion is not.
5. If Phase 4 was skipped (e.g. due to a scoped audit), skip the supersession-based decay rule and apply only the link-graph and closed-project rules.

Apply every archive decision immediately. The archive folder itself is the recovery mechanism; if a future run mis-archived something, a separate manual restore is the path.

### Phase 6: Consolidate (Apply Fixes)

Apply every hygiene fix from Phase 2's violation list. No confirmation gate. The fix table below covers the full surface — there is no "safe vs. unsafe" split: dream applies all of them.

| Violation | Auto-fix |
|-----------|----------|
| Missing frontmatter | Generate frontmatter from filename and content, then kb_ingest the updated doc |
| Missing title | Derive from filename (kebab-case to Title Case), add to frontmatter |
| Missing tags | Derive 2-3 tags from folder name and content keywords |
| Missing lead insight | Prepend a one-sentence summary before the first heading |
| Word count under 50 | Flag for manual attention — do NOT auto-fix stubs |
| Word count over 500 | Flag for manual attention with a suggested split plan (list proposed new docs) |
| Wrong heading level | Replace H1/H3 top-level sections with H2 |
| Markdown links to KB docs | Convert `[text](folder/file.md)` to `[[file\|text]]` |
| Bold path references | Convert `**folder/file.md**` to `[[file]]` |
| Wikilinks with extensions | Convert `[[file.md]]` to `[[file]]` |
| Wikilinks with folder paths | Convert `[[folder/file]]` to `[[file]]` only when the filename is unique across the vault — if duplicates exist, keep the path for disambiguation |
| Inline hashtags | Move `#tag-name` from body into frontmatter `tags` array, remove from body text |
| Uppercase/underscore tags | Normalize to lowercase kebab-case in frontmatter (e.g. `TechStack` becomes `tech-stack`) |

For each fix applied, call `kb_ingest` with the corrected document. Preserve all existing content — only add or adjust metadata and structure.

**Apply with judgment** (these need a decision; make one):

- **Oversized docs (>500 words)** — split along the existing `## H2` boundaries. Each H2 section becomes its own doc named after the section topic; cross-link with wikilinks. If H2s are too small to stand alone, group adjacent H2s into a topical sibling doc.
- **Path/naming violations** — rename to the canonical kebab-case noun. Update incoming wikilinks across the vault to point at the new path. If a rename would collide with an existing doc, suffix with the topic context (e.g. `metrics-thanx.md` vs `metrics-personal.md`).
- **Multi-topic docs** — same split strategy as oversized; pick the highest-level cut (top H2s) rather than fragmenting further than necessary.
- **Stub docs under 50 words** — leave them. Stubs are often placeholders for soon-to-arrive content; deleting them risks losing intent. Note them in the report so they can be revisited.
- **Ambiguous bare-text references** — convert to a wikilink to the closest-matching doc when there's a clear single match, otherwise leave as-is. Don't break working text in pursuit of theoretical link consistency.
- **Duplicate filenames** — keep the most recently modified doc at the original filename. Rename the older one with a `-legacy` suffix and add a `superseded_by: [[newer]]` field plus the `redirect` tag. Update incoming wikilinks to point at the canonical doc.
- **Orphan notes** — add an outgoing wikilink to the closest topic neighbor (highest tag overlap from the link graph). If no neighbor scores above a noise threshold, add it to the most relevant index/MOC doc in the same folder. If no MOC exists in the folder, leave the orphan and note it.

### Phase 7: Report

Always write the report to `memory/dream/<YYYY-MM-DD>-report.md` (via `kb_ingest`) and append a one-line summary to `~/.dots/sys/dream-runs/<YYYY-MM-DD>.log` so the next scheduled run can find the timestamp of this one. Print the same content to stdout as well so the agent log shows what changed.

Use this structure:

```
## KB Hygiene Report

**Scanned:** N documents
**Healthy:** N documents (no violations)
**Fixed:** N documents
**Held in inbox:** N documents (only when classification was impossible — see Phase 3)

### Fixes Applied
| Document | Fix Applied |
|----------|------------|
| path | what was fixed |

### Judgment Calls
For decisions made under "Apply with judgment" (oversized/multi-topic splits, naming renames, orphan link choices, duplicate filename resolution). Audit trail for the next dream run or a human spot-check.

| Document | Decision | Rationale |
|----------|----------|-----------|
| path | what was done | why this option vs. the alternative |

### Redirects Skipped
- path (N total)

### Duplicate Filenames
| Filename | Paths |
|----------|-------|
| name | folder1/name.md, folder2/name.md |

(Omit section if no duplicates found)

### Orphan Notes
| Document | Links Out | Links In |
|----------|-----------|----------|
| path | 0 | 0 |

(Omit section if no orphans found)

### Link Graph
- Total wikilinks: N
- Docs with outgoing links: N / N total
- Docs with incoming links: N / N total
- Most linked-to: path (N incoming)

### Stats
- Smallest doc: path (N words)
- Largest doc: path (N words)
- Average doc size: N words
- Folders: list of top-level folders with doc counts
```

If `--dry-run` was specified, label the report "KB Hygiene Report (Dry Run)" and note that no changes were made.

#### Extra report sections (Phases 0, 3-5)

Add these sections to the report — they cover ingest, triage/synthesis, conflicts, and decay:

```
### Ingested (Phase 0)
| Source | Count | Notes |
|--------|-------|-------|
| granola | N | yesterday's meetings, deduped against existing inbox |
| notion | N | yesterday's meeting notes |
| session-end hook | N | session captures already on disk |

### Inbox Triage & Synthesis (Phase 3)
| Inbox Doc | Tags | Action | Knowledge Distilled Into |
|-----------|------|--------|-------------------------|
| memory/inbox/<doc> | high-value, commit-merged | synthesize+delete | patterns/dev-tools.md (new convention), memory/project/foo.md (decision) |
| memory/inbox/<doc> | meeting-capture | synthesize+archive | memory/people/engineering.md (role change) |
| memory/inbox/<doc> | session-capture, work-in-progress | discard | nothing distillable |
| memory/inbox/<doc> | <tags> | re-file | <new path> |
| memory/inbox/<doc> | <tags> | hold | (kept in inbox — too degraded) |

### Conflicts Resolved (Phase 4)
| Topic | Canonical | Superseded | Strategy |
|-------|-----------|------------|----------|
| <topic> | path | path | fact-update / dedupe / merged-ambiguous |

### Aged Out (Phase 5)
| Doc | Age (days) | Reason | Action |
|-----|-----------|--------|--------|
| path | N | no incoming links / superseded / closed project | archived |
```

## Scheduling

`/dream` is the unattended mode by default. Wire it into Argus scheduled tasks (or any cron) at a low-activity hour. Each run:

- Triages the inbox, resolves conflicts, ages out stale entries, fixes hygiene violations — all without prompting.
- Writes the report to `memory/dream/<date>-report.md` and `~/.dots/sys/dream-runs/<date>.log`.
- Skips work entirely if `~/.dots/sys/kb-changes/changes.jsonl` shows no writes since the previous run (see Instructions preamble).

For interactive previews use `/dream --dry-run` — that's the only mode that does not write to the KB.

### Obsidian Internal Link Reference

The KB is an Obsidian vault. All cross-references between docs MUST use Obsidian internal links (wikilinks). When auditing or fixing docs, apply these rules:

**Supported wikilink syntax:**

| Syntax | Purpose |
|--------|---------|
| `[[filename]]` | Link to another doc (no extension, no folder path) |
| `[[filename\|display text]]` | Link with custom display text |
| `[[filename#heading]]` | Link to a specific heading in another doc |
| `[[filename#heading\|display text]]` | Heading link with display text |
| `[[#heading]]` | Link to a heading in the same doc |
| `![[filename]]` | Embed (transclude) another doc inline |
| `![[filename#heading]]` | Embed a specific section from another doc |

**Resolution rules:**
- Omit the `.md` extension — Obsidian adds it automatically
- Omit the folder path — Obsidian resolves by filename if unique across the vault
- If filenames collide, use the shortest unambiguous path (e.g. `[[thanx/people-cs]]`)

**Patterns to flag and fix:**
- Markdown links to KB docs: `[text](folder/file.md)` should be `[[file\|text]]`
- Bold path references: `**folder/file.md**` should be `[[file]]`
- Wikilinks with extensions: `[[file.md]]` should be `[[file]]`
- Wikilinks with unnecessary paths: `[[folder/file]]` should be `[[file]]` (when filename is unique)
- Bare inline paths: `See thanx/people-cs.md` should be `See [[people-cs]]`

**Do NOT convert:**
- External URLs (`https://...`) — these are not internal links
- Code blocks or inline code containing paths — these are literal references
- Paths referencing files outside the KB vault
