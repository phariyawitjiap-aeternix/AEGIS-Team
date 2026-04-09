<p align="center">
  <img src="https://img.shields.io/badge/version-8.4-blue?style=for-the-badge" alt="Version 8.4"/>
  <img src="https://img.shields.io/badge/agents-13-green?style=for-the-badge" alt="13 Agents"/>
  <img src="https://img.shields.io/badge/skills-30-orange?style=for-the-badge" alt="30 Skills"/>
  <img src="https://img.shields.io/badge/commands-27-yellow?style=for-the-badge" alt="27 Commands"/>
  <img src="https://img.shields.io/badge/gates-6-red?style=for-the-badge" alt="6 Gates"/>
  <img src="https://img.shields.io/badge/hooks-6-teal?style=for-the-badge" alt="6 Hooks"/>
  <img src="https://img.shields.io/badge/ISO--29110-compliant-brightgreen?style=for-the-badge" alt="ISO 29110"/>
  <img src="https://img.shields.io/badge/Claude_4.x-1M_context-blueviolet?style=for-the-badge" alt="Claude 4.x"/>
  <img src="https://img.shields.io/badge/license-MIT-purple?style=for-the-badge" alt="MIT License"/>
</p>

# :shield: AEGIS v8.4 — AI Agent Team Framework for Claude Code

> **"Context is King, Memory is Soul"**
>
> :dna: Nick Fury · 13 Marvel Agents · 30 Skills · 27 Commands · 6-Gate Quality · 6 Hooks · ISO 29110 · Claude 4.x 1M Context

---

## :sparkles: What's new in v8.4

**9 patterns adopted from global research** — zero cloud uploads, all local.

### 4 patterns from [affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code) (145k ⭐)
- **Runtime hook profile switching** — `AEGIS_HOOK_PROFILE=minimal|standard|strict`, live-tunable without editing files
- **Batched Stop-time format/typecheck** — 10 edits = 1 `tsc` run (was 10), via accumulator pattern
- **Config protection hook** — blocks agents from editing `.eslintrc`/`biome`/`tsconfig` to "fix" lint errors
- **Instinct lifecycle** — confidence-scored learned patterns (`pending → active → promoted → retired`), enforced by Loki

### 5 patterns from [VoltAgent/awesome-design-md](https://github.com/VoltAgent/awesome-design-md) (35k ⭐)
- **DESIGN.md 9-section visual design system** — new `design-system-md` skill (Wasp-owned)
- **Do's and Don'ts** mandatory in every spec — Loki auto-CONDITIONAL if missing
- **Agent Prompt Guide footer** — every master spec ends with copy-paste prompts for Spider-Man/Thor
- **Locked H2 skeletons** for all 9 ISO 29110 document types — Coulson validates before write
- **Matrix tables + soul paragraphs** — Iron Man specs open with intent, use tables for 3+ discrete values

### New artifacts
- `/aegis-instinct` · `/aegis-evolve` commands
- `skills/design-system-md.md`
- `.claude/hooks/guard-write.sh` · `post-edit-accumulate.sh` · `run-with-flags.sh`
- `_aegis-brain/instincts/` (pending/active/promoted/retired)
- `_aegis-output/design/` (for `DESIGN.md`)

---

## What is AEGIS?

AEGIS (**A**utonomous **E**nhanced **G**roup **I**ntelligence **S**ystem) — production-grade AI agent team framework for Claude Code. 13 Marvel-character agents, 14-stage SDLC pipeline, 6-gate quality (including a mandatory pre-work gate), ISO 29110 compliance, JIRA-like PM, self-enforcing instinct system, visual design discipline. :dna: ยิ่งใช้ยิ่งเก่ง.

---

## :rocket: New Install (one command)

**Step 1 — Install prerequisites (skip if already done):**

```bash
brew install node && npm install -g @anthropic-ai/claude-code
```

**Step 2 — Initialize your project:**

```bash
cd ~/Documents/my-project && git init && git commit --allow-empty -m "init"
```

**Step 3 — Install AEGIS:**

```bash
bash <(curl -sL https://raw.githubusercontent.com/phariyawitjiap-aeternix/AEGIS-Team/main/install-remote.sh) --profile full --project-name "My Project"
```

> :bulb: Profile options: `minimal` (7 skills) · `standard` (15 skills) · `full` (30 skills)

**Step 4 — Set permissions (one-time):**

```bash
cat > ~/.claude/settings.json << 'EOF'
{"permissions":{"defaultMode":"bypassPermissions","allow":["Bash","Edit","Write","Read","Glob","Grep","Agent","TeamCreate","TeamDelete","SendMessage"]},"env":{"CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS":"1"}}
EOF
```

**Step 5 — Start:**

```bash
claude --dangerously-skip-permissions
```

Then type `/aegis-start`. Nick Fury will scan your project, check **BLOCK 0** (required ISO docs + kanban), and begin autonomously.

**What you get with a fresh install:**

| | |
|--|--|
| :dna: **13 Marvel agents** | Nick Fury, Iron Man, Spider-Man, Black Panther, Loki, Coulson, Thor + 6 more |
| :lock: **BLOCK 0 gate** | Coulson creates PM.01 + SI.01 + SI.02 + kanban before any code is written |
| :brain: **Claude 4.x models** | Opus 4.6 (1M ctx) for thinkers · Sonnet 4.6 (1M ctx) for builders · Haiku 4.5 for scanners |
| :chart_with_upwards_trend: **Adaptive thinking** | Each agent uses the right reasoning depth (`max` → `low`) |
| :scroll: **ISO 29110** | 14 work products, activity-time generation, traceability matrix |

---

## :arrows_counterclockwise: Upgrade Existing Install

> :warning: **Exit Claude Code before upgrading** — Claude caches files at session start

**Step 1 — Run the upgrade:**

```bash
cd ~/Documents/my-project
bash <(curl -sL https://raw.githubusercontent.com/phariyawitjiap-aeternix/AEGIS-Team/main/install-remote.sh) --upgrade
```

**Step 2 — Restart:**

```bash
claude --dangerously-skip-permissions
```

**What `--upgrade` does:**

| Step | Action |
|:----:|--------|
| 1 | :lock: **Backup** `_aegis-brain/`, `iso-docs/`, `CLAUDE_lessons.md` → `_aegis-backup/` |
| 2 | :wastebasket: **Remove** old agents, commands, references, teams, skills |
| 3 | :arrow_down: **Download** latest AEGIS from GitHub (to `/tmp/`, auto-cleaned) |
| 4 | :package: **Install** 13 Marvel agents, 27 commands, 14 references, 7 teams, 30 skills, 6 hooks |
| 5 | :mag: **Verify** all files present + migrate old versions (v6→v8, v7→v8, v8.2→v8.3→v8.4) + auto-detect profile from project-identity.md |

**What's new in v8.4:**

| Change | Details |
|--------|---------|
| :zap: Hook profiles | Runtime switching via `AEGIS_HOOK_PROFILE` env var (minimal/standard/strict) |
| :stopwatch: Batched check | `post-edit-accumulate` + Stop-time `tsc`/`biome` — 10× speedup on multi-file edits |
| :lock: Config protection | `guard-write.sh` blocks agent edits to `.eslintrc`/`biome`/`tsconfig`/`pyproject.toml` |
| :brain: Instinct lifecycle | Confidence-scored patterns enforced by Loki (new `/aegis-instinct`, `/aegis-evolve`) |
| :art: DESIGN.md skill | New `design-system-md` skill — 9-section visual design system (Wasp-owned) |
| :bookmark: Do's/Don'ts | Mandatory in every spec — Loki auto-CONDITIONAL if missing |
| :rocket: Agent Prompt Guide | Every master spec ends with copy-paste prompts for downstream agents |
| :clipboard: Locked ISO H2 | Coulson validates frozen H2 skeletons for all 9 ISO 29110 doc types |
| :bar_chart: Matrix tables | Iron Man specs use tables for 3+ discrete values, open with "soul paragraph" |

**Previous v8.3 changes (still in effect):**

| Change | Details |
|--------|---------|
| :superhero: Agent renames | All 13 agents renamed to Marvel characters matching their behavior |
| :lock: BLOCK 0 gate | Coulson enforced as mandatory pre-work checkpoint before any task starts |
| :brain: Claude 4.x models | Haiku agents updated to `claude-haiku-4-5-20251001`; Opus/Sonnet get 1M context |
| :6: Gate 0 added | Quality pipeline is now 6 gates (Gate 0 = pre-work docs) |

**:lock: NEVER touched by upgrade:** `_aegis-brain/` (tasks, sprints, patterns, learnings), `iso-docs/`, `CLAUDE_lessons.md`, project source code

---

## :movie_camera: See It In Action

### `/aegis-start` — Mother Brain activates with heartbeat

```
🛡️ ═══════════════════════════════════════════════════
🛡️  AEGIS v8.4 — Session Started
🛡️  "Context is King, Memory is Soul"
🛡️ ═══════════════════════════════════════════════════

📋 Project:    My SaaS App
📅 Date:       2026-03-30
🎚️  Profile:    full (25 skills)
🔐 Autonomy:   L3 — Autonomous (Mother Brain active)
📊 Context:    8% used

🧬 Mother Brain: ONLINE — persistent heartbeat active

💓 Heartbeat: Scanning project state...
   Mother Brain will continuously monitor and dispatch agents.
   She never sleeps until the session ends.

👀 Watch: Shift+Down to view agent detail | Shift+Up to return
🛑 Stop: Ctrl+C to interrupt | /aegis-mode --autonomy L1 for manual
```

```
🧬 Mother Brain: Scan complete.

📊 Scan Results:
  ├── Git: clean (main, 12 commits)
  ├── Tests: PASS (28/28)
  ├── Sprint: sprint-2 active (day 3/5)
  ├── Kanban: 3 TODO, 1 IN_PROGRESS, 2 DONE
  ├── QA: pending for PROJ-T-007
  ├── Compliance: 8/11 ISO docs current
  └── Tech Debt: 5 TODOs, 2 FIXMEs

🎯 Decision: P2.5 — Active sprint, pick next TODO from kanban
   Task: PROJ-T-008 "Add payment webhook handler" [5pts]
   Rationale: Highest priority TODO in sprint-2, spec exists.

⚡ Action: Spawning build team...
   → 📐 Sage: Validate spec for PROJ-T-008
   → ⚡ Bolt: Implement webhook handler
   → 🛡️ Vigil: Code review (Gate 1)

💓 Heartbeat: 3 agents alive | context 15% | next pulse in 30s
```

### `/aegis-status` — Live dashboard with heartbeat

```
╔══════════════════════════════════════════════════════════════════╗
║  AEGIS Team Status                              v8.4            ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                 ║
║  💓 Mother Brain: ALIVE (last pulse: 8s ago)                    ║
║     Cycle: #4 | Agents spawned: 3 | Tasks done: 2              ║
║                                                                 ║
║  Agent          Task                    Status      Progress    ║
║  ─────────────  ──────────────────────  ──────────  ────────    ║
║  📐 Sage        Validating spec         ✅ Done     100%        ║
║  ⚡ Bolt        Implementing webhook    🔄 Working  60%         ║
║  🛡️ Vigil       Waiting for Bolt        ⏳ Waiting  —           ║
║                                                                 ║
║  Pipeline: Build Team [████████████░░░░░░░░] Step 2/3           ║
║  Context: 22% used 🟢 | ~78% remaining                         ║
║                                                                 ║
╚══════════════════════════════════════════════════════════════════╝
```

### `/super-spec` — Human Q&A then full autonomy

```
📐 Sage: I've analyzed your brief and researched similar systems.
Before I write the spec, I need your input:

📌 BUSINESS CONTEXT
1. Who are the primary users?
2. What specific problem does this solve?
3. How do they solve this today?

📌 SCOPE & PRIORITIES
4. What are the MUST-HAVE features for v1? (top 3-5)
5. What is explicitly OUT of scope?

📌 CONSTRAINTS
7. Tech stack preference?
8. Timeline pressure?

📌 SUCCESS
10. How will you measure success?
```

> :bulb: After you answer and approve the spec, Mother Brain enters **Spec Proxy mode** — she answers all team questions using your approved spec. No more interruptions.

```
🧬 Mother Brain: Spec approved. Entering Spec Proxy mode.
   I now have full context from BRD + SRS + UX Blueprint.
   I will answer team questions on your behalf.
   I'll only ask you for business decisions outside the spec.

💓 Resuming full autonomy (L3)...
   → Running /aegis-breakdown from spec...
   → Running /aegis-sprint plan...
   → Spawning build team for first task...
```

---

## :busts_in_silhouette: The 13 Agents

| # | Agent | Model | Role |
|:-:|:------|:-----:|:-----|
| :dna: | **Nick Fury** | `opus 4.6` | Autonomous Controller — scans, decides, spawns teams, enforces BLOCK 0 |
| :compass: | **Captain America** | `opus 4.6` | Navigator/Lead — orchestrates, synthesizes, retros |
| :triangular_ruler: | **Iron Man** | `opus 4.6` | Architect — specs, system design, ADRs |
| :zap: | **Spider-Man** | `sonnet 4.6` | Implementer — writes code, builds features |
| :shield: | **Black Panther** | `sonnet 4.6` | Reviewer — 5-pass code review, quality gates |
| :red_circle: | **Loki** | `opus 4.6` | Devil's Advocate — challenges assumptions, finds flaws |
| :wrench: | **Beast** | `haiku 4.5` | Scanner/Research — programmatic codebase analysis |
| :art: | **Wasp** | `sonnet 4.6` | UX Designer — UI/UX, accessibility |
| :paintbrush: | **Songbird** | `haiku 4.5` | Content Creator — docs, changelogs |
| :dart: | **War Machine** | `sonnet 4.6` | QA Lead — test strategy, release gate |
| :microscope: | **Vision** | `haiku 4.5` | QA Executor — runs tests, reports raw results |
| :scroll: | **Coulson** | `haiku 4.5` | Compliance — ISO 29110, BLOCK 0 gate owner |
| :rocket: | **Thor** | `sonnet 4.6` | DevOps — deploy, health check, rollback |

> **Routing:** Opus (1M ctx, max thinking) → Sonnet (1M ctx, medium thinking) → Haiku (200k ctx, low thinking)

---

## :factory: SDLC Pipeline

```
BLOCK 0 (Coulson) → BREAKDOWN → SPRINT PLAN
     ↓
[ SPEC → BUILD → REVIEW(G1) → QA(G2) → COMPLY(G3) ] → CLOSE → DEPLOY(G4) → MONITOR(G5) → FEEDBACK
  └──────────────── per-task loop ─────────────────┘
```

> BLOCK 0 is a hard gate. No task enters the per-task loop until PM.01 + SI.01 + SI.02 + kanban exist.

---

## :vertical_traffic_light: 6-Gate Quality System

| Gate | Name | Owner | Blocks |
|:----:|:-----|:------|:-------|
| **G0** | **Pre-Work Docs** | **Coulson** | **PM.01 + SI.01 + SI.02 + Epic/Task/Sub-task + Kanban must exist** |
| G1 | Code Review | Black Panther | 5-pass: correctness, security, performance, maintainability, compliance |
| G2 | Product QA | War Machine | Test plan, execution, coverage, verdict |
| G3 | Compliance | Coulson | ISO 29110 work products, traceability matrix |
| G4 | Deploy | Thor | Build, deploy, health check, smoke test |
| G5 | Monitor | Thor | Post-deploy health, metrics, rollback readiness |

> Gate 0 is enforced by Nick Fury at session start and before every IN_PROGRESS transition.

---

## :keyboard: Commands (23)

| Command | Purpose |
|:--------|:--------|
| `/aegis-start` | Begin session — Nick Fury activates + checks BLOCK 0 |
| `/aegis-retro` | End session — retrospective + lessons |
| `/aegis-handoff` | Handoff document for next session |
| `/aegis-pipeline` | Full analysis pipeline (all agents) |
| `/aegis-status` | Check all agent progress |
| `/aegis-mode` | Switch profile: `minimal` / `standard` / `full` |
| `/aegis-context` | Context budget usage + token breakdown |
| `/aegis-distill` | Compress conversation context |
| `/aegis-memory` | Read/write persistent brain |
| `/aegis-verify` | Verify outputs meet acceptance criteria |
| `/aegis-launch` | Launch specific agent with task |
| `/aegis-flow` | Visualize pipeline flow + dependencies |
| `/aegis-team-build` | Spawn build team (Iron Man + Spider-Man + Black Panther) |
| `/aegis-team-review` | Spawn review team (Black Panther + Loki + Beast) |
| `/aegis-team-debate` | Spawn debate team (Iron Man + Loki + Captain America) |
| `/aegis-kanban` | Task board with WIP limits |
| `/aegis-breakdown` | Decompose stories → epics → tasks |
| `/aegis-sprint` | Sprint ceremonies — plan, standup, review, close |
| `/aegis-qa` | QA pipeline — plan, run, report, gate |
| `/aegis-compliance` | ISO 29110 document management + audit |
| `/aegis-deploy` | Deploy pipeline — build, deploy, health, monitor |
| `/aegis-dashboard` | Project dashboard — burndown, metrics, workload |

---

## :jigsaw: Skill Profiles

| Profile | Skills | Use Case |
|:--------|:------:|:---------|
| `minimal` | 7 | Quick tasks, small projects |
| `standard` | 15 | Normal development (default) |
| `full` | 29 | Enterprise, full SDLC |

Switch: `/aegis-mode minimal` · `/aegis-mode standard` · `/aegis-mode full`

---

## :star2: Key Features

- **BLOCK 0 Pre-Work Gate** — Coulson generates PM.01 + SI.01 + SI.02 + kanban before any code is written. Nick Fury hard-blocks the team until complete.
- **Claude 4.x 1M Context** — Opus 4.6 and Sonnet 4.6 agents operate with 1M token context windows. No more session fragmentation on large codebases.
- **Adaptive Thinking** — Each agent uses the right reasoning depth: `max` for architecture, `high` for review, `medium` for implementation, `low` for scanning.
- **Programmatic Scanning (Beast)** — `code_execution_20260120` lets Beast scan 100s of files in a single round-trip, not N sequential reads.
- **Self-Evolving Intelligence** — auto-learn from tasks, shared cache across agents, skill evolution
- **ISO 29110 Compliance** — 14 work products, activity-time generation, audit trail
- **Sprint/Scrum/Kanban** — ceremonies, velocity tracking, WIP limits, burndown
- **Architecture Decision Records (ADRs)** — structured decisions with status tracking
- **Tech Debt Tracking** — continuous scanning, sprint-integrated, priority scoring
- **Persistent Brain** — resonance, learnings, retrospectives survive across sessions

---

## :thailand: Thai Triggers (ภาษาไทย)

| พิมพ์ | Triggers |
|:------|:---------|
| "เริ่ม session" | `/aegis-start` |
| "รีวิวโค้ดให้" | code-review + Black Panther |
| "ทีมสร้าง" | `/aegis-team-build` |
| "ทีมรีวิว" | `/aegis-team-review` |
| "ถกเถียง" | `/aegis-team-debate` |
| "เช็ค context" | `/aegis-context` |
| "สถานะ" | `/aegis-status` |
| "จบ session" | `/aegis-retro` |
| "ส่งต่อ" | `/aegis-handoff` |
| "วางแผน" | orchestrator + Captain America |
| "เขียน spec" | super-spec + Iron Man |
| "ตรวจความปลอดภัย" | security-audit |
| "หนี้เทคนิค" | tech-debt-tracker |
| "ท้าทายการตัดสินใจ" | adversarial-review + Loki |

---

## :file_folder: Directory Structure

```
your-project/
├── CLAUDE.md                    # Hub file (loaded every session)
├── CLAUDE_agents.md             # Agent quick reference
├── CLAUDE_skills.md             # Skill catalog
├── CLAUDE_safety.md             # Safety rules
├── CLAUDE_lessons.md            # Accumulated learnings
├── .claude/
│   ├── commands/                # 22 slash commands
│   ├── agents/                  # 13 Marvel agent personas
│   ├── references/              # 13 protocol files
│   ├── teams/                   # Team configurations
│   └── settings.json            # Permissions + env
├── skills/                      # 29 skill definitions
└── _aegis-brain/                # Persistent memory (never overwritten by upgrade)
    ├── resonance/               # Project identity + conventions + ADRs
    ├── learnings/               # Accumulated lessons
    ├── tasks/                   # Epic/Task/Sub-task hierarchy (BLOCK 0)
    ├── sprints/                 # Sprint plans + kanban boards
    └── logs/                    # Activity tracking
```

---

## :sparkles: Version History

### v8.4 (current) — Global Patterns Adopted

| Feature | Before (v8.3) | After (v8.4) |
|:--------|:-------------|:-------------|
| **Hook config** | Edit settings.json to toggle | Live env var: `AEGIS_HOOK_PROFILE=minimal\|standard\|strict` |
| **Quality checks** | Per-edit or Gate 1 only | Batched at Stop time (10× faster) |
| **Lint configs** | Agents could weaken rules | Blocked by `guard-write.sh` |
| **Lessons** | Freeform markdown | Confidence-scored instincts with auto-promotion |
| **Visual design** | No artifact | `DESIGN.md` 9-section skeleton (Wasp-owned) |
| **Spec guardrails** | Optional | Mandatory Do's/Don'ts + Agent Prompt Guide |
| **ISO 29110 docs** | Variable structure | Frozen H2 skeletons per doc type |
| **Iron Man specs** | Prose-heavy | Matrix tables + soul paragraphs |

### v8.3 — Marvel Rename + BLOCK 0 + Claude 4.x

| Feature | Before (v8.2) | After (v8.3) |
|:--------|:-------------|:-------------|
| **Agent names** | Sage, Bolt, Vigil, Havoc... | 13 Marvel characters (Nick Fury, Iron Man, ...) |
| **Pre-work gate** | None | BLOCK 0 — Coulson enforces PM.01+SI.01+SI.02 |
| **Haiku Models** | Mixed (3-5 / 4-5) | All standardized to `claude-haiku-4-5-20251001` |
| **Context window** | 200k | 1M (Opus 4.6 / Sonnet 4.6) |
| **Quality gates** | 5 | 6 (Gate 0 = pre-work docs) |
| **Thinking** | Manual | `ultrathink` keyword + adaptive thinking guide |

---

## :handshake: Credits

| Contribution | Credit |
|:-------------|:-------|
| Oracle Brain (ψ/) | **Nat Weerawan** — [Soul-Brews-Studio](https://github.com/Soul-Brews-Studio) |
| MAW Framework | **Soul-Brews-Studio** |
| Claude Thailand Community | **Joon**, **Mickey** (AX Digital), **New** (Debox) |
| Claude Code Agent Teams | **Anthropic** |

---

## :scroll: License

MIT License. See [LICENSE](LICENSE) for details.

---

<p align="center">
  <b>Built with :brain: by the AEGIS community</b><br/>
  <sub>Powered by Claude Code · Anthropic · Claude 4.x</sub>
</p>
