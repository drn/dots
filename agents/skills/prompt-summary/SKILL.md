---
name: prompt-summary
description: Summarize the prompts used in the current conversation as a numbered list. Use when the user wants to see the prompt chain, review their prompts, or share the sequence of prompts that produced a result.
---

# Prompt Summary

Review the conversation history and produce a concise numbered list of the user prompts that drove this session.

## Instructions

### Step 1: Extract Prompts

Scan the full conversation history. Collect every user-submitted prompt in order. Exclude:
- System prompts and injected context
- Slash command invocations (e.g., /test, /pr) unless the user typed additional instructions with them
- Tool approval responses (yes/no clicks)
- Empty or whitespace-only messages

### Step 2: Classify Each Prompt

Tag each prompt as one of:
- **investigation** -- directed research, exploration, or analysis
- **implementation** -- requested code changes, file creation, or builds
- **refinement** -- adjusted output format, wording, scope, or style

### Step 3: Format the Output

Produce a numbered list. Each entry has the prompt text (quoted or paraphrased to stay concise) followed by a brief annotation of what it accomplished.

Format:

```
1. "the prompt text" -- what it accomplished
2. "the prompt text" -- what it accomplished
```

Rules:
- One line per prompt, no sub-bullets or headers
- Paraphrase long prompts to keep each line scannable (aim for under 120 characters for the prompt portion)
- Keep annotations to half a sentence

### Step 4: Add a Summary Line

End with a single line summarizing prompt count by phase. Group adjacent prompts of the same type.

Example: "Three prompts for investigation, two for refinement."

Only count phases that actually appeared. Do not force all three categories.

### Output

Print the numbered list and summary line directly -- no code fences, no headers, no preamble. The output should be immediately copy-pasteable into Slack or a document.
