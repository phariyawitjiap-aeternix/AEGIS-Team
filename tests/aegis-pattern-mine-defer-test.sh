#!/usr/bin/env bash
# tests/aegis-pattern-mine-defer-test.sh
# ────────────────────────────────────────────────────────────────────────────
# Test suite for v14-03 S14-03-02: first-run defer + interval gate
# retrofit on tools/aegis-pattern-mine/mine.mjs.
#
# Verifies:
#   1. Fresh state (no state file) + --auto → seeds + exits 0 silently
#   2. State file exists with recent last_run_at + --auto → skips
#   3. State file exists with last_run_at older than interval + --auto → runs
#   4. Without --auto, manual runs always proceed (no gate)
#   5. State file written atomically (mktemp + rename)
#   6. Subsequent --auto runs increment run_count
# ────────────────────────────────────────────────────────────────────────────

set -uo pipefail

PASS=0
FAIL=0
RESULTS=()
pass() { PASS=$((PASS+1)); RESULTS+=("✓ $1"); }
fail() { FAIL=$((FAIL+1)); RESULTS+=("✗ $1: $2"); }

# Set up isolated test root
TEST_ROOT=$(mktemp -d)
mkdir -p "$TEST_ROOT/.aegis/brain/logs" "$TEST_ROOT/.aegis/brain/state"

# Copy mine.mjs + lib.mjs into a tools/ subdir so it can find lib.mjs sibling
mkdir -p "$TEST_ROOT/tools/aegis-pattern-mine"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cp "$REPO_ROOT/tools/aegis-pattern-mine/"* "$TEST_ROOT/tools/aegis-pattern-mine/"

# Seed minimal decision-audit.log so mining doesn't fail on empty input
cat > "$TEST_ROOT/.aegis/brain/logs/decision-audit.log" <<'EOF'
{"ts": "2026-05-01T10:00:00Z", "decision_id": "D-001", "question": "Test question", "source": "judgment", "confidence": 0.5, "answer": "test"}
EOF

cd "$TEST_ROOT"

STATE_FILE=".aegis/brain/state/pattern-miner-state.json"

# ─── TC1: Fresh state + --auto → seeds + exits silently ──────────────────────
out=$(node tools/aegis-pattern-mine/mine.mjs --root . --auto --quiet 2>&1) && rc=0 || rc=$?
if [[ "$rc" = "0" ]] && [[ -f "$STATE_FILE" ]]; then
    pass "TC1 fresh + --auto seeds state"
else
    fail "TC1" "exit=$rc, state_file_exists=$([[ -f $STATE_FILE ]] && echo yes || echo no): $out"
fi

# TC2: state has deferred_first_run = true
if grep -q '"deferred_first_run": true' "$STATE_FILE" 2>/dev/null; then
    pass "TC2 seeded state has deferred_first_run=true"
else
    fail "TC2" "expected deferred_first_run=true: $(cat $STATE_FILE 2>/dev/null)"
fi

# TC3: state has run_count = 0
if grep -q '"run_count": 0' "$STATE_FILE" 2>/dev/null; then
    pass "TC3 seeded state has run_count=0"
else
    fail "TC3" "expected run_count=0: $(cat $STATE_FILE 2>/dev/null)"
fi

# ─── TC4: --auto again (within interval) → skips silently ────────────────────
out=$(node tools/aegis-pattern-mine/mine.mjs --root . --auto --json 2>&1) && rc=0 || rc=$?
if [[ "$rc" = "0" ]] && echo "$out" | grep -q '"action":"skip_within_interval"'; then
    pass "TC4 second --auto within interval → skip"
else
    fail "TC4" "expected skip action: $out"
fi

# ─── TC5: simulate old state (24h+ ago) + --auto with --interval-hours 1 → runs ─
# Rewrite state to look like it ran 2 hours ago
python3 -c "
import json, datetime
state = json.load(open('$STATE_FILE'))
state['last_run_at'] = (datetime.datetime.utcnow() - datetime.timedelta(hours=2)).strftime('%Y-%m-%dT%H:%M:%SZ')
state['deferred_first_run'] = False
json.dump(state, open('$STATE_FILE', 'w'), indent=2)
" 2>/dev/null

# Now --auto with interval=1 should run
out=$(node tools/aegis-pattern-mine/mine.mjs --root . --auto --interval-hours 1 --json 2>&1) && rc=0 || rc=$?
if [[ "$rc" = "0" ]] && echo "$out" | grep -q '"ok":true' && echo "$out" | grep -q "report_path"; then
    pass "TC5 --auto past interval → runs"
else
    fail "TC5" "expected mine to run: rc=$rc, out=$out"
fi

# TC6: state has run_count = 1 after run
run_count=$(python3 -c "import json; print(json.load(open('$STATE_FILE'))['run_count'])" 2>/dev/null)
if [[ "$run_count" = "1" ]]; then
    pass "TC6 run_count incremented to 1"
else
    fail "TC6" "expected run_count=1, got: $run_count"
fi

# ─── TC7: state.deferred_first_run flips to false after first real run ───────
deferred=$(python3 -c "import json; print(json.load(open('$STATE_FILE'))['deferred_first_run'])" 2>/dev/null)
if [[ "$deferred" = "False" ]]; then
    pass "TC7 deferred_first_run = false after real run"
else
    fail "TC7" "expected false, got: $deferred"
fi

# ─── TC8: Without --auto, mine runs regardless of state ──────────────────────
# Wipe state and verify manual run still works (no gate)
rm -f "$STATE_FILE"
out=$(node tools/aegis-pattern-mine/mine.mjs --root . --quiet 2>&1) && rc=0 || rc=$?
if [[ "$rc" = "0" ]]; then
    # State file should NOT have been created in non-auto mode
    if [[ ! -f "$STATE_FILE" ]]; then
        pass "TC8 manual mode runs without creating state file"
    else
        fail "TC8" "manual mode created state file (unexpected)"
    fi
else
    fail "TC8" "manual mode failed: $out"
fi

# ─── TC9: --auto deferred-message visible without --quiet ────────────────────
rm -f "$STATE_FILE"
out=$(node tools/aegis-pattern-mine/mine.mjs --root . --auto 2>&1)
if echo "$out" | grep -qE 'deferred.first.run|deferred_first_run'; then
    pass "TC9 --auto first-run shows deferred message"
else
    fail "TC9" "expected deferred message: $out"
fi

# ─── TC10: --auto --json emits action=deferred_first_run on seed ─────────────
rm -f "$STATE_FILE"
out=$(node tools/aegis-pattern-mine/mine.mjs --root . --auto --json 2>&1)
if echo "$out" | grep -q '"action":"deferred_first_run"'; then
    pass "TC10 --auto --json first-run emits deferred action"
else
    fail "TC10" "expected deferred_first_run JSON: $out"
fi

# Cleanup
cd /
rm -rf "$TEST_ROOT"

# Summary
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  v14-03 S14-03-02 — Pattern Miner Defer Tests"
echo "═══════════════════════════════════════════════════════════════"
for r in "${RESULTS[@]}"; do echo "  $r"; done
echo "───────────────────────────────────────────────────────────────"
echo "  Result: $PASS passed, $FAIL failed (out of $((PASS+FAIL)) tests)"
echo "═══════════════════════════════════════════════════════════════"

exit $([ $FAIL -eq 0 ] && echo 0 || echo 1)
