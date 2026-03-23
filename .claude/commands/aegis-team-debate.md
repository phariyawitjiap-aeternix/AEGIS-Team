---
name: aegis-team-debate
description: "Spawn debate team — multi-perspective architecture decisions"
triggers:
  en: debate, architecture decision, team debate, decide
  th: ถกเถียง, ทีมถกเถียง, ตัดสินใจ
---

# /aegis-team-debate

Spawn a debate team using Claude Code's **built-in Agent tool**.

## Instructions

When this command is triggered:

### Step 1: Determine the topic

Look at the user's message for the debate topic:
- "ถกเถียง — SQL vs NoSQL" → topic is "SQL vs NoSQL"
- "/aegis-team-debate monolith or microservices" → topic is "monolith or microservices"
- Just "/aegis-team-debate" → ask: "What architecture decision should we debate?"

### Step 2: Spawn agents using the Agent tool

Launch all perspectives in **parallel**, then synthesize:

**Perspective 1: Architecture (📐 Sage) — run in background**

Use the Agent tool with `run_in_background: true`:
```
subagent_type: use the agent defined in .claude/agents/sage.md
prompt: |
  You are Sage, the architect, in an architecture debate.
  Topic: [TOPIC]

  Present 2-3 architecture options with:
  1. Option name and description
  2. Pros and cons
  3. When each option is best suited
  4. Long-term maintenance implications
  5. Your recommended option with rationale

  Write to: _aegis-output/debates/sage-proposal.md
```

**Perspective 2: Feasibility (⚡ Bolt) — run in background**

Use the Agent tool with `run_in_background: true`:
```
subagent_type: use the agent defined in .claude/agents/bolt.md
prompt: |
  You are Bolt, the implementer, in an architecture debate.
  Topic: [TOPIC]

  For each realistic option, evaluate:
  1. Implementation effort (hours/days/weeks)
  2. Technical complexity
  3. Libraries/tools needed
  4. Team skill requirements
  5. Migration path from current state

  Write to: _aegis-output/debates/bolt-feasibility.md
```

**Perspective 3: Challenge (🔴 Havoc) — run in background**

Use the Agent tool with `run_in_background: true`:
```
subagent_type: use the agent defined in .claude/agents/havoc.md
prompt: |
  You are Havoc, the devil's advocate, in an architecture debate.
  Topic: [TOPIC]

  Challenge EVERY option:
  1. What breaks at 10x scale?
  2. What's the worst-case failure mode?
  3. What assumptions are wrong?
  4. What hidden costs exist?
  5. What would make you choose the OTHER option?

  Write to: _aegis-output/debates/havoc-challenges.md
```

Wait for ALL 3 to complete.

**Synthesis: Decision (🧭 Navi)**

Use the Agent tool:
```
subagent_type: use the agent defined in .claude/agents/navi.md
prompt: |
  You are Navi, the navigator, synthesizing a debate.
  Topic: [TOPIC]

  Read all 3 perspectives:
  - _aegis-output/debates/sage-proposal.md
  - _aegis-output/debates/bolt-feasibility.md
  - _aegis-output/debates/havoc-challenges.md

  Produce an Architecture Decision Record (ADR):
  1. Decision: [chosen option]
  2. Status: Accepted
  3. Context: [why this decision was needed]
  4. Options considered: [from Sage]
  5. Feasibility: [from Bolt]
  6. Risks mitigated: [from Havoc]
  7. Consequences: [trade-offs accepted]

  Save ADR to: _aegis-brain/resonance/architecture-decisions.md (append)
  Write debate summary to: _aegis-output/debates/decision.md
```

### Step 3: Report results

```
🛡️ Debate Complete!

📐 Sage: [options proposed]
⚡ Bolt: [feasibility assessment]
🔴 Havoc: [challenges raised]
🧭 Navi: Decision → [chosen option]
         Rationale: [why]

ADR saved to: _aegis-brain/resonance/architecture-decisions.md
```
