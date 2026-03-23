---
name: eli5
description: Explain any topic in the simplest possible terms using analogies and everyday examples. Use when the user says "explain like I'm 5", "eli5", "explain simply", "dumb it down", or "explain in simple terms".
---

# Explain Like I'm 5

Break down a topic so a 5-year-old could understand it.

## Arguments

- `$ARGUMENTS` - The topic, concept, code, error message, or architecture decision to explain

## Instructions

### Step 1: Identify the topic

Read `$ARGUMENTS`. If empty, ask the user what they want explained and stop.

The topic can be anything:
- A programming concept (e.g., "recursion", "dependency injection")
- A piece of code (read the file or selection first)
- An error message or stack trace
- An architecture decision or system design
- A non-technical concept

If the topic references a file or code, read it before explaining.

### Step 2: Explain it using the ADEPT pattern

Structure your explanation in this order:

1. **Core idea first.** State what it is in one plain sentence. No jargon, no acronyms unless you define them immediately. This is the "headline" -- if the reader stops here, they still learned something.

2. **Analogy.** Connect the concept to something from everyday life -- toys, food, playgrounds, animals, building blocks, a library, a kitchen. Pick an analogy that maps well to the actual mechanics, not just the surface.

3. **Diagram (when visual).** If the concept has structure, flow, or relationships, include a short ASCII diagram. Keep it under 10 lines. Skip this for purely abstract concepts where a diagram would not help.

4. **Example.** Walk through one concrete, minimal example. For code concepts, show 3-5 lines of real code with a one-line comment. For non-code topics, give a specific scenario.

5. **Plain-English summary.** One sentence a child could repeat back. Connect the analogy to the real thing: "So [analogy] is like [real thing] because..."

Rules:
- Use short sentences. Active voice. Simple words.
- Do not hedge, qualify, or add caveats. Be confident and direct.
- Accuracy matters but simplicity wins -- leave out details that do not help understanding.
- If the topic has multiple parts, build up layer by layer. Start with the simplest piece and add complexity one step at a time.
- Maximum 2-3 short paragraphs of prose per section. Brevity is the goal.

### Step 3: Offer to go deeper

After the explanation, offer: "Want me to go deeper on any part of this, or see more examples?"
