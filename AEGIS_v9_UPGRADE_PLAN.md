# AEGIS v9.0 Super Upgrade Plan

> **Soul**: AEGIS v9 คือการลดความเปราะบาง แล้วเพิ่มความฉลาด ระบบต้องติดตั้งง่ายกว่าเดิม
> ปลอดภัยกว่าเดิม และเรียนรู้จากตัวเองได้จริง ไม่ใช่แค่ scaffold ว่างเปล่า
> Brain ถูกออกแบบเป็น 3-tier (project/user/team) เพื่อให้ knowledge ไหลจาก local สู่ shared
> โดย privacy-by-default -- ไม่มีอะไร leak ข้าม project จนกว่า user จะ opt-in
> ทุกอย่างอยู่ใน `.aegis/` folder เดียว -- project repo สะอาด, uninstall ง่าย, gitignore ชัดเจน
> ทุก decision ใน plan นี้ optimize สำหรับ "day-2 experience" -- ไม่ใช่แค่ demo ดี แต่ต้องใช้จริงแล้วดี

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Current State Analysis](#2-current-state-analysis)
3. [Target State (v9.0 Vision)](#3-target-state)
4. [Architecture Decision Records](#4-architecture-decision-records)
5. [Phased Roadmap](#5-phased-roadmap)
6. [Risk Register](#6-risk-register)
7. [Success Metrics](#7-success-metrics)
8. [Backward Compatibility Strategy](#8-backward-compatibility-strategy)
9. [Open Questions](#9-open-questions)
10. [Appendix](#10-appendix)

---

## 1. Executive Summary

**Vision**: AEGIS v9.0 ยกเครื่อง framework ทั้งระบบให้เป็น Claude 4.7-native -- รวมทุกอย่างเข้า single folder `.aegis/` (จากเดิม 8+ paths กระจาย), ใช้ Claude Code Plugin เป็น primary distribution (MCP server เป็น optional power-user add-on สำหรับ Tier 2/3 brain), ออกแบบ memory เป็น 3-tier architecture (Project Brain default-on, User Brain + Team Brain opt-in), บังคับ worktree isolation สำหรับ subagent ทุกตัว, และปิดช่องโหว่ `bypassPermissions` ทั้งหมด Framework rules ถูก inject ผ่าน plugin runtime -- root CLAUDE.md เป็นของ user ไม่ใช่ของ framework อีกต่อไป curl|bash installer จะถูก sunset ภายใน 6 เดือนหลัง GA

**Top 4 Outcomes:**
1. **Single-folder layout**: `.aegis/` รวม brain, config, cache, logs, metrics -- ลดจาก 8+ scattered paths เหลือ 1 folder, uninstall = `rm -rf .aegis/`
2. **Security-first**: permission model เปลี่ยนจาก deny-list (5 rules) เป็น scoped-allow + default-deny ปิด attack surface ทั้งหมด
3. **3-Tier Brain**: knowledge ไหลจาก project-local (Tier 1, default) สู่ user-wide (Tier 2, opt-in) สู่ team-shared (Tier 3, opt-in) -- privacy-by-default, ทุก tier backed by `memory_20250818`
4. **Dual distribution**: Plugin (90% users) + MCP server (10% power users) -- framework files live in plugin path ไม่ใช่ project repo

**Effort estimate**: 15 sprints, ~482 story points, ~7.5 เดือน (2-week sprints)
**Timeline**: Sprint 1 เริ่ม May 2026, target GA กลาง December 2026, curl|bash removal มิถุนายน 2027

---

## 2. Current State Analysis

### Architecture As-Is (v8.4)

```
User
  |
  v
[curl|bash installer] -- copies ~150 files
  |
  v
+---------------------------------------------------+
|  Project Directory (8+ AEGIS paths scattered)      |
|                                                    |
|  CLAUDE.md  ------+                                |
|  CLAUDE_safety.md |  5 root-level framework files  |
|  CLAUDE_agents.md |  (pollute project root)        |
|  CLAUDE_skills.md |                                |
|  CLAUDE_lessons.md+                                |
|                                                    |
|  .claude/            (Claude Code required)        |
|    agents/  (13 persona .md files)                 |
|    commands/ (10 slash commands)                    |
|    references/ (10 protocol docs)                  |
|    teams/  (6 team configs)                        |
|    hooks/  (6 bash scripts)                        |
|    settings.json (bypassPermissions=default)       |
|                                                    |
|  _aegis-brain/       (brain data)                  |
|    instincts/ (1 promoted, 1 pending)              |
|    resonance/ (4 files, all empty)                 |
|    sprints/  (no current/ symlink)                 |
|    tasks/    (22 task dirs)                         |
|    skill-cache/                                    |
|                                                    |
|  skills/             (skill .md files)             |
|  _aegis-output/      (specs, ISO docs)             |
+---------------------------------------------------+
```

### Key Weaknesses

| # | Severity | Issue | Impact |
|---|----------|-------|--------|
| W1 | CRITICAL | Version drift -- 4 files อ้าง version ต่างกัน (8.2.1/8.3/8.4) | ไม่รู้ว่า install ตัวไหน, bug report ไม่ reproducible |
| W2 | CRITICAL | `bypassPermissions` = default, deny list มีแค่ 5 entries ขณะที่ allow list มี `rm`, `curl`, `docker`, `kubectl`, `terraform` | Agent สามารถ run arbitrary commands ได้โดยไม่ต้อง prompt |
| W3 | CRITICAL | Nick Fury = Single Point of Failure, lvl-8 fallback = "judgment" | ถ้า Nick Fury hallucinate ไม่มีใคร catch ได้ |
| W4 | HIGH | Self-learning files ว่างหมด (evolved-patterns, anti-patterns, architecture-decisions) | ระบบไม่ได้ learn จริง แม้จะ design ไว้ |
| W5 | HIGH | BLOCK 0 บังคับทุก task -- แม้ typo fix ก็ต้องผ่าน PM.01/SI.01/SI.02 | ~31K tokens/story-point overhead |
| W6 | HIGH | `curl|bash` installer ขัดกับ safety policy ของตัวเอง | CLAUDE_safety.md block `curl|bash` แต่ installer ทำเอง |
| W7 | MEDIUM | 13 agents + 31 commands + 28 skills = cognitive overload | ผู้ใช้ใหม่ overwhelmed, context budget กิน 12K tokens แค่ full profile |
| W8 | MEDIUM | ไม่มี fallback controller, bus factor = 1 | ถ้า human ไม่อยู่ + Nick Fury stuck = deadlock |
| W9 | MEDIUM | AEGIS files กระจาย 8+ paths (5 root .md, .claude/, _aegis-brain/, skills/, _aegis-output/) | Hard to gitignore, hard to uninstall, pollutes PR diffs + IDE file tree |

### What Is Working (Keep)

- **Master Brain Protocol** -- single-point-of-contact pattern ลด human interrupts ได้ดี
- **5-Gate quality system** -- structure ดี แม้จะ heavy
- **Agent persona separation** -- model routing (opus/sonnet/haiku) ตาม role สมเหตุสมผล
- **Hook-based enforcement** -- guard-bash.sh, guard-write.sh ป้องกัน destructive commands ได้จริง
- **Brain directory structure** -- `_aegis-brain/` layout ดี เหมาะเป็น foundation สำหรับ 3-tier brain

---

## 3. Target State

### v9.0 Architecture

```
User
  |
  v
[Claude Code Plugin] ----primary----> [MCP Server] --optional add-on
  |                                        |
  v                                        v
+-------------------------------+    +---------------------------+
|  AEGIS Plugin (90% users)     |    |  AEGIS MCP (10% power)    |
|                               |    |                           |
|  Manages:                     |    |  Manages:                 |
|  - Agent templates            |    |  - Tier 2: User Brain     |
|  - Commands (12 consolidated) |    |  - Tier 3: Team Brain     |
|  - Hooks (3 core)             |    |  - Cross-project memory   |
|  - Settings + permissions     |    |  - Sprint daemons         |
|  - Tier 1: Project Brain      |    |  - Learning loop sched.   |
+-------------------------------+    +---------------------------+
  |
  v
+---------------------------------------------------------------+
|  Project Root (CLEAN -- minimal AEGIS footprint)               |
|                                                                |
|  CLAUDE.md (OPTIONAL, user-owned -- project-specific rules)    |
|                                                                |
|  .claude/  (Claude Code requirement -- minimal)                |
|    settings.json      <-- default-deny permissions             |
|    (plugin activation -- ~5 lines, auto-generated)             |
|                                                                |
|  .aegis/  (SINGLE FOLDER -- all AEGIS project state)           |
|    config.yaml        <-- project config (replaces 150 files)  |
|    brain/                                                      |
|      instincts/       <-- promoted + active rules              |
|      resonance/       <-- patterns, conventions, decisions     |
|      sprints/         <-- sprint plans + kanban                 |
|      tasks/           <-- task history + metadata              |
|    cache/             <-- skill-cache, tool results            |
|    logs/              <-- activity logs, agent logs            |
|    tmp/               <-- temporary working files              |
|    metrics/                                                    |
|      raw/             <-- raw performance data                 |
|    output/            <-- specs, ISO docs, architecture        |
|                                                                |
|  Framework files (agents, commands, skills, references):       |
|    Live in ~/.claude/plugins/aegis/ (NOT in project)           |
|    Plugin injects framework rules at runtime                   |
+---------------------------------------------------------------+
```

### .aegis/ Directory Structure (Detail)

```
.aegis/
  config.yaml             # project-level AEGIS configuration
  brain/                  # Tier 1 Project Brain (tracked in git by default)
    instincts/
      promoted/           # hard rules (enforced)
      active/             # soft rules (suggested)
      pending/            # candidate rules
    resonance/
      team-conventions.md
      evolved-patterns.md
      anti-patterns.md
      architecture-decisions.md
    sprints/
      current -> sprint-N # symlink to active sprint
      sprint-1/
      sprint-2/
    tasks/
      PROJ-E-001/
      PROJ-T-001/
  cache/                  # NOT tracked in git
    skill-cache/
    tool-results/
  logs/                   # NOT tracked in git
    activity.log
    nick-fury.log
  tmp/                    # NOT tracked in git
    worktree-state/
  metrics/
    raw/                  # NOT tracked in git
    summary.json          # tracked -- aggregated metrics only
  output/                 # tracked in git
    specs/
    architecture/
    iso-docs/
```

### Auto-Gitignore Modes

| Mode | Default? | What Is Ignored | What Is Tracked | Use Case |
|------|----------|----------------|-----------------|----------|
| `shared` | YES | `.aegis/cache/`, `.aegis/logs/`, `.aegis/tmp/`, `.aegis/metrics/raw/` | `.aegis/brain/`, `.aegis/config.yaml`, `.aegis/output/`, `.aegis/metrics/summary.json` | Team projects -- share brain learning via git |
| `private` | no | Entire `.aegis/` | nothing | Solo/experimental projects -- keep repo clean |
| `paranoid` | no | `.aegis/` AND `.claude/` | nothing | Security-sensitive -- zero framework traces in repo |

**Generated .gitignore block (shared mode):**

```gitignore
# <<< AEGIS-V9-START >>>
.aegis/cache/
.aegis/logs/
.aegis/tmp/
.aegis/metrics/raw/
.aegis/skill-cache/

# Selective output tracking
.aegis/output/iso-docs/*/drafts/
.aegis/output/iso-docs/*/history/
# Tracked: .aegis/output/specs/, .aegis/output/architecture/, .aegis/output/iso-docs/*/current.md
# <<< AEGIS-V9-END >>>
```

Sentinel markers `<<< AEGIS-V9-START >>>` / `<<< AEGIS-V9-END >>>` enable idempotent updates: `aegis init` and `aegis migrate` replace content between sentinels without duplicating or corrupting user-added gitignore rules outside the block.

### CLAUDE.md Ownership Model

| File | v8.x | v9.0 |
|------|------|------|
| `CLAUDE.md` | Framework-owned (AEGIS rules + user rules mixed) | **User-owned** -- project-specific rules only (optional) |
| `CLAUDE_safety.md` | Framework file at project root | **Removed** -- rules injected by plugin at runtime |
| `CLAUDE_agents.md` | Framework file at project root | **Removed** -- agent catalog lives in plugin |
| `CLAUDE_skills.md` | Framework file at project root | **Removed** -- skill catalog lives in plugin |
| `CLAUDE_lessons.md` | Framework file at project root | **Removed** -- lessons live in `.aegis/brain/resonance/` |
| Framework rules | Embedded in root CLAUDE.md | **Plugin-injected** -- plugin prepends framework context at runtime |

### Distribution Model

| Component | Mechanism | Target Users | Manages | Status |
|-----------|-----------|-------------|---------|--------|
| **AEGIS Plugin** | Claude Code Plugin (primary) | ทุกคน (90%) | Agents, commands, hooks, settings, Tier 1 brain, framework rule injection | GA at v9.0 |
| **AEGIS MCP Server** | MCP server (optional add-on) | Power users (10%) | Tier 2/3 brain, cross-project memory, sprint daemons, learning scheduler | Beta at v9.0 |
| **curl/bash** | Legacy installer (6-month bridge) | v8.x users ระหว่าง migrate | N/A -- bridge only | Deprecated at GA, removed GA+6mo |

**Plugin vs MCP Feature Split:**

| Feature | Plugin | MCP Server | Notes |
|---------|--------|------------|-------|
| Agent templates + spawning | YES | no | Plugin core responsibility |
| Slash commands (12 core) | YES | no | Plugin registers commands |
| Hook registration (guard-bash, guard-write, on-stop) | YES | no | Plugin API hooks |
| Settings + permission model | YES | no | `.aegis/config.yaml` owned by plugin |
| Framework rule injection (replaces root CLAUDE_*.md) | YES | no | Plugin prepends rules at session start |
| `.aegis/` folder init + auto-gitignore | YES | no | `aegis init` creates .aegis/ + .gitignore block |
| Tier 1: Project Brain (per-repo) | YES | no | `.aegis/brain/` in project dir |
| Tier 2: User Brain (per-machine) | no | YES | `~/.claude/aegis-brain/` |
| Tier 3: Team Brain (org-level) | no | YES | Shared backend (S3/git/etc.) |
| Cross-project pattern queries | no | YES | "What patterns work across my projects?" |
| Sprint daemon (background health) | no | YES | CronCreate for TinMan heartbeat |
| Learning loop scheduler | no | YES | ScheduleWakeup for auto-learn across projects |
| Offline emergency mode | YES (fallback shell) | no | Minimal .sh scripts for no-plugin scenarios |

### Brain Model: 3-Tier Architecture

```
+------------------------------------------------------------------+
|                     AEGIS Brain Architecture                      |
+------------------------------------------------------------------+
|                                                                    |
|  Tier 1: Project Brain (DEFAULT ON, per-repo)                     |
|  +--------------------------------------------------------------+ |
|  |  Location: ./<project>/.aegis/brain/                          | |
|  |  memory_20250818 type: "project"                              | |
|  |  Contains: sprints, ADRs, project-specific patterns,          | |
|  |            task history, resonance, instincts                 | |
|  |  Managed by: AEGIS Plugin                                     | |
|  |  Git tracking: shared mode tracks brain/ by default           | |
|  +--------------------------------------------------------------+ |
|                          | (opt-in promote)                       |
|                          v                                         |
|  Tier 2: User Brain (OPT-IN, per-machine)                        |
|  +--------------------------------------------------------------+ |
|  |  Location: ~/.claude/aegis-brain/                             | |
|  |  memory_20250818 types: "user", "feedback"                    | |
|  |  Contains: working style, preferences, reusable patterns,    | |
|  |            cross-project retrospective themes                 | |
|  |  Managed by: MCP Server                                       | |
|  +--------------------------------------------------------------+ |
|                          | (opt-in share)                         |
|                          v                                         |
|  Tier 3: Team Brain (OPT-IN, org-level)                          |
|  +--------------------------------------------------------------+ |
|  |  Location: shared backend (S3 bucket / git repo / DB)         | |
|  |  memory_20250818 type: "reference"                            | |
|  |  Contains: team conventions, shared lessons, org-wide         | |
|  |            anti-patterns, blessed architecture patterns       | |
|  |  Managed by: MCP Server + team admin                          | |
|  +--------------------------------------------------------------+ |
|                                                                    |
+------------------------------------------------------------------+
```

**Default config (`.aegis/config.yaml`):**

```yaml
version: "9.0"
brain:
  tier1_project: true
  tier2_user: false
  tier3_team: null
gitignore_mode: shared   # shared | private | paranoid
```

**Data flow rules:**
- Tier 1 -> Tier 2: user explicitly promotes a pattern via `aegis brain promote --to-user`
- Tier 2 -> Tier 3: team admin approves pattern via `aegis brain promote --to-team`
- Tier 3 -> Tier 1: auto-sync on `/aegis-start` if `tier3_team` is configured (read-only pull)
- NO implicit upward flow -- every promotion requires explicit user action
- Tier 1 data never leaves the project directory without user opt-in

### curl|bash Deprecation Schedule (6-Month Bridge)

| Milestone | Date | Behavior |
|-----------|------|----------|
| v9.0 Beta | Oct 2026 | Plugin + curl|bash both work side by side |
| v9.0 GA | Dec 2026 | Plugin = default install method, curl|bash shows "DEPRECATED" warning banner |
| GA + 3 months | Mar 2027 | curl|bash prints error message + auto-suggests `aegis migrate` command |
| GA + 6 months | Jun 2027 | curl|bash REMOVED from repo (keep emergency offline shell script only) |

### Agent Model (Streamlined)

| Agent | Role | Model | v9 Change |
|-------|------|-------|-----------|
| 🧬 Nick Fury | Controller | Opus 4.7 | + Captain America fallback, + ScheduleWakeup |
| 🧭 Captain America | Fallback Controller | Opus 4.7 | เลื่อนขึ้นเป็น backup brain |
| 📐 Iron Man | Architect | Opus 4.7 | ใช้ anthropic-skills:spec-kit |
| ⚡ Spider-Man | Implementer | Sonnet 4.7 | worktree isolation default |
| 🛡️ Black Panther | Reviewer | Sonnet 4.7 | worktree isolation (read-only) |
| 🔴 Loki | Devil's Advocate | Opus 4.7 | ไม่เปลี่ยน |
| 🚀 Thor | DevOps | Sonnet 4.7 | + code_execution sandbox |
| 🎯 War Machine | QA Lead | Sonnet 4.7 | merge Vision เข้ามา |
| 🔧 Beast | Scanner | Haiku 4.7 | ใช้ ToolSearch lazy-load |
| 📜 Coulson | Compliance | Haiku 4.7 | ไม่เปลี่ยน |

**ลดจาก 13 เหลือ 10**: merge Vision เข้า War Machine (QA lead ก็ execute ได้),
retire Wasp + Songbird (ใช้ Spider-Man + Coulson แทน)

### Safety Model

```
permissions:
  defaultMode: "allowEdits"          # <-- เปลี่ยนจาก bypassPermissions
  allow:
    - Read, Write, Edit, Glob, Grep  # file tools (safe)
    - Agent, SendMessage             # agent tools (safe)
    - "Bash(git log:*)"              # read-only git
    - "Bash(git status:*)"
    - "Bash(git diff:*)"
    - "Bash(ls:*)"
    - "Bash(cat:*)"
    - "Bash(find:*)"
    - "Bash(grep:*)"
    - "Bash(wc:*)"
    - "Bash(node --eval:*)"          # sandboxed eval
    - "Bash(npm test:*)"
    - "Bash(npm run:*)"
  deny:                              # explicit deny (defense-in-depth)
    - "Bash(rm -rf /:*)"
    - "Bash(git push --force:*)"
    - "Bash(git push -f:*)"
    - "Bash(git reset --hard:*)"
    - "Bash(git commit --amend:*)"
    - "Bash(curl|bash:*)"
    - "Bash(eval:*)"
    - "Bash(sudo:*)"
```

**Key change**: ย้ายจาก "allow everything, deny 5" เป็น "allow specific, deny dangerous"
Commands ที่ไม่อยู่ใน allow list = Claude จะถามก่อน run (default behavior)

---

## 4. Architecture Decision Records

### ADR-001: Distribution Mechanism -- Plugin Primary, MCP Optional Add-on

**Status**: Accepted
**Context**: v8.x ใช้ `curl|bash` copy ~150 files ลง project directory ทำให้เกิด version drift, ไม่มี auto-update, ขัดกับ safety policy ของตัวเอง, และ user ต้อง commit framework files เข้า repo ต้องเลือกระหว่าง Plugin-only, MCP-only, หรือ dual-layer
**Decision**: ใช้ Claude Code Plugin เป็น primary distribution สำหรับทุกคน (agents, commands, hooks, Tier 1 brain) ใช้ MCP Server เป็น optional add-on สำหรับ power users (Tier 2/3 brain, cross-project memory, sprint daemons) ไม่ใช่ either/or แต่เป็น layered -- 90% users ต้องการแค่ Plugin
**Consequences**:
- (+) Plugin ครอบคลุม core functionality ทั้งหมด -- ผู้ใช้ทั่วไปไม่ต้องรู้จัก MCP
- (+) MCP add-on เปิดทาง power features โดยไม่ bloat Plugin
- (+) Version เดียว ไม่ drift, auto-update ผ่าน plugin registry
- (+) ไม่ต้อง commit 150 files เข้า project repo
- (-) ต้อง maintain 2 distribution channels (Plugin + MCP)
- (-) Feature boundary (Plugin vs MCP) ต้อง clear -- ไม่งั้น confusing
- (-) Plugin API ยังเป็น beta -- อาจ break ใน Claude 4.8
- (-) curl|bash bridge ต้อง maintain 6 เดือน

**Alternatives considered**:
1. *Plugin only (no MCP)* -- simpler แต่ไม่มีทาง serve cross-project brain (Tier 2/3)
2. *MCP only (no Plugin)* -- universal แต่ไม่ integrate กับ Claude Code CLI ลึกพอสำหรับ agents/hooks
3. *NPM package* -- familiar แต่ไม่ได้ประโยชน์จาก plugin auto-update + signing
4. *Keep curl/bash* -- backward compat แต่ไม่แก้ปัญหา version drift, safety contradiction

### ADR-002: Memory Tool Migration -- File as Source of Truth

**Status**: Accepted (revised v3.1 -- Nick Fury post-Loki resolution)
**Context**: v8.x ใช้ custom file-based memory (`_aegis-brain/`) ซึ่ง work แต่ไม่ integrate กับ Claude session lifecycle -- agent ต้อง manual read/write, ไม่มี cross-session enforcement, resonance files ว่างเปล่า ต้องกำหนดว่า file system หรือ memory tool เป็น source of truth เพื่อหลีกเลี่ยง dual-write consistency risk
**Decision**: File system = authoritative source of truth, `memory_20250818` = read-through cache ที่ sync จาก file ทุก session start Map memory types ตาม 3-tier brain model:
- Tier 1 (Project): files ใน `.aegis/brain/`, cached ผ่าน `memory_20250818` type `project`
- Tier 2 (User): files ใน `~/.claude/aegis-brain/`, cached ผ่าน types `user` + `feedback`
- Tier 3 (Team): files ใน shared backend, cached ผ่าน type `reference`

**Conflict resolution protocol**: On any divergence between memory tool content and file content, file wins. Memory tool re-syncs from file at every session start. Memory tool writes are best-effort cache updates that also write-through to file. If write-through to file fails, memory tool update is rolled back.

**Consequences**:
- (+) Single source of truth eliminates dual-write consistency risk
- (+) File system is stable substrate independent of Claude API changes -- survives memory tool format changes
- (+) Claude enforce "read memory before acting" automatically (cache layer)
- (+) Cross-session continuity via memory tool read-through cache
- (+) Memory pruning/compaction handled by Claude runtime (cache only)
- (+) 3-tier mapping ทำให้ memory types มี semantic meaning ชัดเจน
- (+) Files are auditable, diffable, git-trackable -- memory tool is ephemeral
- (-) Memory tool requires periodic re-sync from file (sync overhead at session start ~1-2s)
- (-) ต้อง migrate existing brain data (script + manual verify)
- (-) ต้อง maintain file write-through logic alongside memory tool cache logic

**Alternatives considered**:
1. *Keep file-only* -- ไม่ได้ประโยชน์จาก Claude-level enforcement (auto-read at session start)
2. *Hybrid dual-write (memory tool + files as peers)* -- REJECTED: dual source of truth creates consistency risk ที่ Loki identified; no clear winner when they diverge
3. *Memory tool as primary, files as backup* -- REJECTED: couples AEGIS to memory_20250818 API stability; file loss on API change is catastrophic
4. *MCP memory server for all tiers* -- over-engineering สำหรับ Tier 1

### ADR-003: Agent Isolation Model

**Status**: Accepted
**Context**: v8.x subagents run ใน shared workspace -- Spider-Man, Black Panther, Thor ทำงานกับ files เดียวกันพร้อมกัน เสี่ยง conflict, ไม่มี blast radius control
**Decision**: ทุก subagent ใช้ `isolation: "worktree"` by default, ยกเว้น read-only agents (Beast, Coulson) ที่ใช้ shared workspace
**Consequences**:
- (+) Spider-Man แก้ code ใน worktree แยก -- merge conflict ถูก detect ก่อน commit
- (+) Black Panther review ใน read-only worktree -- ไม่มีโอกาส modify code ที่ review
- (+) Parallel agents ทำงานได้จริงโดยไม่ชนกัน
- (-) Git worktree management ซับซ้อนขึ้น (cleanup, branch naming)
- (-) Disk usage เพิ่มขึ้น (worktree per agent)
- (-) ต้อง update merge workflow ใน build team

**Alternatives considered**:
1. *Shared workspace + file locks* -- fragile, ไม่ scale
2. *Container-based isolation* -- overkill, ต้อง Docker
3. *Branch-per-agent without worktree* -- ช้ากว่า (checkout switch)

### ADR-004: Permission Model Overhaul

**Status**: Accepted
**Context**: v8.x ใช้ `defaultMode: "bypassPermissions"` กับ allow list 50+ entries + deny list 5 entries ทำให้ agent run `rm`, `curl`, `docker`, `kubectl`, `terraform` ได้โดยไม่ถาม -- risk surface กว้างมาก
**Decision**: เปลี่ยนเป็น `defaultMode: "allowEdits"` (file edits ไม่ต้องถาม, bash commands ที่ไม่อยู่ใน allow list ต้องถาม) + ลด allow list เหลือ read-only commands + safe build commands, เพิ่ม deny list ให้ครอบคลุม dangerous patterns
**Consequences**:
- (+) Attack surface ลดจาก 50+ allowed commands เหลือ ~15
- (+) Dangerous commands (docker, kubectl, terraform, rm, curl) ต้อง human approve
- (+) สอดคล้องกับ CLAUDE_safety.md policy
- (-) ช้าลงเล็กน้อยเพราะ Claude ถาม permission บ่อยขึ้น
- (-) Existing users ที่ชินกับ bypass ต้องปรับตัว
- (-) CI/CD automation ต้อง configure allow list เพิ่ม

**Alternatives considered**:
1. *Keep bypassPermissions + expand deny list* -- ยัง vulnerable ต่อ commands ที่ไม่คาดคิด
2. *Full lockdown (ask everything)* -- UX แย่มาก agent flow ถูก interrupt ทุก command
3. *Role-based permissions per agent* -- ideal แต่ Claude Code ยังไม่ support per-agent permissions

### ADR-005: Skills Consolidation

**Status**: Accepted
**Context**: v8.x มี 28 custom skills + Claude 4.7 มี `anthropic-skills:*` (autonomous-coding, spec-kit, skill-creator) ที่ทำหน้าที่ซ้ำกับ AEGIS skills หลายตัว, AEGIS skills บางตัว superseded แล้ว (sprint-tracker #26), surface area กว้างเกินไป
**Decision**: adopt `anthropic-skills:*` สำหรับ generic capabilities (coding, spec, testing), keep เฉพาะ AEGIS-specific skills 5 ตัว (orchestrator, personas, sprint-manager, kanban-board, iso-29110-docs), retire ที่เหลือ
**Consequences**:
- (+) ลดจาก 28 skills เหลือ 5 AEGIS-custom + N anthropic-skills = ลด maintenance
- (+) anthropic-skills ได้ benefit จาก Anthropic upstream updates
- (+) Context budget ลดจาก ~12K tokens (full profile) เหลือ ~4K
- (-) Feature gap ช่วง transition -- anthropic-skills อาจไม่ครอบคลุม AEGIS workflow ทั้งหมด
- (-) ผู้ใช้ที่ customize skills ต้อง re-map
- (-) Lock-in กับ anthropic-skills API surface

**Alternatives considered**:
1. *Keep all 28 + add anthropic-skills* -- duplication, confusion, context bloat
2. *Build all custom, ignore anthropic-skills* -- maintenance burden สูง, miss upstream improvements
3. *Gradual adoption (skill-by-skill)* -- longer timeline แต่ lower risk -- อาจใช้เป็น implementation approach

### ADR-006: 3-Tier Brain Architecture

**Status**: Accepted
**Context**: v8.x มี brain model เดียว (per-project `_aegis-brain/`) ที่ไม่มี knowledge sharing ข้าม project และ resonance files ว่างเปล่า ผู้ใช้ที่ทำหลาย projects ต้อง re-learn patterns ซ้ำทุกครั้ง ขณะที่ team ไม่มีทาง share conventions
**Decision**: ออกแบบ brain เป็น 3 tiers ที่ stack กัน:
- **Tier 1 (Project Brain)**: default ON, per-repo `.aegis/brain/`, managed by Plugin
- **Tier 2 (User Brain)**: opt-in, per-machine `~/.claude/aegis-brain/`, managed by MCP
- **Tier 3 (Team Brain)**: opt-in, shared backend (S3/git), managed by MCP + team admin

Data flows upward ONLY via explicit user action (`aegis brain promote`), never implicitly
Data flows downward automatically (Tier 3 -> Tier 1 on session start if configured)

**Consequences**:
- (+) Privacy-by-default -- Tier 1 data stays in project, no leak
- (+) Power users get cross-project knowledge reuse via Tier 2
- (+) Teams get shared conventions + anti-patterns via Tier 3
- (+) Clean separation: Plugin owns Tier 1, MCP owns Tier 2/3
- (-) 3-tier complexity -- users may be confused about what lives where
- (-) Tier 2/3 require MCP server -- adds install/config overhead for power users
- (-) Data promotion flow needs careful UX design to avoid accidental leaks
- (-) Migration from v8.x flat brain to 3-tier requires mapping decisions

**Brain Merge Strategy** (added v3.1):
When brain data merges across tiers (e.g., Tier 3 team conventions pulled into Tier 1 project brain at session start), the following rules apply:
- **Append-only format**: brain files use `<!-- APPEND-ONLY -->` markers; new entries are appended, never overwrite existing content
- **YAML union merge**: for structured config files (e.g., `config.yaml`, instinct metadata), merge uses YAML union semantics -- keys from source are added if absent, existing keys are NOT overwritten
- **`aegis brain merge` command**: explicit manual merge for advanced scenarios (e.g., cherry-pick specific Tier 3 patterns into Tier 1)
- **`aegis brain compact` command**: when append-only files grow beyond 50KB, compact command deduplicates entries, archives history to `.aegis/brain/archive/`, and resets active file
- **Conflict on merge**: if a Tier 3 pattern directly contradicts a Tier 1 pattern, the conflict is logged to `.aegis/logs/conflict-resolution.log` and resolved per ADR-002 conflict resolution protocol (Tier 1 project wins by default)

**Alternatives considered**:
1. *Single tier (per-project only)* -- simple แต่ไม่มี knowledge reuse, same as v8.x
2. *Two tiers (project + shared)* -- skip user tier; but user preferences are distinct from team conventions
3. *Cloud-backed all tiers* -- violates local-first principle, requires internet
4. *Flat shared brain (all projects share one)* -- privacy nightmare, no isolation

### ADR-007: Single-Folder Project Layout (.aegis/)

**Status**: Accepted
**Context**: v8.x scatters AEGIS files across the project: `.claude/` (agents, commands, references, teams, hooks), `_aegis-brain/` (brain data), `skills/` (skill files), `_aegis-output/` (specs, ISO docs), plus 5 root-level framework files (CLAUDE.md, CLAUDE_safety.md, CLAUDE_agents.md, CLAUDE_skills.md, CLAUDE_lessons.md) รวม 8+ paths ที่ต้อง manage ทำให้ hard to gitignore (multiple paths), hard to uninstall (rm 8+ paths, easy to miss), hard to identify "what is AEGIS vs project files", pollutes PR diffs + IDE file tree + developer mental model
**Decision**: รวมทุก AEGIS project state เข้า single hidden folder `.aegis/` ที่ project root:
- `.aegis/` contains: `brain/`, `config.yaml`, `cache/`, `logs/`, `tmp/`, `metrics/`, `output/`
- `.claude/` stays at root (Claude Code requirement) แต่มีเฉพาะ `settings.json` + plugin activation (~5 lines)
- Framework files (agents, commands, skills, references) live in plugin path `~/.claude/plugins/aegis/` ไม่ใช่ใน project
- Root CLAUDE_*.md files (5 ไฟล์) ถูก REMOVED จาก project -- framework rules inject ผ่าน plugin runtime
- Root CLAUDE.md = optional, user-owned (project-specific rules only ไม่ใช่ framework rules)
- Auto-gitignore 3 modes: `shared` (default, track brain + config, ignore cache/logs/tmp), `private` (ignore .aegis/), `paranoid` (ignore .aegis/ + .claude/)

**Consequences**:
- (+) Clean project repo -- 1 folder แทน 8+ paths
- (+) Easy uninstall: `rm -rf .aegis/ && claude plugin uninstall aegis`
- (+) Single .gitignore block -- จบปัญหา scattered ignore patterns
- (+) Clear separation: framework concerns (plugin) vs project state (.aegis/) vs user rules (CLAUDE.md)
- (+) Plugin auto-update ไม่ touch project files
- (+) New developer onboarding: clone repo -> brain context loads via tracked `brain/` (shared mode)
- (-) Discoverability: new devs need README to know `.aegis/` exists (mitigated by docs)
- (-) Migration complexity สำหรับ v8.x users -- 5 framework root files + 2 data dirs ต้อง relocate
- (-) User CLAUDE_*.md customizations need backup + diff + restore during migration
- (-) Brain commits add to git history (acceptable -- represents team learning)

**Alternatives considered**:
1. *`aegis/` (visible folder)* -- breaks convention with `.git`, `.claude`, `.vscode`
2. *`.aegis/` + symlink CLAUDE.md to project root* -- Windows symlink issues, git filemode complications
3. *Keep current scattered layout* -- this is the original problem being solved
4. *Move .claude/ into .aegis/* -- Claude Code hardcodes `.claude/` at project root, cannot move
5. *CLAUDE.md @import directive* -- not a standard Claude Code parser feature, would require upstream change

---

## 5. Phased Roadmap

### Phase 1: Foundation Hardening (Sprints 1-3) -- Safety + Version Sanity

**Theme**: แก้ CRITICAL issues ก่อน ไม่เพิ่ม feature ใหม่

#### Sprint 1: Version Consolidation + Permission Lockdown
**Goal**: Single source of truth สำหรับ version, ปิด bypassPermissions

| ID | Task | Agent | Effort | Dependencies | Acceptance Criteria |
|----|------|-------|--------|-------------|---------------------|
| S1-01 | - [ ] สร้าง `VERSION` file เป็น single source of truth | ⚡ Spider-Man | S(1) | none | `VERSION` file ที่ root, ทุกไฟล์อื่น read จากนี่ |
| S1-02 | - [ ] Update install.sh อ่าน version จาก `VERSION` file | ⚡ Spider-Man | S(1) | S1-01 | install.sh ไม่ hardcode version string |
| S1-03 | - [ ] สร้าง `aegis-version-check.sh` hook ที่ validate version consistency | ⚡ Spider-Man | M(3) | S1-01 | Hook run ที่ session start, fail ถ้า version drift |
| S1-04 | - [ ] เปลี่ยน settings.json จาก bypassPermissions เป็น allowEdits + scoped allow list | 📐 Iron Man | M(3) | none | deny list >= 10 entries, allow list <= 20 safe commands |
| S1-05 | - [ ] เพิ่ม `curl\|bash`, `eval`, `sudo`, `chmod 777` เข้า deny list | 🛡️ Black Panther | S(1) | S1-04 | deny list ครอบคลุม dangerous patterns ทั้งหมด |
| S1-06 | - [ ] สร้าง permission migration guide สำหรับ v8.x users | 📜 Coulson | M(3) | S1-04 | Guide อธิบายว่า commands ไหนต้อง approve ใหม่ |
| S1-07 | - [ ] Update CLAUDE_safety.md ให้ version ตรงกับ CLAUDE.md | ⚡ Spider-Man | S(1) | S1-01 | ทุก .md file อ้าง version เดียวกัน |

**Sprint 1 total**: 13 points

#### Sprint 2: Nick Fury Resilience + BLOCK 0 Reform
**Goal**: ลด SPOF risk, ทำให้ BLOCK 0 proportional กับ task size

| ID | Task | Agent | Effort | Dependencies | Acceptance Criteria |
|----|------|-------|--------|-------------|---------------------|
| S2-01 | - [ ] Implement Captain America fallback protocol -- ถ้า Nick Fury ไม่ respond ภายใน 30s, Captain America เข้ามา | 📐 Iron Man | L(8) | none | Fallback trigger + recovery flow documented + tested |
| S2-02 | - [ ] เพิ่ม "decision audit" -- ทุก Nick Fury lvl-8 judgment ต้อง log reason + confidence score | ⚡ Spider-Man | M(3) | none | Judgment decisions ถูก log ที่ activity.log พร้อม confidence |
| S2-03 | - [ ] สร้าง BLOCK 0 "lite" mode -- tasks < 3pts skip SI.01/SI.02, ต้องการแค่ task meta.json | 📐 Iron Man | L(8) | none | Spec document แยก full vs lite BLOCK 0 criteria |
| S2-04 | - [ ] Implement BLOCK 0 lite ใน nick-fury.md decision flow | ⚡ Spider-Man | M(3) | S2-03 | typo fix (1pt) ไม่ trigger Coulson ISO doc generation |
| S2-05 | - [ ] สร้าง `_aegis-brain/sprints/current` symlink management ใน sprint commands | ⚡ Spider-Man | S(1) | none | `/aegis-sprint plan` สร้าง symlink, `/aegis-sprint close` ลบ |
| S2-06 | - [ ] Audit และ document ทุก lvl-8 judgment path ใน Nick Fury | 🔴 Loki | M(3) | none | Report ระบุทุก path ที่ fallback ถึง judgment พร้อม risk rating |
| S2-07 | - [ ] Consolidate project folder structure to `.aegis/` + auto-gitignore | 🚀 Thor | M(3) | S1-01 | `.aegis/` dir created with brain/cache/logs/tmp/metrics/output; `config.yaml` replaces scattered configs; installer accepts `--gitignore-mode {shared\|private\|paranoid}` (default: shared); auto-add .gitignore block using `<<< AEGIS-V9-START >>>` / `<<< AEGIS-V9-END >>>` sentinel markers (idempotent -- `aegis init` and `aegis migrate` replace content between sentinels without duplicating or corrupting user rules outside the block); `aegis migrate --consolidate` for v8.x users; update all agent/command refs from `_aegis-brain/` to `.aegis/brain/` |

**Sprint 2 total**: 29 points

#### Sprint 3: Self-Learning Bootstrap + Test Harness
**Goal**: ทำให้ evolved-patterns/anti-patterns populate จริง, สร้าง test framework

| ID | Task | Agent | Effort | Dependencies | Acceptance Criteria |
|----|------|-------|--------|-------------|---------------------|
| S3-01 | - [ ] Seed evolved-patterns.md ด้วย 10 patterns จาก codebase analysis | 🔧 Beast | M(3) | none | >= 10 patterns พร้อม evidence count |
| S3-02 | - [ ] Seed anti-patterns.md ด้วย 5 anti-patterns จาก retrospectives/issues | 🔧 Beast | M(3) | none | >= 5 anti-patterns พร้อม root cause |
| S3-03 | - [ ] Seed architecture-decisions.md ด้วย 3 ADRs จาก existing codebase | 📐 Iron Man | M(3) | none | >= 3 ADRs ที่ reflect actual decisions |
| S3-04 | - [ ] สร้าง test suite สำหรับ hooks (guard-bash, guard-write) | 🎯 War Machine | L(8) | none | >= 20 test cases, ครอบคลุม deny list ทุก entry |
| S3-05 | - [ ] สร้าง integration test: full BLOCK 0 flow (lite + full) | 🎯 War Machine | L(8) | S2-03 | Test ว่า 1pt task skip ISO, 8pt task require ISO |
| S3-06 | - [ ] สร้าง version consistency test (CI-ready) | ⚡ Spider-Man | M(3) | S1-01 | `aegis-doctor` command check version across all files |

**Sprint 3 total**: 28 points

---

### Phase 2: Claude 4.7 Native Templates (Sprints 4-6) -- Memory, Worktree, Schedule

**Theme**: Adopt Claude 4.7 official capabilities, replace custom implementations

#### Sprint 4: Memory Tool Integration (Tier 1 Foundation)
**Goal**: `memory_20250818` เป็น primary memory layer สำหรับ Tier 1 Project Brain

| ID | Task | Agent | Effort | Dependencies | Acceptance Criteria |
|----|------|-------|--------|-------------|---------------------|
| S4-01 | - [ ] Design memory schema mapping: Tier 1 `.aegis/brain/` dirs -> `project` memory type (sprints, ADRs, patterns, instincts) | 📐 Iron Man | L(8) | S2-07 | Schema doc ระบุ mapping ทุก field, uses `.aegis/brain/` paths |
| S4-02 | - [ ] Implement memory tool wrapper ใน Nick Fury -- read Tier 1 memories at session start, write at session end | ⚡ Spider-Man | L(8) | S4-01 | Nick Fury scan phase อ่าน memories ก่อน file scan |
| S4-03 | - [ ] สร้าง `aegis migrate brain` command -- convert v8.x flat brain เป็น Tier 1 memory tool entries ใน `.aegis/brain/` | ⚡ Spider-Man | L(8) | S4-01, S2-07 | Migrate instincts, resonance, sprint history into `.aegis/brain/` Tier 1 |
| S4-04 | - [ ] Update Auto-Learn Protocol ให้ write ผ่าน memory tool (Tier 1) แทน direct file write | ⚡ Spider-Man | M(3) | S4-02 | Pattern detection result ถูกเก็บทั้ง memory tool + file backup |
| S4-05 | - [ ] Adversarial test: Tier 1 memory corruption scenario + recovery | 🔴 Loki | M(3) | S4-02 | Recovery จาก corrupted memory ใช้ file backup ได้ |
| S4-06 | - [ ] Performance benchmark: memory tool vs file read latency | 🔧 Beast | S(1) | S4-02 | Report latency comparison |

**Sprint 4 total**: 31 points

#### Sprint 5: Worktree Isolation + Background Agents
**Goal**: Subagents ทำงาน parallel ใน isolated worktrees

| ID | Task | Agent | Effort | Dependencies | Acceptance Criteria |
|----|------|-------|--------|-------------|---------------------|
| S5-01 | - [ ] Design worktree naming convention + lifecycle (create/merge/cleanup) | 📐 Iron Man | M(3) | none | Spec: `aegis-wt/<agent>-<task-id>` pattern |
| S5-02 | - [ ] Update Spider-Man agent template: `isolation: "worktree"` default | ⚡ Spider-Man | M(3) | S5-01 | Spider-Man spawns in dedicated worktree |
| S5-03 | - [ ] Update Black Panther: worktree read-only mode สำหรับ review | ⚡ Spider-Man | M(3) | S5-01 | Black Panther ไม่สามารถ modify files ใน review worktree |
| S5-04 | - [ ] Implement worktree merge protocol -- post-review merge back to main worktree | ⚡ Spider-Man | L(8) | S5-02, S5-03 | Conflict detection + resolution flow |
| S5-05 | - [ ] Enable `run_in_background: true` สำหรับ Beast scanning + Coulson doc gen | ⚡ Spider-Man | M(3) | none | Beast scan ไม่ block build pipeline |
| S5-06 | - [ ] Implement `mark_chapter` ที่ phase boundaries (SCAN/PLAN/BUILD/REVIEW/QA) | ⚡ Spider-Man | S(1) | none | Session UX แสดง chapter markers |
| S5-07 | - [ ] Worktree cleanup hook -- post-sprint-close ลบ stale worktrees | 🚀 Thor | M(3) | S5-01 | ไม่มี orphan worktrees หลัง sprint close |

**Sprint 5 total**: 24 points

#### Sprint 6: Schedule + ToolSearch + Agent Consolidation
**Goal**: Self-paced loops, lazy-load, ลด agent count

| ID | Task | Agent | Effort | Dependencies | Acceptance Criteria |
|----|------|-------|--------|-------------|---------------------|
| S6-01 | - [ ] Implement `ScheduleWakeup` สำหรับ Tier 1 brain maintenance (pattern extraction ทุก 3 tasks) | ⚡ Spider-Man | M(3) | S4-02 | Auto-trigger pattern extraction ไม่ต้อง manual |
| S6-02 | - [ ] Implement `ToolSearch` (deferred tools) สำหรับ agent schemas -- lazy-load แทน preload | ⚡ Spider-Man | M(3) | none | Agent templates ไม่ถูก load จนกว่าจะ spawn |
| S6-03 | - [ ] Merge Vision เข้า War Machine -- single QA agent | 📐 Iron Man | M(3) | none | War Machine template รวม test execution capability |
| S6-04 | - [ ] Retire Wasp agent -- UX tasks route ผ่าน Spider-Man + style guide reference | 📐 Iron Man | S(1) | none | Wasp.md archived, routing table updated |
| S6-05 | - [ ] Retire Songbird agent -- content tasks route ผ่าน Coulson | 📐 Iron Man | S(1) | none | Songbird.md archived, routing table updated |
| S6-06 | - [ ] Consolidate 31 commands เหลือ 12 core commands | 📐 Iron Man | L(8) | none | Command mapping doc: old -> new |
| S6-07 | - [ ] Update CLAUDE_agents.md, CLAUDE_skills.md, CLAUDE.md สำหรับ v9 agent list | 📜 Coulson | M(3) | S6-03, S6-04, S6-05 | ทุก doc reflect 10-agent model |

**Sprint 6 total**: 22 points

---

### Phase 2.5: Brain Tier Architecture (Sprints 7-9) -- 3-Tier Brain Build-Out

**Theme**: ก่อสร้าง Tier 2 (User Brain) และ Tier 3 (Team Brain) พร้อม data promotion flow

#### Sprint 7: Tier 2 -- User Brain
**Goal**: Per-machine User Brain ที่เก็บ preferences + reusable patterns ข้าม projects

| ID | Task | Agent | Effort | Dependencies | Acceptance Criteria |
|----|------|-------|--------|-------------|---------------------|
| S7-01 | - [ ] Design Tier 2 schema: `~/.claude/aegis-brain/` directory structure + memory types (`user`, `feedback`) | 📐 Iron Man | L(8) | S4-01 | Schema doc แยก Tier 1 vs Tier 2 data boundaries ชัดเจน |
| S7-02 | - [ ] Implement Tier 2 brain init -- `aegis brain init --tier2` creates `~/.claude/aegis-brain/` with default structure | ⚡ Spider-Man | M(3) | S7-01 | Directory created with correct permissions (700) |
| S7-03 | - [ ] Implement `aegis brain promote --to-user` command -- explicit promotion from Tier 1 to Tier 2 | ⚡ Spider-Man | L(8) | S7-02 | Pattern/preference promoted with audit log, requires confirmation |
| S7-04 | - [ ] Implement Tier 2 read on session start -- Nick Fury merges User Brain preferences into session config | ⚡ Spider-Man | M(3) | S7-02 | User preferences (autonomy level, agent effort) loaded from Tier 2 |
| S7-05 | - [ ] Privacy guard: validate that Tier 1 -> Tier 2 promotion ไม่ leak project-specific data (secrets, paths, identifiers) | 🛡️ Black Panther | L(8) | S7-03 | Scrubbing rules for project paths, API keys, task IDs |
| S7-06 | - [ ] Adversarial test: attempt to exfiltrate Tier 1 data through Tier 2 promotion loophole | 🔴 Loki | M(3) | S7-05 | Zero data leak paths found, or mitigations documented |

**Sprint 7 total**: 33 points

#### Sprint 8: Tier 3 -- Team Brain
**Goal**: Org-level shared brain ที่ sync conventions + lessons across team members

| ID | Task | Agent | Effort | Dependencies | Acceptance Criteria |
|----|------|-------|--------|-------------|---------------------|
| S8-01 | - [ ] Design Tier 3 schema + backend options (S3 bucket, git repo, local SQLite for small teams) | 📐 Iron Man | L(8) | S7-01 | ADR ระบุ backend choice criteria + schema for `reference` memory type |
| S8-02 | - [ ] Implement Tier 3 backend adapter interface (pluggable: git, S3, local-file) | ⚡ Spider-Man | L(8) | S8-01 | Adapter interface + git backend implementation (MVP) |
| S8-03 | - [ ] Implement `aegis brain promote --to-team` command -- user promotes pattern, team admin approves | ⚡ Spider-Man | L(8) | S8-02, S7-03 | 2-step promotion flow with admin approval gate |
| S8-04 | - [ ] Implement Tier 3 -> Tier 1 auto-sync: read-only pull of team conventions on `/aegis-start` | ⚡ Spider-Man | M(3) | S8-02 | Team patterns merged into `.aegis/brain/` at session start (no write-back) |
| S8-05 | - [ ] Implement `aegis brain status` -- shows all 3 tiers, data counts, last sync timestamps | ⚡ Spider-Man | M(3) | S7-02, S8-02 | Clear overview of what data lives where |
| S8-06 | - [ ] Security audit: Tier 3 backend auth + data-at-rest encryption requirements | 🛡️ Black Panther | M(3) | S8-02 | Audit report: encryption, auth, access control spec |

**Sprint 8 total**: 33 points

#### Sprint 9: Brain Integration Testing + Migration Path
**Goal**: 3-tier brain ทำงานร่วมกัน end-to-end, migration path จาก v8.x flat brain

| ID | Task | Agent | Effort | Dependencies | Acceptance Criteria |
|----|------|-------|--------|-------------|---------------------|
| S9-01 | - [ ] End-to-end test: pattern discovered in Tier 1 -> promoted to Tier 2 -> shared to Tier 3 -> pulled by another project's Tier 1 | 🎯 War Machine | L(8) | S8-04 | Full promotion + sync cycle works across 2 test projects |
| S9-02 | - [ ] Update `aegis migrate brain` to support v8.x -> `.aegis/brain/` Tier 1 mapping (flat brain -> structured Tier 1) | ⚡ Spider-Man | M(3) | S4-03, S2-07 | v8.x instincts, resonance, patterns land in correct `.aegis/brain/` Tier 1 slots |
| S9-03 | - [ ] Implement brain conflict resolution -- Tier 3 pattern conflicts with Tier 1 project-specific pattern | ⚡ Spider-Man | L(8) | S8-04 | Nick Fury resolves conflicts automatically via priority rule: Tier 1 (Project) > Tier 3 (Team) > Tier 2 (User); every resolution logged to `.aegis/logs/conflict-resolution.log` with timestamp, conflicting values, winner tier, and rationale; `aegis brain conflicts --recent` command shows last 10 resolutions; edge case (equal priority or ambiguous conflict) escalates to human via Nick Fury standard escalation; `aegis brain merge` command for manual cherry-pick merge across tiers |
| S9-04 | - [ ] Performance test: session start latency with all 3 tiers enabled (target: < 2s overhead) | 🔧 Beast | M(3) | S8-04 | Benchmark report: Tier 1-only vs all-3-tiers startup time |
| S9-05 | - [ ] Update `aegis.config.yaml` schema to include brain tier configuration + gitignore mode | 📐 Iron Man | M(3) | S7-02, S8-02, S2-07 | Config schema validated, documented with examples |
| S9-06 | - [ ] Write Brain Tier user guide -- when to use each tier, promotion flow, privacy guarantees | 📜 Coulson | M(3) | S9-01 | Guide covers all 3 tiers, includes examples + warnings |

**Sprint 9 total**: 28 points

---

### Phase 3: Distribution -- Plugin + MCP (Sprints 10-13)

**Theme**: สร้าง Plugin (mandatory) แล้วต่อด้วย MCP Server (optional) เป็น 2 sub-phases

#### Sprint 10: Plugin Core
**Goal**: Working Claude Code Plugin ที่ install ได้ พร้อม `.aegis/` folder init + framework rule injection

| ID | Task | Agent | Effort | Dependencies | Acceptance Criteria |
|----|------|-------|--------|-------------|---------------------|
| S10-00 | - [ ] MCP-only Capability Spike (2-day timebox) -- validate whether MCP server alone can cover >= 90% of AEGIS Plugin functionality | 📐 Iron Man + ⚡ Spider-Man (paired) | M(3) | none | 2-day strict timebox; test MCP coverage for: agent spawning, hook registration, framework rule injection, `.aegis/` init, permission model, session lifecycle; produce coverage matrix (feature vs MCP capability: YES/NO/PARTIAL); decision gate: if MCP coverage >= 90%, escalate to Nick Fury for Plugin-vs-MCP-only architectural re-evaluation; if < 90%, proceed with Plugin as planned; spike report saved to `.aegis/output/specs/S10-00-mcp-spike-report.md` |
| S10-01 | - [ ] Research Claude Code Plugin API + packaging format | 🔧 Beast | M(3) | S10-00 | Report: API surface, constraints, publish flow |
| S10-01b | - [ ] Build Plugin API Abstraction Layer -- `IPluginAdapter` interface that shields AEGIS from Claude Plugin API changes | 📐 Iron Man | L(8) | S10-01 | `IPluginAdapter` interface defined with methods: `registerAgent()`, `registerHook()`, `registerCommand()`, `injectContext()`, `getSettings()`, `onSessionStart()`, `onSessionEnd()`; versioned compatibility matrix (Plugin API v1 -> adapter v1, future API v2 -> adapter v2); adapter implementation for current Plugin API; unit tests for adapter contract; if Plugin API changes in Claude 4.8+, only adapter implementation changes -- zero changes to AEGIS core code |
| S10-02 | - [ ] Design `aegis.config.yaml` schema -- single config file inside `.aegis/` that replaces 150 scattered files | 📐 Iron Man | L(8) | S10-01b, S2-07 | Schema doc + YAML schema validation |
| S10-03 | - [ ] Build plugin scaffold -- manifest, entry point, config loader, `.aegis/` folder init | ⚡ Spider-Man | L(8) | S10-02 | Plugin installs via `claude plugin add aegis`, creates `.aegis/` on `aegis init` |
| S10-04 | - [ ] Implement agent template loader (from plugin package at `~/.claude/plugins/aegis/`) | ⚡ Spider-Man | L(8) | S10-03 | Agents load from plugin path, not from `.claude/agents/` files |
| S10-05 | - [ ] Implement hook registration from plugin | ⚡ Spider-Man | M(3) | S10-03 | guard-bash, guard-write hooks register via plugin API |
| S10-06 | - [ ] Wire Tier 1 brain into plugin lifecycle (init on `aegis init`, read/write on session) | ⚡ Spider-Man | M(3) | S10-03, S4-02 | Plugin manages `.aegis/brain/` directory + memory tool |
| S10-07 | - [ ] Implement plugin-injected framework rules (replace root CLAUDE_*.md files) | ⚡ Spider-Man | M(3) | S10-03 | Plugin prepends framework context at session start; root CLAUDE.md is user-owned only |

**Sprint 10 total**: 47 points (was 36; +3 for S10-00 MCP spike, +8 for S10-01b abstraction layer)

#### Sprint 11: Plugin Polish + Skills Migration
**Goal**: Plugin production-ready, adopt anthropic-skills

| ID | Task | Agent | Effort | Dependencies | Acceptance Criteria |
|----|------|-------|--------|-------------|---------------------|
| S11-01 | - [ ] Plugin auto-update mechanism | ⚡ Spider-Man | L(8) | S10-03 | Version check + prompt to update |
| S11-02 | - [ ] Plugin signing + integrity verification | 🚀 Thor | L(8) | S10-03 | SHA256 checksum verify at install time |
| S11-03 | - [ ] สร้าง `aegis init` command (plugin mode) -- interactive project setup, creates `.aegis/` + auto-gitignore + minimal `.claude/` | ⚡ Spider-Man | M(3) | S10-03, S2-07 | Replace install.sh สำหรับ new projects; asks gitignore mode preference |
| S11-04 | - [ ] Integrate `anthropic-skills:autonomous-coding` แทน AEGIS code-standards skill | ⚡ Spider-Man | M(3) | none | Spider-Man ใช้ official skill |
| S11-05 | - [ ] Integrate `anthropic-skills:spec-kit` แทน AEGIS super-spec skill | ⚡ Spider-Man | M(3) | none | Iron Man ใช้ official skill |
| S11-06 | - [ ] Map remaining 23 AEGIS skills: keep (5) / retire (18) + deprecation warnings | 📐 Iron Man | M(3) | none | Decision table + skill deprecation warnings in `aegis-mode` |
| S11-07 | - [ ] Plugin smoke test: `/aegis-start` -> full build cycle via plugin-loaded agents, `.aegis/` folder layout | 🎯 War Machine | L(8) | S11-01, S11-03 | Full scan + spawn + build + review cycle works with `.aegis/` paths |

**Sprint 11 total**: 36 points

#### Sprint 12: MCP Server -- Tier 2/3 Brain Backend
**Goal**: MCP server ที่ serve Tier 2 User Brain + Tier 3 Team Brain

| ID | Task | Agent | Effort | Dependencies | Acceptance Criteria |
|----|------|-------|--------|-------------|---------------------|
| S12-01 | - [ ] Design MCP server architecture: endpoints for Tier 2/3 read/write, brain promotion, pattern query | 📐 Iron Man | L(8) | S8-02 | Spec: tool list, auth model, data flow diagram |
| S12-02 | - [ ] Implement MCP server core: Tier 2 read/write (user preferences, feedback) | ⚡ Spider-Man | L(8) | S12-01 | Server runs locally, responds to Tier 2 queries |
| S12-03 | - [ ] Implement MCP server: Tier 3 read/write (team conventions via git backend) | ⚡ Spider-Man | L(8) | S12-01, S8-02 | Tier 3 sync works with git remote |
| S12-04 | - [ ] Implement MCP server: cross-project pattern query tool ("what patterns work across my projects?") | ⚡ Spider-Man | L(8) | S12-02 | Query returns aggregated patterns from Tier 2 |
| S12-05 | - [ ] Implement MCP server: sprint daemon via CronCreate (TinMan heartbeat replacement) | ⚡ Spider-Man | M(3) | S12-01 | Background health checks run on schedule |
| S12-06 | - [ ] Implement MCP server: learning loop scheduler via ScheduleWakeup (auto-learn trigger across projects) | ⚡ Spider-Man | M(3) | S12-02 | Pattern extraction triggers cross-project |

**Sprint 12 total**: 38 points

#### Sprint 13: MCP Polish + Security Audit
**Goal**: MCP server stable, security audited, documentation complete

| ID | Task | Agent | Effort | Dependencies | Acceptance Criteria |
|----|------|-------|--------|-------------|---------------------|
| S13-01 | - [ ] End-to-end test: Plugin + MCP working together (Tier 1 via Plugin in `.aegis/brain/`, Tier 2/3 via MCP) | 🎯 War Machine | L(8) | S12-04 | Full 3-tier brain lifecycle works |
| S13-02 | - [ ] Security audit: MCP server endpoints + brain data isolation between projects/users | 🛡️ Black Panther | L(8) | S12-03 | Audit report, zero CRITICAL findings |
| S13-03 | - [ ] Write MCP server setup guide (install, config, connect to Plugin) | 📜 Coulson | M(3) | S12-04 | Guide tested with fresh install |
| S13-04 | - [ ] Write migration guide: v8.x curl/bash -> v9.0 Plugin (+ optional MCP) including `.aegis/` consolidation + CLAUDE_*.md lift | 📜 Coulson | M(3) | S11-03 | Step-by-step guide verified with real project |
| S13-05 | - [ ] Implement MCP server graceful degradation -- Plugin works fine if MCP is down (Tier 2/3 unavailable, Tier 1 still works) | ⚡ Spider-Man | M(3) | S13-01 | Plugin does not error when MCP server is not running |
| S13-06 | - [ ] Offline emergency shell script -- minimal aegis commands that work without Plugin or MCP | ⚡ Spider-Man | M(3) | none | Shell script covers: aegis-start (scan only), aegis-status, aegis-doctor |

**Sprint 13 total**: 28 points

---

### Phase 4: Migration + Deprecation (Sprints 14-15) -- 6-Month Bridge

**Theme**: Migrate existing users, deprecate v8.x with aggressive 6-month schedule

#### Sprint 14: Migration Tooling + Beta Release
**Goal**: `aegis migrate` command ทำงานจริง, v9.0-beta released

| ID | Task | Agent | Effort | Dependencies | Acceptance Criteria |
|----|------|-------|--------|-------------|---------------------|
| S14-01 | - [ ] Implement `aegis migrate` full pipeline: detect v8 -> backup -> consolidate to `.aegis/` -> convert brain (Tier 1) -> convert permissions -> lift CLAUDE_*.md to plugin -> install plugin -> verify | ⚡ Spider-Man | XL(21) | S4-03, S11-03, S2-07 | Migrate v8.4 project เป็น v9.0 ได้ใน 1 command, project root clean |
| S14-02 | - [ ] Migrate brain data: v8.x `_aegis-brain/` -> `.aegis/brain/` Tier 1 structured brain + memory tool | ⚡ Spider-Man | L(8) | S9-02 | ทุก brain data ถูก preserve ใน correct `.aegis/brain/` Tier 1 slots |
| S14-03 | - [ ] Migration dry-run + rollback: `--dry-run` shows changes, `--rollback` restores v8.x state | ⚡ Spider-Man | L(8) | S14-01 | Dry-run output matches actual migration; rollback fully restores scattered layout |
| S14-04 | - [ ] Migration: lift CLAUDE_*.md from project root to plugin -- diff against defaults, backup customizations to `.aegis/backup/`, merge user rules into project CLAUDE.md | 🚀 Thor | M(3) | S14-01, S10-07 | Detect 5 root framework files; unchanged files deleted; customized files backed up + merged into single user CLAUDE.md; summary printed; idempotent; `--yes` flag for CI |
| S14-05 | - [ ] Internal dogfood: ใช้ v9.0-beta กับ AEGIS-Team repo เอง | 🧬 Nick Fury | L(8) | S14-01 | AEGIS-Team repo migrate สำเร็จ, `.aegis/` layout, 1 sprint ใช้งานได้ |
| S14-06 | - [ ] v9.0-beta tag + release notes + feedback issue templates | 🚀 Thor | M(3) | S14-05 | GitHub release with changelog |
| S14-07 | - [ ] Performance benchmark: v8.4 vs v9.0-beta (install time, first-task time, tokens/sp) | 🔧 Beast | M(3) | S14-05 | Benchmark report with comparison table |
| S14-08 | - [ ] Security regression test: ทุก deny-list entry ถูก block ใน v9.0 | 🎯 War Machine | M(3) | S14-05 | Zero security regressions |

**Sprint 14 total**: 57 points

#### Sprint 15: GA Release + Deprecation Enforcement
**Goal**: v9.0 GA, curl/bash enters aggressive deprecation schedule

| ID | Task | Agent | Effort | Dependencies | Acceptance Criteria |
|----|------|-------|--------|-------------|---------------------|
| S15-01 | - [ ] Fix remaining beta issues (budget: top 8 issues) | ⚡ Spider-Man | L(8) | S14-06 | Zero CRITICAL/HIGH issues open |
| S15-02 | - [ ] curl/bash installer: add "DEPRECATED" warning banner + auto-suggest `aegis migrate` | ⚡ Spider-Man | M(3) | S14-01 | Warning banner shown before every install |
| S15-03 | - [ ] Implement curl/bash GA+3mo behavior: error message + migration command output | ⚡ Spider-Man | M(3) | S15-02 | Script prints error after cutoff date, shows `aegis migrate` command |
| S15-04 | - [ ] Implement curl/bash GA+6mo behavior: remove from repo, keep only emergency offline shell | ⚡ Spider-Man | S(1) | S15-03 | Removal PR prepared, offline shell tested |
| S15-05 | - [ ] Update README.md: v9.0 install instructions (Plugin-first, MCP optional, `.aegis/` layout) | 📜 Coulson | M(3) | S15-01 | README reflects dual distribution model + single-folder layout |
| S15-06 | - [ ] v9.0 GA tag + signed release | 🚀 Thor | M(3) | S15-01 | Signed release on GitHub |
| S15-07 | - [ ] Publish Plugin to Claude Code registry | 🚀 Thor | M(3) | S15-06 | Plugin findable via `claude plugin search aegis` |
| S15-08 | - [ ] Publish MCP server package (npm/pip) | 🚀 Thor | M(3) | S15-06 | MCP server installable via `npm install -g aegis-mcp` |

**Sprint 15 total**: 27 points

---

**Total across all phases**: ~482 story points

| Phase | Sprints | Points | % of Total |
|-------|---------|--------|------------|
| Phase 1: Foundation Hardening | 1-3 | 70 | 15% |
| Phase 2: Claude 4.7 Native | 4-6 | 77 | 16% |
| Phase 2.5: Brain Tier Architecture | 7-9 | 94 | 19% |
| Phase 3: Distribution (Plugin + MCP) | 10-13 | 149 | 31% |
| Phase 4: Migration + Deprecation | 14-15 | 84 | 17% |

Note: Phase 3 increased from 138 to 149 pts in v3.1 (+3 for S10-00 MCP capability spike, +8 for S10-01b plugin abstraction layer). Sprint 10 is now 47 pts -- above 40pt threshold; recommend splitting into Sprint 10a (S10-00 spike + S10-01 research + S10-01b abstraction = 14pts) and Sprint 10b (S10-02 through S10-07 = 33pts) if team velocity < 40pts/sprint.

---

## 6. Risk Register

| ID | Risk | Likelihood | Impact | Mitigation | Owner |
|----|------|-----------|--------|------------|-------|
| R1 | Backward compat breaks -- v8.x projects fail after v9 migration | H | H | `aegis migrate --rollback`, 6-month bridge, dry-run mode | 📐 Iron Man |
| R2 | Claude Code Plugin API changes -- Anthropic modifies plugin API ใน 4.8 | M | H | S10-01b implements `IPluginAdapter` abstraction layer with versioned compatibility matrix; only adapter implementation changes on API update -- zero AEGIS core changes; pin API version; monitor Anthropic changelog | 📐 Iron Man |
| R3 | Memory tool migration data loss -- Tier 1 brain data lost during v8.x conversion | M | H | Dual-write strategy (memory tool + file backup), migration verification step, `--rollback` | ⚡ Spider-Man |
| R4 | User adoption resistance -- ผู้ใช้ไม่อยาก migrate จาก curl/bash ที่ "works fine" | H | M | Clear migration guide, show concrete benefits (install time, token savings, clean repo), 6-month bridge | 📜 Coulson |
| R5 | ~~Dual-write consistency -- memory tool vs file divergence~~ | ~~M~~ | ~~H~~ | **RESOLVED** via ADR-002 v3.1: file = authoritative source of truth, memory tool = read-through cache; no dual-write risk | ~~📐 Iron Man~~ |
| R5b | Security regression -- permission lockdown ทำให้ legitimate workflows break | M | H | Comprehensive allow-list testing, beta period สำหรับ permission feedback, per-project config override | 🛡️ Black Panther |
| R6 | Performance regression -- worktree isolation + memory tool + 3-tier brain เพิ่ม latency | L | M | Benchmark at Sprint 6, 9, and 14; worktree pooling + lazy tier loading ถ้า latency สูง | 🔧 Beast |
| R7 | Brain corruption during migration -- concurrent access ขณะ migrate | L | H | Lock file during migration, require no active Claude session, backup before start | ⚡ Spider-Man |
| R8 | Skill duplication -- AEGIS custom skills conflict กับ anthropic-skills | H | M | Explicit mapping table (ADR-005), deprecation warnings, phased retirement | 📐 Iron Man |
| R9 | Worktree cleanup failure -- orphan worktrees accumulate disk space | M | L | Cleanup hook on sprint close, `aegis-doctor` command checks for orphans | 🚀 Thor |
| R10 | Single-developer bottleneck -- bus factor 1 สำหรับ core framework | H | H | Document all architecture decisions, comprehensive test suite, contributor guide | 🧬 Nick Fury |
| R11 | 6-month bridge too short -- users ไม่ migrate ทัน ก่อน curl/bash removal | M | M | Monitor adoption metrics ที่ GA+2mo; ถ้า < 50% migrated, extend bridge 3 months | 🧬 Nick Fury |
| R12 | Brain tier migration data leak -- Tier 1 project data accidentally promoted to Tier 2 User Brain | M | H | Privacy scrubbing rules (strip project paths, secrets, task IDs), confirmation prompt, audit log | 🛡️ Black Panther |
| R13 | MCP server adoption gap -- power features (Tier 2/3, cross-project learning) stuck behind opt-in barrier ที่ผู้ใช้ส่วนใหญ่ไม่ install | H | M | Plugin UI prompt "Enable cross-project learning?" after 3rd project; one-command MCP install; show value via examples | 📐 Iron Man |
| R14 | Plugin/MCP feature drift -- boundary ว่า feature ไหนอยู่ฝั่งไหนไม่ clear ทำให้ team develop feature ซ้ำ | M | M | Maintain Plugin/MCP feature split table (Section 3) as living doc; quarterly review of boundary; single owner per feature | 📐 Iron Man |
| R15 | User CLAUDE.md customizations lost during v9 migration -- users ที่ edit CLAUDE.md, CLAUDE_safety.md ฯลฯ อาจ lose custom rules เมื่อ framework files ถูก lift ไป plugin | M | H | Migration script diffs each file against framework default; unchanged = safe delete; customized = backup to `.aegis/backup/claude-md-<timestamp>/` + merge into user-owned CLAUDE.md; interactive confirmation before deletion; `--yes` flag for CI | 🚀 Thor |
| R16 | MCP capability spike (S10-00) takes longer than 2-day timebox -- scope creep during investigation delays Sprint 10 start | M | M | Strict 2-day timebox enforced by Nick Fury; spike ends with GO/NO-GO decision regardless of completeness; incomplete spike = default to Plugin as planned (safe fallback); daily standup check during spike days | 📐 Iron Man |

---

## 7. Success Metrics

| KPI | v8.4 Baseline | v9.0 Target | Measurement |
|-----|--------------|-------------|-------------|
| **Install time** | ~2 min (curl + copy 150 files) | < 30s (plugin install) | Time from command to `/aegis-start` ready |
| **First-task time** | ~15 min (BLOCK 0 full for any task) | < 3 min (BLOCK 0 lite for small tasks) | Time from `/aegis-start` to first task IN_PROGRESS |
| **Tokens per story point** | ~31,481 (estimated) | < 15,000 | Total input+output tokens / completed story points |
| **Brain freshness (Tier 1)** | 0% (all resonance files empty) | > 60% files updated in last 30 days | `find .aegis/brain -mtime -30 \| wc -l` / total files |
| **Permission incidents** | Unknown (no tracking) | 0 critical in beta period | Count of unintended command executions |
| **Version consistency** | FAIL (4 different versions) | 100% PASS | `aegis-doctor` version check across all files |
| **Context budget efficiency** | ~12K tokens for full profile | < 5K tokens for full profile | Token count of loaded framework at session start |
| **Agent utilization** | 13 agents, some never used | 10 agents, all active per sprint | Count unique agents spawned per sprint |
| **Tier 2 adoption** | N/A (not exists) | > 30% users enable Tier 2 within 90 days of GA | Count users with `tier2_user: true` / total users |
| **MCP server install rate** | N/A (not exists) | > 15% users install MCP server within 90 days of GA | MCP server download count / plugin install count |
| **curl/bash migration rate** | 100% on curl/bash | > 80% on Plugin by GA+3mo | Plugin installs / total active installations |
| **Single-folder adoption** | 0% (8+ scattered paths) | 100% of v9.0 projects use `.aegis/` layout | `aegis-doctor` checks for `.aegis/` presence + no scattered v8 paths |

---

## 8. Backward Compatibility Strategy

### Version Support Matrix

| v8.x Version | v9.0 Migration Path | Support Until |
|-------------|---------------------|---------------|
| v8.4 | `aegis migrate` (full auto -- consolidate to `.aegis/`, brain to Tier 1, lift CLAUDE_*.md, permissions) | Jun 2027 (GA+6mo) |
| v8.3 | `aegis migrate` (auto + manual version fix first) | Apr 2027 (GA+4mo) |
| v8.2.x | `aegis migrate` (auto + manual permission fix first) | Mar 2027 (GA+3mo) |
| < v8.2 | Manual reinstall recommended | Not supported |

### Migration Command Spec

```bash
# Full migration (detects v8.x version automatically)
aegis migrate --from v8 --to v9

# Dry run (show changes, don't apply)
aegis migrate --from v8 --to v9 --dry-run

# Migrate specific component only
aegis migrate brain         # v8.x _aegis-brain/ -> .aegis/brain/ Tier 1
aegis migrate permissions   # settings.json bypassPermissions -> allowEdits
aegis migrate agents        # agent templates -> plugin format
aegis migrate consolidate   # scatter -> .aegis/ single folder
aegis migrate claude-md     # lift CLAUDE_*.md framework files to plugin

# Brain tier setup (post-migration, opt-in)
aegis brain init --tier2   # create ~/.claude/aegis-brain/ (User Brain)
aegis brain init --tier3 --backend git --remote <url>  # Team Brain

# Gitignore mode (set during init or change later)
aegis config set gitignore_mode shared    # default
aegis config set gitignore_mode private
aegis config set gitignore_mode paranoid

# Rollback (restores v8.x state from backup)
aegis migrate --rollback
```

**Migration steps (internal)**:
1. Detect current version from multiple sources (VERSION, CLAUDE.md, install.sh)
2. Create backup at `_aegis-backup-v8/` (full copy of .claude/ + _aegis-brain/ + root CLAUDE_*.md)
3. Consolidate scattered dirs into `.aegis/` (brain/, cache/, logs/, output/)
4. Convert settings.json permissions (bypassPermissions -> allowEdits + scoped allow)
5. Convert flat brain files to `.aegis/brain/` Tier 1 structured format + memory tool entries
6. Lift CLAUDE_*.md: diff against framework defaults, backup customizations, delete framework copies, merge user rules into root CLAUDE.md
7. Update agent templates (remove retired agents, update model refs)
8. Install Plugin (if plugin registry available)
9. Generate `.gitignore` block based on `gitignore_mode` setting (default: shared)
10. Verify: run `aegis-doctor` to check consistency + `.aegis/` layout
11. Report: show what changed, what needs manual review
12. (Optional) Prompt: "Enable Tier 2 User Brain? `aegis brain init --tier2`"

### CLAUDE_*.md Lift Process (v8.x -> v9.0)

| Step | Action | Detail |
|------|--------|--------|
| 1 | Detect | Scan project root for CLAUDE.md, CLAUDE_safety.md, CLAUDE_agents.md, CLAUDE_skills.md, CLAUDE_lessons.md |
| 2 | Diff | Compare each file against framework default (shipped in plugin package) |
| 3 | Classify | `unchanged` = safe to delete, `customized` = needs backup + merge |
| 4 | Backup | Customized files -> `.aegis/backup/claude-md-<timestamp>/` |
| 5 | Merge | Extract user-specific rules from customized files -> single root `CLAUDE.md` (user-owned) |
| 6 | Delete | Remove framework-default copies from project root |
| 7 | Report | Print summary: "Removed N framework files, preserved M user customizations in CLAUDE.md" |
| 8 | Verify | Idempotent -- safe to re-run, won't double-process already-lifted files |

### Deprecation Timeline (6-Month Bridge)

| Date | Action |
|------|--------|
| v9.0-beta (Oct 2026) | curl/bash and Plugin both work; beta feedback collected |
| v9.0 GA (Dec 2026) | Plugin = default install; curl/bash shows "DEPRECATED" warning banner |
| GA + 3mo (Mar 2027) | curl/bash prints error message + auto-suggests `aegis migrate` command |
| GA + 6mo (Jun 2027) | curl/bash REMOVED from repo; emergency offline shell script retained |

### Brain Format Migration (v8.x -> v9.0 .aegis/brain/ Tier 1)

| v8.x Location | v9.0 Location | Memory Type |
|---------------|---------------|-------------|
| `_aegis-brain/instincts/promoted/` | `.aegis/brain/instincts/promoted/` + memory tool `project` | project |
| `_aegis-brain/instincts/active/` | `.aegis/brain/instincts/active/` + memory tool `project` | project |
| `_aegis-brain/resonance/team-conventions.md` | `.aegis/brain/resonance/team-conventions.md` + memory tool `project` | project |
| `_aegis-brain/resonance/evolved-patterns.md` | `.aegis/brain/resonance/evolved-patterns.md` + memory tool `project` | project |
| `_aegis-brain/resonance/anti-patterns.md` | `.aegis/brain/resonance/anti-patterns.md` + memory tool `project` | project |
| `_aegis-brain/sprints/` | `.aegis/brain/sprints/` (unchanged structure, file-based only) | N/A |
| `_aegis-brain/tasks/` | `.aegis/brain/tasks/` (unchanged structure, file-based only) | N/A |
| `_aegis-brain/skill-cache/` | `.aegis/cache/skill-cache/` (NOT tracked in git) | N/A |

Note: user preferences / cross-project patterns ไม่ถูก migrate อัตโนมัติ -- user ต้อง explicit `aegis brain promote --to-user` หลัง migration เพื่อ populate Tier 2

---

## 9. Open Questions

| # | Question | Status | Impact | Blocker For |
|---|----------|--------|--------|-------------|
| Q1 | ~~Claude Code Plugin API GA เมื่อไหร่?~~ | CLOSED -- proceed with Plugin, fallback to sideload if API not GA | n/a | n/a |
| Q2 | ~~`memory_20250818` tool size limit per entry?~~ | CLOSED -- chunk large brain files into multiple entries (< 4KB each) | n/a | n/a |
| Q3 | ~~Worktree `read-only` mode support?~~ | CLOSED -- implement via hook-level enforcement (guard-write blocks writes in review worktree) | n/a | n/a |
| Q4 | จะ rename agents จาก Marvel characters เป็นชื่อ generic หรือไม่? (trademark risk) | OPEN | ถ้า rename ต้อง update ทุก doc + user muscle memory break | Phase 4 |
| Q5 | Tier 3 Team Brain: git backend ควร support monorepo (single repo, multi-project) หรือ multi-repo? | OPEN | Architecture complexity ต่างกันมาก | Sprint 8 |
| Q6 | `anthropic-skills:*` มี skill ไหนที่ overlap กับ AEGIS orchestrator/sprint-manager โดยตรง? | OPEN | ถ้ามี ต้อง decide ว่า adopt หรือ keep custom | Sprint 11 |
| Q7 | 6-month bridge period เพียงพอไหม? ควรมี adoption checkpoint ที่ GA+2mo เพื่อ decide ว่า extend หรือไม่? | OPEN | ถ้า adoption < 50% ที่ checkpoint ต้อง extend | Sprint 15 |
| Q8 | CI/CD pipeline integration -- ควรมี `aegis ci` mode ที่ run ใน headless/non-interactive? | OPEN | Enterprise users ต้องการ, แต่เพิ่ม scope อีก | Post-GA |
| Q9 | Tier 2 User Brain ควร encrypt at rest by default หรือ opt-in? (performance vs security trade-off) | OPEN | Sensitive user patterns อาจ leak ถ้า machine compromised | Sprint 7 |
| Q10 | ~~`.aegis/output/` ควร track ใน git (shared mode) หรือ ignore?~~ | CLOSED -- Selective tracking. Specs/architecture/current ISO docs tracked, drafts/history ignored. See gitignore sentinel block in Section 3. | n/a | n/a |
| Q11 | MCP spike outcome -- if S10-00 finds MCP coverage >= 90%, do we drop Plugin entirely or keep both (Plugin + MCP)? | OPEN | Major architectural pivot if MCP-only is viable; Plugin development (S10-01 through S11-07) may be unnecessary | Sprint 10 |

---

## 10. Appendix

### Glossary

| Term | Definition |
|------|-----------|
| **AEGIS** | Agent Ensemble for Guided Intelligence Systems -- agent team framework สำหรับ Claude Code |
| **`.aegis/`** | Single hidden folder ที่ project root -- รวม brain, config, cache, logs, output ทั้งหมดของ AEGIS (v9.0) |
| **Brain** | Persistent memory system ของ AEGIS -- organized into 3 tiers |
| **Tier 1 (Project Brain)** | Per-repo brain ที่ `.aegis/brain/` -- default ON, managed by Plugin |
| **Tier 2 (User Brain)** | Per-machine brain ที่ `~/.claude/aegis-brain/` -- opt-in, managed by MCP |
| **Tier 3 (Team Brain)** | Org-level shared brain (S3/git) -- opt-in, managed by MCP + team admin |
| **BLOCK 0** | Pre-work documentation gate ที่ต้องผ่านก่อน task เริ่ม |
| **Gate** | Quality checkpoint (0-5) ที่ task ต้องผ่าน |
| **Instinct** | Learned rule ที่ agents follow -- promoted = enforced, active = suggested |
| **Resonance** | Project identity + accumulated wisdom ใน brain |
| **Worktree** | Git worktree -- separate working directory ที่ share .git directory |
| **SPOF** | Single Point of Failure |
| **Plugin** | Claude Code Plugin -- primary distribution mechanism สำหรับ AEGIS (agents, commands, framework rule injection, Tier 1) |
| **MCP** | Model Context Protocol -- optional add-on สำหรับ Tier 2/3 brain + power features |
| **Bridge** | 6-month transition period ที่ curl/bash installer ยัง work ระหว่างที่ users migrate to Plugin |
| **Gitignore modes** | 3 modes for `.aegis/` git tracking: `shared` (track brain, ignore cache/logs), `private` (ignore all), `paranoid` (ignore .aegis/ + .claude/) |
| **Plugin-injected rules** | Framework rules (safety, agents, skills) ที่ plugin prepend เข้า session context at runtime แทนที่ root CLAUDE_*.md files |

### File Location Reference

| Purpose | v8.4 Path | v9.0 Path |
|---------|-----------|-----------|
| Main config | `CLAUDE.md` + `.claude/settings.json` | `.aegis/config.yaml` + `.claude/settings.json` |
| Framework rules | `CLAUDE.md` + `CLAUDE_safety.md` + `CLAUDE_agents.md` + `CLAUDE_skills.md` + `CLAUDE_lessons.md` (5 root files) | Plugin-injected at runtime from `~/.claude/plugins/aegis/` |
| User project rules | Mixed into CLAUDE.md (framework + user) | Root `CLAUDE.md` (user-owned only, optional) |
| Agent templates | `.claude/agents/*.md` | Plugin package `~/.claude/plugins/aegis/agents/` (runtime loaded) |
| Skills | `skills/*.md` | `anthropic-skills:*` + 5 custom skills in plugin |
| Commands | `.claude/commands/*.md` (10 files) | `.claude/commands/*.md` (12 consolidated, plugin-registered) |
| Hooks | `.claude/hooks/*.sh` (6 files) | `.claude/hooks/*.sh` (3 core hooks, plugin-registered) |
| Brain (Tier 1) | `_aegis-brain/` (flat, file-only) | `.aegis/brain/` (structured) + `memory_20250818` |
| Brain (Tier 2) | N/A | `~/.claude/aegis-brain/` + MCP server |
| Brain (Tier 3) | N/A | Shared backend (git/S3) + MCP server |
| Output | `_aegis-output/` | `.aegis/output/` |
| Logs | `_aegis-brain/logs/` | `.aegis/logs/` (NOT tracked in git) |
| Cache | `_aegis-brain/skill-cache/` | `.aegis/cache/` (NOT tracked in git) |
| Version | hardcoded ใน 4+ files | `VERSION` file (single source) |

### Related Work

| Source | What AEGIS Adopted | v9 Relevance |
|--------|-------------------|--------------|
| Karpathy LLM Wiki | Index-ingest-lint pattern สำหรับ knowledge management | 3-tier brain promotion flow inspired by wiki curation model |
| VoltAgent awesome-design-md | Spec format conventions (soul paragraph, matrix tables, do/don't) | Iron Man specs continue using this format |
| ECC Patterns | Error-correction-code inspired redundancy ใน agent decisions | Captain America fallback = ECC parity agent |
| Metaswarm | Post-tool-use validation pattern | Keep post-tool-use.sh hook architecture |

---

*Document version: 3.1*
*Author: 📐 Iron Man (System Architect)*
*Status: DRAFT -- reflects 4 confirmed architectural decisions + Nick Fury post-Loki review decisions*
*Decisions confirmed: 2026-04-18*
*Last updated: 2026-04-18 (v3.1 -- Nick Fury post-Loki resolution)*

**Changelog:**
- v3.1: ADR-002 revised to file-as-source-of-truth model; S9-03 conflict resolution via Nick Fury priority rule; S10-00 MCP capability spike added; S10-01b plugin abstraction layer added; ADR-006 brain merge strategy added; gitignore sentinel markers; R5 resolved, R16 added; Q10 closed, Q11 added; Sprint 10 recalculated to 47pts; total effort 471 -> 482 story points
- v3.0: Single-folder `.aegis/` layout, ADR-007, auto-gitignore 3 modes, CLAUDE.md ownership model, plugin-injected rules
- v2.0: Plugin primary + MCP optional, 3-Tier Brain, 15 sprints
- v1.0: Initial plan, 10 sections, 12 sprints
