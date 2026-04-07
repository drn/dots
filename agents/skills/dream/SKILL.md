---
name: dream
description: Audit and fix knowledge base hygiene — missing frontmatter, oversized docs, naming violations, stale redirects. Use for KB maintenance, knowledge base cleanup, dream consolidation, or memory hygiene.
allowed-tools: mcp__argus-kb__kb_list, mcp__argus-kb__kb_read, mcp__argus-kb__kb_ingest, mcp__argus-kb__kb_search
---

# Dream — Knowledge Base Hygiene

Audit all documents in the argus-kb knowledge base against the documented schema, identify violations, auto-fix what is safe, and report what needs manual attention.

## Arguments

- `$ARGUMENTS` - Optional: `--dry-run` to report violations without fixing, or a path prefix to scope the audit (e.g. `thanx/`)

## Context

- KB doc count: !`echo "Use kb_list to get actual count at runtime"`

## Instructions

Run the four phases below in order. If `$ARGUMENTS` contains `--dry-run`, skip all fix steps and only report violations.

If `$ARGUMENTS` contains a path prefix (no leading `--`), pass it to kb_list as the prefix filter to scope the audit.

### Phase 1: Orient

1. Call `kb_list` (with prefix filter if provided) to get all document paths
2. Group paths by top-level folder
3. Note the total document count for the summary

### Phase 2: Gather Signal

Read every document with `kb_read` and check each against these rules from the kb_ingest schema:

**Frontmatter (required)**
- Has YAML frontmatter between `---` fences
- Has `title` field (non-empty string)
- Has `tags` field (non-empty array of lowercase strings)

**Content structure**
- Leads with a key insight sentence (first line after frontmatter is not a heading)
- Uses `## H2` for subtopics (not H1 or H3 as top-level sections)
- Bolds key terms in bullet lists

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

### Phase 3: Consolidate (Auto-Fix)

For each violation, apply the fix if it is safe. Safe fixes:

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
| Wikilinks with folder paths | Convert `[[folder/file]]` to `[[file]]` (Obsidian resolves by filename) |
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

### Phase 4: Report

Print a structured summary:

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
