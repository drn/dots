---
name: write-skill
description: Create or improve a Claude Code skill/slash command with best practices for structure, dynamic context, and safety
---

# Skill Author

Create or improve Claude Code skills (slash commands) following established patterns and avoiding known pitfalls.

## Arguments

- `$ARGUMENTS` - What the skill should do, or the name of an existing skill to improve

## Context

- Existing skills: !`find ~/.claude/commands -maxdepth 1 -name "*.md" -exec basename {} .md \; 2>/dev/null | sort | head -30`
- Project type: !`find . -maxdepth 1 \( -name go.mod -o -name Gemfile -o -name package.json -o -name Cargo.toml -o -name pyproject.toml \) 2>/dev/null | head -3`

## Instructions

### Step 1: Understand the Request

Determine whether the user wants to:
- **Create a new skill** from a description
- **Improve an existing skill** (read it first, then apply changes)

If creating, ask the user what the skill should do if `$ARGUMENTS` is vague.

### Step 2: Design the Skill

Plan the skill structure:

1. **Frontmatter** (YAML between `---` fences)
2. **Context section** (dynamic context via shell commands)
3. **Instructions** (what Claude should do when the skill is invoked)

### Step 3: Write the Skill File

Write the `.md` file to `claude/commands/<name>.md`.

Follow all rules below carefully.

---

## Skill File Reference

### Frontmatter

All fields are optional. Only `description` is strongly recommended.

```yaml
---
description: One-line summary of what this skill does and when to use it
allowed-tools: Bash(git *), Bash(npm test)
---
```

| Field | Purpose |
|---|---|
| `description` | Drives auto-activation and `/` menu. Write in third person. Max 1024 chars. Include trigger keywords. |
| `allowed-tools` | Tools Claude can use without asking permission. Glob patterns supported. |
| `context` | Set to `fork` to run in an isolated subagent (no conversation history). |
| `agent` | Subagent type when `context: fork` (e.g., `Explore`, `Plan`). |
| `model` | Override model (e.g., `sonnet` for cheaper tasks). |
| `disable-model-invocation` | `true` to prevent auto-loading (manual `/name` only). Use for destructive skills. |
| `user-invocable` | `false` to hide from `/` menu (background knowledge only). |

### Dynamic Context

Inject live data by writing an exclamation mark followed by a command wrapped in backticks. The command runs locally and its output replaces the placeholder before Claude sees the prompt.

In the examples below, !{command} represents the actual syntax (exclamation mark + backtick + command + backtick). Curly braces are used here to prevent this skill file from executing its own examples.

```markdown
## Context

- Current branch: !{git branch --show-current}
- Git status: !{git status --short}
- Project type: !{ls -1 go.mod package.json Cargo.toml 2>/dev/null | head -3}
```

#### CRITICAL: No `$()` Command Substitution

Claude Code blocks `$()` inside dynamic context expressions for security reasons. This is the single most common authoring mistake.

```markdown
# BROKEN — $() is blocked
- Branch commits: !{DEFAULT=$(git symbolic-ref ...) && git log origin/$DEFAULT..HEAD}
- Changes: !{git diff --stat HEAD...$(git symbolic-ref ...)}

# FIXED — single commands with error suppression
- Branch commits: !{git log origin/HEAD..HEAD --oneline 2>/dev/null}
- Changes: !{git diff --stat HEAD...origin/HEAD 2>/dev/null}
```

**Alternatives to `$()`:**
- Pipe chains: `command1 | command2 | command3`
- Error suppression: `command 2>/dev/null` (empty output on failure is fine)
- Use `origin/HEAD`: resolves to whatever the remote default branch is, no hardcoding needed
- Separate context lines: split a complex command into multiple simpler dynamic context lines

#### Output Size Management

Always bound output to avoid blowing up the context window:

```markdown
# GOOD — bounded output
- Files: !{find . -maxdepth 3 -name "*.go" 2>/dev/null | head -20}
- Commits: !{git log --oneline -10}

# BAD — unbounded, could be massive
- Files: !{find . -name "*.go"}
- Log: !{git log}
```

#### Error Handling and Exit Codes

**Never use `||` or `&&`** — Claude Code's permission system treats these as multiple operations and blocks them.

Use `2>/dev/null` to suppress stderr, but **it does not fix exit codes**. When a command fails, the skill loader sees the non-zero exit code and treats it as an error, even though stderr is suppressed. This breaks skill loading entirely.

**Fix: always pipe through `| head -N`** after `2>/dev/null`. In a pipeline, the exit code is that of the last command (`head`), which exits 0 even when the upstream command fails and produces no output.

```markdown
# BAD — 2>/dev/null suppresses stderr but exit code is still non-zero
- Tag: !{git describe --tags --abbrev=0 2>/dev/null}
- Commits: !{git log origin/master..HEAD --oneline 2>/dev/null}

# BAD — || treated as multiple operations by permission system
- Tag: !{git describe --tags --abbrev=0 2>/dev/null || echo "No tags"}

# GOOD — pipe neutralizes exit code, empty output on failure is fine
- Tag: !{git describe --tags --abbrev=0 2>/dev/null | head -1}
- Commits: !{git log origin/master..HEAD --oneline 2>/dev/null | head -50}
```

### String Substitutions

| Variable | Description |
|---|---|
| `$ARGUMENTS` | All arguments the user passed after `/skill-name` |
| `$ARGUMENTS[0]`, `$1` | First argument (0-indexed) |

### Skill Body Best Practices

1. **Be concise.** Only add context Claude does not already have. The context window is shared.
2. **Use imperative instructions.** Tell Claude what to do, not what the skill "can" do.
3. **Structure with numbered steps.** Makes execution predictable and debuggable.
4. **Include abort conditions.** Define when to stop (e.g., "if no changes, tell the user and stop").
5. **Set loop limits.** If the skill loops (CI check/fix), cap retries (e.g., "if stuck 3+ times, stop and report").
6. **Avoid backticks in prose.** The skill content passes through shell evaluation; inline code fences can break parsing. Use plain text or code blocks (triple backtick fences) instead of inline backticks where possible.
7. **Avoid contractions.** Words like "don't" or "can't" can break due to single-quote shell interpretation.
8. **Match specificity to fragility.** Give high freedom for flexible tasks, exact commands for fragile operations.
9. **Use `disable-model-invocation: true`** for skills with side effects (deploy, merge, send).

### Existing Skill Patterns in This Repo

Skills in `claude/commands/` follow this general structure:

```
---
description: ...
allowed-tools: ...  (optional)
---

## Context
- Key info: !{command}

## Your task / Instructions
Step-by-step instructions for Claude.

### Step 1: ...
### Step 2: ...
```

Multi-agent skills (like `/dev`, `/debug`, `/explore`) use the Task tool to spawn subagents with specific roles.

---

### Step 4: Validate

After writing, check the skill for:
- [ ] No `$()` in any dynamic context line
- [ ] No `||` or `&&` operators in any dynamic context line
- [ ] Error-prone commands use `2>/dev/null | head -N` (suppresses stderr AND neutralizes exit code)
- [ ] No bare `2>/dev/null` without a trailing pipe (exit code breaks skill loading)
- [ ] Description is present and includes trigger keywords
- [ ] No inline backticks in prose that could break shell evaluation
- [ ] No contractions (don't, can't, won't) in the skill body
- [ ] Destructive skills have `disable-model-invocation: true`

Report the validation results and the file path of the new/updated skill.
