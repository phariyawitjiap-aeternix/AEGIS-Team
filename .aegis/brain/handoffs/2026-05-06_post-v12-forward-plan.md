# Post-v12 Forward Plan — แผนเดินหน้าหลัง v12 ปิด

**Date:** 2026-05-06
**Author:** Captain America (sole Opus 4.7 session)
**Project state:** clean rest · all sprint series CLOSED · 0 open PRs · 0 human-queue
**Grand total:** 214 / 210 pt = 101.9% (over-delivered by v9-04 stretch)
**Source for everything below:** [`.aegis/brain/sprints/roadmap.md`](../sprints/roadmap.md), [`.aegis/brain/learnings/2026-05-04_aegis-plus-pilot-feedback.md`](../learnings/2026-05-04_aegis-plus-pilot-feedback.md), [`.aegis/brain/logs/decision-audit.log`](../logs/decision-audit.log)

---

## 0. TL;DR — ที่เหลือ 0 items (was 4 — all done 2026-05-06)

```
✅ A — settings-patch apply       (DONE · D-090 · activates on next Desktop reload)
✅ B — kam-tong-ham remediate     (DONE · D-092 · F1 self-heal clean / F3 untracked 2 dirs)
                                   USER must commit .gitignore in kam-tong-ham terminal
✅ C — open sprint-v10-07         (DONE · CLOSED 8/8 pt · PR #130 · 20/20 assertions)
✅ D — scope sprint-v10-08        (DONE · SCOPED-DEFERRED · plan.md w/ 3 unblock conditions)

🟢 optional — distill memory · stale doc cleanup · TODO/FIXME prose markers
```

**Forward plan exhausted.** AEGIS framework at clean rest state.

---

## 1. Item A — settings-patch.json apply ✅ DONE 2026-05-06

**Status:** COMPLETED 2026-05-06 23:29 by user via separate macOS Terminal.app · D-090 logged

**Outcome verified:**
- `PostToolUse[matcher="Edit|Write|MultiEdit"]` → 2 commands: existing `post-edit-accumulate` + new `tools/aegis-brain-graph/hook.sh`
- `SessionStart[matcher="startup"]` → 2 commands: existing `aegis-resume/session-start.mjs` + new `tools/aegis-brain-graph/staleness.mjs`
- Backup at `.claude/settings.json.pre-v12-04-backup`

**Activates on next Claude Desktop session reload** (close project tab → reopen, or `Cmd+Q` → relaunch). Current session still uses old in-memory settings; that's fine — next session picks up new hooks automatically.

**Below sections kept for reference / rollback:**

**Why:** v12-04 PostToolUse graph-build hook + v12-06 SessionStart staleness banner ยังไม่ได้ wire ใน meta `.claude/settings.json` เพราะ `guard-write.sh` (v9-01 self-protection) block การแก้ settings.json ระหว่าง Claude session กำลังรัน

**Reference:** [`tools/aegis-brain-graph/settings-patch.md`](../../tools/aegis-brain-graph/settings-patch.md)

### Prerequisites
- [ ] ออกจาก Claude Code session (กด Ctrl+D / `/exit` / Ctrl+C)
- [ ] เปิด terminal ใหม่บนเครื่อง

### Steps

```bash
cd ~/Documents/AEGIS-Team

# Backup ก่อน — กลับมาได้
cp .claude/settings.json .claude/settings.json.pre-v12-04-backup

# Apply 2 hooks (graph-build + staleness)
python3 - <<'PYEOF'
import json, sys
with open('.claude/settings.json') as f:
    s = json.load(f)
post = s['hooks']['PostToolUse']
for entry in post:
    if entry.get('matcher') == 'Edit|Write|MultiEdit':
        cmds = entry['hooks']
        target = 'tools/aegis-brain-graph/hook.sh'
        if not any(target in h.get('command', '') for h in cmds):
            cmds.append({'type': 'command',
                         'command': 'bash "$CLAUDE_PROJECT_DIR/tools/aegis-brain-graph/hook.sh"'})
            print('+ added graph-build hook to PostToolUse Edit|Write|MultiEdit')
        else:
            print('= graph-build hook already present')
        break
sess = s['hooks'].get('SessionStart', [])
for entry in sess:
    if entry.get('matcher') == 'startup':
        cmds = entry['hooks']
        target = 'tools/aegis-brain-graph/staleness.mjs'
        if not any(target in h.get('command', '') for h in cmds):
            cmds.append({'type': 'command',
                         'command': 'node "$CLAUDE_PROJECT_DIR/tools/aegis-brain-graph/staleness.mjs"'})
            print('+ added staleness hook to SessionStart startup')
        else:
            print('= staleness hook already present')
        break
with open('.claude/settings.json', 'w') as f:
    json.dump(s, f, indent=2); f.write('\n')
print('\n✓ patch applied. Backup: .claude/settings.json.pre-v12-04-backup')
PYEOF

# Verify
jq '.hooks.PostToolUse[] | select(.matcher=="Edit|Write|MultiEdit")' .claude/settings.json
jq '.hooks.SessionStart[] | select(.matcher=="startup")' .claude/settings.json

# กลับเข้า Claude Code
claude
```

### Expected outcome

- `+ added graph-build hook to PostToolUse Edit|Write|MultiEdit`
- `+ added staleness hook to SessionStart startup`
- ทุก Edit/Write/MultiEdit จะ trigger graph rebuild (debounced 3s) ใน background
- SessionStart จะแสดง `🕒 brain graph N hours behind HEAD` ถ้า graph เก่ากว่า HEAD ≥ 1h

### Rollback (ถ้าพัง)

```bash
cp .claude/settings.json.pre-v12-04-backup .claude/settings.json
```

### Effort
~2 minutes · idempotent · low risk (มี backup, มี rollback)

---

## 2. Item B — kam-tong-ham retroactive remediate ✅ DONE 2026-05-06

**Status:** COMPLETED 2026-05-06 by user "remediate kam-tong-ham" imperative · D-092 logged

**Outcome:**
- F1 (hook self-heal): `copied=0 dropped=0` — bootstrap.sh step-5 self-heal already cleaned the chain on the earlier 2026-05-06 bootstrap run (D-087)
- F3 (untrack runtime brain dirs): 2 dirs untracked (activity/ + logs/) · 2 .gitignore lines added
- Backup: `~/Documents/kam-tong-ham/.claude/settings.json.pre-remediate.1778086759.bak`

**Remaining manual step (USER, in kam-tong-ham terminal):**

```bash
cd ~/Documents/kam-tong-ham
git add .gitignore
git commit -m 'chore: untrack runtime brain dirs (pilot remediation F3)'
```

**Below sections kept for reference / rollback:**

**Why:** kam-tong-ham pilot project ถูก bootstrap ก่อน v12-04 fixes พร้อม → มี tracked runtime brain dirs (race กับ merge) + hooks ที่อ้างถึง `aegis-token-profile.sh` ที่ไม่มีใน pilot's tools/

**Reference:** [`tools/aegis-plus-pilot/remediate.sh`](../../tools/aegis-plus-pilot/remediate.sh)

### Prerequisites
- [ ] Claude session กำลังรัน (อยู่ที่ meta repo `~/Documents/AEGIS-Team`)
- [ ] kam-tong-ham git tree clean ก่อน (commit งานที่กำลังทำเพื่อความปลอดภัย)

### Trigger

ในบทสนทนากับ Claude Code (meta repo) — พิมพ์ imperative ตรง ๆ:

- ✅ `remediate kam-tong-ham`
- ✅ `ทำ kam-tong-ham`
- ✅ `go remediate kam-tong-ham`
- ❌ `ทำ kam-tong-ham ได้มั้ย` (เป็นคำถาม → guard-bash hook block)
- ❌ `do them all` (generic sweep ไม่ครอบคลุม External Access ตาม memory rule)

### What runs

```bash
bash tools/aegis-plus-pilot/remediate.sh ~/Documents/kam-tong-ham
```

จะทำ 2 อย่าง:
1. **F1 self-heal:** scan kam-tong-ham `.claude/settings.json` หา hook ที่อ้าง path ที่ไม่มี → copy จาก meta ถ้ามี, drop entry ถ้าไม่มี (มี backup `settings.json.pre-remediate.<ts>.bak`)
2. **F3 untrack:** `git rm --cached -r .aegis/brain/{activity,runs,logs,state}/` + เพิ่มเข้า `.gitignore` ของ kam-tong-ham

### Post-step (ทำต่อใน kam-tong-ham terminal)

```bash
cd ~/Documents/kam-tong-ham
git status --short        # ดู untracked + .gitignore changes
git add .gitignore
git commit -m "chore: untrack runtime brain dirs (pilot remediation F3)"
```

### Expected outcome

- ไม่มี "No such file" stderr noise ทุก Bash call ใน kam-tong-ham อีก
- Stash/merge ใน kam-tong-ham ไม่ race กับ hook writes อีก

### Effort
~1 minute · idempotent · auto-backup of settings.json

---

## 3. Item C — Open sprint-v10-07 (Hermes L2 pattern miner)

**Status:** SCOPED, plan.md เขียนเสร็จแล้ว · 8pt · กำลังรอ user "open v10-07" go

**Reference:** [`sprint-v10-07/plan.md`](../sprints/sprint-v10-07/plan.md)

### Why now is the right time

`decision-audit.log` ตอนนี้มี:
- **120 entries** (พอสำหรับ pattern mining)
- **55 judgment-fallbacks** (target ของ miner)
- ครอบคลุม **11 sprints** (sprint diversity = signal คุณภาพ)

ก่อน 2026-05-06 ข้อมูลน้อยเกินจะ mine — ตอนนี้พอแล้ว

### Trigger

ใน Claude Code session — พิมพ์:
- ✅ `open v10-07`
- ✅ `ship pattern miner`
- ✅ `start hermes l2`

### Sprint scope (per plan.md)

| Story | Pt | What |
|---|---:|---|
| A | 3 | `tools/aegis-pattern-mine/mine.sh` — JSONL → cluster report |
| B | 2 | Cluster key stability (SHA256 + sort discipline, byte-equal output) |
| C | 2 | `tools/aegis-pattern-mine/propose.sh` — write top-3 candidates as `instincts/_proposed/<id>.yaml` |
| D | 1 | Tests + integration with v10-09 instinct-promote |

### Open questions for kickoff (จาก plan.md §"Open questions")

1. Normalizer rule scope — start small (3 rules) or rich up front?
2. Top-N default — 3 / 5 / 10?
3. Mine cadence — manual `/aegis-mine` only, or PostToolUse/SessionStart auto?
4. Cross-pollination with v11-02 activity-logger — ADR needed?

ผมจะเดาคำตอบ default เริ่ม (start small / N=3 / manual / no cross-pollination) แล้วเขียน ADR-stub ถ้าต้องการ

### Estimated calendar
~1 session (2-3 ชั่วโมง) ตามแบบ v12-04..06 — single Opus session, single PR

---

## 4. Item D — sprint-v10-08 (Hermes L3 instinct refinement loop)

**Status:** DEFERRED — blocked on L2 measurement

**Why blocked:** L3 = "เมื่อ instinct candidate ถูก promote แล้ว observed-vs-actual outcome ตรงกันมั้ย?" — ต้องมี:
1. Instinct ที่ถูก promote จาก L2 (ยังไม่มี — ต้องรัน L2 mine + propose ก่อน)
2. ≥1 cycle ของ "instinct fired → outcome recorded" (ต้องผ่านบาง session ที่ใช้งาน instinct จริง)

**Unblock condition:** ปิด v10-07 + รัน mine ครั้งแรก + ใช้งาน instinct ที่ promote ในอย่างน้อย 1 session ถัดไป

**Estimated:** ปิด v10-07 ก่อน 2 weeks → L3 unblock ได้

ไม่มี action ตอนนี้ · plan จะเขียนเมื่อ L2 ปิด

---

## 5. Optional / cosmetic (ไม่ blocking)

### 5.1 Distill memory (count=64)

Counter อยู่ที่ 64 sessions since last distill (threshold=3). Auto-fires next session start ทุกครั้งจนกว่าจะรัน distill จริง

**ทำตอนไหน:** เมื่อมีเวลา ~30 นาทีให้ Captain America synthesize learnings/activity จริง

**ทำยังไง:** พิมพ์ `/aegis-memory --distill` ใน session ถัดไป → Captain America จะ Agent-dispatch synthesis · ห้าม fake-reset (เป็น "policy-without-test" Sign exact bug class · D-089 logged)

**Effort:** ~30 minutes Agent dispatch + review

### 5.2 AEGIS_v9_PROGRESS_TRACKER.md cleanup

Last-updated 2026-04-20 · CLAUDE.md note บอกว่าเป็น "Historical v9 tracker" แล้ว · พิจารณา archive ไปไว้ใน `_aegis-output/architecture/archive/` หรือ delete ทั้งไฟล์

**Effort:** 1-line decision + 1 git mv · 1 PR

### 5.3 TODO/FIXME prose markers

5 skills มี TODO/FIXME ใน prose body (docstring TODOs, ไม่ใช่ functional bugs):
- `tools/aegis-design-init.sh`
- `skills/tech-debt-tracker.md`
- `skills/aegis-reengineer.md`
- `skills/kanban-board.md`
- `skills/sprint-tracker.md`

**ทำตอนไหน:** เมื่อ touch แต่ละ file ครั้งหน้าเพื่อเหตุผลอื่น · ไม่ต้องเปิด PR แยก

---

## 6. Sequencing & priority — all done

```
✅ A (settings-patch)             DONE 2026-05-06 (D-090) · activates on next reload
✅ B (kam-tong-ham remediate)    DONE 2026-05-06 (D-092) · USER must commit .gitignore in pilot
✅ C (open v10-07)               DONE 2026-05-06 (PR #130) · CLOSED 8/8 pt · 20/20 assertions
✅ D (Hermes L3)                 DONE 2026-05-06 (PR #130) · plan.md SCOPED-DEFERRED w/ 3 unblock conditions
```

**Plan exhausted — all forward items handled in this session.**

---

## 7. State snapshot ตอนเขียนแผนนี้ (updated 2026-05-06 post-Item-A)

```
Branch:                 main
Last commit (pre-A):    f46f0a5 docs: post-v12 forward plan handoff (#128)
Open PRs:               0
Human queue:            0 pending / ไม่มีคิวรอ
Working tree:           clean
Roadmap "Current":      sprint-v12-06 (last closed)
Hooks wired on disk:    v11 chain + v12-04 PostToolUse build hook + v12-06 SessionStart staleness ✅
Hooks active in-mem:    next Claude Desktop reload activates v12 hooks (current session still old)
Decision audit:         121 entries · 56 judgment-fallbacks · ready for L2 mine
Pilot:                  kam-tong-ham bootstrapped 2026-05-06 (D-087); awaiting remediate

v9 :  73 / 69  pt  (CLOSED, 100% + stretch)
v10:  39 / 39  pt  (CLOSED, 100%)  + sprint-v10-07 SCOPED 8pt awaiting open
v11:  63 / 63  pt  (CLOSED, 100%)
v12:  39 / 39  pt  (CLOSED, 100%)
─────────────────
total: 214 / 210 pt  (101.9% over-delivered)
```

---

## 8. References

- [`.aegis/brain/sprints/roadmap.md`](../sprints/roadmap.md) — single source of truth for grand total + sprint state
- [`.aegis/brain/sprints/sprint-v10-07/plan.md`](../sprints/sprint-v10-07/plan.md) — detailed L2 design
- [`.aegis/brain/learnings/2026-05-04_aegis-plus-pilot-feedback.md`](../learnings/2026-05-04_aegis-plus-pilot-feedback.md) — full pilot retro w/ F1-F4 signals
- [`tools/aegis-brain-graph/settings-patch.md`](../../tools/aegis-brain-graph/settings-patch.md) — between-session apply instructions
- [`tools/aegis-plus-pilot/remediate.sh`](../../tools/aegis-plus-pilot/remediate.sh) — kam-tong-ham retroactive fixer
- [`~/.claude/projects/-Users-phariyawit-jiap-Documents-AEGIS-Team/memory/feedback_external_access_stays_gated.md`](file:///Users/phariyawit.jiap/.claude/projects/-Users-phariyawit-jiap-Documents-AEGIS-Team/memory/feedback_external_access_stays_gated.md) — saved memory: ทำไม "do them all" ไม่ครอบคลุม External Access

---

**End of plan.** Pick any item, send the trigger phrase, ผมเริ่มทันที
