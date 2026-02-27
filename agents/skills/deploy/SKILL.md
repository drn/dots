---
name: deploy
allowed-tools: Bash(git fetch:*), Bash(git tag:*), Bash(git log:*), Bash(git ls-remote:*), Bash(thanx version update:*), Bash(git push:*)
description: Deploy latest master to production with a version tag
disable-model-invocation: true
---

## Context

- Current tags: !`git tag --sort=-v:refname 2>/dev/null | head -5`
- Remotes: !`git remote -v 2>/dev/null | head -10`

## Your task

Deploy the latest master to production by creating a version tag and pushing to the production branch. This works from any branch — no need to checkout master.

### Step 0: Determine the target remote

1. Run `git remote` to list available remotes.
2. If an `upstream` remote exists, set **TARGET=upstream**.
3. Otherwise, set **TARGET=origin**.
4. All references to `{TARGET}` below use the determined remote.

### Pre-flight checks

Before continuing, verify all of the following. If any check fails, stop and tell the user why.

- At least one remote (upstream or origin) is configured.
- `git fetch {TARGET}` succeeded.

### Step 1: Create a new version tag on {TARGET}/master

`thanx version update` always tags HEAD, so we use it to calculate the correct sprint-based version, then move the tag to `{TARGET}/master`.

1. Run `thanx version update` — this creates an annotated tag on HEAD.
2. Identify the new tag name from the output (or compare tags before/after).
3. Move the tag to `{TARGET}/master`:
   ```
   git tag -d <new-tag>
   git tag -a <new-tag> {TARGET}/master -m ''
   ```

Save the new tag name for Step 2.

### Step 2: Push the tag and {TARGET}/master to production

Push the specific new tag and the production branch update in a single atomic command:

```
git push {TARGET} <new-tag> {TARGET}/master:refs/heads/production
```

Do NOT use `--tags` — that pushes every local tag. Push only the new tag by name.

This MUST be a single git push command to avoid a race condition where CircleCI fetches the repo before GitHub has indexed the new version tag, causing the Docker image to be tagged as "latest" instead of the version.

### Step 3: Verify and report

1. Verify the tag exists on the remote: `git ls-remote --tags {TARGET} <new-tag>`
2. Confirm the new version tag and the commit it points to.
3. Confirm that the tag and master were pushed to production.

Execute all steps in sequence. If any step fails, stop and report the error.
