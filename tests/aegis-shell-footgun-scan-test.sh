#!/usr/bin/env bash
# aegis-shell-footgun-scan-test.sh — Pin scanner detection of bash footguns.
#
# Sprint v13-02 AI-2 (from v13-01 retro). Verifies that
# tools/aegis-shell-footgun-scan.sh:
#   1. Detects all 3 known-dangerous patterns when present (positive cases)
#   2. Stays silent on the corrected forms (negative cases)
#   3. Exits 0 on clean repo, 1 on findings
#
# This is the regression net for the scanner itself.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SCANNER="${REPO_ROOT}/tools/aegis-shell-footgun-scan.sh"

[[ -f "$SCANNER" ]] || { echo "FATAL: scanner missing at $SCANNER" >&2; exit 2; }

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
PASS=0; FAIL=0
pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}FAIL${NC}: $1 -- $2"; FAIL=$((FAIL+1)); }

TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/aegis-footgun-scan-test-XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT INT TERM

echo "============================================"
echo "AEGIS shell-footgun-scan regression tests"
echo "============================================"

# ─── T1: scanner exits 0 on clean repo ─────────────────────────────────────
if bash "$SCANNER" >/dev/null 2>&1; then
  pass "T1: scanner exits 0 on clean repo"
else
  rc=$?
  fail "T1: scanner clean-exit" "exit=$rc"
fi

# ─── T2: detects FOOTGUN-1 (set -e + && short-circuit) ─────────────────────
mkdir -p "$TEST_DIR/footgun1"
cat > "$TEST_DIR/footgun1/bad.sh" <<'EOF'
#!/usr/bin/env bash
set -e
my_func() {
  local x=1
  [[ $x -eq 1 ]] && echo "ok"
}
my_func
EOF
out=$(bash "$SCANNER" --paths "$TEST_DIR/footgun1/bad.sh" 2>&1 || true)
if echo "$out" | grep -qF 'FOOTGUN-1'; then
  pass "T2: FOOTGUN-1 detected (set -e + && short-circuit at function tail)"
else
  fail "T2: FOOTGUN-1 detection" "scanner missed: $out"
fi

# ─── T3: doesn't flag fixed form (explicit return 0) ───────────────────────
mkdir -p "$TEST_DIR/footgun1-fixed"
cat > "$TEST_DIR/footgun1-fixed/good.sh" <<'EOF'
#!/usr/bin/env bash
set -e
my_func() {
  local x=1
  [[ $x -eq 1 ]] && echo "ok"
  return 0
}
my_func
EOF
out=$(bash "$SCANNER" --paths "$TEST_DIR/footgun1-fixed/good.sh" 2>&1 || true)
if echo "$out" | grep -qF 'FOOTGUN-1'; then
  fail "T3: FOOTGUN-1 false-positive on fixed form" "scanner flagged: $out"
else
  pass "T3: explicit return 0 form not flagged"
fi

# ─── T4: detects FOOTGUN-2 (find -perm +111) ───────────────────────────────
mkdir -p "$TEST_DIR/footgun2"
cat > "$TEST_DIR/footgun2/bad.sh" <<'EOF'
#!/usr/bin/env bash
find . -name "*.sh" -perm +111
EOF
out=$(bash "$SCANNER" --paths "$TEST_DIR/footgun2/bad.sh" 2>&1 || true)
if echo "$out" | grep -qF 'FOOTGUN-2'; then
  pass "T4: FOOTGUN-2 detected (find -perm +)"
else
  fail "T4: FOOTGUN-2 detection" "scanner missed: $out"
fi

# ─── T5: detects FOOTGUN-3 (sed -i '') ─────────────────────────────────────
mkdir -p "$TEST_DIR/footgun3"
cat > "$TEST_DIR/footgun3/bad.sh" <<'EOF'
#!/usr/bin/env bash
sed -i '' "s|foo|bar|" "$1"
EOF
out=$(bash "$SCANNER" --paths "$TEST_DIR/footgun3/bad.sh" 2>&1 || true)
if echo "$out" | grep -qF 'FOOTGUN-3'; then
  pass "T5: FOOTGUN-3 detected (sed -i '')"
else
  fail "T5: FOOTGUN-3 detection" "scanner missed: $out"
fi

# ─── T6: doesn't flag portable form (sed -i.bak) ───────────────────────────
mkdir -p "$TEST_DIR/footgun3-fixed"
cat > "$TEST_DIR/footgun3-fixed/good.sh" <<'EOF'
#!/usr/bin/env bash
sed -i.bak "s|foo|bar|" "$1"
rm -f "${1}.bak"
EOF
out=$(bash "$SCANNER" --paths "$TEST_DIR/footgun3-fixed/good.sh" 2>&1 || true)
if echo "$out" | grep -qF 'FOOTGUN-3'; then
  fail "T6: FOOTGUN-3 false-positive on -i.bak form" "scanner flagged: $out"
else
  pass "T6: portable -i.bak form not flagged"
fi

# ─── T7: doesn't flag BSD-then-GNU fallback (multi-line continuation) ──────
mkdir -p "$TEST_DIR/footgun3-fallback"
cat > "$TEST_DIR/footgun3-fallback/good.sh" <<'EOF'
#!/usr/bin/env bash
sed -i '' "s|foo|bar|" "$1" \
  || sed -i "s|foo|bar|" "$1"
EOF
out=$(bash "$SCANNER" --paths "$TEST_DIR/footgun3-fallback/good.sh" 2>&1 || true)
if echo "$out" | grep -qF 'FOOTGUN-3'; then
  fail "T7: FOOTGUN-3 false-positive on BSD||GNU fallback" "scanner flagged: $out"
else
  pass "T7: BSD-then-GNU fallback continuation not flagged"
fi

# ─── T8: doesn't flag comments documenting the patterns ────────────────────
mkdir -p "$TEST_DIR/comments"
cat > "$TEST_DIR/comments/doc.sh" <<'EOF'
#!/usr/bin/env bash
# This script documents the footgun: don't use `find -perm +111` or `sed -i ''`
echo "safe"
EOF
out=$(bash "$SCANNER" --paths "$TEST_DIR/comments/doc.sh" 2>&1 || true)
if echo "$out" | grep -qE 'FOOTGUN-[23]'; then
  fail "T8: FOOTGUN-2/3 false-positive in comment" "scanner flagged: $out"
else
  pass "T8: comments documenting patterns not flagged"
fi

# ─── Summary ───────────────────────────────────────────────────────────────
echo ""
echo "============================================"
echo "RESULTS: ${PASS} passed, ${FAIL} failed"
echo "============================================"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
