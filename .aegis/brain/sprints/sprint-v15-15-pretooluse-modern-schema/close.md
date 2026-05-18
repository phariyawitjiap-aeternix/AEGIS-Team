# Sprint v15-15 Close — PreToolUse modern-schema migration

**Status**: CLOSED (100%)
**Date**: 2026-05-18
**Driver**: User-reported recurring "Bash hook error" / "Write hook error" red labels in CC 2.1.143
**Branch**: `claude/sprint-v15-15-pretooluse-modern-schema`

## What shipped

Three PreToolUse hooks migrated from **dual-path** (modern JSON + stderr + exit 2) to **modern-only** (JSON + exit 0):

1. `tools/aegis-approval-gate/check.mjs`
2. `.claude/hooks/guard-bash.sh`
3. `.claude/hooks/guard-write.sh`

Each preserves a `*_LEGACY=1` env-var escape hatch for older CC versions:
- `AEGIS_APPROVAL_GATE_LEGACY=1`
- `AEGIS_GUARD_LEGACY=1`

## Behavior change

| Scenario | Before (v15-09) | After (v15-15) |
|---|---|---|
| Modern CC sees a block | JSON dialog **+** "Bash hook error" red label | JSON dialog only ✓ |
| Stderr on block (modern) | Multi-line BLOCKED context | None — context lives in `permissionDecisionReason` |
| Exit code (modern) | 2 | 0 |
| Legacy opt-in | Schema env var | `*_LEGACY=1` env var |

## Why it works

CC 2.1.141+ has two block-detection paths:

1. **Modern**: read `hookSpecificOutput.permissionDecision` from stdout
2. **Legacy**: see exit non-zero + non-empty stderr

Before v15-15, AEGIS PreToolUse hooks emitted BOTH. CC read the modern
JSON correctly (showed the permission dialog) — but ALSO matched the
legacy hook-error trigger and tagged the event with a red "hook error"
label. Now AEGIS emits only modern, so CC only fires the dialog path.

## Test coverage

- `tests/aegis-approval-gate-test.sh`: 26 → 27 (+ 7.f no-stderr-on-modern-block)
- `tests/aegis-guard-write-test.sh`: 9/9 (exit-code asserts 2→0)
- `tests/aegis-maintainer-test.sh`: invoke_guard_* helpers refactored to detect via JSON; 23/23 PASS
- Full suite: 59/59 PASS

## Verification

```
$ echo '{"tool_name":"Bash","tool_input":{"command":"git push --force"}}' | node tools/aegis-approval-gate/check.mjs
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"⛔ aegis-approval-gate: BLOCKED\n   command:  git push --force\n   rule(s):  git-force-push\n..."}}
$ echo "exit=$?"
exit=0
$ # stderr is empty — no "Bash hook error" trigger
```

## Out of scope

- `guard-ask-user.sh` — rarely fires; same migration deferred to v15-16
- Audit of PostToolUse/Stop/SessionStart hooks for stderr leaks — already exit 0 + log-to-file per v15-12
- CC version detection — relies on CC's own backward-compat handling

## Roadmap impact

v15 net: 42pt → 47pt.

## Related

- Builds on v15-09 (CC 2.1.141 permission-dialog adoption — dual-path)
- Builds on v15-12 (PostToolUse friendly-fail)
- Closes the loop: AEGIS is now fully aligned with CC 2.1.141 hook contract
