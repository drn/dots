# Review artifact layout

Fill template.html (same directory level as SKILL.md) and publish it as a private artifact. Keep one self-contained file. Content comes from the verified findings, not from raw reviewer output.

## Sections, in order

1. **Header**: title naming the batch, a two-sentence lede (what the batch is for, date, how many PRs, how many are open), and one overall line with the recommended merge order.
2. **At a glance table**: one row per PR with link, one-line plain description, size, CI state, and a verdict pill. Verdict pill classes: ok (approve, approve-with-fixes), warn (needs-discussion, request-changes minor), bad (request-changes).
3. **Stack diagram**: monospace tree showing base branches and which PRs are stacked on which. Omit the section when nothing is stacked.
4. **Cross-PR findings**: inconsistencies, conflicts, ordering and deploy dependencies, gaps. Omit the section when empty.
5. **One card per PR**, bottom of a stack first:
   - header: title, verdict pill, meta line (repo and number link, additions and deletions, file count, base branch, review depth)
   - "What it does": 2 to 4 plain sentences, no findings mixed in
   - two columns: "Should fix" (blockers first, each with the failure scenario) and "Smaller notes" (nits, questions, good)
   - each finding is a list row with a checkbox, a severity tag, the text, and file:line when known; unverified findings carry an "unverified" tag
   - a "Questions for the author" list when present
6. **Open design questions**: each with a recommendation and the reason, when the source thread or PR bodies raised any.
7. **Appendix note**: source link, review depth per PR, what was not verified by execution, how many findings the verifier refuted, and the sentence "Nothing has been posted" (or what was posted, with URLs).

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
