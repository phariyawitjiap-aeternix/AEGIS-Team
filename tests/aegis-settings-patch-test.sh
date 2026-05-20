#!/usr/bin/env bash
# aegis-settings-patch-test.sh — sprint v15-18B regression.
#
# Tests the safe-edit migration tool for `.claude/settings.json`:
#   T1: `list` shows available patches
#   T2: `dry-run` produces diff without writing
#   T3: `apply` patches the target file + creates timestamped backup
#   T4: `revert` restores from backup
#   T5: idempotency — applying same patch twice doesn't re-mutate
#   T6: patch on a fixture validates the narrow-matcher logic semantically

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TOOL="$REPO_ROOT/tools/aegis-settings-patch.sh"
PATCH_FILE="$REPO_ROOT/tools/aegis-settings-patches/narrow-posttooluse-matcher.jq"

[[ -f "$TOOL" ]] || { echo "FATAL: missing $TOOL" >&2; exit 2; }
[[ -f "$PATCH_FILE" ]] || { echo "FATAL: missing $PATCH_FILE" >&2; exit 2; }
command -v jq >/dev/null 2>&1 || { echo "FATAL: jq not installed (test env)" >&2; exit 2; }

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
PASS=0; FAIL=0
pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}FAIL${NC}: $1 -- $2"; FAIL=$((FAIL+1)); }

TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/aegis-settings-patch-XXXXXX")
trap 'find "$TEST_DIR" -type f -delete 2>/dev/null; find "$TEST_DIR" -depth -type d -delete 2>/dev/null' EXIT INT TERM

# Build a synthetic AEGIS-installed project as the test fixture.
FIXTURE="$TEST_DIR/fixture"
mkdir -p "$FIXTURE/.claude" "$FIXTURE/tools/aegis-settings-patches" "$FIXTURE/.aegis/brain/state"
# Write a minimal settings.json with the `.*` matcher we want to narrow.
cat > "$FIXTURE/.claude/settings.json" <<'EOF'
{
  "env": {"FIXTURE": "1"},
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {"type": "command", "command": "bash some-bash-only-hook.sh"}
        ]
      },
      {
        "matcher": ".*",
        "hooks": [
          {"type": "command", "command": "bash hot-path-hook.sh"},
          {"type": "command", "command": "node hot-path-hook.mjs"}
        ]
      }
    ]
  }
}
EOF
# Copy the tool + patch into the fixture so we exercise the user-facing path
cp "$TOOL" "$FIXTURE/tools/aegis-settings-patch.sh"
chmod +x "$FIXTURE/tools/aegis-settings-patch.sh"
cp "$PATCH_FILE" "$FIXTURE/tools/aegis-settings-patches/narrow-posttooluse-matcher.jq"

export CLAUDE_PROJECT_DIR="$FIXTURE"

echo "============================================"
echo "AEGIS settings-patch migration tool — v15-18B"
echo "============================================"

# ── T1: list ─────────────────────────────────────────────────────────────
echo ""
echo "--- T1: list shows the narrow-posttooluse-matcher patch ---"
OUT=$(bash "$FIXTURE/tools/aegis-settings-patch.sh" list 2>&1)
if echo "$OUT" | grep -q "narrow-posttooluse-matcher" && echo "$OUT" | grep -q "Narrow PostToolUse"; then
    pass "T1: list output contains patch name + description"
else
    fail "T1: list format" "got: $OUT"
fi

# ── T2: dry-run ──────────────────────────────────────────────────────────
echo ""
echo "--- T2: dry-run shows diff without writing ---"
ORIG_SIZE=$(wc -c < "$FIXTURE/.claude/settings.json")
OUT=$(bash "$FIXTURE/tools/aegis-settings-patch.sh" dry-run narrow-posttooluse-matcher 2>&1)
NEW_SIZE=$(wc -c < "$FIXTURE/.claude/settings.json")
if [[ "$ORIG_SIZE" == "$NEW_SIZE" ]] && echo "$OUT" | grep -q "Bash|Edit|Write|MultiEdit|Task"; then
    pass "T2: dry-run preserves file unchanged + shows new matcher in diff"
else
    fail "T2: dry-run side effects" "orig=$ORIG_SIZE new=$NEW_SIZE"
fi

# ── T3: apply ────────────────────────────────────────────────────────────
echo ""
echo "--- T3: apply patches the file + creates backup ---"
bash "$FIXTURE/tools/aegis-settings-patch.sh" apply narrow-posttooluse-matcher >/dev/null 2>&1
# Check file contents
new_matcher=$(jq -r '.hooks.PostToolUse[] | select(.matcher | contains("Edit|Write")) | .matcher' "$FIXTURE/.claude/settings.json" 2>/dev/null | head -1)
backup_exists=$(ls "$FIXTURE/.aegis/brain/state/settings-backups/"settings-*-pre-narrow-posttooluse-matcher.json 2>/dev/null | wc -l | tr -d ' ')
if [[ "$new_matcher" == "Bash|Edit|Write|MultiEdit|Task" ]] && [[ "$backup_exists" -ge "1" ]]; then
    pass "T3: matcher narrowed + backup created"
else
    fail "T3: apply incomplete" "matcher=$new_matcher backups=$backup_exists"
fi

# ── T4: revert ───────────────────────────────────────────────────────────
echo ""
echo "--- T4: revert restores from backup ---"
bash "$FIXTURE/tools/aegis-settings-patch.sh" revert narrow-posttooluse-matcher >/dev/null 2>&1
reverted_matcher=$(jq -r '.hooks.PostToolUse[] | select(.matcher == ".*") | .matcher' "$FIXTURE/.claude/settings.json" 2>/dev/null | head -1)
if [[ "$reverted_matcher" == ".*" ]]; then
    pass "T4: revert restored original .* matcher"
else
    fail "T4: revert failed" "got matcher='$reverted_matcher'"
fi

# ── T5: idempotency ──────────────────────────────────────────────────────
echo ""
echo "--- T5: applying twice is a no-op on the second call ---"
bash "$FIXTURE/tools/aegis-settings-patch.sh" apply narrow-posttooluse-matcher >/dev/null 2>&1
hash_after_first=$(md5 -q "$FIXTURE/.claude/settings.json" 2>/dev/null || md5sum "$FIXTURE/.claude/settings.json" 2>/dev/null | awk '{print $1}')
bash "$FIXTURE/tools/aegis-settings-patch.sh" apply narrow-posttooluse-matcher >/dev/null 2>&1
hash_after_second=$(md5 -q "$FIXTURE/.claude/settings.json" 2>/dev/null || md5sum "$FIXTURE/.claude/settings.json" 2>/dev/null | awk '{print $1}')
if [[ "$hash_after_first" == "$hash_after_second" ]]; then
    pass "T5: second apply is content-identical (idempotent)"
else
    fail "T5: second apply mutated content" "first=$hash_after_first second=$hash_after_second"
fi

# ── T6: semantic check — Bash matcher entry left alone ───────────────────
echo ""
echo "--- T6: only the .* matcher is changed; other entries untouched ---"
bash_matcher=$(jq -r '.hooks.PostToolUse[] | select(.matcher == "Bash") | .matcher' "$FIXTURE/.claude/settings.json" 2>/dev/null | head -1)
hook_count=$(jq '[.hooks.PostToolUse[] | select(.matcher | contains("Edit|Write")) | .hooks[]] | length' "$FIXTURE/.claude/settings.json" 2>/dev/null)
if [[ "$bash_matcher" == "Bash" ]] && [[ "$hook_count" == "2" ]]; then
    pass "T6: Bash matcher preserved + .* entry's inner hooks (2) intact"
else
    fail "T6: semantic regression" "bash=$bash_matcher hooks=$hook_count"
fi

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
echo "============================================"

if [[ "$FAIL" -gt 0 ]]; then
    exit 1
fi
exit 0
