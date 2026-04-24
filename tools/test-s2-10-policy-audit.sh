#!/usr/bin/env bash
# test-s2-10-policy-audit.sh -- Test harness for aegis-policy-audit.sh
# Bash 3.2 compatible.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/aegis-test-harness-template.sh"

echo "=== S2-10: Policy-Without-Test Audit Tool ==="
echo ""

# TC-01: Tool exists and is executable
assert_file_exists "$SCRIPT_DIR/aegis-policy-audit.sh" "TC-01 aegis-policy-audit.sh exists"

# TC-02: --help exits 0 and prints usage
_help_exit=0
bash "$SCRIPT_DIR/aegis-policy-audit.sh" --help >/dev/null 2>&1 || _help_exit=$?
assert_eq "$_help_exit" "0" "TC-02 --help exits 0"

# TC-03: Bad argument exits 2
_bad_exit=0
bash "$SCRIPT_DIR/aegis-policy-audit.sh" --nonexistent >/dev/null 2>&1 || _bad_exit=$?
assert_eq "$_bad_exit" "2" "TC-03 unknown arg exits 2"

# TC-04: Default run produces claim count output
_output=$(bash "$SCRIPT_DIR/aegis-policy-audit.sh" 2>/dev/null || true)
if echo "$_output" | grep -q "Claims scanned:"; then
    PASS "TC-04 default output contains Claims scanned"
else
    FAIL "TC-04 default output missing Claims scanned header"
fi

# TC-05: --json mode produces valid JSON with required keys
_json_output=$(bash "$SCRIPT_DIR/aegis-policy-audit.sh" --json 2>/dev/null || true)
if echo "$_json_output" | python3 -c "import json,sys; d=json.load(sys.stdin); assert 'total_claims' in d and 'matched' in d and 'unmatched' in d and 'coverage_pct' in d" 2>/dev/null; then
    PASS "TC-05 --json output is valid JSON with required keys"
else
    FAIL "TC-05 --json output invalid or missing keys"
fi

# TC-06: --verbose mode shows unmatched details (at least one Keyword: line)
_verbose_output=$(bash "$SCRIPT_DIR/aegis-policy-audit.sh" --verbose 2>/dev/null || true)
if echo "$_verbose_output" | grep -q "Keyword:"; then
    PASS "TC-06 --verbose output shows Keyword details"
else
    FAIL "TC-06 --verbose output missing Keyword details"
fi

# TC-07: Total claims > 0 (we know AEGIS docs have enforcement claims)
_total=$(echo "$_json_output" | python3 -c "import json,sys; print(json.load(sys.stdin)['total_claims'])" 2>/dev/null || echo "0")
if [[ "$_total" -gt 0 ]]; then
    PASS "TC-07 total_claims > 0 (found $_total)"
else
    FAIL "TC-07 total_claims is 0 -- scanner found nothing"
fi

# TC-08: Matched > 0 (we know hooks exist that match some claims)
_matched=$(echo "$_json_output" | python3 -c "import json,sys; print(json.load(sys.stdin)['matched'])" 2>/dev/null || echo "0")
if [[ "$_matched" -gt 0 ]]; then
    PASS "TC-08 matched > 0 (found $_matched)"
else
    FAIL "TC-08 matched is 0 -- no enforcement evidence found"
fi

test_results
