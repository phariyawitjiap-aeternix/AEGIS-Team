# Sprint v15-09 Kanban

## DONE

- [x] **A** — Emit `hookSpecificOutput` on block (2pt)
  - `check.mjs` writes `{hookSpecificOutput:{hookEventName,permissionDecision,permissionDecisionReason}}` to stdout when verdict is `block`.
  - Reason format: `aegis-approval-gate blocked: <reason> [rule(s): <list>]`.
  - Legacy stderr text + exit code 2 preserved (strictly additive).
- [x] **B** — Legacy escape hatch (1pt)
  - `AEGIS_APPROVAL_GATE_SCHEMA=legacy` suppresses stdout JSON.
  - Default (unset) emits JSON.
- [x] **C** — Regression coverage (2pt)
  - Group 7 in `aegis-approval-gate-test.sh` × 5 scenarios:
    - 7.a block emits hookSpecificOutput on stdout
    - 7.b legacy env opts back to stderr-only
    - 7.c allow path emits NO stdout JSON
    - 7.d rule attribution in reason
    - 7.e exit code 2 preserved in BOTH modes

## Stories table

| Story | Type | Points | Status | Hash |
|-------|------|--------|--------|------|
| A — emit hookSpecificOutput | enhancement | 2 | DONE | — |
| B — legacy escape hatch | enhancement | 1 | DONE | — |
| C — regression coverage | testing | 2 | DONE | — |

**Total**: 5/5 points done.
