# Sprint Kanban — sprint-v9-04

**Goal**: Design Generator + carry-forward cleanup
**Capacity**: 10pt · **Progress**: 5/10 (50%)
**Status**: ACTIVE

## BACKLOG
- [ ] 4 LOW findings batched (v9-03 BP F-02 realpath, F-04 settings apply doc; v9-04 round-1 F-01 TC-2 grep, F-02 WebSearch advisory) — 4pt

## TODO
- [ ] [S3-05] EXCLUDE/INCLUDE pattern SSOT — 3pt — single file sourced by guard-ui-edit, block0-f-gate test, nick-fury.md prose
- [ ] [S2-05] Promote resonance → instinct lifecycle — 3pt — pipeline gap from v9-02 retro
- [ ] [S2-06] Track approved specs in git — 2pt — fix `_aegis-output/specs/` exclusion
- [ ] [S3-09] realpath normalization in guard-ui-edit — 1pt — v9-03 BP F-02 LOW

## IN_PROGRESS
_(empty)_

## IN_REVIEW
_(empty)_

## QA
_(empty)_

## DONE

- [x] [S3-06] Wasp Revival — Design Generator (@spider-man) — 5pt [PR #50 merged 2026-04-23]
      Full 6-decision autonomous cycle D-036 → D-041. Iron Man mega-spec → Loki
      CONDITIONAL 4 conditions (all stem from Bash-less-Wasp phantom-lint root) →
      Iron Man v1.1 APPROVE → Spider-Man 8-file delivery → BP PASS.
      Artifacts: new `.claude/agents/wasp.md` (181 LOC, Design Generator role with
      full MBP + Continuation Protocol), BLOCK_0F_CHECK Path D + broken-DESIGN
      branches in nick-fury.md, Loki Design-Approval Gate, BP PASS 7 a11y review,
      new `tools/aegis-contrast-check.sh` (WCAG math, 4/4 TCs),
      `tools/aegis-wasp-generate-test.sh` (12/12 TCs). Total 16/16 new assertions.

## Framework capability matrix after this sprint (so far)

| Capability | Before v9-04 | After S3-06 |
|---|---|---|
| DESIGN.md copy from library | ✅ (Paths A/B) | ✅ |
| DESIGN.md blank scaffold | ✅ (Path C) | ✅ |
| DESIGN.md **custom authoring** | 🔴 (Wasp archived) | ✅ **(Path D, Wasp)** |
| DESIGN.md validation | ✅ (lint) | ✅ + inline contrast ratios |
| DESIGN.md a11y review | 🔴 | ✅ (BP PASS 7) |
| Contrast verification | 🔴 | ✅ (WCAG tool + inline) |

Visual Design Layer is now **complete**: produce → validate → enforce → review, all 4 capabilities shipped.
