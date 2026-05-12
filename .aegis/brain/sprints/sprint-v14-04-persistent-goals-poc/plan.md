<!-- version: 1.0.0 -->
<!-- Last updated: 2026-05-12 -->

# Sprint v14-04 Plan — Persistent Goals POC

**Goal**: Ship POC tooling for Hermes-style Ralph-loop persistent goals. **Tooling only** — measurement campaign deferred (requires multi-session calendar time).

**Capacity**: 10pt (2 stories)
**Status**: ACTIVE (opened 2026-05-12)
**Series**: [v14-series-plan.md](../v14-series-plan.md)

## Scope clarification

The v14-series-plan gated this sprint on External Access (real judge-model calls). Per the explicit "non-stop" go from the human, this sprint ships:
- ✅ **POC tooling infrastructure** (this sprint, S14-04-01) — judge.sh + state.sh + slash command, with HEURISTIC judge stub
- ⚠️ **Measurement campaign** (S14-04-02 ships methodology doc; **actual sessions deferred** to a future calendar-time activity since they require real LLM calls + multi-session orchestration outside one turn's capacity)

This is honest scope: tooling is reversible (deletable). Measurement campaign + real-judge integration is the External Access gate that opens at user-initiated time, not implied by a "non-stop" batch.

## Stories

| ID | Title | Points | Hermes source |
|----|-------|--------|---------------|
| S14-04-01 | Judge-loop POC tooling (heuristic stub) | 5 | Hermes `/goal` Ralph-loop |
| S14-04-02 | Measurement methodology document | 5 | (none — AEGIS-specific governance) |

## Acceptance criteria

### S14-04-01
- [ ] `tools/aegis-goal/judge.sh` — heuristic judge (yes/no/unclear) with pluggable real-LLM call
- [ ] `tools/aegis-goal/state.sh` — load/save per-session YAML state at `.aegis/brain/state/goal-<session>.yaml`
- [ ] `.claude/commands/aegis-goal.md` slash command spec with `<text>|pause|resume|clear|status`
- [ ] Add `aegis-goal` to `tools/aegis-commands/registry.mjs` (16 commands)
- [ ] Update registry test to expect 16
- [ ] 20-turn budget enforced
- [ ] Stop on: judge=yes / user message / budget exhausted / clear
- [ ] Test: state lifecycle, judge stub, budget enforcement

### S14-04-02
- [ ] `.aegis/brain/learnings/v14-04-goal-pattern-methodology.md` — measurement plan
- [ ] Specifies: control vs experimental session protocol, what to record, decision criteria, budget cap, kill switch
- [ ] References the real LLM cost ($0.10/session target, <10% false-positive, <30% user-interrupt)
- [ ] Documents how to wire real judge into `judge.sh` when measurement runs
