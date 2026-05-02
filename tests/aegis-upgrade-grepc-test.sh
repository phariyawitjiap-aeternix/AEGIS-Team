#!/usr/bin/env bash
# aegis-upgrade-grepc-test.sh — Regression test for grep -c "0\n0" bug
#
# Repro of the original bug:
#   In tools/aegis-upgrade.sh:157, REL_COUNT was assigned via
#     REL_COUNT=$(grep -cE 'pattern' file 2>/dev/null || echo 0)
#   When grep matched nothing it printed "0" with exit-1, so the `|| echo 0`
#   ALSO fired, producing the literal value "0\n0". The next line
#     [[ "$REL_COUNT" -gt 0 ]]
#   then errored with "0\n0: integer expression expected" (and -gt fell
#   through to the success branch by accident).
#
# Fix: drop the `|| echo 0` and use ${VAR:-0} default instead, since
# grep -c always prints a count.
#
# This test isolates the assignment block, drives it with a known-empty
# settings.json, and asserts REL_COUNT is exactly "0" (length 1, no
# embedded newline).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
UPGRADE_SH="${SCRIPT_DIR}/../tools/aegis-upgrade.sh"

if [[ ! -f "$UPGRADE_SH" ]]; then
  echo "FATAL: cannot locate aegis-upgrade.sh at $UPGRADE_SH" >&2
  exit 2
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
PASS_COUNT=0
FAIL_COUNT=0
pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS_COUNT=$((PASS_COUNT+1)); }
fail() { echo -e "${RED}FAIL${NC}: $1 -- $2"; FAIL_COUNT=$((FAIL_COUNT+1)); }

TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/aegis-upgrade-grepc-XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT INT TERM

echo "============================================"
echo "AEGIS upgrade -- grep -c 0\\n0 regression"
echo "============================================"

# --- Extract the assignment block from the live upgrade.sh ---
# We grep out the two lines that set REL_COUNT (current implementation)
# so the test always exercises whatever the script currently uses.
ASSIGN_BLOCK=$(grep -E '^[[:space:]]*REL_COUNT=' "$UPGRADE_SH")
if [[ -z "$ASSIGN_BLOCK" ]]; then
  fail "extract REL_COUNT assignment" "no REL_COUNT lines found in upgrade.sh"
  echo "RESULTS: $PASS_COUNT passed, $FAIL_COUNT failed"
  exit 1
fi

# --- Fixture: empty JSON, contains no hook commands at all ---
EMPTY_SETTINGS="${TEST_DIR}/empty-settings.json"
echo '{}' > "$EMPTY_SETTINGS"
TARGET_DIR_PARENT="${TEST_DIR}/empty-target"
mkdir -p "$TARGET_DIR_PARENT/.claude"
cp "$EMPTY_SETTINGS" "$TARGET_DIR_PARENT/.claude/settings.json"

# --- Fixture: settings.json with 2 relative-path hooks ---
HIT_DIR="${TEST_DIR}/hit-target"
mkdir -p "$HIT_DIR/.claude"
cat > "$HIT_DIR/.claude/settings.json" <<'JSON'
{
  "hooks": {
    "PostToolUse": [{"matcher": "Bash", "hooks": [{"type": "command", "command": "bash .claude/hooks/foo.sh"}]}],
    "Stop":        [{"matcher": "",     "hooks": [{"type": "command", "command": "bash .claude/hooks/bar.sh"}]}]
  }
}
JSON

# --- Test runner: source the assignment block in a subshell ---
run_block() {
  local target_dir="$1"
  bash -c "
    set -uo pipefail
    TARGET_DIR='$target_dir'
    $ASSIGN_BLOCK
    printf '%s' \"\$REL_COUNT\"
  "
}

# Test 1: no-match must produce exactly "0" — no embedded newline, length 1
echo ""
echo "--- Test 1: no-match returns clean '0' ---"
out=$(run_block "$TARGET_DIR_PARENT")
if [[ "$out" == "0" ]] && [[ ${#out} -eq 1 ]]; then
  pass "REL_COUNT == '0' (length 1) on no-match"
else
  fail "REL_COUNT clean on no-match" "got=$(printf '%q' "$out") len=${#out}"
fi

# Test 2: the integer-test that broke under the bug must succeed cleanly
echo ""
echo "--- Test 2: [[ \$REL_COUNT -gt 0 ]] runs without integer error ---"
err_log="${TEST_DIR}/integer-test.err"
bash -c "
  set -uo pipefail
  TARGET_DIR='$TARGET_DIR_PARENT'
  $ASSIGN_BLOCK
  if [[ \"\$REL_COUNT\" -gt 0 ]]; then
    echo 'GT_BRANCH'
  else
    echo 'LE_BRANCH'
  fi
" >"${TEST_DIR}/integer-test.out" 2>"$err_log"
out=$(cat "${TEST_DIR}/integer-test.out")
err=$(cat "$err_log")
if [[ "$out" == "LE_BRANCH" ]] && ! grep -q "integer expression expected\|0.n0" "$err_log"; then
  pass "integer test takes correct branch with no shell error"
else
  fail "integer test on no-match" "out=$out stderr=$err"
fi

# Test 3: positive case still counts correctly
echo ""
echo "--- Test 3: hit count is correct on match ---"
out=$(run_block "$HIT_DIR")
if [[ "$out" == "2" ]]; then
  pass "REL_COUNT == '2' on 2 hook matches"
else
  fail "REL_COUNT correct on match" "got=$(printf '%q' "$out") expected=2"
fi

# Test 4: missing settings.json does not blow up
echo ""
echo "--- Test 4: missing settings.json handled cleanly ---"
MISSING_DIR="${TEST_DIR}/missing-target"
mkdir -p "$MISSING_DIR/.claude"
out=$(run_block "$MISSING_DIR" 2>"${TEST_DIR}/missing.err") || true
err=$(cat "${TEST_DIR}/missing.err")
if [[ "$out" == "0" ]] && ! grep -q "integer expression expected" "${TEST_DIR}/missing.err"; then
  pass "REL_COUNT == '0' when settings.json is missing"
else
  fail "missing settings.json" "out=$(printf '%q' "$out") stderr=$err"
fi

echo ""
echo "============================================"
echo "RESULTS: ${PASS_COUNT} passed, ${FAIL_COUNT} failed"
echo "============================================"

if [[ $FAIL_COUNT -gt 0 ]]; then
  echo -e "${RED}AEGIS-UPGRADE GREPC TESTS: FAILURES${NC}"
  exit 1
fi
echo -e "${GREEN}AEGIS-UPGRADE GREPC TESTS: ALL PASSED${NC}"
exit 0
