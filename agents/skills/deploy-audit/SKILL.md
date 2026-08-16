---
name: deploy-audit
description: Audit every commit pending between a base branch and a deployed branch/tag for deploy risk (migrations, config/secret wiring completeness, feature-flag defaults, schema parity), then open the GitHub compare diff. Use when asked to audit pending commits, check deploy risk, review what is about to ship, or before opening a deploy PR or shipping to production.
---

# Pre-Deploy Risk Audit

Audit the commits pending between a base branch and a deployed branch/tag,
assess the risk of each change, and open the GitHub compare diff for human
review. This is an informational audit — it does not block or change anything
on its own.

## Arguments

- `$ARGUMENTS` - Optional: `<base>..<deployed>` (e.g. `master..production`), or
  just the deployed ref if the base is the repo's default branch. If omitted,
  detect candidates from context below and ask the user to confirm.

## Context

- Remote: !`git remote get-url origin 2>/dev/null | head -1`
- Default branch: !`git branch -r 2>/dev/null | grep -oE 'origin/(main|master)' | head -1`
- Remote branches: !`git branch -r 2>/dev/null | grep -viE 'HEAD|dependabot' | head -30`
- Recent tags: !`git tag --sort=-creatordate 2>/dev/null | head -10`

## Instructions

### Step 1: Determine the two refs

Parse `$ARGUMENTS` for `<base>..<deployed>`. If only one ref is given, treat it
as the deployed ref and use the detected default branch as base. If nothing is
given, look at the remote branches/tags in Context above for likely
candidates (a `production`/`release`/`deploy` branch, or the most recent tag)
and ask the user to confirm the base and deployed refs before proceeding.

Run `git fetch origin` for both refs to ensure they are current.

### Step 2: Enumerate pending commits

```
git log --oneline <deployed>..<base>
git diff --stat <deployed>..<base>
```

If this returns nothing, report "Nothing pending — `<deployed>` and `<base>`
are in sync" and stop.

Read full commit messages for risk signal:

```
git log --format='%H %s%n%b%n---' <deployed>..<base>
```

Commit bodies often carry the actual risk context (design rationale, what a
migration does, why a flag was added) that the subject line does not.

### Step 3: Assess migration safety

If the diff touches migration files (schema migrations, database migration
directories — detect the project's convention rather than assuming one path),
read each new migration and classify it:

- **Additive/safe**: new nullable column, new table, new index created
  concurrently/online
- **Requires care**: backfill needed, column made non-nullable, default value
  added to an existing large table
- **Destructive**: column/table drop, rename, type change without a
  compatibility shim

Flag anything in the latter two categories explicitly.

### Step 4: Check schema parity

If the project maintains more than one copy of a schema file (a canonical
schema plus mirrored/generated copies used by other services or packages —
check the project's own docs/rules for this convention, or search for
multiple files with the same schema filename), diff the canonical version
against every mirror. Flag any mismatch in version or content.

If the project has no such mirrored-schema convention, skip this step and
say so.

### Step 5: Trace config and secret wiring

For every new environment variable or secret introduced by the diff, trace it
through the **full chain** the project uses to get a value from
infrastructure config into a running process — for example: an IaC variable
declaration, through any module wiring, into the per-environment secret
definitions, into the actual task/service/container definition that reads it.

A secret or parameter existing in a vault/parameter store is not the same as
it being wired anywhere a running process reads it — check for a reference at
every layer, not just that the value was provisioned. This is the single
highest-value check in this audit: a half-wired chain (defined but never
referenced downstream) will not be caught by `terraform plan` or similar and
fails silently in production.

If the project has no IaC/config-chain convention to trace, skip this step
and say so.

### Step 6: Check feature-flag defaults

If the diff introduces calls to a feature-flag SDK for a new flag key, look up
that flag's default/targeting state in whatever flag-management tooling the
project has available (search with ToolSearch for a feature-flag MCP tool, or
check for a flag-provider CLI). Confirm new flags default to **off**, or note
explicitly if a new flag is live-by-default and why.

If no flag-management tooling is discoverable, skip this step and say so.

### Step 7: Open the compare diff

Derive `<org>/<repo>` from the remote URL in Context and open:

```
https://github.com/<org>/<repo>/compare/<deployed>...<base>
```

On macOS use `open "<url>"`; on Linux use `xdg-open "<url>"`; otherwise print
the URL for the user to open manually.

### Step 8: Report

Summarize per pending change (or per logical group of changes) with a
low/moderate/high risk rating, and call out explicitly:

- Any destructive or backfill-requiring migrations
- Any schema mirror mismatches
- Any half-wired or unverified config/secret chains
- Any new flags that are live-by-default rather than off
- Any risk category that was skipped because no tooling was available to
  verify it

Do not silently drop a skipped category from the summary — an unverified
check is different from a verified-safe one.
