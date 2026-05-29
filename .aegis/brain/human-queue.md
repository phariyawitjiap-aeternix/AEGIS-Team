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

<!-- PENDING_END -->

---

## ✅ Resolved / แก้ไขแล้ว

<!-- RESOLVED_START -->

### [2026-05-12] EXTERNAL — Decide Linear free-plan cleanup vs upgrade (16 sprints blocked) / ตัดสินใจ Linear free-plan — ล้าง demo projects หรือ upgrade (16 sprints ค้าง)

- **EN**: Linear free plan cap 250 issues/workspace hit during AEGIS-Team back-fill. 50/120 stories synced (19/35 milestones). Blocked sprints: v9-01..06, v10-01/02/08, v12-02..06, v13-01-refactor, v13-02-cleanup. Options: (a) delete 8 unused demo projects in Linear UI to free ~24 slots, (b) delete new-project-99 demo, (c) request free trial from sales@linear.app, (d) accept partial coverage. AEGIS sync code is correct (v3 marker verified 0 collisions) — this is a Linear quota issue, not a code bug.
- **TH**: Linear free plan ชน cap 250 issues ระหว่าง back-fill. ทำได้ 50/120 stories (19/35 milestones). Sprint ที่ยังว่าง: v9-01..06, v10-01/02/08, v12-02..06, v13-01-refactor, v13-02-cleanup. ทางเลือก: (a) ลบ 8 demo projects ใน Linear UI ปลดล็อก ~24 slots, (b) ลบ new-project-99 demo, (c) ติดต่อ sales@linear.app ขอ free trial, (d) รับสภาพปัจจุบัน. โค้ด sync ถูกแล้ว (v3 marker ตรวจสอบแล้ว 0 collisions) — เป็นปัญหา quota ของ Linear ไม่ใช่ bug.
- **Category**: External access
- **Raised by**: claude
- **Blocks**: back-fill 16 remaining sprint milestones in AEGIS-Team Linear project
- **Raised**: 2026-05-12T09:05:37Z
- **Resolved**: 2026-05-13T08:51:15Z — Cleanup done 2026-05-13: deleted 11 demo projects + new-project-99 (12 total, freed 25 active issue slots). User authorized via 'ทั้งหมด' message. Back-fill attempt revealed sync code has a marker-matching bug (creates duplicates from prior-version markers) — separate issue, captured in new learning. Linear quota decision (upgrade or not) is moot for now: AEGIS-Team has 19 milestones synced, which the user accepts.

### [2026-05-07] EXTERNAL — Add shell-footgun-scan to required-status-checks on main / เพิ่ม shell-footgun-scan เข้า required checks ของ main

- **EN**: PR #151 wires aegis-shell-footgun-scan.sh into the lint workflow. Check is registering as 'shell footgun scan (cross-platform bash patterns)' and passing on first run. To make it a hard merge gate (not just advisory), need to PATCH branch protection with the new context name. Run: gh api -X PATCH repos/phariyawitjiap-aeternix/AEGIS-Team/branches/main/protection/required_status_checks --input <full JSON in close-followup commit msg>. This is a separate External Access action from the initial Tier-1 enable already approved.
- **TH**: PR #151 ผูก aegis-shell-footgun-scan เข้า lint workflow แล้ว — check ผ่าน first run แล้ว แต่ตอนนี้เป็น advisory ถ้าจะให้บล็อก merge ต้อง PATCH branch protection เพิ่มชื่อ check เข้า required list (External Access เพิ่มเติม นอกเหนือจาก Tier-1 ครั้งแรก)
- **Category**: External access
- **Raised by**: thor
- **Blocks**: shell-footgun-scan job is currently advisory; will catch new bugs but won't block merge until added to required contexts
- **Raised**: 2026-05-07T16:10:35Z
- **Resolved**: 2026-05-12T19:36:09Z — PATCHed via gh api on 2026-05-13 — added 'shell footgun scan (cross-platform bash patterns)' to required contexts (now 7 required, strict=true). Verified by independent read of /branches/main/protection.
### [2026-05-07] EXTERNAL — Enable Tier-1 branch protection on main / เปิด branch protection (Tier-1) บน main

- **EN**: Per sprint-v13-02 AI-3: main has no protection rules — explains the v13-01 'merge through red CI' pattern that hid the install-v11 brain-graph delivery bug for ~1 month. Run the gh API call in .aegis/brain/sprints/sprint-v13-02-cleanup/ai-3-branch-protection-audit.md to enable Tier-1 (status checks required, no force-push, no main-deletion, admins still allowed override).
- **TH**: ตาม AI-3 ของ sprint-v13-02: main ยังไม่มี protection — อธิบาย pattern 'merge ทั้งที่ CI แดง' ที่ซ่อน bug install-v11 brain-graph เกือบ 1 เดือน — รัน gh API ในไฟล์ ai-3-branch-protection-audit.md เพื่อเปิด Tier-1 (ต้องผ่าน CI, ห้าม force push / ลบ main, admin override ได้)
- **Category**: External access
- **Raised by**: thor
- **Blocks**: future PRs that are CI-flake-merged
- **Raised**: 2026-05-07T14:43:19Z
- **Resolved**: 2026-05-07T16:03:50Z — User approved ("approve") in the same conversation turn that asked about AI-3 specifically — clear by-name go in context. Ran gh API PUT on repos/phariyawitjiap-aeternix/AEGIS-Team/branches/main/protection with Tier-1 config from sprint-v13-02 audit doc. Verified via read-back: required_status_checks (6 contexts) + strict + force-push/delete disabled + enforce_admins=false (allows user override). Branch protection is now live.
### [2026-05-05] EXTERNAL — Bootstrap AEGIS into kam-tong-ham (pilot project) / ติดตั้ง AEGIS ลงใน kam-tong-ham (pilot project)

- **EN**: Day-0 of the v11 Phase-1 pilot week. Runs bash install.sh --target-dir ~/Documents/kam-tong-ham --project-name 'kam-tong-ham' --profile standard. Modifies an external project outside the meta repo — explicit human go required. Once approved, run: bash tools/aegis-plus-pilot/bootstrap.sh ~/Documents/kam-tong-ham
- **TH**: Day-0 ของ pilot week (v11 Phase-1) จะรัน install.sh ใส่ kam-tong-ham — แตะ external project นอก meta repo ต้องได้อนุมัติจากมนุษย์ก่อน เมื่อพร้อมรัน: bash tools/aegis-plus-pilot/bootstrap.sh ~/Documents/kam-tong-ham
- **Category**: External access
- **Raised by**: nick-fury
- **Blocks**: Phase-2 gate measurement (D6 from Mega Plan)
- **Raised**: 2026-05-05T03:32:24Z
- **Resolved**: 2026-05-06T11:46:23Z — User gave imperative 'go' on 2026-05-06. Bootstrap ran successfully — all 4 steps OK, backup at _aegis-backup-20260506-184557, 12 v11 artifacts verified, hooks wired (live-tail + activity-logger), issue prefix set to KAM. Decision D-087.
### [2026-05-01] EXTERNAL — Add Bash(./tests/*) to .claude/settings.json allowlist / เพิ่ม Bash(./tests/*) ใน allowlist ของ .claude/settings.json

- **EN**: Sprint v10-05 Story E moved test harnesses from tools/ to tests/. settings.json allowlist still has 'Bash(./tools/*)' but no 'Bash(./tests/*)'. Without this entry, agents may hit permission prompts when running tests via the new path. guard-write blocks mid-session settings.json edits (ADR-004), so this requires between-session apply: add a single line '"Bash(./tests/*)"' to the permissions.allow array in .claude/settings.json after the existing './tools/*' entry.
- **TH**: Sprint v10-05 Story E ย้าย test harnesses จาก tools/ ไป tests/. settings.json allowlist ยังมี 'Bash(./tools/*)' แต่ยังไม่มี 'Bash(./tests/*)'. ถ้าไม่เพิ่ม, agent อาจจะติด permission prompt ตอนรัน test ผ่าน path ใหม่. guard-write block การแก้ settings.json ระหว่างเซสชัน (ADR-004), ต้องเพิ่มระหว่างเซสชัน: เพิ่มบรรทัด '"Bash(./tests/*)"' ใน permissions.allow array หลัง entry './tools/*' ที่มีอยู่แล้ว.
- **Category**: External access
- **Raised by**: main-agent
- **Blocks**: Test runs from agent context may hit permission prompts until applied
- **Raised**: 2026-05-01T07:52:47Z
- **Resolved**: 2026-05-02T05:39:20Z — Applied via jq one-liner on 2026-05-02: '.permissions.allow |= (. + ["Bash(./tests/*)"] | unique)'. JSON validity confirmed; both './tools/*' and './tests/*' entries present.
### [2026-04-25] EXTERNAL — Apply token-profile hook installer (sprint v10-02 Story A activation) / Apply token-profile hook installer (เปิดใช้งาน Story A ของ v10-02)

- **EN**: Sprint v10-02 shipped tools/aegis-token-profile.sh with --install flag. Wires a PostToolUse hook that records every tool call's category + token estimate to .aegis/brain/metrics/token-profile-<date>.jsonl. Apply between sessions (guard-write blocks mid-session per ADR-004): close Claude Code, run 'bash tools/aegis-token-profile.sh --install', restart. Then use AEGIS normally for >=3 sessions and run 'bash tools/aegis-token-profile.sh --summary' to answer Loki's killshot question (Bash vs Read/Grep/Glob token breakdown). This is a passive, no-risk measurement step. Rollback: 'bash tools/aegis-token-profile.sh --uninstall'.
- **TH**: Sprint v10-02 ส่ง tools/aegis-token-profile.sh พร้อม --install flag แล้ว. เพิ่ม PostToolUse hook ที่บันทึก category + token estimate ทุก tool call ลง .aegis/brain/metrics/token-profile-<date>.jsonl. ติดตั้งระหว่างเซสชัน (guard-write บล็อกระหว่างเซสชัน per ADR-004): ปิด Claude Code, รัน 'bash tools/aegis-token-profile.sh --install', เปิดใหม่. ใช้งาน AEGIS ปกติ >=3 sessions แล้วรัน 'bash tools/aegis-token-profile.sh --summary' เพื่อตอบคำถาม killshot ของ Loki. Passive measurement, ไม่มี risk. Rollback ง่าย: 'bash tools/aegis-token-profile.sh --uninstall'.
- **Category**: External access
- **Raised by**: main-agent
- **Blocks**: Sprint v10-02 Story A is built but not collecting data; Loki's killshot question (Bash vs Read/Grep/Glob %) cannot be answered until hook is active for ≥3 real sessions
- **Raised**: 2026-04-25T05:39:20Z
- **Resolved**: 2026-05-02T05:39:15Z — Installed via 'bash tools/aegis-token-profile.sh --install' on 2026-05-02; PostToolUse hook wired with matcher='.*'. Verified via grep on settings.json. Will collect ≥3 sessions of data before running --summary.
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

Entries live between sentinel comments (`<!-- PENDING_START -->
_No pending items. / ไม่มีคิวรอ._
<!-- PENDING_END --><!-- RESOLVED_START -->

### [2026-05-29] EXPLICIT — Authorize SWE-bench full-500 run (multi-day quota spend) / อนุมัติรัน SWE-bench ครบ 500 ตัว (กิน quota หลายวัน)

- **EN**: Verified result stands at 37/50 on the first-50 subset (astropy+django). A full-500 headline number needs ~450 more agent sessions = days of subscription quota that will throttle your interactive use, plus batched x86 CI eval. DEFERRED by Nick Fury: marginal credibility gain over 37/50 does not justify the multi-day quota spend unprompted. Run only on your explicit go, ideally as a scheduled overnight batch. Trigger when ready: extend predictions via run_agent.py --limit 500, then gh workflow run swe-bench-eval.yml -f count=<batch>.
- **TH**: ตอนนี้ผล verified อยู่ที่ 37/50 (subset 50 ตัวแรก astropy+django) การได้ตัวเลข full-500 ต้องรัน agent อีก ~450 ตัว = กิน quota subscription หลายวัน + ทำให้คุณใช้งาน interactive ช้าลง บวกกับ eval แบบ batch บน x86 CI — Nick Fury ตัดสินว่า 'ยังไม่รัน' เพราะ credibility ที่เพิ่มไม่คุ้มกับ quota หลายวันที่ต้องเสีย รันต่อเมื่อคุณสั่งชัดเจน (ควรเป็น batch ค้างคืน)
- **Category**: Explicit approval gate
- **Raised by**: nick-fury
- **Blocks**: swe-bench full-500 (task #25)
- **Raised**: 2026-05-29T06:46:04Z
- **Resolved**: 2026-05-29T06:51:04Z — User said 'go' 2026-05-29 → authorized. Full-500 agent loop launched in background (run_agent.py --limit 500, does remaining 450). Hardened first: rate-limit/error+empty no longer recorded (left for resume).
### [2026-05-12] EXTERNAL — Decide Linear free-plan cleanup vs upgrade (16 sprints blocked) / ตัดสินใจ Linear free-plan — ล้าง demo projects หรือ upgrade (16 sprints ค้าง)

- **EN**: Linear free plan cap 250 issues/workspace hit during AEGIS-Team back-fill. 50/120 stories synced (19/35 milestones). Blocked sprints: v9-01..06, v10-01/02/08, v12-02..06, v13-01-refactor, v13-02-cleanup. Options: (a) delete 8 unused demo projects in Linear UI to free ~24 slots, (b) delete new-project-99 demo, (c) request free trial from sales@linear.app, (d) accept partial coverage. AEGIS sync code is correct (v3 marker verified 0 collisions) — this is a Linear quota issue, not a code bug.
- **TH**: Linear free plan ชน cap 250 issues ระหว่าง back-fill. ทำได้ 50/120 stories (19/35 milestones). Sprint ที่ยังว่าง: v9-01..06, v10-01/02/08, v12-02..06, v13-01-refactor, v13-02-cleanup. ทางเลือก: (a) ลบ 8 demo projects ใน Linear UI ปลดล็อก ~24 slots, (b) ลบ new-project-99 demo, (c) ติดต่อ sales@linear.app ขอ free trial, (d) รับสภาพปัจจุบัน. โค้ด sync ถูกแล้ว (v3 marker ตรวจสอบแล้ว 0 collisions) — เป็นปัญหา quota ของ Linear ไม่ใช่ bug.
- **Category**: External access
- **Raised by**: claude
- **Blocks**: back-fill 16 remaining sprint milestones in AEGIS-Team Linear project
- **Raised**: 2026-05-12T09:05:37Z
- **Resolved**: 2026-05-13T08:51:15Z — Cleanup done 2026-05-13: deleted 11 demo projects + new-project-99 (12 total, freed 25 active issue slots). User authorized via 'ทั้งหมด' message. Back-fill attempt revealed sync code has a marker-matching bug (creates duplicates from prior-version markers) — separate issue, captured in new learning. Linear quota decision (upgrade or not) is moot for now: AEGIS-Team has 19 milestones synced, which the user accepts.

### [2026-05-07] EXTERNAL — Add shell-footgun-scan to required-status-checks on main / เพิ่ม shell-footgun-scan เข้า required checks ของ main

- **EN**: PR #151 wires aegis-shell-footgun-scan.sh into the lint workflow. Check is registering as 'shell footgun scan (cross-platform bash patterns)' and passing on first run. To make it a hard merge gate (not just advisory), need to PATCH branch protection with the new context name. Run: gh api -X PATCH repos/phariyawitjiap-aeternix/AEGIS-Team/branches/main/protection/required_status_checks --input <full JSON in close-followup commit msg>. This is a separate External Access action from the initial Tier-1 enable already approved.
- **TH**: PR #151 ผูก aegis-shell-footgun-scan เข้า lint workflow แล้ว — check ผ่าน first run แล้ว แต่ตอนนี้เป็น advisory ถ้าจะให้บล็อก merge ต้อง PATCH branch protection เพิ่มชื่อ check เข้า required list (External Access เพิ่มเติม นอกเหนือจาก Tier-1 ครั้งแรก)
- **Category**: External access
- **Raised by**: thor
- **Blocks**: shell-footgun-scan job is currently advisory; will catch new bugs but won't block merge until added to required contexts
- **Raised**: 2026-05-07T16:10:35Z
- **Resolved**: 2026-05-12T19:36:09Z — PATCHed via gh api on 2026-05-13 — added 'shell footgun scan (cross-platform bash patterns)' to required contexts (now 7 required, strict=true). Verified by independent read of /branches/main/protection.
### [2026-05-07] EXTERNAL — Enable Tier-1 branch protection on main / เปิด branch protection (Tier-1) บน main

- **EN**: Per sprint-v13-02 AI-3: main has no protection rules — explains the v13-01 'merge through red CI' pattern that hid the install-v11 brain-graph delivery bug for ~1 month. Run the gh API call in .aegis/brain/sprints/sprint-v13-02-cleanup/ai-3-branch-protection-audit.md to enable Tier-1 (status checks required, no force-push, no main-deletion, admins still allowed override).
- **TH**: ตาม AI-3 ของ sprint-v13-02: main ยังไม่มี protection — อธิบาย pattern 'merge ทั้งที่ CI แดง' ที่ซ่อน bug install-v11 brain-graph เกือบ 1 เดือน — รัน gh API ในไฟล์ ai-3-branch-protection-audit.md เพื่อเปิด Tier-1 (ต้องผ่าน CI, ห้าม force push / ลบ main, admin override ได้)
- **Category**: External access
- **Raised by**: thor
- **Blocks**: future PRs that are CI-flake-merged
- **Raised**: 2026-05-07T14:43:19Z
- **Resolved**: 2026-05-07T16:03:50Z — User approved ("approve") in the same conversation turn that asked about AI-3 specifically — clear by-name go in context. Ran gh API PUT on repos/phariyawitjiap-aeternix/AEGIS-Team/branches/main/protection with Tier-1 config from sprint-v13-02 audit doc. Verified via read-back: required_status_checks (6 contexts) + strict + force-push/delete disabled + enforce_admins=false (allows user override). Branch protection is now live.
### [2026-05-05] EXTERNAL — Bootstrap AEGIS into kam-tong-ham (pilot project) / ติดตั้ง AEGIS ลงใน kam-tong-ham (pilot project)

- **EN**: Day-0 of the v11 Phase-1 pilot week. Runs bash install.sh --target-dir ~/Documents/kam-tong-ham --project-name 'kam-tong-ham' --profile standard. Modifies an external project outside the meta repo — explicit human go required. Once approved, run: bash tools/aegis-plus-pilot/bootstrap.sh ~/Documents/kam-tong-ham
- **TH**: Day-0 ของ pilot week (v11 Phase-1) จะรัน install.sh ใส่ kam-tong-ham — แตะ external project นอก meta repo ต้องได้อนุมัติจากมนุษย์ก่อน เมื่อพร้อมรัน: bash tools/aegis-plus-pilot/bootstrap.sh ~/Documents/kam-tong-ham
- **Category**: External access
- **Raised by**: nick-fury
- **Blocks**: Phase-2 gate measurement (D6 from Mega Plan)
- **Raised**: 2026-05-05T03:32:24Z
- **Resolved**: 2026-05-06T11:46:23Z — User gave imperative 'go' on 2026-05-06. Bootstrap ran successfully — all 4 steps OK, backup at _aegis-backup-20260506-184557, 12 v11 artifacts verified, hooks wired (live-tail + activity-logger), issue prefix set to KAM. Decision D-087.
### [2026-05-01] EXTERNAL — Add Bash(./tests/*) to .claude/settings.json allowlist / เพิ่ม Bash(./tests/*) ใน allowlist ของ .claude/settings.json

- **EN**: Sprint v10-05 Story E moved test harnesses from tools/ to tests/. settings.json allowlist still has 'Bash(./tools/*)' but no 'Bash(./tests/*)'. Without this entry, agents may hit permission prompts when running tests via the new path. guard-write blocks mid-session settings.json edits (ADR-004), so this requires between-session apply: add a single line '"Bash(./tests/*)"' to the permissions.allow array in .claude/settings.json after the existing './tools/*' entry.
- **TH**: Sprint v10-05 Story E ย้าย test harnesses จาก tools/ ไป tests/. settings.json allowlist ยังมี 'Bash(./tools/*)' แต่ยังไม่มี 'Bash(./tests/*)'. ถ้าไม่เพิ่ม, agent อาจจะติด permission prompt ตอนรัน test ผ่าน path ใหม่. guard-write block การแก้ settings.json ระหว่างเซสชัน (ADR-004), ต้องเพิ่มระหว่างเซสชัน: เพิ่มบรรทัด '"Bash(./tests/*)"' ใน permissions.allow array หลัง entry './tools/*' ที่มีอยู่แล้ว.
- **Category**: External access
- **Raised by**: main-agent
- **Blocks**: Test runs from agent context may hit permission prompts until applied
- **Raised**: 2026-05-01T07:52:47Z
- **Resolved**: 2026-05-02T05:39:20Z — Applied via jq one-liner on 2026-05-02: '.permissions.allow |= (. + ["Bash(./tests/*)"] | unique)'. JSON validity confirmed; both './tools/*' and './tests/*' entries present.
### [2026-04-25] EXTERNAL — Apply token-profile hook installer (sprint v10-02 Story A activation) / Apply token-profile hook installer (เปิดใช้งาน Story A ของ v10-02)

- **EN**: Sprint v10-02 shipped tools/aegis-token-profile.sh with --install flag. Wires a PostToolUse hook that records every tool call's category + token estimate to .aegis/brain/metrics/token-profile-<date>.jsonl. Apply between sessions (guard-write blocks mid-session per ADR-004): close Claude Code, run 'bash tools/aegis-token-profile.sh --install', restart. Then use AEGIS normally for >=3 sessions and run 'bash tools/aegis-token-profile.sh --summary' to answer Loki's killshot question (Bash vs Read/Grep/Glob token breakdown). This is a passive, no-risk measurement step. Rollback: 'bash tools/aegis-token-profile.sh --uninstall'.
- **TH**: Sprint v10-02 ส่ง tools/aegis-token-profile.sh พร้อม --install flag แล้ว. เพิ่ม PostToolUse hook ที่บันทึก category + token estimate ทุก tool call ลง .aegis/brain/metrics/token-profile-<date>.jsonl. ติดตั้งระหว่างเซสชัน (guard-write บล็อกระหว่างเซสชัน per ADR-004): ปิด Claude Code, รัน 'bash tools/aegis-token-profile.sh --install', เปิดใหม่. ใช้งาน AEGIS ปกติ >=3 sessions แล้วรัน 'bash tools/aegis-token-profile.sh --summary' เพื่อตอบคำถาม killshot ของ Loki. Passive measurement, ไม่มี risk. Rollback ง่าย: 'bash tools/aegis-token-profile.sh --uninstall'.
- **Category**: External access
- **Raised by**: main-agent
- **Blocks**: Sprint v10-02 Story A is built but not collecting data; Loki's killshot question (Bash vs Read/Grep/Glob %) cannot be answered until hook is active for ≥3 real sessions
- **Raised**: 2026-04-25T05:39:20Z
- **Resolved**: 2026-05-02T05:39:15Z — Installed via 'bash tools/aegis-token-profile.sh --install' on 2026-05-02; PostToolUse hook wired with matcher='.*'. Verified via grep on settings.json. Will collect ≥3 sessions of data before running --summary.
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

Entries live between sentinel comments (`<!-- PENDING_START -->` / `

### [2026-05-29] EXPLICIT — Authorize SWE-bench full-500 run (multi-day quota spend) / อนุมัติรัน SWE-bench ครบ 500 ตัว (กิน quota หลายวัน)

- **EN**: Verified result stands at 37/50 on the first-50 subset (astropy+django). A full-500 headline number needs ~450 more agent sessions = days of subscription quota that will throttle your interactive use, plus batched x86 CI eval. DEFERRED by Nick Fury: marginal credibility gain over 37/50 does not justify the multi-day quota spend unprompted. Run only on your explicit go, ideally as a scheduled overnight batch. Trigger when ready: extend predictions via run_agent.py --limit 500, then gh workflow run swe-bench-eval.yml -f count=<batch>.
- **TH**: ตอนนี้ผล verified อยู่ที่ 37/50 (subset 50 ตัวแรก astropy+django) การได้ตัวเลข full-500 ต้องรัน agent อีก ~450 ตัว = กิน quota subscription หลายวัน + ทำให้คุณใช้งาน interactive ช้าลง บวกกับ eval แบบ batch บน x86 CI — Nick Fury ตัดสินว่า 'ยังไม่รัน' เพราะ credibility ที่เพิ่มไม่คุ้มกับ quota หลายวันที่ต้องเสีย รันต่อเมื่อคุณสั่งชัดเจน (ควรเป็น batch ค้างคืน)
- **Category**: Explicit approval gate
- **Raised by**: nick-fury
- **Blocks**: swe-bench full-500 (task #25)
- **Raised**: 2026-05-29T06:46:04Z
- **Resolved**: _(pending)_
<!-- PENDING_END -->` and `<!-- RESOLVED_START -->` / `<!-- RESOLVED_END -->`) so the helper scripts can safely insert/move without disturbing the surrounding intro/format text.
