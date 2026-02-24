---
allowed-tools: Bash(git fetch:*), Bash(git tag:*), Bash(git log:*), Bash(thanx version update:*), Bash(git push:*)
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
- `git fetch upstream` succeeded (context above confirms this).
- `thanx` is installed (run `thanx version update --help` or similar to verify). If not, you'll use manual tagging in Step 1.

### Step 1: Create a new version tag on upstream/master

1. Try `thanx version update` first.
2. If it fails for any reason (not installed, requires checkout of master, etc.), fall back to manual tagging: determine the next version by incrementing the patch of the latest tag, then run `git tag <next-version> upstream/master`.

### Step 2: Push tags and upstream/master to production

- Run `git push upstream --tags upstream/master:refs/heads/production` to push tags and deploy atomically.
- This MUST be a single git push command to avoid a race condition where CircleCI fetches the repo before GitHub has indexed the new version tag, causing the Docker image to be tagged as "latest" instead of the version.

### Step 3: Report the result

- Confirm the new version tag that was created.
- Confirm that tags and master were pushed to production.
- Show the commit being deployed.

Execute all steps in sequence. If any step fails, stop and report the error.
