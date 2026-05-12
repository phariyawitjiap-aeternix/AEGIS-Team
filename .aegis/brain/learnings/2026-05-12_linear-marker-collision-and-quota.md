# Linear free-plan cap + marker collision — 2026-05-12 session

## Context
Back-filling 35 AEGIS sprints into Linear via /aegis-linear-sync after merging PR #154.

## What broke
1. **Marker collision (v2)**: `aegis-sync:STORY_ID` not unique across sprints — story IDs
   "A/B/C/D" and "AI-1/AI-2" repeat across v11-*, v13-*. 25 of 50 first-pass issues
   ended up in WRONG milestone in Linear because find_issue_by_story matched a stale
   PHA-N from an earlier sprint with the same story_id.
2. **Parser coverage gap**: only the bullet-kanban format was supported. Older sprints
   (1, 2, 3) use table-kanban; v13-* sprints have no kanban.md at all (Stories
   live in plan.md). 30/35 sprints silently parsed to 0 stories.
3. **UPDATE path didn't fix milestone**: orphan / mis-linked issues stayed stuck
   because update fields only refreshed state + description + labels.
4. **Linear free-plan cap (250 issues/workspace)**: after fixing 1-3, back-fill
   created 50/120 stories before Linear started rejecting with USAGE_LIMIT_EXCEEDED.
   Workspace had ghost-counted issues from older deleted ones + 8 unused demo projects.

## Resolution
- PR #155 merged with v3 marker `aegis-sync:SPRINT/STORY v=hash` + 3-tier parser +
  milestone repair on update path.
- 50/50 issues in AEGIS-Team are now correctly linked (verified via marker→milestone
  match: 0 collisions).
- 16 milestones remain empty — BLOCKED by Linear quota, not by code.
- Added human-queue entry for the quota decision (External Access category).

## Lessons learned (for future similar work)
1. **Marker schema must include EVERY axis of uniqueness** that can collide. Story-ID
   alone is not enough when story IDs are local to a sprint. Always: `<scope>/<id>`.
2. **Test deduplication early with cross-sprint collisions** before mass-creating
   resources in external systems. A 5-min collision test would have caught this
   before 50 issues went to wrong places.
3. **Wrap external mass-create in budget-aware loop** — quota limits hit silently
   per-call. Need pre-flight check (workspace remaining-quota query) or fail-fast
   on first USAGE_LIMIT_EXCEEDED.
4. **`fail()` in subshell of `$(...)` doesn't exit parent** — must return JSON
   error sentinel and check on the caller side.
5. **One-way mirror with idempotency requires content hash** — Linear normalizes
   markdown, so direct string-diff false-positives. SHA1 over canonical source
   fields is stable across renderer changes.

## Files touched
- tools/aegis-linear-sync.sh (parser + marker + UPDATE path)
- tools/aegis-linear-bootstrap.sh (fresh-repo init — earlier in session)
- .aegis/brain/func-catalog.json (regen after new helpers)
- install.sh (command count bump 13→14)

## Closing state
- AEGIS-Team Linear project: 50 issues, 19/35 milestones filled, all correctly linked
- 16 sprints awaiting external quota decision (in human-queue.md)
- main has both PR #154 + #155 merged, all tests green
