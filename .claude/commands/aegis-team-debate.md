---
name: aegis-team-debate
description: "Spawn debate team — multi-perspective architecture decisions"
triggers:
  en: debate, architecture decision, team debate, decide
  th: ถกเถียง, ดีเบต, ตัดสินใจสถาปัตยกรรม
---

You MUST execute ALL of the following steps NOW. Do not explain — just do it.

## Step 1: Get the topic

The user's message contains the debate topic. If empty, use: "$ARGUMENTS"

## Step 2: Create team NOW

Call TeamCreate right now:
- team_name: "aegis-debate"
- description: "Architecture debate: [TOPIC]"

## Step 3: Spawn 4 teammates NOW (all in parallel)

Call Agent tool 4 times in a SINGLE message (parallel):

1. Agent with subagent_type="sage", team_name="aegis-debate", name="sage", mode="bypassPermissions", run_in_background=true, prompt="You are 📐 Sage the architect. Read .claude/agents/sage.md for your persona. DEBATE TOPIC: [TOPIC]. Present 2-3 architecture options with clear trade-offs for each. Send your proposal to navi via SendMessage when ready."

2. Agent with subagent_type="bolt", team_name="aegis-debate", name="bolt", mode="bypassPermissions", run_in_background=true, prompt="You are ⚡ Bolt the implementer. Read .claude/agents/bolt.md for your persona. DEBATE TOPIC: [TOPIC]. Wait for sage's proposal. Evaluate each option for implementation feasibility — effort, complexity, risk. Send your analysis to navi via SendMessage."

3. Agent with subagent_type="havoc", team_name="aegis-debate", name="havoc", mode="bypassPermissions", run_in_background=true, prompt="You are 🔴 Havoc the devil's advocate. Read .claude/agents/havoc.md for your persona. DEBATE TOPIC: [TOPIC]. Wait for sage's proposal. Challenge every option — find what could go wrong, identify hidden assumptions, stress-test scalability. Send your challenges to navi via SendMessage."

4. Agent with subagent_type="navi", team_name="aegis-debate", name="navi", mode="bypassPermissions", run_in_background=true, prompt="You are 🧭 Navi the navigator. Read .claude/agents/navi.md for your persona. DEBATE TOPIC: [TOPIC]. Wait for input from sage, bolt, and havoc. Synthesize all perspectives into a consensus decision. Write ADR (Architecture Decision Record) to _aegis-brain/resonance/architecture-decisions.md. Send final decision to team lead via SendMessage."

## Step 4: Report and cleanup when done

Summarize the decision, send shutdown_request to each, then TeamDelete.
