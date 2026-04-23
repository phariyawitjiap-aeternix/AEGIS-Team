# Sprint v9-04 Plan — Design Generator + Cleanup

**Goal**: Close the final Visual Design Layer gap (AUTHOR custom DESIGN.md) + address carry-forward debt from prior sprints.
**Capacity**: 10pt (6 stories, last one stretch)
**Status**: ACTIVE (opened 2026-04-23, S3-06 already shipped this session)

## Stories

| ID | Title | Points | Status |
|----|-------|--------|--------|
| **S3-06** | Wasp Revival — Design Generator | 5 | **DONE (PR #50 merged 2026-04-23)** |
| S3-05 | EXCLUDE/INCLUDE pattern SSOT (v9-03 BP F-03) | 3 | TODO |
| S2-05 | Promote resonance → instinct lifecycle (v9-02 retro carry) | 3 | TODO |
| S2-06 | Track approved specs in git (v9-02 retro carry) | 2 | TODO |
| S3-09 | realpath normalization in guard-ui-edit (v9-03 BP F-02) | 1 | TODO |
| BACKLOG-LOW | 4 LOW findings from v9-03 + v9-04 round-1 reviews | 4 | BACKLOG |

## Acceptance criteria for S3-06 (done)

- [x] Wasp un-archived to `.claude/agents/wasp.md` with MBP section
- [x] Nick Fury BLOCK_0F_CHECK has Path D (custom-author) + broken-DESIGN branches
- [x] Loki has Design-Approval Gate (DESIGN_APPROVAL_RESPONSE verdict format)
- [x] Black Panther has PASS 7 Accessibility Review
- [x] `tools/aegis-contrast-check.sh` WCAG contrast calculator (4/4 TCs)
- [x] `tools/aegis-wasp-generate-test.sh` (12/12 TCs)
- [x] Paths A/B/C from v9-03 unchanged (regression-free)

## Decision Audit Trail (so far)

D-036 (sprint-open, framework 0.95) → D-037 (Loki round-1 CONDITIONAL 4 conditions) → D-038 (Iron Man v1.1) → D-039 (Loki APPROVE) → D-040 (Spider-Man impl) → D-041 (BP APPROVE)

6 decisions for S3-06. Judgment-source: 0 (0% — all brain-backed on this story). Sprint-level 1 judgment (D-036 framework-source).

## Scope honesty note

S3-06 actual effort was ~5.5pt (Iron Man claimed 0pt for contrast-check helper but Loki flagged it as 0.5pt real work in D-038). Sprint tally reflects the original 5pt budget; scope creep of 0.5pt absorbed within sprint.
