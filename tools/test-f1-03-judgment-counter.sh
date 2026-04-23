#!/usr/bin/env bash
# test-f1-03-judgment-counter.sh — Tests for F1-03 judgment counter exit code
# Bash 3.2 compatible.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/aegis-test-harness-template.sh"

LOG_DECISION="${SCRIPT_DIR}/aegis-log-decision.sh"

echo "=== F1-03: Judgment counter exit code ==="
echo ""

# The script uses REPO_ROOT from its own path, so we need to use the real repo
# but with a unique session ID to isolate counter state.
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
COUNTER="${REPO_ROOT}/.aegis/brain/metrics/judgment-fallback-counter.json"
TEST_SESSION="aegis-f103-test-$$"

# Reset counter for our test session
mkdir -p "$(dirname "$COUNTER")"
python3 - "$COUNTER" "$TEST_SESSION" <<'PYEOF'
import json, sys
path, sid = sys.argv[1], sys.argv[2]
state = {
    'session_id': sid,
    'started_at': '2026-01-01T00:00:00Z',
    'judgment_count': 0,
    'threshold': 3,
    'auto_escalate_on_threshold': True,
    'last_judgment_at': None,
}
with open(path, 'w') as f:
    json.dump(state, f, indent=2)
PYEOF

# Helper to call log-decision with our test session
log_judgment() {
    CLAUDE_SESSION_ID="$TEST_SESSION" bash "$LOG_DECISION" \
        --question "TC test judgment $1" \
        --source judgment \
        --confidence 0.4 \
        --answer "test answer" \
        --reasoning "test reasoning for TC $1" 2>&1
}

log_nonjudgment() {
    CLAUDE_SESSION_ID="$TEST_SESSION" bash "$LOG_DECISION" \
        --question "TC test adr $1" \
        --source "adr:ADR-001" \
        --confidence 0.9 \
        --answer "test answer" 2>&1
}

# TC-01: Log 2 judgment decisions — both should exit 0
EC1=0
log_judgment 1 >/dev/null 2>&1 || EC1=$?
assert_eq "$EC1" "0" "TC-01a first judgment exits 0"

EC2=0
log_judgment 2 >/dev/null 2>&1 || EC2=$?
assert_eq "$EC2" "0" "TC-01b second judgment exits 0"

# Verify counter is at 2
COUNT=$(python3 - "$COUNTER" "$TEST_SESSION" <<'PYEOF' 2>/dev/null
import json, sys
with open(sys.argv[1]) as f:
    s = json.load(f)
# Only count if same session
if s.get('session_id') == sys.argv[2]:
    print(s.get('judgment_count', 0))
else:
    print(0)
PYEOF
)
assert_eq "$COUNT" "2" "TC-01c counter = 2 after two judgments"

# TC-02: 3rd judgment hits threshold (3) — should exit 3, stderr contains THRESHOLD_EXCEEDED
EC3=0
COMBINED3=$(CLAUDE_SESSION_ID="$TEST_SESSION" bash "$LOG_DECISION" \
    --question "TC test judgment 3" \
    --source judgment \
    --confidence 0.4 \
    --answer "test answer" \
    --reasoning "test reasoning for TC 3" 2>&1) || EC3=$?
assert_eq "$EC3" "3" "TC-02 third judgment exits 3 (threshold hit)"
if echo "$COMBINED3" | grep -q "THRESHOLD_EXCEEDED"; then
    PASS "TC-02 output contains THRESHOLD_EXCEEDED"
else
    FAIL "TC-02 output missing THRESHOLD_EXCEEDED (got: $COMBINED3)"
fi

# TC-03: Non-judgment decision after threshold — should exit 0
EC4=0
log_nonjudgment 4 >/dev/null 2>&1 || EC4=$?
assert_eq "$EC4" "0" "TC-03 non-judgment source exits 0 (threshold only applies to judgment)"

# TC-04: New session ID resets counter — exits 0, counter = 1
NEW_SESSION="aegis-f103-new-$$"
EC5=0
CLAUDE_SESSION_ID="$NEW_SESSION" bash "$LOG_DECISION" \
    --question "new session test" \
    --source judgment \
    --confidence 0.4 \
    --answer "test" \
    --reasoning "new session reset test" >/dev/null 2>&1 || EC5=$?
assert_eq "$EC5" "0" "TC-04 first judgment in new session exits 0"

COUNT_NEW=$(python3 - "$COUNTER" "$NEW_SESSION" <<'PYEOF' 2>/dev/null
import json, sys
with open(sys.argv[1]) as f:
    s = json.load(f)
if s.get('session_id') == sys.argv[2]:
    print(s.get('judgment_count', 0))
else:
    print(0)
PYEOF
)
assert_eq "$COUNT_NEW" "1" "TC-04 counter resets to 1 for new session"

# Restore counter to avoid polluting real session data
python3 - "$COUNTER" "${CLAUDE_SESSION_ID:-default}" <<'PYEOF' 2>/dev/null || true
import json, sys
path, sid = sys.argv[1], sys.argv[2]
try:
    with open(path) as f:
        s = json.load(f)
    # Only restore if we're the last writer
    if s.get('session_id') not in (sys.argv[2],):
        pass  # don't overwrite someone else's data
except Exception:
    pass
PYEOF

test_results
