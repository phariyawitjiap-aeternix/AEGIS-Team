#!/usr/bin/env bash
# aegis-return-format-test.sh — sprint v15-20 Story A regression.
#
# Tests tools/aegis-return-validator.sh:
#   T1: classifies a clean tagged return (all VERIFIED) — 0 untagged
#   T2: classifies a Contra-Thai-style untagged return — 100% untagged
#   T3: mixed return (1 VERIFIED, 1 PRODUCED, 1 untagged)
#   T4: ignores prose/narrative lines (no counts, no status)
#   T5: summary subcommand emits parseable KEY=VAL pairs
#   T6: file input (vs stdin) works
#   T7: soft gate — always exits 0 even on high untagged ratio

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TOOL="$REPO_ROOT/tools/aegis-return-validator.sh"

[[ -f "$TOOL" ]] || { echo "FATAL: missing $TOOL" >&2; exit 2; }

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
PASS=0; FAIL=0
pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}FAIL${NC}: $1 -- $2"; FAIL=$((FAIL+1)); }

# ── T1: clean tagged return ──────────────────────────────────────────────
echo ""
echo "--- T1: clean tagged return ---"
TXT1=$'Closes S03-02 [VERIFIED: bash tests/foo.sh]\n28 tests added [VERIFIED: npm test]\nBuild succeeded [VERIFIED: dotnet build]'
OUT=$(bash "$TOOL" summary --inline "$TXT1" 2>&1)
if echo "$OUT" | grep -q "UNTAGGED=0" && echo "$OUT" | grep -q "VERIFIED=3"; then
    pass "T1: clean return → VERIFIED=3 UNTAGGED=0"
else
    fail "T1: clean classification" "got: $OUT"
fi

# ── T2: Contra-Thai-style untagged return ────────────────────────────────
echo ""
echo "--- T2: Contra-Thai-style untagged return ---"
TXT2=$'Closes S02-02\n28 tests added\nAll quality checks pass'
OUT=$(bash "$TOOL" summary --inline "$TXT2" 2>&1)
ut=$(echo "$OUT" | grep -oE 'UNTAGGED=[0-9]+' | grep -oE '[0-9]+')
tot=$(echo "$OUT" | grep -oE 'TOTAL=[0-9]+' | grep -oE '[0-9]+')
if [[ "$ut" -ge 3 ]] && [[ "$tot" -ge 3 ]]; then
    pass "T2: Contra-Thai pattern → UNTAGGED=$ut TOTAL=$tot"
else
    fail "T2: untagged classification" "got: $OUT"
fi

# ── T3: mixed return ─────────────────────────────────────────────────────
echo ""
echo "--- T3: mixed return (1 VERIFIED, 1 PRODUCED, 1 untagged) ---"
TXT3=$'Closes S04-01 [VERIFIED: pytest]\n12 tests added [PRODUCED: unverified]\n3 stories complete'
OUT=$(bash "$TOOL" summary --inline "$TXT3" 2>&1)
if echo "$OUT" | grep -qE "VERIFIED=1.*PRODUCED=1.*UNTAGGED=1"; then
    pass "T3: mixed return classification correct"
else
    fail "T3: mixed classification" "got: $OUT"
fi

# ── T4: prose/narrative ignored ──────────────────────────────────────────
echo ""
echo "--- T4: prose lines without claims are ignored ---"
TXT4=$'I think this design is elegant.\nThe ScriptableObject pattern feels Unity-native.\nFurther polish is recommended in a future sprint.'
OUT=$(bash "$TOOL" summary --inline "$TXT4" 2>&1)
if echo "$OUT" | grep -q "TOTAL=0"; then
    pass "T4: prose-only return → TOTAL=0 (no claims to tag)"
else
    fail "T4: prose ignore" "got: $OUT"
fi

# ── T5: summary parseable ────────────────────────────────────────────────
echo ""
echo "--- T5: summary emits parseable KEY=VAL pairs ---"
TXT5=$'12 tests added [VERIFIED: pytest]'
OUT=$(bash "$TOOL" summary --inline "$TXT5" 2>&1)
keys=$(echo "$OUT" | grep -oE '(VERIFIED|PRODUCED|UNTAGGED|TOTAL)=' | wc -l | tr -d ' ')
if [[ "$keys" == "4" ]]; then
    pass "T5: 4 KEY=VAL fields present"
else
    fail "T5: summary schema" "got: $OUT (keys=$keys)"
fi

# ── T6: file input works ─────────────────────────────────────────────────
echo ""
echo "--- T6: file input mode works ---"
TMP=$(mktemp /tmp/return-XXXX.txt)
echo "Closes S05-01 [VERIFIED: npm test]" > "$TMP"
OUT=$(bash "$TOOL" summary "$TMP" 2>&1)
if echo "$OUT" | grep -q "VERIFIED=1"; then
    pass "T6: file input mode works"
else
    fail "T6: file input" "got: $OUT"
fi
rm -f "$TMP"

# ── T7: soft gate — always exits 0 ───────────────────────────────────────
echo ""
echo "--- T7: soft gate — even high-untagged exits 0 ---"
TXT7=$'5 tests added\nAll pass'
bash "$TOOL" check --inline "$TXT7" >/dev/null 2>&1
rc=$?
if [[ "$rc" == "0" ]]; then
    pass "T7: check exits 0 on high-untagged input (soft gate)"
else
    fail "T7: soft gate" "exit code was $rc"
fi

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
echo "============================================"
[[ "$FAIL" -gt 0 ]] && exit 1
exit 0
