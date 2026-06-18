# AEGIS Application Playbook

> Step-by-step guide for applying AEGIS to any new project.

## Overview

AEGIS (Autonomous Enhanced Governance & Intelligence System) is a framework
that turns Claude Code into an autonomous development team. This playbook
walks you through applying it to a new project -- from blank directory to
first sprint delivery.

**Time to first sprint**: ~15 minutes for a solo project, ~30 minutes for
a full team project.

**Prerequisites**:
- Claude Code CLI installed and authenticated
- Git repository (existing or new)
- Node.js / Python / Go / Rust / etc. -- AEGIS is language-agnostic

---

## 1. Initialize the Brain

The brain is AEGIS's memory and decision-making substrate. It persists
across sessions.

```bash
# From your project root:
mkdir -p .aegis/brain/{logs,metrics,resonance,learnings,instincts/{promoted,active,pending},handoffs,retrospectives,sprints/{current},state,conversations,design-library}
```

### 1.1 Create Project Identity

The identity file tells AEGIS what your project IS. Every decision the
system makes references this file.

Create `.aegis/brain/resonance/project-identity.md`:

```markdown
# Project Identity

## Name
<your-project-name>

## One-liner
<one sentence describing the project>

## Tech Stack
- Language: <e.g., TypeScript>
- Framework: <e.g., Next.js 15>
- Database: <e.g., PostgreSQL>
- Hosting: <e.g., Vercel>

## Conventions
- Testing: <e.g., Vitest for unit, Playwright for e2e>
- Linting: <e.g., ESLint + Prettier>
- Git: <e.g., conventional commits, squash merge>

## Non-Negotiables
- <e.g., 80% code coverage on all new code>
- <e.g., No direct database access from UI components>
- <e.g., All API endpoints require authentication>
```

### 1.2 Seed Architecture Decisions

Create `.aegis/brain/resonance/architecture-decisions.md`:

```markdown
# Architecture Decision Records

> Each decision is immutable once recorded.

---

## ADR-001: <Your First Decision>

**Date**: <today>
**Status**: Accepted
**Context**: <why this decision matters>
**Decision**: <what you decided>
**Consequences (+)**: <benefits>
**Consequences (-)**: <trade-offs>
```

### 1.3 Seed Team Conventions

Create `.aegis/brain/resonance/team-conventions.md`:

```markdown
# Team Conventions

## Commit Messages
<e.g., Conventional commits: feat/fix/chore/docs(scope): description>

## Branch Naming
<e.g., feat/<ticket-id>-<short-description>>

## PR Process
<e.g., Squash merge, require 1 review>

## Code Style
<e.g., Follow .editorconfig + linter rules>
```

---

## 2. Configure CLAUDE.md

CLAUDE.md is the file Claude Code reads at session start. It tells the
system how to behave for THIS project.

Copy the AEGIS template and customize:

```markdown
# <Your Project Name> -- AEGIS-Powered

## Golden Rules
1. NEVER use --force flags on git
2. NEVER push to main -- branch + PR always
3. NEVER git commit --amend
4. Agents ask Nick Fury, not the human (Master Brain Protocol)
5. Run /aegis-start at session begin
6. Run /aegis-retro at session end

## Nick Fury
After /aegis-start, Nick Fury takes full control.
Default autonomy: L3 (Autonomous)

## Quick Commands
| Command | Purpose |
|---------|---------|
| /aegis-start | Begin session |
| /aegis-status | Check progress |
| /aegis-retro | End session -- retrospective |
| /aegis-sprint | Sprint lifecycle |
| /aegis-breakdown | Decompose stories |

## Project Context
- Stack: <your stack>
- Repository: <your repo URL>
- Primary language: <language>
```

---

## 3. Set Up Persona Team

AEGIS has 8 active personas. Choose which ones to enable based on your
project profile.

### Full Team (enterprise / 5+ person projects)

| Persona | Role | When Active |
|---------|------|-------------|
| Nick Fury | Decision engine, orchestrator | Always |
| Iron Man | Architecture, specs | Design phase |
| Loki | Adversarial review, plan approval | Every spec review |
| Spider-Man | Implementation | Build phase |
| Black Panther | Code review, quality gate | Every PR |
| War Machine | QA planning | Tasks >= 3pt |
| Captain America | Orchestration fallback | When Nick Fury defers |
| Coulson | ISO compliance docs | Sprint close |

### Standard Team (typical projects)

Enable: Nick Fury, Iron Man, Spider-Man, Black Panther, Loki
Skip: War Machine (BP review sufficient), Coulson (no compliance need),
Captain America (Nick Fury handles everything)

### Solo Mode (side projects, prototypes)

Enable: Nick Fury only (subsumes all roles)
Nick Fury scans, decides, builds, reviews in a single decision loop.
No agent spawning overhead.

### Agent File Setup

Create `.claude/agents/<persona-name>.md` for each enabled persona.
Copy templates from the AEGIS-Team repository's `.claude/agents/` directory.

Minimum viable agent file:
```markdown
---
name: <persona-name>
description: "<one-liner>"
---

# <Persona Name>

## Role
<what this agent does>

## Constraints
- MUST NOT ask the human directly
- <additional constraints>
```

---

## 4. BLOCK 0 Bootstrap Sequence

BLOCK 0 ensures documentation exists before any code is written.
This is the correct order:

### Step 1: PM.01 Project Plan (if using Coulson)

```
mkdir -p _aegis-output/iso-docs/PM-01-project-plan
# Coulson generates this, or create manually:
# current.md with project scope, timeline, milestones
```

### Step 2: SI.01 Requirements Specification

```
mkdir -p _aegis-output/iso-docs/SI-01-requirements-spec
# Document functional requirements as REQ-001, REQ-002, etc.
# Each requirement: ID, description, priority, acceptance criteria
```

### Step 3: Task Breakdown (Epic -> Task -> Sub-task)

```
mkdir -p .aegis/brain/tasks
# Or run /aegis-breakdown from your spec

# Structure:
# .aegis/brain/tasks/PROJ-E-001/meta.json  (Epic)
# .aegis/brain/tasks/PROJ-T-001/meta.json  (Task, links to Epic)
# Each Task has sub_tasks[] in meta.json
```

### Step 4: Sprint + Kanban

```
# Create sprint plan:
# .aegis/brain/sprints/sprint-1/plan.md
# .aegis/brain/sprints/sprint-1/kanban.md

# Symlink current:
cd .aegis/brain/sprints && ln -s sprint-1 current
```

### Step 5: SI.02 Traceability Matrix (if using Coulson)

```
mkdir -p _aegis-output/iso-docs/SI-02-traceability-matrix
# Maps REQ-xxx to TASK-xxx to TEST-xxx
```

### Lite Mode (for small tasks)

Tasks <= 1 story point or tagged `chore/typo/docs-fix/hotfix` use BLOCK 0
lite mode: only Steps 3 and 4 are required. SI.01, SI.02, and PM.01 are
skipped.

---

## 5. First Sprint

### 5.1 Open Sprint

```
/aegis-sprint plan
```

Or manually create the plan and kanban files.

### 5.2 Start AEGIS

```
/aegis-start
```

Nick Fury will:
1. Scan project state (git, tests, specs, deps)
2. Check BLOCK 0 (generate missing docs if needed)
3. Pick the highest-priority TODO from kanban
4. Spawn the build team
5. Code review (Black Panther)
6. Move task to DONE
7. Pick next task
8. Repeat until sprint is empty or context budget exhausted

### 5.3 Monitor Progress

```
/aegis-status
```

Shows: kanban state, active agents, test results, context budget.

### 5.4 End Session

```
/aegis-retro
```

Generates: retrospective, lessons learned, handoff for next session.

---

## 6. Golden Path Example: Greenfield React App

Here is a complete walkthrough applying AEGIS to a new React application.

### Setup (5 minutes)

```bash
# 1. Create React app
npx create-next-app@latest my-app --typescript
cd my-app
git init && git add -A && git commit -m "initial commit"

# 2. Initialize AEGIS brain
mkdir -p .aegis/brain/{logs,metrics,resonance,learnings,instincts/{promoted,active,pending},handoffs,retrospectives,sprints/{current},state,conversations}

# 3. Create project identity
cat > .aegis/brain/resonance/project-identity.md << 'IDENTITY'
# Project Identity
## Name
my-app
## One-liner
A Next.js 15 web application with TypeScript.
## Tech Stack
- Language: TypeScript
- Framework: Next.js 15
- Testing: Vitest + Playwright
- Linting: ESLint
## Non-Negotiables
- All new features have tests
- Server components by default, client only when needed
IDENTITY

# 4. Create CLAUDE.md (copy AEGIS template, customize project section)

# 5. Copy agent files from AEGIS-Team repo
mkdir -p .claude/agents
# Copy nick-fury.md, iron-man.md, spider-man.md, black-panther.md, loki.md
```

### First Session (10 minutes)

```
# Start Claude Code in the project directory
claude

# Type:
/aegis-start

# Nick Fury activates, scans, detects:
# - No spec -> runs /super-spec or prompts for project description
# - No breakdown -> runs /aegis-breakdown
# - No sprint -> runs /aegis-sprint plan
# - BLOCK 0 checks -> generates missing docs
# - Then picks first TODO and starts building
```

### Ongoing Sessions

```
# Each session:
/aegis-start          # Nick Fury picks up where last session left off
# ... autonomous work ...
/aegis-retro          # Saves learnings, writes handoff

# Sprint lifecycle:
/aegis-sprint status  # Check progress
/aegis-sprint close   # Close sprint, open next
```

---

## 7. Anti-Patterns to Avoid

### Do NOT force all skills on a small project

AEGIS has 12+ skills (shell-lint, design-lint, policy-audit, etc.).
A solo side project does not need all of them. Let Nick Fury decide
which skills are relevant based on the task at hand.

### Do NOT skip BLOCK 0

Even for "just a quick fix", BLOCK 0 lite mode (task + kanban entry)
takes 30 seconds and makes the work traceable. The full mode (PM.01 +
SI.01 + SI.02) is only required for features >= 6 points.

### Do NOT ask agents questions directly

The Master Brain Protocol (MBP) is the #1 rule. All questions route
through Nick Fury. If you find yourself typing a question to Claude Code
mid-task, stop -- Nick Fury should be making that decision from the brain,
instincts, and ADRs.

### Do NOT amend commits

`git commit --amend` breaks all agents' understanding of git history.
Create new commits instead. The squash merge at PR time handles cleanup.

### Do NOT push to main

Always branch + PR. This is non-negotiable. Even Nick Fury at L4 autonomy
respects this rule.

### Do NOT ignore retrospective findings

`/aegis-retro` extracts lessons. If the same friction point appears
3 times, it becomes a promoted instinct (hard rule). Ignoring retro
findings defeats the self-improvement loop.

---

## 8. Hooks Setup (Optional but Recommended)

AEGIS hooks enforce Golden Rules at the machine level. To install:

### settings.json

Create `.claude/settings.json`:
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{"type": "command", "command": "bash .claude/hooks/guard-bash.sh"}]
      }
    ]
  },
  "permissions": {
    "defaultMode": "acceptEdits",
    "allow": ["Read", "Write", "Edit", "Glob", "Grep", "Agent"],
    "deny": [
      "Bash(git push --force:*)",
      "Bash(git commit --amend:*)",
      "Bash(rm -rf /:*)"
    ]
  }
}
```

### Minimum hook: guard-bash.sh

Blocks destructive git operations. Copy from the AEGIS-Team repository's
`.claude/hooks/guard-bash.sh`.

---

## 9. Directory Structure Reference

After full setup, your project should have:

```
your-project/
  .aegis/
    brain/
      logs/              # activity.log, decision-audit.log
      metrics/           # judgment-fallback-counter.json
      resonance/         # project-identity.md, architecture-decisions.md, team-conventions.md
      learnings/         # session learnings (auto-generated)
      instincts/         # promoted/, active/, pending/
      handoffs/          # session handoff documents
      retrospectives/    # sprint retros
      sprints/           # sprint-1/, sprint-2/, current -> sprint-N/
      state/             # maintainer-mode grants, etc.
      conversations/     # team chat logs
  .claude/
    agents/              # nick-fury.md, spider-man.md, etc.
    hooks/               # guard-bash.sh, etc.
    references/          # framework reference docs
    settings.json        # permissions + hook wiring
  CLAUDE.md              # project-level Claude Code config
  _aegis-output/         # generated specs, ISO docs (gitignored selectively)
```

---

## 10. Troubleshooting

### "BLOCK 0 keeps failing"

Check which sub-check fails (A through E). Most common:
- 0C: No task structure -> run `/aegis-breakdown`
- 0D: No kanban -> run `/aegis-sprint plan`
- 0B: No SI.01 -> have Coulson generate it, or create a stub

### "Nick Fury asks me questions"

This is an MBP violation. Nick Fury should only ask about:
1. Project identity (empty project, no resonance)
2. Irreversible scope (deleting modules permanently)
3. External access (API keys, credentials)
4. Explicit approval gates (production deployment)

If he asks anything else, the brain is under-populated. Add more to
`project-identity.md`, `team-conventions.md`, and `architecture-decisions.md`.

### "Context budget exhausted mid-task"

Normal for large tasks. Nick Fury writes a handoff before stopping.
Run `/aegis-start` in a new session -- it reads the handoff and continues.

### "Tests fail after agent changes"

Run `bash tools/aegis-test-all.sh` to identify which harness fails.
Check the FAIL output for the specific assertion. Most failures are
path-related (file moved or renamed) or format-related (output changed).
