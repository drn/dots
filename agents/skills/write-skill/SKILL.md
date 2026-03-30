---
name: write-skill
description: Create or improve a Claude Code skill/slash command with best practices for structure, dynamic context, and safety. Use for creating new skills, improving existing ones, or learning skill authoring.
---

# Skill Author

Create or improve Claude Code skills (slash commands) following established patterns and avoiding known pitfalls.

## Arguments

- `$ARGUMENTS` - What the skill should do, or the name of an existing skill to improve

## Context

- Global skills: !`find ~/.claude/commands -maxdepth 1 -name "*.md" -exec basename {} .md \; 2>/dev/null | sort | head -20`
- Project skills (Agent Skills standard): !`find . -maxdepth 3 -path "*/skills/*/SKILL.md" 2>/dev/null | head -20`
- Project skills (Claude Code standard): !`find . -path "./claude/commands/*.md" 2>/dev/null | head -20`
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

Detect the project skill convention from the context above:
- If the project has skills matching `*/skills/*/SKILL.md` (Agent Skills standard), create `<skills-dir>/<name>/SKILL.md`
- Otherwise, create `claude/commands/<name>.md` (Claude Code standard)

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

# FIXED — detect base branch portably, provide both branches
- Base ref: !{git branch -r 2>/dev/null | grep -oE 'origin/(main|master)' | head -1}
- Commits vs main: !{git log origin/main..HEAD --oneline 2>/dev/null | head -20}
- Commits vs master: !{git log origin/master..HEAD --oneline 2>/dev/null | head -20}
- Changes vs main: !{git diff --stat HEAD...origin/main 2>/dev/null | head -50}
- Changes vs master: !{git diff --stat HEAD...origin/master 2>/dev/null | head -50}
```

**Alternatives to `$()`:**
- Pipe chains: `command1 | command2 | command3`
- Error suppression: `command 2>/dev/null` (empty output on failure is fine)
- Detect base branch: `git branch -r | grep -oE 'origin/(main|master)' | head -1` — portable, no custom tools needed
- Provide both branches: include `origin/main` and `origin/master` variants — one will be empty, the agent uses whichever has output
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
10. **Keep skills generic.** This is a public repo. Never embed company names, internal tool names, proprietary patterns, or org-specific conventions. Skills should work for any user. Put org-specific knowledge in private CLAUDE.md files or project-local config instead.

### Existing Skill Patterns

Skills follow this general structure (path varies by convention -- see Step 3):

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

After writing, run two validation passes. Fix issues silently — only flag if the fix would change the skill's intent.

#### Syntax and Safety

- [ ] No `$()` in any dynamic context line
- [ ] No `||` or `&&` operators in any dynamic context line
- [ ] Error-prone commands use `2>/dev/null | head -N` (suppresses stderr AND neutralizes exit code)
- [ ] No bare `2>/dev/null` without a trailing pipe (exit code breaks skill loading)
- [ ] Description is present and includes trigger keywords
- [ ] No inline backticks in prose that could break shell evaluation
- [ ] No contractions (don't, can't, won't) in the skill body
- [ ] Destructive skills have `disable-model-invocation: true`
- [ ] No company-specific names, internal tools, or proprietary patterns (this is a public repo)

#### Content Quality

Scan the skill for these failure patterns. Fix any you find — these are the patterns that cause skills to waste tokens, loop endlessly, or produce wrong results.

**Task clarity**
- [ ] No vague verbs ("help with", "handle", "deal with") — replace with precise operations ("refactor", "extract", "migrate")
- [ ] Single responsibility — skill does one thing, not two unrelated tasks bundled together
- [ ] Success criteria defined — the skill states what "done" looks like, not just what to do

**Scope control**
- [ ] Skills that edit code specify file/directory boundaries, not global instructions
- [ ] Skills that spawn agents scope each agent to specific files or responsibilities
- [ ] No unbounded work — complex tasks are broken into numbered steps with clear boundaries

**Stop conditions**
- [ ] Agentic skills (using Task tool, running commands, editing files) have explicit stop/abort conditions
- [ ] Looping skills cap retries (already covered in best practice #5, but verify it is present)
- [ ] Skills that call external services have failure modes defined ("if X fails, do Y" not infinite retry)

**Context efficiency**
- [ ] Dynamic context pulls only what the skill needs — no exploratory commands that dump large output
- [ ] Instructions tell Claude what to do, not background theory on how it works
- [ ] No redundant context — if CLAUDE.md already provides information, the skill does not re-derive it

Report the validation results and the file path of the new/updated skill.
