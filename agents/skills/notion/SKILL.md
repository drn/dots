---
name: notion
description: Read Notion pages and databases using MCP tools. Use when looking up Notion content, reading pages, or querying databases.
---

# Notion (Read-Only)

Read Notion pages and databases via MCP tools. This skill covers reading operations only.

## Quick Reference: MCP Tools

| Tool | Use For |
|------|---------|
| `mcp__notion__notion-fetch` | Read page content as Notion-flavored markdown |
| `ReadMcpResourceTool` with `notion://docs/enhanced-markdown-spec` | Get the full markdown spec (useful for understanding page structure) |

### Fallback: Keystone MCP Tools

If `mcp__notion__notion-fetch` is not available (e.g., in environments using Keystone), use these tools instead:

| Tool | Use For |
|------|---------|
| `mcp__plugin_thanx_keystone__notion_get_page` | Read page metadata (title, properties, dates) |
| `mcp__plugin_thanx_keystone__notion_get_page_content` | Read page blocks (raw Notion API JSON) |
| `mcp__plugin_thanx_keystone__notion_search` | Search for pages by title |
| `mcp__plugin_thanx_keystone__notion_query_database` | Query a database with filters |
| `mcp__plugin_thanx_keystone__notion_get_database` | Get database schema and metadata |

The blocks API returns raw JSON. To extract readable text, parse each block's `rich_text[].plain_text` fields. Use ToolSearch to discover and load these tools before calling them.

## Instructions

You are helping read Notion data. Use the MCP tools above for all operations.

### Reading a Page

```
mcp__notion__notion-fetch with the page URL or ID
```

The tool returns Notion-flavored markdown. Key things to know about the format:
- Code blocks have language tags (e.g., ` ```ruby `)
- Toggle headings use `{toggle="true"}` attribute
- Toggle children are tab-indented
- Tables use HTML `<table>` syntax
- Dot-notation in text may appear auto-linked (e.g., `[d.date](http://d.date)`)

### Common Tasks

#### Read a specific page
Use `mcp__notion__notion-fetch` with the page URL.

#### Browse database contents
Use `mcp__notion__notion-fetch` on the database URL to see its schema and entries.

### Diagnosing Page Issues

If a page has mangled content in the markdown output:
- Code blocks whose content starts with heading markers (`#`, `##`)
- Code blocks containing `<table` or `---` dividers
- Wrong language tags on code blocks

These indicate sections that were absorbed into code blocks during a bad edit.

## Capabilities

- **Page reading**: Full page content as structured markdown
- **Database browsing**: View database schemas and entries

### Large Page Handling

Notion pages can return very large responses (100K+ characters) that exceed token limits. When this happens:
- The content may be saved to a temp file automatically
- Use `python3 -c` or `jq` to extract block text rather than reading raw JSON directly
- For Keystone blocks JSON, extract text with: `jq -r '.. | .rich_text? // empty | .[].plain_text' < temp_file.json`
- Consider requesting specific sections rather than the full page when possible

## Limitations

- **Read-only** — Cannot create, update, or delete pages
- Page content is returned as Notion-flavored markdown, not raw JSON (except Keystone fallback which returns raw blocks)
