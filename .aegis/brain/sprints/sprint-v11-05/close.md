# Sprint v11-05 Close: aegis-approval-gate

**Status**: CLOSED (100%) · **Points**: 8/8
**Branch**: `feat/v11-05-aegis-approval-gate`
**v11 Phase-2 first sprint** — gate opened 2026-05-05 with 2/3 signals (audit-query + run-replay).

## Stories shipped

| ID | Story | Pt | Outcome |
|----|-------|----|---------|
| A | rules schema + scaffolding | 1 | ✅ `.aegis/brain/gate-rules.yaml` with 8 default rules |
| B | check.mjs PreToolUse hook | 3 | ✅ p95 = 134ms (<200ms) |
| C | grant/list/revoke CLIs | 2 | ✅ TTL parsing, scope formats, --json, --all-expired |
| D | tests + AEGIS_BYPASS + audit | 2 | ✅ 21-assertion regression |

## Acceptance criteria — all green

- [x] rm -rf blocked without approval marker
- [x] Approval marker (rule:rm-rf scope) grants permission until expires_at
- [x] Expired markers ignored
- [x] Non-matching tool calls (Edit/Write/Read/innocuous Bash) pass through
- [x] AEGIS_BYPASS=1 env override works + writes audit-log entry
- [x] Hook latency p95 <200ms (measured 134ms)
- [x] Existing AEGIS skills regression-clean

## Test results

```
tests/aegis-approval-gate-test.sh         — 21/21 pass
tests/aegis-install-v11-delivery-test.sh  — 37/37 pass (was 29 — added 8 v11-05 checks)
tests/aegis-live-tail-test.sh             — 27/27 (regression)
tests/aegis-activity-logger-test.sh       — 17/17 (regression)
tests/aegis-issue-thread-test.sh          — 15/15 (regression)
tests/aegis-parallel-dispatch-test.sh     — 16/16 (regression)
tests/aegis-plus-pilot-test.sh            — 18/18 (regression)
tests/aegis-version-consistency-test.sh   —  8/8  (regression)
                                  total — 159/159
```

## Hook wiring

`.claude/settings.json` PreToolUse Bash matcher now chains:
1. `bash run-with-flags.sh guard-bash guard-bash.sh` (existing)
2. `node tools/aegis-approval-gate/check.mjs` (v11-05 — new)

Both run on every Bash tool call. check.mjs fail-OPENs on internal error (R6 mitigation), so a crash here can never block legitimate work — only confirmed pattern matches block.

## install.sh delivery

- Added `aegis-approval-gate` to `tool_packages` array
- Added `aegis-approval-gate` to `standard_skills` array
- New brain-config seed step ships `.aegis/brain/gate-rules.yaml` (preserved on upgrade if user customized)

## Risks observed during sprint

| Risk | Mitigation result |
|---|---|
| R1 hook latency | ✅ 134ms p95 over 30 invocations |
| R5 lockout | ✅ AEGIS_BYPASS=1 always wins, audited |
| R6 hook crash blocks tools | ✅ try/catch wraps everything → fail-OPEN |
| R8 scope creep | ✅ Default rule set kept conservative (8 rules); per-project override supported |

## Deviations from Mega Plan §7.1

1. **Single check.mjs hook instead of separate gate-check + approval-check files.** Plan implied a split; consolidating made the hot path faster.
2. **Scope format extended.** Plan listed `["bash:rm -rf", "bash:git push --force"]`. Sprint added `rule:<name>` form (more precise) and `*` wildcard. Original `bash:<substring>` form still works.
3. **Audit log location.** Plan said scope-implicit; sprint pinned to `.aegis/brain/logs/approval-audit.log` for grep-ability.
4. **Regex case-insensitivity.** JS RegExp doesn't support `(?i)` inline flag, so `drop-table` rule uses character classes (`[Dd][Rr][Oo][Pp]`) instead.

## v11 Phase-2 progress

| Sprint | Pt | Status |
|---|---:|---|
| v11-05 aegis-approval-gate | 8 | **CLOSED (100%)** |
| v11-06 aegis-router | 8 | next |
| v11-07 aegis-run-logger | 8 | planned |
| v11-08 aegis-trace-export | 8 | planned |
| **v11 Phase-2** | **32** | **8/32 (25%)** |

## Pilot impact

kam-tong-ham can re-upgrade to pick up:
- The 5 new tool files under `tools/aegis-approval-gate/`
- New skill `skills/aegis-approval-gate.md`
- Default `.aegis/brain/gate-rules.yaml`
- Wired check.mjs PreToolUse hook in settings.json

```bash
bash ~/Documents/AEGIS-Team/install.sh --upgrade --target-dir ~/Documents/kam-tong-ham --project-name 'kam-tong-ham' --profile standard
```

After this, attempting `rm -rf` from Claude Code will block with a helpful message + grant instructions.
