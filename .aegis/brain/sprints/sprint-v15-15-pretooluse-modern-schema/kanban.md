# Sprint v15-15 Kanban

## DONE

- [x] **A** — `aegis-approval-gate/check.mjs` modern-only default (2pt)
  - Block path: exit 0 + JSON-only (no stderr)
  - Full BLOCKED context (rule list, reason, hint) moved into `permissionDecisionReason`
  - `AEGIS_APPROVAL_GATE_LEGACY=1` opts back into stderr + exit 2 + JSON dual-path
- [x] **B** — `guard-bash.sh` modern schema (1pt)
  - `block()` emits `hookSpecificOutput.permissionDecision: "deny"` + exit 0
  - `AEGIS_GUARD_LEGACY=1` opts back into `decision: block` + stderr + exit 2
  - JSON-escapes reason via python3 (handles quotes/newlines safely)
- [x] **C** — `guard-write.sh` modern schema (1pt)
  - Same migration as guard-bash
- [x] **D** — Tests + regression (1pt)
  - `run_check` helper in approval-gate test refactored to be implementation-agnostic (detect block via JSON OR exit code)
  - Group 7 updated: new env var name, new exit codes, added 7.f "no stderr on modern block"
  - `aegis-guard-write-test.sh` exit code assertions 2→0
  - `aegis-maintainer-test.sh` `invoke_guard_*` helpers refactored to detect block via JSON
  - Suite stays 59/59 PASS

## Stories table

| Story | Type | Points | Status |
|-------|------|--------|--------|
| A — approval-gate modern-only | bug-fix | 2 | DONE |
| B — guard-bash modern schema | bug-fix | 1 | DONE |
| C — guard-write modern schema | bug-fix | 1 | DONE |
| D — tests + regression | testing | 1 | DONE |

**Total**: 5/5 points done.
