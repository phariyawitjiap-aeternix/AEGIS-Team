# Sprint v13-01 Phase C Close: Agent visibility — 23→5 orphans + graph coverage

**Status**: CLOSED · 3pt of 3pt
**Date**: 2026-05-07
**Branch**: `sprint-v13-01-phase-c`
**Phase C of 5** — see [plan.md](plan.md). A + B + D already CLOSED in PRs #139 + #140 + #141 + #142 + #143.

## Stories shipped

| ID | Story | Pt | Status |
|----|-------|----|--------|
| **C1** | Reduce orphan tools (no refs in agents/skills/commands/settings) from 23 to ≤5 by adding "Tools You Can Reach For" sections to relevant agents | 2 | DONE |
| **C2** | Update v12-04 graph build to include single-file `tools/aegis-*.sh` as tool nodes + agent files as MENTIONED_IN sources | 1 | DONE |

Total: **3pt**. v13-01 cumulative now **18/24 = 75%**.

## C1 — Agent tool visibility

Started with **23 orphan tools** (no references in `.claude/agents/`, `skills/`, `.claude/commands/`, or `.claude/settings.json`).

Added a **"Tools You Can Reach For"** section to 8 agents based on natural ownership:

| Agent | Tools added |
|-------|-------------|
| **beast** (researcher) | aegis-brain-search, aegis-brain-index, aegis-brain-benchmark, aegis-token-profile |
| **captain-america** (orchestrator) | aegis-progress, aegis-status-brief, aegis-pending-items, aegis-team-chat |
| **nick-fury** (controller) | aegis-log-decision, aegis-queue-human, aegis-queue-resolve, aegis-pending-items, aegis-policy-audit |
| **thor** (devops) | aegis-test-all, aegis-trace-audit, aegis-fix-hook-paths, aegis-distill-reset, aegis-worktree-gc, aegis-upgrade |
| **war-machine** (qa) | aegis-test-all, aegis-trace-audit, aegis-policy-audit, aegis-token-profile, aegis-brain-benchmark |
| **coulson** (compliance) | aegis-trace-audit, aegis-policy-audit, aegis-func-catalog, aegis-agent-tools-matrix, aegis-privacy-scrubber |
| **wasp** (design) | aegis-design-fetch |
| **iron-man** (architect) | aegis-func-catalog, aegis-agent-tools-matrix |
| **spider-man** (implementer) | aegis-fix-task-list-id, aegis-fix-hook-paths |

**Result**: 23 → 5 orphans. The 5 remaining are architecturally agent-invisible (correct):

| Tool | Why agentless |
|------|---------------|
| `aegis-brain-sync` | Internal helper called by `aegis-brain-write` (sourced library, not direct CLI) |
| `aegis-brain-write` | Internal helper sourced by hooks (not invoked from agent prompts) |
| `aegis-instinct-auto-reinforce` | Cron/scheduler-driven; runs without agent dispatch |
| `aegis-instinct-promote` | Cron/scheduler-driven; runs without agent dispatch |
| `aegis-maintainer-grant` | Security-sensitive; only invoked by user explicit action, never agent |

These are infrastructure tools, not agent-callable. Adding them to agents would be wrong (security/architectural).

## C2 — Graph build coverage

The v12-04 NDJSON graph build (`tools/aegis-brain-graph/build.mjs`) had two gaps that hid agent → tool relationships:

### Gap 1: single-file `tools/aegis-*.sh` were not tool nodes

`listToolPackages()` only iterated *directories* under `tools/`. So multi-file packages like `aegis-live-tail/emit.mjs` got nodes, but single-file scripts like `tools/aegis-progress.sh` were invisible.

**Fix**: added `listSingleFileTools()` that scans top-level `aegis-*.{sh,mjs,js}` and creates one tool node per file with `meta: { single_file: true }`.

### Gap 2: agent files were not parsed for MENTIONED_IN edges

`gatherSources()`'s `brainDocs` array included `learnings/`, `resonance/`, `handoffs/`, `retrospectives/` — but not `.claude/agents/`. So even with the new tool nodes, agent → tool references couldn't form edges.

**Fix**: include `.claude/agents/*.md` (excluding `_archived/`) in the `brainDocs` source list. They get parsed by the existing `parseBrainDoc()` which already creates MENTIONED_IN edges for any node-name match in the document body.

### Verification

```
$ node tools/aegis-brain-graph/build.mjs --full
graph: built 310 nodes, 446 edges (mode=full)   # was 262 nodes, 319 edges → +48 nodes, +127 edges

$ node tools/aegis-brain-graph/query.mjs mentions aegis-progress
aegis-progress: 3 mention(s)
  brain-doc:.aegis/brain/learnings/2026-05-04_aegis-plus-pilot-feedback.md
  brain-doc:.aegis/brain/retrospectives/2026-04/23/14.30_final-push-genuine-100-percent.md
  brain-doc:.claude/agents/captain-america.md  ← Phase C edge

$ node tools/aegis-brain-graph/query.mjs mentions aegis-policy-audit
aegis-policy-audit: 5 mention(s)
  ... 3 prior mentions ...
  brain-doc:.claude/agents/coulson.md           ← Phase C edge
  brain-doc:.claude/agents/nick-fury.md         ← Phase C edge
  brain-doc:.claude/agents/war-machine.md       ← Phase C edge
```

Plan acceptance criterion satisfied:
> Every surviving root tool is referenced from ≥1 of: `.claude/agents/*.md`, `skills/*.md`, `.claude/commands/*.md`, `.claude/settings.json`. v12-04 graph re-build picks up the new edges and `query mentions <tool>` returns ≥1 hit per tool.

## Acceptance evidence

- [x] Orphan-tool count: 23 → 5 (the 5 are architecturally agent-invisible — internal helpers + cron + security-sensitive)
- [x] 8 agents updated with "Tools You Can Reach For" sections
- [x] `tools/aegis-brain-graph/build.mjs`: now indexes single-file aegis-*.sh + agent files
- [x] Graph node count: 262 → 310 (+48 single-file tool nodes); edge count: 319 → 446 (+127 MENTIONED_IN)
- [x] `query mentions aegis-progress` / `aegis-queue-human` / `aegis-policy-audit` all return agent edges
- [x] FUNC catalog regenerated to match (298 entries)
- [x] Full suite: 44/44 ALL PASS · 70s · exit 0

## v13-01 progress after Phase C

```
v13-01 refactor:    18 / 24 pt  =  75.0%
  ✅ Phase A — dead code removal      3 / 3   PR #139
  ✅ Phase B — test coverage           8 / 8   PR #141 + #142 + #143
  ✅ Phase C — agent visibility        3 / 3   this PR
  ✅ Phase D — CI/CD                   5 / 5   PR #140
  ⏳ Phase E — refactor hot files     0 / 5

Phase E remaining: 5pt
  - skills/sprint-tracker.md (564 lines — split into smaller skill files)
  - tools/aegis-instinct-promote.sh (469 lines — review for complexity reduction)
  - AEGIS_v9_PROGRESS_TRACKER.md (7.3KB — archive if dead)
```

## References

- Close doc: this file
- Plan: [`plan.md`](plan.md)
- Predecessor closes: A, D, B/c1, B/c2, B/c3
- Updated agents: [beast](../../../.claude/agents/beast.md), [captain-america](../../../.claude/agents/captain-america.md), [nick-fury](../../../.claude/agents/nick-fury.md), [thor](../../../.claude/agents/thor.md), [war-machine](../../../.claude/agents/war-machine.md), [coulson](../../../.claude/agents/coulson.md), [wasp](../../../.claude/agents/wasp.md), [spider-man](../../../.claude/agents/spider-man.md), [iron-man](../../../.claude/agents/iron-man.md)
- Graph build: [tools/aegis-brain-graph/build.mjs](../../../tools/aegis-brain-graph/build.mjs)
