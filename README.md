<p align="center">
  <img src="https://img.shields.io/badge/version-6.0-blue?style=for-the-badge" alt="Version 6.0"/>
  <img src="https://img.shields.io/badge/agents-8-green?style=for-the-badge" alt="8 Agents"/>
  <img src="https://img.shields.io/badge/skills-21-orange?style=for-the-badge" alt="21 Skills"/>
  <img src="https://img.shields.io/badge/license-MIT-purple?style=for-the-badge" alt="MIT License"/>
  <img src="https://img.shields.io/badge/platform-Claude%20Code-black?style=for-the-badge" alt="Claude Code"/>
</p>

# :shield: AEGIS v6.0 — AI Agent Team Framework for Claude Code

> **"Context is King, Memory is Soul"**
>
> 8 AI Personas · 21 Skills · 15 Commands · Persistent Brain · tmux Agent Teams

---

AEGIS (**A**utonomous **E**nhanced **G**roup **I**ntelligence **S**ystem) is a production-grade framework that transforms Claude Code into a coordinated team of 8 specialized AI agents. Each agent carries a distinct role — from architecture to adversarial review — with intelligent model routing across Opus, Sonnet, and Haiku tiers. Blast radius containment ensures agents only touch what they own. Built for real-world SDLC workflows, AEGIS handles everything from sprint planning and code generation to security audits and retrospectives, with a persistent brain that remembers across sessions.

---

## :rocket: Quick Start

```bash
# Clone the repository
git clone https://github.com/Soul-Brews-Studio/AEGIS-Team.git
cd AEGIS-Team

# Make installer executable
chmod +x install.sh

# Install with your preferred profile
./install.sh --profile standard --project-name "My Project"

# Start your first session
/aegis-start
```

**Profile options:** `minimal` (7 skills) · `standard` (13 skills) · `full` (21 skills)

---

## :building_construction: Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    AEGIS v6.0 Architecture                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─── Layer 6: Skills + Profiles ──────────────────────────┐   │
│  │  minimal (7)  ──▶  standard (13)  ──▶  full (21)        │   │
│  │  Progressive disclosure · ~50 tokens/skill scan          │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─── Layer 5: Personas + Model Routing ───────────────────┐   │
│  │  opus ───── Navi · Sage · Havoc    (strategy/synthesis)  │   │
│  │  sonnet ─── Bolt · Vigil · Pixel   (implementation)     │   │
│  │  haiku ──── Forge · Muse           (scanning/content)   │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─── Layer 4: Agent Teams (tmux) ─────────────────────────┐   │
│  │  review-team · build-team · debate-team                  │   │
│  │  Mesh communication · Structured message types (8)       │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─── Layer 3: ψ Brain (Persistent Knowledge) ─────────────┐   │
│  │  _aegis-brain/                                           │   │
│  │  ├── resonance/   (identity + conventions + ADRs)        │   │
│  │  ├── learnings/   (accumulated lessons)                  │   │
│  │  ├── logs/        (activity tracking)                    │   │
│  │  └── retrospectives/ (session retros)                    │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─── Layer 2: Session Lifecycle ──────────────────────────┐   │
│  │  /aegis-start → WORK → /aegis-retro → /aegis-handoff    │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─── Layer 1: Context Budget ─────────────────────────────┐   │
│  │  20% rule · Token monitoring · Auto-distill              │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## :busts_in_silhouette: The 8 Agents

| # | Agent | Model | Role | Blast Radius |
|:-:|:------|:-----:|:-----|:-------------|
| 1 | :compass: **Navi** | `opus` | Navigator/Lead — Orchestrates, synthesizes, writes retros | CLAUDE*.md, brain, output |
| 2 | :triangular_ruler: **Sage** | `opus` | Architect — Specs, system design, ADRs | docs, specs, architecture |
| 3 | :zap: **Bolt** | `sonnet` | Implementer — Writes code, builds features, runs tests | src, lib, tests, configs |
| 4 | :shield: **Vigil** | `sonnet` | Reviewer — Code review, quality gates, security checks | output/reviews (read-only src) |
| 5 | :red_circle: **Havoc** | `opus` | Devil's Advocate — Challenges assumptions, finds flaws | output/challenges |
| 6 | :wrench: **Forge** | `haiku` | Scanner/Research — Gathers data, scans repos, metrics | brain/logs, output/scans |
| 7 | :art: **Pixel** | `sonnet` | UX Designer — UI/UX, accessibility, design systems | components, styles, assets |
| 8 | :paintbrush: **Muse** | `haiku` | Content Creator — Docs, changelogs, copywriting | docs, README, CHANGELOG |

### Model Routing Strategy

| Tier | Agents | Purpose | Cost |
|:-----|:-------|:--------|:----:|
| **Opus** | Navi, Sage, Havoc | Strategy, synthesis, deep reasoning | $$$ |
| **Sonnet** | Bolt, Vigil, Pixel | Implementation, review, design | $$ |
| **Haiku** | Forge, Muse | Data gathering, content, scanning | $ |

> **Rule of thumb:** Opus thinks, Sonnet builds, Haiku gathers.

---

## :keyboard: Commands

AEGIS provides 15 slash commands for session and team management:

| Command | Purpose |
|:--------|:--------|
| `/aegis-start` | Begin session — load brain, check context, restore state |
| `/aegis-retro` | End session — run retrospective, extract lessons |
| `/aegis-handoff` | Generate handoff document for next session |
| `/aegis-pipeline` | Run full analysis pipeline across all agents |
| `/aegis-status` | Check progress of all active agents |
| `/aegis-mode` | Switch skill profile: `minimal` / `standard` / `full` |
| `/aegis-context` | Show context budget usage and token breakdown |
| `/aegis-distill` | Compress conversation context into essentials |
| `/aegis-memory` | Read/write to persistent brain |
| `/aegis-verify` | Verify agent outputs meet acceptance criteria |
| `/aegis-launch` | Launch a specific agent with a task |
| `/aegis-flow` | Visualize current pipeline flow and dependencies |
| `/aegis-team-build` | Spawn **build team** (Bolt + Vigil) via tmux |
| `/aegis-team-review` | Spawn **review team** (Vigil + Havoc + Forge) via tmux |
| `/aegis-team-debate` | Spawn **debate team** (Sage + Havoc) via tmux |

---

## :jigsaw: Skill Profiles

Skills load on-demand based on the active profile. Progressive disclosure keeps context lean — each skill scans at approximately 50 tokens.

### Minimal Profile — 7 skills (~3K tokens)

> Quick tasks, small projects, limited context

| # | Skill | Description |
|:-:|:------|:------------|
| 1 | `personas` | Load and activate AEGIS agent personas |
| 2 | `orchestrator` | Pipeline orchestration, task routing |
| 3 | `code-review` | Structured review with severity ratings |
| 4 | `code-standards` | Linting rules, style conventions |
| 5 | `git-workflow` | Git branching, commit conventions, PR workflow |
| 6 | `bug-lifecycle` | Bug triage, root cause analysis, fix verification |
| 7 | `project-navigator` | Explore project structure, find files |

### Standard Profile — 13 skills (~6K tokens)

> Normal development, team projects (includes all minimal skills)

| # | Skill | Description |
|:-:|:------|:------------|
| 8 | `super-spec` | Feature specifications from requirements |
| 9 | `test-architect` | Test strategy, test cases, coverage analysis |
| 10 | `security-audit` | Vulnerability scanning, threat modeling, OWASP |
| 11 | `tech-debt-tracker` | Identify and prioritize technical debt |
| 12 | `sprint-tracker` | Sprint planning, velocity, standup summaries |
| 13 | `api-docs` | API documentation, OpenAPI/Swagger specs |

### Full Profile — 21 skills (~12K tokens)

> Complex analysis, full pipeline, enterprise (includes all standard skills)

| # | Skill | Description |
|:-:|:------|:------------|
| 14 | `aegis-distill` | Compress context into essential summaries |
| 15 | `aegis-observe` | Monitor agent performance and pipeline health |
| 16 | `adversarial-review` | Red-team analysis, assumption challenging |
| 17 | `code-coverage` | Analyze test coverage, identify gaps |
| 18 | `retrospective` | Structured session retrospectives |
| 19 | `course-correction` | Detect pipeline drift, realign with goals |
| 20 | `skill-marketplace` | Discover and install community skills |
| 21 | `aegis-builder` | Meta-skill to create new AEGIS skills |

---

## :star2: Key Features

### Structured Message Types
Eight typed message formats (`TaskAssignment`, `StatusUpdate`, `FindingReport`, `PlanProposal`, `ApprovalRequest`, `EscalationAlert`, and more) ensure clean, parseable inter-agent communication.

### Graduated Autonomy
Four levels that scale trust with your comfort:

| Level | Mode | Description |
|:-----:|:-----|:------------|
| L1 | Supervised | Human approves every action |
| L2 | Guided | Human approves plans, agents execute |
| L3 | Autonomous | Agents work, human reviews output |
| L4 | Full Auto | Fully autonomous with async monitoring |

### Persistent Brain
The `_aegis-brain/` directory survives across sessions:
- **resonance/** — Project identity, team conventions, architecture decisions
- **learnings/** — Accumulated lessons from past sessions
- **logs/** — Activity tracking and scan results
- **retrospectives/** — Session retros with actionable insights

### Progressive Disclosure
Skills are scanned at approximately 50 tokens each, loaded fully only when needed. Context stays lean and efficient.

### Review Gates
Mandatory quality checkpoints between pipeline phases. Vigil reviews every change before merge. No auto-approvals.

### Reflexion Loop
Agents learn from failures. When something goes wrong, the retrospective captures lessons that feed into future decisions.

### Blast Radius Containment
Each agent has strict read/write boundaries. Bolt cannot touch CLAUDE.md. Vigil cannot modify source code. Forge only gathers — never decides. Scope limits prevent cascading mistakes.

---

## :file_folder: Directory Structure

```
AEGIS-Team/
├── CLAUDE.md                  # Main entry — golden rules, navigation
├── CLAUDE_agents.md           # 8 agent personas + routing
├── CLAUDE_safety.md           # Safety rules for git/file ops
├── CLAUDE_skills.md           # Skill catalog (21 skills)
├── CLAUDE_lessons.md          # Accumulated lessons learned
│
├── .claude/
│   ├── commands/              # 15 slash commands
│   │   ├── aegis-start.md
│   │   ├── aegis-retro.md
│   │   ├── aegis-handoff.md
│   │   ├── aegis-pipeline.md
│   │   ├── aegis-status.md
│   │   ├── aegis-mode.md
│   │   ├── aegis-context.md
│   │   ├── aegis-distill.md
│   │   ├── aegis-memory.md
│   │   ├── aegis-verify.md
│   │   ├── aegis-launch.md
│   │   ├── aegis-flow.md
│   │   ├── aegis-team-build.md
│   │   ├── aegis-team-review.md
│   │   └── aegis-team-debate.md
│   ├── agents/                # Agent profile configs
│   │   ├── navi.md
│   │   ├── sage.md
│   │   ├── bolt.md
│   │   ├── vigil.md
│   │   ├── havoc.md
│   │   ├── forge.md
│   │   ├── pixel.md
│   │   └── muse.md
│   ├── teams/                 # Predefined team compositions
│   │   ├── aegis-review.md
│   │   ├── aegis-build.md
│   │   └── aegis-debate.md
│   └── references/            # Shared reference docs
│       ├── progress-protocol.md
│       ├── output-format.md
│       ├── review-checklist.md
│       ├── context-rules.md
│       ├── message-types.md
│       └── autonomy-levels.md
│
├── skills/                    # 21 loadable skill files
│   ├── ai-personas.md
│   ├── orchestrator.md
│   ├── code-review.md
│   ├── code-standards.md
│   ├── git-workflow.md
│   ├── bug-lifecycle.md
│   ├── project-navigator.md
│   ├── super-spec.md
│   ├── test-architect.md
│   ├── security-audit.md
│   ├── tech-debt-tracker.md
│   ├── sprint-tracker.md
│   ├── api-docs.md
│   ├── aegis-distill.md
│   ├── aegis-observe.md
│   ├── adversarial-review.md
│   ├── code-coverage.md
│   ├── retrospective.md
│   ├── course-correction.md
│   ├── skill-marketplace.md
│   └── aegis-builder.md
│
├── _aegis-brain/              # Persistent knowledge (ψ Brain)
│   ├── resonance/             # Project identity + conventions
│   ├── learnings/             # Accumulated lessons
│   ├── logs/                  # Activity logs
│   └── retrospectives/        # Session retrospectives
│
├── _aegis-output/             # Agent work products
│
├── install.sh                 # One-command installer
└── .gitignore
```

---

## :arrows_counterclockwise: Session Lifecycle

```
  ┌──────────────┐
  │ /aegis-start │  Load brain, restore state, check context budget
  └──────┬───────┘
         │
         ▼
  ┌──────────────┐
  │     WORK     │  Agents execute tasks within blast radius
  │              │  ├── /aegis-pipeline   (full analysis)
  │              │  ├── /aegis-team-*     (spawn teams)
  │              │  ├── /aegis-status     (check progress)
  │              │  └── /aegis-verify     (validate outputs)
  └──────┬───────┘
         │
         ▼
  ┌──────────────┐
  │ /aegis-retro │  Retrospective — what went well, what to improve
  └──────┬───────┘
         │
         ▼
  ┌────────────────┐
  │ /aegis-handoff │  Generate handoff doc for next session
  └────────────────┘  Brain persists → next session picks up where you left off
```

---

## :people_holding_hands: Agent Teams (tmux)

AEGIS spawns coordinated agent teams via tmux sessions. Each team is a predefined composition optimized for a specific workflow.

### Review Team — `/aegis-team-review`
```
┌─────────────────────────────────────────┐
│  aegis-review (tmux session)            │
│                                         │
│  ┌─────────┐  ┌─────────┐  ┌────────┐  │
│  │  Vigil  │  │  Havoc  │  │ Forge  │  │
│  │ (review)│  │ (challenge) │ (scan) │  │
│  └────┬────┘  └────┬────┘  └───┬────┘  │
│       └────────────┼───────────┘        │
│                    ▼                    │
│              Navi (synthesize)           │
└─────────────────────────────────────────┘
```
Vigil reviews code quality, Havoc challenges assumptions, Forge scans for data. Navi synthesizes findings.

### Build Team — `/aegis-team-build`
```
┌─────────────────────────────────┐
│  aegis-build (tmux session)     │
│                                 │
│  ┌─────────┐      ┌─────────┐  │
│  │   Bolt  │ ◀──▶ │  Vigil  │  │
│  │ (implement)     │ (review) │  │
│  └─────────┘      └─────────┘  │
│                                 │
│  Bolt builds, Vigil reviews     │
│  Tight feedback loop            │
└─────────────────────────────────┘
```
Bolt implements features while Vigil provides continuous code review in a tight feedback loop.

### Debate Team — `/aegis-team-debate`
```
┌─────────────────────────────────┐
│  aegis-debate (tmux session)    │
│                                 │
│  ┌─────────┐      ┌─────────┐  │
│  │   Sage  │ ◀──▶ │  Havoc  │  │
│  │ (propose)       │(challenge)│  │
│  └─────────┘      └─────────┘  │
│                                 │
│  Sage proposes, Havoc challenges│
│  Best ideas survive             │
└─────────────────────────────────┘
```
Sage proposes architecture options while Havoc stress-tests them. Only the strongest designs survive.

---

## :gear: Golden Rules

1. **NEVER** use `--force` flags on git
2. **NEVER** push to main — always branch + PR
3. **NEVER** `git commit --amend` — it breaks all agents
4. **NEVER** end turn before agents finish (false-ready guard)
5. Run `/aegis-start` at session begin
6. Run `/aegis-retro` at session end

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
  <sub>Powered by Claude Code · Anthropic</sub>
</p>
