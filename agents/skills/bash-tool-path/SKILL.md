---
name: bash-tool-path
description: Safely add a directory to Claude Code's Bash tool PATH. Use when a binary runs in your terminal but is "command not found" inside Claude Code's Bash tool, when adding a directory to PATH for Claude Code, when configuring CLAUDE_ENV_FILE, or when settings.json env.PATH did not work. Explains why env.PATH replaces rather than appends PATH and is not variable-expanded, why ~/.zshrc PATH exports are dropped, and the supported SessionStart hook fix.
---

## Context

- Worked example hook: ~/.dots/agents/hooks/session-start-path.sh
- Existing SessionStart hooks (user): !{grep -n SessionStart ~/.claude/settings.json 2>/dev/null | head -10}
- env.PATH in user settings (a footgun if present): !{grep -n '"PATH"' ~/.claude/settings.json 2>/dev/null | head -5}

## When to use this skill

Use this when a command that works in an interactive terminal fails with
"command not found" inside Claude Code's Bash tool, or when the user wants to
add a directory (a go/bin, cargo, asdf shim, or custom tool dir) to the PATH
that Claude Code's Bash tool sees.

## Why the obvious fixes do not work

Three footguns make this harder than it looks. State them plainly so nobody
re-discovers them by hand.

1. settings.json `env` values are set **literally**. Claude Code does not
   expand `$VAR` or `${VAR}` in them. So `"PATH": "${PATH}:/x/bin"` sets PATH
   to that literal, broken string, not to the inherited PATH plus a directory.

2. `env.PATH` **replaces** the inherited PATH wholesale. It cannot append,
   and replacing it drops the directories Claude Code already needs (for
   example plugin bin dirs). So `env.PATH` is the wrong tool for adding a dir.

3. The Bash tool sources `~/.zshrc` (or `~/.bashrc`/`~/.profile`) at session
   start **only to capture aliases, functions, and shell options**. PATH
   `export` lines in `~/.zshrc` or `~/.zshenv` are not captured. Claude Code
   builds the Bash tool PATH from the process that launched it (often a daemon),
   not from your interactive shell, so daemon-launched sessions can lack
   go/bin and similar dirs even though they resolve fine in your terminal.

## The supported fix: a SessionStart hook that writes to CLAUDE_ENV_FILE

Claude Code sources the file named by `$CLAUDE_ENV_FILE` before every Bash
command. Because the file is sourced, `$PATH` expands at source time, so you
can prepend a directory and preserve the inherited PATH. Populate that file
from a `SessionStart` hook. `$CLAUDE_ENV_FILE` is available to the
SessionStart, Setup, CwdChanged, and FileChanged hooks.

A static alternative exists — point `CLAUDE_ENV_FILE` at a fixed shell script
before launching Claude Code — but the SessionStart hook is the portable,
dynamic choice and is what this repo ships.

### Steps

1. Write (or extend) a SessionStart hook script that appends an `export` line
   per directory to `$CLAUDE_ENV_FILE`. Read the worked, tested reference
   first: `~/.dots/agents/hooks/session-start-path.sh`. It is idempotent,
   guards that each directory exists, and prepends rather than clobbers. Mirror
   its shape rather than writing a new pattern from scratch. The core line is:

   ```bash
   export PATH="/your/dir:$PATH"
   ```

   Keep `$PATH` literal (escaped or single-quoted in the heredoc/printf) so it
   expands when the env file is sourced, not when the hook runs.

2. Make the hook a no-op when `$CLAUDE_ENV_FILE` is unset, and append each
   export only if the file does not already contain it (the file persists
   across repeated SessionStart fires within a session).

3. Register the hook in settings.json under `hooks.SessionStart`, invoked via
   `bash`. In this repo, registration is handled by `dots install agents`; for
   a standalone setup, add the SessionStart entry to `~/.claude/settings.json`.
   Use the `/update-config` skill for the settings.json edit mechanics.

4. Verify in a fresh session: run the bare command name in the Bash tool and
   confirm it resolves.

### What NOT to do

- Do not set `env.PATH` in settings.json to add a directory (it replaces, and
  is not variable-expanded — see footguns 1 and 2).
- Do not add the PATH export only to `~/.zshrc`/`~/.zshenv` and expect the
  Bash tool to pick it up (footgun 3).

## References

- Bash tool behavior (what gets sourced at session start):
  https://code.claude.com/docs/en/tools
- Persisting environment variables across Bash commands via CLAUDE_ENV_FILE
  and SessionStart hooks: https://code.claude.com/docs/en/hooks
- Worked reference implementation in this repo:
  ~/.dots/agents/hooks/session-start-path.sh
