---
date: 2026-04-22
category: architecture
confidence: high
status: consolidated
merged_from:
  - 2026-04-22_policy-without-test-bug-class.md
  - 2026-04-22_mbp-needs-four-enforcement-layers.md
---

# Policy Enforcement Architecture: From Documentation to Operational Control

## Context

Agent governance rules in AEGIS are critical to safe autonomous behavior — rules like "never ask the human mid-task" and "never force-push to main" shape how agents interact with users and repositories. However, history shows that rules living only as documentation drift silently. Two distinct failure patterns emerged in v9 dogfooding:

1. **Policy-without-test bug class**: Rules claiming enforcement ("MUST", "enforces", "auto-REJECTs", "blocks") but lacking corresponding tests, hooks, or prompt-layer enforcement persist as *beliefs* rather than *controls*. The Master Brain Protocol was documented clearly in five places yet violated repeatedly because agents read those docs only when context loaded them — defaults won.

2. **Multi-layer enforcement gap**: Violations of the same rule surfaced at different layers (subagent prompts, tool boundaries, command orchestration, session-end text). Fixing one layer left others exposed because agents reach decision points through different paths.

## Lesson: Rules Need Enforcement at Multiple Tiers

When a rule claims enforcement, it is **not shipped** unless at least one of these exists:

| Tier | Location | Mechanism | Strength |
|------|----------|-----------|----------|
| **Prompt** | Subagent reading its own `.md` | Rule text + MUST-NOT constraint at decision point | Highest (fires at inference time) |
| **Tool** | Code calling a tool (e.g., `AskUserQuestion`) | PreToolUse hook that blocks unauthorized calls | Hard stop (tool-use boundary) |
| **Command boundary** | Main orchestrator finishing a `/aegis-*` command | Continuation Protocol footer in every command `.md` | Routes post-completion behavior |
| **Session end** | Main orchestrator's final text | Hook scans for option-menu + open-question patterns | Observable (learning signal) |

Missing any one tier creates a failure mode. For example:
- No prompt layer → subagent defaults to asking
- No tool layer → agent bypasses prompt and invokes `AskUserQuestion` directly
- No command-boundary layer → orchestrator finishes a command with "what next?" menu
- No session-end layer → option-menu violations in final text go undetected

## Case Study: Master Brain Protocol (MBP)

The Master Brain Protocol (v9.0) requires agents to route decisions through Nick Fury instead of asking the human. The rule was drafted in `context-rules.md` and agent prompts, but violations persisted in two distinct forms:

1. **Session/subagent violation** (early PR #20): Subagents called `AskUserQuestion` mid-task despite prompt instructions.
   - **Fix**: PreToolUse hook (`guard-ask-user.sh`) blocks non-Nick-Fury callers.
   - **Why it's not enough**: Fixes tool layer, not prompt layer or command boundary.

2. **Command orchestration violation** (PR #25): Commands like `/aegis-start` finished with "run retro? handoff? start?" menus.
   - **Root cause**: Prompt fix checked subagents, but main orchestrator code had no guard against ending with open questions.
   - **Fix**: Continuation Protocol footer in every command `.md` + `command-chain.md` reference + session-end hook pattern scanner.
   - **Why it took two sessions to surface**: The first fix was defensive at one layer; the second layer violation didn't trigger until the first one was blocked.

**Result (post-fix)**: MBP is now enforced at all four layers. Future observers can see in a single session whether a violation resurfaces at the fifth layer (it won't, but the framework is now extensible).

## Application

### When Drafting a New Rule / Instinct / ADR

Require the same PR to include enforcement code, not just documentation:

1. Write the rule in a markdown spec (e.g., `CLAUDE.md`, agent prompt, instinct YAML).
2. Identify the primary decision point (prompt? tool call? command boundary? session end?).
3. Add enforcement for that layer (footer, hook, assertion, or guard).
4. Add **at least one secondary enforcement** from a different layer (prompt + tool is a common pair; prompt + command-boundary is another).
5. Test the enforcement: write or update a test that verifies the rule blocks the violating action.

**A rule without a test is not shipped.**

### When Auditing Existing Rules

Search for enforcement claims:

```bash
grep -rE "MUST|enforc|blocks|auto-REJECT|intercept" \
  .claude/references .claude/agents .aegis/brain/instincts
```

For each match, cross-reference with:
- `.claude/hooks/*.sh` (hook-based enforcement)
- Agent prompt footers (prompt-layer rules)
- `.claude/references/command-chain.md` (command-boundary continuations)
- Session-end hook patterns (observability)

Any mismatch is suspect. Flag as enforcement debt.

### When Observing Misbehavior

Ask: **Is this rule enforced, or only believed?**

- If only believed, the fix is **enforcement code**, not a stronger prompt.
- If enforced but still violated, the enforcement is incomplete (multi-layer audit needed).
- If multi-layer enforcement exists and a rule is still violated, the violation is a **new failure mode** — document it separately and extend enforcement accordingly.

### Enforcement Hierarchy for Rule Build-Out

Priority order (when designing a "don't do X" rule):

1. **Prompt layer** (changes behavior at decision time) — highest ROI
2. **Tool layer** (hard stop at capability boundary) — hard blocks
3. **Command boundary layer** (routes post-completion) — operational control
4. **Session-end scanner** (observability/learning) — lowest ROI but feeds retrospectives

## Audit Findings (AEGIS 2026-04-22)

Examples from the v9 enforcement audit:

| Rule | Claim | Enforcement | Status |
|------|-------|------------|--------|
| Rule #1 force-push ban | MUST block | `guard-bash.sh` hook | ✅ Hard (HARD) |
| Rule #3 no amend | MUST block | `guard-bash.sh` hook | ✅ Hard (HARD) |
| Rule #4 false-ready guard | MUST prevent | None (prompt only) | ❌ Missing (fixed PR #24) |
| Rule #7 MBP / no-pause | MUST enforce | Prompt-only initially | ⚠️ Incomplete (fixed PR #20 + #25 added tool + command layers) |
| `route-questions-through-nick-fury` instinct | "Loki auto-REJECTs" | None (claimed only) | ❌ Missing (now enforced in Loki prompt) |

Rules #4 and #7 were the dominant bug-class failure modes of v9 dogfooding. Both are now multi-layer enforced.

## Forward-Looking: Enforcement as Infrastructure

As AEGIS grows, enforcement becomes a first-class infrastructure concern:

- **Pre-commit hook**: Check every new rule in CLAUDE.md, agent prompts, and ADRs for enforcement code. Reject PRs that add "MUST" claims without corresponding checks.
- **Rule audit checklist**: Quarterly scan for enforcement gaps (see audit findings above).
- **Dogfooding discipline**: After shipping a rule fix, watch for the same symptom in the next session at a *different* layer. Multi-layer violations are design signals.
- **Test harness**: Build a "rule enforcement test suite" — each rule gets a test that verifies it blocks the forbidden behavior. Run as pre-commit gate.

This transforms enforcement from an after-the-fact concern (debug a violation, add a guard) into a **design-time invariant** (no rule ships without proof it works).

