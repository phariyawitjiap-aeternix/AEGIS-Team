# Sprint Kanban — sprint-v15-03-continueonblock-investigation

**Goal**: Adopt continueOnBlock for approval-gate
**Capacity**: 5pt
**Status**: CLOSED 2026-05-13 — feature does not apply

## DONE

- [x] [CB-1] Audit which AEGIS hook is approval-gate (PreToolUse vs PostToolUse) (@iron-man) — 1pt
      Result: `aegis-approval-gate/check.mjs` is PreToolUse (matcher=Bash in settings.json).
- [x] [CB-2] Audit CC 2.1.139 release note for the exact scope of continueOnBlock (@iron-man) — 1pt
      Result: PostToolUse ONLY. Quoted: "continueOnBlock: true ใน PostToolUse — feed hook rejection reason กลับให้ Claude แล้ว continue turn".
- [x] [CB-3] Inventory AEGIS PostToolUse hooks (could any benefit?) (@iron-man) — 1pt
      Hooks: post-tool-use.sh (log), post-edit-accumulate.sh (batch quality), aegis-token-profile.sh (count), linear-sync-on-kanban.sh (sync). NONE reject the tool output. All exit 0.
- [x] [CB-4] Document the hook-stage mismatch + correction to v15-01 decision doc (@coulson) — 1pt
      Close.md notes the correction.
- [x] [CB-5] Define re-evaluation trigger (when CC adds PreToolUse soft-block) (@coulson) — 1pt
      Tracked as future signal.
