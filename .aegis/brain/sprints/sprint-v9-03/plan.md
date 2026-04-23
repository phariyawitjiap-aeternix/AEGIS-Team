# Sprint v9-03 Plan — Visual Design Layer

**Goal**: Close the VoltAgent/awesome-design-md adoption gap from 5% (format-only) to first-class BLOCK 0 artifact.
**Capacity**: 11pt (4 stories)
**Source**: User request 2026-04-23 — "best option, unlimited token"
**Status**: CLOSED 2026-04-23

## Stories

| ID | Title | Points | Status |
|----|-------|--------|--------|
| S3-01 | Seed design library + fetch tool | 3 | DONE (PR #47) |
| S3-02 | Init wizard + linter | 3 | DONE (PR #47) |
| S3-03 | BLOCK 0F integration | 3 | DONE (PR #48) |
| S3-04 | guard-ui-edit hook | 2 | DONE (PR #48) |

## Deferred to backlog

- S3-05 (future): pattern SSOT refactor (BP F-03 finding from PR #48)
- S3-06 (future): Wasp revival as DESIGN.md owner
- S3-07 (future): DESIGN.md → tailwind tokens pipeline
- S3-08 (future): AEGIS-HQ DESIGN.md submitted upstream
- S3-09 (future): realpath normalization in guard-ui-edit (BP F-02)
- Carried from v9-02 backlog: 4 LOW findings from S3-01/S3-02 review (--output path validation, --seed-all exit code, set -e in init, spec errata)

## Acceptance Criteria

- [x] `.aegis/brain/design-library/` populated with 10 DESIGN.md files
- [x] `tools/aegis-design-fetch.sh` with --slug / --seed-all / --verify-library
- [x] `tools/aegis-design-init.sh` non-interactive (CLI flags only)
- [x] `tools/aegis-design-lint.sh` with default + --strict modes
- [x] BLOCK 0F wired in nick-fury.md, coulson.md, loki.md, black-panther.md
- [x] `.claude/hooks/guard-ui-edit.sh` with EXCLUDE-first path matching
- [x] `.aegis/brain/design-library/` protected in guard-write.sh
- [x] Settings.json patch staged (manual apply per ADR-004)
- [x] 51/51 test assertions pass across 5 harnesses

## Decision Audit Trail

D-022 (spec approach, judgment 0.85) → D-023 (Loki round-1 CONDITIONAL) → D-024 (Iron Man v1.1) → D-025 (Loki APPROVE) → D-026 (Spider-Man impl pivot) → D-027 (BP round-1 CONDITIONAL) → D-028 (Spider-Man round-2) → D-029 (BP PASS batch 1) → D-030 (Spider-Man batch 2) → D-031 (BP round-1 CONDITIONAL batch 2) → D-032 (Spider-Man F-01 fix) → D-033 (BP PASS batch 2)

13 decisions for sprint-v9-03. Judgment-source: 2 (15%) — below 25% threshold ✓.
