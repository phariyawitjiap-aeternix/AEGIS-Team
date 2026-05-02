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

## Data

| Context | Bash % | Read % | Edit % | Write % | Agent % | n | Verdict |
|---------|-------:|-------:|-------:|--------:|--------:|--:|---------|
| AEGIS-Team (meta) | **65.5%** | 4.5% | 30.0% | — | — | 14 | "STRONG value" |
| RizzLab (real) | **34.8%** | 26.1% | 12.0% | 17.4% | 9.5% | 107 | "MODERATE value, measure more" |
| **Δ** | **−30.7pp** | +21.6pp | −18.0pp | new | new | — | flipped |

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

- [ ] Continue collecting RizzLab data ≥2 more sessions of real work (debug, code review, implementation — varied workload types)
- [ ] Continue collecting AEGIS-Team data ≥2 more sessions of real dev work (not admin)
- [ ] Open sprint-v10-03 only after both contexts have ≥3 sessions of representative data
- [ ] v10-03 should explicitly weight real-project signal > meta-repo signal in RTK go/no-go matrix
- [ ] If RTK decision = no-go, document the workload heterogeneity finding as the rationale (not just "low Bash %")
- [ ] If RTK decision = go, must include caveats: RTK only buys ~14% in real workloads, and only if Bash output is the dominant token consumer in those workloads

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
