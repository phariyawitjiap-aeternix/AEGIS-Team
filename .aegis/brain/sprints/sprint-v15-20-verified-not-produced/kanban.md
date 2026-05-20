# Sprint v15-20 Kanban

## DONE

- [x] **A** — F-C: Sub-agent return tagging convention (2pt)
  - New `tools/aegis-return-validator.sh` (`check`/`summary`/`help` subcommands)
  - New `skills/aegis-return-format.md` — single source of truth for the rule + examples
  - `CLAUDE_agents.md` gains "Return Format (v15-20)" section pointing to the skill
  - Tests: `aegis-return-format-test.sh` × 7 — clean / Contra-Thai-pattern / mixed / prose-ignored / summary schema / file input / soft gate
- [x] **B** — F-B: Sprint-close playtest gate (2pt)
  - New `tools/aegis-sprint-close-gate.sh` (`check`/`report` subcommands)
  - Reads `coverage.json` + per-story `_aegis-output/playtests/S<NN>-<NN>.md` (keys: `verified_by`, `pass`, `date`)
  - Silent for coverage=100%; warns + lists missing/failing for coverage<100%
  - `/aegis-sprint close` Step 3.5 invokes the gate before final close report
  - Tests: `aegis-sprint-close-gate-test.sh` × 7
  - Validated retroactively against Contra-Thai: 7/7 DONE stories flagged as missing playtest evidence
- [x] **C** — F-E: Research probe-gate (1pt)
  - New `tools/aegis-research-probe.sh` (`scan`/`apply`/`check-tags` subcommands)
  - Probes URLs via HEAD/OPTIONS; tags `[PROBED ✓ HTTP <code>]` / `[PROBED ✗ HTTP <code>]` / `[UNPROBED]`
  - Skips placeholder/example URLs
  - Idempotent (second `apply` is byte-identical)
  - Beast persona gains "URL Probe-Gate (v15-20, F-E)" section
  - Tests: `aegis-research-probe-test.sh` × 7

## Stories table

| Story | Type | Points | Status |
|-------|------|--------|--------|
| A — sub-agent tagging | persona + helper | 2 | DONE |
| B — sprint-close gate | new tool + integration | 2 | DONE |
| C — research probe | new tool + persona update | 1 | DONE |

**Total**: 5/5 done. New tests: 21 (7+7+7) standalone, all green.

## Closes (per Contra-Thai research report 2026-05-20)

- ✅ **F-B** — sprint-close playtest gate (was deferred in v15-19 as v15-23 candidate; pulled forward)
- ✅ **F-C** — sub-agent return tagging convention
- ✅ **F-E** — research-doc URL probe gate
- ⏭️ F-D (Unity asmdef cycle check) — skipped: Unity-only, narrow audience; covered transitively by F-A (v15-19) + F-B

## Together with v15-19

| Finding | Status |
|---|---|
| F-A — Project-class declaration at init | ✅ v15-19 |
| F-B — Playtest-result requirement at sprint close | ✅ v15-20 |
| F-C — Sub-agent return tagging | ✅ v15-20 |
| F-D — Unity asmdef cycle check | ⏭️ skipped |
| F-E — Research-doc URL probe gate | ✅ v15-20 |

**4/5 of the Contra-Thai research report's framework gaps closed across v15-19 + v15-20.**

## Follow-ups (v15-21+ candidates)

- Hook-level enforcement: pre-tool-use guard that auto-runs the validator on every Task agent return + emits `permissionDecision: deny` if untagged ratio is too high (hard gate)
- Playtest result auto-template: `/aegis-sprint plan` could pre-create `_aegis-output/playtests/S<NN>-<NN>.md` skeletons per story so the human just fills in
- Probe-gate auto-fire on `_aegis-output/research/*.md` writes via PostToolUse hook (currently manual: Beast runs it)
