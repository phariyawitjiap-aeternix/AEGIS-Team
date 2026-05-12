#!/usr/bin/env bash
# tests/aegis-goal-test.sh
# ────────────────────────────────────────────────────────────────────────────
# Test suite for v14-04 S14-04-01: Persistent Goals POC.
#
# Verifies:
#   - judge.sh heuristic mode returns yes/no/unclear per signal
#   - judge.sh --mode llm errors with integration guidance (POC stub)
#   - state.sh init creates YAML state file
#   - state.sh tick increments turn_count + appends history
#   - state.sh tick with verdict=yes → status=achieved
#   - state.sh budget exhaustion → status=exhausted
#   - state.sh clear removes file
#   - aegis-goal registered in command registry (16 commands now)
# ────────────────────────────────────────────────────────────────────────────

set -uo pipefail

PASS=0
FAIL=0
RESULTS=()
pass() { PASS=$((PASS+1)); RESULTS+=("✓ $1"); }
fail() { FAIL=$((FAIL+1)); RESULTS+=("✗ $1: $2"); }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

JUDGE="tools/aegis-goal/judge.sh"
STATE="tools/aegis-goal/state.sh"

# ─── judge.sh tests ──────────────────────────────────────────────────────────

# TC1: strong completion signal → yes
out=$(echo "✅ All tests pass. Sprint v14-01 closed 13/13pt." | bash "$JUDGE" --goal "ship sprint v14-01" 2>&1)
if echo "$out" | grep -q '"verdict":"yes"'; then
    pass "TC1 strong-completion → yes"
else
    fail "TC1" "expected yes: $out"
fi

# TC2: explicit work-remaining → no
out=$(echo "Next step: implement S14-04-02. TODO: write measurement doc." | bash "$JUDGE" --goal "ship sprint v14-04" 2>&1)
if echo "$out" | grep -q '"verdict":"no"'; then
    pass "TC2 work-remaining → no"
else
    fail "TC2" "expected no: $out"
fi

# TC3: keyword overlap, no completion → unclear
out=$(echo "Working on the brain index for v14 hermes parity sprint." | bash "$JUDGE" --goal "ship v14 hermes parity" 2>&1)
if echo "$out" | grep -q '"verdict":"unclear"'; then
    pass "TC3 keyword-overlap, no marker → unclear"
else
    fail "TC3" "expected unclear: $out"
fi

# TC4: insufficient signal → unclear
out=$(echo "Lorem ipsum dolor sit amet." | bash "$JUDGE" --goal "complete xyz" 2>&1)
if echo "$out" | grep -q '"verdict":"unclear"'; then
    pass "TC4 insufficient signal → unclear"
else
    fail "TC4" "expected unclear: $out"
fi

# TC5: --mode llm exits 1 with guidance
out=$(echo "test" | bash "$JUDGE" --goal "test" --mode llm 2>&1) && rc=0 || rc=$?
if [[ "$rc" = "1" ]] && echo "$out" | grep -q "NOT wired"; then
    pass "TC5 --mode llm errors with guidance"
else
    fail "TC5" "expected exit 1 with guidance: rc=$rc $out"
fi

# TC6: missing --goal → exit 2
out=$(echo "test" | bash "$JUDGE" 2>&1) && rc=0 || rc=$?
if [[ "$rc" = "2" ]]; then
    pass "TC6 missing --goal → exit 2"
else
    fail "TC6" "expected exit 2, got $rc"
fi

# ─── state.sh tests ──────────────────────────────────────────────────────────

# Use isolated test root
TEST_ROOT=$(mktemp -d)
mkdir -p "$TEST_ROOT/.aegis/brain/state"
export AEGIS_REPO_ROOT="$TEST_ROOT"
SID="test-session-$$"

# TC7: init creates state file
out=$(bash "$STATE" init "$SID" "ship v14-04 sprint" 2>&1)
if [[ -f "$TEST_ROOT/.aegis/brain/state/goal-${SID}.yaml" ]]; then
    pass "TC7 state.sh init creates file"
else
    fail "TC7" "state file not created: $out"
fi

# TC8: load shows status=active + turn_count=0
out=$(bash "$STATE" load "$SID" 2>&1)
if echo "$out" | grep -q "status: active" && echo "$out" | grep -q "turn_count: 0"; then
    pass "TC8 init state has status=active, turn_count=0"
else
    fail "TC8" "$out"
fi

# TC9: tick verdict=no increments turn_count to 1
bash "$STATE" tick "$SID" "no" "still-working" >/dev/null 2>&1
out=$(bash "$STATE" load "$SID" 2>&1)
if echo "$out" | grep -q "turn_count: 1" && echo "$out" | grep -q "status: active"; then
    pass "TC9 tick no → turn_count=1, status=active"
else
    fail "TC9" "$out"
fi

# TC10: tick verdict=yes → status=achieved
bash "$STATE" tick "$SID" "yes" "all-done" >/dev/null 2>&1
out=$(bash "$STATE" load "$SID" 2>&1)
if echo "$out" | grep -q "status: achieved"; then
    pass "TC10 tick yes → status=achieved"
else
    fail "TC10" "$out"
fi

# TC11: set-status paused works
bash "$STATE" set-status "$SID" "paused" >/dev/null 2>&1
out=$(bash "$STATE" load "$SID" 2>&1)
if echo "$out" | grep -q "status: paused"; then
    pass "TC11 set-status paused"
else
    fail "TC11" "$out"
fi

# TC12: clear removes state
bash "$STATE" clear "$SID" >/dev/null 2>&1
if [[ ! -f "$TEST_ROOT/.aegis/brain/state/goal-${SID}.yaml" ]]; then
    pass "TC12 clear removes state"
else
    fail "TC12" "file still present"
fi

# TC13: budget exhaustion test — init + tick 20 times with verdict=no
SID2="test-budget-$$"
bash "$STATE" init "$SID2" "test budget" >/dev/null 2>&1
for i in $(seq 1 20); do
    bash "$STATE" tick "$SID2" "no" "wip-$i" >/dev/null 2>&1
done
out=$(bash "$STATE" load "$SID2" 2>&1)
if echo "$out" | grep -q "status: exhausted"; then
    pass "TC13 turn 20 → status=exhausted"
else
    fail "TC13 budget exhaustion: $out"
fi
bash "$STATE" clear "$SID2" >/dev/null 2>&1

# Cleanup
rm -rf "$TEST_ROOT"

# ─── Registry tests ──────────────────────────────────────────────────────────

# TC14: aegis-goal in registry
list_out=$(node tools/aegis-commands/render-help.mjs list 2>/dev/null)
if echo "$list_out" | grep -q "^aegis-goal$"; then
    pass "TC14 aegis-goal registered in registry"
else
    fail "TC14" "aegis-goal missing from registry"
fi

# Summary
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  v14-04 S14-04-01 — Persistent Goals POC Tests"
echo "═══════════════════════════════════════════════════════════════"
for r in "${RESULTS[@]}"; do echo "  $r"; done
echo "───────────────────────────────────────────────────────────────"
echo "  Result: $PASS passed, $FAIL failed (out of $((PASS+FAIL)) tests)"
echo "═══════════════════════════════════════════════════════════════"

exit $([ $FAIL -eq 0 ] && echo 0 || echo 1)
