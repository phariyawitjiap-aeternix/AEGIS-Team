#!/usr/bin/env bash
# aegis-doc-canon-add-sign-test.sh — Sprint v12-02 acceptance + regression test
#
# Verifies tools/aegis-doc-canon/add-sign.mjs:
#   - appends a Sign in the right section
#   - bumps version (patch) and adds a changelog row
#   - validates that all 4 fields (title/trigger/do/why) are non-empty
#   - rejects unknown args
#   - the resulting file passes lint.mjs
#   - lint.mjs DEFAULT_DOCS now includes GUARDRAILS.md (live tree)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ADD_SIGN="${REPO_ROOT}/tools/aegis-doc-canon/add-sign.mjs"
LINT="${REPO_ROOT}/tools/aegis-doc-canon/lint.mjs"
GUARDRAILS_LIVE="${REPO_ROOT}/GUARDRAILS.md"

[[ -f "$ADD_SIGN" ]] || { echo "FATAL: missing $ADD_SIGN" >&2; exit 2; }
[[ -f "$LINT" ]]     || { echo "FATAL: missing $LINT"     >&2; exit 2; }
[[ -f "$GUARDRAILS_LIVE" ]] || { echo "FATAL: missing $GUARDRAILS_LIVE" >&2; exit 2; }
command -v node >/dev/null 2>&1 || { echo "FATAL: node not found" >&2; exit 2; }

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
PASS=0; FAIL=0
pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}FAIL${NC}: $1 -- $2"; FAIL=$((FAIL+1)); }

TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/aegis-add-sign-XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT INT TERM

echo "================================================="
echo "AEGIS doc-canon add-sign — sprint v12-02 acceptance"
echo "================================================="

# ─── Test 1: live tree lints clean (8 docs) ────────────────────────────────
echo
echo "T1: live-tree lint includes GUARDRAILS.md (8 docs)"
OUT=$(node "$LINT" --dir "$REPO_ROOT" 2>&1)
RC=$?
if [[ $RC -eq 0 ]]; then
    pass "live tree lint exits 0 with GUARDRAILS"
else
    fail "live tree lint exits 0" "exit=$RC, output:\n$OUT"
fi
if echo "$OUT" | grep -q "GUARDRAILS.md"; then
    pass "live tree lint includes GUARDRAILS.md"
else
    fail "live tree lint includes GUARDRAILS.md" "output:\n$OUT"
fi
if echo "$OUT" | grep -q "all 8 governance docs pass"; then
    pass "live tree lint reports all 8 pass"
else
    fail "live tree lint reports all 8 pass" "output:\n$OUT"
fi

# ─── Set up a fixture GUARDRAILS-style file ────────────────────────────────
write_fixture() {
    cat > "$TEST_DIR/GUARDRAILS.md" <<'EOF'
<!-- version: 1.0.0 -->
<!-- Last updated: 2026-05-06 -->

Last reviewed: 2026-05-06

# Test Guardrails

## Changelog

| Date | Version | Change |
|------|---------|--------|
| 2026-05-06 | 1.0.0 | Initial. |

## Scope

Test scope.

## Non-negotiables

Test non-negotiables.

---

## Signs

### Existing sign

- **Trigger:** existing trigger
- **Do:** existing do
- **Why:** existing why

---

## How to add a Sign

Use add-sign.mjs.
EOF
}

# ─── Test 2: happy path append ─────────────────────────────────────────────
echo
echo "T2: happy path — non-interactive append succeeds"
write_fixture
OUT=$(node "$ADD_SIGN" \
    --target "$TEST_DIR/GUARDRAILS.md" \
    --non-interactive \
    --title "Test sign" \
    --trigger "test trigger" \
    --do "test do" \
    --why "test why — incident X")
RC=$?
if [[ $RC -eq 0 ]]; then
    pass "happy path exits 0"
else
    fail "happy path exits 0" "exit=$RC, output:\n$OUT"
fi
if grep -q "### Test sign" "$TEST_DIR/GUARDRAILS.md"; then
    pass "new sign heading appears"
else
    fail "new sign heading appears" "file content:\n$(cat "$TEST_DIR/GUARDRAILS.md")"
fi
if grep -q "test trigger" "$TEST_DIR/GUARDRAILS.md" && \
   grep -q "test do" "$TEST_DIR/GUARDRAILS.md" && \
   grep -q "test why" "$TEST_DIR/GUARDRAILS.md"; then
    pass "all 3 sign fields appear"
else
    fail "all 3 sign fields appear" "file content:\n$(cat "$TEST_DIR/GUARDRAILS.md")"
fi
if grep -q "<!-- version: 1.0.1 -->" "$TEST_DIR/GUARDRAILS.md"; then
    pass "version bumped to 1.0.1 (patch)"
else
    fail "version bumped to 1.0.1" "header:\n$(head -2 "$TEST_DIR/GUARDRAILS.md")"
fi
if grep -q "Sign added: Test sign" "$TEST_DIR/GUARDRAILS.md"; then
    pass "changelog row added"
else
    fail "changelog row added" "file content:\n$(cat "$TEST_DIR/GUARDRAILS.md")"
fi

# ─── Test 3: existing sign is preserved (insertion didn't clobber) ─────────
echo
echo "T3: existing sign preserved"
if grep -q "### Existing sign" "$TEST_DIR/GUARDRAILS.md"; then
    pass "existing sign preserved after append"
else
    fail "existing sign preserved after append" "file content:\n$(cat "$TEST_DIR/GUARDRAILS.md")"
fi

# ─── Test 4: fixture passes lint after append ──────────────────────────────
echo
echo "T4: fixture passes lint after append"
LINT_OUT=$(node "$LINT" --dir "$TEST_DIR" --docs "GUARDRAILS.md")
LINT_RC=$?
if [[ $LINT_RC -eq 0 ]]; then
    pass "fixture passes lint after append"
else
    fail "fixture passes lint after append" "exit=$LINT_RC, output:\n$LINT_OUT"
fi

# ─── Test 5: missing title rejected ────────────────────────────────────────
echo
echo "T5: missing title rejected"
write_fixture
OUT=$(node "$ADD_SIGN" \
    --target "$TEST_DIR/GUARDRAILS.md" \
    --non-interactive \
    --trigger "t" --do "d" --why "w" 2>&1)
RC=$?
if [[ $RC -eq 1 ]]; then
    pass "missing title exits 1"
else
    fail "missing title exits 1" "exit=$RC, output:\n$OUT"
fi
if echo "$OUT" | grep -q "missing required field"; then
    pass "missing title reports error"
else
    fail "missing title reports error" "output:\n$OUT"
fi

# ─── Test 6: missing trigger rejected ──────────────────────────────────────
echo
echo "T6: missing trigger rejected"
OUT=$(node "$ADD_SIGN" \
    --target "$TEST_DIR/GUARDRAILS.md" \
    --non-interactive \
    --title "x" --do "d" --why "w" 2>&1)
RC=$?
if [[ $RC -eq 1 ]]; then
    pass "missing trigger exits 1"
else
    fail "missing trigger exits 1" "exit=$RC, output:\n$OUT"
fi

# ─── Test 7: missing do rejected ───────────────────────────────────────────
echo
echo "T7: missing do rejected"
OUT=$(node "$ADD_SIGN" \
    --target "$TEST_DIR/GUARDRAILS.md" \
    --non-interactive \
    --title "x" --trigger "t" --why "w" 2>&1)
RC=$?
if [[ $RC -eq 1 ]]; then
    pass "missing do exits 1"
else
    fail "missing do exits 1" "exit=$RC, output:\n$OUT"
fi

# ─── Test 8: missing why rejected ──────────────────────────────────────────
echo
echo "T8: missing why rejected"
OUT=$(node "$ADD_SIGN" \
    --target "$TEST_DIR/GUARDRAILS.md" \
    --non-interactive \
    --title "x" --trigger "t" --do "d" 2>&1)
RC=$?
if [[ $RC -eq 1 ]]; then
    pass "missing why exits 1"
else
    fail "missing why exits 1" "exit=$RC, output:\n$OUT"
fi

# ─── Test 9: empty (whitespace-only) field rejected ────────────────────────
echo
echo "T9: whitespace-only title rejected"
OUT=$(node "$ADD_SIGN" \
    --target "$TEST_DIR/GUARDRAILS.md" \
    --non-interactive \
    --title "   " --trigger "t" --do "d" --why "w" 2>&1)
RC=$?
if [[ $RC -eq 1 ]]; then
    pass "whitespace title exits 1"
else
    fail "whitespace title exits 1" "exit=$RC, output:\n$OUT"
fi

# ─── Test 10: missing target file → exit 2 ─────────────────────────────────
echo
echo "T10: missing target file exits 2"
OUT=$(node "$ADD_SIGN" \
    --target "$TEST_DIR/does-not-exist.md" \
    --non-interactive \
    --title "t" --trigger "t" --do "d" --why "w" 2>&1)
RC=$?
if [[ $RC -eq 2 ]]; then
    pass "missing target exits 2"
else
    fail "missing target exits 2" "exit=$RC, output:\n$OUT"
fi

# ─── Test 11: target without version header → exit 2 ───────────────────────
echo
echo "T11: target lacking version header exits 2"
echo "# No header here" > "$TEST_DIR/no-header.md"
OUT=$(node "$ADD_SIGN" \
    --target "$TEST_DIR/no-header.md" \
    --non-interactive \
    --title "t" --trigger "t" --do "d" --why "w" 2>&1)
RC=$?
if [[ $RC -eq 2 ]]; then
    pass "no-version-header target exits 2"
else
    fail "no-version-header target exits 2" "exit=$RC, output:\n$OUT"
fi

# ─── Test 12: unknown arg rejected with exit 2 ─────────────────────────────
echo
echo "T12: unknown arg rejected"
OUT=$(node "$ADD_SIGN" --bogus 2>&1)
RC=$?
if [[ $RC -eq 2 ]]; then
    pass "unknown arg exits 2"
else
    fail "unknown arg exits 2" "exit=$RC, output:\n$OUT"
fi

# ─── Test 13: live GUARDRAILS.md has ≥ 10 Signs ────────────────────────────
echo
echo "T13: live GUARDRAILS.md has ≥ 10 Signs"
SIGN_COUNT=$(grep -cE '^### ' "$GUARDRAILS_LIVE")
if [[ $SIGN_COUNT -ge 10 ]]; then
    pass "live GUARDRAILS has $SIGN_COUNT Signs (≥ 10)"
else
    fail "live GUARDRAILS has ≥ 10 Signs" "actual count: $SIGN_COUNT"
fi

# ─── Summary ───────────────────────────────────────────────────────────────
echo
echo "================================================="
echo -e "Total: ${GREEN}$PASS pass${NC} / ${RED}$FAIL fail${NC}"
echo "================================================="
if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
exit 0
