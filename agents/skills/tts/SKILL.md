---
name: tts
description: >
  Read text aloud using text-to-speech. Use when the user says
  "speak to me", "read to me", "read this aloud", "say this",
  "speak the summary", or asks to hear something spoken.
---

# Text-to-Speech

Read content aloud using the `tts` CLI (Kokoro TTS locally, or OpenAI with `--remote`).

## Arguments

- `$ARGUMENTS` - Optional text or reference to read aloud (e.g., "read the summary to me")

## Instructions

### Step 1: Determine Content

Figure out what to speak from the user's message and conversation context:

- If the user said "speak to me" or "read to me" with no specific content, summarize the most recent output or finding in 1-2 sentences and speak that.
- If the user referenced specific content ("read the summary", "say the plan"), speak a concise version of that content.
- If the user provided literal text ("say hello world"), speak exactly that.

### Step 2: Speak

Run the `tts` command via bash:

```bash
tts -s 1.4 "Your text here"
```

- **Speed**: Use `-s 1.4` by default
- **Voice**: heart (default) — user can request others with `-v`: alloy, nova, bella, sky, echo, onyx, or any Kokoro voice ID (af_heart, am_adam, etc.). Voices are auto-cached on first use (brief download delay).
- **Remote**: Add `--remote` to use OpenAI TTS API instead of local Kokoro
- **Daemon**: A persistent daemon auto-starts on first use to keep the model warm (~3s vs ~6.5s cold start). Use `tts serve` / `tts stop` to manage manually.
- **Length**: Keep spoken text concise. For long content, summarize to key points rather than reading verbatim.

### Step 3: Confirm

After speaking, briefly confirm what was read (e.g., "Spoke the deployment summary."). Do not repeat the full text in chat.
