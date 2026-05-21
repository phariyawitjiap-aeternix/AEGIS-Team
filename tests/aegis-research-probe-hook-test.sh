#!/usr/bin/env bash
# aegis-research-probe-hook-test.sh — sprint v15-21 regression.
#
# Tests the PostToolUse hook .claude/hooks/research-probe-on-write.sh
# and the settings.json patch tools/aegis-settings-patches/wire-research-probe-hook.jq.
#
# T1: hook ignores Bash tool calls (only fires on Edit|Write|MultiEdit)
# T2: hook ignores writes outside _aegis-output/research/
# T3: hook auto-annotates URLs in research-doc writes
# T4: jq patch is idempotent (re-applying doesn't duplicate the hook entry)
# T5: jq patch dry-run shows expected diff
# T6: hook exits 0 always (soft gate)
# T7: hook handles missing aegis-research-probe.sh gracefully (older AEGIS installs)

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
HOOK="$REPO_ROOT/.claude/hooks/research-probe-on-write.sh"
PATCH="$REPO_ROOT/tools/aegis-settings-patches/wire-research-probe-hook.jq"
PATCH_TOOL="$REPO_ROOT/tools/aegis-settings-patch.sh"
PROBE_TOOL="$REPO_ROOT/tools/aegis-research-probe.sh"

[[ -f "$HOOK" ]] || { echo "FATAL: missing $HOOK" >&2; exit 2; }
[[ -f "$PATCH" ]] || { echo "FATAL: missing $PATCH" >&2; exit 2; }
[[ -f "$PATCH_TOOL" ]] || { echo "FATAL: missing $PATCH_TOOL" >&2; exit 2; }
command -v jq >/dev/null 2>&1 || { echo "FATAL: jq not installed" >&2; exit 2; }

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
PASS=0; FAIL=0
pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}FAIL${NC}: $1 -- $2"; FAIL=$((FAIL+1)); }

TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/aegis-probe-hook-XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT INT TERM

# ── T1: ignores Bash ─────────────────────────────────────────────────────
echo ""
echo "--- T1: hook ignores Bash tool calls ---"
OUT=$(echo '{"tool_name":"Bash","tool_input":{"command":"ls"}}' \
    | CLAUDE_PROJECT_DIR="$REPO_ROOT" bash "$HOOK" 2>&1)
rc=$?
if [[ "$rc" == "0" ]] && [[ -z "$OUT" ]]; then
    pass "T1: Bash → silent exit 0"
else
    fail "T1: Bash ignore" "rc=$rc out=$OUT"
fi

# ── T2: ignores writes outside research/ ─────────────────────────────────
echo ""
echo "--- T2: hook ignores writes outside _aegis-output/research/ ---"
mkdir -p "$TEST_DIR/elsewhere"
echo "# Not a research doc" > "$TEST_DIR/elsewhere/note.md"
OUT=$(echo "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$TEST_DIR/elsewhere/note.md\"}}" \
    | CLAUDE_PROJECT_DIR="$REPO_ROOT" bash "$HOOK" 2>&1)
rc=$?
# File should not be annotated
if [[ "$rc" == "0" ]] && ! grep -q '\[PROBED' "$TEST_DIR/elsewhere/note.md"; then
    pass "T2: writes outside research/ → file untouched"
else
    fail "T2: outside scope" "rc=$rc content: $(cat "$TEST_DIR/elsewhere/note.md")"
fi

# ── T3: auto-annotates research-doc writes ───────────────────────────────
echo ""
echo "--- T3: hook auto-annotates URLs in research-doc writes ---"
mkdir -p "$TEST_DIR/_aegis-output/research"
cat > "$TEST_DIR/_aegis-output/research/api-r.md" <<'EOF'
# API notes
- https://example.com/api
- https://api.unresolvable-xyz123-zzz.fake/v1
EOF
echo "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$TEST_DIR/_aegis-output/research/api-r.md\"}}" \
    | CLAUDE_PROJECT_DIR="$REPO_ROOT" bash "$HOOK" >/dev/null 2>&1
if grep -qE '(\[PROBED|\[UNPROBED)' "$TEST_DIR/_aegis-output/research/api-r.md"; then
    pass "T3: research-doc gained probe annotations"
else
    fail "T3: auto-annotation" "file content: $(cat "$TEST_DIR/_aegis-output/research/api-r.md")"
fi

# ── T4: jq patch idempotent ──────────────────────────────────────────────
echo ""
echo "--- T4: jq patch is idempotent ---"
FIX_SETTINGS="$TEST_DIR/.claude/settings.json"
mkdir -p "$TEST_DIR/.claude"
cat > "$FIX_SETTINGS" <<'EOF'
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {"type": "command", "command": "bash existing.sh"}
        ]
      }
    ]
  }
}
EOF
tmp1=$(mktemp)
jq -f "$PATCH" "$FIX_SETTINGS" > "$tmp1"
hash1=$(md5 -q "$tmp1" 2>/dev/null || md5sum "$tmp1" | awk '{print $1}')
tmp2=$(mktemp)
jq -f "$PATCH" "$tmp1" > "$tmp2"
hash2=$(md5 -q "$tmp2" 2>/dev/null || md5sum "$tmp2" | awk '{print $1}')
if [[ "$hash1" == "$hash2" ]]; then
    pass "T4: re-applying patch leaves output byte-identical"
else
    fail "T4: idempotency" "hash1=$hash1 hash2=$hash2"
fi
# Verify the new hook entry IS present
if jq -e '.hooks.PostToolUse[] | select(.matcher=="Edit|Write|MultiEdit") | .hooks[] | select(.command | contains("research-probe-on-write"))' "$tmp1" >/dev/null 2>&1; then
    pass "T4b: patch added research-probe-on-write hook"
else
    fail "T4b: patch insertion" "patch did not insert the hook"
fi
rm -f "$tmp1" "$tmp2"

# ── T5: dry-run shows the new hook in the diff ───────────────────────────
echo ""
echo "--- T5: dry-run shows the new hook in the diff ---"
# Use a fresh fixture so the test is robust whether AEGIS-Team's real
# settings.json has the patch applied or not (between-session state).
FIX_DIR="$TEST_DIR/dryrun-fixture"
mkdir -p "$FIX_DIR/.claude" "$FIX_DIR/tools/aegis-settings-patches"
cat > "$FIX_DIR/.claude/settings.json" <<'EOF'
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {"type": "command", "command": "bash existing.sh"}
        ]
      }
    ]
  }
}
EOF
cp "$PATCH_TOOL" "$FIX_DIR/tools/aegis-settings-patch.sh"
chmod +x "$FIX_DIR/tools/aegis-settings-patch.sh"
cp "$PATCH" "$FIX_DIR/tools/aegis-settings-patches/wire-research-probe-hook.jq"
OUT=$(CLAUDE_PROJECT_DIR="$FIX_DIR" bash "$FIX_DIR/tools/aegis-settings-patch.sh" dry-run wire-research-probe-hook 2>&1)
if echo "$OUT" | grep -q "research-probe-on-write"; then
    pass "T5: dry-run output mentions new hook (fresh fixture)"
else
    fail "T5: dry-run diff" "out=$OUT"
fi

# ── T6: hook always exits 0 ──────────────────────────────────────────────
echo ""
echo "--- T6: soft gate — hook exits 0 in all cases ---"
# Malformed JSON
echo "not json" | CLAUDE_PROJECT_DIR="$REPO_ROOT" bash "$HOOK" >/dev/null 2>&1
rc1=$?
# Missing tool_name
echo "{}" | CLAUDE_PROJECT_DIR="$REPO_ROOT" bash "$HOOK" >/dev/null 2>&1
rc2=$?
if [[ "$rc1" == "0" ]] && [[ "$rc2" == "0" ]]; then
    pass "T6: malformed/empty input → exit 0 (soft gate)"
else
    fail "T6: soft gate" "rc1=$rc1 rc2=$rc2"
fi

# ── T7: missing probe tool → graceful skip ───────────────────────────────
echo ""
echo "--- T7: hook handles missing probe tool gracefully ---"
mkdir -p "$TEST_DIR/legacy-aegis/.claude/hooks"
mkdir -p "$TEST_DIR/legacy-aegis/_aegis-output/research"
cp "$HOOK" "$TEST_DIR/legacy-aegis/.claude/hooks/research-probe-on-write.sh"
# NOTE: legacy-aegis intentionally has NO tools/aegis-research-probe.sh
echo "# r" > "$TEST_DIR/legacy-aegis/_aegis-output/research/r.md"
OUT=$(echo "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$TEST_DIR/legacy-aegis/_aegis-output/research/r.md\"}}" \
    | CLAUDE_PROJECT_DIR="$TEST_DIR/legacy-aegis" bash "$HOOK" 2>&1)
rc=$?
if [[ "$rc" == "0" ]]; then
    pass "T7: missing probe tool → silent skip (older AEGIS install compat)"
else
    fail "T7: legacy skip" "rc=$rc out=$OUT"
fi

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
echo "============================================"
[[ "$FAIL" -gt 0 ]] && exit 1
exit 0
