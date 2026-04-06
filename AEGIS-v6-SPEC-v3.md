# AEGIS v6.0 Specification — Version 3

> **"Context is King, Memory is Soul"**
>
> Agent-Enhanced Guided Intelligence System
> Multi-Agent Framework for Claude Code
>
> Spec Version: 3.0
> Framework Version: 6.0
> Date: 2026-03-20
> Authors: Captain America (Lead), Iron Man (Architecture), Loki (Adversarial Review)

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Design Philosophy](#2-design-philosophy)
3. [Architecture Overview](#3-architecture-overview)
4. [Agent System](#4-agent-system)
5. [Structured Message Types (A2A/ACP)](#5-structured-message-types)
6. [Graduated Autonomy L1-L4](#6-graduated-autonomy)
7. [Reflexion Loop](#7-reflexion-loop)
8. [Tool Loading Profiles](#8-tool-loading-profiles)
9. [Decision Trace Logging](#9-decision-trace-logging)
10. [Hook-based Quality Gates](#10-hook-based-quality-gates)
11. [Tiered Memory System](#11-tiered-memory-system)
12. [Flow + Crew Architecture](#12-flow--crew-architecture)
13. [Blast Radius Containment](#13-blast-radius-containment)
14. [Session Templates](#14-session-templates)
15. [Skill System](#15-skill-system)
16. [Context Management](#16-context-management)
17. [Safety & Compliance](#17-safety--compliance)
18. [Installation & Setup](#18-installation--setup)
19. [Command Reference](#19-command-reference)
20. [Migration from v5](#20-migration-from-v5)
21. [Appendices](#21-appendices)

---

## 1. Executive Summary

AEGIS v6 is a multi-agent orchestration framework for Claude Code that enables teams of AI agents with distinct personas, model tiers, and scoped responsibilities to collaborate on software engineering tasks. It builds on AEGIS v5's persona system with 10 research-backed upgrades:

1. **Structured Message Types** — typed A2A communication replaces free-form messages
2. **Graduated Autonomy** — four levels from fully supervised to fully autonomous
3. **Reflexion Loop** — agents reflect on failures before retrying
4. **Tool Loading Profiles** — each agent gets only the tools they need
5. **Decision Trace Logging** — every action is logged with reasoning
6. **Hook-based Quality Gates** — automated validation between pipeline phases
7. **Tiered Memory** — core, archival, and working memory layers
8. **Flow + Crew Architecture** — deterministic pipelines + dynamic teams
9. **Blast Radius Containment** — per-agent scope limits prevent cascade failures
10. **Session Templates** — preconfigured workflows for common tasks

### Key Metrics (Design Targets)
| Metric | Target | How |
|--------|--------|-----|
| Context efficiency | ≤20% at start | Progressive disclosure |
| Cost optimization | 60% reduction vs all-opus | Tiered model routing |
| Defect escape rate | <5% | Review gates + Loki analysis |
| Session continuity | <30s to productive | Brain resonance files |
| Agent coordination overhead | <10% of total tokens | Structured messages |

---

## 2. Design Philosophy

### 2.1 Core Principles

**Context is King** — Every design decision optimizes for context window efficiency. The framework loads minimally at start and progressively discloses information as needed. A session that starts with 15K tokens of framework overhead is a failed session.

**Memory is Soul** — Without persistent memory, every session starts from zero. The brain resonance system (`_aegis-brain/`) ensures knowledge compounds across sessions. Lessons learned in session 5 prevent mistakes in session 50.

**Right Model for Right Task** — Not every task needs opus-level reasoning. Scanning a codebase is haiku work. Writing code is sonnet work. Synthesizing architecture decisions is opus work. Cost scales with complexity, not volume.

**Safety by Default** — The framework assumes the most restrictive safety posture and relaxes only with explicit human authorization. Graduated autonomy means trust is earned, not assumed.

**Agents are Specialists, Not Generalists** — Each agent has a defined role, a defined scope, and defined tools. An agent that can do everything does nothing well.

### 2.2 Design Influences

| Influence | What We Took | What We Left |
|-----------|-------------|--------------|
| CrewAI | Role-based agents, task delegation | Heavy Python runtime |
| AutoGen | Multi-agent conversation patterns | Complex group chat management |
| LangGraph | State machines for workflows | Graph complexity overhead |
| A2A Protocol (Google) | Structured agent communication | Full protocol overhead |
| ACP (Cisco) | Agent capability profiles | Enterprise complexity |
| Reflexion (Shinn et al.) | Self-reflection on failure | Academic scaffolding |
| LATS | Tree-of-thought search | Computational cost |

### 2.3 Persona Attribution

Throughout this spec, design decisions are attributed to the agent persona that championed them:

- **[Captain America]** — Orchestration, pipeline design, team coordination
- **[Iron Man]** — Architecture decisions, system design, trade-off analysis
- **[Loki]** — Adversarial challenges, risk identification, failure modes
- **[Black Panther]** — Quality standards, compliance rules, review processes

---

## 3. Architecture Overview

### 3.1 System Layers

```
┌─────────────────────────────────────────────────┐
│                  Human Operator                  │
├─────────────────────────────────────────────────┤
│              Autonomy Gateway (L1-L4)           │
├─────────────────────────────────────────────────┤
│     Captain America (Orchestrator / Navigator / Lead)       │
├──────────┬──────────┬───────────┬───────────────┤
│  Iron Man    │  Spider-Man    │  Black Panther    │  Loki        │
│  (opus)  │ (sonnet) │ (sonnet)  │  (opus)       │
├──────────┼──────────┼───────────┼───────────────┤
│  Beast   │  Wasp   │  Songbird     │  [Extensions] │
│  (haiku) │ (sonnet) │  (haiku)  │               │
├──────────┴──────────┴───────────┴───────────────┤
│              Tool Layer (scoped per agent)        │
├─────────────────────────────────────────────────┤
│    Tiered Memory: Core | Archival | Working      │
├─────────────────────────────────────────────────┤
│         Decision Trace Log (append-only)         │
└─────────────────────────────────────────────────┘
```

### 3.2 Directory Structure

```
project-root/
├── CLAUDE.md                    # Hub — loaded every session (~500 tokens)
├── CLAUDE_safety.md             # Safety rules — loaded before thor
├── CLAUDE_agents.md             # Agent personas — loaded before spawning
├── CLAUDE_skills.md             # Skill catalog — loaded when choosing skills
├── CLAUDE_lessons.md            # Patterns/anti-patterns — reference
├── AEGIS-v6-SPEC-v3.md          # This specification
├── install.sh                   # Framework installer
├── _aegis-brain/                # Persistent memory (tiered)
│   ├── resonance/               # Session continuity snapshots
│   ├── learnings/               # Accumulated knowledge
│   ├── logs/                    # Decision traces, agent logs
│   └── retrospectives/          # Session retrospectives
├── _aegis-output/               # Pipeline outputs (gitignored)
│   ├── reviews/                 # Black Panther review reports
│   ├── adversarial/             # Loki adversarial reports
│   ├── scans/                   # Beast scan results
│   ├── architecture/            # Iron Man architecture documents
│   ├── design/                  # Wasp design artifacts
│   └── content/                 # Songbird content drafts
├── skills/                      # Skill definition files
├── .claude/                     # Claude CLI configuration
│   ├── agents/                  # Agent profile configs
│   ├── commands/                # Custom slash commands
│   ├── references/              # Reference documents
│   └── teams/                   # Team composition configs
└── docs/                        # Project documentation
    └── decisions/               # Architecture Decision Records
```

### 3.3 Data Flow

```
Human Request
    │
    ▼
[/aegis-start] ─── Load CLAUDE.md ─── Check brain resonance
    │
    ▼
Captain America (Orchestrator)
    │
    ├── Analyze request
    ├── Select Flow or Crew pattern
    ├── Assign agents with TaskAssignment messages
    │
    ▼
Agents Execute (parallel where possible)
    │
    ├── Beast scans (haiku, parallel instances)
    ├── Iron Man designs (opus, sequential reasoning)
    ├── Spider-Man implements (sonnet, fast execution)
    ├── Wasp designs UI (sonnet)
    ├── Songbird writes docs (haiku)
    │
    ▼
Quality Gates (Black Panther + Loki)
    │
    ├── Black Panther reviews (sonnet, structured checklist)
    ├── Loki challenges (opus, adversarial analysis)
    │
    ▼
Captain America Synthesizes
    │
    ├── Merge agent outputs
    ├── Write synthesis (opus-quality)
    ├── Log decision trace
    │
    ▼
Human Review (based on autonomy level)
    │
    ▼
[/aegis-retro] ─── Update lessons ─── Write resonance ─── Archive
```

---

## 4. Agent System

### 4.1 Agent Roster

| Agent | Model | Cost Tier | Parallelizable | Primary Function |
|-------|-------|-----------|----------------|------------------|
| Captain America | opus | $$$ | No (singleton) | Orchestration, synthesis, retros |
| Iron Man | opus | $$$ | No | Architecture, specs, design |
| Spider-Man | sonnet | $$ | Yes (per feature) | Code implementation, tests |
| Black Panther | sonnet | $$ | Yes (per review) | Code review, quality gates |
| Loki | opus | $$$ | No | Adversarial analysis, challenges |
| Beast | haiku | $ | Yes (high fan-out) | Scanning, research, data collection |
| Wasp | sonnet | $$ | Yes (per component) | UI/UX design, frontend |
| Songbird | haiku | $ | Yes (per doc) | Documentation, content |

### 4.2 Model Routing Rules

**[Iron Man]** designed these routing rules based on the cognitive demands of each task type:

1. **Opus tasks** require deep reasoning, multi-step synthesis, or adversarial thinking:
   - Architecture decisions with trade-offs
   - Final synthesis of multi-agent outputs
   - Adversarial analysis and threat modeling
   - Retrospectives and lesson extraction

2. **Sonnet tasks** require solid execution and balanced reasoning:
   - Code implementation following a spec
   - Code review with structured checklist
   - UI/UX design and component building
   - Test writing and debugging

3. **Haiku tasks** are high-volume, low-reasoning data operations:
   - Codebase scanning and grep operations
   - Dependency enumeration
   - Documentation drafting (not finalization)
   - Metrics collection

### 4.3 Agent Lifecycle

```
┌─────────┐    ┌──────────┐    ┌─────────┐    ┌────────┐    ┌───────────┐
│  Spawn  │───▶│  Init    │───▶│ Execute │───▶│ Report │───▶│ Terminate │
└─────────┘    └──────────┘    └─────────┘    └────────┘    └───────────┘
     │              │               │              │               │
  tmux session  Load context   Work within     Send typed      Captain America verifies
  created       (progressive)  blast radius    message         completion
```

### 4.4 Agent Profiles

Each agent is configured via a profile in `.claude/agents/`:

```yaml
# .claude/agents/spider-man.yaml
name: spider-man
emoji: "⚡"
model: sonnet
role: implementer
tools:
  - file_read
  - file_write
  - shell_safe
  - git_commit
blast_radius:
  read: ["**/*"]
  write: ["src/**", "lib/**", "tests/**", "configs/**", "package.json"]
  forbidden: ["CLAUDE*.md", "_aegis-brain/**"]
message_types:
  sends: [StatusUpdate, FindingReport, EscalationAlert]
  receives: [TaskAssignment, PlanProposal]
```

---

## 5. Structured Message Types

**[Captain America]** championed structured messages after observing that free-form agent communication caused 40% of coordination failures in v5.

### 5.1 Message Type Catalog

| Type | Sender | Receiver | Purpose |
|------|--------|----------|---------|
| TaskAssignment | Captain America | Any agent | Assign work with acceptance criteria |
| StatusUpdate | Any agent | Captain America | Report progress, completion, or blockers |
| FindingReport | Any agent | Captain America | Report findings (bugs, scan results, review items) |
| PlanProposal | Iron Man, Captain America | Captain America, Human | Propose a plan with options and trade-offs |
| ApprovalRequest | Captain America | Human | Request human approval for gated actions |
| EscalationAlert | Any agent | Captain America | Escalate issues outside scope or competence |

### 5.2 Message Schema

Every message includes:
```json
{
  "type": "<MessageType>",
  "id": "<unique-id>",
  "timestamp": "<ISO-8601>",
  "from": "<agent-name>",
  "to": "<agent-name|human>",
  "task_id": "<reference-to-task>",
  "payload": { ... }
}
```

### 5.3 Message Validation Rules

**[Black Panther]** defined these validation rules:

1. Every message must have a valid `type` from the catalog
2. `from` must match the agent's registered name
3. `to` must be a valid agent or "human"
4. `task_id` must reference an active task (or "new" for new tasks)
5. Payload must conform to the type's schema
6. Messages exceeding 2000 tokens must be split: summary in message, detail in `_aegis-brain/logs/`

### 5.4 Communication Topology

```
           Human
             │
      ApprovalRequest
        EscalationAlert
             │
             ▼
    ┌────── Captain America ──────┐
    │    (hub & spoke)  │
    │                   │
    ▼                   ▼
  TaskAssignment    StatusUpdate
  PlanProposal      FindingReport
    │               EscalationAlert
    ▼                   │
  Agents ──────────────▶│
```

All communication is hub-and-spoke through Captain America. No direct agent-to-agent messaging. This ensures:
- Single point of coordination
- Complete decision trace
- No circular dependencies
- Easy conflict resolution

---

## 6. Graduated Autonomy

**[Loki]** insisted on graduated autonomy after identifying that unchecked agent autonomy was the #1 risk in multi-agent systems.

### 6.1 Autonomy Levels

| Level | Name | Human Role | Agent Freedom | Risk |
|-------|------|-----------|---------------|------|
| L1 | Supervised | Approves every action | Execute approved actions only | Minimal |
| L2 | Guided | Approves plans | Execute within approved plan | Low |
| L3 | Autonomous | Reviews outputs | Full execution, report results | Medium |
| L4 | Monitored | Async monitoring | Fully autonomous, alert on issues | High |

### 6.2 Level Transitions

```
L1 ──(3 clean sessions)──▶ L2 ──(5 clean sessions)──▶ L3 ──(10 clean sessions)──▶ L4
 ▲                          ▲                          ▲                           │
 │                          │                          │                           │
 └──────────────────────────┴──────────────────────────┴───── (any incident) ──────┘
```

**Graduation criteria:**
- L1 → L2: 3 consecutive sessions with zero safety incidents
- L2 → L3: 5 consecutive sessions with zero incidents and all review gates passed
- L3 → L4: 10 consecutive sessions with zero incidents, all gates passed, and human approval

**Demotion triggers:**
- Any safety incident (secret exposure, scope violation, force push) → immediate L1
- Review gate failure → one level down
- Human override → requested level

### 6.3 Actions by Level

| Action | L1 | L2 | L3 | L4 |
|--------|----|----|----|----|
| File read | Auto | Auto | Auto | Auto |
| File write (in scope) | Confirm | Auto | Auto | Auto |
| Git commit | Confirm | Auto | Auto | Auto |
| Git push (feature) | Confirm | Confirm | Auto | Auto |
| PR creation | Confirm | Confirm | Auto | Auto |
| Package install | Confirm | Confirm | Confirm | Auto |
| Architecture decision | Confirm | Confirm | Confirm | Confirm |
| Deploy | Confirm | Confirm | Confirm | Confirm |

### 6.4 Tracking

Autonomy state is stored in `_aegis-brain/resonance/autonomy-state.md`:
```markdown
# Autonomy State
- Current Level: L1
- Clean Sessions: 0
- Last Incident: none
- Transition History: [initial L1 on 2026-03-20]
```

---

## 7. Reflexion Loop

**[Iron Man]** introduced the Reflexion pattern based on Shinn et al. (2023) to reduce retry waste.

### 7.1 Concept

When an agent's output fails a quality gate, instead of blindly retrying, the agent first reflects on what went wrong and produces a self-critique before the retry attempt.

### 7.2 Reflexion Protocol

```
Agent produces output
         │
         ▼
   Quality Gate check
         │
    ┌────┴────┐
    │ Pass    │ Fail
    ▼         ▼
  Accept    Reflect
              │
              ▼
         Self-critique:
         - What went wrong?
         - What was my assumption?
         - What should I change?
              │
              ▼
         Retry with reflection
         context appended
              │
              ▼
         Quality Gate check (attempt 2)
              │
         ┌────┴────┐
         │ Pass    │ Fail
         ▼         ▼
       Accept    Escalate to Captain America
                 (max 2 retries)
```

### 7.3 Reflection Template

```markdown
## Reflection on [task_id] — Attempt [N]

### What failed
<specific gate failure>

### Root cause analysis
<why did the output fail>

### Assumption that was wrong
<the incorrect assumption>

### Correction plan
<what will be different in the retry>
```

### 7.4 Retry Limits

- Maximum 2 retry attempts per agent per task
- If both retries fail, escalate to Captain America
- Captain America may reassign to a different agent or escalate to human
- All reflections are logged to `_aegis-brain/logs/` for pattern analysis

---

## 8. Tool Loading Profiles

**[Iron Man]** designed tool profiles to minimize the attack surface and context cost of each agent.

### 8.1 Principle

Each agent receives only the tools they need for their role. This:
- Reduces context cost (tool definitions are expensive)
- Prevents accidental misuse
- Makes agent behavior more predictable
- Supports blast radius containment

### 8.2 Tool Profiles

| Tool | Captain America | Iron Man | Spider-Man | Black Panther | Loki | Beast | Wasp | Songbird |
|------|------|------|------|-------|-------|-------|-------|------|
| file_read | Y | Y | Y | Y | Y | Y | Y | Y |
| file_write | Y* | Y* | Y* | Y* | Y* | Y* | Y* | Y* |
| shell_safe (ls, grep) | Y | Y | Y | Y | Y | Y | Y | Y |
| shell_mutation (rm, mv) | Y | - | Y | - | - | - | Y | - |
| git_read (status, log, diff) | Y | Y | Y | Y | Y | Y | Y | Y |
| git_write (commit, branch) | Y | - | Y | - | - | - | - | - |
| git_push | Y | - | - | - | - | - | - | - |
| tmux_manage | Y | - | - | - | - | - | - | - |
| web_search | Y | Y | - | - | Y | Y | - | Y |
| web_fetch | Y | Y | - | - | - | Y | - | Y |
| diagram_gen | - | Y | - | - | - | - | Y | - |
| test_run | - | - | Y | Y | - | - | - | - |

*file_write is scoped to each agent's blast radius directories

### 8.3 Tool Loading

Tools are loaded when an agent is spawned. The orchestrator reads the agent profile and injects only the listed tools into the agent's context.

---

## 9. Decision Trace Logging

**[Black Panther]** required decision trace logging for auditability and post-session analysis.

### 9.1 What Gets Logged

Every significant agent action is logged with:
- Timestamp
- Agent name
- Action type
- Input (summarized)
- Output (summarized)
- Reasoning (why this action was chosen)
- Alternatives considered
- Confidence level

### 9.2 Log Format

```json
{
  "timestamp": "2026-03-20T10:15:30Z",
  "agent": "iron-man",
  "action": "architecture_decision",
  "task_id": "TASK-003",
  "input": "Design auth system for microservices",
  "output": "Selected JWT + Redis approach",
  "reasoning": "Stateless auth needed for horizontal scaling; Redis provides token revocation",
  "alternatives": ["Session-based (rejected: stateful)", "OAuth2-only (rejected: complexity)"],
  "confidence": 0.85,
  "context_tokens_used": 2400
}
```

### 9.3 Storage

- Logs are append-only to `_aegis-brain/logs/trace-<date>.jsonl`
- One file per day, JSONL format (one JSON object per line)
- Logs are never modified or deleted during a session
- Old logs can be archived during /aegis-retro

### 9.4 Querying

Traces can be queried by:
- Agent name: "Show me all Iron Man decisions today"
- Task ID: "Show me the full trace for TASK-003"
- Action type: "Show me all escalations"
- Confidence: "Show me low-confidence decisions"

---

## 10. Hook-based Quality Gates

**[Black Panther]** designed the quality gate system to prevent defects from propagating through the pipeline.

### 10.1 Gate Types

| Gate | Trigger | Validator | Fail Action |
|------|---------|-----------|-------------|
| PostSpec | Iron Man completes spec | Black Panther + Loki | Reflexion → Iron Man retry |
| PostImplement | Spider-Man completes code | Black Panther | Reflexion → Spider-Man retry |
| PostReview | Black Panther completes review | Captain America | Human escalation if critical |
| PostChallenge | Loki completes challenge | Captain America | Route to affected agent |
| PreMerge | PR ready for merge | Black Panther + test suite | Block merge on failure |
| PreDeploy | Deploy requested | Captain America + Human | Always requires human confirm |

### 10.2 Gate Execution

```python
# Pseudocode for gate execution
def execute_gate(gate_type, artifact):
    validators = GATE_CONFIG[gate_type].validators
    results = []

    for validator in validators:
        result = validator.validate(artifact)
        results.append(result)

    if any(r.severity == "critical" for r in results):
        trigger_reflexion(artifact.agent, results)
        return GateResult.FAIL

    if any(r.severity == "warning" for r in results):
        log_warnings(results)
        return GateResult.PASS_WITH_WARNINGS

    return GateResult.PASS
```

### 10.3 Gate Configuration

Gates are configured in `_aegis-brain/resonance/gate-config.md`:
```markdown
# Quality Gate Configuration

## PostSpec Gate
- Validators: [black-panther, loki]
- Acceptance Criteria:
  - All requirements addressed
  - No ambiguous language
  - Test strategy defined
  - Security considerations documented
- On Fail: reflexion + retry (max 2)
- On Pass: notify Captain America, assign Spider-Man

## PostImplement Gate
- Validators: [black-panther]
- Acceptance Criteria:
  - All tests pass
  - No lint errors
  - No security warnings
  - Code matches spec
- On Fail: reflexion + retry (max 2)
- On Pass: notify Captain America, create PR
```

---

## 11. Tiered Memory System

**[Captain America]** designed the memory system to solve the "amnesia problem" — every new session forgetting everything from the last.

### 11.1 Memory Tiers

| Tier | Location | Lifetime | Access Pattern | Token Cost |
|------|----------|----------|----------------|------------|
| Core | CLAUDE*.md | Permanent | Every session, always loaded | ~2K |
| Archival | _aegis-brain/ | Persistent | Search when needed, loaded on demand | Variable |
| Working | Conversation | Session only | Always available, discarded at end | Session budget |

### 11.2 Core Memory

Core memory is the set of CLAUDE*.md files. They are:
- Small (each <1K tokens ideally, hub <500 tokens)
- Always loaded at session start (CLAUDE.md) or on-demand (others)
- Updated rarely (only during /aegis-retro or major framework changes)
- The "DNA" of the framework — defines identity, rules, and structure

### 11.3 Archival Memory

Archival memory lives in `_aegis-brain/` and includes:
- **Resonance files** (`resonance/`): Snapshot of project state, team state, autonomy level
- **Learnings** (`learnings/`): Accumulated patterns and anti-patterns
- **Logs** (`logs/`): Decision traces, agent logs, escalation records
- **Retrospectives** (`retrospectives/`): Full session retrospectives

Access pattern:
1. At session start, load resonance files (~500 tokens)
2. During work, search archival memory when encountering known problem patterns
3. At session end, write new entries via /aegis-retro

### 11.4 Working Memory

Working memory is the conversation context itself:
- Managed carefully to stay within budget
- Distilled when approaching limits (60% threshold)
- Key information promoted to archival before session ends
- Never relied upon for cross-session continuity

### 11.5 Memory Operations

| Operation | When | What |
|-----------|------|------|
| Load | Session start | Core (CLAUDE.md) + Resonance files |
| Search | During work | Grep _aegis-brain/ for relevant knowledge |
| Store | After decisions | Append to logs, update learnings |
| Distill | Context >60% | Summarize conversation, archive to brain |
| Promote | Session end | Key findings → learnings, state → resonance |
| Archive | /aegis-retro | Full retro → retrospectives/ |

---

## 12. Flow + Crew Architecture

**[Iron Man]** designed the dual execution model after analyzing that some tasks need deterministic steps while others need dynamic collaboration.

### 12.1 Flows (Deterministic Pipelines)

Flows are predefined sequences of agent actions. They are predictable, repeatable, and efficient.

```
Flow: code-review-pipeline
┌────────┐    ┌────────┐    ┌────────┐    ┌────────┐
│ Beast  │───▶│ Black Panther  │───▶│ Loki  │───▶│ Captain America   │
│ (scan) │    │(review)│    │(challenge)│  │(synth) │
└────────┘    └────────┘    └────────┘    └────────┘
```

**Built-in Flows:**

| Flow Name | Stages | Purpose |
|-----------|--------|---------|
| code-review | Beast → Black Panther → Loki → Captain America | Full code review with adversarial |
| feature-build | Iron Man → Spider-Man → Black Panther → Captain America | Spec → implement → review |
| security-audit | Beast → Black Panther → Loki → Captain America | Security-focused analysis |
| doc-generation | Beast → Songbird → Black Panther → Captain America | Auto-generate documentation |
| bug-fix | Beast → Spider-Man → Black Panther → Captain America | Diagnose → fix → verify |

### 12.2 Crews (Dynamic Teams)

Crews are ad-hoc teams assembled by Captain America for complex, non-linear tasks that require collaboration.

```
Crew: architecture-redesign
┌──────────────────────────────┐
│  Captain America (coordinator)          │
│  ┌──────┐ ┌──────┐ ┌──────┐ │
│  │ Iron Man │ │Loki │ │Beast │ │
│  │      │◀▶│      │◀▶│      │ │
│  └──────┘ └──────┘ └──────┘ │
│        Dynamic collaboration  │
└──────────────────────────────┘
```

**When to use Flows vs Crews:**

| Criteria | Flow | Crew |
|----------|------|------|
| Task is well-defined | Yes | No |
| Steps are sequential | Yes | No (parallel/iterative) |
| Multiple iterations needed | No | Yes |
| Cross-agent collaboration | Minimal | Heavy |
| Predictability needed | Yes | Flexibility preferred |

### 12.3 Defining Flows

Flows are defined in `.claude/commands/`:

```markdown
# Flow: feature-build
## Stages
1. [iron-man] Analyze requirements and produce spec
   - Gate: PostSpec
2. [spider-man] Implement feature from spec
   - Gate: PostImplement
3. [black-panther] Review implementation
   - Gate: PostReview
4. [captain-america] Synthesize results and create PR
```

### 12.4 Defining Crews

Crews are assembled dynamically by Captain America:

```markdown
# Crew: architecture-redesign
## Members: iron-man, loki, beast
## Coordination: captain-america
## Goal: Redesign the authentication system
## Max Rounds: 5
## Termination: iron-man and loki agree on design OR max rounds reached
```

---

## 13. Blast Radius Containment

**[Loki]** insisted on strict blast radius rules after identifying that the #1 cause of multi-agent failures is scope creep.

### 13.1 Scope Definition

Every agent has:
- **Read scope**: files/directories they can read
- **Write scope**: files/directories they can modify
- **Forbidden scope**: files/directories they must never touch

See CLAUDE_agents.md for the complete blast radius table.

### 13.2 Enforcement

Blast radius is enforced at three levels:

1. **Profile level**: Agent profile lists allowed tools and scopes
2. **Runtime level**: File write operations check against the scope before executing
3. **Review level**: Black Panther verifies no out-of-scope modifications in review gates

### 13.3 Scope Violations

When an agent attempts an out-of-scope operation:
1. Operation is blocked (not executed)
2. Agent receives an error: "SCOPE_VIOLATION: {path} is outside your write scope"
3. EscalationAlert is sent to Captain America
4. Captain America routes the work to the correct agent
5. Violation is logged to the decision trace

### 13.4 Scope Expansion

In rare cases, an agent may need temporary scope expansion:
1. Agent sends EscalationAlert to Captain America explaining the need
2. Captain America evaluates and may send ApprovalRequest to human (at L1/L2) or approve directly (at L3/L4)
3. If approved, temporary scope grant is logged with expiration
4. Scope reverts after task completion

---

## 14. Session Templates

**[Captain America]** created session templates for common workflows to reduce setup time.

### 14.1 Built-in Templates

#### Quick Review
```
/aegis-start --template quick-review
- Load: minimal profile
- Agents: Beast + Black Panther
- Flow: code-review (simplified)
- Duration: ~10 minutes
```

#### Feature Sprint
```
/aegis-start --template feature-sprint
- Load: standard profile
- Agents: Iron Man + Spider-Man + Black Panther + Beast
- Flow: feature-build
- Duration: ~60 minutes
```

#### Architecture Session
```
/aegis-start --template architecture
- Load: full profile
- Agents: Iron Man + Loki + Beast + Captain America
- Mode: Crew (dynamic)
- Duration: ~45 minutes
```

#### Security Audit
```
/aegis-start --template security-audit
- Load: standard profile + security-audit skill
- Agents: Beast + Black Panther + Loki
- Flow: security-audit
- Duration: ~30 minutes
```

#### Documentation Sprint
```
/aegis-start --template doc-sprint
- Load: standard profile + api-docs skill
- Agents: Beast + Songbird + Black Panther
- Flow: doc-generation
- Duration: ~30 minutes
```

### 14.2 Custom Templates

Users can create custom templates in `.claude/teams/`:

```yaml
# .claude/teams/my-template.yaml
name: my-custom-pipeline
profile: standard
agents: [iron-man, spider-man, black-panther, beast]
flow: feature-build
autonomy: L2
skills: [code-review, test-architect, security-audit]
gates:
  - PostSpec: [black-panther]
  - PostImplement: [black-panther, loki]
```

---

## 15. Skill System

### 15.1 Skill Architecture

Skills are modular capabilities that can be loaded on-demand. They are organized by profile tier (minimal, standard, full) and triggered by keyword matching.

See CLAUDE_skills.md for the complete catalog.

### 15.2 Skill Loading Protocol

```
1. Trigger detection (keyword match or explicit /command)
2. Profile check (is this skill available in current profile?)
3. Context budget check (do we have room?)
4. Load skill file into agent context
5. Execute skill workflow
6. Skill output captured
7. Context reclaimed at next distillation
```

### 15.3 Skill Composition

Skills can be composed for complex workflows:
```
/aegis-pipeline security
  → Loads: security-audit + code-review + adversarial-review
  → Flow: Beast(scan) → Black Panther(audit) → Loki(challenge) → Captain America(synthesis)
```

### 15.4 Custom Skills

New skills follow the template in CLAUDE_skills.md and are placed in `skills/`. The aegis-builder meta-skill assists in creating new skills.

---

## 16. Context Management

### 16.1 Context Budget

| Phase | Max Context Usage | Action if Exceeded |
|-------|------------------|--------------------|
| Session start | ≤20% | Error — check what's being loaded |
| Active work | ≤60% | Normal operation |
| Approaching limit | 60-80% | Trigger distillation |
| Critical | >80% | Emergency: complete task, write retro, end session |

### 16.2 Context Optimization Techniques

1. **Progressive disclosure**: Load context only when needed
2. **Reference over copy**: Point to file:line instead of pasting code
3. **Structured messages**: Fixed-format messages are more token-efficient
4. **Agent report limits**: ≤2000 tokens per report
5. **Distillation**: Periodically summarize and archive conversation
6. **Skill unloading**: Skills not in active use are context candidates for distillation

### 16.3 Distillation Process

When context reaches 60%:
1. Captain America identifies completed subtasks in the conversation
2. For each completed subtask, generate a ≤200 token summary
3. Archive full details to `_aegis-brain/logs/distill-<timestamp>.md`
4. Replace verbose conversation segments with summaries
5. Log distillation event in decision trace

---

## 17. Safety & Compliance

See CLAUDE_safety.md for the complete safety rules. This section provides the architectural rationale.

### 17.1 Safety Layers

```
┌─────────────────────────────────┐
│ Layer 1: Autonomy Gateway       │ ← Human controls what agents can do
├─────────────────────────────────┤
│ Layer 2: Blast Radius           │ ← Agents can only touch their files
├─────────────────────────────────┤
│ Layer 3: Tool Permissions       │ ← Agents only get tools they need
├─────────────────────────────────┤
│ Layer 4: Quality Gates          │ ← Output is validated before accepted
├─────────────────────────────────┤
│ Layer 5: Decision Logging       │ ← Everything is auditable
├─────────────────────────────────┤
│ Layer 6: Secret Scanning        │ ← No secrets leak to git
└─────────────────────────────────┘
```

### 17.2 Threat Model

**[Loki]** produced this threat model:

| Threat | Likelihood | Impact | Mitigation |
|--------|-----------|--------|------------|
| Agent writes to wrong file | Medium | High | Blast radius enforcement |
| Secret committed to git | Low | Critical | Pre-commit scanning |
| Agent impersonates another | Low | High | Message validation (from field) |
| Context overflow mid-task | Medium | Medium | Budget monitoring + distillation |
| Agent retries infinitely | Low | Medium | Max 2 retries + escalation |
| Force push destroys history | Low | Critical | Block --force at tool level |
| Amend breaks other agents | Medium | High | Block --amend, Golden Rule #3 |
| Agent deadlock | Low | Medium | Timeout detection + kill |

### 17.3 Compliance Requirements

- All agent actions must be traceable via decision log
- All file modifications must be attributable to a specific agent
- All git operations must follow branching strategy (never main)
- All secrets must be excluded from version control
- All sessions must end with a retrospective

---

## 18. Installation & Setup

### 18.1 Prerequisites

- git (required)
- tmux (required for multi-agent)
- Claude CLI (required)
- Node.js / Python (optional, depends on project)

### 18.2 Quick Install

```bash
# Clone or create project
mkdir my-project && cd my-project
git init -b main

# Download and run installer
curl -O https://raw.githubusercontent.com/aegis-framework/aegis-v6/main/install.sh
chmod +x install.sh
./install.sh --profile standard --project-name "My Project"
```

### 18.3 Manual Install

```bash
# Create directory structure
mkdir -p _aegis-brain/{resonance,learnings,logs,retrospectives}
mkdir -p _aegis-output/{reviews,challenges,scans,architecture,design,content}
mkdir -p skills .claude/{agents,commands,references,teams}
mkdir -p docs/decisions

# Copy CLAUDE*.md files
# Copy skill files for your profile
# Run /aegis-start in Claude Code
```

### 18.4 Upgrade

```bash
./install.sh --upgrade --profile full
```

This backs up existing files and adds new framework features while preserving brain memory and lessons.

---

## 19. Command Reference

| Command | Description | When to Use |
|---------|-------------|-------------|
| /aegis-start | Initialize session, load brain, verify context | Every session start |
| /aegis-retro | Run retrospective, update lessons, write resonance | Every session end |
| /aegis-pipeline [type] | Run a full analysis pipeline | Major tasks |
| /aegis-team-build | Spawn build team (Iron Man + Spider-Man + Black Panther) in tmux | Feature development |
| /aegis-team-review | Spawn review team (Beast + Black Panther + Loki) in tmux | Code review |
| /aegis-status | Check progress of all active agents | During pipelines |
| /aegis-mode [profile] | Switch skill profile (minimal/standard/full) | When needs change |
| /aegis-distill | Manually trigger context distillation | Context getting large |
| /aegis-observe | Show pipeline health metrics | Monitoring |
| /aegis-reflect [agent] | Trigger manual reflexion for an agent | After gate failure |

---

## 20. Migration from v5

### 20.1 What Changed

| v5 | v6 | Migration Action |
|----|----|--------------------|
| Free-form agent messages | Structured message types | Update agent communication |
| Single autonomy level | Graduated L1-L4 | Start at L1, graduate naturally |
| No reflection on failure | Reflexion loop | Automatic (no action needed) |
| All tools to all agents | Scoped tool profiles | Review agent profiles |
| No action logging | Decision trace | Automatic (no action needed) |
| Manual quality checks | Hook-based gates | Configure gate validators |
| Flat memory | Tiered memory | Move files to correct tier |
| Only pipeline mode | Flow + Crew | Choose mode per task |
| No scope limits | Blast radius | Define per-agent scopes |
| Ad-hoc sessions | Session templates | Create templates for common tasks |

### 20.2 Migration Steps

1. Run `./install.sh --upgrade` to create new directory structure
2. Move existing brain files to correct memory tier locations
3. Review and update agent profiles for tool scoping
4. Configure quality gates for your pipeline
5. Set initial autonomy level (recommend L1)
6. Run /aegis-start to verify the new installation

---

## 21. Appendices

### A. Glossary

| Term | Definition |
|------|-----------|
| A2A | Agent-to-Agent protocol for structured communication |
| ACP | Agent Capability Profile — defines what an agent can do |
| ADR | Architecture Decision Record |
| Blast Radius | The set of files/directories an agent is allowed to modify |
| Brain | The persistent memory store (`_aegis-brain/`) |
| Crew | A dynamic team of agents assembled for a complex task |
| Distillation | Compressing conversation context into essential summaries |
| Flow | A deterministic pipeline of agent stages |
| Gate | A quality validation checkpoint between pipeline stages |
| Reflexion | An agent's self-critique after a failed attempt |
| Resonance | Snapshot files that enable session continuity |
| Retro | Retrospective — structured review at session end |

### B. Token Budget Estimates

| Component | Estimated Tokens |
|-----------|-----------------|
| CLAUDE.md | ~400 |
| CLAUDE_safety.md | ~2,500 |
| CLAUDE_agents.md | ~3,500 |
| CLAUDE_skills.md | ~2,000 |
| CLAUDE_lessons.md | ~2,000 |
| Resonance files | ~500 |
| Per-skill load | ~300-500 |
| Per-agent report | ~500-2,000 |
| Structured message | ~100-200 |

### C. Example Session Transcript

```
Human: /aegis-start
Captain America:  Loading CLAUDE.md... ✓
       Loading resonance files... ✓
       Current autonomy: L1
       Profile: standard (13 skills available)
       Last session: #5 (2 days ago)
       Key context: Working on auth feature, Iron Man approved JWT design
       Ready. What would you like to work on?