# Sprint v11-06 Close: aegis-router

**Status**: CLOSED (100%) · **Points**: 8/8

## Stories shipped

| ID | Story | Pt | Outcome |
|----|-------|----|---------|
| A | policy.yaml schema + scaffolding | 1 | ✅ 6 default rules + fallthrough sonnet |
| B | route.mjs CLI | 4 | ✅ persona / keyword / length / override matchers |
| C | SKILL.md + 4 worked examples | 2 | ✅ |
| D | tests + audit log + --json | 1 | ✅ 15-assertion regression |

## Acceptance criteria — all green

- [x] Routing decision logged with model + reason + rule + override flag
- [x] `--model X` override always wins
- [x] Per-persona rules (loki/iron-man → opus, spider-man → sonnet)
- [x] Per-keyword rules ("design" → opus, short "list" → haiku)
- [x] First-match-wins ordering verified
- [x] `--json` output valid and tooling-friendly
- [x] 6 default rules (≥4 required)

## Test results

```
tests/aegis-router-test.sh             — 15/15 pass
tests/aegis-install-v11-delivery-test  — 40/40 pass (was 37 — added 3 v11-06 checks)
all 7 prior v11 suites — green (regression)
```

## Roadmap

v11 Phase-2: 8/32 → 16/32pt (50%). Next: v11-07 aegis-run-logger.
