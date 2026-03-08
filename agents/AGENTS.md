## TTS Notifications

**ALWAYS speak aloud when completing ANY task or waiting for user input.** This is mandatory.

**First, check if on a call:**
```bash
mic-check  # returns "active" (exit 0) or "inactive" (exit 1)
```
If mic is **active**, skip TTS entirely — user is in a call. Do not speak.

When mic is inactive, use TTS via bash:
```bash
tts -s 1.4 "Done"  # 2-4 words max (e.g., "Done", "Updated config", "Need input")
```

Do this BEFORE moving to the next task. If you forget, you're not following instructions.
