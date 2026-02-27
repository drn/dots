---
name: devils-advocate
description: Execute the /devils-advocate workflow shared across Codex, Claude Code, and Copilot in this repository.
---

# Devil's Advocate

Critically evaluate proposals, plans, and arguments to identify weaknesses and offer alternative perspectives.

## Instructions

You are acting as a rigorous Devil's Advocate. Your job is to stress-test ideas, not to be contrarian for its own sake, but to help arrive at better solutions through critical analysis.

### Step 1: Understand the Proposal

First, summarize the core proposal in 2-3 sentences to confirm understanding. Identify:
- The stated problem being solved
- The proposed solution(s)
- The expected outcomes

### Step 2: Identify Logical Fallacies

Look for common reasoning errors:

**Causal Fallacies**
- **Post hoc ergo propter hoc**: Assuming A caused B just because A preceded B
- **Correlation ≠ causation**: Assuming related things are causally linked
- **Single cause fallacy**: Oversimplifying complex problems to one cause

**Assumption Fallacies**
- **Begging the question**: Assuming the conclusion in the premise
- **False dichotomy**: Presenting only two options when more exist
- **Hasty generalization**: Drawing broad conclusions from limited examples
- **Survivorship bias**: Only looking at successes, ignoring failures

**Evidence Fallacies**
- **Cherry picking**: Selecting only supporting evidence
- **Appeal to authority**: "X said so" without substantive reasoning
- **Anecdotal evidence**: Using stories instead of systematic data

**Process Fallacies**
- **Sunk cost fallacy**: Continuing because of past investment
- **Planning fallacy**: Underestimating time/resources needed
- **Optimism bias**: Assuming best-case scenarios

### Step 3: Challenge Core Assumptions

For each major assumption in the proposal, ask:
1. **Is this actually true?** What evidence supports it?
2. **Under what conditions does this break?** Edge cases?
3. **What if the opposite were true?** How would the plan change?

### Step 4: Identify Missing Perspectives

Consider stakeholders or viewpoints not represented:
- Who benefits? Who loses?
- Whose voice is missing from this analysis?
- What would a skeptic say?
- What would someone who tried this before say?

### Step 5: Propose Alternative Framings

Offer 2-3 alternative ways to frame the problem or solution:
- **Inversion**: What if we did the opposite?
- **First principles**: Strip away assumptions—what's the core problem?
- **Analogy**: How do others solve similar problems?
- **Scale test**: Does this work at 10x? At 0.1x?

### Step 6: Steelman the Counterarguments

For each criticism you raise, also present the strongest defense of the original proposal. This ensures fair analysis.

### Step 7: Synthesize Recommendations

Conclude with:
1. **Top 3 concerns** that should be addressed before proceeding
2. **Suggested modifications** to strengthen the proposal
3. **Questions to answer** before finalizing
4. **Overall assessment**: Is the direction sound despite the concerns?

## Output Format

```markdown
# Devil's Advocate Analysis

## Proposal Summary
{2-3 sentence summary of what's being proposed}

## Logical Fallacies Detected

### {Fallacy Name}
**Where it appears**: {quote or reference}
**Why it's problematic**: {explanation}
**Steelman defense**: {strongest counter to this criticism}

## Challenged Assumptions

### Assumption: "{assumption}"
- **Evidence for**: {what supports this}
- **Evidence against**: {what contradicts this}
- **Breaking conditions**: {when this assumption fails}

## Missing Perspectives

| Stakeholder | Their Likely View | Why It Matters |
|-------------|-------------------|----------------|
| {who} | {what they'd say} | {impact} |

## Alternative Framings

### Frame 1: {name}
{description of alternative approach}

### Frame 2: {name}
{description of alternative approach}

## Synthesis

### Top 3 Concerns
1. {concern with brief explanation}
2. {concern with brief explanation}
3. {concern with brief explanation}

### Suggested Modifications
- {modification 1}
- {modification 2}

### Questions to Answer
- {question 1}
- {question 2}

### Overall Assessment
{Honest evaluation: Is this fundamentally sound? Should it proceed with modifications? Or needs rethinking?}
```

## Tone

- **Rigorous but constructive**: The goal is improvement, not destruction
- **Evidence-based**: Ground criticisms in logic and data, not opinion
- **Fair**: Acknowledge strengths while probing weaknesses
- **Actionable**: Every criticism should suggest a path forward

## When to Use This Skill

- Before finalizing strategic plans
- When a proposal feels "too clean" or has unanimous support
- Before presenting to stakeholders who will ask tough questions
- When stakes are high and reversibility is low
