---
name: wrapup
description: End-of-session checklist that detects loose ends — uncommitted changes, unmerged branches, learnings to capture, handoffs needed — and routes to the right skills. Use for session closeout, wrapping up, end of day, or "anything else to capture".
---

# Session Wrapup

End-of-session sweep that detects loose ends and routes to the right follow-up actions before you close the conversation.

## Context

- Current branch: !`git branch --show-current`
- Base ref: !`git branch -r 2>/dev/null | grep -oE 'origin/(main|master)' | head -1`
- Uncommitted changes: !`git status --short 2>/dev/null | head -20`
- Unpushed commits vs main: !`git log origin/main..HEAD --oneline 2>/dev/null | head -20`
- Unpushed commits vs master: !`git log origin/master..HEAD --oneline 2>/dev/null | head -20`
- Open PRs (mine): !`gh pr list --author @me --state open 2>/dev/null | head -10`
- Stash list: !`git stash list 2>/dev/null | head -5`
- Knowledge base exists: !`ls context/knowledge/index.md 2>/dev/null | head -1`
- Context directory exists: !`ls context/ 2>/dev/null | head -5`

## Instructions

**Do NOT automatically run any of the suggested skills.** Present the full report first, then let the user pick which actions to take.

Run through each check below. For each one that fires, report the finding and suggest the action. At the end, present a summary with recommended next steps.

### Check 1: Uncommitted Changes

If `git status` shows modified, added, or untracked files:

- List the changed files
- Suggest: **Commit** the changes, or **stash** if the work is incomplete
- If the changes look ready: offer to run `/commit`

### Check 2: Unpushed Commits

If the branch has commits ahead of the remote base branch:

- Show the commit count and titles
- Suggest: **Push** to remote, or **open a PR** via `/pr`

### Check 3: Unmerged Branch

If the current branch is not the main branch and has commits:

- Note the branch name and commit count
- Check if a PR already exists for this branch (from the Open PRs context)
- If PR exists: report its status (open, draft, checks passing/failing)
- If no PR exists: suggest opening one via `/pr`
- If the work is incomplete: suggest generating a `/handoff` for the next session

### Check 4: Open PRs Needing Attention

If there are open PRs from the current user:

- List them with status
- Suggest: review, merge via `/merge`, or close stale ones

### Check 5: Session Learnings

Scan the conversation for signals that `/improve` would be valuable:

- Skills that required manual workarounds or corrections
- Patterns discovered that could improve skills or agent guidance
- Errors or friction that could be prevented next time
- New knowledge about tools, APIs, or workflows

If any signals found: summarize them and suggest running `/improve`

### Check 6: Incomplete Work

Scan the conversation for work that was started but not finished:

- Tasks discussed but not implemented
- TODOs mentioned but not addressed
- Known issues deferred for later

If found: suggest generating a `/handoff` prompt to preserve context for the next session

### Check 7: Knowledge Capture

If the session involved significant context that is not in the codebase:

- Architectural decisions made
- External system behaviors discovered
- People, processes, or policies discussed
- Debugging insights worth preserving

If the project has a `context/` directory or knowledge base: suggest running `/improve` (which handles knowledge capture)
If not: note that context will be lost unless captured

### Summary

Present findings as a checklist. Only list items that need attention — omit clean items entirely.

```markdown
## Session Wrapup

### Loose Ends
- [ ] **Uncommitted changes** — N files modified (list key ones)
- [ ] **Unpushed commits** — N commits on `branch-name`
- [ ] **No PR open** — branch has work ready for review

### Capture Opportunities
- [ ] **Learnings detected** — skill friction worth capturing via `/improve`
- [ ] **Incomplete work** — generate `/handoff` for next session
- [ ] **Knowledge** — decisions/context worth preserving

### Suggested Actions (pick any)
Only list actions whose corresponding check fired above.
1. `/commit` — commit uncommitted changes
2. `/pr` — open a PR for this branch
3. `/improve` — capture learnings and improve skills
4. `/handoff` — generate context for next session
5. Push to remote — `git push -u origin <branch-name>`
```

Omit any section where all items are clean. If everything is clean, say:

> All clear — no loose ends detected. Session is clean to close.

After presenting the summary, ask:

> Want me to run any of these? (e.g., "1 and 3", "all", or "none")

Then execute the user's chosen actions in order.
