#!/usr/bin/env bash
# aegis-doc-canon-lint-test.sh — Sprint v12-01 acceptance + regression test
#
# Verifies tools/aegis-doc-canon/lint.mjs:
#   - exits 0 on the live tree (DoD/ARCH/CLAUDE_* must all carry headers)
#   - exits 0 on a fully-passing fixture
#   - exits 1 when the version header is missing
#   - exits 1 when the Last-updated header is missing
#   - exits 1 when the Changelog section is missing
#   - exits 1 when the Changelog table has 0 data rows
#   - exits 1 when the file is missing entirely
#   - --json output is parseable JSON

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LINT="${REPO_ROOT}/tools/aegis-doc-canon/lint.mjs"

[[ -f "$LINT" ]] || { echo "FATAL: missing $LINT" >&2; exit 2; }
command -v node >/dev/null 2>&1 || { echo "FATAL: node not found" >&2; exit 2; }

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
PASS=0; FAIL=0
pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}FAIL${NC}: $1 -- $2"; FAIL=$((FAIL+1)); }

TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/aegis-doc-canon-XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT INT TERM

echo "================================================="
echo "AEGIS doc-canon lint — sprint v12-01 acceptance"
echo "================================================="

# ─── Fixture builders ──────────────────────────────────────────────────────
write_passing() {
    local path="$1"
    cat > "$path" <<'EOF'
<!-- version: 1.0.0 -->
<!-- Last updated: 2026-05-06 -->

Last reviewed: 2026-05-06

# Sample Doc

> A passing fixture.

## Changelog

| Date | Version | Change |
|------|---------|--------|
| 2026-05-06 | 1.0.0 | Initial. |

## Body

Lorem ipsum.
EOF
}

write_missing_version_header() {
    local path="$1"
    cat > "$path" <<'EOF'
<!-- Last updated: 2026-05-06 -->

# Sample Doc

## Changelog

| Date | Version | Change |
|------|---------|--------|
| 2026-05-06 | 1.0.0 | Initial. |
EOF
}

write_missing_lastupdated() {
    local path="$1"
    cat > "$path" <<'EOF'
<!-- version: 1.0.0 -->

# Sample Doc

## Changelog

| Date | Version | Change |
|------|---------|--------|
| 2026-05-06 | 1.0.0 | Initial. |
EOF
}

write_missing_changelog_section() {
    local path="$1"
    cat > "$path" <<'EOF'
<!-- version: 1.0.0 -->
<!-- Last updated: 2026-05-06 -->

# Sample Doc

## Body

No changelog at all.
EOF
}

write_empty_changelog_table() {
    local path="$1"
    cat > "$path" <<'EOF'
<!-- version: 1.0.0 -->
<!-- Last updated: 2026-05-06 -->

# Sample Doc

## Changelog

| Date | Version | Change |
|------|---------|--------|

## Body

Empty changelog.
EOF
}

# Run the lint with --docs targeting just one file, and capture exit code.
run_lint_one() {
    local dir="$1"
    local doc="$2"
    shift 2
    node "$LINT" --dir "$dir" --docs "$doc" "$@" 2>&1
    return $?
}

# ─── Test 1: live tree passes ──────────────────────────────────────────────
echo
echo "T1: live tree lint (all governance docs)"
OUT=$(node "$LINT" --dir "$REPO_ROOT" 2>&1)
RC=$?
if [[ $RC -eq 0 ]]; then
    pass "live tree lint exits 0"
else
    fail "live tree lint exits 0" "exit=$RC, output:\n$OUT"
fi
# Match any "all <N> governance docs pass" — count grows as governance corpus expands.
if echo "$OUT" | grep -qE "all [0-9]+ governance docs pass"; then
    DOC_COUNT=$(echo "$OUT" | grep -oE "all [0-9]+ governance" | grep -oE "[0-9]+")
    pass "live tree lint reports all $DOC_COUNT pass"
else
    fail "live tree lint reports all governance docs pass" "output did not contain summary"
fi

# ─── Test 2: passing fixture ───────────────────────────────────────────────
echo
echo "T2: passing fixture exits 0"
write_passing "$TEST_DIR/CLAUDE.md"
OUT=$(run_lint_one "$TEST_DIR" "CLAUDE.md")
RC=$?
if [[ $RC -eq 0 ]]; then
    pass "passing fixture exits 0"
else
    fail "passing fixture exits 0" "exit=$RC, output:\n$OUT"
fi

# ─── Test 3: missing version header ────────────────────────────────────────
echo
echo "T3: missing version header exits 1"
write_missing_version_header "$TEST_DIR/CLAUDE.md"
OUT=$(run_lint_one "$TEST_DIR" "CLAUDE.md")
RC=$?
if [[ $RC -eq 1 ]]; then
    pass "missing version header exits 1"
else
    fail "missing version header exits 1" "exit=$RC, output:\n$OUT"
fi
if echo "$OUT" | grep -q "missing <!-- version:"; then
    pass "missing version header reports the right error"
else
    fail "missing version header reports the right error" "output:\n$OUT"
fi

# ─── Test 4: missing Last-updated ──────────────────────────────────────────
echo
echo "T4: missing Last-updated exits 1"
write_missing_lastupdated "$TEST_DIR/CLAUDE.md"
OUT=$(run_lint_one "$TEST_DIR" "CLAUDE.md")
RC=$?
if [[ $RC -eq 1 ]]; then
    pass "missing Last-updated exits 1"
else
    fail "missing Last-updated exits 1" "exit=$RC, output:\n$OUT"
fi
if echo "$OUT" | grep -q "missing <!-- Last updated:"; then
    pass "missing Last-updated reports the right error"
else
    fail "missing Last-updated reports the right error" "output:\n$OUT"
fi

# ─── Test 5: missing Changelog section ─────────────────────────────────────
echo
echo "T5: missing Changelog section exits 1"
write_missing_changelog_section "$TEST_DIR/CLAUDE.md"
OUT=$(run_lint_one "$TEST_DIR" "CLAUDE.md")
RC=$?
if [[ $RC -eq 1 ]]; then
    pass "missing Changelog section exits 1"
else
    fail "missing Changelog section exits 1" "exit=$RC, output:\n$OUT"
fi
if echo "$OUT" | grep -q 'missing "## Changelog" section'; then
    pass "missing Changelog reports the right error"
else
    fail "missing Changelog reports the right error" "output:\n$OUT"
fi

# ─── Test 6: empty Changelog table ─────────────────────────────────────────
echo
echo "T6: empty Changelog table (0 data rows) exits 1"
write_empty_changelog_table "$TEST_DIR/CLAUDE.md"
OUT=$(run_lint_one "$TEST_DIR" "CLAUDE.md")
RC=$?
if [[ $RC -eq 1 ]]; then
    pass "empty Changelog table exits 1"
else
    fail "empty Changelog table exits 1" "exit=$RC, output:\n$OUT"
fi
if echo "$OUT" | grep -q "0 data rows"; then
    pass "empty Changelog reports the right error"
else
    fail "empty Changelog reports the right error" "output:\n$OUT"
fi

# ─── Test 7: missing file ──────────────────────────────────────────────────
echo
echo "T7: missing file exits 1"
rm -f "$TEST_DIR/CLAUDE.md"
OUT=$(run_lint_one "$TEST_DIR" "CLAUDE.md")
RC=$?
if [[ $RC -eq 1 ]]; then
    pass "missing file exits 1"
else
    fail "missing file exits 1" "exit=$RC, output:\n$OUT"
fi
if echo "$OUT" | grep -q "file not found"; then
    pass "missing file reports the right error"
else
    fail "missing file reports the right error" "output:\n$OUT"
fi

# ─── Test 8: --json is valid JSON ──────────────────────────────────────────
echo
echo "T8: --json output is valid JSON"
write_passing "$TEST_DIR/CLAUDE.md"
JSON_OUT=$(run_lint_one "$TEST_DIR" "CLAUDE.md" --json)
RC=$?
if [[ $RC -eq 0 ]]; then
    pass "--json with passing fixture exits 0"
else
    fail "--json with passing fixture exits 0" "exit=$RC, output:\n$JSON_OUT"
fi
if echo "$JSON_OUT" | node -e 'let d="";process.stdin.on("data",c=>d+=c);process.stdin.on("end",()=>{const j=JSON.parse(d); if(!j.ok || j.failed!==0 || j.checked!==1) process.exit(7);})'; then
    pass "--json output parses as JSON with expected shape"
else
    fail "--json output parses as JSON with expected shape" "output:\n$JSON_OUT"
fi

# ─── Test 9: --quiet suppresses pass lines but prints failures ─────────────
echo
echo "T9: --quiet suppresses pass lines"
write_passing "$TEST_DIR/CLAUDE.md"
QUIET_OUT=$(run_lint_one "$TEST_DIR" "CLAUDE.md" --quiet)
RC=$?
if [[ $RC -eq 0 ]] && ! echo "$QUIET_OUT" | grep -q "^✓"; then
    pass "--quiet suppresses pass lines on success"
else
    fail "--quiet suppresses pass lines on success" "exit=$RC, output:\n$QUIET_OUT"
fi

# ─── Test 10: mixed batch (one pass + one fail) ────────────────────────────
echo
echo "T10: mixed batch — one pass + one fail exits 1"
write_passing "$TEST_DIR/CLAUDE.md"
write_missing_version_header "$TEST_DIR/CLAUDE_safety.md"
OUT=$(node "$LINT" --dir "$TEST_DIR" --docs "CLAUDE.md,CLAUDE_safety.md" 2>&1)
RC=$?
if [[ $RC -eq 1 ]]; then
    pass "mixed batch (pass + fail) exits 1"
else
    fail "mixed batch (pass + fail) exits 1" "exit=$RC, output:\n$OUT"
fi
if echo "$OUT" | grep -q "1 governance doc failed lint (1 passed)"; then
    pass "mixed batch summary reports 1 failed / 1 passed"
else
    fail "mixed batch summary reports 1 failed / 1 passed" "output:\n$OUT"
fi

# ─── Summary ───────────────────────────────────────────────────────────────
echo
echo "================================================="
echo -e "Total: ${GREEN}$PASS pass${NC} / ${RED}$FAIL fail${NC}"
echo "================================================="
if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
exit 0
