---
name: slides
description: Build a self-contained, single-file HTML presentation deck from talking points or a source doc, using a terminal/TUI-styled template with keyboard, tap, and swipe navigation. Use when the user wants to create slides, build a presentation or deck, turn talking points or a doc into a talk, make an HTML slideshow, or produce a presentation as a shareable artifact (instead of Google Slides).
---

# HTML Presentation Deck

Generate a polished, single-file HTML slide deck from a `template.html` baseline.
No build step — all CSS and JS are inline, so the deck opens directly in a
browser and renders as an Argus artifact on desktop and phone.

The template ships a terminal/TUI aesthetic (dark background, accent color,
monospace + serif fonts) and a full navigation model: keyboard, an overview
grid, a help overlay, URL-hash sync, a progress bar, plus mobile tap-to-advance
and swipe. Preserve all of that — you change content and theme, not the nav JS.

## When to stop and ask

If the request is vague ("make me some slides"), ask the user for:
- the talk's topic and audience, and
- source material (a doc, bullet list, or talking points), or whether you should draft an outline first.

Do not invent a whole talk from nothing.

## Workflow

### Step 1 — Gather source and set up the deck

1. Collect the source content: a doc, talking points, or an outline the user provides.
2. Choose a destination directory for the deck (default: a `presentation/` folder
   the user names, or alongside the source material). Decks are talk material,
   not product code — do not commit a deck into an unrelated repo.
3. Copy the template into place:
   ```
   cp <skill-dir>/template.html <dest>/index.html
   ```
   `<skill-dir>` is the directory containing this SKILL.md.

### Step 2 — Set the theme and chrome

Edit the top of `index.html`:
- `<title>` — browser tab text.
- The `:root` block — colors and fonts. The defaults are a terminal look; change
  `--teal` (accent), `--bg`, and `--mono`/`--serif` to re-skin. See `references/theme.md`.
- `.frame .tab` — the window-tab label (short).
- `.statusbar .branch` — the context/branch label.

To swap fonts, also update the Google Fonts `<link>` in `<head>`. If the deck must
work fully offline, see the self-host note in `references/theme.md`.

### Step 3 — Write the slides

Replace the example `<section class="slide ...">` blocks in `<main class="deck">`
with the real content. Each slide is one of six archetypes: `title`, `big`,
`divider`, `list`, `shot`, `question`. Read `references/archetypes.md` for the
exact markup of each, and `references/content-guide.md` for the narrative rules
(one idea per slide, minimal text, more slides less text, questions as slides,
big statements, no name-dropping as proof, factual precision on technical claims).

Verify any specific technical claim (security boundaries, numbers, what a system
does) against the source before it goes on a slide.

### Step 4 — Update the SECTIONS array (critical)

The status bar shows a section label derived from a hand-maintained array in the
`<script>`:
```
const SECTIONS = [ [firstSlideNumber, "label"], ... ];
```
Each entry maps a section's FIRST slide number (1-indexed) to its label.

**This is the number-one footgun.** Adding or removing any slide shifts every
later slide number by ±1, so the labels — and the divider `01`/`02`/… numbers —
desync silently. After ANY structural change to the slide list:
1. Recount the slides in document order.
2. Re-derive each section's first-slide number and update `SECTIONS`.
3. Confirm each `divider` `.num` matches its section position.

The `slide N/M` total auto-updates from `slides.length` at runtime, so ignore the
static `id="total"` value in the HTML — the JS overwrites it.

### Step 5 — QA every slide type

1. Open the deck locally to eyeball it:
   ```
   open <dest>/index.html
   ```
2. For automated screenshot QA, drive it with Playwright and read the images
   back. Capture at least one slide of each archetype used. Verify:
   - the section label in the status bar is correct on each section's first slide,
   - the `slide N/M` total equals the real slide count,
   - divider numbers are sequential,
   - screenshots render and are not cut off.

   IMPORTANT: run Playwright from a directory where it is installed (a `web-tests/`
   or similar with `npm ci` already done), not from an arbitrary repo root, or it
   throws `Cannot find module 'playwright'`. `cd` into that directory first and
   point the script at the deck's absolute path.

Fix any desync found here by returning to Step 4.

### Step 6 — Register as an Argus artifact (optional, for mobile viewing)

The on-disk deck references screenshots by relative path, but the artifact viewer
sandbox has no relative-asset guarantee. Inline the images into a self-contained
copy first, then register that copy:
1. Produce an inlined copy:
   ```
   python3 <skill-dir>/scripts/inline-images.py <dest>/index.html /tmp/deck.inlined.html
   ```
   This base64-encodes every local `<img>` into a data URI.
2. Register `/tmp/deck.inlined.html` via the Argus `artifact_register` tool.
3. Re-run both steps after every edit — registration is last-write-wins on the
   same title.

If the artifact sandbox blocks network, the Google-fonts dependency falls back to
system serif/mono (layout unaffected, look degraded). For a fully offline deck,
self-host or inline the fonts — see `references/theme.md`.

## Done criteria

- `index.html` opens in a browser and navigates with arrows, `o`, `?`, tap, and swipe.
- Every slide is one of the six archetypes; no slide is a wall of text.
- `SECTIONS` and divider numbers match the actual slide order.
- The `slide N/M` total matches the real count.
- Every technical claim on a slide is verified against the source.

## Files

- `template.html` — the baseline deck (theme block at top, slides in `<main>`, nav JS at bottom).
- `references/archetypes.md` — markup for each of the six slide archetypes.
- `references/content-guide.md` — narrative and text conventions.
- `references/theme.md` — theming variables and offline-font notes.
- `scripts/inline-images.py` — base64-inline images for artifact registration.
