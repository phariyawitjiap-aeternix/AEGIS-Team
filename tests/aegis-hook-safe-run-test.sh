#!/usr/bin/env bash
# aegis-hook-safe-run-test.sh — sprint v15-12 regression.
#
# Validates the friendly-fail layer for AEGIS hooks:
#   T1  safeRun on a happy-path hook → exits 0, no stderr noise
#   T2  safeRun catches throw inside main() → exit 0, classified stderr
#   T3  safeRun catches throw → full stack appended to hook-errors.log
#   T4  safeRun classifies ERR_MODULE_NOT_FOUND specifically
#   T5  safeRun classifies generic Error with first-line + log pointer
#   T6  safeRun with failOpen=false propagates non-zero exit
#   T7  run-with-flags.sh classifies bash hook stderr (module-not-found)
#   T8  run-with-flags.sh PreToolUse hook (guard-*) propagates exit code
#   T9  run-with-flags.sh PostToolUse hook always exits 0

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SAFE_RUN="${REPO_ROOT}/tools/_hook-utils/safe-run.mjs"
WRAPPER="${REPO_ROOT}/.claude/hooks/run-with-flags.sh"

[[ -f "$SAFE_RUN" ]] || { echo "FATAL: missing $SAFE_RUN" >&2; exit 2; }
[[ -f "$WRAPPER" ]]  || { echo "FATAL: missing $WRAPPER" >&2; exit 2; }
command -v node >/dev/null 2>&1 || { echo "FATAL: node missing" >&2; exit 2; }

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
PASS=0; FAIL=0
pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}FAIL${NC}: $1 -- $2"; FAIL=$((FAIL+1)); }

TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/aegis-hook-safe-run-XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT INT TERM
export CLAUDE_PROJECT_DIR="$TEST_DIR"

echo "============================================"
echo "AEGIS hook friendly-fail — sprint v15-12"
echo "============================================"

# Helper: write a tiny .mjs that uses safeRun, run it, capture stdout+stderr+rc.
make_node_hook() {
    local body="$1"
    local file="$TEST_DIR/$(date +%s%N).mjs"
    cat > "$file" <<EOF
import { safeRun } from "$SAFE_RUN";
$body
EOF
    echo "$file"
}

# ── T1: happy path ────────────────────────────────────────────────────────
echo ""
echo "--- T1: safeRun happy path ---"
HOOK=$(make_node_hook 'safeRun(async () => 0, { hookName: "t1-happy", failOpen: true });')
ERR=$(node "$HOOK" 2>&1 >/dev/null); RC=$?
if [[ "$RC" == "0" ]] && [[ -z "$ERR" ]]; then
    pass "T1: happy hook → exit 0, no stderr"
else
    fail "T1: happy" "rc=$RC err='${ERR:0:80}'"
fi

# ── T2: throw is caught + classified ──────────────────────────────────────
echo ""
echo "--- T2: safeRun catches throw + classifies ---"
HOOK=$(make_node_hook 'safeRun(async () => { throw new Error("boom"); }, { hookName: "t2-throw", failOpen: true });')
ERR=$(node "$HOOK" 2>&1 >/dev/null); RC=$?
if [[ "$RC" == "0" ]] && echo "$ERR" | grep -q "⚠ \[t2-throw\] failed: boom"; then
    pass "T2: throw → exit 0 + classified message"
else
    fail "T2: throw classification" "rc=$RC err='${ERR:0:120}'"
fi

# ── T3: log written ───────────────────────────────────────────────────────
echo ""
echo "--- T3: hook-errors.log appended on throw ---"
LOG="$TEST_DIR/.aegis/brain/logs/hook-errors.log"
if [[ -f "$LOG" ]] && grep -q "hook=t2-throw" "$LOG"; then
    pass "T3: log has stack trace for t2-throw"
else
    fail "T3: log missing" "expected entry for t2-throw in $LOG"
fi

# ── T4: ERR_MODULE_NOT_FOUND classification ───────────────────────────────
echo ""
echo "--- T4: safeRun classifies ERR_MODULE_NOT_FOUND ---"
HOOK=$(make_node_hook 'safeRun(async () => { const e = new Error("Cannot find module nonexistent"); e.code = "ERR_MODULE_NOT_FOUND"; throw e; }, { hookName: "t4-mod", failOpen: true });')
ERR=$(node "$HOOK" 2>&1 >/dev/null); RC=$?
if [[ "$RC" == "0" ]] && echo "$ERR" | grep -q "missing Node module"; then
    pass "T4: ERR_MODULE_NOT_FOUND → 'missing Node module' hint"
else
    fail "T4: ERR_MODULE_NOT_FOUND" "rc=$RC err='${ERR:0:120}'"
fi

# ── T5: generic Error fallback message ────────────────────────────────────
echo ""
echo "--- T5: safeRun generic error fallback ---"
HOOK=$(make_node_hook 'safeRun(async () => { throw new TypeError("weird unique tag-xyz"); }, { hookName: "t5-generic", failOpen: true });')
ERR=$(node "$HOOK" 2>&1 >/dev/null); RC=$?
if [[ "$RC" == "0" ]] && echo "$ERR" | grep -q "weird unique tag-xyz" && echo "$ERR" | grep -q "hook-errors.log"; then
    pass "T5: generic error → first-line + log pointer"
else
    fail "T5: generic" "rc=$RC err='${ERR:0:120}'"
fi

# ── T6: failOpen=false propagates exit ────────────────────────────────────
echo ""
echo "--- T6: failOpen=false propagates exit 1 ---"
HOOK=$(make_node_hook 'safeRun(async () => { throw new Error("blocked"); }, { hookName: "t6-block", failOpen: false });')
node "$HOOK" >/dev/null 2>&1; RC=$?
if [[ "$RC" == "1" ]]; then
    pass "T6: failOpen=false → exit 1"
else
    fail "T6: failOpen=false propagation" "rc=$RC (expected 1)"
fi

# ── T7: run-with-flags.sh classifies module-not-found from bash hook ──────
echo ""
echo "--- T7: run-with-flags.sh classifies ERR_MODULE_NOT_FOUND ---"
FAKE_HOOK="$TEST_DIR/fake-hook.sh"
cat > "$FAKE_HOOK" <<'EOF'
#!/usr/bin/env bash
node -e 'throw Object.assign(new Error("Cannot find module foo"), { code: "ERR_MODULE_NOT_FOUND" })'
EOF
chmod +x "$FAKE_HOOK"
# settings.json normally provides stdin; we pipe an empty payload.
ERR=$(cd "$TEST_DIR" && echo '{}' | bash "$WRAPPER" t7-mod "$FAKE_HOOK" 2>&1 >/dev/null); RC=$?
if [[ "$RC" == "0" ]] && echo "$ERR" | grep -q "⚠ \[t7-mod\] missing Node module"; then
    pass "T7: bash hook stderr → 'missing Node module' classification"
else
    fail "T7: bash classifier" "rc=$RC err='${ERR:0:200}'"
fi

# ── T8: PreToolUse hook (guard-*) propagates exit code ────────────────────
echo ""
echo "--- T8: guard-* hook propagates exit code ---"
FAIL_HOOK="$TEST_DIR/guard-fail.sh"
cat > "$FAIL_HOOK" <<'EOF'
#!/usr/bin/env bash
echo "blocked" >&2
exit 2
EOF
chmod +x "$FAIL_HOOK"
(cd "$TEST_DIR" && echo '{}' | bash "$WRAPPER" guard-fail "$FAIL_HOOK" >/dev/null 2>&1); RC=$?
if [[ "$RC" == "2" ]]; then
    pass "T8: guard-* exit 2 propagates"
else
    fail "T8: guard propagation" "rc=$RC (expected 2)"
fi

# ── T9: PostToolUse hook always exits 0 ───────────────────────────────────
echo ""
echo "--- T9: post-tool-use exit 0 even on hook failure ---"
(cd "$TEST_DIR" && echo '{}' | bash "$WRAPPER" post-tool-use "$FAIL_HOOK" >/dev/null 2>&1); RC=$?
if [[ "$RC" == "0" ]]; then
    pass "T9: PostToolUse fails-open with exit 0"
else
    fail "T9: PostToolUse fail-open" "rc=$RC (expected 0)"
fi

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
echo "============================================"

if [[ "$FAIL" -gt 0 ]]; then
    exit 1
fi
exit 0
