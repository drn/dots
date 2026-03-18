---
name: combine-prs
description: Compare two competing PRs implementing the same feature, identify strengths of each, and combine the best parts into a single branch. Use when comparing PRs, combining implementations, cherry-picking between PRs, or resolving competing approaches.
allowed-tools: Bash(gh *), Bash(git *)
disable-model-invocation: true
---

## Arguments

- `$ARGUMENTS` - Two PR numbers or branch names to compare (e.g., "230 231" or "#230 #231")

If no arguments are provided, ask the user for two PR numbers.

## Context

- Current branch: !`git branch --show-current`
- Git status: !`git status --short`
- Repo slug: !`gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null | head -1`
- Base ref: !`git branch -r 2>/dev/null | grep -oE 'origin/(main|master)' | head -1`
- Remotes: !`git remote -v 2>/dev/null | head -6`

## Your task

Compare two PRs that implement the same feature, analyze strengths and weaknesses, present a comparison, and on approval combine the best parts into one branch.

### Step 1: Parse arguments and fetch PR metadata

Extract two PR numbers from the arguments (strip any leading "#" characters). If branch names are given instead, find their associated PRs via `gh pr list`.

For each PR, fetch metadata:

```
gh pr view <number> --json number,title,body,headRefName,baseRefName,author,state,additions,deletions,changedFiles
```

Verify both PRs target the same base branch and address the same feature. If they do not appear related, warn the user and ask whether to proceed.

### Step 2: Fetch and analyze both diffs

For each PR, get the full diff:

```
gh pr diff <number>
```

Also read the actual changed files from each branch to understand full context (not just diff hunks). Check out each branch temporarily or use `git show <branch>:<file>` to read files without switching.

Analyze each PR across these dimensions:
- **Files changed** - which files each PR touches
- **Lines added/removed** - scope of changes
- **Package/module placement** - where new code lives, architectural fit
- **Code liveness** - is the code wired in and working, or dead/placeholder code
- **Test coverage** - what tests exist, what is covered
- **Fail-fast vs graceful fallback** - error handling approach
- **API design** - interfaces, contracts, extensibility
- **Architectural implications** - impact on future work, dependency direction

### Step 3: Present comparison table

Present a structured comparison to the user:

```
## PR Comparison: #<A> vs #<B>

| Dimension | #<A> | #<B> | Verdict |
|-----------|------|------|---------|
| Files changed | ... | ... | ... |
| Lines +/- | ... | ... | ... |
| Package placement | ... | ... | ... |
| Code liveness | ... | ... | ... |
| Test coverage | ... | ... | ... |
| Error handling | ... | ... | ... |
| API design | ... | ... | ... |
| Future implications | ... | ... | ... |

## Recommended Combination Strategy

Take from #<A>:
- ...

Take from #<B>:
- ...

Resulting branch: #<winner> (will be updated, #<loser> will be superseded)
```

Wait for the user to approve, modify, or reject the strategy before proceeding.

### Step 4: Combine onto one branch

After user approval:

1. **Determine the surviving PR.** Use whichever branch has the better foundation (or whichever the user specified). Check it out.

2. **Reset to base.** Soft-reset to the merge base so all changes become staged:

```
git checkout <surviving-branch>
git reset --soft <base-branch>
```

3. **Unstage everything** so you can selectively apply the combined result:

```
git reset HEAD .
```

4. **Apply the combined changes.** Read the relevant files from both branches using `git show <branch>:<file>` and write the combined version that incorporates the best parts of each. This requires judgment — it is not a mechanical merge. For files where both PRs made changes:
   - Read both versions in full
   - Determine which parts to keep from each
   - Write the combined result

5. **Stage and commit** with a descriptive squashed commit message:

```
git add <files...>
git commit -m "$(cat <<'EOF'
<concise summary of the combined feature>

Combined from #<A> and #<B>:
- From #<A>: <what was taken>
- From #<B>: <what was taken>
EOF
)"
```

6. **Force-push with lease** to update the surviving PR:

```
git push --force-with-lease origin <surviving-branch>
```

### Step 5: Update PR descriptions

Update the surviving PR body to note the combination:

```
gh pr edit <surviving-number> --body "$(cat <<'EOF'
<original or updated description>

---
Supersedes #<other-number>. Combined the best of both implementations:
- From #<other>: <what was taken>
- From this PR: <what was kept>
EOF
)"
```

### Step 6: Handle the superseded PR

Ask the user whether to close the superseded PR. If approved:

```
gh pr close <other-number> --comment "Superseded by #<surviving-number>, which combines the best parts of both implementations."
```

If the user declines, leave it open but add a comment noting the relationship:

```
gh pr comment <other-number> --body "See #<surviving-number> for a combined implementation that incorporates the best of both PRs."
```

### Step 7: Report

Summarize what was done:

```
## Combined PR Result

- **Surviving PR:** #<number> (<url>)
- **Superseded PR:** #<number> (<status>)
- **Commit:** <short-sha> - <message>
- **From #<A>:** <what was taken>
- **From #<B>:** <what was taken>
```

## Failure Handling

| Failure | Action |
|---------|--------|
| PR not found | Report and ask for correct number |
| PRs target different base branches | Warn user, ask to proceed |
| PRs are unrelated (no file overlap) | Warn user, ask to proceed |
| Merge conflicts during combination | Resolve manually, show user what was resolved |
| Force-push rejected | Report error, suggest `git pull --rebase` first |
| User rejects combination strategy | Ask what they want changed, revise the plan |
