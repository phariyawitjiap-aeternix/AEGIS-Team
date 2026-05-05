#!/usr/bin/env bash
# aegis-plus-pilot-test.sh — regression test for the pilot tooling

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BOOTSTRAP="${REPO_ROOT}/tools/aegis-plus-pilot/bootstrap.sh"
EOD="${REPO_ROOT}/tools/aegis-plus-pilot/daily-eod.sh"
GATE="${REPO_ROOT}/tools/aegis-plus-pilot/gate-check.sh"
SKILL="${REPO_ROOT}/skills/aegis-plus-pilot.md"

for f in "$BOOTSTRAP" "$EOD" "$GATE" "$SKILL"; do
  [[ -f "$f" ]] || { echo "FATAL: missing $f" >&2; exit 2; }
done

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
PASS=0; FAIL=0
pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}FAIL${NC}: $1 -- $2"; FAIL=$((FAIL+1)); }

TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/aegis-plus-pilot-XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT INT TERM

echo "============================================"
echo "AEGIS-Plus pilot tooling — regression"
echo "============================================"

# ── Group 1: bash syntax + executability ────────────────────────────────
echo ""
echo "--- Group 1: bash syntax ---"
for f in "$BOOTSTRAP" "$EOD" "$GATE"; do
  if bash -n "$f" 2>"$TEST_DIR/syn.err"; then
    pass "$(basename "$f") bash -n"
  else
    fail "$(basename "$f") syntax" "$(cat "$TEST_DIR/syn.err")"
  fi
done

# ── Group 2: bootstrap.sh refusal paths ─────────────────────────────────
echo ""
echo "--- Group 2: bootstrap refusal paths ---"

# 2.a — refuse self-bootstrap (META into META)
if bash "$BOOTSTRAP" "$REPO_ROOT" >"$TEST_DIR/self.out" 2>&1; then
  fail "2.a self-bootstrap refusal" "should refuse meta→meta"
else
  if grep -qE "refusing to bootstrap meta source" "$TEST_DIR/self.out"; then
    pass "2.a refuses meta source bootstrap into itself"
  else
    fail "2.a refusal msg" "got: $(cat "$TEST_DIR/self.out")"
  fi
fi

# 2.b — missing path arg → exit 2 with usage
if bash "$BOOTSTRAP" >"$TEST_DIR/usage.out" 2>&1; then
  fail "2.b missing arg" "should exit non-zero"
else
  RC=$?
  if [[ $RC -eq 2 ]] && grep -q "usage:" "$TEST_DIR/usage.out"; then
    pass "2.b missing arg → usage + exit 2"
  else
    fail "2.b missing arg" "rc=$RC out=$(cat "$TEST_DIR/usage.out")"
  fi
fi

# 2.c — non-existent path → exit 1
if bash "$BOOTSTRAP" "$TEST_DIR/does-not-exist" >"$TEST_DIR/missing.out" 2>&1; then
  fail "2.c missing target" "should reject"
else
  pass "2.c non-existent target rejected"
fi

# ── Group 3: daily-eod fail-soft when activity tools missing ────────────
echo ""
echo "--- Group 3: daily-eod fail-soft ---"
PILOT="$TEST_DIR/pilot"
mkdir -p "$PILOT/.aegis/brain/memory"
touch "$PILOT/.aegis/brain/memory/aegis-plus-feedback.md"
EOD_OUT="$TEST_DIR/eod.out"
bash "$EOD" "$PILOT" >"$EOD_OUT" 2>&1 || true
if grep -q "AEGIS-Plus Daily EOD" "$EOD_OUT" && grep -q "view.mjs not yet installed" "$EOD_OUT"; then
  pass "3.a daily-eod prints header + soft-fails missing tools"
else
  fail "3.a daily-eod soft-fail" "out=$(cat "$EOD_OUT" | head -10)"
fi

# 3.b — daily-eod appends friction template (idempotent — once per day)
if grep -q "^## $(date -u +%Y-%m-%d)$" "$PILOT/.aegis/brain/memory/aegis-plus-feedback.md"; then
  pass "3.b friction-log block appended for today"
else
  fail "3.b friction append" "$(cat "$PILOT/.aegis/brain/memory/aegis-plus-feedback.md")"
fi

# 3.c — second invocation does NOT duplicate today's block
bash "$EOD" "$PILOT" >>"$EOD_OUT" 2>&1 || true
COUNT=$(grep -c "^## $(date -u +%Y-%m-%d)$" "$PILOT/.aegis/brain/memory/aegis-plus-feedback.md")
if [[ $COUNT -eq 1 ]]; then
  pass "3.c daily-eod is idempotent (single block per day)"
else
  fail "3.c idempotency" "today block count = $COUNT"
fi

# 3.d — daily-eod rejects non-AEGIS dir
if bash "$EOD" "$TEST_DIR" >/dev/null 2>&1; then
  fail "3.d daily-eod non-aegis" "should reject"
else
  pass "3.d daily-eod rejects non-AEGIS dir"
fi

# ── Group 4: gate-check exit codes ──────────────────────────────────────
echo ""
echo "--- Group 4: gate-check ---"

# Empty pilot — should be GATE HOLD (0/3 signals).
GATE_OUT="$TEST_DIR/gate-empty.out"
if bash "$GATE" "$PILOT" >"$GATE_OUT" 2>&1; then
  fail "4.a empty gate exit" "should be exit 1 (HOLD), got 0"
else
  RC=$?
  if [[ $RC -eq 1 ]] && grep -q "GATE HOLD" "$GATE_OUT"; then
    pass "4.a empty pilot → GATE HOLD (exit 1)"
  else
    fail "4.a empty gate" "rc=$RC out=$(cat "$GATE_OUT" | tail -10)"
  fi
fi

# 4.a.1 — 0-signals run must not emit "unbound variable" for empty notes[@]
# (regression guard for bash 3.2 set -u empty-array bug)
if grep -qE "unbound variable|notes\[@\]" "$GATE_OUT"; then
  fail "4.a.1 empty-notes guard" "0-signal output leaked 'unbound variable': $(grep -E 'unbound|notes' "$GATE_OUT")"
else
  pass "4.a.1 0-signal output is clean (no empty-array warnings)"
fi

# 4.b — friction log mention triggers Signal 3
echo "I had to replay an old session to reconstruct context" >> "$PILOT/.aegis/brain/memory/aegis-plus-feedback.md"
GATE2_OUT="$TEST_DIR/gate-s3.out"
bash "$GATE" "$PILOT" >"$GATE2_OUT" 2>&1 || true
if grep -q "signal 3 met" "$GATE2_OUT"; then
  pass "4.b friction-log replay mention → signal 3 detected"
else
  fail "4.b signal 3" "$(cat "$GATE2_OUT" | tail -15)"
fi

# 4.b.1 — Signal 3 with NO matches must not trigger arithmetic syntax error
# (regression guard for grep -c "0\n0" pattern in REPLAY_HITS / SIGNAL_HITS)
NO_MATCH_FB="$TEST_DIR/no-match-pilot/.aegis/brain/memory/aegis-plus-feedback.md"
mkdir -p "$(dirname "$NO_MATCH_FB")"
echo "no relevant words here at all" > "$NO_MATCH_FB"
mkdir -p "$TEST_DIR/no-match-pilot/.aegis/brain"
GATE_NM_OUT="$TEST_DIR/gate-no-match.out"
bash "$GATE" "$TEST_DIR/no-match-pilot" >"$GATE_NM_OUT" 2>&1 || true
if grep -qE "syntax error in expression|integer expression expected" "$GATE_NM_OUT"; then
  fail "4.b.1 signal-3 grep-c guard" "0\\n0 arithmetic error leaked: $(grep -E 'syntax|integer' "$GATE_NM_OUT")"
else
  pass "4.b.1 signal-3 with no replay matches → no arithmetic error"
fi

# 4.c — gate-check rejects non-AEGIS dir
if bash "$GATE" "$TEST_DIR" >/dev/null 2>&1; then
  fail "4.c gate non-aegis" "should reject (exit 2)"
else
  RC=$?
  [[ $RC -eq 2 ]] && pass "4.c gate-check rejects non-AEGIS dir (exit 2)" \
                  || fail "4.c gate non-aegis exit" "rc=$RC"
fi

# ── Group 5: skill content ───────────────────────────────────────────────
echo ""
echo "--- Group 5: skill content ---"

# 5.a — skill has bilingual triggers
if grep -q "fan\|pilot week" "$SKILL" && grep -qE "ตรวจ gate|รัน pilot" "$SKILL"; then
  pass "5.a aegis-plus-pilot.md has EN+TH triggers"
else
  fail "5.a triggers" "missing one language"
fi

# 5.b — skill documents the 3 signals
if grep -q "Prevented-incident" "$SKILL" \
   && grep -q "Audit-query" "$SKILL" \
   && grep -q "Run-replay" "$SKILL"; then
  pass "5.b skill documents all 3 Phase-2 signals"
else
  fail "5.b signal docs" "missing signal description"
fi

# 5.c — skill references the 3 scripts
if grep -q "bootstrap.sh" "$SKILL" \
   && grep -q "daily-eod.sh" "$SKILL" \
   && grep -q "gate-check.sh" "$SKILL"; then
  pass "5.c skill references all 3 pilot scripts"
else
  fail "5.c script refs" "missing script reference"
fi

echo ""
echo "============================================"
echo "RESULTS: ${PASS} passed, ${FAIL} failed"
echo "============================================"
[[ $FAIL -eq 0 ]] && { echo -e "${GREEN}ALL PASSED${NC}"; exit 0; } || { echo -e "${RED}FAILURES${NC}"; exit 1; }
