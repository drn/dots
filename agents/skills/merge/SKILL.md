---
name: merge
allowed-tools: Bash(git add:*), Bash(git commit:*), Bash(git log:*), Bash(git diff:*), Bash(git status:*), Bash(git rebase:*), Bash(git checkout:*), Bash(bash ~/.claude/skills/merge/scripts/merge.sh:*), Bash(bash agents/skills/merge/scripts/merge.sh:*)
description: Merge current branch to master via GitHub PR merge. Use when ready to merge a PR or land a branch.
---

## Context

- Current branch: !`git branch --show-current`
- Git status: !`git status --short`
- Remotes: !`git remote -v 2>/dev/null | head -10`
- Commits (upstream): !`git log upstream/master..HEAD --oneline 2>/dev/null | head -50`
- Commits (origin): !`git log origin/master..HEAD --oneline 2>/dev/null | head -50`
- Diff stat (upstream): !`git diff upstream/master..HEAD --stat 2>/dev/null | head -50`
- Diff stat (origin): !`git diff origin/master..HEAD --stat 2>/dev/null | head -50`

## Phase Protocol

This skill participates in a phase chain. Read `~/.claude/skills/_shared/resources/phase-protocol.md` for the full protocol.

**Before merging:** Read the latest `.context/phases/ship-*.md` for the PR number/URL if available.

**After merge completes:** Write a `land-{ts}.md` artifact to `.context/phases/` (create with `mkdir -p .context/phases`). The **Detail** section should include the merge commit SHA and PR URL. Optionally archive all phase artifacts: `mkdir -p .context/phases/archive && mv .context/phases/*.md .context/phases/archive/`.

## Your task

Merge the current branch into master via GitHub PR merge. An existing PR is NOT required — one will be created if needed.

### Step 0: Preflight — ahead/behind check

Before committing anything, verify the branch is in a mergeable state.

Run:

```bash
TARGET=$(git remote | grep -q '^upstream$' && echo upstream || echo origin)
git fetch "$TARGET" 2>/dev/null | head -0
AHEAD=$(git log "$TARGET/master..HEAD" --oneline 2>/dev/null | wc -l | tr -d ' ')
BEHIND=$(git log "HEAD..$TARGET/master" --oneline 2>/dev/null | wc -l | tr -d ' ')
DIRTY=$(git status --short 2>/dev/null | wc -l | tr -d ' ')
echo "ahead=$AHEAD behind=$BEHIND dirty=$DIRTY"
```

Decide based on the output:

- **ahead=0 and dirty=0** — Stop. Reply: "Nothing to merge — branch has no commits ahead of master and working tree is clean."
- **behind > 0** — Stop regardless of dirty count. Reply: "Branch is N commit(s) behind master. Rebase onto current master before running /merge — merging from an old base would create a misleading reverse-diff PR."
- **Otherwise** (ahead > 0, or dirty > 0 with behind = 0) — Proceed to Step 1.

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
- **Exit 4 (review blocked)** — The PR requires review and auto-merge is not available. Tell the user: "PR requires an approving review before it can merge. Auto-merge is not enabled on this repository — ask a reviewer to approve, then re-run /merge."
- **Exit 1** — Report the error from stderr.
