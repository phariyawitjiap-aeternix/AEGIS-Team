# Sprint v10-01 Plan — Project-Wide Traceability Wiki

> Created: 2026-04-24
> Points: 13 (5 stories)
> Series: v10 (Framework Application)
> Status: ACTIVE

## Goal

Establish project-wide traceability by connecting all 5 disconnected numbering
systems (doc-level, requirement-level, design-level, test-level, task-level)
into a single navigable wiki with automated drift detection.

## Stories

| ID | Title | Points | Assignee | Status |
|----|-------|--------|----------|--------|
| v10-01-A | Refresh SI.02 traceability matrix | 2 | spider-man | TODO |
| v10-01-B | Author MOD-XX module numbering scheme | 3 | spider-man | TODO |
| v10-01-C | Auto-generate FUNC-XX catalog | 3 | spider-man | TODO |
| v10-01-D | Create root PROJECT_INDEX.md | 3 | spider-man | TODO |
| v10-01-E | tools/aegis-trace-audit.sh | 2 | spider-man | TODO |

## Acceptance Criteria

1. SI.02 reflects reality: 10 agents, 12 canonical commands + 17 shims, correct doc IDs
2. MOD-XX catalog in SI.03 with 8-12 modules, each with owner/files/deps
3. FUNC-XX catalog auto-generated from tools/*.sh + agents/*.md + commands/*.md
4. PROJECT_INDEX.md at repo root cross-references all numbering systems
5. aegis-trace-audit.sh validates all cross-references with exit 0 on clean state
6. TI-01 debt closed

## Dependencies

- None (all in-repo, all existing artifacts)

## Risks

- SI.02 may have more stale claims than identified — full line-by-line audit needed
- FUNC-XX generation must be idempotent — hash-based IDs preferred over sequential
