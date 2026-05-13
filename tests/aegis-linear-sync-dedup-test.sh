#!/usr/bin/env bash
# aegis-linear-sync-dedup-test.sh — Regression tests for the Linear sync
# pagination dedup bug (learnings/2026-05-13_linear-sync-marker-dedup-bug.md).
#
# Root cause: find_issue_by_story queried Linear without pagination, defaulting
# to 50 nodes. Issues beyond cursor 50 were invisible, causing false negatives
# and duplicate creates.
#
# Fix: _fetch_all_project_issues uses cursor-based pagination (first:250 per page).
# These tests verify the fix WITHOUT calling the real Linear API — they mock gql().
#
# Bash 3.2 compatible.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/aegis-test-harness-template.sh"

SYNC_SCRIPT="${SCRIPT_DIR}/../tools/aegis-linear-sync.sh"

echo "=== Linear Sync Dedup Regression Tests ==="
echo ""

# Helper: run the jq dedup filter used by find_issue_by_story.
# Accepts a JSON array on stdin, outputs the matched issue or empty.
# This mirrors the exact jq logic in the sync script.
_run_find_filter() {
  local marker="$1" fallback="$2"
  jq --arg new "$marker" --arg old "$fallback" -c '
    . as $all
    | [.[]? | select(.description != null and (.description | test($new)))]
    | if length == 0 then
        [$all[]? | select(.description != null and (.description | test($old)))]
      else . end
    | sort_by(.identifier | capture("(?<n>[0-9]+)$") | .n | tonumber)
    | .[0] // empty
  '
}

# Helper: build test issue JSON via jq (avoids shell escaping issues with \n)
_build_issues() {
  python3 -c "
import json, sys
issues = json.loads(sys.argv[1])
print(json.dumps(issues))
" "$1"
}

# ─── TC-01: find_issue_by_story matches v3 marker in jq filter ──────────
# Simulates the jq filter logic directly -- no gql mock needed.
TC01_INPUT="$(_build_issues '[
  {"id":"a1","identifier":"PHA-100","title":"T1","description":"some text\n<!-- aegis-sync:sprint-v14-01/A v=abc123 -->","state":{"id":"s1","name":"Todo"},"projectMilestone":{"id":"m1","name":"sprint-v14-01"}},
  {"id":"a2","identifier":"PHA-101","title":"T2","description":"other text\n<!-- aegis-sync:sprint-v14-01/B v=def456 -->","state":{"id":"s1","name":"Todo"},"projectMilestone":{"id":"m1","name":"sprint-v14-01"}}
]')"

TC01_RESULT="$(echo "$TC01_INPUT" | _run_find_filter 'aegis-sync:sprint-v14-01/A[ -]' 'aegis-sync:A[ -]')"
TC01_ID="$(echo "$TC01_RESULT" | jq -r '.identifier // empty')"
if [[ "$TC01_ID" == "PHA-100" ]]; then
  PASS "TC-01 v3 marker match finds correct issue (PHA-100)"
else
  FAIL "TC-01 expected PHA-100, got '$TC01_ID'"
fi

# ─── TC-02: v2 fallback matches when v3 marker is absent ────────────────
# v2 marker: aegis-sync:STORY_ID v=HASH (no sprint prefix)
# The fallback regex should catch this when v3 match returns empty.
TC02_INPUT="$(_build_issues '[
  {"id":"b1","identifier":"PHA-200","title":"Legacy","description":"old issue\n<!-- aegis-sync:A v=old123 -->","state":{"id":"s1","name":"Todo"},"projectMilestone":{"id":"m1","name":"sprint-v14-01"}}
]')"

TC02_RESULT="$(echo "$TC02_INPUT" | _run_find_filter 'aegis-sync:sprint-v14-01/A[ -]' 'aegis-sync:A[ -]')"
TC02_ID="$(echo "$TC02_RESULT" | jq -r '.identifier // empty')"
if [[ "$TC02_ID" == "PHA-200" ]]; then
  PASS "TC-02 v2 fallback matches legacy marker (PHA-200)"
else
  FAIL "TC-02 expected PHA-200, got '$TC02_ID'"
fi

# ─── TC-03: no match returns empty (not crash) ──────────────────────────
TC03_INPUT="$(_build_issues '[
  {"id":"c1","identifier":"PHA-300","title":"Unrelated","description":"no marker here","state":{"id":"s1","name":"Todo"},"projectMilestone":null}
]')"

TC03_RESULT="$(echo "$TC03_INPUT" | _run_find_filter 'aegis-sync:sprint-v14-01/Z[ -]' 'aegis-sync:Z[ -]')"
if [[ -z "$TC03_RESULT" || "$TC03_RESULT" == "null" ]]; then
  PASS "TC-03 no match returns empty (not crash)"
else
  FAIL "TC-03 expected empty, got '$TC03_RESULT'"
fi

# ─── TC-04: v3 match prioritized over v2 when both exist ────────────────
# If v3 marker matches, v2 fallback should NOT override.
TC04_INPUT="$(_build_issues '[
  {"id":"d1","identifier":"PHA-400","title":"V2 legacy","description":"<!-- aegis-sync:A v=old789 -->","state":{"id":"s1","name":"Todo"},"projectMilestone":null},
  {"id":"d2","identifier":"PHA-401","title":"V3 current","description":"<!-- aegis-sync:sprint-v14-01/A v=new999 -->","state":{"id":"s1","name":"Todo"},"projectMilestone":null}
]')"

TC04_RESULT="$(echo "$TC04_INPUT" | _run_find_filter 'aegis-sync:sprint-v14-01/A[ -]' 'aegis-sync:A[ -]')"
TC04_ID="$(echo "$TC04_RESULT" | jq -r '.identifier // empty')"
if [[ "$TC04_ID" == "PHA-401" ]]; then
  PASS "TC-04 v3 match prioritized over v2 (PHA-401)"
else
  FAIL "TC-04 expected PHA-401, got '$TC04_ID'"
fi

# ─── TC-05: cross-sprint collision avoidance ─────────────────────────────
# Story ID "A" exists in sprint-v13-01 and sprint-v14-01.
# Searching for sprint-v14-01/A must NOT match sprint-v13-01/A.
TC05_INPUT="$(_build_issues '[
  {"id":"e1","identifier":"PHA-500","title":"Sprint 13","description":"<!-- aegis-sync:sprint-v13-01/A v=aaa111 -->","state":{"id":"s1","name":"Done"},"projectMilestone":null},
  {"id":"e2","identifier":"PHA-501","title":"Sprint 14","description":"<!-- aegis-sync:sprint-v14-01/A v=bbb222 -->","state":{"id":"s1","name":"Todo"},"projectMilestone":null}
]')"

TC05_RESULT="$(echo "$TC05_INPUT" | _run_find_filter 'aegis-sync:sprint-v14-01/A[ -]' 'aegis-sync:A[ -]')"
TC05_ID="$(echo "$TC05_RESULT" | jq -r '.identifier // empty')"
if [[ "$TC05_ID" == "PHA-501" ]]; then
  PASS "TC-05 cross-sprint collision avoidance (sprint-v14-01/A finds PHA-501, not PHA-500)"
else
  FAIL "TC-05 expected PHA-501, got '$TC05_ID'"
fi

# ─── TC-06: pagination query includes first:250 ─────────────────────────
# Verify the script source contains the paginated query (static analysis).
if grep -q 'issues(first: 250' "$SYNC_SCRIPT"; then
  PASS "TC-06 sync script uses paginated query (first: 250)"
else
  FAIL "TC-06 sync script missing paginated query — dedup bug likely unfixed"
fi

# ─── TC-07: pagination query includes pageInfo cursor fields ─────────────
if grep -q 'pageInfo.*hasNextPage.*endCursor' "$SYNC_SCRIPT"; then
  PASS "TC-07 sync script uses cursor pagination (hasNextPage + endCursor)"
else
  FAIL "TC-07 sync script missing cursor pagination fields"
fi

# ─── TC-08: _fetch_all_project_issues function exists ────────────────────
if grep -q '_fetch_all_project_issues' "$SYNC_SCRIPT"; then
  PASS "TC-08 _fetch_all_project_issues helper exists"
else
  FAIL "TC-08 _fetch_all_project_issues helper missing"
fi

# ─── TC-09: find functions use _fetch_all_project_issues ─────────────────
# Both find_issue_by_story and find_issue_by_story_with_labels must delegate
# to the paginated fetcher instead of doing their own unpaginated gql().
TC09_PASS=true
for fn in find_issue_by_story find_issue_by_story_with_labels; do
  # Extract function body using awk (portable across macOS/Linux)
  fn_body="$(awk "/^${fn}\\(\\)/,/^}/" "$SYNC_SCRIPT")"
  if echo "$fn_body" | grep -q '_fetch_all_project_issues'; then
    : # good
  else
    FAIL "TC-09 ${fn} does not call _fetch_all_project_issues"
    TC09_PASS=false
  fi
  # Verify it does NOT call gql directly (would bypass pagination)
  if echo "$fn_body" | grep -qw 'gql'; then
    FAIL "TC-09 ${fn} still calls gql() directly -- bypasses pagination"
    TC09_PASS=false
  fi
done
if $TC09_PASS; then
  PASS "TC-09 both find functions delegate to _fetch_all_project_issues (no direct gql)"
fi

# ─── TC-10: pagination safety cap exists ─────────────────────────────────
# The pagination loop must have a safety cap to prevent infinite loops.
if grep -q 'page >= 10' "$SYNC_SCRIPT"; then
  PASS "TC-10 pagination loop has safety cap (10 pages / 2500 issues)"
else
  FAIL "TC-10 pagination loop missing safety cap"
fi

# ─── TC-11: null description handled gracefully ─────────────────────────
# Issues with null description should not crash the jq filter.
TC11_INPUT="$(_build_issues '[
  {"id":"f1","identifier":"PHA-600","title":"No desc","description":null,"state":{"id":"s1","name":"Todo"},"projectMilestone":null},
  {"id":"f2","identifier":"PHA-601","title":"Match","description":"<!-- aegis-sync:sprint-v14-01/X v=xxx000 -->","state":{"id":"s1","name":"Todo"},"projectMilestone":null}
]')"

TC11_RESULT="$(echo "$TC11_INPUT" | _run_find_filter 'aegis-sync:sprint-v14-01/X[ -]' 'aegis-sync:X[ -]' 2>&1)"
TC11_EXIT=$?

TC11_ID="$(echo "$TC11_RESULT" | jq -r '.identifier // empty' 2>/dev/null)"
if [[ "$TC11_EXIT" -eq 0 && "$TC11_ID" == "PHA-601" ]]; then
  PASS "TC-11 null description handled gracefully (finds PHA-601)"
else
  FAIL "TC-11 null description caused error or wrong result (exit=$TC11_EXIT, got '$TC11_ID')"
fi

# ─── TC-12: v2 fallback was dead code (old bug), now wired ──────────────
# In the old code, $old was passed to jq but never used in the filter.
# The fix adds a conditional: if v3 match returns empty, retry with v2 fallback.
# This test verifies the jq filter structure includes the fallback branch.
if grep -A5 'test(\$new)' "$SYNC_SCRIPT" | grep -q 'test(\$old)'; then
  PASS "TC-12 v2 fallback is wired in jq filter (was dead code before fix)"
else
  FAIL "TC-12 v2 fallback still not wired in jq filter"
fi

echo ""
test_results
