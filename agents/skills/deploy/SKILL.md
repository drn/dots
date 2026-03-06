---
name: deploy
disable-model-invocation: true
allowed-tools: Bash(bash ~/.claude/skills/deploy/scripts/deploy.sh:*), Bash(bash agents/skills/deploy/scripts/deploy.sh:*)
description: Deploy latest master to production with a version tag
---

## Context

- Current tags: !`git tag --sort=-v:refname 2>/dev/null | head -5`
- Remotes: !`git remote -v 2>/dev/null | head -10`

## Your task

Deploy the latest master to production by creating a version tag and pushing to the production branch. This works from any branch — no need to checkout master.

### Step 1: Run the deploy script

Resolve the script path — use the first that exists:
1. `~/.claude/skills/deploy/scripts/deploy.sh` (deployed via symlink)
2. `agents/skills/deploy/scripts/deploy.sh` (repo-relative, for development/workspaces)

```
bash <script-path>
```

Handle the exit code:

- **Exit 0** — Show the output block verbatim as your final response. Do not add commentary.
- **Exit 1** — Report the error from stderr.
