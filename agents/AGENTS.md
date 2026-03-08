## TTS Notifications

**ALWAYS speak aloud when completing ANY task or waiting for user input.** This is mandatory.

Use the **Haiku** model to generate a task-specific summary (6 words max), then speak it:
```bash
tts -s 1.1 "<SUMMARY>"           # default
tts -s 1.1 -v alloy "<SUMMARY>"  # for thanx repos (git remote contains "thanx")
```

The `tts` command automatically skips playback when the mic is active (e.g., on a call).

Do this BEFORE moving to the next task. If you forget, you're not following instructions.
