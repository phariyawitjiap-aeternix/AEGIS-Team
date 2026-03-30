# Spec: PROJ-T-005 -- Multi-cycle within session (context budget aware)

## Summary
Mother Brain must track context usage percentage and run multiple SCAN->EXECUTE
cycles within a single session, distilling at 60% and wrapping at 80%. This makes
Mother Brain context-aware so she can maximize throughput per session without
hitting context limits.

## Current State
- mother-brain.md already describes the heartbeat loop with BUDGET step (step 8)
- aegis-context command exists but is a display-only tool (shows usage to human)
- No mechanism for Mother Brain to programmatically track context between cycles
- No distillation trigger or wrap-up protocol tied to context thresholds

## Acceptance Criteria
1. Mother Brain's heartbeat loop includes a concrete context budget check after
   each task completes (not just a description -- actionable protocol)
2. Context thresholds are defined with specific actions:
   - < 40%: full autonomy, read files freely, spawn agents without concern
   - 40-60%: moderate caution, prefer targeted reads, limit agent count
   - 60-80%: distill context (run /aegis-distill or equivalent), one more small task max
   - > 80%: STOP, write handoff, suggest /aegis-start next session
3. Context estimation heuristic is documented (token estimation approach)
4. Multi-cycle counter tracks how many SCAN->EXECUTE cycles ran in this session
5. Each cycle logs context estimate to activity.log
6. The /aegis-context command is enhanced to support Mother Brain's programmatic needs
   (not just human-facing display)

## Implementation Plan

### A. Enhance mother-brain.md -- Context Budget Protocol
Add a new section "Context Budget Protocol" with:
- Token estimation heuristic (conversation turns * ~2000 tokens + files read * ~1500)
- Threshold-based action table
- Cycle counter tracking
- Distillation trigger at 60%
- Hard stop at 80%

### B. Enhance mother-brain.md -- Multi-Cycle Tracking
Add to the heartbeat loop:
- Session cycle counter (increments after each VERIFY step)
- Per-cycle logging format: cycle_number, context_estimate, tasks_completed
- Decision to continue/distill/stop based on budget

### C. Enhance aegis-context.md -- Programmatic Mode
Add a "Mother Brain Integration" section that documents:
- How Mother Brain estimates context without running the full display
- Quick-check protocol (lightweight, no visual output)
- Return format for programmatic consumption

### D. Update aegis-distill.md reference
Ensure /aegis-distill exists or document the distillation protocol:
- Summarize conversation history
- Drop large file contents from context
- Compact agent communication logs
- Equivalent to running /compact with AEGIS awareness

## Out of Scope
- Actual token counting API (not available in Claude Code)
- Modifying Claude Code runtime behavior
- Changes to the Agent tool itself

## Havoc Finding Reference
H-005: Multi-cycle tracking not implemented
H-011: Context budget thresholds described but not actionable
