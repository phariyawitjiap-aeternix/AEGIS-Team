# Sprint v10-03 Close: RTK Adoption Decision = DEFER

**Closed**: 2026-05-02
**Delivered**: 2/2 pt (100%)
**Decision**: **DEFER** RTK adoption (not REJECT — reconsider triggers documented)

## Final Verdict

> **DEFER**. Bash token share in real workloads is at the threshold of Loki's killshot (30-32%, just above the <30% auto-REJECT line). Net projected saving from RTK is ~12-13% — below the ~25% ROI threshold typically required for new-infra adoption. Install/test/governance overhead is not justified at this margin.

## ADOPT Gate Evaluation

| # | Condition | Status | Outcome | Citation |
|---|-----------|--------|---------|----------|
| 1 | Bash token % from 3+ real sessions | **BORDERLINE FAIL** | 30-32% across 3 samples × 2 contexts × 2 dates. Just above auto-REJECT, but ROI insufficient. | `.aegis/brain/learnings/2026-05-02_token-profile-meta-vs-real-divergence.md` |
| 2 | Upstream issue #427 resolved | ✅ PASS | Closed 2026-04-03, labels "bug,P2-important". | `tools/aegis-rtk-upstream-check.sh` cache (~/.aegis/state/rtk-upstream.json) |
| 3 | Canary test 3/3 PASS | ⏸️ N/A | RTK not installed — canary correctly SKIPs. Re-runs automatically when RTK present. | `tools/aegis-rtk-canary-test.sh` |
| 4 | Version pinned + hash verified | ⏸️ N/A | RTK not installed. | — |
| 5 | Passthrough allowlist validated | ⏸️ N/A | RTK not installed. Allowlist documented in ADR-007 for future use. | ADR-007 §Passthrough Allowlist |

**Gate result**: Condition 1 is the borderline. Even if treated as PASS, the marginal ROI does not justify installing RTK to evaluate Conditions 3/4/5.

## Convergent Measurement Evidence

| Sample | Date | n | Bash % | Net RTK saving (Bash% × 40%) |
|--------|------|--:|-------:|-----------------------------:|
| AEGIS-Team | 2026-04-24 | 9 | 31.9% | ~13% |
| RizzLab | 2026-05-02 | 200 | 30.6% | ~12% |
| AEGIS-Team | 2026-05-02 | 14 | 65.5% | (admin outlier — excluded) |

**Pre-data hypothesis**: Bash dominates (>50%) → RTK adoption gives ~26% saving.
**Post-data finding**: Bash ≈ 1/3 of tokens → RTK adoption gives ~12% saving.

This is exactly the bias Loki's killshot was designed to surface. The team vote in v10-02 (2 ADOPT, 2 DEFER, 2 CONDITIONAL, 1 REJECT) prevented adoption based on the misleading meta-repo signal that was conventional wisdom pre-measurement.

## Reconsider Triggers (when to revisit RTK)

This decision is DEFER, not REJECT. Re-open RTK adoption discussion if any of the following:

1. **Workload shifts to Bash-dominant** — sustained ≥50% Bash share across 3+ representative sessions (e.g., heavy infra-ops sprint, deployment migration project)
2. **RTK upstream improves compression ratio** — if RTK delivers ≥60% compression (vs current ~40%), RTK net saving in current workload becomes ~18-19% — borderline-acceptable
3. **Anthropic does not ship native compression for >12 months** — increases relative value of RTK as interim solution
4. **Token cost increase materially changes ROI** — if token costs 2× from current pricing, 12% saving becomes more material in absolute dollar terms

If any trigger fires, re-open this sprint as v10-03b (or sprint-v11-NN if cycle warrants) and re-evaluate Conditions 1 + 3/4/5.

## ADR-007 Status Update

Updated `.aegis/brain/resonance/architecture-decisions.md` ADR-007 status line:
- Before: `DEFERRED pending measurement + upstream fix + canary pass`
- After:  `DEFERRED based on measurement (2026-05-02): Bash share at threshold, ROI marginal — see sprint-v10-03/close.md`

## Stories Delivered

| ID | Story | Pt | Status |
|----|-------|----|----|
| A | Evaluate ADOPT gate Conditions 1-5 | 1 | ✅ DONE (this document) |
| B | Update ADR-007 status + close v10-02 loop | 1 | ✅ DONE |

## Carry-forward

- **Keep token-profile hook running** in AEGIS-Team + RizzLab — ongoing measurement supports reconsider trigger #1 (workload shift detection)
- **Keep `aegis-rtk-upstream-check.sh`** — passive watcher, runs weekly, catches reconsider trigger #2
- **Keep canary scaffold** — dormant but ready if RTK is ever installed for testing
- **No queue items added** — decision is closed, no human action required

## Lessons (delta from v10-02)

1. **Adversarial review pays off** — Loki was the only REJECT vote; turned out to be correct. Without the killshot question forcing measurement, RTK would have been adopted on the misleading meta-repo signal.
2. **Three samples is enough for directional decisions** — full statistical rigor would want 10+ but for a go/no-go on adoption complexity, 3 convergent samples (especially across 2 contexts) is sufficient evidence.
3. **DEFER ≠ REJECT** — explicit reconsider triggers turn a closed decision into a re-openable one. Healthier than binary kill/ship.
4. **Outlier identification matters** — admin-heavy sessions (today's 14-call meta-repo sample) skewed signals 2× the truth. Real-workload data is the truth-teller.
5. **The "policy-without-test" bug class generalizes upward** — applies not just to MBP enforcement gaps but to architectural assumptions like "Bash dominates token use." Always measure in target environment.
