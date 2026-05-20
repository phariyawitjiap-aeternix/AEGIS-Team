# Sprint v15-19 Kanban

## DONE

- [x] **A** — `tools/aegis-coverage-screen.sh` (1pt)
  - Subcommands: `detect / screen / show / ack / list-stacks`
  - 25 known stack IDs from web-next (100%) to unreal (50%) to unknown (0%)
  - Soft gate: process always exits 0 (verified by T11 + T11b)
  - Plain Thai + English warning block (per [[plain-thai-voice]])
  - Writes `.aegis/brain/state/coverage.json` schema `aegis-coverage-v1`
- [x] **B** — `skills/aegis-coverage-screen.md` + wired into commands (1pt)
  - Skill ships at all profiles (`profile: minimal|standard|full`)
  - `/super-spec` gains Phase 0 (before Phase 1 Q&A)
  - `/aegis-start` Step 2.3 re-surfaces warning if unack'd
  - `install.sh` ships the tool via `runtime_helpers` (also auto-shipped by `install-remote.sh` glob)
  - CLAUDE.md gains "Coverage Contract (v15-19)" section
- [x] **C** — `tests/aegis-coverage-screen-test.sh` × 12 (1pt)
  - T1-T7 detection across 7 stacks (web-next, unity, xcode-ios, godot-cli, godot-editor, terraform, rust, empty→unknown)
  - T8: Unity screen → 60% + 4 gaps verified in JSON
  - T9: web-next → 100% + 0 gaps verified
  - T10: ack flips ack=true
  - T11+T11b: soft gate (exit 0) for low-coverage stacks
  - T12: idempotency (re-screen produces same JSON shape)
  - **All 14 tests pass green standalone**
- [x] **D** — Retroactive Contra-Thai coverage screen (1pt)
  - Wrote `~/Documents/Contra-Thai/.aegis/brain/state/coverage.json` (60%, 4 gaps, ack=false)
  - Wrote `~/Documents/Contra-Thai/_aegis-output/reviews/2026-05-21-coverage-screen-retroactive.md`
  - Demonstrates "what AEGIS should have shown on 2026-05-18"

## Stories table

| Story | Type | Points | Status |
|-------|------|--------|--------|
| A — coverage-screen tool | new tool | 1 | DONE |
| B — wire into commands + skill | new skill + integration | 1 | DONE |
| C — tests × 12 | testing | 1 | DONE |
| D — Contra-Thai retroactive | demo + audit | 1 | DONE |

**Total**: 4/4 done.

## Closes

- Bug class: silent low-coverage projects (Contra-Thai pattern, 2026-05-18..20)
- [[feedback_aegis_coverage_contract]] — moves rule from memory → enforced code
- [[policy-without-test]] — coverage contract previously had no enforcement

## Establishes pattern

- Tool-boundary screen at intake = day-1 honesty about what AEGIS can/can't drive
- Soft-gate warning + persistent re-surface = forcing function without friction
- Future projects: silent coverage gaps will not survive `/super-spec`

## Carry / follow-ups

- v15-20 candidate: if soft gate proves ignored in practice (Loki future finding), upgrade to hard ack
- v15-21 candidate: split GAP_CRED into OAuth-browser-flow vs raw-API-key sub-types
- v15-22 candidate: glob-discover `runtime_helpers` from `tools/aegis-*.sh` (kill the 2nd manifest-drift surface — install.sh hand-list is parallel to the skill drift we killed in v15-18A)
- v15-23 candidate: extend Sprint close DoD to fail closure if coverage<1.0 AND no build-artifact freshness signal
