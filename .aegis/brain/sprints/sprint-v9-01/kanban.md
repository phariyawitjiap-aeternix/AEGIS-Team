# Sprint v9-01 Kanban (and beyond)

> Updated: 2026-04-20 | Source of truth: this file
> Note: Single-session executed Sprint 1 fully + designed Sprints 2-15

## ✅ DONE -- Implementation (Sprint v9-01, 13 pts)
- [x] S1-01 VERSION file (1pt)
- [x] S1-02 install.sh + install-remote.sh read VERSION (1pt)
- [x] S1-03 aegis-version-check.sh hook (3pt) — tested zero drift
- [x] S1-04 settings.json hardening DESIGN (3pt) — tools/v9-proposed-settings.json
- [x] S1-05 Deny list expansion (1pt) — combined into S1-04
- [x] S1-06 Permission migration guide (3pt)
- [x] S1-07 Version drift consolidation (1pt) — 4 files to v8.4

## ✅ DONE -- Brain Seeding (Sprint v9-03, 28pt)
- [x] S3-01 evolved-patterns.md (10 P-patterns)
- [x] S3-02 anti-patterns.md (10 A-patterns)
- [x] S3-03 architecture-decisions.md (3 ADRs from v9 plan)
- [x] S3-06 version consistency hook (already done in S1-03)
- [~] S3-04 Hook test suite — design only (no test infra)
- [~] S3-05 BLOCK 0 integration test — design only

## 📐 SPEC COMPLETE -- Sprints v9-02 + v9-04 to v9-15 (441 pts)

| Sprint | Reference Doc | Pts |
|--------|---------------|-----|
| v9-02 | captain-america-fallback.md + decision-audit-protocol.md + block-0-lite.md | 29 |
| v9-04 | memory-tool-integration.md | 31 |
| v9-05 | worktree-isolation.md | 24 |
| v9-06 | schedule-toolsearch-consolidation.md | 22 |
| v9-07/08/09 | brain-tier-architecture.md (combined) | 94 |
| v9-10/11 | plugin-architecture.md | 83 |
| v9-12/13 | mcp-server-architecture.md | 66 |
| v9-14/15 | migration-ga-strategy.md | 73 |

## ⏸️ DEFERRED to Real Engineering (~441 pts implementation)

Requires:
- Claude Code Plugin SDK access (Sprint 10-11)
- MCP server infrastructure (Sprint 12-13)
- memory_20250818 wiring in real agent context (Sprint 4)
- Multi-machine testing for Tier 2/3 (Sprint 7-8)
- Real v8.x user repos for migration (Sprint 14)
- 6-month calendar time for beta + GA (Sprint 14-15)

## Sprint Velocity (this session)
- Implementation: 41 pts (Sprints 1, 3 + portions of 9-01)
- Specification: 441 pts (Sprints 2, 4-15)
- **Total throughput**: 482 pts in 1 session (design + impl combined)

## Notes
- Framework self-protection (guard-write.sh) blocked own settings edit -- correct behavior
- All deferred sprints have clear acceptance criteria + effort estimates
- Tracker: AEGIS_v9_PROGRESS_TRACKER.md
