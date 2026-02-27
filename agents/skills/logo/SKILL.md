---
name: logo
description: Logo Generation
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

| # | Direction | What to Try |
|---|-----------|-------------|
| 1 | **Minimal** | Strip to the essential mark. One shape, one gradient. App icon clean. |
| 2 | **Geometric** | Low-poly, faceted, angular. Crystal/tech aesthetic. |
| 3 | **Organic** | Flowing curves, natural forms. Warmth and craft. |
| 4 | **Structural** | Architectural forms, layered shapes, or negative space. The structure is the mark. |
| 5 | **Conceptual** | Symbolic/metaphorical. Combine two ideas into one mark (e.g., flame + orbits). |
| 6 | **Bold** | High-contrast, strong presence. Thick strokes, confident shapes. Statement piece. |

**CRITICAL: No text in logos.** Never use `<text>` elements, letters, words, or typographic marks in the SVG logos. Every logo must be purely symbolic — shapes, icons, and abstract marks only. Text/wordmarks are added separately by the user if needed.

**SVG quality standards:**
- Always include explicit `width="200" height="200"` on the `<svg>` element (required for `<img>` tag rendering)
- **Transparent background** — do not include a background `<rect>`. The comparison page provides the dark background via the `.well` container. Logos must work on any background.
- Use `<defs>` for gradients, filters, and reusable elements
- Include glow/blur filters for light-emitting elements (`feGaussianBlur` + `feMerge`)
- Use `linearGradient` for directional surfaces, `radialGradient` for point-light and glow
- Layer elements: ambient light → structure → hero element → accents
- Keep the viewBox at `0 0 200 200` for the main logo

Save to the project's `assets/` directory:
- `assets/logo-alt-1.svg` through `assets/logo-alt-6.svg`
- If there's an existing logo, include it as the "Current" option

### Step 3: Generate Comparison Page

Create `assets/logo-compare.html` — a dark-themed grid page showing all options side-by-side.

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
    text-align: center;
    background: #1a1a1a;
    border-radius: 16px;
    padding: 32px 24px 24px;
    border: 1px solid #2a2a2a;
    transition: border-color 0.2s;
  }
  .card:hover { border-color: #F59E0B44; }
  .well { display: flex; align-items: center; justify-content: center; width: 160px; height: 160px; margin: 0 auto 16px; background: #111; border-radius: 12px; }
  .well img { width: 140px; height: 140px; }
  .card h3 { color: #F59E0B; font-size: 16px; margin-bottom: 6px; }
  .card p { color: #888; font-size: 12px; line-height: 1.5; }
  .label { display: inline-block; background: #F59E0B22; color: #F59E0B; padding: 2px 10px; border-radius: 12px; font-size: 11px; margin-bottom: 12px; }
  .current .label { background: #22c55e22; color: #22c55e; }
</style>
</head>
<body>
  <h1>[Project] Logo Alternatives</h1>
  <p class="subtitle">6 design directions. Click any logo to open full-size SVG.</p>
  <div class="grid">
    <!-- If there is an existing logo, include it as the first card with class="card current" and label CURRENT -->
    <div class="card">
      <span class="label">ALT 1</span>
      <div class="well"><a href="logo-alt-1.svg" target="_blank"><img src="logo-alt-1.svg" alt="Alt 1"></a></div>
      <h3>[Short Name]</h3>
      <p>[1-line description]</p>
    </div>
    <!-- ... repeat for ALT 2 through ALT 6 ... -->
  </div>
</body>
</html>
```

### Step 4: Open and Present

1. Open the comparison HTML in the browser: `open assets/logo-compare.html`
2. Present a summary table of all options with name and concept
3. Offer to refine, mix elements, or apply the chosen design

### Step 5: Apply the Winner

When the user picks a logo:

1. Copy it to `favicon.svg` in the project root
2. Add the logo to the top of the project's README, centered at 120px width:
   ```html
   <p align="center"><img src="favicon.svg" width="120"></p>
   ```
   Insert this as the very first line, before any existing heading or content.
3. Clean up the `logo-alt-*.svg` files and `logo-compare.html`

## Design Principles

1. **Distinct directions** — Each alternative should be recognizably different at a glance, not minor tweaks
2. **SVG-native** — Use gradients, filters, and transforms. No raster effects.
3. **Scale well** — Design should read clearly at 32px (favicon) and 200px (logo)
4. **Dark-first** — Assume dark backgrounds. Light elements should glow.
5. **Layered depth** — Background → ambient glow → structure → hero → sparkle/accent
6. **Name each option** — Short, memorable names make discussion easier ("Orbital Forge" vs "Alt 5")