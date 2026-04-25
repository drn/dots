---
name: merge
allowed-tools: Bash(git add:*), Bash(git commit:*), Bash(git log:*), Bash(git diff:*), Bash(git status:*), Bash(git rebase:*), Bash(git checkout:*), Bash(git reset:*), Bash(bash ~/.claude/skills/merge/scripts/merge.sh:*), Bash(bash agents/skills/merge/scripts/merge.sh:*)
description: Merge current branch to the default branch via GitHub PR merge. Use when ready to merge a PR or land a branch.
---

## Context

- Current branch: !`git branch --show-current`
- Git status: !`git status --short`
- Remotes: !`git remote -v 2>/dev/null | head -10`
- Base ref: !`git branch -r 2>/dev/null | grep -oE 'origin/(main|master)' | head -1`
- Commits vs main (upstream): !`git log upstream/main..HEAD --oneline 2>/dev/null | head -50`
- Commits vs master (upstream): !`git log upstream/master..HEAD --oneline 2>/dev/null | head -50`
- Commits vs main (origin): !`git log origin/main..HEAD --oneline 2>/dev/null | head -50`
- Commits vs master (origin): !`git log origin/master..HEAD --oneline 2>/dev/null | head -50`
- Diff stat vs main (upstream): !`git diff upstream/main..HEAD --stat 2>/dev/null | head -50`
- Diff stat vs master (upstream): !`git diff upstream/master..HEAD --stat 2>/dev/null | head -50`
- Diff stat vs main (origin): !`git diff origin/main..HEAD --stat 2>/dev/null | head -50`
- Diff stat vs master (origin): !`git diff origin/master..HEAD --stat 2>/dev/null | head -50`

## Phase Protocol

This skill participates in a phase chain. Read `~/.claude/skills/_shared/resources/phase-protocol.md` for the full protocol.

**Before merging:** Read the latest `.context/phases/ship-*.md` for the PR number/URL if available.

**After merge completes:** Write a `land-{ts}.md` artifact to `.context/phases/` (create with `mkdir -p .context/phases`). The **Detail** section should include the merge commit SHA and PR URL. Optionally archive all phase artifacts: `mkdir -p .context/phases/archive && mv .context/phases/*.md .context/phases/archive/`.

## Your task

Merge the current branch into the default branch via GitHub PR merge. An existing PR is NOT required — one will be created if needed.

### Step 0: Preflight — ahead/behind check

Before committing anything, verify the branch is in a mergeable state.

Run:

```bash
TARGET=$(git remote | grep -q '^upstream$' && echo upstream || echo origin)
git fetch "$TARGET" >/dev/null 2>&1 || true
DEFAULT_BRANCH=$(git branch -r 2>/dev/null | grep -oE "${TARGET}/(main|master)" | head -1 | sed "s|${TARGET}/||")
[ -z "$DEFAULT_BRANCH" ] && DEFAULT_BRANCH="master"
AHEAD=$(git log "$TARGET/$DEFAULT_BRANCH..HEAD" --oneline 2>/dev/null | wc -l | tr -d ' ')
BEHIND=$(git log "HEAD..$TARGET/$DEFAULT_BRANCH" --oneline 2>/dev/null | wc -l | tr -d ' ')
DIRTY=$(git status --short 2>/dev/null | wc -l | tr -d ' ')
echo "ahead=$AHEAD behind=$BEHIND dirty=$DIRTY default_branch=$DEFAULT_BRANCH"
```

Decide based on the output:

- **ahead=0 and dirty=0** — Stop. Reply: "Nothing to merge — branch has no commits ahead of $DEFAULT_BRANCH and working tree is clean."
- **Otherwise** (ahead > 0, or dirty > 0) — Proceed to Step 1. The merge script handles fetch + rebase automatically, so being behind the default branch is fine.

### Step 1: Commit uncommitted changes

If git status shows uncommitted changes, stage and commit them with an appropriate message. Skip if working tree is clean.

### Step 2: Analyze commits and craft PR metadata

Review all commits and the full diff since the branch diverged from the default branch. Determine:

- **Title**: Concise imperative summary of what the branch accomplishes (not individual commits). Under 72 characters.
- **Body**: Short description of the changes. Do NOT include Co-Authored-By — the script adds it.

If there are no prior commits (only what was committed in step 1), base the summary on that commit.

### Step 3: Run the merge script

Resolve the script path — use the first that exists:
1. `~/.claude/skills/merge/scripts/merge.sh` (deployed via symlink)
2. `agents/skills/merge/scripts/merge.sh` (repo-relative, for development/workspaces)

```
bash <script-path> [--method <squash|merge|rebase>] "<title>" "<body>"
```

#### Choosing a merge method

The script defaults to **squash** (collapses all commits into one). Pick a different method when squash would lose intentional structure:

- `--method squash` (default) — single commit, ideal for a stream of WIP commits.
- `--method merge` (alias `--merge`) — preserves all commits via a merge commit. Use when each commit is independently meaningful and you want to keep the merge boundary visible on master.
- `--method rebase` (alias `--rebase`) — preserves all commits linearly via fast-forward / rebase. **Use this when the user has deliberately split work into multiple commits** (e.g., the user ran `/squash` to condense 7 commits into 2 separate logical commits, and wants both on master). A naive squash merge here would silently undo that intent.

Heuristic: if the branch has more than one commit AND the commit messages look distinct rather than incremental ("WIP", "fix typo"), confirm with the user before using the default squash. The deliberate-split case is common after `/squash`.

#### Handle the exit code

- **Exit 0** — Show the output block verbatim as your final response. Do not add commentary.
- **Exit 2 (rebase conflict)** — Resolve conflicts:
  1. Read the conflicting files from stderr
  2. Open each file, resolve the conflict
  3. `git add` resolved files
  4. `git rebase --continue`
  5. Repeat if more conflicts
  6. Re-run: `bash <script-path> --skip-rebase [--method <method>] "<title>" "<body>"`
  7. Show the output block verbatim

  **Special case: "distinct types" conflicts.** If the rebase reports conflicts because the branch converted regular files to symlinks (or vice versa) while master independently edited those same files, do NOT naively resolve with `--theirs` or `--ours`. Both sides "win" — the branch's symlink target was sourced from old master content, so keeping the branch's version silently loses master's content updates.

  Recovery pattern:
  1. `git rebase --abort`.
  2. Drop the symlink-conversion commit from the branch (e.g., `git rebase -i master` and drop it, or `git reset --soft <sha-before-symlink-commit>` then re-stage selectively).
  3. Rebase the remaining commits onto master cleanly.
  4. Rebuild the symlink-conversion commit fresh against current master — re-source the symlink target's content from the *current* master file, not from the original AGENTS.md content captured on the branch.
  5. Re-run the merge script with `--skip-rebase`.

- **Exit 3** — Tell the user: "Nothing to merge — branch has no commits ahead of the default branch."
- **Exit 4 (review blocked)** — The PR requires review and auto-merge is not available. Tell the user: "PR requires an approving review before it can merge. Auto-merge is not enabled on this repository — ask a reviewer to approve, then re-run /merge."
- **Exit 1** — Report the error from stderr.
