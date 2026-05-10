---
name: rereview-loop
description: "Iteratively run /rereview, fix the findings, and loop until reviewers approve clean. Use for iterative automated review, when you want /rereview to loop until clean, or for a paranoid pre-merge review that auto-addresses every blocker."
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
prior_blocking_count = -1      (B count from previous iteration; -1 = no prior)
prior_warning_count = -1       (W count from previous iteration; -1 = no prior)
prior_info_count = -1          (I count from previous iteration; -1 = no prior)
last_iteration_committed = false   (did the previous iteration produce a commit?)
total_pushbacks = 0            (cumulative pushbacks across all iterations)
total_findings_addressed = 0   (cumulative findings touched, for the pushback rate)
stashed = false                (set true if Phase 0 stashes unrelated work)
```

**Preflight:**

1. **Detached HEAD guard.** Run `git symbolic-ref --short HEAD` (or `git branch --show-current`). If empty, exit immediately: "Cannot run /rereview-loop in detached HEAD state -- check out a named branch first." Do not proceed.

2. **No-changes guard.** If there are no commits ahead of the base branch and no uncommitted changes, tell the user "Nothing to re-review -- branch has no changes vs base." and stop.

3. **Stash unrelated work.** If `git status --short` shows uncommitted changes that are NOT part of the work being reviewed (i.e., the user has unrelated dirty files), run `git stash push -u -m "rereview-loop pre-loop"` and set `stashed = true`. Tell the user you stashed. The stash MUST be popped on every exit path -- see Phase 4 and the failure-handling table.

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

If `/rereview` reports "no changes to review," the loop is trivially clean -- exit with the success summary in Phase 4.

---

## Phase 2: Decide whether to exit

Read the final verdict and the agreement table. Record this iteration's `B` (blocking), `W` (warning), and `I` (info) counts from the consolidated report.

The exit condition depends on `severity_filter`:

| `severity_filter`     | "Clean" means          |
|-----------------------|------------------------|
| `blocking`            | B == 0                 |
| `blocking+warning`    | B == 0 AND W == 0      |
| `all`                 | B == 0 AND W == 0 AND I == 0 |

```
IF this iteration's counts meet the "clean" condition for severity_filter:
  → EXIT. Go to Phase 4 with status = CLEAN.
  (If severity_filter == "blocking" and W > 0, status = APPROVED_WITH_WARNINGS_IGNORED.)

IF iteration >= max_iterations:
  → EXIT (cap hit). Go to Phase 4 with status = MAX_ITERATIONS.

OTHERWISE:
  → Continue to Phase 3 to address findings.
```

### Stuck-state detection

After Phase 3 commits the iteration's fixes, the next iteration's Phase 2 must check whether progress was actually made. Use a hard counter, not a paraphrased-text signature:

```
IF iteration > 0 AND last_iteration_committed == true AND
   B >= prior_blocking_count AND
   W >= prior_warning_count AND
   I >= prior_info_count:
  → Apparent no-progress. The fix did not reduce the finding counts.
    Re-read the report carefully:
      - If the SAME items are flagged at the SAME file:line, try a
        different approach to those specific findings in this iteration.
      - If this is the second consecutive iteration with no progress,
        EXIT with status = STUCK after applying best-effort fixes once more.

IF iteration > 0 AND last_iteration_committed == false:
  → The previous iteration applied no fixes (everything was pushed back
    or deferred). Counts may legitimately be unchanged. Do NOT treat as
    stuck on this basis alone -- continue with the loop.
```

Save the current B/W/I counts as `prior_blocking_count`, `prior_warning_count`, `prior_info_count` for the next iteration's comparison. Reset `last_iteration_committed` to `false` -- Phase 3 sets it back to `true` if a commit lands.

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

     Track pushbacks at two levels:
     - **Per-iteration:** if you push back on more than 25% of findings in this iteration, STOP and ask the user before continuing.
     - **Cumulative:** increment `total_pushbacks` and `total_findings_addressed` after each finding is processed. If `total_pushbacks / total_findings_addressed > 0.25` once at least 4 findings have been processed total, STOP and ask the user. Per-iteration framing alone allows systematic 1-of-4 pushbacks to compound to 100% across iterations without ever tripping a single-iteration ceiling.

     Pushing back on a quarter of an independent panel's findings -- in any single iteration or cumulatively -- usually means you're rationalizing rather than reviewing.

   - **(c) Defer to user.** The finding requires a product decision, scope expansion, or knowledge you don't have (e.g., "the new SLA isn't documented"). Do NOT silently skip. Surface it in the iteration summary and continue. The loop will likely re-flag it next iteration; that is correct behavior.

3. **After all findings in this iteration are processed:**

   - Re-run the project's test suite (same command `/rereview` detected).
   - Re-run the linter.
   - If tests now fail that previously passed -- that is a regression you introduced. Fix it before continuing. Do NOT proceed to commit.

4. **Commit the iteration's fixes** as a single commit per iteration. List the changed paths explicitly -- never use `git add -A` (the Phase 0 stash already moved unrelated work aside, but explicit paths are still the safe default):

   ```
   git add path/to/changed-file-1 path/to/changed-file-2 ...
   git commit -m "rereview-loop iter {N}: address {M} findings

   {bulleted list of finding summaries with file:line, prefixed by [BLOCKING] / [WARNING] / [INFO]}"
   ```

   Set `last_iteration_committed = true` once the commit succeeds. If no findings led to code changes in this iteration (everything was pushed back or deferred), do NOT create an empty commit -- leave `last_iteration_committed = false`.

5. **Heartbeat.** Output the per-iteration summary defined below before looping back.

6. Increment `iteration`. Loop back to **Phase 1**.

### Iteration heartbeat (output at end of every Phase 3 cycle)

```
## Iteration {N} complete

**Verdict from /rereview:** {verdict}
**Findings this iteration:** {B} blocking, {W} warning, {I} info
**Applied fixes:** {count}
**Pushed back:** {count} this iteration, {total_pushbacks} cumulative ({rate}% of {total_findings_addressed})
**Deferred:** {count}
**Tests after fixes:** {PASS / FAIL}
**Lint after fixes:** {CLEAN / WARNINGS / ERRORS}

Next: running /rereview again (iteration {N+1} of {max_iterations}).
```

If there are pushback or deferred items, list them under the heartbeat with file:line + one-sentence reason.

### What NOT to do in Phase 3

- Do not amend prior commits -- each iteration gets its own commit so the audit trail is clear.
- Do not delete or skip tests to make findings go away. If a test is genuinely wrong, replace it; explain in the commit message.
- Do not introduce new abstractions, refactors, or "while I'm here" cleanups. The loop fixes findings, nothing else.
- Do not push to remote. Pushing is the user's call.

---

## Phase 4: Final report

**Stash pop guard.** Every exit path (CLEAN, APPROVED_WITH_WARNINGS_IGNORED, MAX_ITERATIONS, STUCK, ERROR, and any early exit from Phase 0 after the stash was pushed) MUST run `git stash pop` if `stashed == true` before printing the final report. The user's unrelated work-in-progress is not the loop's to discard.

If the stash pop reports conflicts, surface them to the user verbatim and stop -- do NOT attempt to resolve unrelated conflicts.

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
| User has uncommitted unrelated changes | Stash them up front in Phase 0 (`git stash push -u -m "rereview-loop pre-loop"`) and pop on every exit path -- see Phase 4's stash-pop guard. |

---

## Design notes

- Each iteration commits independently so a future `git log` shows exactly what the loop changed and why.
- The B/W/I count comparison in Phase 2 exists to catch the bad-fix → re-flag → bad-fix cycle. A count-based check (instead of paraphrased text matching) is robust against reviewer agents wording the same finding differently across iterations.
- The 25% pushback ceiling -- both per-iteration and cumulative -- exists because once you start rejecting a quarter of an independent panel's findings, the failure mode is almost always rationalization, not the reviewers being wrong. The cumulative bound prevents systematic 1-of-4 pushbacks from compounding.
- This skill does not push or open a PR -- that is the user's call. Pair with `/pr` after a clean exit.
