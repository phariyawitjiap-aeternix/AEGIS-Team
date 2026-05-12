<!-- version: 1.0.0 -->
<!-- Last updated: 2026-05-12 -->

# v14-04 Goal Pattern — Measurement Methodology

> Calendar-time activity. Cannot run in one execution turn — requires real LLM calls + multi-session orchestration. Documented here so the measurement can be executed by a future session-owner without re-doing the design work.

## Why a methodology doc instead of a measurement run

S14-04-02 was budgeted 5pt. The honest accounting:
- ~1pt — designing the methodology (this doc)
- ~4pt — running 10 actual sessions across calendar days (NOT this turn)

This sprint shipped the methodology + POC tooling (S14-04-01). The actual measurement is **External Access work** (real LLM judge calls) and is **gated separately** per the MBP rule "External Access stays gated even after 'do them all'".

## Hypothesis under test

> The Hermes-style Ralph-loop judge pattern, when applied to AEGIS sprint orchestration, reduces session-end overhead without introducing >10% false-positive completion claims, at a cost <$0.10 per measurement session.

## POC tooling (already shipped in S14-04-01)

- `tools/aegis-goal/judge.sh` — heuristic stub (free) + `--mode llm` placeholder
- `tools/aegis-goal/state.sh` — per-session YAML state lifecycle
- `.claude/commands/aegis-goal.md` — slash command spec
- Registry entry — `aegis-goal` in `tools/aegis-commands/registry.mjs`

The tooling works end-to-end with the heuristic judge (14/14 tests GREEN in `tests/aegis-goal-test.sh`). What's not wired is the real LLM call.

## Pre-flight: wiring the real judge

Before the measurement starts, edit `tools/aegis-goal/judge.sh:llm_judge()` to call Claude through routing/policy.yaml. The integration sketch:

```bash
llm_judge() {
    local goal="$1"
    local response="$2"

    # Pull Haiku-tier endpoint from routing policy
    local model_endpoint
    model_endpoint=$(yq '.tiers.haiku.endpoint' .aegis/brain/routing/policy.yaml)

    local prompt
    prompt=$(cat <<PROMPT
You are a judge. Determine if the following response achieves the goal.
Goal: ${goal}
Response: ${response}
Answer in single-line JSON: {"verdict":"yes|no|unclear","reason":"<one-line>"}
PROMPT
)
    # Make the API call (curl or claude CLI). Parse + return JSON.
    # Record cost + latency to .aegis/brain/state/goal-${session}-judge-log.jsonl
    ...
}
```

Critical safety: record EVERY judge call's cost+latency to a JSONL log so the budget cap can fire automatically.

## Experimental protocol

### Session set design

- **Control arm (n=5)**: existing manual orchestration. Sprint-end retro via `/aegis-retro` driven by Claude assessing-its-own-output.
- **Experimental arm (n=5)**: same task profile, but driven by `/aegis-goal "<sprint goal>"` + judge-loop. Heuristic-mode judge first (free), then a single LLM-mode session to compare verdicts head-to-head.

### Task profile (same across both arms)

Pick a sprint with **measurable completion**: e.g., "ship sprint v14-05 — 3 stories with tests, all GREEN". The completion criterion is unambiguous (test results).

### Metrics recorded (per session)

| Metric | How recorded | Decision criterion |
|--------|--------------|---------------------|
| Judge cost per session | Sum of `cost_usd` from `goal-${session}-judge-log.jsonl` | < $0.10 → PASS |
| Latency per judge call | Mean `latency_ms` | < 2000ms → PASS |
| False-positive rate | (judge=yes ∧ work-actually-incomplete) / total yes verdicts | < 10% → PASS |
| User-interrupt rate | (sessions terminated by user message before status=achieved) / total | < 30% → PASS |
| Mean turns to achievement | turn_count at status=achieved | informational |
| Budget exhaustion rate | sessions ending in status=exhausted / total | < 20% → PASS |

### Pre-committed kill switches

- **$10 hard cap** across all 10 measurement sessions. If `sum(cost_usd)` exceeds, abort + log.
- **Single-session false-positive cap**: if judge=yes but work-incomplete is observed in 2 of the first 5 LLM sessions, abort + log.
- **Latency cap**: if any judge call takes >5000ms, abort + investigate (likely model misconfiguration).

## Promote / archive decision tree

After measurement completes:

```
              ┌──────────────────────────────────┐
              │ All 4 PASS gates met (cost,     │
              │ FP rate, latency, interrupt)?   │
              └──────────────────────────────────┘
                            │
              ┌─────────────┴─────────────┐
              │                           │
            YES                         NO
              │                           │
              ▼                           ▼
   ┌────────────────────┐    ┌────────────────────┐
   │ PROMOTE — log a     │    │ ARCHIVE — log a    │
   │ framework decision  │    │ framework decision │
   │ "/aegis-goal is     │    │ "/aegis-goal POC   │
   │ canonical for v15+" │    │ rejected for       │
   │ + add to            │    │ reason X" + remove │
   │ aegis-retro chain   │    │ from registry +    │
   │ as opt-in flag      │    │ from canonical .md │
   └────────────────────┘    └────────────────────┘
```

## Decision log entries (to be written at measurement-time)

```
D-XXX: Open measurement campaign for /aegis-goal POC
  source: framework
  source_id: v14-04-goal-pattern-methodology
  confidence: <0.5..0.9>
  answer: opened measurement of N=5 control + N=5 experimental sessions per
          .aegis/brain/learnings/v14-04-goal-pattern-methodology.md

D-XXX: Close measurement — promote OR archive
  source: judgment
  source_id: v14-04-measurement-results-<date>
  reasoning: required (LLM judgments are judgment-source)
  answer: <PROMOTE|ARCHIVE> with measured numbers
```

## Risk: judge model availability

This methodology assumes a Haiku-tier endpoint is reachable via routing policy at measurement time. Validate before kicking off:

```bash
# Smoke test before measurement
echo '{"goal":"test","response":"done"}' | bash tools/aegis-goal/judge.sh --goal "x" --mode llm
# Expect: {"verdict":"yes|no|unclear","mode":"llm","cost_usd":0.0X,"latency_ms":XXX}
# If error → fix wiring first, then measure
```

## Out-of-scope (for this methodology)

- Multi-user sessions (AEGIS is single-user today; no concurrent-session bias to worry about)
- Cross-session goal handoff (each measurement session is independent)
- Non-English goals (all measurement sessions use English-shaped goal text; Thai test deferred to later)
- Comparison against Hermes's own /goal (out of repo; would require parallel Hermes install)

## Carry-forward for whoever runs this

When ready to run the measurement:
1. Read this doc end-to-end
2. Wire the real judge (per "Pre-flight" section)
3. Smoke-test the LLM mode
4. Run 5 control sessions on a low-stakes sprint
5. Run 5 experimental sessions on the same task profile
6. Compare metrics against decision criteria
7. Log D-XXX decisions per the entry sketches
8. PROMOTE or ARCHIVE per the decision tree
9. Update `tools/aegis-commands/registry.mjs` if archiving (remove aegis-goal)
10. Update v14-04 close.md with measurement outcomes

The POC infrastructure ships today. The campaign happens when the operator is ready to spend $10 on LLM calls.
