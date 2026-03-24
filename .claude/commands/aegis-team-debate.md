---
name: aegis-team-debate
description: "Spawn debate team — multi-perspective architecture decisions"
triggers:
  en: debate, architecture decision, team debate, decide, /aegis-team-debate
  th: ถกเถียง, ทีมถกเถียง, อภิปราย, ดีเบต
---

You MUST execute ALL of the following steps NOW. Do not explain — just do it.

## Step 1: Get the Topic

The user's message contains the debate topic. If empty, use: "$ARGUMENTS"
If still empty, ask the user: "What architecture decision should we debate?"

## Step 2: Threshold Check

Evaluate the debate complexity:
- If it's a simple binary choice (e.g., "tabs vs spaces") → run in **SOLO mode**: use a single Agent (Sage) to analyze pros/cons and recommend. Skip team creation. Go to Step 6.
- If it's a real architecture decision with trade-offs, unknown requirements, or multiple valid options → run in **TEAM mode**: proceed to Step 3.

Report which mode was selected and why.

## Step 3: Create Team

Call TeamCreate:
- team_name: "aegis-debate"
- description: "Architecture debate: [TOPIC]"

## Step 4: Spawn 4 Teammates (all in parallel)

Call Agent tool 4 times in a SINGLE message (parallel). All agents run in-process.

1. Agent with subagent_type="sage", team_name="aegis-debate", name="sage", mode="bypassPermissions", run_in_background=true
   Prompt: "You are 📐 Sage the architect on team aegis-debate. Read .claude/agents/sage.md for your persona. TOPIC: [TOPIC]. Propose 2-3 architecture options with clear trade-offs for each. Include: scalability, maintainability, cost, complexity, team skill requirements. SUCCESS CRITERIA: Each option has pros, cons, and a recommended use case. Send your proposals to all teammates via SendMessage."

2. Agent with subagent_type="bolt", team_name="aegis-debate", name="bolt", mode="bypassPermissions", run_in_background=true
   Prompt: "You are ⚡ Bolt the implementer on team aegis-debate. Read .claude/agents/bolt.md for your persona. TOPIC: [TOPIC]. Wait for sage's proposals. Then evaluate each option from an implementation perspective: effort estimate, migration complexity, dependency impact, testing difficulty. SUCCESS CRITERIA: Each option rated by implementation feasibility (Easy/Medium/Hard) with specific reasoning. Send your evaluation to navi via SendMessage."

3. Agent with subagent_type="havoc", team_name="aegis-debate", name="havoc", mode="bypassPermissions", run_in_background=true
   Prompt: "You are 🔴 Havoc the devil's advocate on team aegis-debate. Read .claude/agents/havoc.md for your persona. TOPIC: [TOPIC]. Wait for sage's proposals. Then challenge EVERY option: What could go wrong? What assumptions are wrong? What's the worst case? What are they not considering? SUCCESS CRITERIA: At least 2 challenges per option with severity rating. Send your challenges to navi via SendMessage."

4. Agent with subagent_type="navi", team_name="aegis-debate", name="navi", mode="bypassPermissions", run_in_background=true
   Prompt: "You are 🧭 Navi the navigator on team aegis-debate. Read .claude/agents/navi.md for your persona. TOPIC: [TOPIC]. Wait for input from sage (proposals), bolt (feasibility), and havoc (challenges). Then synthesize into a final Architecture Decision Record (ADR). Write the ADR to _aegis-brain/resonance/architecture-decisions.md (append, don't overwrite). SUCCESS CRITERIA: ADR contains: context, options considered, decision, rationale, consequences, and dissenting views. Send the decision summary to the team lead via SendMessage."

## Step 5: Report to user

```
🛡️ AEGIS Debate Team Spawned!

📐 Sage (proposer) — Designing options...
⚡ Bolt (feasibility) — Waiting for proposals...
🔴 Havoc (challenger) — Waiting to challenge...
🧭 Navi (synthesizer) — Waiting to write ADR...

Pipeline: Sage → [Bolt + Havoc] (parallel) → Navi
View agents: Shift+Down | Back to main: Shift+Up
```

## Step 6: Integration (after all agents complete)

1. Read Navi's ADR from _aegis-brain/resonance/architecture-decisions.md
2. Present the decision:
   - Chosen option and rationale
   - Key trade-offs acknowledged
   - Dissenting views (from Havoc)
   - Implementation notes (from Bolt)
3. Ask user: "Do you agree with this decision? If not, we can re-debate with constraints."
4. Send shutdown_request to each teammate, then TeamDelete

## Failure Handling

If any agent fails to respond within a reasonable time:
1. Check agent status via team tools
2. If stuck → send a nudge message with simplified instructions
3. If errored → report error to user, proceed with available results
4. If multiple fail → abort team, report partial results, suggest retry
