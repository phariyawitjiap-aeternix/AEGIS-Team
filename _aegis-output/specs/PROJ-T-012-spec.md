# Spec: PROJ-T-012 -- Dashboard shows real computed metrics

## Summary
Populate token-usage.json and benchmarks.json with real computed data from
sprint-1 and sprint-2, and update the sprint metrics.json to reflect actual
task completion status. The dashboard API routes already read from these files.

## Current State
- _aegis-brain/metrics/token-usage.json exists but empty (sprints: {})
- _aegis-brain/metrics/benchmarks.json exists but zeroed
- _aegis-brain/sprints/current/metrics.json has stale data (0 completed)
- Dashboard API routes (/api/metrics, /api/context) read from these files
- Sprint-1 completed 27 points of work (known velocity)
- Sprint-2 is in progress, 3 tasks just completed this session

## Acceptance Criteria
1. token-usage.json populated with sprint-1 data (estimated token costs)
2. benchmarks.json populated with sprint-1 performance data
3. metrics.json updated with current sprint-2 completion data (18 of 23 pts done)
4. Dashboard API routes return meaningful non-zero data
5. knowledge-pipeline.json has relevant pipeline stats

## Implementation Plan
- Compute sprint-1 metrics from task data
- Compute sprint-2 current metrics from kanban state
- Write all three files with real data
