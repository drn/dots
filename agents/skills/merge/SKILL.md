---
name: merge
allowed-tools: Bash(git add:*), Bash(git commit:*), Bash(git log:*), Bash(git diff:*), Bash(git status:*), Bash(git rebase:*), Bash(git checkout:*), Bash(bash ~/.claude/skills/merge/scripts/merge.sh:*), Bash(bash agents/skills/merge/scripts/merge.sh:*)
description: Merge current branch to master via GitHub PR merge
---

## Context

- Current branch: !`git branch --show-current`
- Git status: !`git status --short`
- Remotes: !`git remote -v 2>/dev/null | head -10`
- Commits (upstream): !`git log upstream/master..HEAD --oneline 2>/dev/null | head -50`
- Commits (origin): !`git log origin/master..HEAD --oneline 2>/dev/null | head -50`
- Diff stat (upstream): !`git diff upstream/master..HEAD --stat 2>/dev/null | head -50`
- Diff stat (origin): !`git diff origin/master..HEAD --stat 2>/dev/null | head -50`

## Your task

Merge the current branch into master via GitHub PR merge. An existing PR is NOT required — one will be created if needed.

### Step 1: Commit uncommitted changes

If git status shows uncommitted changes, stage and commit them with an appropriate message. Skip if working tree is clean.

### Step 2: Analyze commits and craft PR metadata

Review all commits and the full diff since the branch diverged from master. Determine:

- **Title**: Concise imperative summary of what the branch accomplishes (not individual commits). Under 72 characters.
- **Body**: Short description of the changes. Do NOT include Co-Authored-By — the script adds it.

If there are no prior commits (only what was committed in step 1), base the summary on that commit.

### Step 3: Run the merge script

Resolve the script path — use the first that exists:
1. `~/.claude/skills/merge/scripts/merge.sh` (deployed via symlink)
2. `agents/skills/merge/scripts/merge.sh` (repo-relative, for development/workspaces)

```
bash <script-path> "<title>" "<body>"
```

Handle the exit code:

- **Exit 0** — Show the output block verbatim as your final response. Do not add commentary.
- **Exit 2 (rebase conflict)** — Resolve conflicts:
  1. Read the conflicting files from stderr
  2. Open each file, resolve the conflict
  3. `git add` resolved files
  4. `git rebase --continue`
  5. Repeat if more conflicts
  6. Re-run: `bash <script-path> --skip-rebase "<title>" "<body>"`
  7. Show the output block verbatim
- **Exit 3** — Tell the user: "Nothing to merge — branch has no commits ahead of master."
- **Exit 1** — Report the error from stderr.
