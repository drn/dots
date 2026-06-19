---
name: logo
description: Generate SVG logo alternatives with side-by-side comparison. Use when creating logos, branding, or project icons.
---
# Logo Generation

Generate SVG logo alternatives for a project, then present them in a side-by-side comparison page for review.

## Arguments

- `$ARGUMENTS` - Description of the logo concept, style direction, or project name

## Instructions

You are generating SVG logo alternatives and a visual comparison page. Your goal is to produce **6 distinct design directions** so the user can pick and refine.

### Step 1: Understand the Brief

Determine what the logo should communicate:

1. **Project name** — What is the logo for?
2. **Core concept** — What metaphor or visual idea? (e.g., "forge + AI agents", "speed + reliability")
3. **Style direction** — Modern/minimal, geometric, organic, playful, corporate?
4. **Color palette** — Dark background? Brand colors? Warm/cool?
5. **Shape** — Circle, rounded rect, hexagon, freeform?
6. **Existing logo** — Is there a current logo to improve on? Read it first.

If unclear, ask the user before generating.

### Step 2: Design 6 Alternatives

Create 6 **meaningfully different** SVG logo files. Each should explore a distinct visual direction:

| # | Direction | Color | What to Try |
|---|-----------|-------|-------------|
| 1 | **Minimal** | Amber/Gold | Strip to the essential mark. One shape, one gradient. App icon clean. |
| 2 | **Geometric** | Cyan/Teal | Low-poly, faceted, angular. Crystal/tech aesthetic. |
| 3 | **Organic** | Violet/Purple | Flowing curves, natural forms. Warmth and craft. |
| 4 | **Typographic** | Emerald/Green | Lettermark or monogram. The initial letter as hero. |
| 5 | **Conceptual** | Rose/Pink | Symbolic/metaphorical. Combine two ideas into one mark (e.g., flame + orbits). |
| 6 | **Sci-fi** | Blue/Indigo | Orbital, atomic, or space-inspired. Tech gravitas. |

**CRITICAL: No text in logos.** Never use `<text>` elements, letters, words, or typographic marks in the SVG logos. Every logo must be purely symbolic — shapes, icons, and abstract marks only. Text/wordmarks are added separately by the user if needed.

**SVG quality standards:**
- Always include explicit `width="200" height="200"` on the `<svg>` element (required for `<img>` tag rendering)
- **Namespace all `id` attributes per logo** (gradients, filters, clip paths): use `halo-1`, `core-grad-1` in `logo-alt-1.svg`, `halo-2` in `logo-alt-2.svg`, and so on. When the comparison page inlines every SVG into one document (Step 3), duplicate ids across files collide and marks render with the wrong fills.
- **Transparent background** — do not include a background `<rect>`. The comparison page provides the dark background via the `.well` container. Logos must work on any background.
- Use `<defs>` for gradients, filters, and reusable elements
- **For circular glow halos**, use `radialGradient` fills (not blur filters). Blur filters (`feGaussianBlur`) clip to a rectangular region and render as squares at small sizes. Use a `radialGradient` with opacity tapering to 0 at the edge, applied to a circle larger than the core element. Example:
    ```xml
    <radialGradient id="halo" cx="50%" cy="50%" r="50%">
      <stop offset="0%" stop-color="#COLOR" stop-opacity="0.6"/>
      <stop offset="40%" stop-color="#COLOR" stop-opacity="0.15"/>
      <stop offset="100%" stop-color="#COLOR" stop-opacity="0"/>
    </radialGradient>
    <circle cx="X" cy="Y" r="20" fill="url(#halo)"/>
    <circle cx="X" cy="Y" r="5" fill="#COLOR" opacity="0.9"/>
    ```
- Reserve `feGaussianBlur` for trail/path effects where rectangular clipping is less visible
- Use `linearGradient` for directional surfaces, `radialGradient` for point-light and glow
- Layer elements: ambient light → structure → hero element → accents
- Keep the viewBox at `0 0 200 200` for the main logo
- **Center precisely**: Calculate the bounding box of all visible elements and ensure its center is at (100, 100). For asymmetric layouts (e.g., 3 nodes around a hub), offset the composition so the bounding box center — not just the primary element — sits at (100, 100). Verify: (minX + maxX) / 2 ≈ 100, (minY + maxY) / 2 ≈ 100.

Save to the project's `assets/` directory:
- `assets/logo-alt-1.svg` through `assets/logo-alt-6.svg`
- If there's an existing logo, include it as the "Current" option

### Step 3: Generate Comparison Page

Create `assets/logo-compare.html` — a dark-themed grid page showing all options side-by-side.

**CRITICAL: Inline the SVGs — do not use `<img src="logo-alt-N.svg">`.** A relative `<img src>` renders on the local filesystem but breaks when the page is registered as an Argus artifact (Step 4b): the artifact viewer runs under a strict CSP with no network and no relative-path resolution, so every logo shows as a broken image. Inline each SVG instead so one page works in both contexts.

**How to inline:** Define each logo once as a hidden `<symbol>`, then render it with `<use>` at two sizes — the full-size well AND a small avatar (~36px round). The avatar is the real selection test: these marks become bot/GitHub/Linear avatars, and small-size legibility is what matters.

To turn a `logo-alt-N.svg` file into a symbol: copy everything **inside** its `<svg>` element into a `<symbol id="logo-N" viewBox="0 0 200 200">…</symbol>`. Keep the same `viewBox` the file uses (`0 0 200 200`). Ensure ids inside each file are namespaced per logo (see Step 2) so inlined gradients/filters do not collide.

`<symbol>`/`<use>` is preferred over data-URIs: one definition per mark, small file, readable markup, and it renders both locally and in the artifact viewer.

**Template:**

```html
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>[Project] Logo Alternatives</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { background: #111; color: #ccc; font-family: -apple-system, BlinkMacSystemFont, sans-serif; padding: 40px; }
  h1 { text-align: center; color: #F59E0B; margin-bottom: 12px; font-size: 28px; }
  .subtitle { text-align: center; color: #666; margin-bottom: 48px; font-size: 14px; }
  .grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 40px;
    max-width: 1000px;
    margin: 0 auto;
  }
  .card {
    display: flex;
    flex-direction: column;
    align-items: center;
    background: #1a1a1a;
    border-radius: 16px;
    padding: 32px 24px 24px;
    border: 1px solid #2a2a2a;
    transition: border-color 0.2s;
  }
  .card:hover { border-color: #F59E0B44; }
  .well { display: flex; align-items: center; justify-content: center; width: 160px; height: 160px; margin: 0 auto 16px; background: #111; border-radius: 12px; }
  .well svg { width: 140px; height: 140px; }
  .avatar-row { display: flex; align-items: center; justify-content: center; gap: 10px; margin-bottom: 16px; }
  .avatar { width: 36px; height: 36px; border-radius: 50%; background: #111; padding: 4px; }
  .avatar.light { background: #f5f5f5; }
  .avatar svg { width: 100%; height: 100%; }
  .card h3 { color: #F59E0B; font-size: 16px; margin-bottom: 6px; }
  .card p { text-align: center; color: #888; font-size: 12px; line-height: 1.5; }
  .label { display: inline-block; background: #F59E0B22; color: #F59E0B; padding: 2px 10px; border-radius: 12px; font-size: 11px; margin-bottom: 12px; }
  .current .label { background: #22c55e22; color: #22c55e; }
</style>
</head>
<body>
  <h1>[Project] Logo Alternatives</h1>
  <p class="subtitle">6 design directions. Full mark plus 36px avatar preview (dark + light).</p>

  <!-- Hidden symbol definitions: one <symbol> per logo, contents copied from each logo-alt-N.svg -->
  <svg width="0" height="0" style="position:absolute" aria-hidden="true">
    <symbol id="logo-1" viewBox="0 0 200 200"><!-- inner contents of logo-alt-1.svg --></symbol>
    <!-- ... repeat <symbol id="logo-2"> through <symbol id="logo-6"> ... -->
  </svg>

  <div class="grid">
    <!-- If there is an existing logo, include it as the first card with class="card current" and label CURRENT -->
    <div class="card">
      <span class="label">ALT 1</span>
      <div class="well"><svg viewBox="0 0 200 200"><use href="#logo-1"/></svg></div>
      <div class="avatar-row">
        <span class="avatar"><svg viewBox="0 0 200 200"><use href="#logo-1"/></svg></span>
        <span class="avatar light"><svg viewBox="0 0 200 200"><use href="#logo-1"/></svg></span>
      </div>
      <h3>[Short Name]</h3>
      <p>[1-line description]</p>
    </div>
    <!-- ... repeat for ALT 2 through ALT 6, referencing #logo-2 .. #logo-6 ... -->
  </div>
</body>
</html>
```

### Step 4: Open and Present

1. Open the comparison HTML in the browser: `open assets/logo-compare.html`
2. Present a summary table of all options with name and concept
3. Offer to refine, mix elements, or apply the chosen design

**Optional — register for mobile review (Argus):** If the `mcp__argus__artifact_register` tool is available, offer to register `assets/logo-compare.html` as an Argus artifact so the user can review the options on their phone. Pass the absolute path to the HTML file. This works only because Step 3 inlines the SVGs — a page using relative `<img src>` renders as broken images in the artifact viewer. If the tool is not available, skip silently.

### Step 4b: Refine the Winner (if requested)

When the user wants to vary a single element (e.g., center color, accent style):
1. Create 4-5 variants that ONLY change the requested element
2. Name each variant file descriptively (e.g., `center-1-white.svg`, `center-2-gold.svg`)
3. Generate a comparison page (`assets/<element>-compare.html`) using the same flexbox grid template
4. Open it for the user to pick
5. Apply the chosen variant to the main logo and clean up variant files

### Step 5: Apply the Winner

When the user picks a logo:

1. Copy it to `favicon.svg` in the project root
2. Add the logo to the top of the project's README, centered at 120px width:
   ```html
   <p align="center"><img src="favicon.svg" width="120"></p>
   ```
   Insert this as the very first line, before any existing heading or content.
3. If raster avatars are needed (GitHub org/Linear/bot avatars often require PNG), export a size set (512, 256, 64) from `favicon.svg`. **`sips` cannot convert SVG to PNG** — it only handles raster formats. Use whichever of these is installed:
   ```bash
   rsvg-convert -w 512 -h 512 favicon.svg -o favicon-512.png   # librsvg, preferred
   resvg favicon.svg favicon-512.png --width 512 --height 512   # resvg
   convert -density 384 -background none favicon.svg -resize 512x512 favicon-512.png   # ImageMagick
   ```
   Use a transparent background (`-background none` / default for the others) so the mark drops onto any avatar background. Repeat per size, or export 512 once and downscale.
4. Clean up the `logo-alt-*.svg` files and `logo-compare.html` (and any `*-compare.html` from Step 4b)

## Design Principles

1. **Distinct directions** — Each alternative should be recognizably different at a glance, not minor tweaks
2. **SVG-native** — Use gradients, filters, and transforms. No raster effects.
3. **Scale well** — Design should read clearly at 32px (favicon) and 200px (logo)
4. **Dark-first** — Assume dark backgrounds. Light elements should glow.
5. **Layered depth** — Background → ambient glow → structure → hero → sparkle/accent
6. **Name each option** — Short, memorable names make discussion easier ("Orbital Forge" vs "Alt 5")
7. **Unique palettes** — Each alternative MUST use a different color scheme. Never repeat the same palette across options.