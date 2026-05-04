#!/usr/bin/env bash
# aegis-issue-thread-test.sh — Sprint v11-03 acceptance + regression test

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ISSUE="${REPO_ROOT}/tools/aegis-issue-thread/issue.mjs"

[[ -f "$ISSUE" ]] || { echo "FATAL: missing $ISSUE" >&2; exit 2; }
command -v node >/dev/null 2>&1 || { echo "FATAL: node missing" >&2; exit 2; }

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
PASS=0; FAIL=0
pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}FAIL${NC}: $1 -- $2"; FAIL=$((FAIL+1)); }

TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/aegis-issue-thread-XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT INT TERM
export CLAUDE_PROJECT_DIR="$TEST_DIR"
ISSUES_DIR="$TEST_DIR/.aegis/brain/issues"

echo "============================================"
echo "AEGIS issue-thread — sprint v11-03 acceptance"
echo "============================================"

# ── Group 1: create ─────────────────────────────────────────────────────
echo ""
echo "--- Group 1: create ---"

# 1.a — first create produces KTH-1
ID1=$(node "$ISSUE" create --title "First issue" --assignee spider-man)
if [[ "$ID1" == "KTH-1" ]]; then
  pass "1.a first create returns KTH-1"
else
  fail "1.a create id" "got '$ID1'"
fi

# 1.b — yaml file exists with required fields
F1="$ISSUES_DIR/KTH-1.yaml"
if [[ -f "$F1" ]] && grep -q "title: First issue" "$F1" \
                  && grep -q "status: todo" "$F1" \
                  && grep -q "assignee: spider-man" "$F1"; then
  pass "1.b YAML file has required fields"
else
  fail "1.b YAML fields" "$(cat "$F1" 2>&1)"
fi

# 1.c — second create produces KTH-2 + index incremented
ID2=$(node "$ISSUE" create --title "Second" --status in_progress)
if [[ "$ID2" == "KTH-2" ]] && [[ -f "$ISSUES_DIR/KTH-2.yaml" ]]; then
  pass "1.c second create returns KTH-2"
else
  fail "1.c second create" "id=$ID2 file_exists=$(test -f "$ISSUES_DIR/KTH-2.yaml" && echo y || echo n)"
fi

# 1.d — _index.yaml carries last_n=2 + ordered ids
if grep -q "^last_n: 2" "$ISSUES_DIR/_index.yaml" \
   && grep -qE "^[[:space:]]+- KTH-1" "$ISSUES_DIR/_index.yaml" \
   && grep -qE "^[[:space:]]+- KTH-2" "$ISSUES_DIR/_index.yaml"; then
  pass "1.d _index.yaml has last_n=2 + both ids"
else
  fail "1.d index state" "$(cat "$ISSUES_DIR/_index.yaml")"
fi

# 1.e — invalid status rejected
if node "$ISSUE" create --title "x" --status nonsense >/dev/null 2>&1; then
  fail "1.e bad status" "should reject 'nonsense'"
else
  pass "1.e invalid status rejected"
fi

# ── Group 2: update / comment / link ────────────────────────────────────
echo ""
echo "--- Group 2: update / comment / link ---"

# 2.a — update status in_progress
node "$ISSUE" update KTH-1 --status in_progress >/dev/null
if grep -q "status: in_progress" "$F1"; then
  pass "2.a update status in_progress"
else
  fail "2.a update status" "$(cat "$F1")"
fi

# 2.b — comment appended
node "$ISSUE" comment KTH-1 --by sage --body "Spec drafted in SPEC.md§3.2"
if grep -q "by: sage" "$F1" && grep -q "Spec drafted" "$F1"; then
  pass "2.b comment appended"
else
  fail "2.b comment" "$(cat "$F1")"
fi

# 2.c — link added (PR type)
node "$ISSUE" link KTH-1 --type pr --value "https://github.com/foo/bar/pull/12"
if grep -q "type: pr" "$F1" && grep -q "pull/12" "$F1"; then
  pass "2.c PR link added"
else
  fail "2.c link" "$(cat "$F1")"
fi

# 2.d — invalid link type rejected
if node "$ISSUE" link KTH-1 --type bogus --value x >/dev/null 2>&1; then
  fail "2.d bad link type" "should reject"
else
  pass "2.d invalid link type rejected"
fi

# 2.e — second comment doesn't lose first
node "$ISSUE" comment KTH-1 --by spider-man --body "Tests passing"
COMMENT_COUNT=$(grep -c "by:" "$F1")
if [[ "$COMMENT_COUNT" -eq 2 ]]; then
  pass "2.e two comments preserved"
else
  fail "2.e comment count" "got $COMMENT_COUNT"
fi

# ── Group 3: list / show ────────────────────────────────────────────────
echo ""
echo "--- Group 3: list / show ---"

# 3.a — list all
LIST_ALL=$(node "$ISSUE" list)
if echo "$LIST_ALL" | grep -q "KTH-1" && echo "$LIST_ALL" | grep -q "KTH-2"; then
  pass "3.a list shows both"
else
  fail "3.a list all" "out=$LIST_ALL"
fi

# 3.b — list --status in_progress filters
LIST_IP=$(node "$ISSUE" list --status in_progress)
if echo "$LIST_IP" | grep -q "KTH-1" && echo "$LIST_IP" | grep -q "KTH-2"; then
  pass "3.b list --status in_progress shows both (both are in_progress)"
else
  fail "3.b list --status filter" "out=$LIST_IP"
fi

# 3.c — list --json valid + array of length 2
LIST_JSON=$(node "$ISSUE" list --json)
if echo "$LIST_JSON" | node -e 'const a=JSON.parse(require("fs").readFileSync(0,"utf8")); if(!Array.isArray(a)||a.length!==2) process.exit(1); console.log("ok")' 2>/dev/null; then
  pass "3.c list --json valid array of 2"
else
  fail "3.c json list" "$LIST_JSON"
fi

# 3.d — show KTH-1 prints YAML with comment + link
SHOW_OUT=$(node "$ISSUE" show KTH-1)
if echo "$SHOW_OUT" | grep -q "Spec drafted" && echo "$SHOW_OUT" | grep -q "pull/12"; then
  pass "3.d show prints comment + link content"
else
  fail "3.d show content" "out=$SHOW_OUT"
fi

# 3.e — show on missing id returns exit 2
if node "$ISSUE" show KTH-999 >/dev/null 2>&1; then
  fail "3.e missing id" "should exit non-zero"
else
  pass "3.e show on missing id exits non-zero"
fi

echo ""
echo "============================================"
echo "RESULTS: ${PASS} passed, ${FAIL} failed"
echo "============================================"
[[ $FAIL -eq 0 ]] && { echo -e "${GREEN}ALL PASSED${NC}"; exit 0; } || { echo -e "${RED}FAILURES${NC}"; exit 1; }
