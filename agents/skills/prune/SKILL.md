---
name: prune
allowed-tools: Bash(bash ~/.claude/skills/prune/scripts/prune.sh:*), Bash(bash agents/skills/prune/scripts/prune.sh:*)
description: Clean up merged and stale git branches, prune old local and remote branches safely. Use for cleaning up old branches or pruning stale remotes.
disable-model-invocation: true
---

# Branch Cleanup

Delete merged and stale local branches safely, with preview and confirmation.

## Arguments

- `$ARGUMENTS` - Optional: `--stale-days <N>` to override the 30-day stale threshold, `--remote` to also delete remote branches

## Context

- Current branch: !`git branch --show-current`
- Remote: !`git remote 2>/dev/null | head -5`

## Instructions

Resolve the script path — use the first that exists:
1. `~/.claude/skills/prune/scripts/prune.sh` (deployed via symlink)
2. `agents/skills/prune/scripts/prune.sh` (repo-relative, for development/workspaces)

### Step 1: Preview branches

Run the preview command, forwarding any `--stale-days` argument:

```
bash <script-path> preview [--stale-days N]
```

Handle the exit code:

- **Exit 0** — Present the output as a formatted table (see format below). Proceed to Step 2.
- **Exit 3** — Tell the user: "All branches are current — nothing to prune." and stop.
- **Exit 1** — Report the error from stderr.

Format the preview output as:

```markdown
## Branch Cleanup Preview

### Merged (safe to delete)
| Branch | Last Commit | Merged Into |
|--------|------------|-------------|
| <branch> | <date> | <default> |

### Stale (no commits in N days)
| Branch | Last Commit |
|--------|------------|
| <branch> | <date> |

### Skipped
| Branch | Reason |
|--------|--------|
| <branch> | <reason> |
```

### Step 2: Confirm and delete

Ask the user which branches to delete. Accept "all", specific branch names, or "none".

For confirmed branches, run the delete command:

```
bash <script-path> delete [--remote] <branch1> [branch2 ...]
```

Include `--remote` only if the user passed it in `$ARGUMENTS`.

Handle the exit code:

- **Exit 0** — Show the output block verbatim as your final response.
- **Exit 1** — Report the error from stderr.
