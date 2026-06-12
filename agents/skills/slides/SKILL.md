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
2. Choose a destination directory for the deck. Decks are talk material, not
   product code — do not commit one into an unrelated code repo. Good defaults:
   a `presentation/` folder the user names, alongside the source material, or
   `~/presentations/<talk-slug>/`.
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
- The window-tab label and the status-bar context label — both marked with
  `<!-- EDIT: ... -->` comments in the HTML body. Keep them short.

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

### Step 4 — Set section labels and divider numbers

The status bar shows a section label that holds from the slide opening a section
until the next one. Sections are declared inline with a `data-section="..."`
attribute on the slide that OPENS each section, and the `<script>` derives the
label list from the DOM at load — so adding or removing slides never desyncs the
labels. To structure the deck:
1. Put `data-section="label"` on the FIRST slide of each section (the opening
   `title`, each `divider`, and any mid-deck transition you want labelled). The
   very first slide must carry one, or early slides show a blank label.
2. The divider `.num` values (`01`, `02`, …) are still hand-written — keep them
   sequential and matching the section order. This is the one remaining manual
   sync, so check it after reordering sections.

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

### Step 6 — Publish as a shareable artifact (optional, for mobile viewing)

The primary deliverable is the self-contained `index.html` — it opens in any
browser as-is. This step is only for viewers that render a registered artifact
(such as Argus, for viewing on a phone).

The on-disk deck references screenshots by relative path, but an artifact viewer
sandbox has no relative-asset guarantee. Inline the images into a self-contained
copy first, then register that copy:
1. Produce an inlined copy (writes to the system temp dir by default):
   ```
   python3 <skill-dir>/scripts/inline-images.py <dest>/index.html
   ```
   This base64-encodes every local `<img>` into a data URI and prints the output path.
2. Register the inlined copy via your artifact tool (e.g. the Argus
   `artifact_register` tool, if available).
3. Re-run both steps after every edit — registration is typically last-write-wins
   on the same title.

If the sandbox blocks network, the Google-fonts dependency falls back to system
serif/mono (layout unaffected, look degraded). For a fully offline deck, self-host
or inline the fonts — see `references/theme.md`.

## Done criteria

- `index.html` opens in a browser and navigates with arrows, `o`, `?`, tap, and swipe.
- Every slide is one of the six archetypes; no slide is a wall of text.
- Section labels (`data-section`) and divider numbers match the actual slide order.
- The `slide N/M` total matches the real count.
- Every technical claim on a slide is verified against the source.

## Files

- `template.html` — the baseline deck (theme block at top, slides in `<main>`, nav JS at bottom).
- `references/archetypes.md` — markup for each of the six slide archetypes.
- `references/content-guide.md` — narrative and text conventions.
- `references/theme.md` — theming variables and offline-font notes.
- `scripts/inline-images.py` — base64-inline images for artifact registration.
