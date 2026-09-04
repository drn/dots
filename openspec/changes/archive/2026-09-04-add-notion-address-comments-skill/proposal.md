# Change: Add notion-address-comments skill

## Why

The existing `/notion` skill is deliberately read-only ("Cannot create, update, or
delete pages"). Iterating on a Notion page across rounds of inline review comments —
read each open thread, make the edit it asks for, reply summarizing the change — is a
repeatable workflow currently done ad hoc with raw MCP tool calls, with no skill
covering it.

## What Changes

- Add `agents/skills/notion-address-comments/SKILL.md`: given a Notion page with open
  inline comments, reads each unresolved thread, edits the page to address it, and
  replies with a short summary of the change, without reprocessing threads already
  answered.
- The skill is tool-agnostic in spirit but documents the concrete
  `mcp__claude_ai_Notion__*` tool calls needed (`notion-get-comments`, `notion-fetch`,
  `notion-update-page`, `notion-create-comment`) since no alternate vendor path exists
  for Notion writes today.
- The skill states explicitly that there is no resolve-thread tool available — threads
  stay open for the user to resolve manually in the Notion UI.
- Add a short cross-reference line in `agents/skills/notion/SKILL.md` pointing to the
  new skill for writes/comment threads.
- Update `README.md` skill count.

## Impact

- Affected specs: `notion-comment-workflow` (new capability)
- Affected code: `agents/skills/notion-address-comments/`,
  `agents/skills/notion/SKILL.md`, `README.md`
