# Sprint v9-01 Plan -- Foundation Hardening

## Goal
Single source of truth for version + permission lockdown (close attack surface)

## Source
[AEGIS_v9_UPGRADE_PLAN.md](../../../../AEGIS_v9_UPGRADE_PLAN.md) Phase 1 Sprint 1

## Duration
- Start: 2026-04-20
- End: 2026-04-20 (single-session execution)

## Capacity
- 13 story points
- 1 session

## Tasks

| ID | Task | Pts | Status |
|----|------|-----|--------|
| S1-01 | VERSION file (single source of truth) | 1 | DONE |
| S1-02 | install.sh + install-remote.sh read VERSION | 1 | DONE |
| S1-03 | aegis-version-check.sh hook | 3 | DONE |
| S1-04 | settings.json hardening (designed, manual apply) | 3 | DONE-DESIGN |
| S1-05 | Deny list expansion (combined into S1-04) | 1 | DONE |
| S1-06 | Permission migration guide | 3 | DONE |
| S1-07 | Version drift consolidation (4 files to v8.4) | 1 | DONE |

**Total**: 13/13 pt complete

## Outcome
- Zero version drift detected by hook
- Permission model designed (26 deny patterns vs 8 in v8.x)
- Migration guide ready for v8.x users
- Framework self-protection validated (hook blocked our own settings edit -- correct behavior)

## Carryover to Sprint v9-02
None. Sprint complete.
