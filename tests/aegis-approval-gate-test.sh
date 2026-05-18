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

# Helper: feed a Bash hook payload to check.mjs and capture an
# *implementation-agnostic* "blocked" verdict + a context string.
#
# v15-15 background: default mode is now JSON-only (exit 0 +
# `hookSpecificOutput.permissionDecision: "deny"` on stdout). Tests can no
# longer rely solely on `rc == 2` to detect a block — they must inspect
# the JSON. This helper returns:
#
#   line 1: "2" if blocked (legacy semantic preserved for existing tests)
#           "0" if allowed
#   line 2: combined stderr + JSON-reason text, so existing grep checks
#           against "BLOCKED" / rule names still pass against the
#           permissionDecisionReason payload.
run_check() {
  local cmd="$1"
  local payload
  payload="$(node -e "process.stdout.write(JSON.stringify({tool_name:'Bash',tool_input:{command:process.argv[1]}}))" "$cmd")"
  local rc=0
  local stdout stderr
  stdout=$(printf '%s' "$payload" | node "$CHECK" 2>/tmp/aegis-rc-err) || rc=$?
  stderr=$(cat /tmp/aegis-rc-err 2>/dev/null || true)
  rm -f /tmp/aegis-rc-err

  # Implementation-agnostic block detection:
  #   - legacy mode: rc != 0 OR stderr contains "BLOCKED"
  #   - modern mode: stdout JSON has `permissionDecision: "deny"`
  local blocked=0
  if [[ "$rc" -ne 0 ]]; then
    blocked=1
  elif echo "$stdout" | grep -q '"permissionDecision":"deny"'; then
    blocked=1
  fi

  # Emit legacy-shape return so existing tests still work:
  #   rc=2 = blocked, rc=0 = allowed (matches old contract)
  if [[ "$blocked" == "1" ]]; then
    echo "2"
  else
    echo "0"
  fi
  # Pass BOTH stderr and the JSON reason through, joined, so existing
  # `grep "BLOCKED"` / `grep "<rule>"` assertions still match.
  printf '%s\n%s\n' "$stderr" "$stdout"
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

# ── Group 7: v15-09 CC 2.1.141 permission-dialog schema ─────────────────
echo ""
echo "--- Group 7: CC 2.1.141 permission-dialog JSON ---"

# Earlier groups left active approvals in TEST_DIR (KAM-9 covers rule:rm-rf).
# Wipe them so the v15-09 JSON-emission assertions see a clean block path.
# Approvals are YAML files per .aegis/brain/approvals/<TASK>-<ACTION>.yaml.
find "$TEST_DIR/.aegis/brain/approvals" -maxdepth 1 -type f -name '*.yaml' -delete 2>/dev/null

# Helper: capture stdout (not stderr) from check.mjs for a blocked command.
capture_check_stdout() {
  local cmd="$1"
  local payload
  payload="$(node -e "process.stdout.write(JSON.stringify({tool_name:'Bash',tool_input:{command:process.argv[1]}}))" "$cmd")"
  printf '%s' "$payload" | node "$CHECK" 2>/dev/null
}

# 7.a — block emits hookSpecificOutput JSON to stdout (default mode)
JSON_OUT=$(capture_check_stdout 'rm -rf /tmp/cc141-test')
if echo "$JSON_OUT" | node -e '
  const d = JSON.parse(require("fs").readFileSync(0,"utf8"));
  if (!d.hookSpecificOutput) process.exit(1);
  if (d.hookSpecificOutput.hookEventName !== "PreToolUse") process.exit(1);
  if (d.hookSpecificOutput.permissionDecision !== "deny") process.exit(1);
  if (typeof d.hookSpecificOutput.permissionDecisionReason !== "string") process.exit(1);
  if (!/aegis-approval-gate/.test(d.hookSpecificOutput.permissionDecisionReason)) process.exit(1);
' 2>/dev/null; then
  pass "7.a block → CC 2.1.141 hookSpecificOutput JSON on stdout"
else
  fail "7.a schema JSON" "got: ${JSON_OUT:0:200}"
fi

# 7.b — v15-15: AEGIS_APPROVAL_GATE_LEGACY=1 ALSO writes stderr + exits 2
# (dual-path for older CC); stdout JSON is still emitted alongside.
LEGACY_STDOUT=$(
  payload="$(node -e "process.stdout.write(JSON.stringify({tool_name:'Bash',tool_input:{command:'rm -rf /tmp/legacy'}}))")"
  printf '%s' "$payload" | AEGIS_APPROVAL_GATE_LEGACY=1 node "$CHECK" 2>/dev/null
)
LEGACY_RC=0
payload="$(node -e "process.stdout.write(JSON.stringify({tool_name:'Bash',tool_input:{command:'rm -rf /tmp/legacy'}}))")"
printf '%s' "$payload" | AEGIS_APPROVAL_GATE_LEGACY=1 node "$CHECK" >/dev/null 2>&1 || LEGACY_RC=$?
if echo "$LEGACY_STDOUT" | grep -q '"permissionDecision":"deny"' && [[ "$LEGACY_RC" == "2" ]]; then
  pass "7.b AEGIS_APPROVAL_GATE_LEGACY=1 → JSON on stdout + exit 2 (dual path)"
else
  fail "7.b legacy mode" "stdout_has_json=$(echo "$LEGACY_STDOUT" | grep -c deny) rc=$LEGACY_RC"
fi

# 7.c — allow path emits no JSON on stdout (only blocks do)
JSON_OUT=$(capture_check_stdout 'ls -la')
if [[ -z "$JSON_OUT" ]]; then
  pass "7.c allow path → no stdout JSON"
else
  fail "7.c allow JSON leak" "got: ${JSON_OUT:0:200}"
fi

# 7.d — JSON includes matched rule attribution in reason
JSON_OUT=$(capture_check_stdout 'git push --force origin main')
if echo "$JSON_OUT" | node -e '
  const d = JSON.parse(require("fs").readFileSync(0,"utf8"));
  const r = d.hookSpecificOutput.permissionDecisionReason;
  if (!/rule\(s\):/.test(r)) process.exit(1);
  if (!/force-push|git-force-push|push/.test(r)) process.exit(1);
' 2>/dev/null; then
  pass "7.d JSON reason includes matched rule attribution"
else
  fail "7.d rule attribution" "got: ${JSON_OUT:0:200}"
fi

# 7.e — v15-15: default modern mode now exits 0 + emits JSON deny
# (no more stderr+exit-2 dual signal that CC interpreted as "Bash hook
# error"). Legacy mode still exits 2 for older CC compatibility.
RC=0
payload='{"tool_name":"Bash","tool_input":{"command":"rm -rf /tmp/rc"}}'
printf '%s' "$payload" | node "$CHECK" >/dev/null 2>&1 || RC=$?
RC_LEGACY=0
printf '%s' "$payload" | AEGIS_APPROVAL_GATE_LEGACY=1 node "$CHECK" >/dev/null 2>&1 || RC_LEGACY=$?
if [[ "$RC" == "0" && "$RC_LEGACY" == "2" ]]; then
  pass "7.e modern=exit 0, legacy=exit 2 (no more 'hook error' label on modern CC)"
else
  fail "7.e exit code matrix" "modern=$RC (expected 0) legacy=$RC_LEGACY (expected 2)"
fi

# 7.f — v15-15: default modern block emits NO stderr (the key fix —
# stderr+exit-2 was what made CC label the block as "Bash hook error").
STDERR_OUT=$(
  payload="$(node -e "process.stdout.write(JSON.stringify({tool_name:'Bash',tool_input:{command:'rm -rf /tmp/no-stderr'}}))")"
  printf '%s' "$payload" | node "$CHECK" 2>&1 >/dev/null
)
if [[ -z "$STDERR_OUT" ]]; then
  pass "7.f modern block emits NO stderr — no more 'hook error' label"
else
  fail "7.f stderr leak" "expected empty, got: ${STDERR_OUT:0:120}"
fi

echo ""
echo "============================================"
echo "RESULTS: ${PASS} passed, ${FAIL} failed"
echo "============================================"
[[ $FAIL -eq 0 ]] && { echo -e "${GREEN}ALL PASSED${NC}"; exit 0; } || { echo -e "${RED}FAILURES${NC}"; exit 1; }
