# Hammerspoon Music Controls (Spotify / Apple Music)

`hammerspoon/music.lua` dispatches to `hammerspoon/music/spotify.lua` or
`hammerspoon/music/apple_music.lua` based on which app is running
(`hammerspoon/music.lua:8`). Bindings live in `hammerspoon/init.lua`.

## Why Spotify needs a separate CLI, but Apple Music doesn't

Everything except save/remove/transfer goes through `hs.spotify` /
`hs.itunes` (Hammerspoon's built-in modules), which just wrap AppleScript —
no separate CLI needed for play/pause/next/previous/seek/volume/display.

Apple Music's local AppleScript dictionary exposes a `favorited` track
property, so `itunes.save`/`itunes.remove` in `apple_music.lua` implement
"like/unlike" with pure AppleScript. `itunes.toggle`/`itunes.transfer` are
explicitly unsupported (`alert.show("Unsupported")`).

Spotify's local AppleScript dictionary has **no equivalent** — no
save-to-library verb, no transfer-to-device verb. Those are Spotify **Web
API** operations (`/me/tracks`, `/me/player`) requiring OAuth, which
`osascript` structurally cannot do (it only talks to apps with an AppleScript
dictionary, not arbitrary HTTP+OAuth). That's why `cmd/spotify` (a Go binary
at `~/go/bin/spotify`) exists and is shelled out to via `hs.execute` in
`spotify.lua`'s `spotifyExec` — it's irreplaceable by AppleScript, not a
workaround.

`spotify.toggle` (and the corresponding entry in `music.lua`'s `bindings`
table) is dead code — nothing in `init.lua` calls `music.toggle()`.
`save`/`remove`/`transfer` are real, bound to `ctrl+cmd+=`, `ctrl+cmd+-`, and
`cmd+alt+shift+delete` respectively (`init.lua`).

## OAuth setup (`cmd/spotify/auth`)

- `SPOTIFY_REDIRECT_URI` (in `~/.dots/sys/env`) must be a **loopback URL with
  an explicit port**, e.g. `http://127.0.0.1:8888/callback` — the CLI starts
  a local HTTP server on that port to catch the OAuth callback itself, and
  the same URI must be registered under Redirect URIs on the app at
  https://developer.spotify.com/dashboard.
- Cached tokens live in `~/.dots/sys/config` under `[spotify]`
  (`access_token`, `refresh_token`), managed via `cli/config`.
- As of 2026-09-03, `FetchAccessToken` (`cmd/spotify/auth/root.go`)
  self-heals specifically from `invalid_grant` (a revoked/expired refresh
  token): it clears the stale cached tokens and falls back to a full
  interactive re-authorization automatically, capped at one retry so a
  persistently-failing cache write can't loop forever. Any other
  token-endpoint failure (rate limit, 5xx, etc.) still exits without
  touching the cache, since destroying an otherwise-good refresh token over
  a transient error would be worse than the old behavior. Previously any
  non-200 forced a manual clear of `~/.dots/sys/config`'s
  `[spotify]` section by hand to force re-auth.
