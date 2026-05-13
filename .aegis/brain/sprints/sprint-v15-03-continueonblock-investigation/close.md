# Sprint v15-03 — Close (NON-APPLICABLE)

**Status**: CLOSED 2026-05-13
**Velocity**: 5/5 pt (investigation complete)
**Outcome**: Feature does not apply to AEGIS's current hook layout

## Why this is non-applicable

CC 2.1.139 release note:
> `continueOnBlock: true` ใน **PostToolUse** — feed hook rejection reason กลับให้ Claude แล้ว continue turn

`continueOnBlock` works on **PostToolUse** hooks only. It lets a hook that rejects a tool's
output emit a reason into Claude's context so the turn can continue rather than hard-stop.

AEGIS's `aegis-approval-gate/check.mjs` is a **PreToolUse** hook (registered with `matcher: "Bash"`
in `.claude/settings.json` under `hooks.PreToolUse`). It blocks the command BEFORE it runs.
There's no "PostToolUse rejection reason" because the tool never executes.

**The two hook stages have different semantics**:

| Stage | Fires | If hook exits 2 | continueOnBlock available? |
|---|---|---|---|
| PreToolUse | before tool runs | tool blocked, turn halts | ❌ NO — feature doesn't exist here |
| PostToolUse | after tool runs | output rejected, turn halts | ✅ YES — emits reason, turn continues |

## What AEGIS uses each for

PreToolUse: guard-bash, guard-write, guard-ui-edit, guard-ask-user, aegis-approval-gate.
ALL block destructive ops. ALL benefit from a "soft-block-with-feedback" pattern... but
CC 2.1.139 doesn't provide one for PreToolUse.

PostToolUse: post-tool-use (logging), post-edit-accumulate (quality), aegis-token-profile
(counting), linear-sync-on-kanban (sync). NONE of these reject. ALL exit 0 always. So
`continueOnBlock` has no use case in current AEGIS PostToolUse hooks either.

## Correction to v15-01 decision.md

The decision doc's "Phase B — Hook modernization" section listed v15-03 as 5pt to adopt
`continueOnBlock` in approval-gate. That was based on a misreading of the release note —
I assumed the feature was available for both Pre and PostToolUse. It's PostToolUse only.

decision.md should be amended (or this close.md serves as the correction). The good news:
no code was written before catching the error.

## Re-evaluation triggers

Future Claude Code release adds either:
- **PreToolUse `continueOnBlock`** — would let approval-gate emit the rule + hint into Claude's
  context, then Claude proposes a non-destructive alternative or asks for explicit auth in
  the same turn. Huge UX win for the gate.
- **AEGIS PostToolUse hook that needs to reject** — e.g., a "PR-readiness check" hook that
  blocks a `gh pr create` if tests are red. Such a hook would benefit from `continueOnBlock`
  to surface the reason without breaking the agent's flow.

Neither holds today. Sprint closes with investigation logged.

## Net session impact

v15-02 ✓ shipped (HYBRID `/goal` wiring with fallback)
v15-03 ✗ non-applicable (wrong hook stage)
v15-04 ✓ no-op (settings already wildcard-clean)
v15-05 ✓ no-op (hooks already compatible)

Net deliverable: **just v15-02** out of the 4-sprint plan. The other 3 turned out to be
audits with no actionable changes. That's a legit outcome — the framework was healthier
than the impact analysis projected.
