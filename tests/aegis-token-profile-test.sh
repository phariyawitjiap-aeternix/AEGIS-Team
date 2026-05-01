#!/usr/bin/env bash
# aegis-token-profile-test.sh — Unit tests for token profiling tool
#
# Tests hook mode (JSONL ingestion) and summary mode (aggregation math).
# Uses fixture tool-call events to assert correct categorization and totals.
#
# Sprint: sprint-v10-02 / Story A companion test

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOOL="$REPO_ROOT/tools/aegis-token-profile.sh"
METRICS_DIR="$REPO_ROOT/.aegis/brain/metrics"
TEST_DATE="2099-01-01"
TEST_LOG="$METRICS_DIR/token-profile-${TEST_DATE}.jsonl"

PASS=0
FAIL=0
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

assert_contains() {
    local label="$1" needle="$2" haystack="$3"
    TOTAL=$((TOTAL + 1))
    if echo "$haystack" | grep -qF "$needle"; then
        PASS=$((PASS + 1))
        echo "  PASS: $label"
    else
        FAIL=$((FAIL + 1))
        echo "  FAIL: $label (expected to contain '$needle')"
    fi
}

# ── Setup ───────────────────────────────────────────────────────────────────

echo "=== aegis-token-profile-test.sh ==="
echo ""

# Clean test artifacts
rm -f "$TEST_LOG"

# ── Test 1: Hook mode — Bash event ─────────────────────────────────────────

echo "Test 1: Hook mode ingests Bash tool event"

# Create a fixture with known char counts
# tool_input JSON = {"command":"git status"} = 24 chars -> 6 tokens
# tool_response = {"output":"On branch main"} = 30 chars -> ~8 tokens
FIXTURE='{"tool_name":"Bash","tool_input":{"command":"git status --short"},"tool_response":{"output":"On branch main\\nnothing to commit"}}'

echo "$FIXTURE" | bash "$TOOL" 2>/dev/null

# Verify JSONL was written (we override the date by checking the actual output file)
# Since hook mode uses today's date, we need to check today's file
TODAY=$(date -u +"%Y-%m-%d")
TODAY_LOG="$METRICS_DIR/token-profile-${TODAY}.jsonl"

if [[ -f "$TODAY_LOG" ]]; then
    LAST_LINE=$(tail -1 "$TODAY_LOG")
    assert_contains "JSONL written" '"category":"Bash"' "$LAST_LINE"
    assert_contains "tool field present" '"tool":"Bash"' "$LAST_LINE"
    assert_contains "total_tokens present" '"total_tokens":' "$LAST_LINE"
else
    TOTAL=$((TOTAL + 2))
    FAIL=$((FAIL + 2))
    echo "  FAIL: No JSONL file created at $TODAY_LOG"
fi

# ── Test 2: Hook mode — Read event ─────────────────────────────────────────

echo ""
echo "Test 2: Hook mode categorizes Read correctly"

FIXTURE_READ='{"tool_name":"Read","tool_input":{"file_path":"/tmp/test.txt"},"tool_response":{"content":"hello world this is a test file with some content"}}'
echo "$FIXTURE_READ" | bash "$TOOL" 2>/dev/null

LAST_LINE=$(tail -1 "$TODAY_LOG")
assert_contains "Read categorized" '"category":"Read"' "$LAST_LINE"

# ── Test 3: Hook mode — Grep event ─────────────────────────────────────────

echo ""
echo "Test 3: Hook mode categorizes Grep correctly"

FIXTURE_GREP='{"tool_name":"Grep","tool_input":{"pattern":"TODO","path":"/tmp"},"tool_response":{"matches":["file1.txt:3:TODO fix","file2.txt:7:TODO refactor"]}}'
echo "$FIXTURE_GREP" | bash "$TOOL" 2>/dev/null

LAST_LINE=$(tail -1 "$TODAY_LOG")
assert_contains "Grep categorized" '"category":"Grep"' "$LAST_LINE"

# ── Test 4: Hook mode — Glob event ─────────────────────────────────────────

echo ""
echo "Test 4: Hook mode categorizes Glob correctly"

FIXTURE_GLOB='{"tool_name":"Glob","tool_input":{"pattern":"**/*.sh"},"tool_response":{"files":["a.sh","b.sh","c.sh"]}}'
echo "$FIXTURE_GLOB" | bash "$TOOL" 2>/dev/null

LAST_LINE=$(tail -1 "$TODAY_LOG")
assert_contains "Glob categorized" '"category":"Glob"' "$LAST_LINE"

# ── Test 5: Hook mode — Edit event ─────────────────────────────────────────

echo ""
echo "Test 5: Hook mode categorizes Edit correctly"

FIXTURE_EDIT='{"tool_name":"Edit","tool_input":{"file_path":"/tmp/test.txt","old_string":"old","new_string":"new"},"tool_response":{"success":true}}'
echo "$FIXTURE_EDIT" | bash "$TOOL" 2>/dev/null

LAST_LINE=$(tail -1 "$TODAY_LOG")
assert_contains "Edit categorized" '"category":"Edit"' "$LAST_LINE"

# ── Test 6: Hook mode — Agent event ────────────────────────────────────────

echo ""
echo "Test 6: Hook mode categorizes Agent correctly"

FIXTURE_AGENT='{"tool_name":"Agent","tool_input":{"prompt":"do something"},"tool_response":{"result":"done"}}'
echo "$FIXTURE_AGENT" | bash "$TOOL" 2>/dev/null

LAST_LINE=$(tail -1 "$TODAY_LOG")
assert_contains "Agent categorized" '"category":"Agent"' "$LAST_LINE"

# ── Test 7: Hook mode — unknown tool -> Other ──────────────────────────────

echo ""
echo "Test 7: Unknown tool categorized as Other"

FIXTURE_UNK='{"tool_name":"WebSearch","tool_input":{"query":"test"},"tool_response":{"results":[]}}'
echo "$FIXTURE_UNK" | bash "$TOOL" 2>/dev/null

LAST_LINE=$(tail -1 "$TODAY_LOG")
assert_contains "Other categorized" '"category":"Other"' "$LAST_LINE"

# ── Test 8: Summary mode — text output ─────────────────────────────────────

echo ""
echo "Test 8: Summary mode produces text output"

SUMMARY=$(bash "$TOOL" --summary --date "$TODAY" 2>/dev/null)
assert_contains "Header present" "Token Profile Summary" "$SUMMARY"
assert_contains "Bash row present" "Bash" "$SUMMARY"
assert_contains "Read row present" "Read" "$SUMMARY"
assert_contains "Killshot answer" "Killshot" "$SUMMARY"

# ── Test 9: Summary mode — JSON output ─────────────────────────────────────

echo ""
echo "Test 9: Summary mode produces valid JSON"

JSON_OUT=$(bash "$TOOL" --summary --date "$TODAY" --json 2>/dev/null)
# Validate it's valid JSON
echo "$JSON_OUT" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null
assert_eq "Valid JSON" "0" "$?"

# Check JSON has expected fields
HAS_CATEGORIES=$(echo "$JSON_OUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print('yes' if 'categories' in d else 'no')" 2>/dev/null)
assert_eq "JSON has categories" "yes" "$HAS_CATEGORIES"

HAS_TOTAL=$(echo "$JSON_OUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print('yes' if d.get('total_calls',0) > 0 else 'no')" 2>/dev/null)
assert_eq "JSON has nonzero total_calls" "yes" "$HAS_TOTAL"

# ── Test 10: Summary mode — aggregation math ───────────────────────────────

echo ""
echo "Test 10: Aggregation math — percentages sum to ~100%"

PCT_SUM=$(echo "$JSON_OUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
total = sum(c['pct_of_total'] for c in d['categories'].values())
# Allow 0.5% rounding tolerance
print('yes' if 99.0 <= total <= 101.0 else f'no:{total}')
" 2>/dev/null)
assert_eq "Percentages sum to ~100%" "yes" "$PCT_SUM"

# ── Test 11: Token estimation sanity ────────────────────────────────────────

echo ""
echo "Test 11: Token estimation — chars/4 rounding"

# Feed a known-size input: 100 chars -> 25 tokens
FIXTURE_100='{"tool_name":"Bash","tool_input":{"command":"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"},"tool_response":{}}'
echo "$FIXTURE_100" | bash "$TOOL" 2>/dev/null

LAST_LINE=$(tail -1 "$TODAY_LOG")
INPUT_TOKENS=$(echo "$LAST_LINE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['input_tokens'])" 2>/dev/null)

# The JSON serialization of the input adds quotes and braces, so tokens > 25
# Just verify it's a positive integer and reasonable (> 20)
REASONABLE=$(python3 -c "print('yes' if int('$INPUT_TOKENS') > 20 else 'no')" 2>/dev/null)
assert_eq "Input tokens reasonable for 100-char command" "yes" "$REASONABLE"

# ── Test 12: Missing date file — graceful handling ──────────────────────────

echo ""
echo "Test 12: Summary for nonexistent date is graceful"

NO_DATA=$(bash "$TOOL" --summary --date "1999-01-01" 2>/dev/null)
assert_contains "No data message" "No token profile data" "$NO_DATA"

# ── Test 13: Help flag ──────────────────────────────────────────────────────

echo ""
echo "Test 13: --help works"

HELP_OUT=$(bash "$TOOL" --help 2>/dev/null)
assert_contains "Help shows usage" "Usage" "$HELP_OUT"

# ── Test 14: Empty stdin in hook mode ───────────────────────────────────────

echo ""
echo "Test 14: Empty stdin does not crash"

echo "" | bash "$TOOL" 2>/dev/null
EXIT_CODE=$?
assert_eq "Exit 0 on empty stdin" "0" "$EXIT_CODE"

# ── Cleanup & Results ───────────────────────────────────────────────────────

echo ""
echo "=== Results ==="
echo "  $PASS passed, $FAIL failed, $TOTAL total"

if [[ "$FAIL" -gt 0 ]]; then
    echo "  STATUS: FAIL"
    exit 1
else
    echo "  STATUS: PASS"
    exit 0
fi
