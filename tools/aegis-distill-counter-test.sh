#!/usr/bin/env bash
# AEGIS Distill Counter Regression Test (Sprint v9-06 S6-01)
# Validates the session-start hook's counter increment + reminder trigger +
# reset-helper round-trip.
#
# Exits 0 if all assertions pass, 1 otherwise. Saves/restores any existing
# distill-state.json and does not touch brain logs.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
HOOK="${REPO_ROOT}/.claude/hooks/session-start.sh"
RESET="${REPO_ROOT}/tools/aegis-distill-reset.sh"
STATE="${REPO_ROOT}/.aegis/brain/state/distill-state.json"

cd "$REPO_ROOT"

PASS=0
FAIL=0
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() { echo -e "  ${GREEN}PASS${NC} $1"; PASS=$((PASS+1)); }
fail() { echo -e "  ${RED}FAIL${NC} $1"; FAIL=$((FAIL+1)); }
info() { echo -e "${YELLOW}==>${NC} $1"; }

# --- Setup: save any existing state ---
BACKUP=""
if [[ -f "$STATE" ]]; then
    BACKUP=$(mktemp)
    cp "$STATE" "$BACKUP"
fi
cleanup() {
    if [[ -n "$BACKUP" && -f "$BACKUP" ]]; then
        mv "$BACKUP" "$STATE"
    else
        rm -f "$STATE"
    fi
}
trap cleanup EXIT

# --- Preconditions ---
[[ -x "$HOOK" ]] || { echo "ERROR: $HOOK not executable"; exit 1; }
[[ -x "$RESET" ]] || { echo "ERROR: $RESET not executable"; exit 1; }
command -v python3 >/dev/null || { echo "ERROR: python3 required"; exit 1; }

rm -f "$STATE"

count() {
    python3 -c "import json; print(json.load(open('$STATE'))['sessions_since_last_distill'])" 2>/dev/null || echo "MISSING"
}

reminder_fires() {
    # stderr of hook contains the reminder marker
    local out
    out=$(bash "$HOOK" 2>&1 >/dev/null)
    echo "$out" | grep -q "sessions since last /aegis-distill"
}

echo "======================================"
echo "S6-01 Distill Counter Test"
echo "======================================"
echo

# T1: state file does not exist initially, hook creates it
info "T1: Hook creates state file on first run"
rm -f "$STATE"
bash "$HOOK" >/dev/null 2>&1
if [[ -f "$STATE" ]]; then
    pass "state file created"
else
    fail "state file missing after hook run"
fi

# T2: first run counter is 1, no reminder
info "T2: First run = count 1, no reminder"
rm -f "$STATE"
if reminder_fires; then
    fail "reminder fired on run 1 (should not)"
else
    pass "no reminder on run 1"
fi
c=$(count)
if [[ "$c" == "1" ]]; then
    pass "counter = 1"
else
    fail "counter = $c, expected 1"
fi

# T3: second run = count 2, no reminder
info "T3: Second run = count 2, no reminder"
if reminder_fires; then
    fail "reminder fired on run 2 (should not)"
else
    pass "no reminder on run 2"
fi
c=$(count)
if [[ "$c" == "2" ]]; then
    pass "counter = 2"
else
    fail "counter = $c, expected 2"
fi

# T4: third run hits threshold, reminder fires
info "T4: Third run hits threshold (default 3), reminder fires"
if reminder_fires; then
    pass "reminder fired at threshold"
else
    fail "reminder did NOT fire at threshold"
fi
c=$(count)
if [[ "$c" == "3" ]]; then
    pass "counter = 3"
else
    fail "counter = $c, expected 3"
fi

# T5: reset zeros the counter
info "T5: Reset helper zeros the counter"
"$RESET" >/dev/null 2>&1
c=$(count)
if [[ "$c" == "0" ]]; then
    pass "counter reset to 0"
else
    fail "counter = $c after reset, expected 0"
fi

# T6: post-reset run = count 1, no reminder
info "T6: Post-reset first run = count 1, no reminder"
if reminder_fires; then
    fail "reminder fired post-reset (should not)"
else
    pass "no reminder post-reset"
fi
c=$(count)
if [[ "$c" == "1" ]]; then
    pass "counter = 1 post-reset"
else
    fail "counter = $c, expected 1"
fi

# T7: AEGIS_DISTILL_THRESHOLD override
info "T7: AEGIS_DISTILL_THRESHOLD=5 raises the threshold"
rm -f "$STATE"
for _ in 1 2 3 4; do
    AEGIS_DISTILL_THRESHOLD=5 bash "$HOOK" >/dev/null 2>&1
done
# Count should be 4, no reminder yet
c=$(count)
if [[ "$c" == "4" ]]; then
    pass "counter = 4 under threshold=5"
else
    fail "counter = $c, expected 4"
fi
out=$(AEGIS_DISTILL_THRESHOLD=5 bash "$HOOK" 2>&1 >/dev/null)
if echo "$out" | grep -q "threshold: 5"; then
    pass "reminder shows correct threshold (5)"
else
    fail "reminder threshold wrong or missing"
fi

# T8: corrupt state file recovers gracefully
info "T8: Corrupt state file recovers"
echo 'NOT VALID JSON' > "$STATE"
bash "$HOOK" >/dev/null 2>&1
c=$(count)
if [[ "$c" == "1" ]]; then
    pass "recovered to count=1 after corruption"
else
    fail "counter = $c, expected 1 after recovery"
fi

echo
echo "======================================"
echo "Results: ${PASS} passed, ${FAIL} failed"
echo "======================================"
[[ "$FAIL" == "0" ]] && exit 0 || exit 1
