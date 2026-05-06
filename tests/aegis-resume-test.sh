#!/usr/bin/env bash
# aegis-resume-test.sh — Sprint v11-10 acceptance + regression test

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CHECKPOINT="${REPO_ROOT}/tools/aegis-resume/checkpoint.mjs"
RESUME="${REPO_ROOT}/tools/aegis-resume/resume.mjs"
SS="${REPO_ROOT}/tools/aegis-resume/session-start.mjs"

for f in "$CHECKPOINT" "$RESUME" "$SS"; do
  [[ -f "$f" ]] || { echo "FATAL: missing $f" >&2; exit 2; }
done
command -v node >/dev/null 2>&1 || { echo "FATAL: node missing" >&2; exit 2; }

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
PASS=0; FAIL=0
pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}FAIL${NC}: $1 -- $2"; FAIL=$((FAIL+1)); }

_TMP="${TMPDIR:-/tmp}"; _TMP="${_TMP%/}"
TEST_DIR=$(mktemp -d "$_TMP/aegis-resume-XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT INT TERM
export CLAUDE_PROJECT_DIR="$TEST_DIR"

# Bootstrap a real git repo so checkpoint can capture branch/commit.
( cd "$TEST_DIR"
  git init -q
  git -c user.email=test@example.com -c user.name=test commit -q --allow-empty -m "init"
  echo "hello" > a.txt
)

mkdir -p "$TEST_DIR/.aegis/brain/state" "$TEST_DIR/.aegis/brain/runs"

echo "============================================"
echo "AEGIS resume — sprint v11-10 acceptance"
echo "============================================"

# ── Group 1: checkpoint write ───────────────────────────────────────────
echo ""
echo "--- Group 1: checkpoint ---"

# 1.a — checkpoint writes a YAML file at the expected path
OUT=$(node "$CHECKPOINT" --session abc123 --task "fix wordPool dedup race" --persona spider-man 2>&1)
CHECK_FILE="$TEST_DIR/.aegis/brain/state/abc123.yaml"
if [[ -f "$CHECK_FILE" ]] && echo "$OUT" | grep -q "checkpoint:"; then
  pass "1.a checkpoint writes YAML at .aegis/brain/state/<session>.yaml"
else
  fail "1.a checkpoint write" "$OUT — file_exists=$(test -f "$CHECK_FILE" && echo y || echo n)"
fi

# 1.b — required fields present
if grep -q "session_id: abc123" "$CHECK_FILE" \
   && grep -q "ts:" "$CHECK_FILE" \
   && grep -q "branch:" "$CHECK_FILE" \
   && grep -q "persona: spider-man" "$CHECK_FILE" \
   && grep -q "task:" "$CHECK_FILE" \
   && grep -q "last_commit:" "$CHECK_FILE"; then
  pass "1.b checkpoint has all required fields"
else
  fail "1.b fields" "$(cat "$CHECK_FILE")"
fi

# 1.c — dirty_files captured (a.txt was untracked)
if grep -q "dirty_files:" "$CHECK_FILE" && grep -q "a.txt" "$CHECK_FILE"; then
  pass "1.c dirty_files captured (untracked a.txt)"
else
  fail "1.c dirty_files" "$(cat "$CHECK_FILE")"
fi

# 1.d — missing --session → exit 2
RC=0
node "$CHECKPOINT" --task "x" >/dev/null 2>&1 || RC=$?
if [[ "$RC" == "2" ]]; then
  pass "1.d checkpoint requires --session"
else
  fail "1.d session-required" "rc=$RC"
fi

# ── Group 2: resume list/show/clear ─────────────────────────────────────
echo ""
echo "--- Group 2: resume list / show / clear ---"

# 2.a — list shows abc123 as INTERRUPTED (no runs/ archive)
LIST=$(node "$RESUME" list)
if echo "$LIST" | grep -q "abc123" && echo "$LIST" | grep -q "interrupted"; then
  pass "2.a list shows interrupted checkpoint"
else
  fail "2.a list interrupted" "$LIST"
fi

# 2.b — --interrupted filter retains, --archived filter empties
LIST_INT=$(node "$RESUME" list --interrupted)
LIST_ARC=$(node "$RESUME" list --archived)
if echo "$LIST_INT" | grep -q "abc123" && ! echo "$LIST_ARC" | grep -q "abc123"; then
  pass "2.b --interrupted/--archived filters work"
else
  fail "2.b filters" "int=$LIST_INT arc=$LIST_ARC"
fi

# 2.c — --json valid
JSON=$(node "$RESUME" list --json)
if echo "$JSON" | node -e 'const a=JSON.parse(require("fs").readFileSync(0,"utf8")); if(!Array.isArray(a)||a.length<1) process.exit(1); if(!a[0].session_id) process.exit(1); console.log("ok")' 2>/dev/null; then
  pass "2.c list --json valid"
else
  fail "2.c json" "$JSON"
fi

# 2.d — show prints paste-ready brief
SHOW=$(node "$RESUME" show abc123)
if echo "$SHOW" | grep -q "Resume brief" \
   && echo "$SHOW" | grep -q "INTERRUPTED" \
   && echo "$SHOW" | grep -q "fix wordPool dedup race" \
   && echo "$SHOW" | grep -q "git checkout"; then
  pass "2.d show prints paste-ready brief with task + git instruction"
else
  fail "2.d show" "$SHOW"
fi

# 2.e — show on unknown id exits 2
RC=0
node "$RESUME" show MISSING >/dev/null 2>&1 || RC=$?
if [[ "$RC" == "2" ]]; then
  pass "2.e show <unknown> → exit 2"
else
  fail "2.e show unknown" "rc=$RC"
fi

# ── Group 3: archived detection (v11-07 integration) ────────────────────
echo ""
echo "--- Group 3: archived detection ---"

# Simulate v11-07 archive for abc123
TODAY=$(date -u +%Y-%m-%d)
mkdir -p "$TEST_DIR/.aegis/brain/runs/${TODAY}-abc123"
echo '{"session_id":"abc123"}' > "$TEST_DIR/.aegis/brain/runs/${TODAY}-abc123/meta.json"

# 3.a — list now shows abc123 as ARCHIVED
LIST=$(node "$RESUME" list)
if echo "$LIST" | grep -q "abc123" && echo "$LIST" | grep -q "archived"; then
  pass "3.a runs/ archive flips state to 'archived'"
else
  fail "3.a archived flip" "$LIST"
fi

# 3.b — clear --all-stopped removes archived ones
CLEAR=$(node "$RESUME" clear --all-stopped)
if echo "$CLEAR" | grep -q "cleared: abc123"; then
  pass "3.b clear --all-stopped removes archived checkpoints"
else
  fail "3.b clear --all-stopped" "$CLEAR"
fi

# 3.c — checkpoint file gone after clear
if [[ ! -f "$CHECK_FILE" ]]; then
  pass "3.c checkpoint file deleted by clear"
else
  fail "3.c file persists" "still at $CHECK_FILE"
fi

# 3.d — clear without --all-stopped or session id → exit 2
RC=0
node "$RESUME" clear >/dev/null 2>&1 || RC=$?
if [[ "$RC" == "2" ]]; then
  pass "3.d clear without args → exit 2"
else
  fail "3.d clear validation" "rc=$RC"
fi

# ── Group 4: SessionStart hook output ───────────────────────────────────
echo ""
echo "--- Group 4: SessionStart hook ---"

# Re-create a fresh interrupted checkpoint
node "$CHECKPOINT" --session ses-fresh --task "carry over to next session" --persona thor >/dev/null

# 4.a — hook prints banner mentioning the interrupted run
HOOK_OUT=$(echo '{"session_id":"new-session","stop_hook_active":false}' | node "$SS" 2>&1)
if echo "$HOOK_OUT" | grep -q "interrupted run" \
   && echo "$HOOK_OUT" | grep -q "ses-fresh" \
   && echo "$HOOK_OUT" | grep -q "carry over"; then
  pass "4.a SessionStart hook surfaces interrupted run"
else
  fail "4.a hook output" "$HOOK_OUT"
fi

# 4.b — hook exits 0 even on garbage stdin
RC=0
echo "garbage" | node "$SS" >/dev/null 2>&1 || RC=$?
if [[ "$RC" == "0" ]]; then
  pass "4.b SessionStart hook fail-OPEN on garbage stdin"
else
  fail "4.b fail-open" "rc=$RC"
fi

# 4.c — hook silent when no interrupted runs (after clearing the only one)
node "$RESUME" clear ses-fresh >/dev/null
HOOK_OUT=$(echo '{"session_id":"x"}' | node "$SS" 2>&1)
if [[ -z "$HOOK_OUT" ]]; then
  pass "4.c hook silent when no interrupted checkpoints exist"
else
  fail "4.c silence" "$HOOK_OUT"
fi

echo ""
echo "============================================"
echo "RESULTS: ${PASS} passed, ${FAIL} failed"
echo "============================================"
[[ $FAIL -eq 0 ]] && { echo -e "${GREEN}ALL PASSED${NC}"; exit 0; } || { echo -e "${RED}FAILURES${NC}"; exit 1; }
