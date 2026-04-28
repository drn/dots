# Argus KB Capture Reference

Detailed instructions for `/improve` Step 0a (load) and Step 8 Part 0 (capture). The main SKILL.md keeps a brief pointer; everything in this file is loaded on demand when Argus KB is available.

## MCP tool naming

The Argus KB MCP server is registered as `argus` (current) or `argus-kb` (legacy). Try `mcp__argus__*` first; fall back to `mcp__argus-kb__*` if the harness exposes the legacy name.

## Step 0a: Loading KB Context

When `argus` is on `PATH` and the KB index is non-empty:

1. **Always-on docs** (small, high-signal): the SessionStart hook already injects `memory/user/` and `memory/feedback/` into context. If those sections are missing from the system context (older session, hook disabled), call `kb_read` for every path under `memory/user/` and `memory/feedback/` listed in the KB index.
2. **Session-relevant docs**: derive 1-3 search queries from the current session topic (e.g. project name, repo name, key entities discussed) and call `kb_search` to find related entries. Read top matches with `kb_read`.
3. **Recently-changed docs** (from the dynamic context "recent changes" log): if any of those paths are relevant, read them too.

Use the KB content to decide whether something captured later is *new* knowledge or a *conflict/update* of an existing entry.

## Step 8 Part 0: Capturing Knowledge (inbox-first)

For each piece of durable knowledge worth preserving (people, decisions, conventions, debugging insights, non-obvious tool behavior, project context, user prefs, corrections):

1. **Search first.** Call `kb_search` with relevant keywords to find existing entries. If a match exists, update it via `kb_ingest` at the same path with merged content. Same-path overwrites are fine; near-duplicates at different paths get reconciled later by `/dream`.

2. **No match? Write to inbox.** New captures go into `memory/inbox/<YYYY-MM-DD>-<slug>.md`. The inbox is intentionally raw — don't agonize over the perfect destination. `/dream` will triage and re-file each entry into the right folder.

3. **Frontmatter** (required by Argus KB schema):
   ```yaml
   ---
   title: "<Concise title, under 60 chars>"
   tags: [<lowercase, kebab-case, tags>]
   ---
   ```
   Add a `source: improve-<session-id-or-date>` tag and a `captured: <YYYY-MM-DD>` line in the body so `/dream` can reason about provenance and recency.

4. **Body**: lead with the key insight, then supporting detail. 50-500 words. Use Obsidian wikilinks `[[topic]]` to cross-reference existing entries.

## Routing Rules

Only used when you're confident — otherwise default to inbox:

- User stated a personal preference / "I prefer..." → `memory/user/<topic>.md`
- User corrected your behavior / "don't do X" → `memory/feedback/<topic>.md`
- Project convention or architecture detail → `memory/project/<project>-<topic>.md`
- Reusable reference data (lookup tables, env IDs) → `memory/reference/<topic>.md`
- Topical knowledge already covered by an existing top-level folder in the KB (check `kb_list` output for the active folder set) → that folder
