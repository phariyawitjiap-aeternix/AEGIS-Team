# 👤 Human Action Queue — คิวงานที่ต้องการ human

> **Single source of truth for things agents cannot decide alone.**
> **ที่เดียวสำหรับเรื่องที่ agent ตัดสินเองไม่ได้**

Only 4 categories (per MBP / Golden Rule #7) ever reach this queue. Anything
else is routed through Nick Fury, not handed to the human.

มีแค่ 4 หมวด (ตาม MBP / Golden Rule #7) เท่านั้นที่เข้าคิวนี้ได้ —
นอกเหนือจากนี้ Nick Fury ตัดสินเอง ไม่รบกวน human.

| Category | หมวด | Example / ตัวอย่าง |
|---|---|---|
| **Identity** | อัตลักษณ์ | "What is this project?" on empty repo / "โปรเจคนี้คืออะไร" บน repo เปล่า |
| **Irreversible scope** | ย้อนไม่ได้ | Permanent delete, force-push to main / ลบถาวร, force push ไป main |
| **External access** | เข้าถึงภายนอก | API keys, credentials, prod access / คีย์ API, credentials, prod |
| **Explicit approval gate** | อนุมัติก่อนปล่อย | Production deploy sign-off / อนุมัติ deploy prod |

## Surfacing / จุดแสดงผล

This queue surfaces in four places automatically:
คิวนี้จะโผล่อัตโนมัติที่ 4 ที่:

- `/aegis-start` — at session load (if pending count > 0) / เริ่ม session (ถ้ามี pending)
- `/aegis-status` — pending count in dashboard / count ใน dashboard
- `/aegis-handoff` — auto-embedded in next-session handoff / ฝังใน handoff เซสชันถัดไป
- `on-stop.sh` hook — bilingual banner at session end (if pending) / banner สองภาษาตอนจบเซสชัน

Any agent may read `.aegis/brain/human-queue.md` directly.
Agent ตัวไหนอ่านไฟล์นี้ตรงก็ได้

## Tools / เครื่องมือ

- `tools/aegis-queue-human.sh` — append a new pending entry / เพิ่ม entry ใหม่ใน pending
- `tools/aegis-queue-resolve.sh` — mark a pending entry resolved / mark resolved

---

## 🔔 Pending / รอดำเนินการ

<!-- PENDING_START -->
_No pending items. / ไม่มีคิวรอ._
<!-- PENDING_END -->

---

## ✅ Resolved / แก้ไขแล้ว

<!-- RESOLVED_START -->

### [2026-04-24] EXTERNAL — Prune stale ~/.claude/tasks/aegis-shared-tasks/ once all AEGIS projects are migrated / ลบ ~/.claude/tasks/aegis-shared-tasks/ ที่ค้าง หลัง AEGIS projects ทั้งหมดย้ายเรียบร้อย

- **EN**: After upgrading AEGIS-Team, DriveWiki-MCP, and RizzLab to the per-project task-list-ID (PR #70), verify each now writes to its own aegis-tasks-<slug>/ directory. Then remove the old shared dir: rm -rf ~/.claude/tasks/aegis-shared-tasks/. This purges the 44 cross-contaminated tasks including the recurring 'Cloud Build GitHub triggers' ghost. Safe only AFTER all 3 projects have been upgraded + verified.
- **TH**: หลังจาก upgrade AEGIS-Team, DriveWiki-MCP, RizzLab ด้วย per-project task-list-ID (PR #70), ตรวจว่าทั้ง 3 projects เขียนเข้า aegis-tasks-<slug>/ ของตัวเองแล้ว จึงลบ ~/.claude/tasks/aegis-shared-tasks/ ทิ้ง. จะลบ task ที่ปนกัน 44 รายการรวมถึง 'Cloud Build GitHub triggers' ที่โผล่เรื่อยๆ. ปลอดภัยเฉพาะเมื่อ upgrade ทุก project แล้วเท่านั้น.
- **Category**: External access
- **Raised by**: main-agent
- **Blocks**: Cross-project task ghosts will keep appearing in any project still reading from the shared list
- **Raised**: 2026-04-24T12:06:03Z
- **Resolved**: 2026-04-24T12:41:14Z — Directory already gone. All 5 projects migrated to aegis-tasks-<slug>/ isolation. No prune needed.
### [2026-04-24] EXTERNAL — Apply hook-path fix: anchor .claude/settings.json hooks to $CLAUDE_PROJECT_DIR / Apply hook-path fix: anchor hook ใน .claude/settings.json ให้ใช้ $CLAUDE_PROJECT_DIR

- **EN**: Root cause of the recurring Stop hook error ('bash: .claude/hooks/run-with-flags.sh: No such file or directory'): hook commands in .claude/settings.json use RELATIVE paths. When a sub-agent or background process fires a hook from a cwd that is not the repo root, bash cannot resolve the path. Fix: close Claude Code, run 'bash tools/aegis-fix-hook-paths.sh', restart Claude Code. guard-write.sh blocks mid-session edits to settings.json (ADR-004), so this cannot run from inside the current session.
- **TH**: สาเหตุของ Stop hook error ที่เกิดเรื่อยๆ: hook ใน .claude/settings.json ใช้ relative path. พอ sub-agent หรือ background process ยิง hook จาก cwd ที่ไม่ใช่ repo root, bash หาไฟล์ไม่เจอ. วิธีแก้: ปิด Claude Code, รัน 'bash tools/aegis-fix-hook-paths.sh', แล้วเปิดใหม่. guard-write.sh บล็อกการแก้ settings.json ระหว่างเซสชัน (ADR-004).
- **Category**: External access
- **Raised by**: main-agent
- **Blocks**: Stop hooks silently failing every session; retro logging + false-ready detection degraded until fix applied
- **Raised**: 2026-04-24T11:25:56Z
- **Resolved**: 2026-04-24T12:41:14Z — Applied to all 5 AEGIS projects (AEGIS-Team self-fix + 4 upgraded via /aegis-upgrade). 0 relative-path hooks across all projects.
### [2026-04-24] IDENTITY — v9 roadmap complete -- what should AEGIS do next? / v9 roadmap เสร็จสมบูรณ์ -- AEGIS จะทำอะไรต่อ?

- **EN**: AEGIS v9 in-repo roadmap is 100% complete (62/58pt shipped across 5 sprints). Three paths forward: (A) Open sprint-v9-06 for 11pt operational debt (flock atomicity, test-harness UX, policy-without-test audit, hook-governance ADR). (B) Pivot to SDK-adjacent prep (brain-tier architecture for v9-07/08/09 when SDK features land). (C) Start a new project/epic using the AEGIS framework on a real codebase. The framework is production-ready.
- **TH**: AEGIS v9 in-repo roadmap เสร็จ 100% (62/58pt ส่งครบใน 5 sprints) มี 3 ทางเลือก: (A) เปิด sprint-v9-06 สำหรับ operational debt 11pt (B) เตรียม brain-tier architecture สำหรับ v9-07/08/09 (C) เริ่มโปรเจคใหม่โดยใช้ AEGIS framework บน codebase จริง Framework พร้อมใช้งานแล้ว
- **Category**: Identity
- **Raised by**: nick-fury
- **Blocks**: Next sprint planning -- cannot open a sprint without knowing direction
- **Raised**: 2026-04-24T05:18:21Z
- **Resolved**: 2026-04-24T06:21:12Z — user replied A+B+C continuously -- execute all three in sequence autonomously (D-059)
### [2026-04-22] EXTERNAL — Apply MBP settings patch / Apply settings.json layer 2

- **EN**: Run `bash tools/aegis-apply-mbp-guard.sh` between sessions to activate the `guard-ask-user` PreToolUse hook at the tool layer. Required because `guard-write.sh` blocks mid-session edits to `settings.json` (ADR-004).
- **TH**: รัน `bash tools/aegis-apply-mbp-guard.sh` ระหว่างเซสชันเพื่อเปิด hook `guard-ask-user` ที่ tool layer. จำเป็นเพราะ `guard-write.sh` ล็อก `settings.json` กลางเซสชัน (ADR-004).
- **Category**: External access (settings file grant)
- **Raised by**: main agent (MBP fix PR #20)
- **Raised**: 2026-04-22T07:24Z
- **Resolved**: 2026-04-22T08:58Z — user applied, auto-committed in PR #27

<!-- RESOLVED_END -->

---

## Format / รูปแบบ

When adding an entry, use `tools/aegis-queue-human.sh`. Manually, the template is:

```markdown
### [YYYY-MM-DD] CATEGORY — <english-title> / <thai-title>

- **EN**: <1-2 sentence description with concrete ask>
- **TH**: <คำอธิบาย 1-2 ประโยค พร้อมสิ่งที่ต้องการให้ทำ>
- **Category**: Identity | Irreversible scope | External access | Explicit approval gate
- **Raised by**: <agent-name>
- **Blocks**: <what is waiting / อะไรรออยู่>
- **Raised**: <ISO-8601 timestamp>
- **Resolved**: _(pending)_
```

Entries live between sentinel comments (`<!-- PENDING_START -->` / `<!-- PENDING_END -->` and `<!-- RESOLVED_START -->` / `<!-- RESOLVED_END -->`) so the helper scripts can safely insert/move without disturbing the surrounding intro/format text.
