# Spec: PROJ-T-006 -- Cross-session continuity via handoff

## Summary
Ensure /aegis-handoff writes a structured transfer brief and /aegis-start reads it
to resume from where the last session left off. The handoff directory must exist,
the handoff format must include all necessary state for Mother Brain to pick up
seamlessly, and /aegis-start must explicitly load the latest handoff.

## Current State
- aegis-handoff.md command exists with 7-step protocol (read retro, summarize
  completed/pending, list blockers, recommend next action, save, print brief)
- aegis-start.md Step 2 says "Read _aegis-brain/handoffs/ for last session's handoff"
- The _aegis-brain/handoffs/ directory does NOT exist yet
- No sample handoff has ever been written
- Mother Brain's cross-session continuity section references handoffs but lacks
  specific pickup protocol

## Acceptance Criteria
1. _aegis-brain/handoffs/ directory is created (or auto-created by handoff command)
2. aegis-handoff.md includes Mother Brain state in the handoff:
   - Active sprint name and progress (tasks done / total)
   - Kanban state snapshot (how many in each column)
   - Context zone at time of handoff
   - Cycle count and tasks completed this session
3. aegis-start.md Step 2 explicitly reads the LATEST handoff file (sorted by date)
   and passes key data to Mother Brain's spawn prompt
4. Mother Brain's "Cross-session continuity" section is enhanced with a
   specific PICKUP protocol that reads handoff and adjusts Decision Matrix accordingly
5. A sample/template handoff file exists as documentation reference

## Implementation Plan

### A. Enhance aegis-handoff.md -- Add Mother Brain state
Add a "Step 5.5: Capture Mother Brain State" that writes:
- Sprint progress, kanban snapshot, context zone, cycle count
- Last Decision Matrix signal that was being worked on
- Any agents that were active and their tasks

### B. Enhance aegis-start.md -- Explicit handoff loading
In Step 2, add specific instructions to:
- Find the latest file in _aegis-brain/handoffs/ (by filename date sort)
- Parse the handoff frontmatter for machine-readable state
- Pass handoff summary to Mother Brain's spawn prompt

### C. Enhance mother-brain.md -- PICKUP protocol
Add to "Cross-session continuity" section:
- When handoff data is provided, skip full scan for already-known state
- Resume from the recommended first action in the handoff
- Log: "PICKUP from handoff [filename], resuming [action]"

### D. Create handoffs directory + template
- mkdir _aegis-brain/handoffs/
- Create a template showing the expected format

## Out of Scope
- Automatic handoff on context RED (already covered by T-005)
- Changes to the retro command
