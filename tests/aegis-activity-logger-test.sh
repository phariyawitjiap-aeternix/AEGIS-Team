#!/usr/bin/env bash
# aegis-activity-logger-test.sh — Sprint v11-02 acceptance + regression test

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LOG_MJS="${REPO_ROOT}/tools/aegis-activity-logger/log.mjs"
VIEW_MJS="${REPO_ROOT}/tools/aegis-activity-logger/view.mjs"
STATS_MJS="${REPO_ROOT}/tools/aegis-activity-logger/stats.mjs"

for f in "$LOG_MJS" "$VIEW_MJS" "$STATS_MJS"; do
  [[ -f "$f" ]] || { echo "FATAL: missing $f" >&2; exit 2; }
done
command -v node >/dev/null 2>&1 || { echo "FATAL: node not found" >&2; exit 2; }

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
PASS=0; FAIL=0
pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}FAIL${NC}: $1 -- $2"; FAIL=$((FAIL+1)); }

TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/aegis-activity-logger-XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT INT TERM
export CLAUDE_PROJECT_DIR="$TEST_DIR"
ACTIVITY_DIR="$TEST_DIR/.aegis/brain/activity"

echo "============================================"
echo "AEGIS activity-logger — sprint v11-02 acceptance"
echo "============================================"

# ── Group 1: log.mjs writes one JSONL line per hook call ─────────────────
echo ""
echo "--- Group 1: log.mjs JSONL append ---"

HOOK_EDIT='{"tool_name":"Edit","tool_input":{"file_path":"src/app.ts","old_string":"a\nb","new_string":"a\nb\nc"},"tool_response":{}}'
printf '%s' "$HOOK_EDIT" | AEGIS_PERSONA=spider-man node "$LOG_MJS"

TODAY=$(date -u +%Y-%m-%d)
JSONL="$ACTIVITY_DIR/${TODAY}.jsonl"
if [[ -f "$JSONL" ]] && [[ $(wc -l < "$JSONL" | tr -d ' ') -ge 1 ]]; then
  pass "1.a Edit hook wrote one line to $TODAY.jsonl"
else
  fail "1.a JSONL append" "no file or empty: $(ls -la "$ACTIVITY_DIR" 2>&1)"
fi

# 1.b — line is valid JSON with required fields
LINE=$(head -1 "$JSONL" 2>/dev/null || echo "")
if echo "$LINE" | node -e '
  const buf = require("fs").readFileSync(0, "utf8").trim();
  const r = JSON.parse(buf);
  const need = ["ts","tool","target","persona","status"];
  const missing = need.filter(k => !(k in r));
  if (missing.length) { console.error("missing: "+missing.join(",")); process.exit(1); }
  if (r.tool !== "Edit") { console.error("tool="+r.tool); process.exit(1); }
  if (r.target !== "src/app.ts") { console.error("target="+r.target); process.exit(1); }
  if (r.persona !== "spider-man") { console.error("persona="+r.persona); process.exit(1); }
'; then
  pass "1.b record has required fields with correct values"
else
  fail "1.b record schema" "line=$LINE"
fi

# 1.c — Bash hook also logged
HOOK_BASH='{"tool_name":"Bash","tool_input":{"command":"npm test"},"tool_response":{}}'
printf '%s' "$HOOK_BASH" | AEGIS_PERSONA=war-machine node "$LOG_MJS"
LINES=$(wc -l < "$JSONL" | tr -d ' ')
if [[ "$LINES" -eq 2 ]]; then
  pass "1.c Bash hook appended (2 lines total)"
else
  fail "1.c Bash append" "expected 2 lines got $LINES"
fi

# 1.d — fail-open on missing tool_name
GARBAGE_OUT="$TEST_DIR/g.out"
if echo "garbage not json" | node "$LOG_MJS" >"$GARBAGE_OUT" 2>&1; then
  pass "1.d log.mjs exits 0 on garbage stdin"
else
  fail "1.d garbage stdin" "exit=$? out=$(cat "$GARBAGE_OUT")"
fi

# 1.e — latency p95 <200ms (matches v11-01 acceptance)
# Run in an isolated tmpdir so the 30 sample records don't pollute later
# filter-test assertions on the main TEST_DIR.
LAT_DIR=$(mktemp -d "${TMPDIR:-/tmp}/aegis-act-lat-XXXXXX")
mkdir -p "$LAT_DIR/.aegis/brain/activity"
: > "$LAT_DIR/lat.txt"
for i in $(seq 1 30); do
  T0=$(node -e 'process.stdout.write(String(Date.now()))')
  printf '%s' "$HOOK_BASH" | CLAUDE_PROJECT_DIR="$LAT_DIR" node "$LOG_MJS"
  T1=$(node -e 'process.stdout.write(String(Date.now()))')
  echo $((T1 - T0)) >> "$LAT_DIR/lat.txt"
done
P95=$(sort -n "$LAT_DIR/lat.txt" | awk 'BEGIN{c=0}{a[NR]=$0;c=NR}END{print a[int(c*0.95+0.5)]}')
rm -rf "$LAT_DIR"
if [[ "$P95" -lt 200 ]]; then
  pass "1.e log.mjs p95 = ${P95}ms (<200ms)"
else
  fail "1.e log.mjs p95" "got ${P95}ms"
fi

# ── Group 2: view.mjs filters ────────────────────────────────────────────
echo ""
echo "--- Group 2: view.mjs filters ---"

# 2.a --today shows lines
OUT_2A=$(node "$VIEW_MJS" --today 2>&1)
if echo "$OUT_2A" | grep -q "src/app.ts"; then
  pass "2.a --today shows the Edit line"
else
  fail "2.a --today" "out=$OUT_2A"
fi

# 2.b --tool Edit filters out Bash
OUT_2B=$(node "$VIEW_MJS" --today --tool Edit 2>&1)
if echo "$OUT_2B" | grep -q "src/app.ts" && ! echo "$OUT_2B" | grep -q "npm test"; then
  pass "2.b --tool Edit excludes Bash"
else
  fail "2.b --tool filter" "out=$OUT_2B"
fi

# 2.c --persona war-machine includes only Bash
OUT_2C=$(node "$VIEW_MJS" --today --persona war-machine 2>&1)
if echo "$OUT_2C" | grep -q "npm test" && ! echo "$OUT_2C" | grep -q "src/app.ts"; then
  pass "2.c --persona filter (war-machine → Bash only)"
else
  fail "2.c --persona filter" "out=$OUT_2C"
fi

# 2.d --json emits machine-readable
OUT_2D=$(node "$VIEW_MJS" --today --tool Edit --json 2>&1)
if echo "$OUT_2D" | head -1 | node -e 'JSON.parse(require("fs").readFileSync(0,"utf8")); console.log("ok")' 2>/dev/null; then
  pass "2.d --json output is valid JSON"
else
  fail "2.d --json validity" "first line: $(echo "$OUT_2D" | head -1)"
fi

# 2.e --limit 1 returns exactly 1 line
OUT_2E=$(node "$VIEW_MJS" --today --limit 1 2>&1 | wc -l | tr -d ' ')
if [[ "$OUT_2E" -eq 1 ]]; then
  pass "2.e --limit 1 returns exactly 1 line"
else
  fail "2.e --limit" "got $OUT_2E lines"
fi

# ── Group 3: stats.mjs aggregation ───────────────────────────────────────
echo ""
echo "--- Group 3: stats.mjs ---"

# Add a few more events for richer stats
for i in 1 2 3; do printf '%s' "$HOOK_EDIT" | AEGIS_PERSONA=spider-man node "$LOG_MJS"; done

# 3.a default (day+tool grid)
OUT_3A=$(node "$STATS_MJS" 2>&1)
if echo "$OUT_3A" | grep -q "Edit" && echo "$OUT_3A" | grep -q "Bash" && echo "$OUT_3A" | grep -q "total:"; then
  pass "3.a default day+tool grid shows Edit + Bash + total"
else
  fail "3.a default stats" "out=$OUT_3A"
fi

# 3.b --by tool
OUT_3B=$(node "$STATS_MJS" --by tool 2>&1)
if echo "$OUT_3B" | grep -qE "^Edit\s+[0-9]+"; then
  pass "3.b --by tool aggregates by tool"
else
  fail "3.b --by tool" "out=$OUT_3B"
fi

# 3.c --by persona
OUT_3C=$(node "$STATS_MJS" --by persona 2>&1)
if echo "$OUT_3C" | grep -q "spider-man" && echo "$OUT_3C" | grep -q "war-machine"; then
  pass "3.c --by persona shows both personas"
else
  fail "3.c --by persona" "out=$OUT_3C"
fi

# 3.d --json
OUT_3D=$(node "$STATS_MJS" --json 2>&1)
if echo "$OUT_3D" | node -e 'const o = JSON.parse(require("fs").readFileSync(0,"utf8")); if(typeof o.total!=="number") process.exit(1); console.log("ok")' 2>/dev/null; then
  pass "3.d --json valid"
else
  fail "3.d --json" "out=$OUT_3D"
fi

# 3.e --today flag (regression — wasn't accepted in original ship; guide
# instructions said `stats --today` but stats only had --week/--month/--since)
OUT_3E=$(node "$STATS_MJS" --today 2>&1)
if echo "$OUT_3E" | grep -qE "unknown flag|Unknown"; then
  fail "3.e --today flag" "rejected: $OUT_3E"
else
  pass "3.e --today flag accepted"
fi

# ── Group 4: end-to-end ───────────────────────────────────────────────────
echo ""
echo "--- Group 4: end-to-end ---"

# 4.a — 10 hook fires produce 10 (or close, race-tolerant) lines visible
rm -f "$JSONL"
for i in $(seq 1 10); do
  printf '%s' "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"src/file-${i}.ts\"}}" | AEGIS_PERSONA=spider-man node "$LOG_MJS"
done
COUNT=$(wc -l < "$JSONL" | tr -d ' ')
if [[ "$COUNT" -eq 10 ]]; then
  pass "4.a 10 hooks → 10 JSONL lines"
else
  fail "4.a end-to-end count" "got $COUNT/10"
fi

# 4.b — view --today --limit 100 returns 10 lines
OUT_4B=$(node "$VIEW_MJS" --today --limit 100 2>&1 | wc -l | tr -d ' ')
if [[ "$OUT_4B" -eq 10 ]]; then
  pass "4.b view --today reads 10 lines"
else
  fail "4.b view roundtrip" "got $OUT_4B/10"
fi

echo ""
echo "============================================"
echo "RESULTS: ${PASS} passed, ${FAIL} failed"
echo "============================================"
[[ $FAIL -eq 0 ]] && { echo -e "${GREEN}ALL PASSED${NC}"; exit 0; } || { echo -e "${RED}FAILURES${NC}"; exit 1; }
