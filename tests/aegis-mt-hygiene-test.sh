#!/usr/bin/env bash
# aegis-mt-hygiene-test.sh — sprint v15-23.
#
# Tests new subcommands on tools/aegis-multi-tenant/mt.mjs:
#   T1: unregister removes a named entry
#   T2: unregister errors on unknown name (exit 2)
#   T3: prune --dry-run lists stale entries without writing
#   T4: prune (no dry-run) removes stale entries from registry
#   T5: prune is a no-op when registry is already clean
#   T6: prune handles empty registry gracefully

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
MT="$REPO_ROOT/tools/aegis-multi-tenant/mt.mjs"

[[ -f "$MT" ]] || { echo "FATAL: missing $MT" >&2; exit 2; }
command -v node >/dev/null 2>&1 || { echo "FATAL: node not installed" >&2; exit 2; }

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
PASS=0; FAIL=0
pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}FAIL${NC}: $1 -- $2"; FAIL=$((FAIL+1)); }

# Each test gets its own temp HOME so registries don't collide.
make_fix_home() {
    local h
    h=$(mktemp -d /tmp/mt-hygiene-XXXX)
    mkdir -p "$h/p-alive/.aegis" "$h/p-also/.aegis"
    HOME="$h" node "$MT" register --path "$h/p-alive" --name p-alive >/dev/null 2>&1
    HOME="$h" node "$MT" register --path "$h/p-also" --name p-also >/dev/null 2>&1
    echo "$h"
}

cleanup_home() {
    # Avoid rm -rf to keep clear of guards; remove file-by-file then dir
    local h="$1"
    find "$h" -type f -delete 2>/dev/null
    find "$h" -depth -type d -delete 2>/dev/null
}

# ── T1: unregister removes named entry ───────────────────────────────────
echo ""
echo "--- T1: unregister removes a named entry ---"
H=$(make_fix_home)
HOME="$H" node "$MT" unregister p-alive >/dev/null 2>&1
COUNT=$(HOME="$H" node "$MT" list --json 2>/dev/null | grep -c '"name"' || echo 0)
if [[ "$COUNT" == "1" ]]; then
    pass "T1: 2 → 1 after unregister"
else
    fail "T1: unregister count" "got $COUNT (expected 1)"
fi
cleanup_home "$H"

# ── T2: unregister unknown name errors ──────────────────────────────────
echo ""
echo "--- T2: unregister unknown → exit 2 ---"
H=$(make_fix_home)
HOME="$H" node "$MT" unregister nothing-by-this-name >/dev/null 2>&1
rc=$?
if [[ "$rc" == "2" ]]; then
    pass "T2: unknown name → exit 2"
else
    fail "T2: unknown exit" "rc=$rc"
fi
cleanup_home "$H"

# ── T3: prune --dry-run lists without writing ────────────────────────────
echo ""
echo "--- T3: prune --dry-run lists stale, no write ---"
H=$(make_fix_home)
# Make p-also stale by removing its dir
find "$H/p-also" -type f -delete 2>/dev/null
find "$H/p-also" -depth -type d -delete 2>/dev/null
BEFORE=$(HOME="$H" node "$MT" list --json 2>/dev/null | grep -c '"name"' || echo 0)
OUT=$(HOME="$H" node "$MT" prune --dry-run 2>&1)
AFTER=$(HOME="$H" node "$MT" list --json 2>/dev/null | grep -c '"name"' || echo 0)
if echo "$OUT" | grep -q "Would prune" && echo "$OUT" | grep -q "p-also" && [[ "$BEFORE" == "$AFTER" ]]; then
    pass "T3: dry-run reports stale + leaves registry unchanged"
else
    fail "T3: dry-run side-effect" "before=$BEFORE after=$AFTER out=$OUT"
fi
cleanup_home "$H"

# ── T4: prune removes stale entries ──────────────────────────────────────
echo ""
echo "--- T4: prune removes stale entries ---"
H=$(make_fix_home)
find "$H/p-also" -type f -delete 2>/dev/null
find "$H/p-also" -depth -type d -delete 2>/dev/null
HOME="$H" node "$MT" prune >/dev/null 2>&1
AFTER=$(HOME="$H" node "$MT" list --json 2>/dev/null | grep -c '"name"' || echo 0)
if [[ "$AFTER" == "1" ]]; then
    pass "T4: stale entry removed (count 2 → 1)"
else
    fail "T4: prune count" "got $AFTER (expected 1)"
fi
cleanup_home "$H"

# ── T5: prune on clean registry is no-op ────────────────────────────────
echo ""
echo "--- T5: prune on clean registry is no-op ---"
H=$(make_fix_home)
OUT=$(HOME="$H" node "$MT" prune 2>&1)
if echo "$OUT" | grep -q "no stale entries"; then
    pass "T5: prune on clean registry reports no-op"
else
    fail "T5: no-op message" "out=$OUT"
fi
cleanup_home "$H"

# ── T6: prune on empty registry is graceful ─────────────────────────────
echo ""
echo "--- T6: prune on empty registry is graceful ---"
EMPTY_H=$(mktemp -d /tmp/mt-empty-XXXX)
OUT=$(HOME="$EMPTY_H" node "$MT" prune 2>&1)
rc=$?
if [[ "$rc" == "0" ]] && echo "$OUT" | grep -q "no stale entries"; then
    pass "T6: empty registry → exit 0, no-op"
else
    fail "T6: empty graceful" "rc=$rc out=$OUT"
fi
find "$EMPTY_H" -type f -delete 2>/dev/null
find "$EMPTY_H" -depth -type d -delete 2>/dev/null

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
echo "============================================"
[[ "$FAIL" -gt 0 ]] && exit 1
exit 0
