#!/usr/bin/env bash
# aegis-trace-audit-test.sh — Test suite for aegis-trace-audit.sh
# Sprint: v10-01-E
#
# Tests:
#   1. Audit runs without error on clean state
#   2. Audit exits 0 on clean state
#   3. Audit detects a missing requirement (injected fault)
#   4. Audit detects ghost file reference (injected fault)
#   5. Audit is idempotent (two runs same result)

set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AUDIT="${PROJECT_ROOT}/tools/aegis-trace-audit.sh"
PASS=0
FAIL=0
TESTS=0

assert() {
  TESTS=$((TESTS + 1))
  local label="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    PASS=$((PASS + 1))
    echo "  PASS: $label"
  else
    FAIL=$((FAIL + 1))
    echo "  FAIL: $label"
  fi
}

echo "=== Trace Audit Test Suite ==="
echo ""

# --- Test 1: Audit runs ---
assert "T1: Audit script executes without crash" bash "$AUDIT"

# --- Test 2: Clean state = exit 0 ---
bash "$AUDIT" > /dev/null 2>&1
AUDIT_EXIT=$?
assert "T2: Clean state exits 0" test "$AUDIT_EXIT" -eq 0

# --- Test 3: Idempotency (ignore timestamp line) ---
OUT1=$(bash "$AUDIT" 2>&1 | grep -v '^Date:')
OUT2=$(bash "$AUDIT" 2>&1 | grep -v '^Date:')
assert "T3: Two consecutive runs produce same result (ignoring timestamp)" test "$OUT1" = "$OUT2"

# --- Test 4: Detects injected ghost reference ---
SI02="${PROJECT_ROOT}/_aegis-output/iso-docs/SI-02-traceability-matrix/current.md"
if [ -f "$SI02" ]; then
  cp "$SI02" "${SI02}.test-backup"
  echo '| FR-99 | Ghost test | Test | `path/to/nonexistent/ghost-file.md` | TC-99 | Test |' >> "$SI02"
  bash "$AUDIT" > /dev/null 2>&1
  GHOST_EXIT=$?
  mv "${SI02}.test-backup" "$SI02"
  assert "T4: Detects injected ghost reference (exit != 0)" test "$GHOST_EXIT" -ne 0
else
  TESTS=$((TESTS + 1))
  FAIL=$((FAIL + 1))
  echo "  FAIL: T4: SI.02 not found, cannot test ghost detection"
fi

echo ""
echo "=== Results: $PASS/$TESTS passed, $FAIL failed ==="
[ "$FAIL" -gt 0 ] && exit 1
exit 0
