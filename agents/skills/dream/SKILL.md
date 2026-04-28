---
name: dream
description: Audit and fix knowledge base hygiene — triage inbox captures, resolve conflicts, age out stale entries, fix frontmatter and links. Use for KB maintenance, knowledge base cleanup, dream consolidation, memory hygiene, or as a scheduled daily KB pass.
allowed-tools: mcp__argus__kb_list, mcp__argus__kb_read, mcp__argus__kb_ingest, mcp__argus__kb_delete, mcp__argus-kb__kb_list, mcp__argus-kb__kb_read, mcp__argus-kb__kb_ingest, mcp__argus-kb__kb_delete
---

# Dream — Knowledge Base Hygiene & Consolidation

Audit the argus-kb knowledge base: triage new captures from `memory/inbox/`, resolve conflicting facts in favor of the most recent, archive entries that have aged out, and fix schema/link/naming violations. Designed to run unattended as a scheduled daily task.

## Arguments

- `$ARGUMENTS` — Optional flags and scoping:
  - `--dry-run` — report all proposed actions without applying them
  - `--auto` — skip interactive confirmation prompts and apply all safe fixes (designed for scheduled runs)
  - A path prefix (no leading `--`) to scope the audit (e.g. `work/`)

## Context

- Argus KB available: !`command -v argus 2>/dev/null | head -1`
- Recent changes since last dream run: !`tail -100 ~/.dots/sys/kb-changes/changes.jsonl 2>/dev/null | head -100`
- Last dream run: !`ls -t ~/.dots/sys/dream-runs 2>/dev/null | head -1`
- Today's date: !`date +%Y-%m-%d`

## MCP tool naming

The Argus KB MCP server is registered as `argus` (current) or `argus-kb` (legacy). Use whichever tool name the harness exposes — try `mcp__argus__*` first, fall back to `mcp__argus-kb__*` if the first returns tool-not-found.

## Instructions

Run the seven phases below in order.

- If `$ARGUMENTS` contains `--dry-run`, replace every "apply" step with "report what would change."
- If `$ARGUMENTS` contains `--auto`, skip all interactive confirmation prompts; apply all safe fixes. At the end, write a summary to `memory/dream/<date>-report.md` instead of printing it interactively. This mode is designed for scheduled runs (e.g. via Argus scheduled tasks).
- If `$ARGUMENTS` contains `--auto` AND the change log (`~/.dots/sys/kb-changes/changes.jsonl`) shows no writes since the timestamp of the last successful dream run (latest file under `~/.dots/sys/dream-runs/`), exit immediately with an empty report — saves work when the KB is quiet.
- If `$ARGUMENTS` contains a bare path prefix, pass it to `kb_list` as the prefix filter to scope the audit. The triage and decay phases still scan their respective folders (`memory/inbox/`, full vault) regardless.

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

### Phase 3: Triage Inbox

The inbox holds raw captures from `/improve` (and other capture flows) that haven't been classified yet. Goal: route every inbox doc to its proper folder OR merge it into an existing entry.

1. Filter the doc list from Phase 1 down to paths under `memory/inbox/`.
2. For each inbox doc:
   - The full content is already in memory from Phase 2 — re-read via `kb_read` only if truncated.
   - Run a `kb_search` using the doc's title + key entities to find existing related entries.
   - Decide one of:
     - **Merge** — content overlaps an existing doc. Append/integrate into that doc's body, preserve frontmatter, write back via `kb_ingest` with the existing path. Then delete the inbox source via `kb_delete`.
     - **Re-file** — content is genuinely new. Determine the correct destination folder using the routing rules below, write via `kb_ingest` to the new path, then `kb_delete` the inbox copy.
     - **Hold** — too ambiguous to classify (rare). Leave in inbox and flag in the report.

**Routing rules** (apply in order, first match wins):
1. Frontmatter `tags` contain a clear domain tag matching an existing top-level folder (e.g. `homelab`, `tools`, `patterns`, `health`, `home`, `personal`, or any user-defined domain folder) → match that folder.
2. Tags include `user` / `preference` → `memory/user/<topic>.md`.
3. Tags include `feedback` / `correction` → `memory/feedback/<topic>.md`.
4. Tags include `project` or title references a project name → `memory/project/<topic>.md`.
5. Tags include `reference` / `lookup` → `memory/reference/<topic>.md`.
6. Otherwise: pick the topical folder whose existing docs best match (by tag overlap or kb_search neighborhood) — when in doubt, default to `memory/reference/`.

When choosing a filename, follow the existing schema (kebab-case, 2-3 words, topic noun). Strip the date prefix from inbox filenames before re-filing.

In `--auto` mode, apply the merge/re-file decisions without confirmation. In interactive mode, batch the proposals and confirm before applying.

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

In `--auto` mode, only auto-apply the fact-update and near-duplicate strategies when the contradiction is unambiguous (exact same key, different value). Flag everything else for the report.

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

In `--auto` mode, apply archive decisions automatically for entries that match decay rules. In interactive mode, confirm each batch.

### Phase 6: Consolidate (Auto-Fix)

Before applying any fixes, print a summary of all planned changes and ask the user for confirmation. If the user declines, treat the run as `--dry-run` for the remainder. In `--auto` mode, skip confirmation and proceed.

For each approved violation, apply the fix if it is safe. Safe fixes:

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

**Do NOT auto-fix:**
- Oversized docs (require topic judgment to split correctly)
- Path/naming violations (would change the document address)
- Multi-topic docs (require human decision on how to split)
- Stub docs under 50 words (may grow naturally)
- Ambiguous bare-text references that might refer to KB docs (flag for manual review)
- Duplicate filenames (requires deciding which doc to rename)
- Orphan notes (requires understanding the intended link structure)

### Phase 7: Report

In interactive mode, print the summary directly. In `--auto` mode, write it to `memory/dream/<YYYY-MM-DD>-report.md` (via `kb_ingest`) and also append a one-line summary to `~/.dots/sys/dream-runs/<YYYY-MM-DD>.log` so the next run can find the timestamp of the previous run.

Use this structure:

```
## KB Hygiene Report

**Scanned:** N documents
**Healthy:** N documents (no violations)
**Auto-fixed:** N documents
**Needs attention:** N documents

### Auto-Fixed
| Document | Fix Applied |
|----------|------------|
| path | what was fixed |

### Needs Manual Attention
| Document | Issue | Suggested Action |
|----------|-------|-----------------|
| path | violation | what to do |

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

#### Extra report sections (Phases 1-3)

Add these sections to the report — they cover triage, conflicts, and decay:

```
### Inbox Triage (Phase 3)
| Inbox Doc | Action | Destination |
|-----------|--------|------------|
| memory/inbox/<doc> | merge / re-file / hold | <new path or kept> |

### Conflicts Resolved (Phase 4)
| Topic | Canonical | Superseded | Strategy |
|-------|-----------|------------|----------|
| <topic> | path | path | fact-update / dedupe / flagged |

### Aged Out (Phase 5)
| Doc | Age (days) | Reason | Action |
|-----|-----------|--------|--------|
| path | N | no incoming links / superseded / closed project | archived |
```

## Scheduling

`/dream --auto` is designed to run unattended on a schedule. Use Argus scheduled tasks to run it daily — for example, set the daemon to invoke `/dream --auto` at a low-activity hour. The `--auto` flag:

- Skips all interactive confirmations
- Applies safe fixes (frontmatter, link conversion, tag normalization, inbox triage, unambiguous conflict resolution, aging-out under decay rules)
- Writes the report to `memory/dream/<date>-report.md` instead of stdout
- Logs run completion to `~/.dots/sys/dream-runs/<date>.log`

The "skip if no writes since last run" guard is enforced by the Instructions preamble — see the bullet under `## Instructions`.

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
