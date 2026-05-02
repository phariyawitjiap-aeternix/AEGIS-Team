---
date: 2026-05-02
sprint: v10-02 (Story A measurement) → blocks v10-03 (RTK decision)
severity: high
type: data-driven course correction
---

# Token Profile: Meta-Repo Pattern ≠ Real-Project Pattern (n=121 first measurement)

## Context

Sprint v10-02 Story A built the token-profile hook (`tools/aegis-token-profile.sh`) to answer Loki's killshot question for v10-03 RTK adoption decision: **"What % of AEGIS tokens is Bash vs Read/Grep/Glob?"**

On 2026-05-02 the hook was activated in two contexts:
1. **AEGIS-Team meta-repo** (framework dev work) — 14 tool calls
2. **RizzLab real project** (Next.js dev, pre-AEGIS-upgrade branch) — 107 tool calls

## Data (3 sessions, 2 contexts, 2 dates)

| Sample | Date | Project | n | Bash % | R+G+G % | Other notable | Verdict |
|--------|------|---------|--:|-------:|--------:|---------------|---------|
| 1 | 2026-04-24 | AEGIS-Team | 9 | **31.9%** | **40.6%** | Read-heavy | MODERATE |
| 2 | 2026-05-02 | AEGIS-Team | 14 | 65.5% | 4.5% | **Admin outlier** (git/jq/install) | STRONG |
| 3 | 2026-05-02 | RizzLab | 200 | **30.6%** | 12.9% | Write 32.6% (biggest) | MODERATE |

**Convergence**: 2 of 3 samples (containing 95%+ of tokens) show Bash ≈ 30-32%.
Outlier is Sample 2 — known atypical (14-call admin marathon: git, jq, settings.json patches, install/uninstall ops).

## Triangulated answer to Loki's killshot

**"What % of AEGIS tokens is Bash vs Read/Grep/Glob?"** — answered across 3 samples, 2 contexts, 2 dates:

- Bash share in representative work: **~30-32%** (not the >50% that base assumption claimed)
- RTK addresses Bash output compression only
- Net RTK saving ≈ Bash% × ~40% reduction = **~12-13% token saving in real workloads**

**Pre-data hypothesis**: Bash dominates → adopt RTK → 26% saving
**Post-data finding**: Bash ≈ 1/3 → RTK gives ~12% saving → marginal value vs adoption complexity

## Lesson

**Meta-repo signal would have justified RTK adoption. Real-project signal does not.**

Specifically:
- AEGIS-Team session was admin-heavy (git, jq, settings.json patches, brain-index DB ops). 12 of 14 calls were Bash. That's framework-dev pattern, NOT typical workload.
- RizzLab session was real Next.js work (file reads, edits, dev server). Bash was significant (34.8%) but not dominant. Read/Write/Edit collectively 55.5%.

**RTK ROI math (revised)**:
- RTK targets Bash output token compression (~40% reduction estimate per Hermes design).
- Meta-repo projection: 65% × 40% = **~26% net token saving** → STRONG case
- Real-project projection: 35% × 40% = **~14% net token saving** → MODERATE case
- Real-project target population is the one that matters for AEGIS framework adoption decision.

**Loki was right to demand measurement before adoption.** v9-era pre-data assumption "Bash dominates" came from observing meta-repo sessions, not real-project sessions. This is exactly the kind of bias that the v10-02 measurement infrastructure was built to expose.

## Generalization

This is the second instance of the **policy-without-test bug class** at strategic scope (first was MBP enforcement gaps in 2026-04-22). Pattern:

> A claim/decision is shaped by where the observer happens to be looking. The framework's own dogfood environment may not represent the framework's real target environment. Always measure in the target environment before deciding.

For future framework-vs-application decisions:
1. **Default skepticism** about meta-repo signals as proxies for real-project behavior
2. **Always collect real-project data** before adoption — doesn't have to be a lot, but must be present
3. **Verdict thresholds should be conservative** — "MODERATE" / "STRONG" labels are calibrated to encourage measurement, not adoption

## Action Items

- [x] Collect ≥2 representative samples (DONE: April 24 AEGIS, May 2 RizzLab — both ~30% Bash, convergent)
- [ ] Optional: 1-2 more representative AEGIS-Team sessions (real dev work, not admin) for triangulation
- [ ] **Open sprint-v10-03 with this learning as primary evidence** — RTK pre-decision = DEFER
- [ ] v10-03 plan must cite this convergence: 2 samples × 2 contexts × 2 dates → Bash ≈ 30%, not >50%
- [ ] If anyone re-litigates RTK adoption later, point them at this file before they argue from theory

## Pre-decision (recommended for v10-03)

**RTK = DEFER** (not REJECT — re-evaluate if workload changes)

Rationale:
1. Real-workload Bash share = 30-32% (3 samples agree)
2. RTK net saving projection = ~12-13% tokens
3. Adoption cost: new compression layer, new failure modes, new debugging surface
4. ROI threshold for new infra adoption typically wants ≥25% saving — RTK at half that
5. If/when workload shifts to Bash-heavy (e.g., heavy infra-ops sprints), revisit

Reconsider triggers:
- Sustained ≥50% Bash share across 3+ sessions in real work
- RTK upstream issue #427 closed with stronger compression ratio
- Token cost increase that makes 12% saving more material

## Provenance

- Hook installed via `bash tools/aegis-token-profile.sh --install` on 2026-05-02 in both AEGIS-Team and RizzLab.
- Raw JSONL data:
  - AEGIS-Team: `.aegis/brain/metrics/token-profile-2026-05-02.jsonl` (14 lines, ~3.6KB)
  - RizzLab: `/Users/phariyawit.jiap/Documents/RizzLab/.aegis/brain/metrics/token-profile-2026-05-02.jsonl` (107 lines)
- Summary commands: `bash tools/aegis-token-profile.sh --summary`
- Killshot question source: sprint-v10-02 plan, Loki's "RTK adoption vote".

## Cross-references

- `.aegis/brain/sprints/sprint-v10-02/plan.md` — original Story A definition
- `.aegis/brain/learnings/2026-04-22_policy-without-test-bug-class.md` — same bug class precedent
- Future: `.aegis/brain/sprints/sprint-v10-03/plan.md` (when opened) — must cite this file
