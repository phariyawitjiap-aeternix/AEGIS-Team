# Sprint v10-08 Plan: Hermes L3 — Instinct Refinement Loop

**Status**: SCOPED-DEFERRED · 5pt (planned) · authored 2026-05-06 alongside v10-07 close
**Goal**: Close the Hermes adaptation loop. Track observed-vs-actual outcomes for promoted instincts, refine confidence scores, and demote/retire instincts that consistently disagree with reality. ISO 29110-safe: no LLM-driven rewrites, only deterministic confidence updates from observed data.

## Why DEFERRED

Per [v10-07 close.md](../sprint-v10-07/close.md) §"Blocking discovery for v10-08":

> L3 needs ≥1 promoted instinct + ≥1 use-cycle to refine — both of which require L2 to FIRST produce something to promote.

Today's state (2026-05-06):
- L2 (`mine.mjs`) shipped ✓
- L2 live mine on real `decision-audit.log` (57 judgment / 122 total entries) → **0 clusters at default thresholds**
- 0 clusters → 0 promoted candidates → 0 promoted instincts → nothing for L3 to refine
- Test fixtures aside (which the default exclusion correctly drops), real-world judgment fallbacks are too few and too varied to mine yet

**Concrete unblock conditions** — open v10-08 when ANY of these is true:

1. **Data accumulation:** `decision-audit.log` reaches ≥ 200 real (non-fixture) judgment entries spanning ≥ 6 months of usage, AND `mine.mjs` produces ≥ 3 clusters at default thresholds. (At current usage cadence: roughly 2026-Q4 / 2027-Q1.)
2. **Human-seeded path:** Operator manually authors ≥ 1 instinct YAML in `.aegis/brain/instincts/`, uses it across ≥ 3 distinct sessions (each session calling `aegis-instinct-record-outcome.sh` — built in this sprint when it opens), AND wants the auto-refinement loop active.
3. **Different framework adopts AEGIS:** A separate project bootstraps AEGIS via `install.sh`, accumulates decisions there, and L2/L3 want to compare-and-merge across the multi-tenant registry (sprint-v11-09).

If none of these come up, v10-08 stays parked indefinitely — that's correct, not a failure.

## Scope (when opened)

| Story | Pt | What |
|---|---:|---|
| A | 2 | `aegis-instinct-record-outcome.sh` — call from agent flow when an instinct fires; records `{instinct_id, fired_at, predicted_answer, actual_answer, agreement: bool}` to `.aegis/brain/state/instinct-outcomes.jsonl` |
| B | 2 | `aegis-instinct-refine.mjs` — read outcomes, update each instinct's `observed_confidence` and `agreement_rate`; demote if rate < 0.5 over ≥ 5 firings |
| C | 1 | Tests + integration with v10-09 instinct-promote (refinement re-runs after each new outcome) |

## Schema (planned)

```jsonl
// .aegis/brain/state/instinct-outcomes.jsonl
{"instinct_id":"abc123","fired_at":"2026-XX-XX","predicted_answer":"yes","actual_answer":"no","agreement":false,"context":{"sprint":"v13-01","question_norm":"open sprint <sprint> next?"}}
```

Refinement output (additive to `.aegis/brain/instincts/<id>.yaml`):

```yaml
# Existing fields from v10-07 propose:
status: promoted
trigger_pattern: "..."
recommendation: "..."
confidence: 0.86          # original, set at promotion
# v10-08 additions:
firings: 7
agreements: 5
disagreements: 2
agreement_rate: 0.714
observed_confidence: 0.71  # weighted update from agreements + original confidence
last_refined_at: "2026-XX-XX"
status_history:
  - { ts: "2026-XX-XX", from: pending, to: promoted }
  - { ts: "2026-XX-XX", from: promoted, to: demoted, reason: "agreement_rate 0.4 < 0.5 over 5 firings" }
```

## Acceptance criteria (when opened)

- [ ] `aegis-instinct-record-outcome.sh` writes one valid JSONL line per call
- [ ] `aegis-instinct-refine.mjs` updates each instinct's stats deterministically (idempotent re-run = same output)
- [ ] Demotion threshold honored: `agreement_rate < 0.5 AND firings ≥ 5` → status flips to `demoted`
- [ ] Tests cover: happy path (agree), disagree path, threshold flip, idempotent refine, missing outcomes-file (graceful)
- [ ] Tests: ≥ 8 assertions
- [ ] No LLM call anywhere in the loop (deterministic refinement only)
- [ ] Integration: v10-09 `aegis-instinct-promote.sh` wires `--with-outcome-tracking` flag that ensures `observed_confidence` field exists post-promote

## Out of scope (this sprint, when opened)

- LLM-driven instinct rewriting (Hermes does this; AEGIS rejects it for ISO 29110 audit-trail preservation)
- Automatic re-mining when confidence falls (operator decides via `mine.mjs --re-cluster <id>`)
- Cross-project refinement aggregation (v11-09 multi-tenant could surface this later, not L3's job)

## Open questions (deferred until kickoff)

1. Q: Demotion threshold sensitivity — 0.5 hard cutoff is suspicious. Better: Bayesian confidence with credible interval on `agreement_rate`?
2. Q: Where to call `record-outcome.sh` from — explicit at end of every Captain America synthesis? Or a PostToolUse hook that auto-records on Agent dispatch?
3. Q: Outcome JSONL retention — keep forever, or archive after demote like `.aegis/brain/runs/`?

## Why this plan exists despite being deferred

Writing the v10-08 plan now (rather than waiting for unblock) preserves design intent. Three months from now, when real decision-audit data accumulates, the L3 implementer can:
- Read this plan to understand the original reasoning
- Confirm or revise based on what L2's mine output looks like at scale
- Avoid redesigning from scratch under pressure

This is the same discipline as v10-07 SCOPED status before its open.

## References

- v10-07 close.md — pattern miner shipped + honest null-result rationale
- `project_hermes_adoption_pattern` memory — L1/L2/L3 mapping
- v10-09 `aegis-instinct-promote.sh` — feeds promoted instincts into the queue this sprint will consume
- AEGIS-Plus Mega Plan v1.1 — terminal-only / file-as-contract / ISO-29110-safe principles inherited
