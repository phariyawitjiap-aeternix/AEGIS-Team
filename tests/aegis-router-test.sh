#!/usr/bin/env bash
# aegis-router-test.sh — Sprint v11-06 acceptance + regression test

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ROUTE="${REPO_ROOT}/tools/aegis-router/route.mjs"
POLICY="${REPO_ROOT}/.aegis/brain/routing/policy.yaml"

[[ -f "$ROUTE" ]]  || { echo "FATAL: missing $ROUTE" >&2; exit 2; }
[[ -f "$POLICY" ]] || { echo "FATAL: missing $POLICY" >&2; exit 2; }
command -v node >/dev/null 2>&1 || { echo "FATAL: node missing" >&2; exit 2; }

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
PASS=0; FAIL=0
pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}FAIL${NC}: $1 -- $2"; FAIL=$((FAIL+1)); }

TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/aegis-router-XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT INT TERM

# Install meta policy as project policy for the test (avoids depending on
# the test runner's $PWD).
mkdir -p "$TEST_DIR/.aegis/brain/routing" "$TEST_DIR/.aegis/brain/logs"
cp "$POLICY" "$TEST_DIR/.aegis/brain/routing/policy.yaml"
export CLAUDE_PROJECT_DIR="$TEST_DIR"

echo "============================================"
echo "AEGIS router — sprint v11-06 acceptance"
echo "============================================"

# Helper: run route.mjs --json + extract picked
run_pick() {
  node "$ROUTE" --json "$@" 2>/dev/null | node -e 'console.log(JSON.parse(require("fs").readFileSync(0,"utf8")).picked)'
}
run_rule() {
  node "$ROUTE" --json "$@" 2>/dev/null | node -e 'console.log(JSON.parse(require("fs").readFileSync(0,"utf8")).rule)'
}

# ── Group 1: persona-based routing ──────────────────────────────────────
echo ""
echo "--- Group 1: persona routing ---"

PICK=$(run_pick --task "review SPEC.md adversarially" --persona loki)
[[ "$PICK" == "opus" ]] && pass "1.a loki → opus" || fail "1.a loki" "got=$PICK"

PICK=$(run_pick --task "design a system" --persona iron-man)
[[ "$PICK" == "opus" ]] && pass "1.b iron-man → opus" || fail "1.b iron-man" "got=$PICK"

PICK=$(run_pick --task "write tests for module" --persona spider-man)
[[ "$PICK" == "sonnet" ]] && pass "1.c spider-man → sonnet" || fail "1.c spider-man" "got=$PICK"

PICK=$(run_pick --task "deploy v11-05 to prod" --persona thor)
[[ "$PICK" == "sonnet" ]] && pass "1.d thor → sonnet" || fail "1.d thor" "got=$PICK"

# ── Group 2: keyword-based routing ──────────────────────────────────────
echo ""
echo "--- Group 2: keyword routing ---"

PICK=$(run_pick --task "design a new pattern for caching")
[[ "$PICK" == "opus" ]] && pass "2.a 'design' keyword → opus" || fail "2.a design" "got=$PICK"

PICK=$(run_pick --task "list ts files")
[[ "$PICK" == "haiku" ]] && pass "2.b short list-task → haiku" || fail "2.b haiku" "got=$PICK"

PICK=$(run_pick --task "review my pull request branch please")
[[ "$PICK" == "sonnet" ]] && pass "2.c review keyword → sonnet" || fail "2.c review" "got=$PICK"

# ── Group 3: override + default ─────────────────────────────────────────
echo ""
echo "--- Group 3: override + default fallthrough ---"

PICK=$(run_pick --task "trivial task" --model opus)
[[ "$PICK" == "opus" ]] && pass "3.a --model opus override wins" || fail "3.a override" "got=$PICK"

PICK=$(run_pick --task "totally unmatched random text 12345 xyzzy quux")
[[ "$PICK" == "sonnet" ]] && pass "3.b unmatched → default sonnet" || fail "3.b default" "got=$PICK"

RULE=$(run_rule --task "totally unmatched random text 12345 xyzzy quux")
[[ "$RULE" == "default" ]] && pass "3.c default rule named 'default'" || fail "3.c default rule" "got=$RULE"

# ── Group 4: audit log ──────────────────────────────────────────────────
echo ""
echo "--- Group 4: audit log ---"

# Wipe audit, generate one decision, verify line shape
rm -f "$TEST_DIR/.aegis/brain/logs/routing-audit.log"
node "$ROUTE" --task "design system" --persona iron-man >/dev/null 2>&1
AUDIT="$TEST_DIR/.aegis/brain/logs/routing-audit.log"
if [[ -f "$AUDIT" ]] && [[ $(wc -l < "$AUDIT" | tr -d ' ') -ge 1 ]]; then
  pass "4.a audit log written"
else
  fail "4.a audit exists" "missing"
fi

# Validate JSON shape
LINE=$(head -1 "$AUDIT")
if echo "$LINE" | node -e '
  const o = JSON.parse(require("fs").readFileSync(0, "utf8"));
  for (const k of ["ts","task_summary","persona","picked","reason","rule","override"]) {
    if (!(k in o)) { console.error("missing "+k); process.exit(1); }
  }
  if (o.picked !== "opus") process.exit(1);
  if (o.persona !== "iron-man") process.exit(1);
  console.log("ok");
' 2>/dev/null; then
  pass "4.b audit record has required fields + correct values"
else
  fail "4.b audit shape" "line=$LINE"
fi

# Override flag captured
node "$ROUTE" --task "x" --model haiku >/dev/null 2>&1
LINE=$(tail -1 "$AUDIT")
if echo "$LINE" | grep -q '"override":true' && echo "$LINE" | grep -q '"picked":"haiku"'; then
  pass "4.c override decision logged with override=true"
else
  fail "4.c override audit" "line=$LINE"
fi

# ── Group 5: --json output shape ────────────────────────────────────────
echo ""
echo "--- Group 5: --json shape ---"

OUT=$(node "$ROUTE" --json --task "design a system" --persona iron-man)
if echo "$OUT" | node -e '
  const o = JSON.parse(require("fs").readFileSync(0, "utf8"));
  if (o.picked !== "opus") process.exit(1);
  if (typeof o.reason !== "string" || !o.reason.length) process.exit(1);
  if (o.override !== false) process.exit(1);
  console.log("ok");
' 2>/dev/null; then
  pass "5.a --json valid + correct fields"
else
  fail "5.a json" "out=$OUT"
fi

# ── Group 6: text output shape ──────────────────────────────────────────
echo ""
echo "--- Group 6: text output shape ---"
OUT=$(node "$ROUTE" --task "design a system" --persona iron-man)
if echo "$OUT" | grep -q "picked: opus" && echo "$OUT" | grep -q "rule:" && echo "$OUT" | grep -q "reason:"; then
  pass "6.a text output has picked + reason + rule lines"
else
  fail "6.a text" "out=$OUT"
fi

echo ""
echo "============================================"
echo "RESULTS: ${PASS} passed, ${FAIL} failed"
echo "============================================"
[[ $FAIL -eq 0 ]] && { echo -e "${GREEN}ALL PASSED${NC}"; exit 0; } || { echo -e "${RED}FAILURES${NC}"; exit 1; }
