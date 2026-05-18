#!/usr/bin/env bash
# aegis-install-manifest-test.sh — sprint v15-14 regression (issue #182).
#
# Validates that install-remote.sh ships every file referenced by the
# active settings.json + .claude/hooks/*.sh. Prevents manifest drift —
# the bug class where the installer adds a new wired script but forgets
# to copy its dependencies (hooks/lib/, tool packages, etc.).
#
# Tests:
#   T1  Fresh install in temp dir → exits 0
#   T2  aegis-doctor.sh on fresh install → exits 0, no orphans
#   T3  Critical files shipped: hook libs, tool packages, _hook-utils
#   T4  Doctor fail-loud: if a wired file is deleted post-install,
#       install-remote.sh re-run would exit non-zero (uses simulated
#       orphan, not actual reinstall — that's heavier than CI tolerates).
#
# All test fixtures live under TEST_DIR and are wiped on exit. No
# Linear/multi-tenant side effects (passes --no-linear --no-mt).

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
INSTALLER="${REPO_ROOT}/install-remote.sh"
DOCTOR="${REPO_ROOT}/tools/aegis-doctor.sh"

[[ -f "$INSTALLER" ]] || { echo "FATAL: missing $INSTALLER" >&2; exit 2; }
[[ -f "$DOCTOR" ]]    || { echo "FATAL: missing $DOCTOR" >&2; exit 2; }
command -v git >/dev/null 2>&1 || { echo "FATAL: git missing" >&2; exit 2; }

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
PASS=0; FAIL=0
pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}FAIL${NC}: $1 -- $2"; FAIL=$((FAIL+1)); }

TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/aegis-install-manifest-XXXXXX")
trap 'find "$TEST_DIR" -type f -delete 2>/dev/null; find "$TEST_DIR" -depth -type d -delete 2>/dev/null' EXIT INT TERM

echo "============================================"
echo "AEGIS install manifest — sprint v15-14"
echo "============================================"

# Use a HOME override so multi-tenant registration goes to a sandboxed
# projects.yaml, not the user's real registry.
export HOME="$TEST_DIR/fake-home"
mkdir -p "$HOME"

# ── T1: install runs to completion ────────────────────────────────────────
echo ""
echo "--- T1: fresh install completes with exit 0 ---"
INSTALL_TARGET="$TEST_DIR/repro"
mkdir -p "$INSTALL_TARGET"
cd "$INSTALL_TARGET" && git init -q
INSTALL_RC=0
bash "$INSTALLER" --profile full --project-name "Manifest Test" --no-linear --no-mt --no-doctor \
    >"$TEST_DIR/install.log" 2>&1 || INSTALL_RC=$?
cd "$REPO_ROOT"

if [[ "$INSTALL_RC" == "0" ]]; then
    pass "T1: install exits 0"
else
    fail "T1: install non-zero exit" "rc=$INSTALL_RC; last lines: $(tail -3 "$TEST_DIR/install.log" 2>/dev/null | tr '\n' ' ' | head -c 200)"
fi

# ── T2: doctor finds zero orphans ──────────────────────────────────────────
echo ""
echo "--- T2: doctor on fresh install → no orphans ---"
DOCTOR_RC=0
bash "$DOCTOR" "$INSTALL_TARGET" >"$TEST_DIR/doctor.log" 2>&1 || DOCTOR_RC=$?
if [[ "$DOCTOR_RC" == "0" ]]; then
    pass "T2: doctor exits 0 — no orphans"
else
    fail "T2: doctor found orphans" "rc=$DOCTOR_RC; orphans: $(grep -c orphan "$TEST_DIR/doctor.log" 2>/dev/null || echo 0)"
    echo "    Orphan list:" >&2
    grep -E "·|orphan" "$TEST_DIR/doctor.log" 2>/dev/null | sed 's/^/    /' >&2 || true
fi

# ── T3: critical files shipped ────────────────────────────────────────────
echo ""
echo "--- T3: critical files present after install ---"

critical_files=(
    ".claude/hooks/lib/quality-check.sh"
    ".claude/hooks/lib/mbp-scan.sh"
    ".claude/hooks/lib/false-ready.sh"
    ".claude/hooks/lib/queue-banner.sh"
    "tools/aegis-approval-gate/check.mjs"
    "tools/aegis-brain-graph/hook.sh"
    "tools/aegis-brain-graph/staleness.mjs"
    "tools/aegis-live-tail/emit.mjs"
    "tools/aegis-activity-logger/log.mjs"
    "tools/aegis-run-logger/archive.mjs"
    "tools/aegis-resume/session-start.mjs"
    "tools/_hook-utils/safe-run.mjs"
    "tools/aegis-doctor.sh"
)
missing=0
for f in "${critical_files[@]}"; do
    if [[ ! -e "$INSTALL_TARGET/$f" ]]; then
        echo "  ✗ missing: $f" >&2
        missing=$((missing + 1))
    fi
done
if [[ "$missing" == "0" ]]; then
    pass "T3: all ${#critical_files[@]} critical files shipped"
else
    fail "T3: missing files" "$missing of ${#critical_files[@]} missing"
fi

# ── T4: doctor fail-loud behavior ─────────────────────────────────────────
echo ""
echo "--- T4: doctor exits non-zero when an orphan exists ---"
# Simulate manifest drift: delete one wired file, doctor should now FAIL.
TEST_ORPHAN="$INSTALL_TARGET/.claude/hooks/lib/quality-check.sh"
[[ -f "$TEST_ORPHAN" ]] && rm -f "$TEST_ORPHAN"
DOCTOR_FAIL_RC=0
bash "$DOCTOR" "$INSTALL_TARGET" >/dev/null 2>&1 || DOCTOR_FAIL_RC=$?
if [[ "$DOCTOR_FAIL_RC" != "0" ]]; then
    pass "T4: doctor exits ${DOCTOR_FAIL_RC} when an orphan is injected"
else
    fail "T4: doctor missed injected orphan" "expected non-zero, got 0"
fi

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
echo "============================================"

if [[ "$FAIL" -gt 0 ]]; then
    exit 1
fi
exit 0
