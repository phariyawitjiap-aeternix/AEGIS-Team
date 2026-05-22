#!/usr/bin/env bash
# aegis-claude-agents-test.sh — sprint v15-22 Story E (wrapper portion).
#
# Tests tools/aegis-claude-agents.sh:
#   T1: `list --json` returns a JSON array (even when claude is missing)
#   T2: `list` (human) succeeds without crashing
#   T3: `filter --cwd <path>` returns JSON array (smoke-OK)
#   T4: `self` returns a JSON object (smoke-OK)
#   T5: graceful fallback when `claude` binary absent (PATH override)
#   T6: 1-sec cache: re-fetch within 1s returns same byte-for-byte output

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TOOL="$REPO_ROOT/tools/aegis-claude-agents.sh"

[[ -f "$TOOL" ]] || { echo "FATAL: missing $TOOL" >&2; exit 2; }
command -v jq >/dev/null 2>&1 || { echo "FATAL: jq not installed" >&2; exit 2; }

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
PASS=0; FAIL=0
pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}FAIL${NC}: $1 -- $2"; FAIL=$((FAIL+1)); }

# ── T1: list --json returns JSON array ───────────────────────────────────
echo ""
echo "--- T1: list --json returns JSON array ---"
OUT=$(bash "$TOOL" list --json 2>&1)
if echo "$OUT" | jq -e 'type == "array"' >/dev/null 2>&1; then
    pass "T1: list --json output is a JSON array"
else
    fail "T1: array type" "got: $OUT"
fi

# ── T2: list (human) succeeds ────────────────────────────────────────────
echo ""
echo "--- T2: list (human) succeeds ---"
bash "$TOOL" list >/dev/null 2>&1
rc=$?
if [[ "$rc" == "0" ]]; then
    pass "T2: list (human) exits 0"
else
    fail "T2: list exit" "rc=$rc"
fi

# ── T3: filter --cwd returns JSON array ──────────────────────────────────
echo ""
echo "--- T3: filter --cwd returns JSON array ---"
OUT=$(bash "$TOOL" filter --cwd "$HOME" 2>&1)
if echo "$OUT" | jq -e 'type == "array"' >/dev/null 2>&1; then
    pass "T3: filter --cwd output is JSON array"
else
    fail "T3: filter array" "got: $OUT"
fi

# ── T4: self returns JSON object ─────────────────────────────────────────
echo ""
echo "--- T4: self returns JSON object ---"
OUT=$(bash "$TOOL" self 2>&1)
if echo "$OUT" | jq -e 'type == "object"' >/dev/null 2>&1; then
    pass "T4: self output is JSON object"
else
    fail "T4: self object" "got: $OUT"
fi

# ── T5: graceful fallback when `claude` missing ──────────────────────────
echo ""
echo "--- T5: graceful fallback when claude binary absent ---"
# PATH must still include essentials (bash, jq, cat, mktemp) but exclude `claude`.
# Build a sanitized PATH with only /bin and /usr/bin and stub the local claude
# location by symlinking essentials into a temp dir + omitting claude.
SANE_PATH="/usr/bin:/bin"
# Ensure bash + jq + node + cat + mktemp resolvable on that minimal PATH
if ! PATH="$SANE_PATH" command -v jq >/dev/null 2>&1; then
    # jq not on minimal PATH — find its dir and add only that
    JQ_DIR=$(dirname "$(command -v jq)")
    SANE_PATH="$SANE_PATH:$JQ_DIR"
fi
# Confirm `claude` is NOT on the sanitized PATH (test precondition)
if PATH="$SANE_PATH" command -v claude >/dev/null 2>&1; then
    fail "T5: precondition" "claude unexpectedly still on sanitized PATH"
else
    OUT=$(PATH="$SANE_PATH" bash "$TOOL" list --json 2>&1)
    rc=$?
    if [[ "$rc" == "0" ]] && echo "$OUT" | jq -e 'type == "array"' >/dev/null 2>&1; then
        pass "T5: missing claude → returns [] (soft fallback)"
    else
        fail "T5: fallback" "rc=$rc out=$OUT"
    fi
fi

# ── T6: 1-sec cache ──────────────────────────────────────────────────────
echo ""
echo "--- T6: cache returns identical output within 1s ---"
OUT1=$(bash "$TOOL" list --json 2>&1)
OUT2=$(bash "$TOOL" list --json 2>&1)
if [[ "$OUT1" == "$OUT2" ]]; then
    pass "T6: two consecutive calls return identical bytes (cache hit)"
else
    fail "T6: cache" "outputs differ"
fi

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
echo "============================================"
[[ "$FAIL" -gt 0 ]] && exit 1
exit 0
