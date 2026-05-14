# Sprint v15-09 Close — Approval-Gate CC 2.1.141 Schema

**Status**: CLOSED (100%)
**Date**: 2026-05-14
**Tests**: 58/58 (approval-gate suite expanded 21/21 → 26/26 with Group 7)
**Branch**: `claude/sprint-v15-09-approval-gate-schema`

## What shipped

- `tools/aegis-approval-gate/check.mjs` — on block verdict, emits
  `{hookSpecificOutput: {hookEventName, permissionDecision, permissionDecisionReason}}`
  to stdout in addition to the legacy stderr text + exit code 2.
- Reason format: `aegis-approval-gate blocked: <reason> [rule(s): <list>]`.
- `AEGIS_APPROVAL_GATE_SCHEMA=legacy` env var disables stdout JSON
  emission (escape hatch).
- `tests/aegis-approval-gate-test.sh` — Group 7 (5 scenarios).
- Approval cleanup before Group 7 (find-delete on `.yaml` files) so the
  new tests see a clean block path despite earlier groups granting
  approvals.

## Spec-spike result

CC 2.1.141 PreToolUse hook output schema (documented):

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny" | "ask" | "allow",
    "permissionDecisionReason": "string"
  }
}
```

AEGIS implements `deny` only — the rule engine has no `ask` decision
today. Emitting `permissionDecision: "deny"` triggers CC 2.1.141's
attributed permission dialog. Older CC versions ignore unknown stdout
JSON and fall back to the exit-code-2 path (verified by 7.b legacy mode).

## Design decisions

- **Strictly additive JSON**: Don't replace the legacy contract; layer on
  top. Stderr + exit 2 remain authoritative; CC 2.1.141 reads the JSON
  for the dialog text but the hook still blocks even if JSON parsing
  fails.
- **Default ON**: New CC versions are the majority case. Legacy env var
  is the kill-switch, not the on-switch.
- **Reason includes rule attribution**: `[rule(s): rm-rf, git-force-push]`
  embedded in the reason string so the dialog tells the user WHICH rule
  fired without expanding the schema.

## Verification

```
$ bash tests/aegis-approval-gate-test.sh
RESULTS: 26 passed, 0 failed
ALL PASSED

$ bash tests/run-all.sh --continue
ALL TESTS PASS — 58/58

$ printf '{"tool_name":"Bash","tool_input":{"command":"rm -rf /tmp/x"}}' \
    | node tools/aegis-approval-gate/check.mjs
[stderr]
⛔ aegis-approval-gate: BLOCKED
   command:  rm -rf /tmp/x
   rule(s):  rm-rf
   reason:   matched destructive pattern

[stdout]
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"aegis-approval-gate blocked: matched destructive pattern [rule(s): rm-rf]"}}

[exit code]
2
```

## Follow-ups

- If CC adds PreToolUse-time `permissionDecision: "ask"` (interactive
  approval), extend the rule engine to emit `ask` instead of `block`
  for low-severity rules. Currently out of scope.
- Migrate the same schema to the PostToolUse audit hook if CC supports
  attribution there.

## Roadmap impact

v15 net deliverable: 23pt → 28pt.
