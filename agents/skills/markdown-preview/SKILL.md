---
name: markdown-preview
description: Render a Markdown file to GitHub-flavored HTML and open a styled local preview (light + dark) in the browser. Use when the user wants to preview markdown, see how a README renders on GitHub, check that relative screenshots or images display correctly, or get a GitHub-like local preview without installing grip or glow.
allowed-tools: Bash(bash *), Bash(gh api *), Bash(rm *), Read, Edit
---

# Markdown Preview

Render a Markdown file the way GitHub would (GFM: tables, task lists, fenced
code) and open a self-contained, GitHub-styled HTML preview with light and dark
support. Rendering goes through `gh api /markdown`, so no local renderer
(grip/glow) is needed — only an authenticated `gh` CLI and `jq`.

The preview is written ALONGSIDE the source file by default. This is
deliberate: relative image paths (e.g. `screenshots/foo.png`) only resolve when
the HTML lives in the same directory as the markdown.

## When to stop and ask

- If no markdown file path is given and none is obvious from context, ask the
  user which file to preview. Do not guess.
- If the file is not a markdown file (`.md` / `.markdown`), confirm before
  rendering.

## Privacy note

`gh api /markdown` sends the file's contents to GitHub over the network. This
is fine for public README / docs content. If the markdown contains anything
sensitive, tell the user it will leave the machine and confirm before rendering.

## Workflow

### Step 1 — Resolve the file

Identify the markdown file path from the argument (`$1`) or conversation
context. Confirm it exists.

### Step 2 — Render and open

Run the render script. `<skill-dir>` is the directory containing this SKILL.md:

```
bash <skill-dir>/scripts/render.sh <file.md>
```

This renders via `gh api /markdown`, writes `<file>-preview.html` next to the
source, and opens it in the default browser (macOS `open`, Linux `xdg-open`,
Windows `start`).

Useful flags:
- `--no-open` — write the preview but do not launch a browser.
- `--out <path>` — choose the output path. Use ONLY when the markdown has no
  relative images; a path outside the source directory breaks relative `src`.

If the script reports `gh` is not installed or `gh api /markdown` failed,
relay the error: the user likely needs to install `gh` or run `gh auth status`.
Do not retry more than once.

### Step 3 — Cleanup

The preview is a temporary artifact and should not be committed. After the user
is done viewing:
- Offer to remove it: `rm <file>-preview.html`.
- If the file sits inside a git repository, optionally suggest adding
  `*-preview.html` to `.gitignore` so regenerating it does not leave untracked
  files (this was the original pain point this skill was built to avoid).

To re-preview after editing the markdown, just rerun Step 2 — it overwrites the
existing preview.
