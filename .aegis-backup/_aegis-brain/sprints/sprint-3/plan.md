# Sprint-3 Plan

## Goal
Complete AEGIS: Scribe auto-generates versioned ISO docs

## Duration
- Start: 2026-03-30
- End: 2026-04-04

## Capacity
- Available: 22 pts
- Committed: 5 pts

## Tasks

| ID | Title | Points | Assignee | Priority |
|----|-------|--------|----------|----------|
| PROJ-T-009 | Scribe generates versioned ISO docs automatically | 5 | @scribe | medium |

## Scope
This is the final sprint. The single task covers:
- Aligning ISO 29110 document directory structure with doc-registry.json
- Correcting document frontmatter to match ISO activity numbering
- Creating the missing PM-05 Correction Register (PM.3 requirement)
- Verifying all 12 ISO documents have current.md, v1.md, and changelog.md
- Ensuring the /aegis-compliance command can audit document status
- Updating doc-registry.json to reflect current state

## Definition of Done
- All 12 ISO doc directories match registry slugs
- All frontmatter document IDs match ISO 29110 activity numbering
- PM-05 Correction Register exists with entries
- doc-registry.json is fully accurate
- /aegis-compliance check would show 12/12 documents present
