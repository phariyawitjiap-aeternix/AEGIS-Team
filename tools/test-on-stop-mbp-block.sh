#!/usr/bin/env bash
# test-on-stop-mbp-block.sh — verify on-stop.sh HARD-BLOCKS option menus
#
# Sprint v10-03 — fix policy-without-test for MBP enforcement.
#
# Coverage:
#   TC-01: option menu (A/B/C) + open question → must output decision:block JSON
#   TC-02: clean response (no menu)             → must NOT output decision:block
#   TC-03: AEGIS_MBP_BLOCK_DISABLE=1            → must skip block (escape hatch)
#   TC-04: stop_hook_active=True                → must skip block (loop prevention)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="$REPO_ROOT/.claude/hooks/on-stop.sh"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

PASS=0
FAIL=0
assert() {
    local name="$1" want="$2" got="$3"
    if [[ "$got" == "$want" ]]; then
        echo "  PASS: $name"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $name"
        echo "    want: $want"
        echo "    got:  $got"
        FAIL=$((FAIL + 1))
    fi
}

# ── Build fake transcripts ─────────────────────────────────────────────────

cat > "$TMP/violation-transcript.jsonl" <<'JSONL'
{"message":{"role":"user","content":[{"type":"text","text":"what next?"}]}}
{"message":{"role":"assistant","content":[{"type":"text","text":"Options:\nA) Open sprint v10-03\nB) Defer for now\nC) Apply RTK\n\nWhich do you prefer?"}]}}
JSONL

cat > "$TMP/clean-transcript.jsonl" <<'JSONL'
{"message":{"role":"user","content":[{"type":"text","text":"what next?"}]}}
{"message":{"role":"assistant","content":[{"type":"text","text":"Sprint v10-03 dispatched. Nick Fury scanning state."}]}}
JSONL

# ── TC-01: violation → must output decision:block ─────────────────────────
echo ""
echo "TC-01: option menu detected → must HARD-BLOCK"
INPUT="{\"session_id\":\"test\",\"stop_hook_active\":false,\"transcript_path\":\"$TMP/violation-transcript.jsonl\"}"
OUT=$(echo "$INPUT" | bash "$HOOK" 2>/dev/null || true)
echo "$OUT" | grep -q '"decision": "block"' && got="block" || got="no-block"
assert "violation triggers decision:block JSON" "block" "$got"

# ── TC-02: clean → must NOT output decision:block ─────────────────────────
echo ""
echo "TC-02: clean response → must NOT block"
INPUT="{\"session_id\":\"test\",\"stop_hook_active\":false,\"transcript_path\":\"$TMP/clean-transcript.jsonl\"}"
OUT=$(echo "$INPUT" | bash "$HOOK" 2>/dev/null || true)
echo "$OUT" | grep -q '"decision": "block"' && got="block" || got="no-block"
assert "clean response does NOT block" "no-block" "$got"

# ── TC-03: escape hatch (AEGIS_MBP_BLOCK_DISABLE=1) ───────────────────────
echo ""
echo "TC-03: AEGIS_MBP_BLOCK_DISABLE=1 → must skip block"
INPUT="{\"session_id\":\"test\",\"stop_hook_active\":false,\"transcript_path\":\"$TMP/violation-transcript.jsonl\"}"
OUT=$(echo "$INPUT" | AEGIS_MBP_BLOCK_DISABLE=1 bash "$HOOK" 2>/dev/null || true)
echo "$OUT" | grep -q '"decision": "block"' && got="block" || got="no-block"
assert "escape hatch skips block" "no-block" "$got"

# ── TC-04: stop_hook_active=True → must skip block (loop prevention) ──────
echo ""
echo "TC-04: stop_hook_active=True → must skip block (loop prevention)"
INPUT="{\"session_id\":\"test\",\"stop_hook_active\":true,\"transcript_path\":\"$TMP/violation-transcript.jsonl\"}"
OUT=$(echo "$INPUT" | bash "$HOOK" 2>/dev/null || true)
echo "$OUT" | grep -q '"decision": "block"' && got="block" || got="no-block"
assert "stop_hook_active=True skips block" "no-block" "$got"

# ── Summary ─────────────────────────────────────────────────────────────────
echo ""
echo "=== Results ==="
TOTAL=$((PASS + FAIL))
echo "  $PASS passed, $FAIL failed, $TOTAL total"
if [[ "$FAIL" -gt 0 ]]; then
    echo "  STATUS: FAIL"
    exit 1
else
    echo "  STATUS: PASS"
    exit 0
fi
