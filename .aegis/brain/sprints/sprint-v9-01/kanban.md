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

## ✅ DONE -- Brain Infrastructure (Sprint v9-04, ~26pt of 31pt)
- [x] S4-01 MEMORY.md index generation (3pt) -- tools/aegis-brain-sync.sh
- [x] S4-03 brain_write() helper (5pt) -- tools/aegis-brain-write.sh (write + append + subtype mapping)
- [x] S4-01b Session-start hook (3pt) -- tools/v9-session-start-hook.sh + .claude/hooks/session-start.sh
- [x] S4-04 Integration guide (2pt) -- tools/v9-04-integration-guide.md (updated with SDK blocker)
- [x] S4-05 Adversarial corruption test (5pt) -- tools/aegis-brain-adversarial-test.sh (9/9 pass: A-G + scenario H deep-nested + zsh)
- [x] S4-06 Benchmarks (5pt) -- tools/aegis-brain-benchmark.sh (write: 10-13ms, sync: ~50ms)
- [x] S4-02 proxy pattern (3pt of 8pt) -- brain_write emits `AEGIS_MEMORY_WRITE: {...}` directive for main-agent replay (see v9-04-integration-guide.md)
- [~] S4-02 direct memory_20250818 wiring (5pt remaining) -- BLOCKED on SDK, proxy pattern is the documented workaround

## ✅ DONE -- Worktree Isolation (Sprint v9-05 partial, ~13pt of 24pt)
- [x] S5-04 Merge script (5pt) -- tools/aegis-merge-worktree.sh (tested: dry-run + real merge + quirks fix applied)
- [x] S5-02 Spider-Man guidance (3pt) -- applied to .claude/agents/spider-man.md (worktree isolation section + reference)
- [x] S5-04b Known-quirks fix (5pt) -- rebase-onto-HEAD before merge, -f -f cleanup escalation, Known Quirks section in spec
- [x] S5-07 GC script -- tools/aegis-worktree-gc.sh (already existed from prior sprint)
- [x] Real-use validation -- Spider-Man spawned with isolation=worktree; Scenario H added to adversarial test; merge verified end-to-end
- [ ] S5-01 Naming convention enforcement -- DEFERRED (runtime needed)
- [ ] S5-03 Per-agent defaults wiring -- DEFERRED (requires Agent tool isolation param testing)
- [ ] S5-05 Background agents -- DEFERRED (design complete, impl needs real workload)
- [ ] S5-06 mark_chapter wire-up -- DEFERRED (requires Claude Code chapter API)

## 📐 SPEC COMPLETE -- Sprints v9-02 + remaining to v9-15 (428 pts)

| Sprint | Reference Doc | Pts |
|--------|---------------|-----|
| v9-02 | captain-america-fallback.md + decision-audit-protocol.md + block-0-lite.md | 29 |
| v9-04 | memory-tool-integration.md (remaining: S4-02 blocked on SDK) | 8 |
| v9-05 | worktree-isolation.md (remaining: S5-01, S5-03, S5-05, S5-06) | 16 |
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

## Sprint Velocity (cumulative across sessions)
- Implementation: 41 pts (Sprints 1, 3 + portions of 9-01) -- session 1-2
- Specification: 441 pts (Sprints 2, 4-15) -- session 1
- Implementation: 13 pts (Sprint v9-04 remaining) -- session 3 (2026-04-20 AM)
- Implementation: 21 pts (S4-05, S4-06, v9-05 merge) -- session 4 (2026-04-20 PM, part 1)
- Implementation: 11 pts (S4-02 proxy 3pt + S5-04b quirks fix 5pt + ADR-004 proposed + Scenario H 3pt) -- session 4 (part 2)
- Implementation: 19 pts (ADR-004 Phase 2 15pt + v9-05 spawn-from-HEAD investigation 4pt) -- session 5 (post-compact, 2026-04-20 late PM)
- **Total throughput**: 546 pts across 5 sessions

## Notes
- Framework self-protection (guard-write.sh) blocked own settings edit -- correct behavior
- guard-write also blocks: .claude/agents/*.md, .claude/references/*.md mid-session
- Workaround: guidance docs in tools/ with apply-between-sessions pattern (superseded by ADR-004 Phase 2 -- principled override channel)
- All deferred sprints have clear acceptance criteria + effort estimates
- S4-02 memory_20250818: BLOCKED on SDK -- tool not available as callable API in agent runtime
- v9-05 spawn-from-current-HEAD: BLOCKED on SDK -- no base-ref parameter; rebase-onto-HEAD in merge script is permanent
- ADR-004: both phases SHIPPED (observation + authorization); test matrix 23/23 green
- Tracker: AEGIS_v9_PROGRESS_TRACKER.md
