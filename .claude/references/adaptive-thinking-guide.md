# Adaptive Thinking Guide — Claude 4.x Extended Reasoning

> How AEGIS agents use Claude's adaptive thinking to match reasoning depth to task complexity.

---

## What Is Adaptive Thinking

Claude 4.x supports extended reasoning with `thinking: {type: "adaptive"}` — Claude reasons step-by-step before responding, using a scratchpad that is not shown to the user. The depth of reasoning is controlled by `effort` level.

Adaptive thinking replaces the deprecated `budget_tokens` parameter.

## Effort Levels

| Level | Tokens Used | Use When |
|-------|-------------|----------|
| `max` | ~32k tokens | Architecture design, security audit, complex debugging |
| `high` | ~16k tokens | Code review (multi-file), spec writing, test strategy |
| `medium` | ~8k tokens | Implementation, single-file review, QA planning |
| `low` | ~2k tokens | Document generation, scanning, simple formatting |

## Agent → Effort Mapping

| Agent | Default Effort | Rationale |
|-------|----------------|-----------|
| Nick Fury | `max` | Multi-signal decision making across entire project state |
| Iron Man | `max` | Architecture requires deep trade-off reasoning |
| Loki | `high` | Adversarial analysis needs thorough challenge generation |
| Captain America | `high` | Coordination decisions affect all downstream agents |
| Black Panther | `high` | 5-pass review must catch all correctness/security issues |
| Spider-Man | `medium` | Implementation is concrete — less ambiguity |
| War Machine | `medium` | Test strategy is structured, not open-ended |
| Wasp | `medium` | UX decisions benefit from reasoning, not excessive depth |
| Thor | `medium` | DevOps decisions are procedural with known patterns |
| Coulson | `low` | Document generation is formatting, not reasoning |
| Beast | `low` | Data gathering is pattern-matching, not analysis |
| Songbird | `low` | Documentation writing is structured output |
| Vision | `low` | Test execution is deterministic — no reasoning needed |

## How to Use in API Calls

```python
response = client.messages.create(
    model="claude-opus-4-6",
    max_tokens=16000,
    thinking={
        "type": "adaptive",
        "effort": "max"   # or "high", "medium", "low"
    },
    messages=[{"role": "user", "content": task}]
)
```

## Interleaved Thinking

With adaptive thinking enabled, Claude automatically reasons between every tool call (interleaved thinking). This means:
- Beast reasons about each scan result before the next search
- Black Panther reasons between each review pass
- Nick Fury reasons between each state check during scan

No special configuration needed — it's automatic with adaptive mode.

## Cost vs Quality Trade-off

Higher effort = better decisions + higher cost. Apply `max`/`high` only when the decision is consequential:
- Wrong architecture costs 10x to fix → use `max`
- Wrong test case → easy to add later → use `medium`
- Wrong document format → trivial to edit → use `low`

## When NOT to Use Extended Thinking

- Simple CRUD operations (Spider-Man implementing a well-specified endpoint): `low`/`medium`
- Document skeleton generation (Coulson, BLOCK 0): `low`
- Test execution (Vision): none needed, Vision runs deterministic commands
