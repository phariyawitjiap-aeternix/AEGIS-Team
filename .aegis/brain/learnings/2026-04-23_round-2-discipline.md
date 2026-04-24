---
date: 2026-04-23
category: workflow
confidence: high
source_sprint: sprint-v9-05
related_decisions: D-055, D-056
---

# Round-2 is a Real Re-Verification, Not a Promise

## Context

In sprint-v9-05, Black Panther issued verdict `CONDITIONAL` on PR #54 with one MEDIUM blocker (F1-05 Loki integration omitted) and three LOW advisories. The temptation in that moment was to accept the fix commit as sufficient and merge — "Spider-Man said he fixed it, BP said CONDITIONAL not REJECT, let's ship." Instead the flow was: Captain America (main agent) applied the 1-line fix, re-pushed, and sent BP a focused re-review request with explicit file:line claims. BP re-read the landed file, verified each of the three fixes at the specific location, and returned `PASS` only then. The merge happened on verified reality, not on promise.

This matters because sprint-v9-04 round-1 had a similar pattern and we caught a HIGH shell-injection bug via exactly this discipline. Treating CONDITIONAL as "soft approval" would have cost the framework a real vulnerability.

## Lesson

**CONDITIONAL is a real blocker, not a graduated approval.** When a reviewer says "merge only after X is fixed", the workflow is:

1. Apply the fix(es) — the exact ones listed, not approximations
2. Re-run any tests that exercise the changed surface
3. Ask the reviewer to re-verify — citing file:line for each fix
4. Merge only after the reviewer returns unconditional `PASS` or `APPROVE`

**Promises don't count.** A self-report saying "I fixed it" is evidence FOR re-verification, not a substitute for it. The reviewer's second pass is what converts a CONDITIONAL into a PASS.

## Application

**Pattern signature**: reviewer returns `CONDITIONAL` with specific blockers.

**Mandatory sequence**:
- Fix commit (minimal, surgical, one commit per blocker if possible)
- Push to the same PR branch
- Re-review request with:
  - PR/commit hash being re-reviewed
  - One-line fix summary per blocker
  - Explicit file:line claim ("fix at `.claude/agents/loki.md` line 68")
- Reviewer returns `PASS` / `APPROVE` / `REJECT` (no third CONDITIONAL round — if they'd conditional again, that's a sign the fix was wrong)

**Anti-pattern to reject**: "BP said CONDITIONAL but the LOW advisories are trivial, merging now with a TODO." If the advisories are truly trivial, fix them in the same PR. If they're not trivial, they're not advisories — promote them to blockers.

**Promoting this to an instinct** after 3+ more confirmed reinforcements — currently `active/` status in the registry.

**Canonical example**: PR #54 round-1 CONDITIONAL → commit `614b128` → BP re-review PASS → merge as `6215a52` (2026-04-23).
