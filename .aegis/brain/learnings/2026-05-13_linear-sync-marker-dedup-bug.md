<!-- version: 1.0.0 -->
<!-- Last updated: 2026-05-13 -->

# Linear sync — marker-dedup bug still present after v3 fix

## Symptom

Re-running `bash tools/aegis-linear-sync.sh open <sprint>` against AEGIS-Team
creates duplicate issues for stories that already exist in Linear. Story
IDs `A`, `B`, `C`, `D` ended up with 18, 18, 15, 10 copies each in the
project after multiple back-fill attempts on 2026-05-13.

## What was supposed to fix it (PR #155)

Marker schema v3 (`<!-- aegis-sync:SPRINT_ID/STORY_ID v=hash -->`) scoped
the marker per-sprint. `find_issue_by_story` was updated to take a
`sprint_id` argument and match the scoped regex.

## What's still wrong

Hypothesis A — old v2-format markers survived the 69-issue wipe and the
12-project demo cleanup. New code with the v3-fallback removed won't match
v2 markers, so it creates a duplicate.

Hypothesis B — the regex passed to `jq | test()` is failing on certain
sprint IDs (e.g. ones containing characters that need escaping). The
character class `[ -]` after the story ID seemed safe, but `/` in the
sprint_id might interact with jq's regex compiler.

Hypothesis C — pagination: `find_issue_by_story` queries `project { issues
{ nodes ... } }` which Linear may paginate at 50 nodes. If a true match
sits past the cursor, find returns nothing → false negative → create.

## Next-session repro plan

1. Wipe AEGIS-Team again (95+ issues) to a clean slate
2. Run sync against ONE sprint twice in a row
3. Verify second run reports `skipped=N` not `created=N`
4. If duplicate created, inspect the existing issue's marker via API,
   confirm v3 format, then debug `find_issue_by_story` regex compilation
   with that exact marker as input

## Why this matters

Without dedup, every run of /aegis-sprint plan or the kanban-write hook
will accrete duplicates in Linear over time. The current AEGIS install
keeps quota under control because the bug is rate-limited by the user's
manual sync invocations. The hook-driven sync on kanban writes would have
caused a runaway.

## Resolution (2026-05-13)

**Root cause: Hypothesis C confirmed (pagination).**

The GraphQL query in `find_issue_by_story` / `find_issue_by_story_with_labels`
did not specify a `first:` argument, so Linear defaulted to 50 nodes. With 94
issues in the project, 44 were invisible to the marker search, causing false
negatives and duplicate creates on every re-sync after the 50-issue threshold.

**Secondary bug found:** The v2-fallback regex (`$old`) was passed into jq but
never referenced in the filter expression -- dead code since the v3 migration.

**Fix (PR #xxx):**
1. Extracted `_fetch_all_project_issues()` with cursor-based pagination
   (`first:250`, loop on `hasNextPage`), 10-page safety cap (2500 issues max).
2. Both `find_issue_by_story` and `find_issue_by_story_with_labels` now delegate
   to the paginated fetcher instead of doing direct `gql()` calls.
3. Fixed the v2-fallback dead code: jq filter now uses `. as $all` binding so
   the fallback branch re-scans the original array, not the empty v3 result.
4. Added per-run cache (`/tmp/aegis-linear-issues.$$`) so multiple
   `find_issue_by_story` calls within one sync don't re-fetch all issues.
5. 12 regression tests in `tests/aegis-linear-sync-dedup-test.sh`.

**Hypotheses A and B were NOT contributing factors:**
- A (v2 markers): All 94 issues have valid v3 markers. No v2 survivors.
- B (regex compile): jq `test()` handles sprint IDs with hyphens correctly.

## Provenance

- Found during 2026-05-13 cleanup session, after user authorized demo deletion
- Cleanup itself succeeded (12 projects deleted, quota partially recovered)
- Back-fill attempt surfaced the bug; not fixed in this session to avoid
  consuming more quota fighting the bug
- Fixed in follow-up session same day (fix/linear-sync-dedup-pagination branch)
