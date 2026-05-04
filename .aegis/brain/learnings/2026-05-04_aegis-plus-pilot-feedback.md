# AEGIS-Plus Pilot Feedback Log

**Started:** 2026-05-04
**Pilot project:** `~/Documents/kam-tong-ham/`
**Plan source:** `~/Documents/AEGIS-PLUS-MEGA-PLAN.md` v1.1
**First skill in flight:** `aegis-live-tail` (sprint-v11-01)

This file is the authoritative friction log for the AEGIS-Plus pilot. Append entries
as issues / observations / quality wins surface during Phase 1 use. One bullet per
event. Date-stamp every entry.

The plan §10 Step 2 calls for `_aegis-brain/memory/aegis-plus-feedback.md` inside the
pilot project itself; this meta-side mirror exists so the FTS5 brain index picks it
up via `aegis-brain-index.sh`.

---

## Pre-flight reconciliation notes (2026-05-04)

### Directory naming divergence (plan vs current AEGIS)

The Mega Plan §5 prescribes `_aegis-brain/` (single underscore prefix) for all new
state directories. Current AEGIS-Team meta uses `.aegis/brain/` (hidden, dotted).
**Decision for v11**: follow current AEGIS convention — use `.aegis/brain/live/`,
`.aegis/brain/activity/`, etc. Reasons:

1. Existing infra (FTS5 index `aegis-brain-index.sh`, search tool, `tools/aegis-*`)
   all assume `.aegis/brain/`. Switching to `_aegis-brain/` would force a parallel
   indexing path or break search.
2. `.aegis/` is gitignore-friendly (single rule excludes transient state).
3. The plan was written without inspecting AEGIS's existing structure; this is a
   doc-vs-reality alignment, not a design tradeoff.

Sprint plans for v11-01..v11-04 use `.aegis/brain/<subdir>/` paths. The `format.yaml`,
`current.fifo`, `activity/YYYY-MM-DD.jsonl` specs from the plan apply unchanged at
the new path.

### Pilot setup status

- ✅ tmux 3.6a installed
- ✅ node v25.8.2 installed (≥20 required by plan §13)
- ✅ kam-tong-ham/ exists at `~/Documents/kam-tong-ham/`
- ⚠️ kam-tong-ham has **no AEGIS install yet** — `.aegis/` and `_aegis-brain/` both
  absent. AEGIS will need to be bootstrapped into the pilot before sprint v11-01
  can be exercised end-to-end. Bootstrap = Phase 1 first step (decision D1: global
  install at `~/.claude/skills/` so kam-tong-ham only needs `.claude/settings.json`
  hook wiring + `.aegis/brain/live/` for fifo).

### Backups taken

- `~/Documents/AEGIS-Team/.claude/settings.json.pre-aegis-plus-<TS>.bak` (untracked)

---

## Friction log

(append entries below as Phase 1 unfolds)

### 2026-05-04 — preflight committed

- Roadmap.md v11 section added: 4 P1 sprints (18pt) + 4 P2 sprints (32pt deferred)
- sprint-v11-01/plan.md drafted following v10-09 sprint plan shape
- No skill code written yet — sprint-v11-01 starts when user gives go

---

## Decision log (mirrored from sprint plans for one-stop visibility)

| Decision | Resolution | Date | Source |
|---|---|---|---|
| D1 install scope | global `~/.claude/skills/` | 2026-05-04 | plan §14 |
| D2 P1 order | sequential, live-tail first | 2026-05-04 | plan §14 |
| D3 transport | named pipe (fifo) | 2026-05-04 | plan §14 |
| D4 issue prefix | KTH (kam-tong-ham) | 2026-05-04 | plan §14 |
| D5 tmux auto-spawn | yes | 2026-05-04 | plan §14 |
| Dx storage path | `.aegis/brain/` not `_aegis-brain/` | 2026-05-04 | this doc, alignment with existing AEGIS |

## Open questions (to capture during pilot)

- Q: hook latency p95 in real session — does it stay <100ms with all 4 P1 hooks active?
- Q: fifo persistence after Claude Code kill — does the watcher reconnect cleanly?
- Q: does live-tail emit duplicate lines if both PostToolUse hooks fire (activity-logger + live-tail)?
- Q: P2 go/no-go signal — what counts as "≥1 prevented incident value" per plan §14 D6?

## References

- `~/Documents/AEGIS-PLUS-MEGA-PLAN.md` — full plan
- `.aegis/brain/sprints/sprint-v11-01/plan.md` — first sprint
- `.aegis/brain/sprints/roadmap.md` — v11 entries
