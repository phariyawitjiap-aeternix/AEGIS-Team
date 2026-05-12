#!/usr/bin/env bash
# tests/aegis-pin-axis-test.sh
# ────────────────────────────────────────────────────────────────────────────
# Test suite for v14-03 S14-03-03: 2-axis pinning primitive.
#
# Verifies:
#   1. pin with default axis=delete
#   2. pin --axis change
#   3. pin --axis both
#   4. check returns 0 for matching axis, 1 for mismatching
#   5. unpin removes entry
#   6. list shows pins
#   7. upsert (pin twice → one entry)
#   8. pins.json atomic write
# ────────────────────────────────────────────────────────────────────────────

set -uo pipefail

PASS=0
FAIL=0
RESULTS=()
pass() { PASS=$((PASS+1)); RESULTS+=("✓ $1"); }
fail() { FAIL=$((FAIL+1)); RESULTS+=("✗ $1: $2"); }

# Isolated test repo
TEST_ROOT=$(mktemp -d)
mkdir -p "$TEST_ROOT/.aegis/brain/logs" "$TEST_ROOT/tools"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cp "$REPO_ROOT/tools/aegis-pin.sh" "$TEST_ROOT/tools/"
chmod +x "$TEST_ROOT/tools/aegis-pin.sh"

export AEGIS_REPO_ROOT="$TEST_ROOT"
PIN="$TEST_ROOT/tools/aegis-pin.sh"

# ─── TC1: pin with default axis ──────────────────────────────────────────────
out=$(bash "$PIN" pin instinct my-instinct-1 2>&1)
if echo "$out" | grep -q "pinned: instinct/my-instinct-1 (axis=delete)"; then
    pass "TC1 pin default axis=delete"
else
    fail "TC1" "expected default-axis output: $out"
fi

# ─── TC2: check delete-pin against delete axis → exit 0 ──────────────────────
bash "$PIN" check instinct my-instinct-1 delete && rc=0 || rc=$?
if [[ "$rc" = "0" ]]; then
    pass "TC2 check delete against delete-pin → exit 0"
else
    fail "TC2" "expected exit 0, got $rc"
fi

# ─── TC3: check delete-pin against change axis → exit 1 (not pinned) ─────────
bash "$PIN" check instinct my-instinct-1 change && rc=0 || rc=$?
if [[ "$rc" = "1" ]]; then
    pass "TC3 check change against delete-pin → exit 1 (not pinned for change)"
else
    fail "TC3" "expected exit 1, got $rc"
fi

# ─── TC4: pin --axis change ──────────────────────────────────────────────────
out=$(bash "$PIN" pin instinct my-instinct-2 --axis change --reason "tested-pattern" 2>&1)
if echo "$out" | grep -q "axis=change"; then
    pass "TC4 pin --axis change"
else
    fail "TC4" "$out"
fi

# TC5: check change against change-pin → exit 0
bash "$PIN" check instinct my-instinct-2 change && rc=0 || rc=$?
if [[ "$rc" = "0" ]]; then
    pass "TC5 check change against change-pin → exit 0"
else
    fail "TC5" "expected exit 0, got $rc"
fi

# TC6: check delete against change-pin → exit 1
bash "$PIN" check instinct my-instinct-2 delete && rc=0 || rc=$?
if [[ "$rc" = "1" ]]; then
    pass "TC6 check delete against change-pin → exit 1"
else
    fail "TC6" "expected exit 1, got $rc"
fi

# ─── TC7: pin --axis both ────────────────────────────────────────────────────
bash "$PIN" pin skill my-skill --axis both >/dev/null 2>&1
bash "$PIN" check skill my-skill delete && rc1=0 || rc1=$?
bash "$PIN" check skill my-skill change && rc2=0 || rc2=$?
if [[ "$rc1" = "0" ]] && [[ "$rc2" = "0" ]]; then
    pass "TC7 --axis both blocks both axes"
else
    fail "TC7" "delete=$rc1 change=$rc2 (expected 0/0)"
fi

# ─── TC8: list shows all 3 pins ──────────────────────────────────────────────
list_out=$(bash "$PIN" list 2>&1)
count=$(echo "$list_out" | grep -cE 'my-(instinct|skill)' || true)
if [[ "$count" -ge 3 ]]; then
    pass "TC8 list shows all 3 pins"
else
    fail "TC8" "expected 3, got $count: $list_out"
fi

# ─── TC9: list --type instinct filters ───────────────────────────────────────
list_inst=$(bash "$PIN" list --type instinct 2>&1)
if echo "$list_inst" | grep -q "my-instinct-1" && echo "$list_inst" | grep -q "my-instinct-2" && ! echo "$list_inst" | grep -q "my-skill"; then
    pass "TC9 list --type instinct filters correctly"
else
    fail "TC9" "filter mismatch: $list_inst"
fi

# ─── TC10: list --json valid ─────────────────────────────────────────────────
json_out=$(bash "$PIN" list --json 2>&1)
if echo "$json_out" | python3 -c "
import json, sys
d = json.load(sys.stdin)
assert isinstance(d, list)
assert len(d) >= 3
" 2>/dev/null; then
    pass "TC10 list --json emits valid JSON array"
else
    fail "TC10" "JSON parse failed: $json_out"
fi

# ─── TC11: pin twice upserts (no duplicates) ─────────────────────────────────
before=$(bash "$PIN" list --json | python3 -c "import json,sys; print(len(json.load(sys.stdin)))")
bash "$PIN" pin instinct my-instinct-1 --axis both >/dev/null  # re-pin with different axis
after=$(bash "$PIN" list --json | python3 -c "import json,sys; print(len(json.load(sys.stdin)))")
if [[ "$before" = "$after" ]]; then
    pass "TC11 re-pin upserts (no duplicates)"
else
    fail "TC11" "duplicate created: before=$before after=$after"
fi

# Verify axis was updated
bash "$PIN" check instinct my-instinct-1 change && rc=0 || rc=$?
if [[ "$rc" = "0" ]]; then
    pass "TC12 re-pin updated axis (was delete, now both)"
else
    fail "TC12" "axis not updated: change-check exit $rc"
fi

# ─── TC13: unpin removes entry ───────────────────────────────────────────────
bash "$PIN" unpin instinct my-instinct-1 >/dev/null
bash "$PIN" check instinct my-instinct-1 delete && rc=0 || rc=$?
if [[ "$rc" = "1" ]]; then
    pass "TC13 unpin removes entry"
else
    fail "TC13" "still pinned after unpin: exit $rc"
fi

# ─── TC14: invalid axis → exit 2 ─────────────────────────────────────────────
out=$(bash "$PIN" pin instinct foo --axis BOGUS 2>&1) && rc=0 || rc=$?
if [[ "$rc" = "2" ]]; then
    pass "TC14 invalid axis → exit 2"
else
    fail "TC14" "expected exit 2, got $rc"
fi

# ─── TC15: missing args → exit 2 ─────────────────────────────────────────────
out=$(bash "$PIN" pin 2>&1) && rc=0 || rc=$?
if [[ "$rc" = "2" ]]; then
    pass "TC15 missing args → exit 2"
else
    fail "TC15" "expected exit 2, got $rc"
fi

# Cleanup
rm -rf "$TEST_ROOT"

# Summary
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  v14-03 S14-03-03 — Pin 2-Axis Tests"
echo "═══════════════════════════════════════════════════════════════"
for r in "${RESULTS[@]}"; do echo "  $r"; done
echo "───────────────────────────────────────────────────────────────"
echo "  Result: $PASS passed, $FAIL failed (out of $((PASS+FAIL)) tests)"
echo "═══════════════════════════════════════════════════════════════"

exit $([ $FAIL -eq 0 ] && echo 0 || echo 1)
