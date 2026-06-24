# cli-utilities Specification

## Purpose

The `cli-utilities` capability defines the standalone single-purpose binaries
under `cmd/`. Each is built by `go install ./...` and is intended for shell
integration, status lines, and developer workflows. They group into system
status probes, network/IP helpers, git workflow helpers, read-only API clients,
developer tooling, and status-line/UI renderers.

This spec documents the behavior that ships today.

## Requirements

### Requirement: System Status Probes

The system status utilities SHALL print a single status value to stdout for use
in status lines: `battery-percent` (battery charge with `%` suffix),
`battery-state` (`charging` or `battery`), `cpu` (1-minute load average as a
rounded percentage), and `ssid` (current WiFi network name, with a `--short`
flag that truncates the output). These probes SHALL source their data from macOS
system commands (`pmset`, `sysctl`, `ipconfig`).

#### Scenario: Battery state reflects power source

- **WHEN** `battery-state` runs while on AC power
- **THEN** it prints `charging`

#### Scenario: Short SSID truncation

- **WHEN** `ssid --short` runs
- **THEN** it prints the network name truncated to at most two words and twelve characters

### Requirement: Network and IP Helpers

`ip` SHALL print the machine's IP address in a mode selected by flag: external
(default, cascading through public IP services), `--local` (interface address),
`--router` (LAN gateway), or `--home` (home WAN via DNS lookup of `HOME_WAN`),
caching results for five minutes. `gps` SHALL print `latitude,longitude` derived
from the external IP. `router` SHALL open the LAN router's admin page in the
browser. `home-scp` SHALL copy a file home over SCP using `HOME_USER` and
`HOME_WAN`.

#### Scenario: Local IP mode

- **WHEN** `ip --local` runs
- **THEN** it prints the local interface address (defaulting to en0)

#### Scenario: Router page opened

- **WHEN** `router` runs and the LAN gateway is resolvable
- **THEN** it opens `http://<gateway-ip>` in the default browser

### Requirement: Git Workflow Helpers

The git helpers SHALL operate relative to a canonical remote and branch.
`git-canonical-remote` SHALL print `upstream` when present, else `origin`;
`git-canonical-branch` SHALL print the canonical branch; `git-canonical-path`
SHALL print `<remote>/<branch>`; `git-ancestor` SHALL print the nearest ancestor
remote branch of HEAD. `git-masterme` SHALL push the current branch to the
canonical branch; `git-rebase-master` SHALL rebase onto the canonical
remote/branch; `git-reset-hard-master` SHALL hard-reset to it; `git-killme` SHALL
tear down a finished branch, refusing to delete protected branches.

#### Scenario: Canonical remote prefers upstream

- **WHEN** `git-canonical-remote` runs in a repo with both `upstream` and `origin` remotes
- **THEN** it prints `upstream`

#### Scenario: Protected branch not deleted

- **WHEN** `git-killme` runs on a protected branch (e.g. master, main, dev, staging, production)
- **THEN** it does not delete that branch

### Requirement: Read-Only API Clients

`gmail` and `slack` SHALL be read-only clients exposing subcommands for search
and retrieval, supporting a `--json` output mode. `gmail` SHALL load OAuth
credentials from `~/.dots/sys/gmail/tokens/` and refresh expired tokens; `slack`
SHALL authenticate with bot/user tokens from the environment or `~/.dots/sys/env`
and respect rate-limit `Retry-After` headers. `spotify` SHALL control playback of
the currently-playing track (save, remove, transfer, or toggle) via the Spotify
API.

#### Scenario: Slack history retrieval

- **WHEN** `slack history <channel> --json` runs with a valid token
- **THEN** it prints the channel's recent messages as JSON

#### Scenario: Spotify toggle saves or removes current track

- **WHEN** `spotify` runs with no subcommand
- **THEN** it saves the currently-playing track if it is not saved, or removes it if it is

### Requirement: Developer Tooling

`skill-usage` SHALL render skill-invocation usage from
`~/.dots/sys/skill-usage/usage.jsonl` as a chart, with a `suggest` subcommand that
surfaces high-leverage and unused skills and a `--json` mode. `search-github`
SHALL open a GitHub code-search URL for a given org and term in the browser.
`version-update` SHALL bump a semantic version tag (patch by default) and create
an annotated git tag.

#### Scenario: Version bump defaults to patch

- **WHEN** `version-update` runs with no bump argument
- **THEN** it increments the patch component of the latest `vX.Y.Z` tag and creates the new tag

#### Scenario: Skill usage suggestions

- **WHEN** `skill-usage suggest` runs
- **THEN** it reports top, never-used, and rarely-used skills

### Requirement: Status-Line and UI Renderers

`tmux-status` SHALL render tmux status-bar segments by position
(`left`/`center`/`right`/`center-current`), scaling detail to the provided width.
`tts` SHALL speak provided text aloud, defaulting to a local Kokoro TTS engine
with an optional `--remote` OpenAI mode, and SHALL skip playback while the
microphone is active.

#### Scenario: Width-responsive tmux status

- **WHEN** `tmux-status left <width>` runs with a narrow width
- **THEN** it renders a reduced-detail status segment

#### Scenario: TTS skips while mic active

- **WHEN** `tts <text>` runs while the microphone is in use
- **THEN** it does not play audio
