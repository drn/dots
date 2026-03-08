---
name: tts
description: >
  Read text aloud using text-to-speech. Use when the user says
  "speak to me", "read to me", "read this aloud", "say this",
  "speak the summary", or asks to hear something spoken.
---

# Text-to-Speech

Read content aloud to the user using the `openai_tts` MCP tool.

## Arguments

- `$ARGUMENTS` - Optional text or reference to read aloud (e.g., "read the summary to me")

## Instructions

### Step 1: Check Mic

```bash
mic-check
```

If exit code is 0 (mic active), tell the user: "Skipping TTS — your mic is active (likely on a call)." Stop here.

### Step 2: Determine Content

Figure out what to speak from the user's message and conversation context:

- If the user said "speak to me" or "read to me" with no specific content, summarize the most recent output or finding in 1-2 sentences and speak that.
- If the user referenced specific content ("read the summary", "say the plan"), speak a concise version of that content.
- If the user provided literal text ("say hello world"), speak exactly that.

### Step 3: Speak

Use the `mcp__tts__openai_tts` tool:

- **Speed**: 1.4
- **Voice**: alloy (default) — user can request: echo, fable, onyx, nova, shimmer
- **Length**: Keep spoken text concise. For long content, summarize to key points rather than reading verbatim.

### Step 4: Confirm

After speaking, briefly confirm what was read (e.g., "Spoke the deployment summary."). Do not repeat the full text in chat.
