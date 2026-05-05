# Sprint v11-05 Plan: aegis-approval-gate (PreToolUse blocker)

**Points**: 8pt · **Branch**: `feat/v11-05-aegis-approval-gate`
**Phase-2 first sprint** — gate opened 2026-05-05 with 2/3 signals (audit-query + run-replay).

## Goal

Block destructive / sensitive Bash ops until an active (non-expired) approval marker exists. Closes G5 from the AEGIS-Plus Mega Plan §7.1.

## Stories

| ID | Story | Pt |
|----|-------|----|
| A | Skill scaffolding + rules schema (`.aegis/brain/gate-rules.yaml` default + per-project override) | 1 |
| B | `check.mjs` PreToolUse hook — pattern match Bash command, search `.aegis/brain/approvals/`, block-or-allow with explicit message | 3 |
| C | `grant.mjs` / `list.mjs` / `revoke.mjs` CLI — issue YAML markers with TTL, list active, revoke by id | 2 |
| D | Tests + AEGIS_BYPASS=1 emergency override + bypass-audit log line | 2 |

## Storage

- `.aegis/brain/gate-rules.yaml` — default destructive patterns (`rm -rf`, `git push --force`, `git reset --hard`, `DROP TABLE`, `chmod -R 777 /`, `dd of=/dev/`, `sudo rm`)
- `.aegis/brain/approvals/<task>-<action>.yaml` — one file per approval, content per Mega Plan §7.1:
  ```yaml
  task: KTH-42
  action: deploy-prod
  approved_by: phariyawit.jiap
  approved_at: 2026-05-05T14:00:00Z
  expires_at: 2026-05-05T15:00:00Z
  scope: ["bash:rm -rf", "bash:git push --force"]
  ```
- `.aegis/brain/logs/approval-audit.log` — every block/allow/bypass decision (one JSON per line)

## Hook wiring

`.claude/settings.json` PreToolUse:
```jsonc
{
  "matcher": "Bash",
  "hooks": [
    { "type": "command", "command": "node \"$CLAUDE_PROJECT_DIR/tools/aegis-approval-gate/check.mjs\"" }
  ]
}
```

PreToolUse hooks **can** block (exit 2) — that's the whole point of this skill.

## Acceptance criteria (Mega Plan §7.1)

- [ ] `rm -rf` blocked without an approval marker
- [ ] Approval marker created via grant.mjs grants permission for matching scope, until expires_at
- [ ] Expired markers ignored
- [ ] Non-matching tool calls pass through unaffected (Edit/Write/Read/non-destructive Bash)
- [ ] Live-tail emits ⛔ on block (already wired — emit.mjs reads tool_response which our hook can populate)
- [ ] `AEGIS_BYPASS=1 bash ...` env var override allows bypass + writes audit-log entry (Risk R5 mitigation)
- [ ] Performance: PreToolUse hook latency p95 <100ms (Risk R1 — must not slow every Bash)

## Risks (Mega Plan §11, applicable subset)

| # | Risk | Mitigation in this sprint |
|---|------|---------------------------|
| R1 | Hook slows tools | Hot-path benchmark; rules YAML cached parsed; minimal regex set |
| R5 | Approval gate locks me out | `AEGIS_BYPASS=1` env override always wins, audited |
| R6 | Hook crash blocks all tool calls | check.mjs `try { decide() } catch { exit 0 }` — fail-OPEN on crash; fail-CLOSED only on confirmed match |
| R8 | Scope creep — turns into Paperclip | Default rules conservative (rm -rf + force push only); per-project rules opt-in |

## Out of scope (deferred to v11-06..08)

- aegis-router (model-tier picker) → v11-06
- aegis-run-logger (Stop hook archive) → v11-07
- aegis-trace-export (PII redaction) → v11-08

## Sprint output

- Skill: `skills/aegis-approval-gate.md`
- Tools: `tools/aegis-approval-gate/{check,grant,list,revoke}.mjs`
- Default rules: `.aegis/brain/gate-rules.yaml` (delivered by install.sh)
- Tests: `tests/aegis-approval-gate-test.sh`
