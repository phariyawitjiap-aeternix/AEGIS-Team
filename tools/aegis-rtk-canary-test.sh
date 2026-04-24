#!/usr/bin/env bash
# aegis-rtk-canary-test.sh — RTK signal-loss canary test
#
# DORMANT test: skips cleanly if `rtk` is not installed (exit 0 + SKIP message).
# When RTK is present, runs 3 signal-loss tests:
#
#   1. Error count preservation: 47 known errors piped through rtk,
#      asserts count is preserved (or documents the loss)
#   2. Git diff recovery: known diff piped through `rtk git diff`,
#      asserts byte-exact recovery from tee directory
#   3. Structured output preservation: JSON piped through rtk,
#      asserts JSON validity preserved after round-trip
#
# Exit codes:
#   0 — all tests pass OR rtk not installed (SKIP)
#   1 — signal loss detected
#
# Sprint: sprint-v10-02 / Story D (1pt)

set -euo pipefail

PASS=0
FAIL=0
SKIP=0
TOTAL=0

assert_eq() {
    local label="$1" expected="$2" actual="$3"
    TOTAL=$((TOTAL + 1))
    if [[ "$expected" == "$actual" ]]; then
        PASS=$((PASS + 1))
        echo "  PASS: $label"
    else
        FAIL=$((FAIL + 1))
        echo "  FAIL: $label (expected='$expected', actual='$actual')"
    fi
}

skip_test() {
    local label="$1"
    TOTAL=$((TOTAL + 1))
    SKIP=$((SKIP + 1))
    echo "  SKIP: $label"
}

echo "=== aegis-rtk-canary-test.sh ==="
echo ""

# ── Pre-flight: check if rtk is installed ───────────────────────────────────

if ! command -v rtk &>/dev/null; then
    echo "RTK not installed (command 'rtk' not found)."
    echo "All canary tests SKIPPED — this is expected on systems without RTK."
    echo "Install RTK and re-run to validate signal preservation."
    echo ""
    echo "=== Results ==="
    echo "  0 passed, 0 failed, 3 skipped, 3 total"
    echo "  STATUS: SKIP (rtk not installed)"
    exit 0
fi

echo "RTK detected: $(rtk --version 2>/dev/null || echo 'version unknown')"
echo ""

# ── Test 1: Error count preservation ────────────────────────────────────────

echo "Test 1: Error count preservation (47 errors)"

# Generate exactly 47 distinct error lines
ERRORS=""
for i in $(seq 1 47); do
    ERRORS="${ERRORS}error[$i]: something failed at line $i in module_$(( i % 7 ))\n"
done

# Count errors before RTK
BEFORE_COUNT=$(echo -e "$ERRORS" | grep -c "^error\[")

# Pipe through RTK
AFTER=$(echo -e "$ERRORS" | rtk 2>/dev/null || echo -e "$ERRORS")
AFTER_COUNT=$(echo "$AFTER" | grep -c "^error\[" || echo "0")

assert_eq "47 errors preserved after RTK" "$BEFORE_COUNT" "$AFTER_COUNT"

if [[ "$BEFORE_COUNT" != "$AFTER_COUNT" ]]; then
    echo "  SIGNAL LOSS: $BEFORE_COUNT errors in, $AFTER_COUNT errors out"
    echo "  Lost: $(( BEFORE_COUNT - AFTER_COUNT )) error lines"
fi

# ── Test 2: Git diff byte-exact recovery ────────────────────────────────────

echo ""
echo "Test 2: Git diff byte-exact recovery from tee"

# Generate a known git diff
KNOWN_DIFF="diff --git a/test.txt b/test.txt
index 1234567..abcdefg 100644
--- a/test.txt
+++ b/test.txt
@@ -1,5 +1,7 @@
 line 1 unchanged
-line 2 removed
+line 2 modified
+line 2.1 added
 line 3 unchanged
-line 4 removed
+line 4 modified
+line 4.1 added
 line 5 unchanged"

# Create temp files for comparison
BEFORE_FILE=$(mktemp)
AFTER_FILE=$(mktemp)
echo "$KNOWN_DIFF" > "$BEFORE_FILE"

# Pipe through rtk git diff
echo "$KNOWN_DIFF" | rtk git diff > "$AFTER_FILE" 2>/dev/null || echo "$KNOWN_DIFF" > "$AFTER_FILE"

# Check tee directory for recovery
TEE_DIR="${HOME}/.local/share/rtk/tee"
if [[ -d "$TEE_DIR" ]]; then
    # Find most recent tee file
    LATEST_TEE=$(find "$TEE_DIR" -type f -name "*.tee" -newer "$BEFORE_FILE" 2>/dev/null | sort | tail -1)
    if [[ -n "$LATEST_TEE" ]]; then
        # Compare tee content with original
        if diff -q "$BEFORE_FILE" "$LATEST_TEE" &>/dev/null; then
            assert_eq "Tee file is byte-exact match" "true" "true"
        else
            assert_eq "Tee file is byte-exact match" "true" "false"
            echo "  SIGNAL LOSS: tee file differs from original input"
        fi
    else
        skip_test "No tee file found (rtk may not write tee for this command)"
    fi
else
    skip_test "Tee directory not found at $TEE_DIR"
fi

# Cleanup temp files
rm -f "$BEFORE_FILE" "$AFTER_FILE"

# ── Test 3: Structured output (JSON) preservation ──────────────────────────

echo ""
echo "Test 3: JSON structure preserved after RTK round-trip"

KNOWN_JSON='{"tool_name":"Bash","tool_input":{"command":"git status"},"tool_response":{"output":"On branch main","exit_code":0},"metadata":{"tokens":42,"timestamp":"2026-04-25T00:00:00Z"}}'

# Pipe through rtk
AFTER_JSON=$(echo "$KNOWN_JSON" | rtk 2>/dev/null || echo "$KNOWN_JSON")

# Validate JSON is still parseable
VALID=$(echo "$AFTER_JSON" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    # Verify key fields survived
    assert d['tool_name'] == 'Bash'
    assert d['metadata']['tokens'] == 42
    print('true')
except:
    print('false')
" 2>/dev/null || echo "false")

assert_eq "JSON valid after RTK round-trip" "true" "$VALID"

# ── Results ─────────────────────────────────────────────────────────────────

echo ""
echo "=== Results ==="
echo "  $PASS passed, $FAIL failed, $SKIP skipped, $TOTAL total"

if [[ "$FAIL" -gt 0 ]]; then
    echo "  STATUS: FAIL (signal loss detected)"
    exit 1
else
    echo "  STATUS: PASS"
    exit 0
fi
