---
date: 2026-04-22
category: architecture
confidence: high
---
# Policy-Without-Test Is a Distinct Bug Class in Governance-Heavy Codebases

## Context

User observed AEGIS agents repeatedly asking the human questions mid-task, violating Golden Rule #7 / Master Brain Protocol. The rule was documented clearly in `context-rules.md`, `nick-fury.md`, and a promoted instinct YAML — yet the behavior persisted.

Root-cause audit found: the rule existed only as **documentation and belief**, never as enforcement. 5 of 10 agent prompts had zero Nick Fury references. No hook blocked `AskUserQuestion`. No test checked whether spawned agents actually knew the rule. The promoted instinct's `status: promoted` field *felt* like enforcement but was only a belief-weight marker.

Rule #4 (false-ready guard) and the command-boundary "what next?" menus had the same shape. Pattern repeated across multiple rules.

## Lesson

When a rule claims enforcement — words like "MUST", "enforces", "auto-REJECTs", "blocks", "intercepts" — it is a policy-without-test bug unless at least one of these exists:

1. A **hook** in `.claude/hooks/*.sh` that blocks the violating action
2. A **test** in CI that fails if the rule is broken (e.g., grep every agent prompt for required protocol block)
3. An **assertion** in a deterministic script (start, pre-commit, stop hook) that surfaces violations
4. A **footer** inside the decision surface (agent prompt, command file) so the model reads the rule at the decision point, not after

Rules living only in markdown docs drift silently. Agents read them only when their context loads them, and defaults win otherwise.

## Application

- **When drafting a new AEGIS rule / instinct / ADR**: require the same PR to include enforcement code, not just the doc. A rule without a test is not shipped.
- **When auditing existing rules**: `grep -rE "MUST|enforc|blocks|auto-REJECT|intercept" .claude/references .claude/agents .aegis/brain/instincts` → cross-reference matches with `.claude/hooks/` and agent-prompt presence. Any mismatch is suspect.
- **When observing misbehavior**: ask "is this rule enforced, or only believed?" before assuming the model forgot. If only believed, the fix is enforcement code, not a stronger prompt.
- **Tier of enforcement matters**: prompt-level (strongest at decision point) > hook-level (tool boundary) > session-end scanner (observability) > doc-only (lowest). Rules claiming "MUST" should have at least two tiers.

Examples from AEGIS 2026-04-22 audit:
- Rule #1 force-push ban → HARD (guard-bash) ✅
- Rule #3 no amend → HARD (guard-bash) ✅
- Rule #4 false-ready guard → MISSING (fixed in PR #24)
- Rule #7 MBP → MISSING (fixed in PR #20 + #25)
- `route-questions-through-nick-fury` instinct → claimed "Loki auto-REJECTs", no code (now enforced in Loki prompt)
