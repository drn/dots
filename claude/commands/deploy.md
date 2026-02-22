---
allowed-tools: Bash(git fetch:*), Bash(git rebase:*), Bash(thanx version update:*), Bash(git push:*)
description: Create a new version tag and deploy to production
disable-model-invocation: true
---

## Context

- Current branch: !`git branch --show-current`
- Current tags: !`git tag --sort=-v:refname 2>/dev/null | head -5 || echo "No tags found"`
- Git status: !`git status --short 2>/dev/null || echo "Unable to determine status"`
- Upstream remote: !`git remote -v 2>/dev/null | grep upstream || echo "No upstream remote configured"`

## Your task

Deploy the application by rebasing on upstream/master, creating a version tag, and pushing to production.

### Pre-flight checks

Before doing anything, verify all of the following. If any check fails, stop and tell the user why.

- The current branch is master. If not, tell the user to switch to master first.
- The working tree is clean (no uncommitted changes). If dirty, tell the user to commit or stash first.
- An upstream remote is configured. If not, tell the user to add one.

### Step 1: Rebase on upstream/master

- Run `git fetch upstream`
- Run `git rebase upstream/master`
- If there are conflicts, stop and report them.

### Step 2: Create a new version tag

- Run `thanx version update` to bump the version and create a git tag.

### Step 3: Push tags and master to production

- Run `git push origin --tags master:production` to push tags and deploy atomically.
- This MUST be a single git push command to avoid a race condition where CircleCI fetches the repo before GitHub has indexed the new version tag, causing the Docker image to be tagged as "latest" instead of the version.

### Step 4: Report the result

- Confirm the rebase was successful.
- Confirm the new version tag that was created.
- Confirm that tags and master were pushed to production.

Execute all steps in sequence. If any step fails, stop and report the error.
