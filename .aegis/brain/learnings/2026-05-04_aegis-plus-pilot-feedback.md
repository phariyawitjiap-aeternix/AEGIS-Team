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

### 2026-05-06 — Day 0 friction (kam-tong-ham bootstrap + first-use)

Bootstrap ran successfully (`bash tools/aegis-plus-pilot/bootstrap.sh ~/Documents/kam-tong-ham`, decision D-087). All 4 steps OK on the bootstrap side. Friction surfaced once Claude Code was opened in the pilot project.

**F1 — `aegis-token-profile.sh` missing in pilot, hook wired anyway**
- Symptom: every Bash tool call in kam-tong-ham emits `bash: /Users/.../kam-tong-ham/tools/aegis-token-profile.sh: No such file or directory` as a non-blocking PostToolUse error.
- Root cause: bootstrap copied `.claude/settings.json` references but `tools/aegis-token-profile.sh` was not in the install set (it's at meta `tools/` root, not under a wired tool package).
- Severity: low (fail-OPEN works; non-blocking) but the noise pollutes every command.
- Fix candidates: (a) install.sh copies all `tools/aegis-*.sh` not just package dirs; (b) bootstrap rewrites settings.json to drop hooks whose target doesn't exist post-install; (c) the hook script itself moves to `tools/aegis-token-profile/<entry>.sh` to match the package convention. **(b) is least invasive — recommend for Day-7 gate review.**

**F2 — `aegis-log-decision.sh` rejects positional args with unhelpful error**
- Symptom: pilot's Claude Code tried `bash tools/aegis-log-decision.sh "ship-sprint-3" "merged ..." ` (positional). Script exits 1 with `Unknown arg: ship-sprint-3` — no pointer to `--help`, no usage hint.
- Root cause: script has no `-h/--help` flag and the `*)` catch-all gives a one-line error.
- Severity: low (the actual logging failed silently — no decision recorded for the Sprint 3 ship in kam-tong-ham). **Loss of audit trail for one decision.**
- Fix: add `-h/--help` printing the usage block, and on unknown arg, suggest `--help`. Fixed in this PR.

**F3 — Stash recovery friction during ship of Sprint 3**
- Symptom: pilot's Claude Code went through 4 retries to ship `feat/sprint3-wip-preserve` because `git stash pop` repeatedly conflicted on `.aegis/brain/logs/activity.log` (hook writes during the merge created a moving target). Eventually resolved with `git apply --reject /tmp/v11-pilot-mods.patch`.
- Root cause: kam-tong-ham was bootstrapped BEFORE v12-04 added `.aegis/brain/{activity,runs,logs}/` to .gitignore. Those paths are TRACKED in the pilot project, so every hook write is a `M` change that races with merges.
- Severity: medium — coding agent burned ~6m of brewed-time recovering from a self-inflicted race.
- Fix: bootstrap should run `git rm --cached -r .aegis/brain/{activity,runs,logs,state}` post-install in the pilot project, OR install.sh should ensure those paths are gitignored before the first hook fires. **Recommend including in Day-7 gate review.**

**F4 — MBP option-menu Stop hook fired correctly (positive signal)**
- Symptom: pilot's Claude Code returned a numbered options menu ("Options: 1. Merge / 2. Cherry-pick / 3. Add remote / 4. Hold") with an explicit question to the human. The on-stop hook detected the pattern and emitted: "AEGIS MBP Golden Rule #7 violation — your last response ended with an option menu PLUS an open question to the human."
- Outcome: Claude Code immediately produced a corrective response that picked one path autonomously and acted on it. **Net result was the right behavior + a recorded violation** for retro mining.
- Severity: positive — the guardrail did its job. The system's first instinct was wrong; the hook re-routed it.
- Action: none needed — confirms v10-04 (MBP soft-ask detection) + on-stop.sh integration is working in the pilot. Counts as a quality win.

**Net Day-0 assessment:** 1 medium (F3, stash race), 2 low (F1, F2), 1 positive (F4). Sprint 3 shipped on the user's actual product (kam-tong-ham game) with all 172 tests passing — the pilot's primary goal. Bootstrap delivered functional value despite F1/F3 being papercuts.

**Open question for pilot Day 1:** does the F1 noise actually impact velocity, or is it just visual? Watch user friction during `/aegis-start` and Bash-heavy work tomorrow.

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
