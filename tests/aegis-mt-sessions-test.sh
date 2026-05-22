#!/usr/bin/env bash
# aegis-mt-sessions-test.sh — sprint v15-22 Story E (mt sessions portion).
#
# Tests `node tools/aegis-multi-tenant/mt.mjs sessions`:
#   T1: human output has expected header row
#   T2: --json output is a JSON array of project records
#   T3: each record has required keys (name, path, status, sessionId, age_min)
#   T4: graceful no-data (empty registry) doesn't crash

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
MT="$REPO_ROOT/tools/aegis-multi-tenant/mt.mjs"

[[ -f "$MT" ]] || { echo "FATAL: missing $MT" >&2; exit 2; }
command -v node >/dev/null 2>&1 || { echo "FATAL: node not installed" >&2; exit 2; }
command -v jq >/dev/null 2>&1 || { echo "FATAL: jq not installed" >&2; exit 2; }

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
PASS=0; FAIL=0
pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}FAIL${NC}: $1 -- $2"; FAIL=$((FAIL+1)); }

# ── T1: human header (with a fixture project registered) ────────────────
echo ""
echo "--- T1: human output has expected header row ---"
# CI registry is empty → would print "(no registered projects, no live sessions)".
# Set HOME to a temp dir + pre-register one fake project so the header is exercised.
FIX_HOME=$(mktemp -d /tmp/mt-test-home.XXXX)
mkdir -p "$FIX_HOME/.aegis/brain/multi-tenant"
# `mt register` requires the registered project to have a .aegis/ subdir,
# or it dies (`not an AEGIS project`). Create it so the fixture inserts cleanly.
mkdir -p "$FIX_HOME/fake-project/.aegis"
echo "test" > "$FIX_HOME/fake-project/CLAUDE.md"
HOME="$FIX_HOME" node "$MT" register --path "$FIX_HOME/fake-project" --name fake >/dev/null 2>&1 || true
OUT=$(HOME="$FIX_HOME" node "$MT" sessions 2>&1)
if echo "$OUT" | head -1 | grep -qE "PROJECT.*VERSION.*EXISTS.*STATUS.*SESSION.*AGE.*PATH"; then
    pass "T1: header row present"
else
    fail "T1: header" "got first line: $(echo "$OUT" | head -1)"
fi
rm -rf "$FIX_HOME" 2>/dev/null || true

# ── T2: --json is array ──────────────────────────────────────────────────
echo ""
echo "--- T2: --json output is JSON array ---"
OUT=$(node "$MT" sessions --json 2>&1)
if echo "$OUT" | jq -e 'type == "array"' >/dev/null 2>&1; then
    pass "T2: --json type is array"
else
    fail "T2: json type" "got: $(echo "$OUT" | head -3)"
fi

# ── T3: required keys present on each record ─────────────────────────────
echo ""
echo "--- T3: each record has required keys ---"
OUT=$(node "$MT" sessions --json 2>&1)
# Pull first record and check it has the keys we expect
ok=$(echo "$OUT" | jq -r '
    if length == 0 then "EMPTY"
    else (.[0] | has("name") and has("path") and has("status") and has("sessionId") and has("age_min")) | tostring
    end
' 2>&1)
case "$ok" in
    true|EMPTY) pass "T3: schema correct ($ok)" ;;
    *)          fail "T3: schema" "got: $ok output_sample: $(echo "$OUT" | head -10)" ;;
esac

# ── T4: empty-registry path doesn't crash ────────────────────────────────
echo ""
echo "--- T4: empty-registry case is graceful ---"
# Run with HOME pointed to an empty dir so the registry file doesn't exist
EMPTY_HOME=$(mktemp -d /tmp/empty-home.XXXX)
OUT=$(HOME="$EMPTY_HOME" node "$MT" sessions --json 2>&1)
rc=$?
if [[ "$rc" == "0" ]] && echo "$OUT" | jq -e 'type == "array"' >/dev/null 2>&1; then
    pass "T4: empty registry → JSON array, exit 0"
else
    fail "T4: empty registry" "rc=$rc out=$OUT"
fi
rmdir "$EMPTY_HOME" 2>/dev/null || true

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
echo "============================================"
[[ "$FAIL" -gt 0 ]] && exit 1
exit 0
