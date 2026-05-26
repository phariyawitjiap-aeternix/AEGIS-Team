# Super Spec: aegis-autopilot

> Non-stop execution wrapper — ให้ AEGIS ทำงานต่อเนื่องไม่ต้องรอคนกด /aegis-start

**Version:** 1.1.0
**Date:** 2026-05-27
**Author:** Sage (📐) + Beast (🔍 research)
**Reviewed by:** Loki (adversarial) + War Machine (QA)
**Status:** REVIEWED — post-review revision applied

### Review Disposition (v1.1.0)

| Finding | Severity | Resolution |
|---------|----------|------------|
| Stall detection deferred to v1.1 | CRITICAL | **Moved to v1** — git diff delta check between sessions |
| jq optional | CRITICAL | **jq now REQUIRED** — refuse to run without it |
| No session timeout | CRITICAL | **Added** — `timeout` command wraps claude -p |
| bypassPermissions allowed | HIGH | **Blocked in v1** — only default/acceptEdits/auto |
| No per-session cost ceiling | HIGH | **Added** — pass --max-turns to claude |
| Handoff race condition | HIGH | **Fixed** — poll for new handoff with 5s timeout |
| Float math without bc | HIGH | **Fixed** — use jq for all float arithmetic |
| SIGINT during JSON parse | MEDIUM | Deferred exit until parse+log complete |
| project-complete check timing | MEDIUM | Check after session, not before next |
| Handoff truncation loses frontmatter | MEDIUM | Truncate from middle, keep head+tail |

---

## 1. Context Recap & Assumptions

### Brief ที่ได้รับ

aegis-autopilot — shell script wrapper ที่ loop Claude Code headless sessions ให้ AEGIS ทำงาน non-stop เหมือน Codex Desktop / Antigravity 2 โดยอ่าน handoff briefs เพื่อ resume work อัตโนมัติ หยุดเมื่อ project-complete หรือ budget หมด

### Parsed Fields

| Field | Value | Source |
|-------|-------|--------|
| `product_keyword` | aegis-autopilot | Provided |
| `domain` | Developer tooling / AI agent orchestration | Inferred |
| `target_users` | AEGIS users ที่ต้องการ autonomous execution | Provided |
| `primary_goals` | ลบ human bottleneck ระหว่าง sessions | Provided |
| `tech_constraints` | Bash script, claude -p headless, macOS + Linux | Provided |
| `product_stage` | MVP (v1 — ใส่ใน AEGIS v15.2) | Inferred |
| `research_depth` | Normal (completed) | Done |

### Key Assumptions [ASSUMED]

- A1: Claude Code CLI v2.1.128+ ติดตั้งอยู่แล้ว (มี `-p`, `--output-format json`, `--resume`)
- A2: `.aegis/brain/handoffs/` มี handoff files ในรูปแบบ markdown+frontmatter ที่ AEGIS สร้างจาก `/aegis-handoff`
- A3: ผู้ใช้มี API key/credits เพียงพอ (ไม่ใช่หน้าที่ autopilot จัดการ billing)
- A4: Project มี `.claude/settings.json` + `CLAUDE.md` ที่ install แล้ว

---

## 2. Research Insights & Feature Landscape

### Industry Patterns (จาก research)

| Pattern | ใช้โดย | วิธีการ |
|---------|--------|---------|
| **Ralph Loop** | Aider, modern agents | Fresh context ทุกรอบ + filesystem memory + explicit cost/step bounds |
| **Session resume** | Claude Code | `--resume <session_id>` หรือ `--continue` สำหรับ session เดิม |
| **Coordinator-specialist** | AI SDK | Lean coordinator + scoped specialists ป้องกัน context buildup |
| **Step limit** | AI SDK, Codex | Default 20-step cap ป้องกัน runaway |

### Claude Code Headless Capabilities (verified)

| Flag | Purpose |
|------|---------|
| `-p "prompt"` | Non-interactive mode |
| `--output-format json` | Returns `{total_cost_usd, session_id, terminal_reason, stop_reason, num_turns}` |
| `--continue` | Resume most recent session in current directory |
| `--resume <id>` | Resume specific session by ID |
| `--permission-mode acceptEdits` | Auto-approve Edit/Write, prompt for Bash |
| `--permission-mode bypassPermissions` | Auto-approve everything (dangerous) |
| `--allowedTools "..."` | Whitelist specific tools |

### Key Finding

> **`--max-budget-usd` ไม่มีจริง** — cost tracking ต้องทำเองจาก `total_cost_usd` ใน JSON output

### Feature Landscape

#### Must-Have (v1)

| Feature | Reason | Reference |
|---------|--------|-----------|
| Headless session loop | Core value — ลบ human bottleneck | Ralph Loop pattern |
| Handoff-based context resume | State continuity ระหว่าง sessions | AEGIS handoff system |
| Budget cap (cumulative USD) | Cost runaway prevention | AI SDK step limit pattern |
| Max iteration cap | Infinite loop prevention | AI SDK default 20 |
| Session logging | Audit trail + debugging | AEGIS activity logger |
| Graceful interrupt (Ctrl+C) | Human override | Standard |
| Completion detection | รู้ว่าเสร็จแล้วหยุด | Project-complete signal file |

#### Nice-to-Have (v1.1)

| Feature | Reason | Risk if Skipped |
|---------|--------|----------------|
| Telegram/webhook notification | แจ้งเตือนเมื่อจบ/error | ต้อง poll ด้วยตาเอง |
| Resume from specific session | ย้อน resume session เก่า | ต้อง continue ล่าสุดเท่านั้น |
| Advanced stall heuristics | Task completion rate, repeated error patterns | Basic git-diff stall covers 80% |

#### Not Recommended (v1)

| Feature | Why Not |
|---------|---------|
| GUI/Desktop app | Scope explosion — เป็น shell tool |
| Multi-project orchestration | ซับซ้อน, ใช้ tmux แทน |
| Auto-billing management | ไม่ใช่หน้าที่, security risk |

---

## 3. Super System Analysis

### Stakeholders & Roles

| Stakeholder | Role | Needs |
|------------|------|-------|
| AEGIS User (Developer) | ผู้สั่งงาน | สั่งครั้งเดียว ไปนอน กลับมาเช้าเจองานเสร็จ |
| Nick Fury (AI) | Autonomous controller | Context จาก handoff, permission ที่พร้อม, budget ที่ชัดเจน |
| Captain America (AI) | Session orchestrator | Handoff ที่สมบูรณ์พอ resume ได้ |

### Key User Journey

```
User รัน: ./tools/aegis-autopilot.sh --budget 10 --max-iterations 20

  ┌──► [1] อ่าน latest handoff (หรือ initial prompt)
  │    [2] สร้าง prompt: "Resume from handoff + /aegis-start"
  │    [3] รัน: claude -p "$PROMPT" --output-format json --permission-mode acceptEdits
  │    [4] Session ทำงาน... (minutes to hours)
  │    [5] Session จบ → parse JSON output
  │    [6] สะสม cost, log session, เช็ค exit conditions
  │    [7] Exit conditions:
  │         ├─ project-complete signal? → EXIT SUCCESS
  │         ├─ budget exceeded?        → EXIT BUDGET
  │         ├─ max iterations?         → EXIT MAX_ITER
  │         ├─ consecutive failures?   → EXIT ERROR
  │         └─ else                    → LOOP ──┐
  └─────────────────────────────────────────────┘
```

### System Context

```
┌─────────────────────────────────────────────────┐
│  aegis-autopilot.sh (bash loop)                 │
│                                                 │
│  Reads:                                         │
│  ├── .aegis/brain/handoffs/*.md                 │
│  ├── .aegis/brain/state/project-complete.json   │
│  ├── .claude/settings.json (permission config)  │
│  │                                              │
│  Writes:                                        │
│  ├── .aegis/brain/logs/autopilot.log            │
│  ├── .aegis/brain/logs/autopilot-sessions.jsonl │
│  │                                              │
│  Invokes:                                       │
│  └── claude -p (headless Claude Code sessions)  │
│       └── AEGIS framework (/aegis-start, etc.)  │
└─────────────────────────────────────────────────┘
```

### Data Entities

| Entity | Format | Purpose |
|--------|--------|---------|
| Handoff Brief | Markdown + YAML frontmatter | Context for session resume |
| Session Result | JSON (claude -p output) | Cost, turns, terminal_reason, session_id |
| Autopilot Log | Append-only text | Human-readable audit trail |
| Sessions JSONL | One JSON object per session | Machine-readable session history |
| Project Complete | JSON flag file | Stop signal |

### Non-Functional Requirements

| Category | Requirement | Target |
|----------|-------------|--------|
| NFR-COMPAT-01 | Platform | macOS (zsh/bash) + Linux (bash) |
| NFR-COMPAT-02 | Claude Code version | ≥ 2.1.128 |
| NFR-SAFE-01 | Budget cap accuracy | ± $0.50 (checked per-session, not per-token) |
| NFR-SAFE-02 | Interrupt response | Ctrl+C propagates SIGINT to claude within 2s |
| NFR-SAFE-03 | Max consecutive failures | 3 (default, configurable) |
| NFR-LOG-01 | Log rotation | One log file per autopilot run (timestamped) |
| NFR-PERF-01 | Cooldown between sessions | 10s default (configurable, prevents rate limit) |
| NFR-ZERO-01 | Minimal external dependencies | Pure bash + jq (REQUIRED) + timeout (coreutils) |
| NFR-SAFE-04 | Session timeout | Each claude -p session hard-capped at 30min default (configurable) |
| NFR-SAFE-05 | Stall detection | Zero git-diff-delta on 2 consecutive completed sessions → STALL exit |
| NFR-SAFE-06 | Permission mode restriction | bypassPermissions blocked in v1; only default/acceptEdits/auto |

---

## 4. BRD — Business Requirements

### Problem Statement

AEGIS users ต้องกด `/aegis-start` ทุกครั้งที่ session ใหม่ — สร้าง bottleneck ที่คนไม่ได้อยู่หน้าจอ ทำให้ agent ทำงานได้เฉพาะตอนคนนั่งดู ขณะที่ Codex Desktop, Antigravity 2, Cursor Cloud Agent ทำงาน non-stop ได้แล้ว ความเสียเปรียบนี้ทำให้ AEGIS ไม่เหมาะกับงาน overnight / long-running

### Business Goals & KPIs

| Goal | KPI | Target |
|------|-----|--------|
| ลบ human bottleneck | Session transitions ที่ไม่ต้องคนกด | 100% (zero human intervention) |
| Cost safety | Budget overrun incidents | 0 (never exceed declared budget) |
| Reliability | Sessions ที่ resume สำเร็จ | > 90% |
| Competitive parity | Feature gap vs Codex non-stop | ปิดใน v1 |

### In-Scope (v1)

- BR-LOOP-01: วน claude -p sessions อัตโนมัติจนกว่าจะเสร็จ
- BR-HAND-01: อ่าน latest handoff brief เป็น context สำหรับ session ถัดไป
- BR-COST-01: หยุดเมื่อ cumulative cost เกิน budget ที่กำหนด
- BR-ITER-01: หยุดเมื่อถึง max iterations
- BR-DONE-01: หยุดเมื่อ project-complete signal ถูกเขียน
- BR-FAIL-01: หยุดเมื่อ consecutive failures เกิน threshold
- BR-INT-01: Ctrl+C หยุดทันที, บันทึก state
- BR-LOG-01: Log ทุก session (cost, turns, duration, terminal_reason)
- BR-PERM-01: ใช้ permission mode ที่ user กำหนด (default: acceptEdits)

### Out-of-Scope (v1)

- GUI / desktop app
- Multi-project orchestration
- Billing / API key management
- Stall detection (v1.1)
- Notification webhooks (v1.1)
- Windows support (ไม่มี claude CLI บน Windows native)

### Business Risks & Assumptions

| # | Type | Description | Mitigation |
|---|------|-------------|-----------|
| R1 | Risk | Cost runaway ถ้า budget check ผิด | Parse `total_cost_usd` from JSON, fail-safe: stop on parse error |
| R2 | Risk | Agent วนไม่ progress (stall) | v1: max iterations cap / v1.1: stall detection |
| R3 | Risk | Handoff ไม่สมบูรณ์พอ resume | ใช้ `/aegis-start` ซึ่ง scan project state เองอยู่แล้ว |
| R4 | Risk | Claude API outage mid-loop | Retry with backoff, max 3 consecutive failures |
| A1 | Assumption | Claude -p output format stable | Pin to `--output-format json`, test in CI |
| A2 | Assumption | Handoff files อยู่ใน `.aegis/brain/handoffs/` | AEGIS convention, enforced by `/aegis-handoff` |

---

## 5. SRS — Functional Requirements

### Module: CORE (Loop Engine)

| ID | Requirement | Input | Output | Precondition | Postcondition |
|----|------------|-------|--------|-------------|---------------|
| FR-CORE-01 | Parse CLI arguments | flags + values | Config object | Script invoked | Config validated |
| FR-CORE-02 | Find latest handoff | `.aegis/brain/handoffs/` | Handoff content string | Directory exists | Handoff loaded or initial prompt used |
| FR-CORE-03 | Build session prompt | Handoff + instructions | Prompt string | Handoff loaded | Prompt ready |
| FR-CORE-04 | Execute claude -p session | Prompt + flags | JSON result | Claude CLI available | Session result parsed |
| FR-CORE-05 | Parse session result | JSON string | Struct: cost, turns, reason, session_id | Valid JSON | Fields extracted |
| FR-CORE-06 | Accumulate cost | Session cost + running total | New total | Previous total exists | Total updated |
| FR-CORE-07 | Check exit conditions | Config + state | CONTINUE or EXIT(reason) | State current | Decision made |
| FR-CORE-08 | Log session | Session result + metadata | Log entries | Log file writable | Entries appended |
| FR-CORE-09 | Handle SIGINT | Ctrl+C signal | Graceful shutdown | Session running | Current session interrupted, state saved |
| FR-CORE-10 | Cooldown between sessions | Config delay | Sleep | Session just ended | Delay applied |

### CLI Arguments

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--budget` | float | 5.00 | Max cumulative USD spend |
| `--max-iterations` | int | 10 | Max session loops |
| `--max-failures` | int | 3 | Consecutive failures before abort |
| `--cooldown` | int | 10 | Seconds between sessions |
| `--permission-mode` | string | acceptEdits | Claude permission mode (default/acceptEdits/auto only; bypassPermissions blocked) |
| `--max-turns` | int | 200 | Max turns per claude session |
| `--session-timeout` | int | 1800 | Max seconds per session (default 30min) |
| `--stall-threshold` | int | 2 | Consecutive zero-delta sessions before STALL exit |
| `--allowed-tools` | string | (none) | Tool whitelist (passed to claude) |
| `--initial-prompt` | string | (none) | Override first-session prompt (instead of handoff) |
| `--project-dir` | path | pwd | Target project directory |
| `--dry-run` | flag | false | Print what would run, don't execute |
| `--verbose` | flag | false | Print session JSON to stdout |
| `-h, --help` | flag | — | Show usage |

### Prompt Template

Session 1 (initial — no handoff available หรือ `--initial-prompt` กำหนด):
```
You are resuming autonomous work on this project.
Run /aegis-start to initialize the session, then continue working on the current plan.
When you finish all planned work or exhaust context, run /aegis-handoff to save state.
If the project is fully complete, create .aegis/brain/state/project-complete.json with {"complete": true, "reason": "..."}.
```

Session N (with handoff):
```
You are resuming autonomous work. Here is the handoff from the previous session:

---
<handoff content>
---

Run /aegis-start to initialize, then continue from where the previous session left off.
When you finish all planned work or exhaust context, run /aegis-handoff to save state.
If the project is fully complete, create .aegis/brain/state/project-complete.json with {"complete": true, "reason": "..."}.
```

### Exit Conditions (priority order)

| Priority | Condition | Exit Code | Message |
|----------|-----------|-----------|---------|
| P0 | SIGINT (Ctrl+C) | 130 | "Interrupted by user" |
| P1 | `project-complete.json` exists with `complete: true` | 0 | "Project complete: {reason}" |
| P2 | Cumulative cost ≥ budget | 2 | "Budget exhausted: ${total} / ${budget}" |
| P3 | Iteration count ≥ max-iterations | 3 | "Max iterations reached: {n}/{max}" |
| P4 | Consecutive failures ≥ max-failures | 1 | "Too many consecutive failures: {n}" |
| P5 | Stall detected (zero git delta N consecutive sessions) | 4 | "Stall detected: {n} sessions with no changes" |
| P6 | Session timeout exceeded | 5 | "Session timed out after {timeout}s" |
| P7 | None of the above | — | Continue loop |

### Session Result Parsing

จาก `claude -p --output-format json`:
```json
{
  "total_cost_usd": 0.262,      // ← สะสมเข้า cumulative
  "session_id": "uuid",          // ← log for resume
  "terminal_reason": "completed", // ← completed | max_turns | interrupted
  "stop_reason": "end_turn",     // ← end_turn | tool_use | max_tokens
  "num_turns": 42                // ← log for metrics
}
```

**Failure detection:** `terminal_reason` ≠ "completed" AND ไม่ใช่ context exhaustion ปกติ → increment failure counter

### Validation Rules

- `--budget`: > 0, ≤ 1000 (hard cap safety)
- `--max-iterations`: > 0, ≤ 100
- `--cooldown`: ≥ 0, ≤ 300
- `--permission-mode`: one of `default`, `acceptEdits`, `auto` (bypassPermissions BLOCKED in v1)
- `--project-dir`: must exist and contain `CLAUDE.md`

---

## 6. UX Blueprint (CLI UX)

### Terminal Output Design

```
╔══════════════════════════════════════════════════════╗
║  🤖 AEGIS Autopilot v1.0.0                          ║
║  Budget: $10.00 | Max iterations: 20                 ║
║  Project: /path/to/project                           ║
║  Permission: acceptEdits                             ║
║  Press Ctrl+C to interrupt                           ║
╚══════════════════════════════════════════════════════╝

── Session 1/20 ─────────────────────────────────────────
   Prompt: Resuming from handoff 2026-05-27-sprint-close.md
   Started: 14:32:05
   ...running... (claude -p output streamed if --verbose)
   Finished: 14:47:22 (15m 17s)
   Cost: $1.23 | Turns: 42 | Reason: completed
   Cumulative: $1.23 / $10.00 (12.3%)

── Session 2/20 ─────────────────────────────────────────
   Cooldown: 10s...
   Prompt: Resuming from handoff 2026-05-27-session-2.md
   Started: 14:47:32
   ...running...
   Finished: 15:02:11 (14m 39s)
   Cost: $1.45 | Turns: 38 | Reason: completed
   Cumulative: $2.68 / $10.00 (26.8%)

...

══ Autopilot Complete ═══════════════════════════════════
   Reason: Project complete — all sprint tasks done
   Sessions: 7 | Total cost: $8.42 | Total time: 1h 47m
   Log: .aegis/brain/logs/autopilot-20260527-143205.log
```

### Error States

| State | Display |
|-------|---------|
| Claude CLI not found | `❌ Error: claude CLI not found. Install: https://claude.ai/download` |
| No CLAUDE.md | `❌ Error: No CLAUDE.md found in {dir}. Is this an AEGIS project?` |
| API error | `⚠️ Session failed (attempt {n}/{max}): {error}. Retrying in {cooldown}s...` |
| Budget hit | `💰 Budget exhausted: $10.00 / $10.00. Stopping.` |
| Max iterations | `🔄 Max iterations reached (20/20). Stopping.` |
| Ctrl+C | `⛔ Interrupted. State saved. Resume with: ./tools/aegis-autopilot.sh --continue` |

---

## 7. PBIs (Product Backlog Items)

### Epic: AUTOPILOT-CORE

#### PBI-001: CLI Argument Parser
**Story:** As an AEGIS user, I want to configure autopilot with flags so that I can set budget, iterations, and permissions.

**AC:**
1. Given `--budget 10`, when parsed, then budget=10.00
2. Given `--budget -5`, when parsed, then error "Budget must be > 0"
3. Given `--budget 2000`, when parsed, then error "Budget must be ≤ 1000"
4. Given no flags, when parsed, then defaults applied (budget=5, max-iter=10, etc.)
5. Given `--help`, when invoked, then usage printed, exit 0
6. Given `--dry-run`, when invoked, then print config + first prompt, exit 0

**DEV Notes:**
- Pure bash, `getopts` or manual while-case loop
- Validate all inputs before entering main loop
- Print parsed config as banner

---

#### PBI-002: Handoff Reader
**Story:** As the autopilot loop, I need to find and read the latest handoff brief so that the next session has context.

**AC:**
1. Given handoff files in `.aegis/brain/handoffs/`, when reading, then return the newest file by filename (date-sorted)
2. Given no handoff files, when reading, then use default initial prompt
3. Given `--initial-prompt "custom"`, when first session, then use custom prompt instead of handoff
4. Given handoff > 50KB, when reading, then truncate to last 50KB with warning

**DEV Notes:**
- `ls -t .aegis/brain/handoffs/*.md | head -1`
- Read file content into variable
- Inject into prompt template

---

#### PBI-003: Session Executor
**Story:** As the autopilot loop, I need to execute a claude -p session and capture the structured result.

**AC:**
1. Given valid prompt, when executing, then `claude -p "$PROMPT" --output-format json --permission-mode $MODE` runs
2. Given `--allowed-tools` set, then `--allowedTools` flag passed to claude
3. Given session completes, then JSON output parsed for: total_cost_usd, session_id, terminal_reason, num_turns
4. Given JSON parse fails, then treated as failure (increment failure counter)
5. Given `--verbose`, then also stream output to stdout

**DEV Notes:**
- Capture stdout to variable: `result=$(claude -p ... 2>/dev/null)`
- Parse with jq if available, fallback to grep/sed
- Redirect stderr to log file

---

#### PBI-004: Cost Tracker & Budget Gate
**Story:** As the autopilot loop, I need to track cumulative cost and stop when budget is exceeded.

**AC:**
1. Given session cost $1.23 and running total $3.00, when accumulated, then total=$4.23
2. Given total $9.80 and budget $10.00, when checking, then CONTINUE (not yet exceeded)
3. Given total $10.50 and budget $10.00, when checking, then EXIT with code 2
4. Given cost parse failure, when accumulating, then assume $5.00 (fail-safe overshoot) and warn

**DEV Notes:**
- bash arithmetic: `bc` or `awk` for float math
- Fail-safe: if can't parse cost, assume worst case

---

#### PBI-005: Exit Condition Checker
**Story:** As the autopilot loop, I need to evaluate all exit conditions in priority order each iteration.

**AC:**
1. Given `project-complete.json` with `complete: true`, when checking, then exit 0
2. Given cost ≥ budget, when checking, then exit 2
3. Given iterations ≥ max, when checking, then exit 3
4. Given consecutive_failures ≥ max_failures, when checking, then exit 1
5. Given none of the above, when checking, then CONTINUE
6. Successful session resets consecutive_failures to 0

**DEV Notes:**
- Check file: `[[ -f .aegis/brain/state/project-complete.json ]]` then parse
- jq or grep for `"complete": true`

---

#### PBI-006: Session Logger
**Story:** As the autopilot loop, I need to log every session for audit and debugging.

**AC:**
1. Given session complete, when logging, then append to `.aegis/brain/logs/autopilot-{timestamp}.log`
2. Given session complete, when logging, then append JSON line to `autopilot-sessions.jsonl`
3. JSONL entry contains: `{iteration, session_id, cost, cumulative_cost, turns, terminal_reason, duration_s, timestamp}`
4. Given autopilot exit, when logging, then write summary line

**DEV Notes:**
- Log file named with autopilot start timestamp
- JSONL for machine parsing, .log for human reading

---

#### PBI-007: Signal Handler (Ctrl+C)
**Story:** As a user, I want Ctrl+C to gracefully stop the autopilot and save state.

**AC:**
1. Given Ctrl+C during session, when caught, then SIGINT forwarded to claude process
2. Given Ctrl+C between sessions (cooldown), when caught, then immediate exit
3. Given interrupt, when exiting, then log final summary
4. Exit code = 130

**DEV Notes:**
- `trap` on SIGINT/SIGTERM
- Store claude PID: `claude -p ... & PID=$!; wait $PID`
- Or: let claude handle its own SIGINT (it does graceful shutdown)

---

#### PBI-008: Main Loop Orchestrator
**Story:** As the autopilot script, I need to tie all components together into the main execution loop.

**AC:**
1. Given all arguments parsed, when starting, then print banner
2. Loop: read handoff → build prompt → execute session → parse result → accumulate cost → check exit → cooldown → repeat
3. Given exit condition met, when exiting, then print summary and exit with correct code
4. Given `--dry-run`, when starting, then print config + first prompt only

**DEV Notes:**
- Main loop is a `while true` with break conditions
- Track: iteration count, cumulative cost, consecutive failures
- Between sessions: sleep $cooldown

---

### Epic: AUTOPILOT-INSTALL

#### PBI-009: Installer Integration
**Story:** As the AEGIS installer, I need to deliver aegis-autopilot.sh to new projects.

**AC:**
1. `aegis-autopilot.sh` added to `runtime_helpers` array in `install.sh`
2. Fresh install delivers the script to `tools/aegis-autopilot.sh`
3. Script is executable (`chmod +x`)

**DEV Notes:**
- Single file, no package directory needed
- Add to `runtime_helpers` array, not `tool_packages`

---

## 8. Role Summary

### DEV (⚡ Bolt / 🕷️ Spider-Man)
- Implement `tools/aegis-autopilot.sh` following PBI-001 through PBI-008
- Pure bash + jq (optional), no other dependencies
- Test on macOS (zsh default shell) and bash

### QA (🛡️ Vigil / 🦇 War Machine)
- Test all exit conditions (budget, iterations, failures, complete, interrupt)
- Test with `--dry-run` first
- Cost tracking accuracy test
- Platform test: macOS zsh + Linux bash
- Edge: no handoff files, empty handoff, corrupt JSON output

### PM (User)
- Validate budget defaults are sane ($5 default, $1000 hard cap)
- Decide on v1.1 features (stall detection, notifications)

---

## 9. Open Questions & Gaps

| # | Question | Owner | Impact if Unresolved |
|---|---------|-------|---------------------|
| Q1 | ควรใช้ `--continue` (resume session เดิม) หรือ fresh session ทุกรอบ? | Dev | Fresh session = clean context แต่ไม่มี history; continue = มี history แต่ context degrade. **Recommendation: fresh session (Ralph Loop pattern)** |
| Q2 | `--permission-mode bypassPermissions` ควรอนุญาตมั้ย? | Security | Risk: agent ลบไฟล์, push force ได้. **Recommendation: allow แต่ print warning** |
| Q3 | Stall detection algorithm สำหรับ v1.1 — วัดจากอะไร? | Dev | Git diff size? File change count? Task completion rate? **Defer to v1.1** |
| Q4 | ควร support `--resume` (resume specific old session) มั้ย? | Dev | v1: ไม่ — fresh session + handoff ดีกว่า |
| Q5 | Max budget hard cap $1000 เหมาะมั้ย? | User | ถ้า project ใหญ่อาจไม่พอ — แต่เป็น safety net |

⚠️ **Safety Notice:** autopilot ที่ `bypassPermissions` + `--budget 1000` + `--max-iterations 100` สามารถสร้างความเสียหายได้มาก ถ้า agent ทำผิด — ใช้ `acceptEdits` + budget ต่ำก่อนเสมอ
