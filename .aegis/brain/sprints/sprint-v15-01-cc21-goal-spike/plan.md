# Sprint v15-01 — CC 2.1 `/goal` adoption spike

**Goal**: Decide whether AEGIS should migrate Nick Fury's heartbeat-loop pattern to Claude Code 2.1.139's native `/goal` command, keep both, or stay with Nick Fury.
**Source**: User question 2026-05-13 after CC 2.1.139 release announcement
**Capacity**: 2pt (single-session spike, half-day)
**Status**: OPEN

## Stories

| ID | Story | Pt | Owner | PR |
|----|-------|-----|-------|-----|
| SK-1 | Build /goal vs Nick-Fury capability matrix | 1 | iron-man | (in flight) |
| SK-2 | Write decision.md with hybrid migration plan if applicable | 1 | iron-man | (in flight) |

## Acceptance Criteria

- [ ] `decision.md` in this sprint dir
- [ ] Recommendation is one of: KEEP (Nick Fury wins) / REPLACE (/goal wins) / HYBRID (split responsibilities)
- [ ] If non-KEEP: migration plan with estimated point cost
- [ ] Re-evaluation trigger documented (when to revisit decision)

## Non-goals

- No code changes this sprint
- No CC 2.1.139 install assumption (we may already be on it; decision doc covers both cases)
- No Phase B/C/D from the release impact analysis — those are downstream sprints conditional on this decision
