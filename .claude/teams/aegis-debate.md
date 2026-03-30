---
name: aegis-debate
description: "Architecture decision debate team"
lead: navi
members: [sage, bolt, havoc]
mode: in-process
requires: agent-teams
---

## Team Purpose
Structured debate for architecture decisions. Multiple perspectives, devil's advocate, consensus building.

## Task Breakdown
1. Sage (opus): Present architecture options with trade-offs
2. Bolt (sonnet): Evaluate implementation feasibility of each option
3. Havoc (opus): Challenge every option, find failure modes
4. Navi (opus): Facilitate, synthesize, drive consensus

## Communication Flow
All → PlanProposal → Navi (proposals)
Havoc → CounterProposal → All (challenges)
Navi → ApprovalRequest → All (vote)
Navi → ArchitectureDecision → All (final)

## Output
_aegis-brain/resonance/architecture-decisions.md (append)
_aegis-output/debates/YYYY-MM-DD_debate.md
