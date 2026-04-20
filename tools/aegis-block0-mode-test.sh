#!/usr/bin/env bash
# AEGIS BLOCK 0 Mode Regression Test (Sprint v9-02 S2-03/04)
# Validates tools/aegis-block0-mode.sh against the decision table in
# .claude/references/block-0-lite.md.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
HELPER="${REPO_ROOT}/tools/aegis-block0-mode.sh"

PASS=0
FAIL=0
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

pass() { echo -e "  ${GREEN}PASS${NC} $1"; PASS=$((PASS+1)); }
fail() { echo -e "  ${RED}FAIL${NC} $1"; FAIL=$((FAIL+1)); }

assert_mode() {
    local points="$1"
    local tags="$2"
    local expected="$3"
    local actual
    if [[ -z "$tags" ]]; then
        actual=$("$HELPER" --points "$points" 2>/dev/null)
    else
        actual=$("$HELPER" --points "$points" --tags "$tags" 2>/dev/null)
    fi
    local label="points=$points tags='$tags' -> $expected"
    if [[ "$actual" == "$expected" ]]; then
        pass "$label (got: $actual)"
    else
        fail "$label (got: $actual, expected: $expected)"
    fi
}

[[ -x "$HELPER" ]] || { echo "ERROR: $HELPER not executable"; exit 1; }

echo "======================================"
echo "S2-03/04 BLOCK 0 Mode Determiner Test"
echo "======================================"
echo

# --- Size-based (no tags) ---
echo "Size-based defaults:"
assert_mode 0 "" "lite"
assert_mode 1 "" "lite"
assert_mode 2 "" "standard"
assert_mode 3 "" "standard"
assert_mode 5 "" "standard"
assert_mode 6 "" "full"
assert_mode 8 "" "full"
assert_mode 13 "" "full"

# --- Tag lite overrides (force lite regardless of size) ---
echo ""
echo "Lite-tag overrides (beat size):"
assert_mode 8 "chore" "lite"
assert_mode 13 "typo" "lite"
assert_mode 8 "docs-fix" "lite"
assert_mode 13 "hotfix" "lite"

# --- Tag full overrides (force full regardless of size) ---
echo ""
echo "Full-tag overrides (beat size):"
assert_mode 1 "feature" "full"
assert_mode 1 "refactor" "full"
assert_mode 1 "security" "full"
assert_mode 1 "breaking" "full"

# --- Precedence: lite-tag wins over full-tag when both present ---
echo ""
echo "Precedence (lite before full per spec ordering):"
assert_mode 8 "chore,security" "lite"
assert_mode 1 "hotfix,breaking" "lite"

# --- Case insensitivity + whitespace tolerance ---
echo ""
echo "Case + whitespace normalization:"
assert_mode 8 "CHORE" "lite"
assert_mode 1 "Security" "full"
assert_mode 8 "chore, refactor" "lite"
assert_mode 8 "  chore  " "lite"

# --- Unrelated tags don't change default ---
echo ""
echo "Unrelated tags:"
assert_mode 3 "backend" "standard"
assert_mode 8 "frontend,ui" "full"

# --- --task-id reading from meta.json (behavioral scenarios) ---
echo ""
echo "Task-id meta.json scenarios:"
SCRATCH_TASKS=$(mktemp -d -t aegis-block0-tasks.XXXXXX)
cleanup_tasks() { rm -rf "$SCRATCH_TASKS"; }
trap cleanup_tasks EXIT

# Build a throwaway .aegis/brain/tasks layout under SCRATCH_TASKS so --task-id
# doesn't touch real repo state. We temporarily chdir for the test.
ORIG_PWD="$PWD"
mkdir -p "${SCRATCH_TASKS}/.aegis/brain/tasks/TA" "${SCRATCH_TASKS}/.aegis/brain/tasks/TB" "${SCRATCH_TASKS}/.aegis/brain/tasks/TC" "${SCRATCH_TASKS}/.aegis/brain/tasks/TD" "${SCRATCH_TASKS}/.aegis/brain/tasks/TE"
# Copy helper + sibling tools expected structure
cp -R "$REPO_ROOT/tools" "$SCRATCH_TASKS/tools"

cat > "${SCRATCH_TASKS}/.aegis/brain/tasks/TA/meta.json" <<EOF_TA
{"id":"TA","points":1,"labels":["typo","docs"]}
EOF_TA
cat > "${SCRATCH_TASKS}/.aegis/brain/tasks/TB/meta.json" <<EOF_TB
{"id":"TB","points":8,"labels":["feature","backend"]}
EOF_TB
cat > "${SCRATCH_TASKS}/.aegis/brain/tasks/TC/meta.json" <<EOF_TC
{"id":"TC","points":3,"labels":["cleanup"]}
EOF_TC
cat > "${SCRATCH_TASKS}/.aegis/brain/tasks/TD/meta.json" <<EOF_TD
{"id":"TD","points":10,"labels":["feature"],"block0_mode":"lite"}
EOF_TD
cat > "${SCRATCH_TASKS}/.aegis/brain/tasks/TE/meta.json" <<EOF_TE
{"id":"TE","points":10,"labels":["chore"]}
EOF_TE

assert_task_mode() {
    local task="$1"
    local expected="$2"
    local actual
    # Invoke the COPIED helper (its SCRIPT_DIR resolves to SCRATCH_TASKS/tools,
    # so REPO_ROOT resolves to SCRATCH_TASKS). The --task-id lookup then hits
    # the scratch meta.json, not the real repo.
    actual=$("$SCRATCH_TASKS/tools/aegis-block0-mode.sh" --task-id "$task" 2>/dev/null)
    if [[ "$actual" == "$expected" ]]; then
        pass "--task-id $task -> $expected"
    else
        fail "--task-id $task -> got '$actual', expected '$expected'"
    fi
}

assert_task_mode "TA" "lite"       # 1pt typo
assert_task_mode "TB" "full"       # 8pt feature
assert_task_mode "TC" "standard"   # 3pt cleanup (no tag override)
assert_task_mode "TD" "lite"       # pinned block0_mode wins
assert_task_mode "TE" "lite"       # chore tag beats size

# --- Error cases ---
echo ""
echo "Error handling:"
out=$("$HELPER" 2>&1 >/dev/null)
if echo "$out" | grep -q "ERROR"; then
    pass "no args -> error"
else
    fail "no args -> no error"
fi
out=$("$HELPER" --points abc 2>&1 >/dev/null)
if echo "$out" | grep -q "non-negative integer"; then
    pass "non-numeric points -> error"
else
    fail "non-numeric points -> no error"
fi

echo
echo "======================================"
echo "Results: ${PASS} passed, ${FAIL} failed"
echo "======================================"
[[ "$FAIL" == "0" ]] && exit 0 || exit 1
