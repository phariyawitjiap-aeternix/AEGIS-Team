#!/usr/bin/env bash
# aegis-research-probe-test.sh — sprint v15-20 Story C regression.
#
# Tests tools/aegis-research-probe.sh:
#   T1: scan detects live URL (github.com)
#   T2: scan detects fake-DNS URL as UNPROBED
#   T3: scan skips example.com / placeholder URLs
#   T4: apply mode rewrites file with annotations
#   T5: apply mode is idempotent (re-running doesn't double-tag)
#   T6: check-tags reports counts
#   T7: soft gate — exits 0 always
#
# Network: needs outbound HTTPS. If unreachable, T1 will be inconclusive
# but T2/T3/T4 still exercise the logic via DNS-fail + skip paths.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TOOL="$REPO_ROOT/tools/aegis-research-probe.sh"

[[ -f "$TOOL" ]] || { echo "FATAL: missing $TOOL" >&2; exit 2; }
command -v curl >/dev/null 2>&1 || { echo "FATAL: curl not installed" >&2; exit 2; }

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
PASS=0; FAIL=0; SKIP=0
pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}FAIL${NC}: $1 -- $2"; FAIL=$((FAIL+1)); }
skip() { echo -e "${YELLOW}SKIP${NC}: $1 -- $2"; SKIP=$((SKIP+1)); }

# Detect if outbound HTTPS works at all (CI env may block)
NET_OK=0
if curl -s -o /dev/null --max-time 5 -I https://github.com/ 2>/dev/null; then
    NET_OK=1
fi

TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/aegis-probe-XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT INT TERM

make_doc() {
    local f="$1"
    cat > "$f" <<'EOF'
# Research draft
- Placeholder: https://example.com/api
- Live target: https://github.com/
- Fake DNS: https://api.thisdoesnotresolveatall-xyz123.fake/v1/foo
EOF
}

# ── T1: scan detects live URL ────────────────────────────────────────────
echo ""
echo "--- T1: scan detects live URL ---"
if [[ "$NET_OK" == "0" ]]; then
    skip "T1: scan detects live URL" "no network — skipping live-URL assertion"
else
    f="$TEST_DIR/doc1.md"; make_doc "$f"
    OUT=$(bash "$TOOL" scan "$f" 2>&1)
    if echo "$OUT" | grep -q "probed-ok:.*1" && echo "$OUT" | grep -q "github.com"; then
        pass "T1: live URL detected as probed-ok"
    else
        fail "T1: live URL detection" "out=$OUT"
    fi
fi

# ── T2: fake DNS → UNPROBED ──────────────────────────────────────────────
echo ""
echo "--- T2: fake-DNS URL → unprobed ---"
f="$TEST_DIR/doc2.md"; make_doc "$f"
OUT=$(bash "$TOOL" scan "$f" 2>&1)
if echo "$OUT" | grep -q "unprobed:.*1" && echo "$OUT" | grep -q "thisdoesnotresolveatall"; then
    pass "T2: fake-DNS URL counted as unprobed"
else
    fail "T2: unprobed count" "out=$OUT"
fi

# ── T3: example.com / placeholder skipped ────────────────────────────────
echo ""
echo "--- T3: placeholder URL skipped ---"
f="$TEST_DIR/doc3.md"; make_doc "$f"
OUT=$(bash "$TOOL" scan "$f" 2>&1)
if echo "$OUT" | grep -q "skip:.*1" && echo "$OUT" | grep -q "example.com"; then
    pass "T3: example.com skipped"
else
    fail "T3: skip count" "out=$OUT"
fi

# ── T4: apply rewrites with annotations ──────────────────────────────────
echo ""
echo "--- T4: apply mode rewrites file with annotations ---"
f="$TEST_DIR/doc4.md"; make_doc "$f"
bash "$TOOL" apply "$f" >/dev/null 2>&1
if grep -qE '(\[PROBED|\[UNPROBED)' "$f"; then
    pass "T4: apply added probe annotations"
else
    fail "T4: apply annotations" "file content: $(cat "$f")"
fi

# ── T5: apply idempotent ─────────────────────────────────────────────────
echo ""
echo "--- T5: apply is idempotent ---"
f="$TEST_DIR/doc5.md"; make_doc "$f"
bash "$TOOL" apply "$f" >/dev/null 2>&1
hash1=$(md5 -q "$f" 2>/dev/null || md5sum "$f" 2>/dev/null | awk '{print $1}')
sleep 1
bash "$TOOL" apply "$f" >/dev/null 2>&1
hash2=$(md5 -q "$f" 2>/dev/null || md5sum "$f" 2>/dev/null | awk '{print $1}')
if [[ "$hash1" == "$hash2" ]]; then
    pass "T5: second apply leaves file byte-identical"
else
    fail "T5: idempotency" "hash1=$hash1 hash2=$hash2"
fi

# ── T6: check-tags reports counts ────────────────────────────────────────
echo ""
echo "--- T6: check-tags reports counts ---"
f="$TEST_DIR/doc6.md"; make_doc "$f"
bash "$TOOL" apply "$f" >/dev/null 2>&1
OUT=$(bash "$TOOL" check-tags "$f" 2>&1)
if echo "$OUT" | grep -qE "PROBED=[0-9]+.*UNPROBED=[0-9]+.*TAGGED=[0-9]+.*URLS=[0-9]+"; then
    pass "T6: check-tags emits PROBED/UNPROBED/TAGGED/URLS"
else
    fail "T6: check-tags schema" "out=$OUT"
fi

# ── T7: soft gate — exit 0 ───────────────────────────────────────────────
echo ""
echo "--- T7: soft gate — exit 0 ---"
f="$TEST_DIR/doc7.md"; make_doc "$f"
bash "$TOOL" scan "$f" >/dev/null 2>&1
rc=$?
if [[ "$rc" == "0" ]]; then
    pass "T7: scan exits 0 even with mixed results"
else
    fail "T7: soft gate" "rc=$rc"
fi

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed, $SKIP skipped"
echo "============================================"
[[ "$FAIL" -gt 0 ]] && exit 1
exit 0
