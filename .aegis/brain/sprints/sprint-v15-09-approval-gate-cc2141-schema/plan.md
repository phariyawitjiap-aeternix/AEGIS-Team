# Sprint v15-09 — Approval-Gate CC 2.1.141 Schema

> Align `aegis-approval-gate` block output with Claude Code 2.1.141's
> permission-dialog JSON schema so a blocked Bash command renders an
> attributed dialog ("Blocked by aegis-approval-gate: …") instead of the
> generic "Hook exited 2" message.

## Sprint metadata

- **ID**: sprint-v15-09-approval-gate-cc2141-schema
- **Points**: 5
- **Status**: SELECTED
- **Branch**: `claude/sprint-v15-09-approval-gate-schema`
- **Driver**: CC 2.1.141 release notes flagged structured permission-dialog
  attribution as a top developer-experience improvement.

## Spec spike outcome

CC 2.1.141 documents the PreToolUse hook output schema as:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny" | "ask" | "allow",
    "permissionDecisionReason": "string"
  }
}
```

AEGIS currently uses the legacy contract (exit code 2 + stderr text).
That still works in CC 2.1.141 — it falls back to a generic block message.
Emitting `hookSpecificOutput` is **strictly additive**: CC 2.1.141 reads it
for the attributed dialog, older CC versions ignore unknown stdout JSON
and fall back to the exit-code path.

## Stories

| Story | Points | Description |
|-------|--------|-------------|
| A — emit hookSpecificOutput on block | 2 | `check.mjs` writes the documented JSON to stdout when a Bash rule matches; preserves exit code 2 + stderr text. |
| B — legacy escape hatch | 1 | `AEGIS_APPROVAL_GATE_SCHEMA=legacy` opts back to stderr-only output if a future CC version regresses. |
| C — regression coverage | 2 | Group 7 in `aegis-approval-gate-test.sh` × 5 scenarios — schema shape, env override, allow path, rule attribution, exit-code backward compat. |

## Acceptance criteria

1. Blocked command → `hookSpecificOutput.{hookEventName,permissionDecision,permissionDecisionReason}` JSON on stdout.
2. `hookEventName` is literally `PreToolUse`; `permissionDecision` is literally `deny`; `permissionDecisionReason` begins with `aegis-approval-gate blocked:`.
3. Matched rule names are surfaced in the reason via `[rule(s): ...]`.
4. Allow path emits NO stdout JSON (only blocks do).
5. `AEGIS_APPROVAL_GATE_SCHEMA=legacy` suppresses stdout JSON.
6. Exit code 2 + stderr human text preserved in BOTH modes.
7. p95 latency budget unchanged (<200ms).
8. Full suite stays GREEN.

## Out of scope

- `permissionDecision: "ask"` flows — current rule engine has only
  block/allow. The `ask` decision would need a new gate-rules.yaml field.
- Migration of the AEGIS-side dialog UI (CC owns the rendering).
- Restricted-tier app handling — separate concern.

## Risks

- **R1**: CC < 2.1.141 might log a "unrecognized stdout JSON" warning.
  Mitigation: rendering is additive and never blocks the block path; if a
  warning appears, the legacy env var disables JSON output.
- **R2**: CC 2.1.141 might require `permissionDecision: "allow"` to be
  emitted for non-block paths too. Mitigation: AEGIS only emits on block,
  so the allow path follows the legacy "no output, exit 0" contract that
  CC supports forever.

## Verification plan

1. `bash tests/aegis-approval-gate-test.sh` → 26/26 (was 21, +5 v15-09).
2. `bash tests/run-all.sh --continue` → 58/58 stays GREEN.
3. Manual sanity: `printf '{"tool_name":"Bash","tool_input":{"command":"rm -rf /tmp/x"}}' | node tools/aegis-approval-gate/check.mjs`
   → stderr has BLOCKED text, stdout has `hookSpecificOutput` JSON, exit
   code 2.
