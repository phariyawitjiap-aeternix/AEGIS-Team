# Sprint Kanban — sprint-v9-04

**Goal**: Design Generator + carry-forward cleanup
**Capacity**: 10pt · **Delivered**: 14pt (140%)
**Status**: CLOSED 2026-04-23

## BACKLOG
_(empty — all items absorbed into sprint or deferred to v9-05)_

## TODO
_(empty)_

## IN_PROGRESS
_(empty)_

## IN_REVIEW
_(empty)_

## QA
_(empty)_

## DONE

- [x] [S3-06] Wasp Revival — Design Generator (@spider-man) — 5pt [PR #50]
- [x] [S3-05] EXCLUDE/INCLUDE pattern SSOT (@spider-man) — 3pt [PR #52]
- [x] [S2-05] Instinct lifecycle tool (@spider-man) — 3pt [PR #52]
- [x] [S2-06] Track approved specs in git + retroactive 5 specs (@spider-man) — 2pt [PR #52]
- [x] [S3-09] realpath normalization in guard-ui-edit (@spider-man) — 1pt [PR #52]

## Deferred to v9-05

- 4 advisory findings from BP reviews this sprint:
  - C-01 MEDIUM: macOS realpath -m silent degradation warning
  - S-02 LOW: python3 -c argv vs interpolation in instinct tool
  - (v9-03 carry) F-02 WebSearch inherent risk documentation
  - (v9-03 carry) F-04 guard-ui-edit settings.json apply doc

## Sprint metrics

- Test assertions added: 57 (7 ui-patterns + 13 guard-ui-edit + 4 spec-tracking + 10 instinct-promote + 4 contrast-check + 12 wasp-generate + 7 block0-f-gate)
- Files changed: 22 unique (8 new tools, 5 agent prompts modified, 5 historical specs preserved, 4 other)
- Decisions logged: 14 (D-036 through D-049)
- Autonomous cycles: 2 (Wasp Revival + 4-story batch), both completed with round-2 fixes after BP CONDITIONAL

## Framework Delta

**Before v9-04**:
- Visual Design Layer: produce (partial — Paths A/B/C only) → validate → enforce
- Instincts: manual YAML edits only (no tooling for promotion)
- Specs: gitignored (history lost)
- Hook path matching: duplicated across 4 files, path traversal false-positives on macOS

**After v9-04**:
- Visual Design Layer: **produce (all 4 paths incl. Path D custom) → validate → enforce → review**
- Instincts: **tooled lifecycle** (create/reinforce/activate/promote/retire/list) matching README thresholds
- Specs: **tracked in git** (approved specs from v9-02/03/04 committed retroactively)
- Hook path matching: **SSOT + canonical** (realpath chain, REPO_ROOT canonicalized for macOS symlink)

Visual Design Layer is now genuinely **production-ready** end-to-end.

## Sprint closed 2026-04-23 by Captain America (main agent)
