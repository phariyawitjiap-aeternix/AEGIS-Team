#!/usr/bin/env bash
# AEGIS BLOCK 0 Gate Test (Sprint v9-02 S2-03 — D-01)
#
# Validates the skip-log behavior of Nick Fury's BLOCK_0_PROCEDURE by simulating
# what Nick Fury WOULD emit for each mode, using tools/aegis-block0-mode.sh as
# the testable equivalent per spec §6.
#
# The helper resolves REPO_ROOT from its own script directory, so --task-id
# always reads from the real repo. Tests therefore pass --points/--tags directly
# (the same flags Nick Fury uses when meta.json is not yet present) or read the
# pinned block0_mode from a temp meta.json themselves.
#
# Test cases:
#   TC-01  lite mode     — skipped=0A, skipped=0B, skipped=0E; no PM.01/SI.01/SI.02 files
#   TC-02  standard mode — skipped=0E only; PM.01 + SI.01 created
#   TC-03  full mode     — no skip lines; all 5 artifact placeholders present
#
# Exit: 0 = all pass, 1 = first failure (message printed to stderr)
#
# Usage: bash tools/aegis-block0-gate-test.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
HELPER="${SCRIPT_DIR}/../tools/aegis-block0-mode.sh"

if [[ ! -x "$HELPER" ]]; then
    echo "ERROR: helper not found or not executable: $HELPER" >&2
    exit 1
fi

# ── helpers ──────────────────────────────────────────────────────────────────

PASS_COUNT=0
FAIL_COUNT=0

pass() { echo "  PASS: $1"; PASS_COUNT=$((PASS_COUNT + 1)); }

fail() {
    echo "  FAIL: $1" >&2
    FAIL_COUNT=$((FAIL_COUNT + 1))
    echo "" >&2
    echo "Assertion failed — aborting." >&2
    exit 1
}

assert_log_contains() {
    local log="$1" pattern="$2" label="$3"
    if grep -qF "$pattern" "$log" 2>/dev/null; then
        pass "$label"
    else
        fail "$label | pattern not found: '$pattern' in $log"
    fi
}

assert_log_not_contains() {
    local log="$1" pattern="$2" label="$3"
    if grep -qF "$pattern" "$log" 2>/dev/null; then
        fail "$label | unexpected pattern found: '$pattern' in $log"
    else
        pass "$label"
    fi
}

assert_file_exists() {
    local file="$1" label="$2"
    if [[ -f "$file" ]]; then
        pass "$label"
    else
        fail "$label | file missing: $file"
    fi
}

assert_file_absent() {
    local file="$1" label="$2"
    if [[ -f "$file" ]]; then
        fail "$label | file should not exist: $file"
    else
        pass "$label"
    fi
}

# ── simulate_block0 ───────────────────────────────────────────────────────────
#
# Emulates the skip-log emission that Nick Fury's BLOCK_0_PROCEDURE would produce.
# Accepts the mode directly (already resolved by the caller via --points/--tags
# or by reading meta.json), then writes [HOOK:block0] lines to a test log and
# creates artifact stubs for checks that are NOT skipped.
#
# Mode table (spec §4 / nick-fury.md BLOCK 0):
#   Check  | lite    | standard | full
#   0A (PM.01)  | skip    | require  | require
#   0B (SI.01)  | skip    | require  | require
#   0C (tasks)  | require | require  | require
#   0D (kanban) | require | require  | require
#   0E (SI.02)  | skip    | skip     | require
#
simulate_block0() {
    local task_id="$1" mode="$2" log_file="$3" out_dir="$4"
    local ts="2026-01-01T00:00:00Z"

    echo "${ts} [HOOK:block0] task=${task_id} mode=${mode} determined" >> "$log_file"

    # --- Check 0A (PM.01) ---
    if [[ "$mode" == "lite" ]]; then
        echo "${ts} [HOOK:block0] task=${task_id} mode=${mode} skipped=0A" >> "$log_file"
    else
        mkdir -p "${out_dir}/iso-docs/PM-01-project-plan"
        echo "# PM.01 stub" > "${out_dir}/iso-docs/PM-01-project-plan/current.md"
    fi

    # --- Check 0B (SI.01) ---
    if [[ "$mode" == "lite" ]]; then
        echo "${ts} [HOOK:block0] task=${task_id} mode=${mode} skipped=0B" >> "$log_file"
    else
        mkdir -p "${out_dir}/iso-docs/SI-01-requirements-spec"
        echo "# SI.01 stub" > "${out_dir}/iso-docs/SI-01-requirements-spec/current.md"
    fi

    # --- Check 0C (tasks) — always required ---
    mkdir -p "${out_dir}/tasks"
    echo "{}" > "${out_dir}/tasks/meta.json"

    # --- Check 0D (kanban) — always required ---
    mkdir -p "${out_dir}/kanban"
    echo "# kanban stub" > "${out_dir}/kanban/kanban.md"

    # --- Check 0E (SI.02) ---
    if [[ "$mode" == "lite" || "$mode" == "standard" ]]; then
        echo "${ts} [HOOK:block0] task=${task_id} mode=${mode} skipped=0E" >> "$log_file"
    else
        mkdir -p "${out_dir}/iso-docs/SI-02-traceability-matrix"
        echo "# SI.02 stub" > "${out_dir}/iso-docs/SI-02-traceability-matrix/current.md"
    fi
}

# ── TC-01: lite mode ──────────────────────────────────────────────────────────

echo ""
echo "TC-01: lite mode (typo tag, 1pt — helper should emit: lite)"

TC01_DIR=$(mktemp -d)
trap 'rm -rf "$TC01_DIR"' EXIT

TASK_ID_01="TEST-T-001"
MODE_01=$("$HELPER" --points 1 --tags "typo")

echo "  helper returned: ${MODE_01}"
if [[ "$MODE_01" != "lite" ]]; then
    fail "TC-01: expected helper to return 'lite', got '${MODE_01}'"
fi

LOG_01="${TC01_DIR}/activity.log"
OUT_01="${TC01_DIR}/output"
simulate_block0 "$TASK_ID_01" "$MODE_01" "$LOG_01" "$OUT_01"

assert_log_contains     "$LOG_01" "skipped=0A" "TC-01: log contains skipped=0A"
assert_log_contains     "$LOG_01" "skipped=0B" "TC-01: log contains skipped=0B"
assert_log_contains     "$LOG_01" "skipped=0E" "TC-01: log contains skipped=0E"
assert_file_absent  "${OUT_01}/iso-docs/PM-01-project-plan/current.md"           "TC-01: PM.01 NOT created"
assert_file_absent  "${OUT_01}/iso-docs/SI-01-requirements-spec/current.md"      "TC-01: SI.01 NOT created"
assert_file_absent  "${OUT_01}/iso-docs/SI-02-traceability-matrix/current.md"    "TC-01: SI.02 NOT created"
assert_log_not_contains "$LOG_01" "skipped=0C" "TC-01: 0C not skipped"
assert_log_not_contains "$LOG_01" "skipped=0D" "TC-01: 0D not skipped"

trap '' EXIT
rm -rf "$TC01_DIR"

# ── TC-02: standard mode ──────────────────────────────────────────────────────

echo ""
echo "TC-02: standard mode (3pt, no special tags — helper should emit: standard)"

TC02_DIR=$(mktemp -d)
trap 'rm -rf "$TC02_DIR"' EXIT

TASK_ID_02="TEST-T-002"
MODE_02=$("$HELPER" --points 3 --tags "")

echo "  helper returned: ${MODE_02}"
if [[ "$MODE_02" != "standard" ]]; then
    fail "TC-02: expected helper to return 'standard', got '${MODE_02}'"
fi

LOG_02="${TC02_DIR}/activity.log"
OUT_02="${TC02_DIR}/output"
simulate_block0 "$TASK_ID_02" "$MODE_02" "$LOG_02" "$OUT_02"

assert_log_not_contains "$LOG_02" "skipped=0A" "TC-02: 0A not skipped"
assert_log_not_contains "$LOG_02" "skipped=0B" "TC-02: 0B not skipped (SI.01 required)"
assert_log_contains     "$LOG_02" "skipped=0E" "TC-02: log contains skipped=0E"
assert_file_exists  "${OUT_02}/iso-docs/PM-01-project-plan/current.md"       "TC-02: PM.01 created"
assert_file_exists  "${OUT_02}/iso-docs/SI-01-requirements-spec/current.md"  "TC-02: SI.01 created"
assert_file_absent  "${OUT_02}/iso-docs/SI-02-traceability-matrix/current.md" "TC-02: SI.02 NOT created"

trap '' EXIT
rm -rf "$TC02_DIR"

# ── TC-03: full mode ──────────────────────────────────────────────────────────

echo ""
echo "TC-03: full mode (8pt, feature tag — helper should emit: full)"

TC03_DIR=$(mktemp -d)
trap 'rm -rf "$TC03_DIR"' EXIT

TASK_ID_03="TEST-T-003"
MODE_03=$("$HELPER" --points 8 --tags "feature")

echo "  helper returned: ${MODE_03}"
if [[ "$MODE_03" != "full" ]]; then
    fail "TC-03: expected helper to return 'full', got '${MODE_03}'"
fi

LOG_03="${TC03_DIR}/activity.log"
OUT_03="${TC03_DIR}/output"
simulate_block0 "$TASK_ID_03" "$MODE_03" "$LOG_03" "$OUT_03"

assert_log_not_contains "$LOG_03" "skipped=0A" "TC-03: 0A not skipped"
assert_log_not_contains "$LOG_03" "skipped=0B" "TC-03: 0B not skipped"
assert_log_not_contains "$LOG_03" "skipped=0E" "TC-03: 0E not skipped"
assert_file_exists "${OUT_03}/iso-docs/PM-01-project-plan/current.md"         "TC-03: PM.01 created"
assert_file_exists "${OUT_03}/iso-docs/SI-01-requirements-spec/current.md"    "TC-03: SI.01 created"
assert_file_exists "${OUT_03}/tasks/meta.json"                                 "TC-03: tasks stub created"
assert_file_exists "${OUT_03}/kanban/kanban.md"                                "TC-03: kanban stub created"
assert_file_exists "${OUT_03}/iso-docs/SI-02-traceability-matrix/current.md"  "TC-03: SI.02 created"

trap '' EXIT
rm -rf "$TC03_DIR"

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "Results: ${PASS_COUNT} passed, ${FAIL_COUNT} failed"

if [[ "$FAIL_COUNT" -gt 0 ]]; then
    exit 1
fi
echo "All gate tests passed."
exit 0
