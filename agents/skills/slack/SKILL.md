---
name: slack
description: Query Slack channels, search messages, and fetch user information. Use when reading Slack data, checking channel history, searching messages, or looking up users.
---

# Slack (Read-Only)

Query Slack channels, search messages, and fetch user information using the `slack` CLI.

## Instructions

You are helping query Slack data. Auth is handled via environment variables loaded from `~/.dots/sys/env`:
- `SLACK_XOXP_TOKEN` — user token for search, history, thread, dms
- `SLACK_XOXB_TOKEN` — bot token for channels, users

### Operations

```bash
# Test authentication
slack auth-test

# Channel operations
slack channels                                # List all channels
slack find-channel releases                   # Find channel by name

# Message history
slack history C04M5PG7P7T                     # By channel ID
slack history releases --limit 50             # By name, limit 50
slack history releases --days 7               # Last 7 days

# Thread replies
slack thread C04M5PG7P7T 1234567890.123456

# Search messages
slack search "deployment failed"              # Full search
slack search "urgent" --days 1                # Last 24 hours
slack search "from:@darren" --days 7 --full   # Full message text

# User operations
slack users                                   # List all users
slack find-user darren                        # Find by name

# DMs
slack dms                                     # List DM conversations

# JSON output (for programmatic use)
slack channels --json
```

### Common Tasks

#### Get recent channel history
```bash
slack history releases --days 7
```

#### Search for mentions of a topic
```bash
slack search "outage" --days 7
```

#### Find who posted about something
```bash
slack search "from:@darren deployment" --days 30
```

#### Get activity from a specific person
```bash
# First find their user ID
slack find-user "john"
# Then search their messages
slack search "from:@john" --days 7
```

#### Full-Text Search
By default, search truncates messages to 200 chars. Use `--full` for complete message text:
```bash
slack search "from:@aaron" --days 7 --full
```

### Token Types & Required Scopes

| Token | Env Var | Used For |
|-------|---------|----------|
| User (xoxp) | `SLACK_XOXP_TOKEN` | `search`, `dms`, `history`, `thread` |
| Bot (xoxb) | `SLACK_XOXB_TOKEN` | `channels`, `users`, `find-user`, `find-channel` |

**Required User Token Scopes**: `channels:history`, `channels:read`, `groups:history`, `groups:read`, `im:history`, `im:read`, `mpim:history`, `mpim:read`, `search:read`, `users:read`

**Required Bot Token Scopes**: `channels:read`, `groups:read`, `users:read`, `users:read.email`

### API Rate Limits

Slack has rate limits:
- Tier 1 methods (chat.postMessage): 1 request/second
- Tier 2 methods (conversations.history): 20 requests/minute
- Tier 3 methods (search.messages): 20 requests/minute

If rate limited, wait for the `retry_after` period.

### Error Handling

Common errors:
- `channel_not_found` — Channel doesn't exist or bot/user not in channel
- `not_in_channel` — Need to join the channel first
- `ratelimited` — Too many requests, check `retry_after`
- `invalid_auth` — Token is expired or invalid
- `missing_scope` — Token lacks required OAuth scopes

## Capabilities

- **Channel listing**: Public and private channels the user has access to
- **Channel history**: Messages from any channel (with proper permissions)
- **Thread replies**: Full thread contents
- **Message search**: Full-text search with date filters
- **User lookup**: Find users by name, display name, or email
- **DM listing**: List direct message conversations

## Limitations

- **Read-only** — Cannot send messages. When asked to send/DM someone, draft the message as copyable text instead.
- Cannot access channels the user/bot isn't in
- Search results are truncated to 200 chars by default. Use `--full` for complete text.
- Rate limited by Slack's API tier system
