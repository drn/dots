# Review artifact layout

Fill template.html (same directory level as SKILL.md) and publish it as a private artifact. Keep one self-contained file. Content comes from the verified findings, not from raw reviewer output.

## Sections, in order

1. **Header**: title naming the batch, a two-sentence lede (what the batch is for, date, how many PRs, how many are open), and one overall line with the recommended merge order.
2. **At a glance table**: one row per PR with link, one-line plain description, size, CI state, and a verdict pill. Verdict pill classes: ok (approve, approve-with-fixes), warn (needs-discussion, request-changes minor), bad (request-changes).
3. **Dependency graph**: inline SVG, left to right. Nodes are PRs (linked PRs in other repos drawn dashed), colored by verdict with the verdict also written in the node. Arrows are labeled "stacked on", "deploy first", or "conflicts with". Caption states the merge order. Omit the section when there are no dependencies.
4. **Cross-PR findings**: inconsistencies, conflicts, ordering and deploy dependencies, gaps. Omit the section when empty.
5. **One card per PR**, bottom of a stack first:
   - header: title, verdict pill, meta line (repo and number link, additions and deletions, file count, base branch, review depth)
   - "What it does": 2 to 4 plain sentences, no findings mixed in
   - "How it works" flow figure when the reviewer returned flow.applies true (see Diagrams below)
   - "Where to look": the reading order, a read-first list with reasons and a collapsed skim list, plus the file-impact map
   - "Test confidence": the rating as a pill with its two-sentence evidence
   - two columns: "Should fix" (blockers first, each with the failure scenario) and "Smaller notes" (nits, questions, good)
   - each finding is a list row with a checkbox, a severity tag, the text, and file:line when known; unverified findings carry an "unverified" tag
   - a "Questions for the author" list when present
6. **Open design questions**: each with a recommendation and the reason, when the source thread or PR bodies raised any.
7. **Appendix note**: source link, review depth per PR, what was not verified by execution, how many findings the verifier refuted, and the sentence "Nothing has been posted" (or what was posted, with URLs).

## Diagrams

- Draw only when a picture shows a mechanism faster than a sentence. Skip the flow figure when flow.applies is false.
- Put the plain-language description above every diagram; the diagram supports it, it never replaces it. Readable beats mechanically complete.
- Depict the mechanism: components, the data or request that moves, the boundary crossed. Show only what the change hinges on, at most 8 nodes.
- Show the difference: new nodes and edges in the accent color with a "new" label, removed ones dashed and struck through with a "removed" label, unchanged ones in the neutral foreground. Status must also be written, not color alone.
- Label every arrow with a verb. Use a legend only when an encoding repeats.
- Hand-author inline SVG with a viewBox, currentColor for strokes and text, marker arrowheads, a figure with a figcaption stating the claim, and role img with an aria-label carrying the same claim. No script, style, or foreignObject inside the SVG, and no external images.
- Text 11 to 13px, short labels, shared baselines on a grid. Explanations go in the caption.

## File-impact map

Per PR, one row per directory (or per file when fewer than 8 files): a bar whose width is lines changed, colored by the worst finding touching it (blocker, should-fix, none), with the finding count written beside it. Generated, lock, snapshot, and fixture files are grouped into one muted "skippable" row. Build it from HTML and CSS bars, not SVG, so it wraps on narrow screens.

## Review-assist controls

- Every finding row has a checkbox, checked by default for blocker and should-fix, unchecked for nit, question, and good.
- Per card, a "Copy selected as review comment" button builds markdown from the checked rows: verdict line, then findings grouped by severity, then the AI-assisted disclosure and the limits. It uses the clipboard API with a visible textarea fallback when the clipboard is blocked.
- A toolbar at the top has "Check all", "Uncheck all", and a filter for severity.
- Checkbox state is a per-viewer convenience only. Wrap any storage access in try and catch and make the page work without it.

## Design requirements

- Colors as tokens on root with dark-mode overrides, explicit body background, system or Google font stacks only, no other external resources.
- Single reading column, max width near 820px, 16px side gutters, no horizontal page scroll at phone width (tables scroll inside their wrapper).
- Severity and verdict use text plus color, never color alone.
- Escape all PR-derived text before inserting it into HTML. PR titles and bodies are untrusted.
- No personal data about end users anywhere in the page.
