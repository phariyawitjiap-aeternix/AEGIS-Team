#!/usr/bin/env bash
# aegis-brain-search-test.sh — Regression tests for FTS5 hyphen handling
#
# Repro of the original bug:
#   bash tools/aegis-brain-search.sh "ADR-007"
#   → Error: stepping, no such column: 007
#
# FTS5 treats unquoted hyphens as the NOT operator, so the query "ADR-007"
# parses as "ADR NOT 007" and FTS5 then tries to resolve "007" as a column.
# The fix wraps hyphenated identifiers in double quotes (preprocess_fts_query
# in tools/aegis-brain-search.sh).
#
# This test builds a self-contained fixture FTS5 DB and verifies hyphenated
# queries succeed and return the expected rows.

set -uo pipefail
# -e intentionally omitted: tests should continue past individual failures.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SEARCH_SH="${SCRIPT_DIR}/../tools/aegis-brain-search.sh"

if [[ ! -f "$SEARCH_SH" ]]; then
  echo "FATAL: cannot locate aegis-brain-search.sh at $SEARCH_SH" >&2
  exit 2
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

PASS_COUNT=0
FAIL_COUNT=0
pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS_COUNT=$((PASS_COUNT+1)); }
fail() { echo -e "${RED}FAIL${NC}: $1 -- $2"; FAIL_COUNT=$((FAIL_COUNT+1)); }

TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/aegis-brain-search-test-XXXXXX")
FAKE_DB="${TEST_DIR}/index.db"

cleanup() { rm -rf "$TEST_DIR"; }
trap cleanup EXIT INT TERM

echo "============================================"
echo "AEGIS Brain Search -- FTS5 hyphen regression"
echo "Test dir: ${TEST_DIR}"
echo "============================================"

# --- Build fixture DB with the same schema as aegis-brain-index.sh ---
sqlite3 "$FAKE_DB" <<'SQL'
CREATE TABLE entries (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  source_type TEXT NOT NULL,
  source_path TEXT NOT NULL,
  line_no INTEGER DEFAULT 0,
  ts TEXT DEFAULT '',
  content_summary TEXT NOT NULL,
  mtime INTEGER NOT NULL
);
CREATE VIRTUAL TABLE entries_fts USING fts5(
  content_summary, source_type, source_path,
  content=entries, content_rowid=id, tokenize='porter unicode61'
);
CREATE TRIGGER entries_ai AFTER INSERT ON entries BEGIN
  INSERT INTO entries_fts(rowid, content_summary, source_type, source_path)
    VALUES (new.id, new.content_summary, new.source_type, new.source_path);
END;
INSERT INTO entries (source_type, source_path, line_no, ts, content_summary, mtime)
VALUES
  ('sprints',  'fake/sprint-v10-03/plan.md',  1, '2026-05-01', 'Sprint v10-03 plan covers RTK adoption decision.',                  1714521600),
  ('handoffs', 'fake/adr-007-context.md',     1, '2026-04-30', 'Context for ADR-007 maintainer-mode override.',                    1714435200),
  ('learnings','fake/policy-without-test.md', 1, '2026-04-29', 'Policy claims without a matching test are the dominant bug class.', 1714348800),
  ('resonance','fake/no-hyphen-here.md',      1, '2026-04-28', 'Plain content with no hyphenated identifiers.',                    1714262400);
SQL

# --- Build a wrapper that points the real script at our fixture DB ---
WRAPPER="${TEST_DIR}/search-test.sh"
cp "$SEARCH_SH" "$WRAPPER"
# Patch: replace the DB_PATH assignment line so it targets the fixture DB.
sed -i '' "s|^DB_PATH=.*|DB_PATH=\"${FAKE_DB}\"|" "$WRAPPER" \
  || sed -i "s|^DB_PATH=.*|DB_PATH=\"${FAKE_DB}\"|" "$WRAPPER"
chmod +x "$WRAPPER"

# Assert helper: run the wrapper with the given query, check exit + stdout.
# Args: <label> <query> <expected_stdout_substring> [extra_args...]
assert_search_finds() {
  local label="$1" query="$2" needle="$3"; shift 3
  local out err exit_code=0
  out=$(bash "$WRAPPER" "$@" "$query" 2>"${TEST_DIR}/stderr") || exit_code=$?
  err=$(cat "${TEST_DIR}/stderr")
  if [[ $exit_code -ne 0 ]]; then
    fail "$label" "exit=$exit_code stderr=$err"
    return
  fi
  if echo "$out" | grep -qF "$needle"; then
    pass "$label"
  else
    fail "$label" "stdout missing '$needle' (got: $(echo "$out" | head -2 | tr '\n' '|'))"
  fi
}

# Assert helper: run wrapper with the given query and verify it fails clean.
# Used to confirm OUR test wrapper actually exercises the FTS5 path (sanity check).
assert_search_runs_clean() {
  local label="$1" query="$2"; shift 2
  local exit_code=0
  bash "$WRAPPER" "$@" "$query" >/dev/null 2>"${TEST_DIR}/stderr" || exit_code=$?
  if [[ $exit_code -ne 0 ]]; then
    fail "$label" "exit=$exit_code stderr=$(cat "${TEST_DIR}/stderr")"
    return
  fi
  # Check stderr is clean (no FTS5 column-resolution errors leaking)
  if grep -qE "no such column|stepping|fts5: syntax error" "${TEST_DIR}/stderr"; then
    fail "$label" "FTS5 error in stderr: $(cat "${TEST_DIR}/stderr")"
    return
  fi
  pass "$label"
}

echo ""
echo "--- Hyphenated queries (the regression) ---"

# 1. ADR-007 — the canonical failing case from the bug report.
assert_search_finds "ADR-007 query returns matching row" \
  "ADR-007" "adr-007-context.md"

# 2. v10-03 — the second failing case from the bug report.
assert_search_finds "v10-03 query returns matching row" \
  "v10-03" "sprint-v10-03/plan.md"

# 3. Multi-segment hyphens (well-known, foo-bar-baz).
assert_search_finds "multi-segment hyphenated token does not error" \
  "policy-without-test" "policy-without-test.md"

echo ""
echo "--- Non-regression: existing query forms still work ---"

# 4. Non-hyphenated queries are untouched.
assert_search_finds "plain term still works" \
  "RTK" "sprint-v10-03/plan.md"

# 5. Already-quoted queries (the original workaround) still work.
assert_search_finds "already-quoted hyphenated query still works" \
  '"ADR-007"' "adr-007-context.md"

# 6. Mixed query: plain term + hyphenated identifier.
assert_search_finds "mixed plain + hyphenated query" \
  "RTK v10-03" "sprint-v10-03/plan.md"

# 7. Two hyphenated tokens with OR — both must be wrapped independently.
assert_search_finds "two hyphenated tokens with OR" \
  "ADR-007 OR v10-03" "sprint-v10-03/plan.md"

echo ""
echo "--- Stderr cleanliness ---"

# 8. No FTS5 column-resolution errors leak through for any of the above.
assert_search_runs_clean "stderr clean for ADR-007"  "ADR-007"
assert_search_runs_clean "stderr clean for v10-03"   "v10-03"
assert_search_runs_clean "stderr clean for plain"    "RTK"

echo ""
echo "============================================"
echo "RESULTS: ${PASS_COUNT} passed, ${FAIL_COUNT} failed"
echo "============================================"

if [[ $FAIL_COUNT -gt 0 ]]; then
  echo -e "${RED}BRAIN-SEARCH REGRESSION TESTS: FAILURES${NC}"
  exit 1
fi
echo -e "${GREEN}BRAIN-SEARCH REGRESSION TESTS: ALL PASSED${NC}"
exit 0
