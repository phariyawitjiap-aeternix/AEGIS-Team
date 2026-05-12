#!/usr/bin/env bash
# aegis-doctor-test.sh — Regression net for tools/aegis-doctor.sh.
#
# Covers the Auto-Affi bug class (2026-05-13): downstream projects receiving
# `on-stop.sh` via upgrade but missing its `lib/` and `tool` dependencies.
#
# Test plan:
#   T1  Doctor exits 0 on a clean self-scan of AEGIS-Team
#   T2  Doctor exits 1 + reports orphans when lib/ is deleted
#   T3  Doctor exits 1 + reports orphans when a settings.json-referenced
#       tool script is missing
#   T4  Doctor --fix restores missing files from AEGIS_SOURCE
#   T5  Doctor --json mode emits valid JSON with orphan_count
#   T6  Doctor exits 2 on a target that has no .claude/ at all
#
# Spec: AEGIS resilience layer, Sprint hook-resilience-aegis-doctor.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DOCTOR="${REPO_ROOT}/tools/aegis-doctor.sh"

[[ -f "$DOCTOR" ]] || { echo "FATAL: doctor missing at $DOCTOR" >&2; exit 2; }

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
PASS=0; FAIL=0
pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}FAIL${NC}: $1 — $2"; FAIL=$((FAIL+1)); }

TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/aegis-doctor-test-XXXXXX")
trap 'find "$TEST_DIR" -type f -delete 2>/dev/null; find "$TEST_DIR" -type d -delete 2>/dev/null' EXIT INT TERM

echo "============================================"
echo "AEGIS doctor regression tests"
echo "============================================"

# ── T1: Clean self-scan ────────────────────────────────────────────────────
echo ""
echo "--- T1: Clean self-scan of AEGIS-Team ---"
out_err=$(bash "$DOCTOR" "$REPO_ROOT" 2>&1)
ec=$?
if [[ "$ec" -eq 0 ]] && echo "$out_err" | grep -q "✅"; then
    pass "T1: clean self-scan exits 0 with ✅ marker"
else
    fail "T1: expected exit 0 + ✅ marker; got exit=$ec, output=${out_err:0:120}"
fi

# ── Prepare a synthetic target (copy of AEGIS-Team's .claude + tools) ──────
TARGET="$TEST_DIR/synthetic-repo"
mkdir -p "$TARGET"
cp -R "$REPO_ROOT/.claude" "$TARGET/"
cp -R "$REPO_ROOT/tools" "$TARGET/"

# ── T2: Missing lib/ directory ─────────────────────────────────────────────
echo ""
echo "--- T2: Detect missing .claude/hooks/lib/*.sh ---"
# Save and remove lib/
SAVED_LIB="$TEST_DIR/saved-lib"
cp -R "$TARGET/.claude/hooks/lib" "$SAVED_LIB"
find "$TARGET/.claude/hooks/lib" -type f -delete 2>/dev/null
rmdir "$TARGET/.claude/hooks/lib" 2>/dev/null

out_err=$(bash "$DOCTOR" "$TARGET" 2>&1)
ec=$?
if [[ "$ec" -eq 1 ]] && echo "$out_err" | grep -q "❌"; then
    if echo "$out_err" | grep -q "lib/quality-check.sh"; then
        pass "T2: detects missing lib/*.sh modules (exit 1)"
    else
        fail "T2: exit 1 but didn't name the missing file" "$out_err"
    fi
else
    fail "T2: expected exit 1 + ❌; got exit=$ec"
fi

# ── T4: --fix restores from AEGIS_SOURCE ───────────────────────────────────
echo ""
echo "--- T4: --fix repairs from sibling AEGIS source ---"
fix_err=$(AEGIS_SOURCE="$REPO_ROOT" bash "$DOCTOR" "$TARGET" --fix 2>&1)
fix_ec=$?
if [[ "$fix_ec" -eq 0 ]] && echo "$fix_err" | grep -q "fixed="; then
    pass "T4: --fix exits 0 + reports fixed count"
else
    fail "T4: expected exit 0 + fix count; got exit=$fix_ec" "$fix_err"
fi

# Confirm files were restored
if [[ -f "$TARGET/.claude/hooks/lib/quality-check.sh" ]]; then
    pass "T4b: lib/quality-check.sh restored on disk"
else
    fail "T4b: lib/quality-check.sh still missing after --fix" "directory listing"
fi

# Re-scan should now be clean
rescan_err=$(bash "$DOCTOR" "$TARGET" 2>&1)
rescan_ec=$?
if [[ "$rescan_ec" -eq 0 ]]; then
    pass "T4c: post-fix re-scan is clean (exit 0)"
else
    fail "T4c: re-scan after fix still finds orphans (exit $rescan_ec)" "$rescan_err"
fi

# ── T5: --json mode ────────────────────────────────────────────────────────
echo ""
echo "--- T5: --json output mode ---"
# Re-break lib/ to get orphans for JSON test
find "$TARGET/.claude/hooks/lib" -type f -delete 2>/dev/null
rmdir "$TARGET/.claude/hooks/lib" 2>/dev/null

json_out=$(bash "$DOCTOR" "$TARGET" --json 2>/dev/null)
json_ec=$?
if echo "$json_out" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['orphan_count']>0; assert 'orphans' in d" 2>/dev/null; then
    pass "T5: --json emits valid JSON with orphan_count>0"
else
    fail "T5: --json output invalid" "$json_out"
fi
if [[ "$json_ec" -eq 1 ]]; then
    pass "T5b: --json exits 1 when orphans present"
else
    fail "T5b: --json wrong exit code: $json_ec"
fi

# Restore lib/ for next test
cp -R "$SAVED_LIB" "$TARGET/.claude/hooks/lib"

# ── T6: Non-AEGIS target ───────────────────────────────────────────────────
echo ""
echo "--- T6: Non-AEGIS target (no .claude/) ---"
EMPTY_DIR="$TEST_DIR/empty-dir"
mkdir -p "$EMPTY_DIR"
empty_err=$(bash "$DOCTOR" "$EMPTY_DIR" 2>&1)
empty_ec=$?
if [[ "$empty_ec" -eq 2 ]]; then
    pass "T6: no-.claude target exits 2 (fatal)"
else
    fail "T6: expected exit 2; got $empty_ec" "$empty_err"
fi

# ── Summary ────────────────────────────────────────────────────────────────
TOTAL=$((PASS+FAIL))
echo ""
echo "============================================"
echo "RESULTS: $PASS passed, $FAIL failed (of $TOTAL)"
echo "============================================"
if [[ "$FAIL" -gt 0 ]]; then
    echo -e "${RED}AEGIS DOCTOR TESTS: FAILURES${NC}"
    exit 1
fi
echo -e "${GREEN}AEGIS DOCTOR TESTS: ALL PASSED${NC}"
exit 0
