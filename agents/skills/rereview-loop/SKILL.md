---
name: rereview-loop
description: "Re-review with /rereview, fix the findings, and loop until all reviewers approve clean. Use for iterative paranoid review where you want every blocker addressed automatically before merging."
---

# Re-Review Loop

Run `/rereview` repeatedly: review → fix the findings → re-review → repeat. Stop when all three reviewers approve with zero BLOCKING and zero WARNING findings, when the iteration cap is hit, or when an iteration makes no progress.

## Arguments

- `$ARGUMENTS` - Optional. Forms:
  - `<branch-or-range>` - passed through to `/rereview` as its scope
  - `max=<N>` - cap the number of review→fix iterations (default 5)
  - `severity=blocking` - only auto-fix BLOCKING findings (default fixes BLOCKING + WARNING)
  - `severity=all` - auto-fix BLOCKING + WARNING + INFO
  - Any combination, space-separated. Example: `/rereview-loop max=3 severity=blocking`

## Context

- Current branch: !`git branch --show-current`
- Base ref: !`git branch -r 2>/dev/null | grep -oE 'origin/(main|master)' | head -1`
- Git status: !`git status --short`
- Commits vs main: !`git log origin/main..HEAD --oneline 2>/dev/null | head -20`
- Commits vs master: !`git log origin/master..HEAD --oneline 2>/dev/null | head -20`

## Overview

You are the **lead coordinator** for an iterative re-review loop. Your job is to drive findings to zero by alternating between review (delegated to `/rereview`) and fixes (applied here).

**Core principle:** trust the reviewers. Fix what they flag, do not argue with the verdict to escape the loop. The loop exits when reviewers say it's clean -- not when you decide it's clean.

**Hard rules:**

- NEVER skip, weaken, or reword reviewer findings to make them "easier to satisfy."
- NEVER mark a finding addressed without making (or consciously rejecting) a code change.
- NEVER cap the loop early just because the remaining findings look minor -- run to the cap or to clean.
- NEVER fix a finding by deleting the test that catches it.

---

## Phase 0: Parse arguments and initialize state

Parse `$ARGUMENTS`:

```
max_iterations = 5             (override with max=<N>)
severity_filter = "blocking+warning"   (override with severity=blocking | severity=all)
rereview_scope = ""            (any non-key=value token; passed to /rereview verbatim)
iteration = 0
prior_findings_signature = ""  (hash/summary of last iteration's findings, to detect no-progress)
```

If there are no commits ahead of the base branch and no uncommitted changes, tell the user "Nothing to re-review -- branch has no changes vs base." and stop.

Announce the run:

```
## Re-review loop starting

**Scope:** {rereview_scope or "current branch vs default"}
**Max iterations:** {max_iterations}
**Auto-fix severity:** {severity_filter}
```

---

## Phase 1: Run /rereview

Invoke the `/rereview` skill via the Skill tool, passing `rereview_scope` as its argument (empty string if no scope was given). Wait for it to complete and capture the full final report.

`/rereview` will:
1. Gather all changed files and dependents
2. Run the test + lint baseline
3. Launch 3 independent reviewers in parallel
4. Synthesize a final verdict

You will receive a markdown report with: a final verdict, a per-reviewer agreement table, and consolidated lists of Blocking Issues, Warnings, Suggestions, Disagreements, and Missing Test Coverage.

If `/rereview` reports "no changes to review," the loop is trivially clean -- exit with the success summary in Phase 5.

---

## Phase 2: Decide whether to exit

Read the final verdict and the agreement table. Decide:

```
IF verdict == "APPROVE" AND total BLOCKING == 0 AND total WARNING == 0:
  → EXIT (clean). Go to Phase 5 with status = CLEAN.

IF verdict == "APPROVE WITH WARNINGS" AND severity_filter == "blocking":
  → EXIT (warnings ignored by request). Go to Phase 5 with status = APPROVED_WITH_WARNINGS_IGNORED.

IF iteration >= max_iterations:
  → EXIT (cap hit). Go to Phase 5 with status = MAX_ITERATIONS.

OTHERWISE:
  → Continue to Phase 3 to address findings.
```

**Compute a findings signature** from the consolidated report -- a short summary string per finding (file:line + first ~80 chars of description), sorted and joined. Compare to `prior_findings_signature` from the previous iteration.

```
IF iteration > 0 AND findings_signature == prior_findings_signature:
  → Apparent no-progress. Reviewers re-flagged the same items.
    Do NOT silently bail. Re-read the report carefully:
      - Did the previous fix actually land in a commit? (Check git log.)
      - If yes: the fix did not satisfy the finding. Try a different approach,
        OR mark this iteration as a stuck state and exit Phase 5
        with status = STUCK after one more attempt.
      - If no commit landed for that finding: the previous iteration was
        incomplete -- continue to Phase 3 and actually apply the fix.
```

Save the new `findings_signature` for the next iteration's comparison.

---

## Phase 3: Address findings

Build the worklist from the consolidated report based on `severity_filter`:

| `severity_filter`     | Includes                          |
|-----------------------|-----------------------------------|
| `blocking`            | BLOCKING only                     |
| `blocking+warning`    | BLOCKING + WARNING (default)      |
| `all`                 | BLOCKING + WARNING + INFO         |

Always include items in this order: BLOCKING first, then WARNING, then INFO. Within a tier, group by file so related fixes can share a single read of that file.

For each finding:

1. **Read the cited file fully** (and any caller/dependent the reviewers referenced). Do not work from the snippet alone.

2. **Classify the finding into one of three buckets:**

   - **(a) Apply the fix.** The reviewer is correct. Make the minimal code change that resolves the issue. If the fix changes behavior, add or update a test that covers the new behavior. If the finding is "missing test coverage," add the test.

   - **(b) Push back with a recorded justification.** The reviewer is wrong, or the change conflicts with intentional design. **This is a high bar.** Document:
     - Why the existing code is correct
     - What evidence convinced you (link to existing test, prior decision, code that shows the invariant)
     - Note this in the iteration summary so the user can sanity-check

     If you push back on more than 25% of findings in any single iteration, STOP and ask the user before continuing -- pushing back on a quarter of an independent panel's findings usually means you're rationalizing rather than reviewing.

   - **(c) Defer to user.** The finding requires a product decision, scope expansion, or knowledge you don't have (e.g., "the new SLA isn't documented"). Do NOT silently skip. Surface it in the iteration summary and continue. The loop will likely re-flag it next iteration; that is correct behavior.

3. **After all findings in this iteration are processed:**

   - Re-run the project's test suite (same command `/rereview` detected).
   - Re-run the linter.
   - If tests now fail that previously passed -- that is a regression you introduced. Fix it before continuing. Do NOT proceed to commit.

4. **Commit the iteration's fixes** as a single commit per iteration:

   ```
   git add -A   # only the files you actually changed -- list them explicitly if mixed
   git commit -m "rereview-loop iter {N}: address {M} findings

   {bulleted list of finding summaries with file:line, prefixed by [BLOCKING] / [WARNING] / [INFO]}"
   ```

   **Use specific paths in `git add`, not `-A`,** if there are unrelated dirty files in the working tree. Do not pull unrelated work into the loop's commit history.

5. Increment `iteration`. Loop back to **Phase 1**.

### What NOT to do in Phase 3

- Do not amend prior commits -- each iteration gets its own commit so the audit trail is clear.
- Do not delete or skip tests to make findings go away. If a test is genuinely wrong, replace it; explain in the commit message.
- Do not introduce new abstractions, refactors, or "while I'm here" cleanups. The loop fixes findings, nothing else.
- Do not push to remote. Pushing is the user's call.

---

## Phase 4: Iteration heartbeat

After each iteration's commit, output a one-screen summary so the user can follow along without reading the full reports:

```
## Iteration {N} complete

**Verdict from /rereview:** {verdict}
**Findings this iteration:** {B} blocking, {W} warning, {I} info
**Applied fixes:** {count}
**Pushed back:** {count} (see "Pushback notes" below if any)
**Deferred:** {count} (see "Deferred to user" below if any)
**Tests after fixes:** {PASS / FAIL}
**Lint after fixes:** {CLEAN / WARNINGS / ERRORS}

Next: running /rereview again (iteration {N+1} of {max_iterations}).
```

If there are pushback or deferred items, list them under the heartbeat with file:line + one-sentence reason.

---

## Phase 5: Final report

When the loop exits, output:

```
# Re-review loop finished

**Status:** {CLEAN / APPROVED_WITH_WARNINGS_IGNORED / MAX_ITERATIONS / STUCK}
**Iterations run:** {N} of {max_iterations}
**Total findings addressed:** {count} (B: {x}, W: {y}, I: {z})
**Total findings pushed back:** {count}
**Total findings deferred:** {count}
**Final verdict from /rereview:** {verdict}
**Final regression risk:** {LOW / MEDIUM / HIGH}

## Commits added by this loop
{git log --oneline of commits made during the loop}

## Outstanding items (deferred or pushed back)
{numbered list, or "None."}

## Recommendation
{One of:
  - "Clean — safe to push and merge."
  - "Warnings remain (ignored per `severity=blocking`). Review the warnings list before merging."
  - "Iteration cap hit with findings still open. Re-run /rereview-loop, raise max=, or address remaining items manually."
  - "Loop is stuck — reviewers re-flagged the same findings after a fix attempt. Manual investigation needed."}
```

Do NOT push the branch. Do NOT open or update a PR. The loop's job is to drive findings to zero locally; merging is the user's decision.

---

## Failure handling

| Failure | Action |
|---------|--------|
| `/rereview` errors out or returns no report | Retry once. If still failing, exit with status = ERROR and surface the message. |
| Test suite breaks mid-loop and you can't fix it | Stop. Do NOT commit broken tests. Report the failing test and last attempted fix. |
| A finding is unclear or contradictory across reviewers | Apply the most conservative interpretation. Note the ambiguity in the iteration heartbeat. |
| Same findings re-appear after a fix attempt (stuck) | One more attempt with a different approach, then exit with status = STUCK and surface the diff of the failed fix. |
| Reviewers disagree sharply (e.g., one APPROVE, one REJECT) | Trust the strictest. Address the REJECT findings in this iteration. |
| User has uncommitted unrelated changes | Stash them up front (`git stash push -u -m "rereview-loop pre-loop"`) and pop after the loop. Tell the user you stashed. |

---

## Design notes

- Each iteration commits independently so a future `git log` shows exactly what the loop changed and why.
- The findings signature check exists to catch the bad-fix → re-flag → bad-fix cycle. Without it, the loop can spin to the cap making the same wrong change.
- The 25% pushback ceiling exists because once you start rejecting a third of an independent panel's findings, the failure mode is almost always rationalization, not the reviewers being wrong.
- This skill does not push or open a PR -- that is the user's call. Pair with `/pr` after a clean exit.
