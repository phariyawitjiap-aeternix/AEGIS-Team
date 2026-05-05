#!/usr/bin/env bash
# aegis-run-logger-test.sh — Sprint v11-07 acceptance + regression test

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ARCHIVE="${REPO_ROOT}/tools/aegis-run-logger/archive.mjs"
REPLAY="${REPO_ROOT}/tools/aegis-run-logger/replay.mjs"
LIST="${REPO_ROOT}/tools/aegis-run-logger/list.mjs"

for f in "$ARCHIVE" "$REPLAY" "$LIST"; do
  [[ -f "$f" ]] || { echo "FATAL: missing $f" >&2; exit 2; }
done
command -v node >/dev/null 2>&1 || { echo "FATAL: node missing" >&2; exit 2; }

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
PASS=0; FAIL=0
pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}FAIL${NC}: $1 -- $2"; FAIL=$((FAIL+1)); }

TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/aegis-run-logger-XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT INT TERM
export CLAUDE_PROJECT_DIR="$TEST_DIR"

# Build a fake transcript.
TRANSCRIPT="$TEST_DIR/fake-transcript.ndjson"
cat > "$TRANSCRIPT" <<'JSON'
{"role":"user","content":"hello"}
{"role":"assistant","content":"hi back"}
{"type":"tool_use","tool_name":"Bash","tool_input":{"command":"ls"}}
{"role":"assistant","content":"done"}
JSON

echo "============================================"
echo "AEGIS run-logger — sprint v11-07 acceptance"
echo "============================================"

# ── Group 1: archive happy path ─────────────────────────────────────────
echo ""
echo "--- Group 1: archive ---"

# 1.a — archive copies transcript + writes meta.json
PAYLOAD="{\"session_id\":\"abc123def\",\"transcript_path\":\"$TRANSCRIPT\",\"stop_hook_active\":false}"
printf '%s' "$PAYLOAD" | AEGIS_PERSONA=spider-man node "$ARCHIVE"

TODAY=$(date -u +%Y-%m-%d)
RUN_DIR="$TEST_DIR/.aegis/brain/runs/${TODAY}-abc123def"
if [[ -d "$RUN_DIR" ]]; then
  pass "1.a archive created run directory"
else
  fail "1.a run dir" "$(ls "$TEST_DIR/.aegis/brain/runs/" 2>&1)"
fi

if [[ -f "$RUN_DIR/transcript.ndjson" ]] && grep -q "hello" "$RUN_DIR/transcript.ndjson"; then
  pass "1.b transcript copied verbatim"
else
  fail "1.b transcript" "$(cat "$RUN_DIR/transcript.ndjson" 2>&1)"
fi

if [[ -f "$RUN_DIR/meta.json" ]]; then
  if node -e "const o=JSON.parse(require('fs').readFileSync('$RUN_DIR/meta.json','utf8')); if(o.session_id!=='abc123def') process.exit(1); if(o.persona!=='spider-man') process.exit(1); if(typeof o.transcript_lines!=='number') process.exit(1); console.log('ok');" 2>/dev/null; then
    pass "1.c meta.json has required fields with correct values"
  else
    fail "1.c meta values" "$(cat "$RUN_DIR/meta.json")"
  fi
else
  fail "1.c meta exists" "missing"
fi

# 1.d — costUsd intentionally omitted (Mega Plan v1.1)
if grep -q "costUsd" "$RUN_DIR/meta.json"; then
  fail "1.d no-cost-tracking" "meta.json contains costUsd field"
else
  pass "1.d meta.json does NOT contain costUsd (per v1.1)"
fi

# 1.e — archive on missing transcript — still creates dir+meta, lines=0
PAYLOAD2='{"session_id":"emptysess","transcript_path":"/does/not/exist","stop_hook_active":false}'
printf '%s' "$PAYLOAD2" | AEGIS_PERSONA=loki node "$ARCHIVE"
RUN_DIR2="$TEST_DIR/.aegis/brain/runs/${TODAY}-emptysess"
if [[ -f "$RUN_DIR2/meta.json" ]] && ! [[ -f "$RUN_DIR2/transcript.ndjson" ]]; then
  pass "1.e missing transcript path → meta-only archive (no crash)"
else
  fail "1.e missing transcript" "$(ls "$RUN_DIR2" 2>&1)"
fi

# 1.f — fail-OPEN on garbage stdin (Risk R6)
RC=0
echo "garbage not json" | node "$ARCHIVE" >/dev/null 2>&1 || RC=$?
if [[ "$RC" == "0" ]]; then
  pass "1.f garbage stdin → exit 0 (fail-OPEN)"
else
  fail "1.f fail-open" "rc=$RC"
fi

# ── Group 2: replay ─────────────────────────────────────────────────────
echo ""
echo "--- Group 2: replay ---"

# 2.a — replay with explicit ID renders both header + content
OUT=$(node "$REPLAY" "${TODAY}-abc123def")
if echo "$OUT" | grep -q "run: ${TODAY}-abc123def" && echo "$OUT" | grep -q "hello" && echo "$OUT" | grep -q "hi back"; then
  pass "2.a replay <id> renders header + transcript"
else
  fail "2.a replay" "out=$OUT"
fi

# 2.b — --latest picks the most recent
OUT=$(node "$REPLAY" --latest)
if echo "$OUT" | grep -qE "run: ${TODAY}-(emptysess|abc123def)"; then
  pass "2.b --latest picks most recent run"
else
  fail "2.b --latest" "out=$OUT"
fi

# 2.c — --raw outputs NDJSON
OUT=$(node "$REPLAY" --raw "${TODAY}-abc123def")
if echo "$OUT" | head -1 | node -e 'JSON.parse(require("fs").readFileSync(0,"utf8")); console.log("ok")' 2>/dev/null; then
  pass "2.c --raw produces valid NDJSON first line"
else
  fail "2.c --raw" "first=$(echo "$OUT" | head -1)"
fi

# 2.d — non-existent ID exits 2
RC=0
node "$REPLAY" 2026-99-99-DOESNOTEXIST >/dev/null 2>&1 || RC=$?
if [[ "$RC" == "2" ]]; then
  pass "2.d unknown run-id → exit 2"
else
  fail "2.d unknown id" "rc=$RC"
fi

# ── Group 3: list ───────────────────────────────────────────────────────
echo ""
echo "--- Group 3: list ---"

OUT=$(node "$LIST")
if echo "$OUT" | grep -q "${TODAY}-abc123def" && echo "$OUT" | grep -q "${TODAY}-emptysess"; then
  pass "3.a list shows all archived runs"
else
  fail "3.a list" "out=$OUT"
fi

OUT=$(node "$LIST" --persona spider-man)
if echo "$OUT" | grep -q "abc123def" && ! echo "$OUT" | grep -q "emptysess"; then
  pass "3.b --persona filters correctly"
else
  fail "3.b persona filter" "out=$OUT"
fi

OUT=$(node "$LIST" --json)
if echo "$OUT" | node -e 'const a=JSON.parse(require("fs").readFileSync(0,"utf8")); if(!Array.isArray(a)||a.length<2) process.exit(1); console.log("ok")' 2>/dev/null; then
  pass "3.c --json valid array"
else
  fail "3.c json" "out=$OUT"
fi

# 3.d — list rejects unknown flag
RC=0
node "$LIST" --bogus >/dev/null 2>&1 || RC=$?
if [[ "$RC" == "2" ]]; then
  pass "3.d unknown flag → exit 2"
else
  fail "3.d arg validation" "rc=$RC"
fi

echo ""
echo "============================================"
echo "RESULTS: ${PASS} passed, ${FAIL} failed"
echo "============================================"
[[ $FAIL -eq 0 ]] && { echo -e "${GREEN}ALL PASSED${NC}"; exit 0; } || { echo -e "${RED}FAILURES${NC}"; exit 1; }
