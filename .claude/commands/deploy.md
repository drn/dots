---
allowed-tools: Bash(git fetch:*), Bash(git rebase:*), Bash(thanx version update:*), Bash(git push:*)
description: Create a new version tag and deploy to production
---

## Context

- Current branch: !`git branch --show-current`
- Current tags: !`git tag --sort=-v:refname | head -5`
- Git status: !`git status --short`

## Your task

Deploy the application by rebasing on upstream/master, creating a version tag, and pushing to production:

1. **Rebase on upstream/master:**
   - Run `git fetch upstream`
   - Run `git rebase upstream/master`
   - If there are conflicts, stop and report them

2. **Create a new version tag:**
   - Run `thanx version update` to create a new version tag
   - This command will automatically bump the version and create a git tag

3. **Push tags and master to production in a single push:**
   - Run `git push origin --tags master:production` to push tags and deploy to production atomically
   - This MUST be a single `git push` command to avoid a race condition where CircleCI
     fetches the repo before GitHub has indexed the new version tag, causing the Docker
     image to be pushed as `latest` instead of the version tag

4. **Report the result:**
   - Confirm the rebase was successful
   - Confirm the new version tag that was created
   - Confirm that tags and master were pushed to production

Execute all steps in sequence. If any step fails, stop and report the error.
