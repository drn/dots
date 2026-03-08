---
name: email
description: Search and read Gmail messages. Use when looking up emails, reading email threads, or checking inbox labels.
---

# Email (Read-Only)

Search and read Gmail messages using the `gmail` CLI.

## Instructions

You are helping read Gmail data. Auth uses OAuth tokens stored at `~/.google-mcp/tokens/`. Additional env vars (if any) are loaded from `~/.dots/sys/env`.

### Operations

```bash
# Search emails
gmail search "from:emily subject:kickoff"     # Search by sender and subject
gmail search "is:unread" --limit 10           # Recent unread
gmail search "after:2025/01/01 from:sarah"    # Date-filtered search

# Read a specific email
gmail read MESSAGE_ID                         # Read full email by ID

# List labels with message counts
gmail labels

# Use a specific account
gmail search "budget" --account personal
gmail labels --account work

# JSON output
gmail search "quarterly review" --json
```

### Common Tasks

#### Find recent emails from someone
```bash
gmail search "from:emily" --limit 10
```

#### Read an email thread
```bash
# First search to find message IDs
gmail search "subject:technical kickoff" --limit 5
# Then read the specific message
gmail read MESSAGE_ID
```

#### Check unread count
```bash
gmail labels
```

### Account Resolution

The CLI resolves accounts in this order:
1. `--account NAME` flag — uses `~/.google-mcp/tokens/NAME.json`
2. Default account from `~/.google-mcp/accounts.json`
3. First token file found in `~/.google-mcp/tokens/`

### Search Syntax

Gmail search supports standard Gmail query operators:
- `from:sender` — messages from a specific sender
- `to:recipient` — messages to a specific recipient
- `subject:words` — subject line search
- `after:YYYY/MM/DD` / `before:YYYY/MM/DD` — date range
- `is:unread` / `is:starred` — message state
- `has:attachment` — messages with attachments
- `label:NAME` — messages with a specific label
- `in:inbox` / `in:sent` — location filters

## Capabilities

- **Email search**: Full Gmail query syntax with pagination
- **Email reading**: Full message content including headers, body text, and attachment metadata
- **Label listing**: All labels with message counts (total and unread)

## Limitations

- **Read-only** — Cannot send, draft, archive, or modify emails. For composing replies, draft the text in the conversation for manual copy/paste.
- Message body is truncated at 5000 characters
- OAuth tokens must be pre-configured in `~/.google-mcp/tokens/`
