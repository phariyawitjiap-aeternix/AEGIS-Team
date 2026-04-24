---
date: 2026-04-23
category: other
confidence: high
source_sprint: sprint-v9-05
related_decisions: BP MEDIUM-01 (PR #54 round-1)
---

# Prose-Only Integration Points are a Spec Bug Class

## Context

FINAL-PUSH-spec.md (v1.1, 973 LOC) described F1-05 as "shell-lint tool + Loki integration". The tool itself (`tools/aegis-shell-lint.sh`) was listed in the Tool Deliverables Matrix. The Loki integration — the instruction to invoke the tool before structural review — was described in the prose under "Integration" paragraph but NOT in the matrix. Spider-Man's self-check used the matrix as his checklist and shipped without touching `loki.md`. BP round-1 caught this as MEDIUM-01 by doing a spec-to-file cross-check: "spec says integrate with loki.md; diff doesn't touch loki.md; blocker."

The feature would have shipped non-functional — the linter existed but no agent ever invoked it — if BP had trusted the self-report.

## Lesson

**A deliverable is complete only when every touchpoint is enumerable.** Prose descriptions of integration points are a known hiding place for forgotten work. If a spec says "integrate with X" or "add to Y" or "call this from Z", those integration sites must appear in a structured section (matrix, table, list) — not as inline prose paragraphs.

## Application

**Spec format requirement** (retroactive, apply to all future specs):

Every spec that claims integration with existing files MUST include a section like:

```markdown
## Cross-Cutting Touchpoints

| Deliverable | Integration Target | Required Change |
|-------------|-------------------|-----------------|
| F1-05 shell-lint tool | .claude/agents/loki.md | Add invocation line in Spec Format Enforcement section |
| F3-02 auto-reinforce | .claude/hooks/on-stop.sh | Call from session-end hook |
```

This section is the single source of truth for "what other files must change". Implementer's checklist = this table. Reviewer's cross-check = this table. Prose in other sections is commentary, not spec.

**BP review criterion** (add to quality-protocol.md):
When reviewing a PR against a spec that claims integration points, explicitly diff the PR file list against the spec's Cross-Cutting Touchpoints table. Any target listed but not in the diff = MEDIUM blocker minimum.

**Iron Man spec template update** (proposed for v9-06):
Add Cross-Cutting Touchpoints to the mandatory sections list in `.claude/agents/iron-man.md` alongside Soul / Matrix / Do's & Don'ts / Agent Prompt Guide.

**Canonical cautionary example**: FINAL-PUSH-spec.md v1.1 — F1-05 Loki integration in prose but not in matrix → Spider-Man shipped tool without invocation → BP caught on round-1 MEDIUM-01.
