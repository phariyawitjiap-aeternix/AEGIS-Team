---
name: aegis-review
description: "Deep multi-perspective code review team"
lead: vigil
members: [havoc, forge]
mode: in-process
requires: agent-teams
---

## Team Purpose
Multi-perspective review combining quality enforcement (Vigil), adversarial challenge (Havoc), and data gathering (Forge).

## Task Breakdown
1. Forge (haiku): Scan codebase, gather metrics, identify hotspots
2. Havoc (opus): Challenge assumptions, find edge cases, adversarial test
3. Vigil (sonnet): Synthesize findings, enforce quality gate, write report

## Communication Flow
Forge → StatusUpdate → Vigil
Havoc → FindingReport → Vigil
Vigil → QualityGate → Lead (Navi)

## Review Gate
- 0 critical findings = PASS
- 1+ critical = FAIL (with details)
- Warnings only = CONDITIONAL (human decides)

## Output
_aegis-output/team-reviews/YYYY-MM-DD_review.md
