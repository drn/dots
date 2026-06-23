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
- Diff stat vs main (upstream, branch-only): !`git diff upstream/main...HEAD --stat 2>/dev/null | head -50`
- Diff stat vs master (upstream, branch-only): !`git diff upstream/master...HEAD --stat 2>/dev/null | head -50`
- Diff stat vs main (origin, branch-only): !`git diff origin/main...HEAD --stat 2>/dev/null | head -50`
- Diff stat vs master (origin, branch-only): !`git diff origin/master...HEAD --stat 2>/dev/null | head -50`

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

These `ahead`/`behind` counts are the authoritative signal for what the branch will land. The injected context block reflects them: the "Commits vs `<base>`" lines use a two-dot range (`<base>..HEAD`), which lists exactly the commits this branch adds, and the "Diff stat vs `<base>` (branch-only)" lines use a three-dot diff (`<base>...HEAD`, from the merge-base), which shows only this branch's own file changes even when `behind > 0`. Both are already scoped to the branch — neither inflates when behind.

Caveat for manual checks: if you run a plain two-dot diff yourself (`git diff <base>..HEAD --stat`) while the branch is behind, it folds base-ahead history in as inverted changes and lists many files unrelated to this branch. That is expected, not a problem with the branch — Step 3 rebases the branch onto the current `<base>` tip, after which the two-dot and three-dot diffs converge. Trust the Step 0 counts and the three-dot diff stat above, not a raw two-dot diff.

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
bash <script-path> [--method <squash|merge|rebase>] [--keep-branch] "<title>" "<body>"
```

#### Choosing a merge method

The script defaults to **squash** (collapses all commits into one). Pick a different method when squash would lose intentional structure:

- `--method squash` (default) — single commit, ideal for a stream of WIP commits.
- `--method merge` (alias `--merge`) — preserves all commits via a merge commit. Use when each commit is independently meaningful and you want to keep the merge boundary visible on master.
- `--method rebase` (alias `--rebase`) — preserves all commits linearly via fast-forward / rebase. **Use this when the user has deliberately split work into multiple commits** (e.g., the user ran `/squash` to condense 7 commits into 2 separate logical commits, and wants both on master). A naive squash merge here would silently undo that intent.

Heuristic: if the branch has more than one commit AND the commit messages look distinct rather than incremental ("WIP", "fix typo"), confirm with the user before using the default squash. The deliberate-split case is common after `/squash`.

#### Post-merge worktree state

After a successful **squash** merge, the script auto-switches the current worktree to the default branch (`master`/`main`). This prevents the next agent or follow-up task in this worktree from committing against the now-divergent feature branch — squash collapses all commits into one new commit on master, so the old feature branch HEAD no longer shares history with the merged result.

- `--method merge` / `--method rebase` — auto-switch is **off** by default. Both methods preserve the original commits, so the feature branch may still be useful for stacked PRs or chained follow-on work.
- `--keep-branch` — opt out of auto-switch on squash. The worktree stays on the feature branch and the script prints a divergence warning instead. Use this for stacked-PR workflows that squash but still need to keep the branch checked out (rare).

If auto-switch fails (e.g., uncommitted changes in the worktree, or `master` is checked out in another worktree), the script falls back to a loud warning rather than aborting — the merge itself already succeeded.

#### Review-required repos: automatic `--admin` escalation

The script handles branch protection on its own — you do **not** need to fall back to a manual `gh pr merge --admin`. When `reviewDecision` is `REVIEW_REQUIRED` or `CHANGES_REQUESTED`, `do_merge` escalates through tiers automatically:

1. Retry the merge with `--admin` (branch-protection bypass; succeeds when you hold admin on the repo). A successful admin merge prints `WARNING: merged via --admin (branch protection bypassed)` so the bypass is never silent.
2. If `--admin` fails (lacking admin is one cause, but a pending required status check is the more common one — gh refuses an admin merge until required checks resolve), enable `--auto` (auto-merge) so the PR lands once checks pass. The real admin error is printed (`Admin merge failed: …`), not swallowed.
3. Only if both fail does it `exit 4` — and the exit-4 message includes the actual admin-merge error so the cause is visible.

On a repo where you hold admin, `/merge` lands the PR through the review gate itself — **never substitute a raw `gh pr merge --admin`**, which skips the post-squash worktree auto-switch and strands you on the merged feature branch. A plain non-blocked PR merges directly; the admin tier only kicks in when review is actually blocking.

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
- **Exit 4 (review blocked)** — Review is required (`REVIEW_REQUIRED`/`CHANGES_REQUESTED`) and both the `--admin` bypass and auto-merge failed. The script prints the **actual** `gh pr merge --admin` error (`admin merge error: …`) alongside the auto-merge error — read it before concluding anything. Do **not** assume "no admin"; an admin merge fails for several reasons, and a **pending required status check** is the most common (gh refuses an admin merge until required checks resolve, even for an admin).
  - If the admin error mentions pending/required checks (or the PR still has checks running), tell the user: "PR is blocked by a still-pending required status check, which prevented even the admin merge. Wait for checks to finish, then re-run /merge." Re-running once checks are green typically lands it.
  - If the admin error actually indicates missing permissions (e.g. "must have admin rights", "not authorized"), tell the user: "PR requires an approving review and I lack admin on this repo to bypass it. Ask a reviewer to approve, then re-run /merge."
  - Otherwise, surface the literal admin error to the user verbatim and suggest the matching next step.
- **Exit 1** — Report the error from stderr.
