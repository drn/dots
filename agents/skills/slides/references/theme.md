# Theming

The aesthetic is swappable. Everything visual lives in the `:root` block and the
`<head>` font link of `template.html` — the slide markup and nav JS are theme-agnostic.

## Color and font variables

In `:root`:

| Variable | Role | Default (terminal/TUI) |
|----------|------|------------------------|
| `--bg` | page background | `#07090f` |
| `--bg-raise` | raised surfaces (status bar, window frames) | `#0c1018` |
| `--ink` | primary text | `#e8edf2` |
| `--dim` | secondary text | `#5c6878` |
| `--faint` | borders, rules | `#2a3240` |
| `--teal` | ACCENT — emphasis, keys, progress | `#19c2bd` |
| `--teal-dark` | muted accent (divider numbers) | `#0c615e` |
| `--amber` | warm highlight (branch label) | `#e8b04b` |
| `--red` | warning / negative (`.x`) | `#e0556a` |
| `--green` | positive / ok (`.ok`) | `#5dd39e` |
| `--mono` | body font | JetBrains Mono |
| `--serif` | display font (headings) | Instrument Serif |

To re-skin: change `--teal` (the accent that ties the deck together), then
`--bg`/`--ink` for the base palette. The accent also appears hard-coded in a few
`rgba(25,194,189,...)` glows (progress bar, divider rule, screenshot shadow) — if
you change `--teal` to a very different hue, update those rgba values to match.

## Swapping fonts

1. Replace the Google Fonts `<link>` in `<head>` with the families you want.
2. Update `--mono` and `--serif` in `:root` to reference them.

The display font (`--serif`) carries most of the character — it renders all the
`h1` headings. The body font (`--mono`) renders bullets, crumbs, and chrome.

## Offline / no-network decks

The template loads fonts from `fonts.googleapis.com`. If the deck must render
where network is blocked (some artifact sandboxes), it falls back to system
serif/mono — layout is unaffected, but the look degrades.

For a fully self-contained, offline deck:
- Download the font files (woff2) and embed them as base64 `@font-face` rules in
  the `<style>` block, dropping the `<link>`, or
- Accept the system-font fallback and pick `--mono`/`--serif` stacks that look
  acceptable without the web fonts.

Images are made offline-safe separately, by `scripts/inline-images.py` (see SKILL.md Step 6).

## Lighter / non-terminal looks

The scanline, grain, and vignette overlays create the CRT/terminal feel. To move
toward a clean modern look:
- Remove or reduce `body::before` (scanlines) and the `.grain` element.
- Soften `body::after` (vignette) or remove it.
- Flip `--bg`/`--ink` for a light theme and lower the glow `rgba` alphas.
