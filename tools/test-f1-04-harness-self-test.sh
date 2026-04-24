#!/usr/bin/env bash
# test-f1-04-harness-self-test.sh — Self-test for aegis-test-harness-template.sh
# Uses the template to verify the template itself works.
# Bash 3.2 compatible.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/aegis-test-harness-template.sh"

echo "=== F1-04: Test Harness Template Self-Test ==="
echo ""

# TC-01: assert_eq passes on matching values
assert_eq "a" "a" "TC-01 assert_eq matching values"

# TC-02: assert_eq increments fail counter on mismatch (we capture and verify)
# We need to test that a fail increments the counter without stopping us.
# Save current fail count, call assert_eq with mismatch, check counter went up.
_before=$_AEGIS_TEST_FAIL
# Force a fail via direct FAIL call so we can count cleanly
FAIL "TC-02 intentional fail (counter increment check)"
_after=$_AEGIS_TEST_FAIL
if [[ $_after -eq $(( _before + 1 )) ]]; then
    # Manually increment pass since we proved it works
    PASS "TC-02 FAIL increments fail counter"
else
    FAIL "TC-02 FAIL counter did not increment"
fi

# TC-03: TEST_TMPDIR exists and is a directory
if [[ -d "$TEST_TMPDIR" ]]; then
    PASS "TC-03 TEST_TMPDIR is a directory"
else
    FAIL "TC-03 TEST_TMPDIR missing or not a directory"
fi

# TC-04 / TC-05: test_results exit codes
# We use a sub-shell to test without killing our test run.

# TC-04: test_results exits 0 when all-pass sub-harness
_result_04=0
bash -c "
source '${SCRIPT_DIR}/aegis-test-harness-template.sh'
PASS 'sub-pass'
test_results
" >/dev/null 2>&1 || _result_04=$?
if [[ $_result_04 -eq 0 ]]; then
    PASS "TC-04 test_results exits 0 when all pass"
else
    FAIL "TC-04 test_results exited $_result_04 (expected 0)"
fi

# TC-05: test_results exits 1 when any fail in sub-harness
_result_05=0
bash -c "
source '${SCRIPT_DIR}/aegis-test-harness-template.sh'
PASS 'sub-pass'
FAIL 'sub-fail'
test_results
" >/dev/null 2>&1 || _result_05=$?
if [[ $_result_05 -eq 1 ]]; then
    PASS "TC-05 test_results exits 1 when any fail"
else
    FAIL "TC-05 test_results exited $_result_05 (expected 1)"
fi

# Correct the fail counter: TC-02's intentional FAIL was verified (counter did
# increment), so subtract it so test_results reflects real test outcomes only.
# Without this correction, CI consumers see exit 1 even when all assertions pass.
_AEGIS_TEST_FAIL=$(( _AEGIS_TEST_FAIL - 1 ))

echo ""
echo "Note: TC-02 intentional FAIL was verified and removed from final count."

test_results
