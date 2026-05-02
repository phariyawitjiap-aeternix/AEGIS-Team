# Sprint v10-03 Plan: RTK Adoption Decision

**Sprint Goal**: Evaluate the 5 ADOPT gate conditions defined in ADR-007 with the measurement data collected by sprint-v10-02. Make a formal go/no-go decision on RTK (Rust Token Killer) adoption for AEGIS.
**Points**: 2pt total (1+1)
**Duration**: 1 session (2026-05-02)
**Branch**: bundled with `feat/v10-06-searchable-brain` (PR #88) for session efficiency

## Strategic Context

Sprint v10-02 deferred RTK adoption pending measurement. The killshot question (Loki):

> **"What % of AEGIS tokens is Bash vs Read/Grep/Glob?"** If Bash <30%, RTK adds complexity for marginal gain.

ADR-007 codified 5 ADOPT gate conditions. v10-03 evaluates them.

## Stories

| ID | Story | Pt | Type |
|----|-------|----|------|
| A | Evaluate ADOPT gate Conditions 1-5 against collected data | 1 | DECIDE |
| B | Update ADR-007 status + close v10-02→v10-03 measurement loop | 1 | DOC |

### Story A — Evaluate 5 ADOPT gate conditions

| # | Condition | Status | Evidence |
|---|-----------|--------|----------|
| 1 | Bash token % from 3+ real sessions | **BORDERLINE** | 30-32% across 3 samples — just above auto-REJECT threshold |
| 2 | Upstream issue #427 resolved | ✅ PASS | Closed 2026-04-03 (verified by `aegis-rtk-upstream-check.sh`) |
| 3 | Canary test 3/3 PASS | ⏸️ PENDING | RTK not installed — canary correctly SKIPs |
| 4 | Version pinned + hash verified | ⏸️ PENDING | RTK not installed |
| 5 | Passthrough allowlist validated | ⏸️ PENDING | RTK not installed |

**Conditions 3/4/5 are install-gated** — they can only be evaluated by installing RTK. Condition 1 is the gate to that gate.

### Story B — ADR-007 status update + carry-forward

- Update ADR-007 in `.aegis/brain/resonance/architecture-decisions.md` with measurement-based status
- Document reconsider triggers
- Close v10-02 → v10-03 measurement loop in handoffs/retros
- Keep token-profile hook running in both contexts (already installed in AEGIS-Team + RizzLab)

## Out of scope

- **Installing RTK** — Condition 1 is borderline; install overhead not justified for ~12% projected saving
- **Anthropic native compression watch** — handled separately if/when Anthropic ships server-side compaction
- **RizzLab AEGIS upgrade** — separate concern, not gated by this decision

## Pre-decision (before Story A formal evaluation)

Per `.aegis/brain/learnings/2026-05-02_token-profile-meta-vs-real-divergence.md`:
- **Convergent data**: 3 samples × 2 contexts × 2 dates show Bash ≈ 30-32%
- **RTK net saving projection**: ~12-13% in real workloads (vs 26% claimed pre-data)
- **ROI threshold for new infra**: typically ≥25% for adoption to be worth complexity
- **Direction**: DEFER (not REJECT — re-evaluate if workload shifts)

## Success Criteria

- [ ] Each of 5 ADOPT gate conditions formally evaluated with cited evidence
- [ ] Decision recorded as DEFER with explicit reconsider triggers
- [ ] ADR-007 status line updated to reflect measurement-based outcome
- [ ] Sprint added to roadmap.md
- [ ] All measurement infrastructure (hook, canary scaffold, upstream watcher) kept active for re-evaluation
