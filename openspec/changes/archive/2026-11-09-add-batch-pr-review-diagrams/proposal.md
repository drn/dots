# Change: Add review aids to batch-pr-review

## Why

The first version of the skill describes and judges each PR but leaves the reviewer to
assemble the mechanism, the reading path, and the test risk themselves. Team discussion
favored readable diagrams that support a plain summary, not mechanically complete ones.

## What Changes

- Reviewers also return a small flow graph (or applies false), a reading order, and a
  test-confidence rating.
- The artifact gains an SVG dependency graph (replacing the ASCII stack tree), a per-PR flow
  figure, a "where to look" block, a test-confidence pill, and a file-impact map.
- `references/ARTIFACT.md` gains diagram rules (mechanism not name, show the difference, label
  arrows, one claim per figure, no diagram when a sentence is faster).
- An external diagramming skill is optional, only from a trusted source, never installed unasked.

## Impact

- Affected specs: `batch-pr-review`
- Affected code: `agents/skills/batch-pr-review/`
