# Slide Archetypes

Every slide is a `<section class="slide ARCHETYPE">` inside `<main class="deck">`.
There are six archetypes. Pick the one that fits the idea — do not invent new
classes unless you also add matching CSS to the theme block.

## title

The opening slide. One per deck, first.

```html
<section class="slide title" data-section="opening">
  <div class="boot">
    <span class="ok">●</span> a scene-setting status line<br>
    <span class="ok">●</span> another line
  </div>
  <h1>Talk Title<br>With an <em>emphasis</em></h1>
  <div class="sub">Subtitle · <b>Event</b> · Month Year</div>
</section>
```

- `data-section` is required on this first slide, or early slides show a blank status-bar label (see SKILL.md Step 4).
- `.boot` is an optional flavor block (terminal-style status lines). Drop it for a cleaner title.
- `<em>` inside `h1` renders in the accent color + italic serif.
- `.sub` is an uppercase, letter-spaced footer line; `<b>` inside it is amber.

## big

A single bold statement. The workhorse for impact slides. One idea, no bullets.

```html
<section class="slide big">
  <div class="crumb">section crumb</div>
  <h1>One bold line with an <em>emphasized</em> phrase.<span class="cursor"></span></h1>
</section>
```

- `.crumb` is an optional uppercase breadcrumb above the statement.
- `.cursor` is an optional blinking block cursor — use sparingly, e.g. a punchy reveal.
- Keep `h1` to roughly one sentence. If it reads like a paragraph, split it into two `big` slides.

## divider

A section opener with a huge outlined number.

```html
<section class="slide divider" data-section="01 · section name">
  <div class="num">01</div>
  <h1>Section name</h1>
  <div class="rule"></div>
  <!-- optional framing crumb under the rule: -->
  <div class="crumb" style="margin:3vh 0 0">a one-line framing note</div>
</section>
```

- `data-section="..."` sets the status-bar label that holds from this slide until the next `data-section` (see SKILL.md Step 4). Put it on the slide that opens a section.
- `.num` is the section number. **It is hand-written** — keep 01/02/03… in order, matching the section sequence.
- `.rule` is the glowing accent underline.

## list

Up to ~5 bullets. One concept per slide; 5 points is often 5 slides, not one dense list.

```html
<section class="slide list">
  <h1>List slide title</h1>
  <ul>
    <li><b>Accent key</b> — supporting detail</li>
    <li>A point with a <span class="x">negative</span> callout</li>
    <li>A point with a <span class="ok">positive</span> callout</li>
  </ul>
</section>
```

- `<b>` = teal accent key (lead term). `.x` = red/warning. `.ok` = green/positive.
- Hard cap at 5 `<li>`. More than that means the slide is doing two jobs — split it.

## shot

A screenshot inside a macOS-style window frame.

```html
<section class="slide shot">
  <h1>Screenshot slide title</h1>
  <div class="win">
    <div class="bar"><i></i><i></i><i></i></div>
    <img src="screenshot.png" alt="Describe the screenshot">
  </div>
</section>
```

- `src` is a relative path beside the HTML. Always write a real `alt`.
- The three `.bar i` dots are the red/amber/green traffic lights — leave them.
- Use real product screenshots, not stock imagery.

## question

A centered italic closing question.

```html
<section class="slide question">
  <h1>A rhetorical closing question with a <span class="hl">highlight</span>?</h1>
</section>
```

- `.hl` highlights a phrase in the accent color.
- Typically the last slide.
