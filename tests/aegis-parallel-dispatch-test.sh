#!/usr/bin/env bash
# aegis-parallel-dispatch-test.sh — Sprint v11-04 acceptance + regression test

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DISPATCH="${REPO_ROOT}/tools/aegis-parallel-dispatch/dispatch.mjs"
SKILL="${REPO_ROOT}/skills/aegis-parallel-dispatch.md"
EXAMPLE="${REPO_ROOT}/tools/aegis-parallel-dispatch/examples/parallel-review.md"

for f in "$DISPATCH" "$SKILL" "$EXAMPLE"; do
  [[ -f "$f" ]] || { echo "FATAL: missing $f" >&2; exit 2; }
done
command -v node >/dev/null 2>&1 || { echo "FATAL: node missing" >&2; exit 2; }

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
PASS=0; FAIL=0
pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}FAIL${NC}: $1 -- $2"; FAIL=$((FAIL+1)); }

TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/aegis-parallel-dispatch-XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT INT TERM

echo "============================================"
echo "AEGIS parallel-dispatch — sprint v11-04 acceptance"
echo "============================================"

# ── Group 1: dispatch.mjs core behavior ─────────────────────────────────
echo ""
echo "--- Group 1: dispatch.mjs ---"

# 1.a — 3-task manifest produces 3 Agent stubs
cat > "$TEST_DIR/m3.json" <<'JSON'
{
  "topic": "review PR #142",
  "agent_type": "code-reviewer",
  "tasks": [
    {"description": "security review", "prompt": "OWASP top-10"},
    {"description": "perf review",     "prompt": "N+1 / hot loops"},
    {"description": "style review",    "prompt": "Style compliance"}
  ]
}
JSON
OUT_1A=$(node "$DISPATCH" --file "$TEST_DIR/m3.json")
AGENT_COUNT=$(echo "$OUT_1A" | grep -cE '^Agent\(\{' || true)
if [[ "$AGENT_COUNT" -eq 3 ]]; then
  pass "1.a 3-task manifest → 3 Agent stubs"
else
  fail "1.a Agent stub count" "got $AGENT_COUNT (expected 3)"
fi

# 1.b — output includes the aggregation table
if echo "$OUT_1A" | grep -q "Result aggregation" \
   && echo "$OUT_1A" | grep -q "| # | Task | Result | Key finding |"; then
  pass "1.b output includes aggregation table"
else
  fail "1.b aggregation" "out: $(echo "$OUT_1A" | head -3)"
fi

# 1.c — header includes topic + agent type
if echo "$OUT_1A" | grep -q "Parallel dispatch plan: review PR #142" \
   && echo "$OUT_1A" | grep -q "code-reviewer"; then
  pass "1.c header has topic + agent_type"
else
  fail "1.c header" "out: $(echo "$OUT_1A" | head -10)"
fi

# 1.d — 5-task manifest (boundary): allowed
cat > "$TEST_DIR/m5.json" <<'JSON'
{"topic":"5","tasks":[
  {"description":"a","prompt":"a"},
  {"description":"b","prompt":"b"},
  {"description":"c","prompt":"c"},
  {"description":"d","prompt":"d"},
  {"description":"e","prompt":"e"}
]}
JSON
if node "$DISPATCH" --file "$TEST_DIR/m5.json" >/dev/null 2>&1; then
  pass "1.d 5-task manifest accepted (boundary)"
else
  fail "1.d boundary" "5 tasks rejected"
fi

# 1.e — 6-task manifest rejected without --force
cat > "$TEST_DIR/m6.json" <<'JSON'
{"topic":"6","tasks":[
  {"description":"a","prompt":"a"},
  {"description":"b","prompt":"b"},
  {"description":"c","prompt":"c"},
  {"description":"d","prompt":"d"},
  {"description":"e","prompt":"e"},
  {"description":"f","prompt":"f"}
]}
JSON
ERR_1E="$TEST_DIR/m6.err"
if node "$DISPATCH" --file "$TEST_DIR/m6.json" >/dev/null 2>"$ERR_1E"; then
  fail "1.e 6-task cap" "should reject without --force"
else
  if grep -qE "exceeds.*5" "$ERR_1E"; then
    pass "1.e 6-task manifest rejected, error explains cap"
  else
    fail "1.e cap msg" "stderr: $(cat "$ERR_1E")"
  fi
fi

# 1.f — 6-task accepted with --force
if node "$DISPATCH" --file "$TEST_DIR/m6.json" --force >/dev/null 2>&1; then
  pass "1.f --force overrides 5-cap"
else
  fail "1.f --force" "should accept with --force"
fi

# 1.g — empty tasks rejected
echo '{"topic":"x","tasks":[]}' > "$TEST_DIR/empty.json"
if node "$DISPATCH" --file "$TEST_DIR/empty.json" >/dev/null 2>&1; then
  fail "1.g empty tasks" "should reject"
else
  pass "1.g empty tasks[] rejected"
fi

# 1.h — invalid JSON rejected
echo "not json at all" > "$TEST_DIR/bad.json"
if node "$DISPATCH" --file "$TEST_DIR/bad.json" >/dev/null 2>&1; then
  fail "1.h bad json" "should reject"
else
  pass "1.h invalid JSON rejected"
fi

# 1.i — task missing description rejected
echo '{"tasks":[{"prompt":"only prompt"}]}' > "$TEST_DIR/badtask.json"
if node "$DISPATCH" --file "$TEST_DIR/badtask.json" >/dev/null 2>&1; then
  fail "1.i missing desc" "should reject"
else
  pass "1.i task without description rejected"
fi

# 1.j — --json output is valid JSON with N tasks
OUT_1J=$(node "$DISPATCH" --file "$TEST_DIR/m3.json" --json)
if echo "$OUT_1J" | node -e '
  const o = JSON.parse(require("fs").readFileSync(0,"utf8"));
  if (!Array.isArray(o.tasks) || o.tasks.length !== 3) process.exit(1);
  if (o.tasks[0].subagent_type !== "code-reviewer") process.exit(1);
  console.log("ok");
' 2>/dev/null; then
  pass "1.j --json output valid + 3 tasks + agent_type propagated"
else
  fail "1.j json output" "out=$OUT_1J"
fi

# 1.k — manifest from stdin works (not just --file)
OUT_1K=$(cat "$TEST_DIR/m3.json" | node "$DISPATCH")
if echo "$OUT_1K" | grep -qE '^Agent\(\{'; then
  pass "1.k stdin manifest works"
else
  fail "1.k stdin" "out=$OUT_1K"
fi

# ── Group 2: SKILL.md content acceptance ────────────────────────────────
echo ""
echo "--- Group 2: skill content ---"

# 2.a — SKILL.md mentions ≥3 worked examples (acceptance criterion)
EXAMPLE_BLOCKS=$(grep -c "^### [0-9]" "$SKILL")
if [[ "$EXAMPLE_BLOCKS" -ge 3 ]]; then
  pass "2.a SKILL.md has $EXAMPLE_BLOCKS worked examples (≥3 required)"
else
  fail "2.a worked examples" "got $EXAMPLE_BLOCKS, need 3"
fi

# 2.b — SKILL.md documents the aggregation pattern
if grep -q "Aggregation table" "$SKILL" || grep -q "aggregation table" "$SKILL"; then
  pass "2.b aggregation pattern documented"
else
  fail "2.b aggregation doc" "missing aggregation section"
fi

# 2.c — SKILL.md states the 5-cap
if grep -qE "[Hh]ard cap.*5|5[- ]concurrent|cap = 5" "$SKILL"; then
  pass "2.c 5-cap stated in SKILL.md"
else
  fail "2.c cap doc" "missing 5-cap mention"
fi

# 2.d — bilingual triggers (EN + TH)
if grep -qE "ทำพร้อมกัน|กระจายงาน" "$SKILL" && grep -q "fan out" "$SKILL"; then
  pass "2.d bilingual EN+TH triggers"
else
  fail "2.d triggers" "missing one language"
fi

# 2.e — example file exists with non-trivial content
if [[ $(wc -l < "$EXAMPLE" | tr -d ' ') -ge 30 ]]; then
  pass "2.e example file has substantive content"
else
  fail "2.e example size" "only $(wc -l < "$EXAMPLE") lines"
fi

echo ""
echo "============================================"
echo "RESULTS: ${PASS} passed, ${FAIL} failed"
echo "============================================"
[[ $FAIL -eq 0 ]] && { echo -e "${GREEN}ALL PASSED${NC}"; exit 0; } || { echo -e "${RED}FAILURES${NC}"; exit 1; }
