#!/usr/bin/env bash
# aegis-notify-test.sh — Regression net for tools/aegis-notify.sh.
#
# Sprint v15-08. Covers the CC 2.1.141 `terminalSequence` adoption:
#   T1  Helper sources cleanly + defines aegis_notify
#   T2  BEL fallback fires to stderr by default (AEGIS_HOOK_NOTIFY unset)
#   T3  JSON terminalSequence emitted to stdout when AEGIS_HOOK_NOTIFY=1
#   T4  Emitted JSON is strict + additive — has ONLY `terminalSequence`
#       (no `continue` field that would confuse Stop hook semantics)
#   T5  Notify log file is written under .aegis/brain/logs/notify.log
#   T6  Re-entrant guard prevents double-sourcing side-effects
#   T7  Standalone `bash tools/aegis-notify.sh test` smoke path works
#   T8  AEGIS_NOTIFY_BEL=0 suppresses the stderr BEL
#
# All output goes to TEST_DIR (no pollution of the repo's notify log).

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
NOTIFY="${REPO_ROOT}/tools/aegis-notify.sh"

[[ -f "$NOTIFY" ]] || { echo "FATAL: notify helper missing at $NOTIFY" >&2; exit 2; }

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
PASS=0; FAIL=0
pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}FAIL${NC}: $1 — $2"; FAIL=$((FAIL+1)); }

TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/aegis-notify-test-XXXXXX")
trap 'find "$TEST_DIR" -type f -delete 2>/dev/null; find "$TEST_DIR" -type d -delete 2>/dev/null' EXIT INT TERM

echo "============================================"
echo "AEGIS notify helper regression tests"
echo "============================================"

# ── T1: Source + symbol export ────────────────────────────────────────────
echo ""
echo "--- T1: source + aegis_notify defined ---"
( source "$NOTIFY" && declare -f aegis_notify >/dev/null ) && \
    pass "T1: source clean + aegis_notify defined" || \
    fail "T1: source failed or aegis_notify missing" "expected function defined"

# ── T2: BEL on stderr by default ──────────────────────────────────────────
echo ""
echo "--- T2: BEL fires to stderr by default ---"
stderr_file="$TEST_DIR/t2-stderr"
(
    unset AEGIS_HOOK_NOTIFY
    export AEGIS_NOTIFY_LOG="$TEST_DIR/notify.log"
    source "$NOTIFY"
    aegis_notify "test_event" "hello"
) >/dev/null 2> "$stderr_file"
# Check for BEL (0x07) byte in the captured stderr file via od octal output.
if od -An -b "$stderr_file" 2>/dev/null | tr -s ' ' '\n' | grep -qx '007'; then
    pass "T2: BEL (0x07) present in stderr"
else
    fail "T2: BEL missing from stderr" "od bytes: $(od -An -b "$stderr_file" 2>/dev/null | head -1)"
fi

# ── T3: JSON terminalSequence on stdout when opted in ─────────────────────
echo ""
echo "--- T3: JSON terminalSequence emits to stdout with AEGIS_HOOK_NOTIFY=1 ---"
stdout_out=$(
    export AEGIS_HOOK_NOTIFY=1
    export AEGIS_NOTIFY_LOG="$TEST_DIR/notify.log"
    source "$NOTIFY"
    aegis_notify "test_event" "ping" 2>/dev/null
)
if printf '%s' "$stdout_out" | grep -q '"terminalSequence"'; then
    pass "T3: stdout has terminalSequence JSON"
else
    fail "T3: stdout missing terminalSequence" "got: ${stdout_out:0:200}"
fi

# ── T4: JSON is strictly additive (no `continue` field) ───────────────────
echo ""
echo "--- T4: JSON omits 'continue' field (Stop-hook safety) ---"
if printf '%s' "$stdout_out" | python3 -c '
import json, sys
data = json.loads(sys.stdin.read().strip())
assert "terminalSequence" in data, "terminalSequence missing"
assert "continue" not in data, "continue must NOT be present (Stop-hook collision risk)"
assert len(data) == 1, f"expected exactly 1 key, got: {list(data.keys())}"
' 2>/dev/null; then
    pass "T4: JSON shape is {terminalSequence: ...} only"
else
    fail "T4: JSON shape wrong" "expected exactly {terminalSequence}; got: $stdout_out"
fi

# ── T5: notify log written ────────────────────────────────────────────────
echo ""
echo "--- T5: notify log file written ---"
log_path="$TEST_DIR/notify.log"
(
    export AEGIS_HOOK_NOTIFY=1
    export AEGIS_NOTIFY_LOG="$log_path"
    source "$NOTIFY"
    aegis_notify "log_event" "log smoke test"
) >/dev/null 2>&1
if [[ -f "$log_path" ]] && grep -q "log_event" "$log_path"; then
    pass "T5: log file contains event entry"
else
    fail "T5: log not written" "expected file $log_path with log_event"
fi

# ── T6: Re-entrant guard ──────────────────────────────────────────────────
echo ""
echo "--- T6: double-source is a no-op ---"
double_source_check=$(
    set +u  # subshell may not have set -u
    source "$NOTIFY"
    # Mark a sentinel — if helper re-runs its setup, sentinel should NOT
    # be overwritten because guard exits early on second source.
    _AEGIS_NOTIFY_BEL="POISONED"
    source "$NOTIFY"
    printf '%s' "$_AEGIS_NOTIFY_BEL"
)
if [[ "$double_source_check" == "POISONED" ]]; then
    pass "T6: re-entrant guard prevents re-initialization"
else
    fail "T6: helper re-ran on second source" "sentinel got: '$double_source_check'"
fi

# ── T7: Standalone smoke test path ────────────────────────────────────────
echo ""
echo "--- T7: standalone 'bash tools/aegis-notify.sh test' works ---"
out=$(
    AEGIS_NOTIFY_LOG="$TEST_DIR/standalone.log" \
        bash "$NOTIFY" test smoke_event "smoke test message" 2>/dev/null
)
if printf '%s' "$out" | grep -q '"terminalSequence"'; then
    pass "T7: standalone test emits JSON"
else
    fail "T7: standalone test no JSON" "got: ${out:0:200}"
fi

# ── T8: AEGIS_NOTIFY_BEL=0 suppresses BEL ─────────────────────────────────
echo ""
echo "--- T8: AEGIS_NOTIFY_BEL=0 suppresses the stderr BEL ---"
suppressed_err_file="$TEST_DIR/t8-stderr"
(
    unset AEGIS_HOOK_NOTIFY
    export AEGIS_NOTIFY_BEL=0
    export AEGIS_NOTIFY_LOG="$TEST_DIR/notify.log"
    source "$NOTIFY"
    aegis_notify "no_bel" "silent"
) >/dev/null 2> "$suppressed_err_file"
if ! od -An -b "$suppressed_err_file" 2>/dev/null | tr -s ' ' '\n' | grep -qx '007'; then
    pass "T8: BEL suppressed when AEGIS_NOTIFY_BEL=0"
else
    fail "T8: BEL leaked despite suppression" "od bytes: $(od -An -b "$suppressed_err_file" 2>/dev/null | head -1)"
fi

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
echo "============================================"

if [[ "$FAIL" -gt 0 ]]; then
    exit 1
fi
exit 0
