#!/usr/bin/env bash
# tests/aegis-dump-test.sh
# ────────────────────────────────────────────────────────────────────────────
# Test suite for v14-03 S14-03-01: aegis-dump redacted summary.
#
# Verifies:
#   1. Script runs without error
#   2. Default output contains key sections (version/git/counts/brain/keys)
#   3. --json emits valid JSON
#   4. Default mode does NOT leak full key values
#   5. --show-keys reveals last-4 only (not full key)
#   6. Runs in <500ms
# ────────────────────────────────────────────────────────────────────────────

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

DUMP="tools/aegis-dump.sh"
PASS=0
FAIL=0
RESULTS=()
pass() { PASS=$((PASS+1)); RESULTS+=("✓ $1"); }
fail() { FAIL=$((FAIL+1)); RESULTS+=("✗ $1: $2"); }

# TC1: script runs
out=$(bash "$DUMP" 2>&1) && rc=0 || rc=$?
if [[ "$rc" = "0" ]]; then
    pass "TC1 dump runs without error"
else
    fail "TC1" "exit $rc: $out"
fi

# TC2: default output contains required sections
for section in "version:" "git:" "counts:" "brain:" "keys:" "recent_activity:"; do
    if echo "$out" | grep -qF "$section"; then
        pass "TC2 contains '$section'"
    else
        fail "TC2" "missing section: $section"
    fi
done

# TC3: --json emits valid JSON with required shape
json_out=$(bash "$DUMP" --json 2>&1)
if echo "$json_out" | node -e "
const d = JSON.parse(require('fs').readFileSync(0, 'utf-8'));
if (!d.version || !d.counts || !d.brain || !d.keys) {
    console.error('missing required keys');
    process.exit(1);
}
" 2>&1; then
    pass "TC3 --json valid + shape OK"
else
    fail "TC3" "JSON invalid or wrong shape"
fi

# TC4: NO full keys leaked in default output
# Simulate a fake API key in env and assert it doesn't appear verbatim
TEST_KEY="lin_api_FAKE1234567890_DO_NOT_LEAK"
out_with_key=$(LINEAR_API_KEY="$TEST_KEY" bash "$DUMP" 2>&1)
if echo "$out_with_key" | grep -qF "$TEST_KEY"; then
    fail "TC4" "full key leaked in default output"
else
    pass "TC4 default mode does not leak full key"
fi

# TC5: --show-keys reveals last 4 only
out_show=$(LINEAR_API_KEY="$TEST_KEY" bash "$DUMP" --show-keys 2>&1)
# Should contain last 4 chars but not full key
last4="${TEST_KEY: -4}"
if echo "$out_show" | grep -qF "$TEST_KEY"; then
    fail "TC5" "--show-keys leaked FULL key (expected last-4 only)"
elif echo "$out_show" | grep -qF "...${last4}"; then
    pass "TC5 --show-keys shows last-4 only"
else
    fail "TC5" "expected ...${last4} pattern, output: $out_show"
fi

# TC6: runs in <500ms (loose check — 2s ceiling for slow CI)
start=$(date +%s%N 2>/dev/null || python3 -c 'import time; print(int(time.time()*1e9))')
bash "$DUMP" >/dev/null 2>&1
end=$(date +%s%N 2>/dev/null || python3 -c 'import time; print(int(time.time()*1e9))')
elapsed_ms=$(( (end - start) / 1000000 ))
if [[ "$elapsed_ms" -lt 2000 ]]; then
    pass "TC6 runs in ${elapsed_ms}ms (<2000ms target)"
else
    fail "TC6" "took ${elapsed_ms}ms (>2000ms)"
fi

# TC7: --help exits 0
help_out=$(bash "$DUMP" --help 2>&1)
if echo "$help_out" | grep -q "Usage:"; then
    pass "TC7 --help shows usage"
else
    fail "TC7" "help output: $help_out"
fi

# Summary
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  v14-03 S14-03-01 — aegis-dump Tests"
echo "═══════════════════════════════════════════════════════════════"
for r in "${RESULTS[@]}"; do echo "  $r"; done
echo "───────────────────────────────────────────────────────────────"
echo "  Result: $PASS passed, $FAIL failed (out of $((PASS+FAIL)) tests)"
echo "═══════════════════════════════════════════════════════════════"

exit $([ $FAIL -eq 0 ] && echo 0 || echo 1)
