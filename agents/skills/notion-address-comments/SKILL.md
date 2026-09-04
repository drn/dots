---
name: notion-address-comments
description: Iterate on a Notion page against its open inline comments — read each unresolved thread, edit the page to address it, and reply with a short summary of the change. Use when the user asks to address the comments in a Notion doc, address feedback left as inline Notion comments, or is running an iterative doc-drafting session where Notion comments are the direction.
---

# Notion Address Comments (Read-Write)

Iterate on a Notion page against its open inline comment threads via MCP tools. This
skill covers writing to a page and replying to comment threads — the sibling `notion`
skill is read-only. See `agents/skills/notion/SKILL.md` for plain page reads.

## Arguments

- `$ARGUMENTS` — The Notion page URL or page ID to iterate on.

## Quick Reference: MCP Tools

| Tool | Use For |
|------|---------|
| `mcp__claude_ai_Notion__notion-get-comments` | List comment threads on a page (resolved threads excluded by default) |
| `mcp__claude_ai_Notion__notion-fetch` | Read the page's current content as Notion-flavored markdown |
| `mcp__claude_ai_Notion__notion-update-page` | Edit page content (`command: update_content`) |
| `mcp__claude_ai_Notion__notion-create-comment` | Reply into a comment thread (`discussion_id`) |

If these tools are not available, search for an equivalent Notion write-capable MCP
server before falling back to asking the user to make the edit manually — this skill
has no read-only fallback path since the whole point is writing.

## Your task

Given a Notion page with open inline comments, address every unresolved thread: edit
the page to do what the thread asks, then reply summarizing the change. End with a
one-line tally and an explicit note that addressed threads remain open for the user to
resolve manually — there is no resolve-thread tool in this toolset.

Do not re-enter this workflow for threads already answered on a prior pass unless a
newer comment has been posted on them since your last reply.

### Step 1: List open comment threads

Call `mcp__claude_ai_Notion__notion-get-comments` with the page ID and
`include_all_blocks: true`. Resolved threads are excluded automatically, so every
thread returned is a candidate for action.

For each thread, check whether the last comment is already from this skill (compare
comment authorship/timestamps against any prior reply). If so, and no newer comment
exists after it, skip the thread entirely — it was already addressed on a previous
pass. If there is no open thread at all, stop and report: `No open comment threads on
this page.`

### Step 2: Re-fetch the page before each edit

Immediately before building an edit for a thread, call
`mcp__claude_ai_Notion__notion-fetch` on the page ID to get its current content. Do not
reuse content fetched earlier in the session or from a prior turn — a prior edit
(including one the user made manually between turns) shifts surrounding text, and a
stale copy produces a failed text match when the edit is applied.

### Step 3: Build and apply the edit

Construct an old-text/new-text pair for `mcp__claude_ai_Notion__notion-update-page`
with `command: update_content`, matching the fetched content exactly.

Watch for one specific gotcha: bold markdown inside a commented sentence splits that
sentence into multiple adjacent span tags carrying a discussion-urls attribute, one
span per segment around each bold marker. Match every one of those spans exactly as
they appear in the fetch output rather than assuming the whole sentence is a single
span. Preserve the span wrapper(s) around the edited text so the comment stays
anchored to it — only drop a wrapper when the text it anchors is being removed
entirely.

Keep the edit scoped to what the thread is asking for. If multiple open threads point
at the same passage, resolve them together in one edit rather than applying conflicting
changes one after another.

### Step 4: Reply to the thread

Call `mcp__claude_ai_Notion__notion-create-comment` with the thread's `discussion_id`
and a short reply describing what changed, for example: `Updated — <one line on the
change>.` Post the reply after the edit succeeds, so the reply always describes what
is actually on the page.

### Step 5: Report

After every open thread is processed, print a tight summary:

```
Page: <url>
Addressed N of M open threads.
<one line per addressed thread, referencing what changed>
No resolve-thread tool available — threads remain open for you to resolve manually in Notion.
```

If a thread could not be addressed (the request was unclear, or the edit could not be
matched against current content after a retry), say so explicitly in the summary rather
than silently skipping it.

## Notes and edge cases

- **Comment IDs and idempotency.** Track which threads already have a reply from this
  skill. A thread only warrants another pass when a comment newer than that reply has
  been added — otherwise leave it alone.
- **No resolve tool.** This toolset has no way to mark a thread resolved. Never imply in
  a reply or summary that a thread was closed — state plainly that resolution is a
  manual step for the user.
- **Failed text match.** If an edit's old-text does not match after a fresh fetch, do
  not guess at a fuzzy replacement — re-read the fetched content around the comment's
  anchor and rebuild the old-text exactly, retrying once before reporting the thread as
  blocked.
