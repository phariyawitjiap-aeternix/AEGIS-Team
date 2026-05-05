#!/usr/bin/env bash
# aegis-approval-gate-test.sh — Sprint v11-05 acceptance + regression test

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CHECK="${REPO_ROOT}/tools/aegis-approval-gate/check.mjs"
GRANT="${REPO_ROOT}/tools/aegis-approval-gate/grant.mjs"
LIST="${REPO_ROOT}/tools/aegis-approval-gate/list.mjs"
REVOKE="${REPO_ROOT}/tools/aegis-approval-gate/revoke.mjs"

for f in "$CHECK" "$GRANT" "$LIST" "$REVOKE"; do
  [[ -f "$f" ]] || { echo "FATAL: missing $f" >&2; exit 2; }
done
command -v node >/dev/null 2>&1 || { echo "FATAL: node missing" >&2; exit 2; }

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
PASS=0; FAIL=0
pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}FAIL${NC}: $1 -- $2"; FAIL=$((FAIL+1)); }

TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/aegis-approval-gate-XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT INT TERM

# Set up a self-contained pilot project with the meta's gate-rules.yaml.
mkdir -p "$TEST_DIR/.aegis/brain/approvals" "$TEST_DIR/.aegis/brain/logs"
cp "$REPO_ROOT/.aegis/brain/gate-rules.yaml" "$TEST_DIR/.aegis/brain/gate-rules.yaml"
export CLAUDE_PROJECT_DIR="$TEST_DIR"

echo "============================================"
echo "AEGIS approval-gate — sprint v11-05 acceptance"
echo "============================================"

# Helper: feed a Bash hook payload to check.mjs and capture rc + stderr.
run_check() {
  local cmd="$1"
  local payload
  payload="$(node -e "process.stdout.write(JSON.stringify({tool_name:'Bash',tool_input:{command:process.argv[1]}}))" "$cmd")"
  local rc=0
  local err
  err=$(printf '%s' "$payload" | node "$CHECK" 2>&1 >/dev/null) || rc=$?
  echo "$rc"
  echo "$err"
}

# ── Group 1: blocking happy path ────────────────────────────────────────
echo ""
echo "--- Group 1: block destructive ops without approval ---"

# 1.a — rm -rf is blocked
RESULT=$(run_check 'rm -rf /tmp/foo')
RC=$(echo "$RESULT" | head -1)
ERR=$(echo "$RESULT" | tail -n +2)
if [[ "$RC" == "2" ]] && echo "$ERR" | grep -q "BLOCKED" && echo "$ERR" | grep -q "rm-rf"; then
  pass "1.a rm -rf without approval → exit 2 + helpful message"
else
  fail "1.a rm -rf block" "rc=$RC err=$ERR"
fi

# 1.b — git push --force is blocked
RESULT=$(run_check 'git push --force origin main')
RC=$(echo "$RESULT" | head -1)
if [[ "$RC" == "2" ]]; then
  pass "1.b git push --force → exit 2"
else
  fail "1.b force-push block" "rc=$RC"
fi

# 1.c — DROP TABLE pattern (case-insensitive)
RESULT=$(run_check 'sqlite3 db.sqlite "DROP TABLE users"')
RC=$(echo "$RESULT" | head -1)
if [[ "$RC" == "2" ]]; then
  pass "1.c DROP TABLE → exit 2"
else
  fail "1.c drop table block" "rc=$RC"
fi

# 1.d — innocuous command passes
RESULT=$(run_check 'ls -la')
RC=$(echo "$RESULT" | head -1)
if [[ "$RC" == "0" ]]; then
  pass "1.d ls -la → exit 0 (no rule match)"
else
  fail "1.d innocuous pass" "rc=$RC"
fi

# 1.e — non-Bash tool (Edit) always passes
EDIT_PAYLOAD='{"tool_name":"Edit","tool_input":{"file_path":"src/x.ts"}}'
RC=0
printf '%s' "$EDIT_PAYLOAD" | node "$CHECK" >/dev/null 2>&1 || RC=$?
if [[ "$RC" == "0" ]]; then
  pass "1.e Edit tool → exit 0 (gate is Bash-only)"
else
  fail "1.e edit pass" "rc=$RC"
fi

# 1.f — sudo rm blocked
RESULT=$(run_check 'sudo rm something')
RC=$(echo "$RESULT" | head -1)
if [[ "$RC" == "2" ]]; then
  pass "1.f sudo rm → exit 2"
else
  fail "1.f sudo rm" "rc=$RC"
fi

# ── Group 2: approval grants pass ───────────────────────────────────────
echo ""
echo "--- Group 2: granted approvals allow ---"

# 2.a — grant rule:rm-rf, retry rm -rf — passes
node "$GRANT" --task KAM-1 --action wipe --scope rule:rm-rf --ttl 1h --by tester >/dev/null
RESULT=$(run_check 'rm -rf /tmp/foo')
RC=$(echo "$RESULT" | head -1)
if [[ "$RC" == "0" ]]; then
  pass "2.a rm -rf with rule:rm-rf approval → exit 0"
else
  fail "2.a granted-rm-rf pass" "rc=$RC err=$(echo "$RESULT" | tail -n +2)"
fi

# 2.b — git push --force still blocked (different scope)
RESULT=$(run_check 'git push --force origin main')
RC=$(echo "$RESULT" | head -1)
if [[ "$RC" == "2" ]]; then
  pass "2.b force-push still blocked (approval was rm-rf-scoped)"
else
  fail "2.b scope isolation" "rc=$RC"
fi

# 2.c — wildcard scope * covers anything
node "$GRANT" --task KAM-2 --action override-all --scope '*' --ttl 1h --by tester >/dev/null
RESULT=$(run_check 'git push --force origin main')
RC=$(echo "$RESULT" | head -1)
if [[ "$RC" == "0" ]]; then
  pass "2.c wildcard scope * passes force-push"
else
  fail "2.c wildcard" "rc=$RC"
fi

# Cleanup wildcard so later tests see clean state
node "$REVOKE" KAM-2-override-all >/dev/null

# ── Group 3: expiry + revoke ────────────────────────────────────────────
echo ""
echo "--- Group 3: expiry + revoke ---"

# 3.a — grant 1 second TTL, sleep, observe block returns
node "$GRANT" --task KAM-3 --action quick --scope rule:rm-rf --ttl 1s --by tester >/dev/null
sleep 1.2
# At this point KAM-3 expired AND KAM-1 is still active (1h). Revoke KAM-1
# so we can observe the expired-only state.
node "$REVOKE" KAM-1-wipe >/dev/null
RESULT=$(run_check 'rm -rf /tmp/foo')
RC=$(echo "$RESULT" | head -1)
if [[ "$RC" == "2" ]]; then
  pass "3.a expired approval no longer covers — block returns"
else
  fail "3.a expiry" "rc=$RC"
fi

# 3.b — list --expired shows KAM-3-quick
LIST_OUT=$(node "$LIST" --expired)
if echo "$LIST_OUT" | grep -q "KAM-3-quick"; then
  pass "3.b list --expired surfaces stale marker"
else
  fail "3.b list expired" "$LIST_OUT"
fi

# 3.c — revoke --all-expired cleans up
REVOKE_OUT=$(node "$REVOKE" --all-expired)
if echo "$REVOKE_OUT" | grep -q "revoked: KAM-3-quick"; then
  pass "3.c revoke --all-expired bulk-cleanup"
else
  fail "3.c bulk revoke" "$REVOKE_OUT"
fi

# 3.d — list --active is empty
LIST_OUT=$(node "$LIST" --active)
if echo "$LIST_OUT" | grep -q "no approvals"; then
  pass "3.d after cleanup, no active approvals"
else
  fail "3.d active state" "$LIST_OUT"
fi

# ── Group 4: AEGIS_BYPASS + audit ───────────────────────────────────────
echo ""
echo "--- Group 4: AEGIS_BYPASS + audit log ---"

# 4.a — AEGIS_BYPASS=1 lets destructive op through
RC=0
PAYLOAD='{"tool_name":"Bash","tool_input":{"command":"rm -rf /tmp/y"}}'
printf '%s' "$PAYLOAD" | AEGIS_BYPASS=1 node "$CHECK" >/dev/null 2>&1 || RC=$?
if [[ "$RC" == "0" ]]; then
  pass "4.a AEGIS_BYPASS=1 → exit 0 (override always wins)"
else
  fail "4.a bypass" "rc=$RC"
fi

# 4.b — audit log captured the block + bypass + revoke trail
AUDIT="$TEST_DIR/.aegis/brain/logs/approval-audit.log"
if [[ -f "$AUDIT" ]] && grep -q '"decision":"block"' "$AUDIT" && grep -q '"decision":"bypass"' "$AUDIT"; then
  pass "4.b audit log records block + bypass decisions"
else
  fail "4.b audit content" "$(cat "$AUDIT" 2>/dev/null | tail -10)"
fi

# 4.c — fail-OPEN on garbage stdin (Risk R6)
RC=0
echo "not json at all" | node "$CHECK" >/dev/null 2>&1 || RC=$?
if [[ "$RC" == "0" ]]; then
  pass "4.c garbage stdin → exit 0 (fail-OPEN on internal error)"
else
  fail "4.c fail-open" "rc=$RC"
fi

# ── Group 5: latency budget ─────────────────────────────────────────────
echo ""
echo "--- Group 5: latency p95 ---"

# 5.a — p95 over 30 invocations stays under 200ms (matches v11-01 budget)
LAT_FILE="$TEST_DIR/lat.txt"
: > "$LAT_FILE"
for i in $(seq 1 30); do
  T0=$(node -e 'process.stdout.write(String(Date.now()))')
  printf '%s' "$PAYLOAD" | AEGIS_BYPASS=1 node "$CHECK" >/dev/null 2>&1
  T1=$(node -e 'process.stdout.write(String(Date.now()))')
  echo $((T1 - T0)) >> "$LAT_FILE"
done
P95=$(sort -n "$LAT_FILE" | awk 'BEGIN{c=0}{a[NR]=$0;c=NR}END{print a[int(c*0.95+0.5)]}')
if [[ "$P95" -lt 200 ]]; then
  pass "5.a check.mjs p95 = ${P95}ms (<200ms)"
else
  fail "5.a latency" "got ${P95}ms"
fi

# ── Group 6: list/grant CLI shape ───────────────────────────────────────
echo ""
echo "--- Group 6: CLI shape ---"

# 6.a — grant requires --task
RC=0
node "$GRANT" --action x --scope rule:rm-rf >/dev/null 2>&1 || RC=$?
if [[ "$RC" == "2" ]]; then
  pass "6.a grant rejects missing --task"
else
  fail "6.a missing-task validation" "rc=$RC"
fi

# 6.b — grant requires --scope
RC=0
node "$GRANT" --task X --action y >/dev/null 2>&1 || RC=$?
if [[ "$RC" == "2" ]]; then
  pass "6.b grant rejects missing --scope"
else
  fail "6.b missing-scope" "rc=$RC"
fi

# 6.c — list --json produces valid JSON
node "$GRANT" --task KAM-9 --action smoke --scope rule:rm-rf --ttl 1h --by tester >/dev/null
JSON=$(node "$LIST" --json)
if echo "$JSON" | node -e 'const a=JSON.parse(require("fs").readFileSync(0,"utf8")); if(!Array.isArray(a)) process.exit(1); if(a.length<1) process.exit(1); console.log("ok")' 2>/dev/null; then
  pass "6.c list --json valid array"
else
  fail "6.c json shape" "$JSON"
fi

# 6.d — revoke unknown id exits 2
RC=0
node "$REVOKE" KAM-DOESNOTEXIST >/dev/null 2>&1 || RC=$?
if [[ "$RC" == "2" ]]; then
  pass "6.d revoke unknown id → exit 2"
else
  fail "6.d unknown revoke" "rc=$RC"
fi

echo ""
echo "============================================"
echo "RESULTS: ${PASS} passed, ${FAIL} failed"
echo "============================================"
[[ $FAIL -eq 0 ]] && { echo -e "${GREEN}ALL PASSED${NC}"; exit 0; } || { echo -e "${RED}FAILURES${NC}"; exit 1; }
