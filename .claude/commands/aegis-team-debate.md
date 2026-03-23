---
name: aegis-team-debate
description: "Spawn debate team — multi-perspective architecture decisions"
triggers:
  en: debate, architecture decision, team debate, decide
  th: ถกเถียง, ทีมถกเถียง, ตัดสินใจ
---

# /aegis-team-debate

Spawn a debate team using Claude Code's **TeamCreate + Agent Teams**.

Each agent runs in its own tmux pane. All perspectives run in parallel, then Navi synthesizes.

## Instructions

### Step 1: Determine the topic

Look at the user's message for the debate topic. If no topic, ask: "What architecture decision should we debate?"

### Step 2: Create the team

Use **TeamCreate**:
```
team_name: "aegis-debate"
description: "Debate team: Sage proposes + Bolt evaluates + Havoc challenges → Navi decides. Topic: [TOPIC]"
```

### Step 3: Spawn teammates

**Spawn Sage (Proposer):**
```
Agent(
  subagent_type: "sage",
  team_name: "aegis-debate",
  name: "sage",
  prompt: "You are Sage in an architecture debate. Topic: [TOPIC]. Present 2-3 options with pros, cons, and your recommendation. Write to _aegis-output/debates/sage-proposal.md. When done, mark task complete.",
  run_in_background: true
)
```

**Spawn Bolt (Feasibility):**
```
Agent(
  subagent_type: "bolt",
  team_name: "aegis-debate",
  name: "bolt",
  prompt: "You are Bolt in an architecture debate. Topic: [TOPIC]. Evaluate implementation effort, complexity, and migration path for each option. Write to _aegis-output/debates/bolt-feasibility.md. When done, mark task complete.",
  run_in_background: true
)
```

**Spawn Havoc (Challenger):**
```
Agent(
  subagent_type: "havoc",
  team_name: "aegis-debate",
  name: "havoc",
  prompt: "You are Havoc in an architecture debate. Topic: [TOPIC]. Challenge EVERY option — what breaks at scale? What assumptions are wrong? What hidden costs? Write to _aegis-output/debates/havoc-challenges.md. When done, mark task complete.",
  run_in_background: true
)
```

Wait for all 3 to complete.

**Spawn Navi (Synthesizer):**
```
Agent(
  subagent_type: "navi",
  team_name: "aegis-debate",
  name: "navi",
  prompt: "You are Navi, synthesizing a debate. Read _aegis-output/debates/sage-proposal.md, bolt-feasibility.md, havoc-challenges.md. Produce an ADR with decision, context, options, and consequences. Save to _aegis-brain/resonance/architecture-decisions.md (append).",
  run_in_background: true
)
```

### Step 4: Report and shutdown

Report the decision, then shutdown all teammates + TeamDelete.

## Team Composition

| Agent | Role | Model | tmux Pane |
|-------|------|-------|-----------|
| 📐 Sage | Proposer — presents options | opus | Own pane |
| ⚡ Bolt | Feasibility — evaluates effort | sonnet | Own pane |
| 🔴 Havoc | Challenger — stress tests | opus | Own pane |
| 🧭 Navi | Synthesizer — makes decision | opus | Own pane |
