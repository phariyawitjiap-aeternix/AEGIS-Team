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

### 2026-05-06 — Pilot week compressed (Day-7-equivalent retro on user request)

User decision (2026-05-06, by-name): "ต้องการให้เสร็จตอนนี้ ไม่อยากรอ 7 วัน" — compress the 7-day pilot week into a single Day-7-equivalent gate-check + remediation cycle. Reasonable given the only day of real signal (Day 0) already produced enough data to act on.

**gate-check.sh result on kam-tong-ham (Day 1 of pilot):**

```
Signal 1 — Prevented-incident value:    0 events     ✗
Signal 2 — Audit-query value:           3 queries    ✓
Signal 3 — Run-replay value:            1 mention    ✓
Verdict:                                2 of 3 met → GATE OPEN
```

Phase-2 (v11-05..08) was already shipped eagerly during the v11 burst; this gate-check **retroactively validates that decision** with real pilot data. Signal 1 is empty because pilot use was 1 day only — would grow with longer pilot. Signal 2 + Signal 3 hit threshold even on Day-1 data.

**Day-7-equivalent fixes shipped (this PR):**

| Signal | Fix | How |
|---|---|---|
| F1 (low) | Bootstrap self-heal + remediate.sh | New step 5/6 in `bootstrap.sh` scans wired hooks for missing target files; copies them from meta if available, drops the entry otherwise. New `remediate.sh` does the same idempotently for already-bootstrapped pilots. |
| F2 (low) | Already shipped in PR #125 | `aegis-log-decision.sh` now has `-h/--help` + better unknown-arg error |
| F3 (medium) | Bootstrap auto-untrack + .gitignore add + remediate.sh | New step 6/6 in `bootstrap.sh` runs `git rm --cached -r` on `.aegis/brain/{activity,runs,logs,state}/` if tracked, and adds them to the pilot's `.gitignore`. Same logic in `remediate.sh`. **Meta repo's own tracked runtime dirs also untracked in this PR.** |
| F4 (positive) | None needed | MBP option-menu Stop hook confirmed working in the wild |

**Verification commands (all green):**

```
$ node tools/aegis-doc-canon/lint.mjs                        # 8/8 governance docs
$ node tools/aegis-doc-canon/skill-frontmatter.mjs --lint    # 39/39 skills satisfy schema
$ node tools/aegis-brain-graph/build.mjs --full --quiet      # graph rebuilds clean
$ bash -n tools/aegis-plus-pilot/{bootstrap,remediate}.sh    # syntax OK
```

**Pilot week — closed.**
- Phase-1 (4 skills · 18pt) shipped: ✓
- Phase-2 (4 skills · 32pt) shipped + gate-validated: ✓
- Phase-3 (resume + multi-tenant · 13pt) shipped early on user "ship it": ✓
- v11 + v12 stacked PRs all merged on main
- Bootstrap fixes for next pilot landing on this PR

**To remediate the existing kam-tong-ham bootstrap (NOT auto-run — External Access):**

```bash
bash tools/aegis-plus-pilot/remediate.sh ~/Documents/kam-tong-ham
cd ~/Documents/kam-tong-ham
git add .gitignore && git commit -m "chore: untrack runtime brain dirs (pilot remediation F3)"
```

This fixes the F1 hook noise and the F3 stash-race in kam-tong-ham retroactively. Single by-name command from user, hook permitting.

**Forward chain (post-merge):**
- Hermes L2 (v10-07) — still DEFERRED, but `decision-audit.log` now has D-086, D-087, D-088 — enough to think about pattern shape next session
- Settings-patch.md apply (between-session) — for v12-04 PostToolUse + v12-06 SessionStart hooks
- Otherwise: AEGIS framework is at a clean rest state, all roadmap items closed.

---

### 2026-05-06 — "จัดการให้หมด" cleanup pass (post-pilot rest-state housekeeping)

User imperative: "จัดการให้หมด" — clean up the 8 known follow-ups surfaced in the prior status check. Done in one PR.

**Cleared (5/8):**
- ✅ #1 — `git rm --cached` of `.aegis/brain/graph/{edges,meta,nodes}.ndjson`. They were tracked from v12-04/05 dev despite being added to `.gitignore` simultaneously. Now ignored, regenerable from sources.
- ✅ #2 — `.aegis/brain/sprints/CURRENT` symlink re-pointed `sprint-v10-02` (May 2) → `sprint-v12-06` (today's latest closed). `aegis-progress.sh` now reports the right "Current sprint" line.
- ✅ #3 — `README.md` bumped v11.0 → **v12.0**. Top-section badges, intro tagline, two new "What's new in v12 — Knowledge Layer" + "What's new in v11 — Operational Layer" sections, refreshed Directory Structure (10 agents, 39 skills, 12 commands, 13 hooks, all v11/v12 brain dirs called out), Version History table extended with v12 sprint roll-up.
- ✅ #6 — `sprint-v10-07/plan.md` authored as a **scoped, grounded** Hermes L2 design. The decision-audit log now has 120 entries with 55 judgment-fallbacks across 11 sprints — well above noise threshold. Plan defines: deterministic miner (`tools/aegis-pattern-mine/mine.sh`), idempotent cluster keys (SHA256 of normalized question), instinct candidate writer (`_proposed/<id>.yaml`), tests, integration with v10-09 instinct-promote. Status remains SCOPED, not OPEN — needs explicit "open v10-07" go.
- ✅ Roadmap updated: v10-07 row added as SCOPED (not counted in v10 in-repo denominator until opened).

**Skipped honestly (1/8):**
- 🟢 #5 — distill memory (count=64, threshold=3). Real distillation = Captain America synthesis over 64 sessions of accumulated learnings (Agent dispatch, ~30min). Resetting just the counter would be the "policy-without-test" Sign exact bug class — claiming distill is fresh without doing it. **Decision:** leave counter as-is; auto-fires next session. If the user wants real distill: dispatch `/aegis-memory --distill` explicitly. Logged as decision D-089.

**Cannot auto-execute (3/8):**
- 🟡 #4 — `tools/aegis-brain-graph/settings-patch.md` apply (v12-04 PostToolUse build hook + v12-06 SessionStart staleness hook). `guard-write.sh` correctly blocks mid-session edits to `.claude/settings.json` — the same self-protection that blocked it in sprint-v12-04. **Apply between sessions** in a fresh terminal: `cat tools/aegis-brain-graph/settings-patch.md | grep -A 30 'python3 -' | bash -s -- ...`. The patch is idempotent.
- ⏸️ #7 — Hermes L3 (sprint-v10-08). Correctly DEFERRED — blocked on L2 measurement. Will unblock once L2 mine runs and produces real pattern data. No action this PR.
- ⏸️ #8 — kam-tong-ham retroactive remediation (`bash tools/aegis-plus-pilot/remediate.sh ~/Documents/kam-tong-ham`). External Access — needs a by-name imperative ("remediate kam-tong-ham" / "ทำ kam-tong-ham"), not a generic "do all" sweep. Tool is ready; awaits explicit go.

**Net post-cleanup state:**
- **Open PRs:** 1 (this one, until merged) → 0 after merge
- **Human queue:** 0 pending
- **Working tree (after merge):** clean
- **CURRENT symlink:** sprint-v12-06 (correct)
- **Active backlog:** sprint-v10-07 SCOPED (8pt) + 3 deferred items (#4 between-session, #7 blocked, #8 needs by-name go)

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
