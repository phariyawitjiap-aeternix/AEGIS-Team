---
date: 2026-04-23
category: workflow
confidence: high
source_sprint: sprint-v9-05
related_decisions: D-051, D-054
---

# Spec Mega-Delivery Pattern

## Context

sprint-v9-05 had 13pt of work framed as "9 loose deliverables closing the gap to 100%". The default instinct was 9 specs, 9 Loki gates, 9 Spider-Man cycles, 9 BP reviews. That framing would have consumed ~2-3 sessions. Instead, Iron Man authored one unified 973-LOC spec (`FINAL-PUSH-spec.md`) treating the 9 items as three themed blocks (F1 hardening, F2 consolidation, F3 lifecycle). The single spec went through two Loki rounds (CONDITIONAL → APPROVE, D-054) and one Spider-Man build cycle. Total review latency dropped roughly 30% vs. the 9-spec baseline.

## Lesson

When N deliverables share a theme — same abstraction level, overlapping files, common reviewer context — fold them into ONE spec with clearly sectioned work blocks. The coherence penalty (a longer spec) is absorbed by the amortized review cost (one Loki, one Spider-Man, one BP cycle). The thematic grouping also makes cross-deliverable consistency bugs easier to catch: F1-05's Loki integration gap was visible because F1-05's spec section was adjacent to the shell-lint tool section, not in a separate file.

## Application

**Use when**:
- 3+ deliverables touch the same subsystem or reviewer concern
- Deliverables can be introduced in any order (low inter-dependency)
- One spec author can reason about all of them coherently
- Single reviewer (Loki or BP) can gate them together

**Don't use when**:
- Deliverables are at different abstraction levels (e.g., architectural + tactical)
- Different reviewer specialists needed (security vs. performance)
- Inter-deliverable dependencies force sequential delivery
- Spec would exceed ~1000 LOC (readability cliff)

**Mandatory guardrail**: the unified spec MUST include a "Tool Deliverables Matrix" (or equivalent section) listing every touchpoint. Prose-only integration points are a known spec bug class — BP round-1 caught exactly that in sprint-v9-05.

**Canonical example**: `_aegis-output/specs/FINAL-PUSH-spec.md` v1.1 (973 LOC, Loki APPROVED D-054, delivered 13pt in one cycle).
