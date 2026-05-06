# Sprint v12-06 Close: Auto-wiki + Staleness Signal

**Status**: CLOSED · 5/5pt · 100% · stacked on sprint-v12-05
**Date**: 2026-05-06
**Branch**: `sprint-v12-06`
**Final v12 sprint** — closes Phase B and v12 at **39/39pt (100%)**.

## Stories shipped

| ID | Story | Pt | Status |
|----|-------|----|--------|
| A | `wiki.mjs` — read graph, write PROJECT_INDEX.md + per-skill / per-sprint pages | 2 | DONE |
| B | Wiki determinism — byte-equal-skip on unchanged content | 1 | DONE |
| C | `staleness.mjs` — SessionStart banner when HEAD newer + sources changed | 1 | DONE |
| D | Tests + settings-patch update for SessionStart hook | 1 | DONE |

## Acceptance evidence

- [x] `PROJECT_INDEX.md` auto-overwritten by `wiki.mjs`; sections for **Skills (39) / Sprints / Tools / Hooks / Open issues / Governance Docs**
- [x] `_aegis-output/wiki/skill-<name>.md` exists per skill (39 files); each has Triggers / Wires / Implemented in / Tests / Reads / Writes / Mentioned in sections
- [x] `_aegis-output/wiki/sprint-<id>.md` exists per sprint with Implements list
- [x] Wiki determinism: re-run reports **0 files written, 66 unchanged** (byte-equal-skip works)
- [x] `--check` mode exits 1 on tampered fixture, 0 on fresh
- [x] `staleness.mjs` silent on fresh graph; emits `🕒 brain graph 24h behind HEAD` banner when graph predates a source change by ≥ 1h
- [x] Staleness fail-OPEN: exit 0 even on missing graph / git failure
- [x] SessionStart hook wiring documented in [settings-patch.md](../../../tools/aegis-brain-graph/settings-patch.md)
- [x] Tests: **22 assertions** (target was ≥ 10 — 2.2× the bar)
- [x] Pre-v12 PROJECT_INDEX.md snapshotted to [`.aegis/brain/learnings/2026-05-06_pre-v12-project-index.md`](../../learnings/2026-05-06_pre-v12-project-index.md) per Mega Plan §8.4 / R-K2 mitigation

## Live wiki output (sample)

```
$ time node tools/aegis-brain-graph/wiki.mjs
wiki: 66 files written, 0 unchanged (skipped)
real    0m0.052s

$ node tools/aegis-brain-graph/wiki.mjs   # second run
wiki: 0 files written, 66 unchanged (skipped)
```

```
$ node tools/aegis-brain-graph/staleness.mjs
(silent — graph is fresh)

$ node tools/aegis-brain-graph/staleness.mjs --json
{
  "stale": false,
  "reason": "fresh",
  "graph_built_at": "2026-05-06T09:32:20.416Z",
  "head_committed_at": "2026-05-06T16:29:59+07:00",
  "hours_behind": 0
}
```

## Test suite output

```
T1:  wiki on real meta produces ≥ 60 files                  [PASS x3]
T2:  PROJECT_INDEX.md has all expected sections             [PASS x5]
T3:  skill-aegis-live-tail.md has expected sections         [PASS x4]
T4:  wiki byte-equal-skip on second run                     [PASS x1]
T5:  --check exits 0 when wiki is fresh                     [PASS x1]
T6:  --check exits 1 after manual staleness                 [PASS x1]
T7:  --json output parses                                   [PASS x1]
T8:  staleness silent on fresh graph                        [PASS x2]
T9:  staleness fires when graph predates HEAD               [PASS x1]
T10: staleness --json reports stale=true                    [PASS x1]
T11: staleness fail-OPEN on missing graph                   [PASS x1]
T12: PROJECT_INDEX links ≥ 39 skill pages                   [PASS x1]
Total: 22 pass / 0 fail
```

## Hook wiring (deferred — between-session apply)

`settings-patch.md` now covers BOTH v12-04 (PostToolUse Edit/Write graph build) AND v12-06 (SessionStart staleness banner). Apply in a fresh terminal:

```bash
cat tools/aegis-brain-graph/settings-patch.md   # then run the apply block
```

## ★ v12 grand-total — COMPLETE

```
v12: 39 / 39 pt = 100% ★ ALL SPRINTS CLOSED ★

Phase A (doc canon):     18 / 18 pt   ✅
  v12-01 doc canon       ✅ 8 / 8     PR #117
  v12-02 GUARDRAILS      ✅ 5 / 5     PR #119
  v12-03 frontmatter     ✅ 5 / 5     PR #120

Phase B (knowledge graph): 21 / 21 pt   ✅
  v12-04 NDJSON build    ✅ 8 / 8     PR #121
  v12-05 graph queries   ✅ 8 / 8     PR #122
  v12-06 wiki + stale    ✅ 5 / 5     PR (this)

Total: 39 / 39 pt — single-session delivery, all 6 sprints stacked,
       149 assertions across 5 test suites (lint + add-sign + skill-
       frontmatter + graph-build + graph-query + wiki).
```

## What v12 delivered (the framework gain)

Before v12: 30+ skills, 11 hooks, 5 brain configs — and no machine-readable map of how they fit, no testable repo-wide DoD, no graph of which spec drives which test drives which sprint.

After v12: AEGIS knows itself.

- **DoD.md** — repo-wide stable completion bar (9 sub-bars)
- **ARCHITECTURE.md** — concern→file map + hook DAG + brain ingestion DAG
- **GUARDRAILS.md** — 12 Signs (Trigger/Do/Why) covering the recurring v11 fix-classes
- **Versioned headers** — every governance doc carries `<!-- version: -->` + Changelog
- **Skill frontmatter schema** — 39 skills with reads/writes/wires/tests/supersedes
- **Knowledge graph** — 234+ nodes, 257+ edges in NDJSON (file-as-contract preserved)
- **5 query subcommands** — impact / context / detect-changes / mentions / wiring
- **Auto-wiki** — PROJECT_INDEX.md + per-skill / per-sprint pages, all derived from graph
- **Staleness banner** — SessionStart warning when graph predates the latest commit

## References

- Plan: [.aegis/brain/sprints/sprint-v12-06/plan.md](plan.md)
- Source: `~/Documents/AEGIS-KNOWLEDGE-MEGA-PLAN.md` v1.1 §6 v12-06 + §2.6 + §2.7
- Predecessor: sprint-v12-05 (PR #122)
- Snapshot: `.aegis/brain/learnings/2026-05-06_pre-v12-project-index.md` (pre-v12 manual content)
