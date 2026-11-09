# Code review best practices behind this skill

Each practice lists the rule the skill applies and where it comes from. Evidence quality is noted because several LLM-review numbers are practitioner claims, not controlled studies.

## 1. Standard: improve code health, do not chase perfect

Approve once a change clearly improves overall code health, even if it is not how the reviewer would have written it. Technical facts and data outweigh personal preference. Optional polish is prefixed "Nit" and never blocks.
- Skill rule: verdicts hinge on correctness, safety, and tests. Style the project does not enforce is a nit at most.
- Source: Google Engineering Practices, reviewer standard (https://google.github.io/eng-practices/review/reviewer/standard.html). Primary source.

## 2. What to look at

Design, functionality, complexity (watch for over-engineering and speculative features), tests (would they fail if the code broke), naming, comments (why, not what), style, consistency, documentation, every line assigned, and context in the wider system. Acknowledge good work.
- Skill rule: the four reviewer lenses (correctness, security and privacy, tests, design and maintainability) map onto this list, and "good" is a required finding type.
- Source: Google Engineering Practices, what to look for (https://google.github.io/eng-practices/review/reviewer/looking-for.html). Primary source.

## 3. Fixed severity taxonomy

Use one vocabulary everywhere so findings can be sorted, counted, and filtered:
- blocker: wrong or unsafe, fix before merge
- should-fix: real risk or clear defect
- nit: optional polish
- question: cannot judge without more information
- good: worth acknowledging
Skill rule: reviewers must pick exactly one; the artifact and posted reviews use the same labels. A finding without a failure scenario cannot exceed question.

## 4. Evidence per finding

Every defect claim carries file and line, a one-sentence claim, and a concrete failure scenario (input or state, wrong outcome). Practitioners report that grounding each claim in cited code and treating the model as an evidence reporter, not a final judge, is what makes AI review trustworthy.
- Skill rule: schema in REVIEWER-PROMPT.md enforces it; line numbers are marked approximate when unsure and never invented.
- Sources: practitioner writeups, for example https://dev.to/kirandeepjassalcrypto/ai-code-review-that-engineers-actually-trust-the-pipeline-we-run-on-every-pull-request-21fp and https://reviewate-website.pages.dev/blog/reduce-false-positives-ai-code-review. Secondary, vendor and blog evidence.

## 5. Separate finding from verifying

Generate findings in one pass and check them in another, with the verifier trying to refute each claim against the real code. One practitioner reports a drop from roughly 35 percent to roughly 6 percent false positives from a skeptical second pass; a vendor reports a 51 percent reduction through specialized agents. Treat the exact numbers as anecdotal.
- Caution: LLM verifiers also over-correct and wrongly reject correct code, so the verifier may only confirm, refute, or mark cannot-verify, and refuted counts are shown to the user. One verification round only.
- Skill rule: Step 5.
- Sources: https://dev.to/david_shibley/i-killed-my-ai-code-reviewers-false-positives-by-making-it-argue-with-itself-21go, https://www.zenml.io/llmops-database/reducing-false-positives-in-ai-code-review-agents-through-architecture-refinement, and the over-correction finding in https://arxiv.org/pdf/2508.12358 (paper; the others are blogs).

## 6. One lens per pass

Splitting review into focused passes (security, performance, readability) counters anchoring, where a model fixates on one category and under-reports the rest.
- Skill rule: reviewers walk the four lenses in order and tag each finding with its lens.
- Source: practitioner commentary (https://dev.to/brightgir/the-never-ending-ai-code-review-why-one-pass-isnt-enough-3k05/comments). Anecdotal.

## 7. Stack and delta awareness

Review each stacked PR against its immediate parent so its diff shows only its own layer, review bottom to top (mirrors dependency order), check upstack PRs when code a lower PR touches changes again, record the parent head SHA that was reviewed, and if a PR makes no sense without the rest of the stack, say the stack should be split differently.
- Skill rule: Step 2 builds the graph and records SHAs; reviewers never repeat parent findings.
- Sources: Graphite (https://graphite.dev/docs/best-practices-for-reviewing-stacks), Mergify (https://docs.mergify.com/stacks/reviewing), extra-codeowners (https://extra-codeowners.readthedocs.io/en/latest/how-to/review-stacked-pull-requests/).

## 8. Describe first, judge second

Keep "what changed and why" separate from "what is wrong". A reader who understands the change can weigh findings; a reader handed findings without context cannot. The description is plain language about behavior, written for a non-expert.
- Skill rule: reviewers output description before findings; the artifact shows the description in its own block.
- Source: Google reviewer guidance on context and understanding every line (see sources 1 and 2); the separation itself is this skill design choice.

## 9. Verdict rubric

- approve: no blockers, no should-fix; nits only
- approve-with-fixes: no blockers, one or more should-fix that are small and safe to land with or right after the change
- request-changes: any confirmed blocker, or should-fix items that together make the change unsafe to merge as is
- needs-discussion: the approach is in question, or information that decides the verdict is missing
Verdicts are advisory. When posting, use a COMMENT review with the verdict in the body, so the skill never blocks a merge on its own authority. If author and reviewer disagree, resolve by consensus and escalate rather than letting the PR sit (Google standard, source 1).

## 10. Cross-PR consistency

A batch has failure modes no single review sees: the same concept handled differently across PRs, overlapping edits that conflict on merge, an assumption in one PR that no other PR provides, and merge or deploy order dependencies (including across repositories). The orchestrator checks these after per-PR reviews, with all PRs in view.
- Skill rule: Step 6. This is a design choice of the skill, not drawn from one source.

## 11. Claims that cannot be verified

Diff-only review cannot see runtime behavior, other repositories, or configuration. State this per PR. Label such claims "not verified by execution" or "unverified", downgrade their severity one level, and convert them to questions for the author when no evidence can be found. When a finding turns on runtime behavior, check out the branch and run the targeted tests instead. Link sibling-repo PRs the change depends on.
- Skill rule: Steps 3 and 5, plus the limits field in the reviewer output.

## 12. Review size

Review quality drops as diffs grow. Flag PRs over about 400 changed lines, split their review across reviewers by directory, and tell the user the PR is likely too large to review well. Treat the 400 line figure as a rule of thumb.

## 13. Review aids: diagrams, reading order, test confidence

Help the human reviewer orient before judging. Put a plain-language summary first, then a diagram only when it shows a mechanism (what moves between which components, what the change adds or removes) that prose would make the reader assemble. Diagrams that are mechanically right but unreadable are worse than none, so keep them small, label every arrow, and state the claim in a caption. Give a reading order (read first, skim, skip generated files) and a test-confidence rating so reviewer attention goes where risk is.
- Skill rule: reviewer output fields flow, reading_order, and test_confidence; artifact sections in ARTIFACT.md.
- Sources: team discussion on AI-generated PR diagrams (readable summary at the top, diagrams as support); PR-description diagram practice in the open-source pr skill at https://github.com/mattpocock/skills/blob/main/skills/engineering/pr/SKILL.md; reviewer guidance to understand every line and context (Google, source 2). The rating and file-impact map are this skill design choices.
