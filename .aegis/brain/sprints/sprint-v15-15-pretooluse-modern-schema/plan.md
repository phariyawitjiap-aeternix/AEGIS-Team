# Sprint v15-15 — PreToolUse modern-schema migration

> Permanent fix for the "Bash hook error" / "Write hook error" red labels
> CC 2.1.143 was showing whenever AEGIS legitimately blocked a
> destructive operation. Root cause: PreToolUse hooks emitted modern
> JSON schema *and* stderr text *and* exit 2. CC reads the JSON to
> render the permission-denied dialog correctly, but also sees the
> stderr+exit-2 combo and tags the event as a hook error.

## Sprint metadata

- **ID**: sprint-v15-15-pretooluse-modern-schema
- **Points**: 5
- **Status**: SELECTED
- **Branch**: `claude/sprint-v15-15-pretooluse-modern-schema`
- **Driver**: User-reported recurring "Bash hook error" / "Write hook error" labels in CC UI on CC 2.1.143

## Root cause

Three PreToolUse hooks used a **dual-path** block contract:

| Hook | Behavior on block | What CC sees |
|---|---|---|
| `aegis-approval-gate/check.mjs` | stdout JSON (modern) + stderr text + exit 2 | "Bash hook error" 🔴 |
| `.claude/hooks/guard-bash.sh` | stdout JSON (legacy `decision: block`) + exit 2 | "Bash hook error" 🔴 |
| `.claude/hooks/guard-write.sh` | stdout JSON (legacy `decision: block`) + exit 2 | "Write hook error" 🔴 |

CC 2.1.141+ uses the modern `hookSpecificOutput.permissionDecision: "deny"`
schema to render a proper permission-denied dialog. But the legacy
exit-2 + stderr signal triggers CC's "hook error" UI in parallel —
making legitimate blocks look like bugs.

## Stories

| Story | Points | Description |
|-------|--------|-------------|
| A — approval-gate modern-only default | 2 | `check.mjs` emits ONLY the modern JSON + exit 0. Full BLOCKED context (rule, reason, hint) moves into `permissionDecisionReason` instead of stderr. `AEGIS_APPROVAL_GATE_LEGACY=1` opts back into stderr + exit 2 for older CC. |
| B — guard-bash modern schema | 1 | `.claude/hooks/guard-bash.sh` `block()` now emits `hookSpecificOutput.permissionDecision` + exit 0 by default. `AEGIS_GUARD_LEGACY=1` re-enables dual-path. |
| C — guard-write modern schema | 1 | Same migration for guard-write. |
| D — Tests + regression | 1 | Update Group 7 in approval-gate test for new env var + new default exit code; update guard-write test asserts (exit 2 → exit 0). Add 7.f "no stderr on modern block" assertion. |

## Acceptance criteria

1. **Default block path emits NO stderr and exits 0** — for all 3 hooks.
2. Modern JSON output includes the full human-readable context in `permissionDecisionReason` (rule list, reason, hint).
3. `AEGIS_APPROVAL_GATE_LEGACY=1` and `AEGIS_GUARD_LEGACY=1` env vars restore the v15-09 dual-path behavior (stderr + exit 2).
4. CC 2.1.141+ users no longer see "Bash hook error" / "Write hook error" red labels when blocks fire — they see only the proper permission-denied dialog.
5. Existing test contracts updated to match new behavior; suite stays GREEN.

## Out of scope

- Wider audit of which other hooks emit stderr unexpectedly (PostToolUse, Stop, SessionStart all already exit 0 + log-to-file per v15-12).
- CC version detection — relies on CC's own backward-compat handling of unknown stdout JSON.
- `guard-ask-user.sh` — its rare-trigger path can be migrated later as v15-16 candidate.

## Verification plan

1. `bash tests/aegis-approval-gate-test.sh` → 27/27 PASS (was 26; added 7.f)
2. `bash tests/aegis-guard-write-test.sh` → 9/9 PASS
3. `bash tests/run-all.sh --continue` → 59/59 PASS
4. Manual: trigger approval-gate block, verify NO stderr, exit 0, JSON on stdout
5. Manual: set `AEGIS_APPROVAL_GATE_LEGACY=1`, verify stderr + exit 2
