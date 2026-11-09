## ADDED Requirements

### Requirement: Batch PR Review Aids

The `batch-pr-review` skill SHALL give each reviewed PR a reading order, a test-confidence
rating, and a file-impact map, and SHALL draw diagrams only where they show a mechanism.

The skill SHALL:
- Require reviewers to return a flow graph of the mechanism a change alters, or mark it not
  applicable, a reading order of files, and a test-confidence rating with evidence.
- Render a dependency graph across PRs (stacked, deploy-order, and conflict relations,
  including linked PRs in other repos) as self-contained inline SVG with labeled arrows.
- Render a per-PR flow figure that shows the difference the change makes, marking new and
  removed parts in text as well as color, with a caption stating the claim.
- Place a plain-language description above every diagram and omit a diagram when a sentence
  conveys the same information.
- Use an external diagramming skill only from a trusted source and never install one unasked.

#### Scenario: Change with no flow to draw

- **WHEN** a PR is a documentation change or a pure refactor
- **THEN** the reviewer marks flow as not applicable and the artifact omits the flow figure

#### Scenario: Stacked PRs with a cross-repo dependency

- **WHEN** a PR depends on a PR in another repository
- **THEN** the dependency graph shows it as a dashed node with a labeled edge and the caption
  states the required merge or deploy order
