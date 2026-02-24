---
allowed-tools: Bash(git fetch:*), Bash(git tag:*), Bash(git log:*), Bash(git ls-remote:*), Bash(thanx version update:*), Bash(git push:*)
description: Deploy latest upstream/master to production with a version tag
disable-model-invocation: true
---

## Context

- Current tags: !`git tag --sort=-v:refname 2>/dev/null | head -5`
- Upstream remote: !`git remote -v 2>/dev/null | grep upstream`
- Upstream master: !`git log --oneline upstream/master -3 2>/dev/null | head -5`

## Your task

Deploy the latest upstream/master to production by creating a version tag and pushing to the production branch. This works from any branch — no need to checkout master.

### Pre-flight checks

Before doing anything, verify all of the following. If any check fails, stop and tell the user why.

- An upstream remote is configured. If not, tell the user to add one.
- `git fetch upstream` succeeded.

### Step 1: Create a new version tag on upstream/master

`thanx version update` always tags HEAD, so we use it to calculate the correct sprint-based version, then move the tag to `upstream/master`.

1. Run `thanx version update` — this creates an annotated tag on HEAD.
2. Identify the new tag name from the output (or compare tags before/after).
3. Move the tag to `upstream/master`:
   ```
   git tag -d <new-tag>
   git tag -a <new-tag> upstream/master -m ''
   ```

Save the new tag name for Step 2.

### Step 2: Push the tag and upstream/master to production

Push the specific new tag and the production branch update in a single atomic command:

```
git push upstream <new-tag> upstream/master:refs/heads/production
```

Do NOT use `--tags` — that pushes every local tag. Push only the new tag by name.

This MUST be a single git push command to avoid a race condition where CircleCI fetches the repo before GitHub has indexed the new version tag, causing the Docker image to be tagged as "latest" instead of the version.

### Step 3: Verify and report

1. Verify the tag exists on the remote: `git ls-remote --tags upstream <new-tag>`
2. Confirm the new version tag and the commit it points to.
3. Confirm that the tag and master were pushed to production.

Execute all steps in sequence. If any step fails, stop and report the error.
