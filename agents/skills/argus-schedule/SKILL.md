---
name: argus-schedule
description: Manage recurring or one-shot tasks in the local Argus daemon via its HTTP API. Use when the user wants to schedule a task locally in argus, create a cron-driven task, fire X every weekday/hour/morning, fire something once at a specific future time or "in N minutes" (one-shot via run_once_at), set up an agent that needs local filesystem access (logs in ~/.argus, local databases, dotfiles), list or update existing argus schedules, or run an argus schedule now. Distinct from /schedule, which creates remote cloud routines without local access.
allowed-tools: Bash(curl *), Bash(cat *), Bash(jq *), Bash(date *), Bash(test *), Bash(ls *)
---

# Argus Schedule

Create, list, update, run-now, or enable/disable a recurring or one-shot task in the local Argus daemon. Argus exposes full schedule CRUD over its HTTP API on `http://localhost:7743`. The cron tick fires the task on the local machine, so the scheduled agent has access to `~/.argus`, the dotfiles repo, and any other local resource — unlike the remote `/schedule` skill, whose routines run in the Anthropic cloud and cannot read the user's filesystem.

## Arguments

- `$ARGUMENTS` — Free-form. May contain a verb (list, create, update, run, enable, disable), a target schedule ID or name, a cron expression or relative/absolute time, and a prompt. If empty or ambiguous, ask the user a clarifying question and stop.

## Context

- API base: http://localhost:7743
- Daemon liveness probe (unauthenticated; expect a 401 JSON body when the daemon is up): !`curl -sS -m 2 http://localhost:7743/api/status 2>/dev/null | head -1`
- Token file: !`ls -1 ~/.argus/api-token 2>/dev/null | head -1`

Interpretation of the liveness probe:
- Empty output → daemon is not running (or port 7743 is not bound). Stop and tell the user.
- Output contains `"error":"missing or invalid Authorization header"` → daemon is up; this is the expected response without a token. Proceed.
- Any other JSON → daemon is up but in an unexpected state; surface the response and stop.

The projects list and the live schedules list require a Bearer token, so do not attempt to fetch them from this Context block — fetch them at runtime in the Verbs section using a single `cat ~/.argus/api-token` substitution inside a curl invocation (where shell command substitution is allowed).

## When to use this skill versus /schedule

| Need | Use |
|------|-----|
| Recurring agent must read local files (`~/.argus/ux.log`, dotfiles, local DB, project worktree) | `/argus-schedule` |
| Recurring agent only needs remote APIs (GitHub, Jira, Slack, web fetches) | `/schedule` |
| User explicitly says "argus", "in argus", "local cron" | `/argus-schedule` |
| User says "remote routine", "cloud agent", "in the background even when laptop sleeps" | `/schedule` |

If both would work, default to `/argus-schedule` when the laptop is the user's primary machine and the workflow already lives in argus. Otherwise ask which they want.

## Pre-flight checks

Before any API call:

1. **Daemon reachable.** If the liveness probe in Context above is empty (no response on port 7743), tell the user the argus daemon does not appear to be running and stop. Do not attempt to start it from this skill. A 401 JSON body in the probe is the expected output and means the daemon is up.
2. **Master token present.** If `~/.argus/api-token` is missing, tell the user to run `argus` once (the daemon mints the token on first run) and stop. The schedule endpoints are master-only — per-device tokens cannot manage schedules.
3. **Read the token at call time, not in dynamic context.** Use `cat ~/.argus/api-token` inside each curl invocation rather than echoing it into the conversation. The token is sensitive.

## Verbs

Pick the verb from `$ARGUMENTS`. If unclear, ask which one.

### list

The daemon returns an object with the rows under a top-level `schedules` key — `{"schedules": [ ... ]}` — not a bare array. Always iterate `.schedules[]`; a bare `.[]` indexes the wrapper object and fails with "Cannot index array with string". Several fields are omitted when empty (`next_run_at`, `last_run_at`, `last_error`), so coalesce them with `//` — otherwise jq interpolates the absent value as a literal "null".

```
curl -sS -H "Authorization: Bearer $(cat ~/.argus/api-token)" \
  http://localhost:7743/api/schedules \
  | jq -r '.schedules[] | "\(.id)\t\(.name)\t\(.schedule // .run_once_at)\t\(.enabled)\t\(.next_run_at // "pending")\t\(.last_run_at // "never")\t\(.last_error // "")"'
```

The jq emits seven tab-separated columns in this order: `id`, `name`, `schedule` (cron expression, or the `run_once_at` timestamp for one-shots), `enabled`, `next_run_at`, `last_run_at`, `last_error`. Render them as a compact table; `id` is column 1 and is needed for the update and run verbs. Show `last_error` only when non-empty, and hide `prompt` unless the user asks — prompts can be long. Empty output means there are no schedules (jq still exits 0); a jq error such as "Cannot iterate over null" means the response was not the expected envelope — surface the raw body and stop rather than retrying.

### create

Required from the user (ask one question collecting any missing pieces, do not invent values):

- **name** — short, human-readable. Will be suffixed with the fire timestamp on each run.
- **project** — must match an existing argus project name from the projects list above. If the user gave a project that is not in the list, show the available names and stop.
- **cadence** — exactly one of `schedule` or `run_once_at`. **Never compute both, and never hand-roll an absolute `minute hour day month *` cron expression to approximate a one-shot** — use the decision table below to pick the right field first.
- **prompt** — what the agent should do at each fire. Multi-line is fine; pass it as a JSON string.
- **backend** (optional) — overrides the default backend for this schedule. Only set if the user asked. Useful for forcing a cheaper model on a polling task.

#### Cadence decision table

The daemon's cron scheduler (`schedule` field) evaluates against the **daemon process's own local time zone**, which is not guaranteed to match the calling shell's time zone even on the same machine — a shell in one zone computing a "current time + offset" cron target can silently land a year in the future if the daemon is in a different zone and the target clock time has already passed there today. `run_once_at` and `@every` sidestep this entirely because they are timezone-agnostic (UTC-absolute, or relative-to-creation respectively). Pick by what the user actually said:

| User asked for | Field to use | Why it is timezone-safe |
|---|---|---|
| A relative one-shot ("in 30 minutes", "retry in an hour") | `run_once_at`, computed from the **calling shell's own current UTC time** | RFC3339 UTC is an absolute instant — no daemon-zone guessing needed |
| A relative recurring interval ("every 30 minutes", "poll hourly") | `schedule: "@every 30m"` | Fires relative to creation time; never touches wall-clock zones |
| An absolute one-shot ("at 9am tomorrow", "tonight at 11pm") | `run_once_at`, converting the user's stated local time to UTC using the **calling shell's** own zone | Only the shell's local→UTC conversion matters; the daemon's zone is irrelevant once the timestamp carries a `Z`/offset |
| An absolute recurring wall-clock time ("9am every weekday") | `schedule: "minute hour day month *"` | Unavoidably depends on the daemon's zone — do the discovery step below before trusting it |

For `run_once_at`, compute the target as UTC directly rather than reasoning about any local offset:

```
# macOS / BSD date:
date -u -v+30M +"%Y-%m-%dT%H:%M:%SZ"

# GNU date (Linux):
date -u -d "+30 minutes" +"%Y-%m-%dT%H:%M:%SZ"
```

For an absolute local time the user named (e.g. "9am tomorrow"), convert with the same `date -u` approach against that wall-clock time in the shell's own zone, then echo the resulting UTC timestamp back to the user for confirmation before posting.

For the last row (absolute recurring cron), do one discovery round-trip before trusting a computed expression: after creating (or from an existing schedule via `list`), compare the offset on the response's `created_at`/`next_run_at` (e.g. `-05:00`) against the calling shell's own `date` offset. If they differ, the daemon is in a different zone than the shell — recompute the cron's `minute hour` fields by that difference and `PUT` the correction, then re-verify `next_run_at` matches the user's intended wall-clock time before confirming.

Build the JSON body with `jq` to handle quoting of multi-line prompts safely:

```
# Recurring (cron or @every):
JSON=$(jq -n \
  --arg name "$NAME" \
  --arg project "$PROJECT" \
  --arg schedule "$CRON" \
  --arg prompt "$PROMPT" \
  '{name:$name, project:$project, schedule:$schedule, prompt:$prompt, enabled:true}')

# One-shot:
JSON=$(jq -n \
  --arg name "$NAME" \
  --arg project "$PROJECT" \
  --arg run_once_at "$WHEN_RFC3339" \
  --arg prompt "$PROMPT" \
  '{name:$name, project:$project, run_once_at:$run_once_at, prompt:$prompt, enabled:true}')

curl -sS -X POST \
  -H "Authorization: Bearer $(cat ~/.argus/api-token)" \
  -H "Content-Type: application/json" \
  -d "$JSON" \
  http://localhost:7743/api/schedules | jq
```

One-shot rows auto-disable after firing — the row stays in the list with `enabled=false` for inspection. The user can delete it once they have read the result.

Create and update both return the schedule object directly (the flat shape, not wrapped under a key), so `.id` and `.next_run_at` index the response without a path prefix. After the call, echo the returned `id`, `next_run_at`, and a one-line confirmation. Do not add `--data-raw` shortcuts that bypass jq — embedding raw user input into a shell-quoted JSON string is a quoting hazard.

### update

The PUT body uses pointer fields: send only what the user wants to change. Setting `schedule` clears any existing `run_once_at` on that row and vice versa — the API rejects sending both non-empty in one call.

```
JSON=$(jq -n --arg schedule "$NEW_CRON" '{schedule:$schedule}')
curl -sS -X PUT \
  -H "Authorization: Bearer $(cat ~/.argus/api-token)" \
  -H "Content-Type: application/json" \
  -d "$JSON" \
  http://localhost:7743/api/schedules/"$ID" | jq
```

If the user gave a name instead of an ID, list first, find the matching row, and confirm the ID with the user before sending the PUT.

### run

Fires the schedule now, out of cycle. Creates a fresh task immediately.

```
curl -sS -X POST \
  -H "Authorization: Bearer $(cat ~/.argus/api-token)" \
  http://localhost:7743/api/schedules/"$ID"/run | jq
```

The response is an object carrying only the new task ID — `{"task_id": "..."}` — not a schedule object; surface that task ID so the user can find the run in argus.

Note for the user: the run-now path does NOT send a push notification (the cron tick path does). If they expected the notification, that is the reason it did not arrive.

### enable / disable

Equivalent to update with only `enabled` set:

```
JSON=$(jq -n --argjson enabled false '{enabled:$enabled}')
```

(Use `true` for enable.) Disabling pauses fires but preserves the row. The user can re-enable later without re-creating.

## Cron primer

Argus parses `schedule` with `robfig/cron/v3` `ParseStandard`. Accepts:

- **5-field cron**: `minute hour day-of-month month day-of-week`. Example: `0 9 * * 1-5` is 9am on weekdays. Time zone follows the **daemon process's own local time zone**, not the calling shell's — see the cadence decision table above before hand-computing one of these for anything that is not a genuinely recurring wall-clock schedule.
- **Descriptors**: `@hourly`, `@daily`, `@weekly`, `@monthly`, `@yearly`. Same daemon-zone caveat as 5-field cron.
- **Interval shortcut**: `@every <duration>` where duration is a Go duration like `30m`, `1h`, `24h`. Example: `@every 1h` fires hourly aligned to the moment of creation. Timezone-agnostic — prefer this for any relative recurring request.

For a one-shot fire (relative or absolute), use `run_once_at` (RFC3339 UTC) instead of cron entirely — see the cadence decision table above.

Minimum resolution is one minute — schedules tighter than that are ignored. The first fire never happens on the very first tick after creation; the scheduler advances `NextRunAt` past `now` on each persist.

When a cron expression names a specific clock time, state the daemon-zone caveat explicitly to the user so they can confirm it matches their expectation, and prefer the discovery round-trip described in the cadence decision table over guessing.

## Validation

After every create or update, refetch the row and report `next_run_at`. For anything with a user-stated target time (a `run_once_at` or a clock-time cron), compare the reported `next_run_at` against what the user asked for — if it does not match (e.g. off by the daemon's UTC offset, or a year out because a same-day target had already passed in the daemon's zone), correct it with a follow-up `update` before confirming, rather than reporting success on a mismatched fire time. If `last_error` is non-empty after a previous fire, surface it — the most common cause is a removed project or a mistyped cron expression.

## Stop conditions

- Daemon unreachable on the health probe → tell the user, stop.
- Token missing → tell the user, stop.
- Project name not in the configured projects list → show available names, stop.
- Cron expression or `run_once_at` rejected by the API (HTTP 400) → show the API error verbatim, ask for a corrected value, do not retry with a guessed value.
- HTTP 5xx from the API → show the response body, stop. Do not loop.

Do not retry destructive or fire-causing calls automatically. One attempt per user instruction.

## Skill mirroring (author note)

This skill has a twin at `~/.dots/agents/skills/argus-schedule/SKILL.md` per the user's skill-mirroring preference. The argus repo copy is canonical; the dotfiles copy makes the slash command reachable from any project. Keep the two files byte-identical.
