---
name: aegis-build
description: "Spec-to-implementation build team"
lead: bolt
members: [sage, vigil]
mode: agent-team
fallback: subagent
---

## Team Purpose
End-to-end build pipeline: Sage designs → Bolt implements → Vigil reviews.

## Task Breakdown
1. Sage (opus): Write/refine technical spec
2. Bolt (sonnet): Implement based on spec
3. Vigil (sonnet): Review implementation against spec

## Communication Flow
Sage → PlanProposal → Bolt
Bolt → StatusUpdate → Vigil
Vigil → FindingReport → Bolt (iterate if needed)
Bolt → CompletionReport → Lead

## Pipeline
Sage spec → GATE → Bolt implement → GATE → Vigil review → GATE → Done

## Output
_aegis-output/builds/YYYY-MM-DD_build.md
