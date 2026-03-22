---
name: amend
description: "Amend the last git commit with a useful, descriptive message. Use when you want to rewrite a commit message, amend commit description, or improve the last commit message."
---

# Amend Last Commit

Rewrite the last commit message with a clear, descriptive summary based on the actual changes.

## Arguments

- `$ARGUMENTS` - Optional: specific instructions for the commit message (e.g., "mention the performance improvement")

## Context

- Current branch: !`git branch --show-current`
- Last commit: !`git log -1 --format="%H %s" 2>/dev/null | head -1`
- Last commit body: !`git log -1 --format="%b" 2>/dev/null | head -20`
- Diff stat: !`git diff HEAD~1 --stat 2>/dev/null | head -30`

## Instructions

### Step 1: Understand the changes

1. Read the diff of the last commit: `git diff HEAD~1` (full diff, not just stat)
2. Read any files that were added or significantly changed to understand their purpose
3. Check the current commit message — if it's already descriptive and accurate, tell the user and stop

### Step 2: Draft the message

Write a commit message following this structure:

**Subject line** (first line):
- Imperative mood ("Add", "Fix", "Update", not "Added", "Fixes")
- Under 72 characters
- Summarize WHAT changed and WHY at a high level
- No trailing period

**Body** (separated by blank line, optional but preferred for non-trivial changes):
- Explain what the change does and why it was made
- Wrap lines at 72 characters
- Focus on context that isn't obvious from the diff
- Skip the body for truly trivial changes (typo fixes, version bumps)

### Step 3: Amend the commit

Run `git commit --amend` with the new message. Use a HEREDOC to pass the message:

```bash
git commit --amend -m "$(cat <<'EOF'
Subject line here

Body paragraph here explaining the change in more detail.
EOF
)"
```

### Step 4: Confirm

Show the user the new commit with `git log -1` so they can verify.

## Rules

- **Never change the commit contents** — only the message. Do not stage or unstage files.
- **Preserve co-author trailers** from the original message if present.
- If the working tree has staged changes, warn the user that `--amend` will include them, and ask before proceeding.
- If `$ARGUMENTS` contains specific instructions, incorporate them into the message.
