#!/usr/bin/env bash
# AEGIS Test — aegis-instinct-promote-test.sh (S2-05)
#
# Tests tools/aegis-instinct-promote.sh lifecycle commands.
# 10 test cases per spec §5.7 + S-01 validation (TC-10).
# Exit 0: all pass  |  Exit 1: one or more failures
#
# Uses AEGIS_INSTINCT_ROOT env override to redirect to a temp directory.
#
# Usage:
#   bash tools/aegis-instinct-promote-test.sh
#   bash tools/aegis-instinct-promote-test.sh --verbose

set -uo pipefail

VERBOSE=0
[[ "${1:-}" == "--verbose" ]] && VERBOSE=1

PASS=0
FAIL=0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL="${SCRIPT_DIR}/aegis-instinct-promote.sh"

if [[ ! -f "$TOOL" ]]; then
    echo "ERROR: $TOOL not found"
    exit 1
fi

# ── Temp directory for all test instincts ────────────────────────────────
TMPDIR_BASE=$(mktemp -d 2>/dev/null || mktemp -d -t 'aegis-instinct-test')
export AEGIS_INSTINCT_ROOT="${TMPDIR_BASE}/instincts"
export AEGIS_ACTIVITY_LOG="${TMPDIR_BASE}/activity.log"
mkdir -p "${AEGIS_INSTINCT_ROOT}/pending" \
         "${AEGIS_INSTINCT_ROOT}/active" \
         "${AEGIS_INSTINCT_ROOT}/promoted" \
         "${AEGIS_INSTINCT_ROOT}/retired"
trap 'rm -rf "$TMPDIR_BASE"' EXIT

# Temp resonance file for create tests
RESONANCE_FILE="${TMPDIR_BASE}/test-resonance.md"
cat > "$RESONANCE_FILE" << 'EOF'
# Test Resonance

## Pattern
Always validate input before processing to prevent injection attacks.

## Rationale
Observed in 3 security incidents.
EOF

# ── Test runner ───────────────────────────────────────────────────────────
run_test() {
    local num="$1"
    local desc="$2"
    local result="$3"  # "pass" or "fail"

    if [[ "$result" == "pass" ]]; then
        PASS=$((PASS + 1))
        [[ $VERBOSE -eq 1 ]] && echo "  PASS [TC-${num}]: ${desc}"
    else
        FAIL=$((FAIL + 1))
        echo "  FAIL [TC-${num}]: ${desc}"
    fi
}

get_field() {
    local file="$1"
    local field="$2"
    grep "^${field}:" "$file" 2>/dev/null | sed "s/^${field}: *//" | tr -d '"' | tr -d "'" | head -1
}

echo "aegis-instinct-promote.sh — 10 Test Cases"
echo "==========================================="

# TC-1: create --from produces valid YAML in pending/
# Assertion: file exists, status=pending, confidence=0.3
tc1_result="fail"
bash "$TOOL" create --from "$RESONANCE_FILE" --id "tc1-validate-input" --cluster "security" > /dev/null 2>&1
YAML_FILE="${AEGIS_INSTINCT_ROOT}/pending/tc1-validate-input.yaml"
if [[ -f "$YAML_FILE" ]]; then
    status=$(get_field "$YAML_FILE" "status")
    confidence=$(get_field "$YAML_FILE" "confidence")
    if [[ "$status" == "pending" && "$confidence" == "0.3" ]]; then
        tc1_result="pass"
    fi
fi
run_test 1 "create --from produces valid YAML in pending/ (status=pending, confidence=0.3)" "$tc1_result"

# TC-2: activate with sufficient confidence+observations -> moves to active/
tc2_result="fail"
# Set confidence=0.6 and observations=2 on the pending file
YAML_PENDING="${AEGIS_INSTINCT_ROOT}/pending/tc1-validate-input.yaml"
sed -i.bak "s/^confidence: .*/confidence: 0.6/" "$YAML_PENDING"
sed -i.bak "s/^observations: .*/observations: 2/" "$YAML_PENDING"
rm -f "${YAML_PENDING}.bak"
bash "$TOOL" activate --id "tc1-validate-input" > /dev/null 2>&1
ACTIVE_FILE="${AEGIS_INSTINCT_ROOT}/active/tc1-validate-input.yaml"
if [[ -f "$ACTIVE_FILE" && ! -f "$YAML_PENDING" ]]; then
    status=$(get_field "$ACTIVE_FILE" "status")
    [[ "$status" == "active" ]] && tc2_result="pass"
fi
run_test 2 "activate with confidence>0.5, observations>=2 -> moves to active/" "$tc2_result"

# TC-3: activate rejected when confidence <= 0.5 -> exit 1, file stays in pending/
tc3_result="fail"
# Create a fresh low-confidence pending instinct
bash "$TOOL" create --from "$RESONANCE_FILE" --id "tc3-low-conf" --cluster "test" > /dev/null 2>&1
LOW_CONF_FILE="${AEGIS_INSTINCT_ROOT}/pending/tc3-low-conf.yaml"
# confidence=0.3 (default), observations=1 (default)
set +e
bash "$TOOL" activate --id "tc3-low-conf" > /dev/null 2>&1
exit_code=$?
set -e
if [[ $exit_code -ne 0 && -f "$LOW_CONF_FILE" && ! -f "${AEGIS_INSTINCT_ROOT}/active/tc3-low-conf.yaml" ]]; then
    tc3_result="pass"
fi
run_test 3 "activate rejected: confidence<=0.5 -> exit 1, file stays in pending/" "$tc3_result"

# TC-4: activate rejected when observations < 2 -> exit 1, file stays in pending/
tc4_result="fail"
bash "$TOOL" create --from "$RESONANCE_FILE" --id "tc4-low-obs" --cluster "test" > /dev/null 2>&1
TC4_FILE="${AEGIS_INSTINCT_ROOT}/pending/tc4-low-obs.yaml"
# Raise confidence to 0.7 but keep observations=1
sed -i.bak "s/^confidence: .*/confidence: 0.7/" "$TC4_FILE"
rm -f "${TC4_FILE}.bak"
set +e
bash "$TOOL" activate --id "tc4-low-obs" > /dev/null 2>&1
exit_code=$?
set -e
if [[ $exit_code -ne 0 && -f "$TC4_FILE" && ! -f "${AEGIS_INSTINCT_ROOT}/active/tc4-low-obs.yaml" ]]; then
    tc4_result="pass"
fi
run_test 4 "activate rejected: observations<2 -> exit 1, file stays in pending/" "$tc4_result"

# TC-5: promote with confidence > 0.8 -> moves to promoted/
tc5_result="fail"
# tc1-validate-input is now in active/; set confidence=0.9
ACTIVE_PROMOTE="${AEGIS_INSTINCT_ROOT}/active/tc1-validate-input.yaml"
if [[ -f "$ACTIVE_PROMOTE" ]]; then
    sed -i.bak "s/^confidence: .*/confidence: 0.9/" "$ACTIVE_PROMOTE"
    rm -f "${ACTIVE_PROMOTE}.bak"
    bash "$TOOL" promote --id "tc1-validate-input" > /dev/null 2>&1
    PROMOTED_FILE="${AEGIS_INSTINCT_ROOT}/promoted/tc1-validate-input.yaml"
    if [[ -f "$PROMOTED_FILE" && ! -f "$ACTIVE_PROMOTE" ]]; then
        status=$(get_field "$PROMOTED_FILE" "status")
        [[ "$status" == "promoted" ]] && tc5_result="pass"
    fi
fi
run_test 5 "promote with confidence>0.8 -> moves to promoted/, status=promoted" "$tc5_result"

# TC-6: promote rejected when confidence <= 0.8 -> exit 1, file stays in active/
tc6_result="fail"
# Create a new pending->active instinct with moderate confidence
bash "$TOOL" create --from "$RESONANCE_FILE" --id "tc6-mod-conf" --cluster "test" > /dev/null 2>&1
TC6_PEND="${AEGIS_INSTINCT_ROOT}/pending/tc6-mod-conf.yaml"
sed -i.bak "s/^confidence: .*/confidence: 0.7/" "$TC6_PEND"
sed -i.bak "s/^observations: .*/observations: 2/" "$TC6_PEND"
rm -f "${TC6_PEND}.bak"
bash "$TOOL" activate --id "tc6-mod-conf" > /dev/null 2>&1
TC6_ACTIVE="${AEGIS_INSTINCT_ROOT}/active/tc6-mod-conf.yaml"
set +e
bash "$TOOL" promote --id "tc6-mod-conf" > /dev/null 2>&1
exit_code=$?
set -e
if [[ $exit_code -ne 0 && -f "$TC6_ACTIVE" && ! -f "${AEGIS_INSTINCT_ROOT}/promoted/tc6-mod-conf.yaml" ]]; then
    tc6_result="pass"
fi
run_test 6 "promote rejected: confidence<=0.8 -> exit 1, file stays in active/" "$tc6_result"

# TC-7: retire moves from any tier to retired/, sets retired_date
tc7_result="fail"
bash "$TOOL" retire --id "tc6-mod-conf" --reason "superseded by tc7" > /dev/null 2>&1
RETIRED_FILE="${AEGIS_INSTINCT_ROOT}/retired/tc6-mod-conf.yaml"
if [[ -f "$RETIRED_FILE" && ! -f "$TC6_ACTIVE" ]]; then
    status=$(get_field "$RETIRED_FILE" "status")
    retired_date=$(get_field "$RETIRED_FILE" "retired_date")
    if [[ "$status" == "retired" && -n "$retired_date" ]]; then
        tc7_result="pass"
    fi
fi
run_test 7 "retire moves to retired/, status=retired, retired_date set" "$tc7_result"

# TC-8: list --tier pending shows only pending instincts, not active/promoted
tc8_result="fail"
list_output=$(bash "$TOOL" list --tier pending 2>/dev/null)
# Should contain tc3-low-conf and tc4-low-obs (still in pending)
# Should NOT contain tc1-validate-input (now in promoted)
if echo "$list_output" | grep -q "tc3-low-conf" && \
   ! echo "$list_output" | grep -q "tc1-validate-input"; then
    tc8_result="pass"
fi
run_test 8 "list --tier pending shows only pending instincts (not active/promoted)" "$tc8_result"

# TC-10: malformed --id (path traversal / uppercase / spaces) rejected with exit 2
tc10_result="fail"
set +e
bash "$TOOL" activate --id "../../etc/malicious" > /dev/null 2>&1
exit_code_a=$?
bash "$TOOL" activate --id "Bad_ID" > /dev/null 2>&1
exit_code_b=$?
bash "$TOOL" reinforce --id "../escape" > /dev/null 2>&1
exit_code_c=$?
set -e
if [[ $exit_code_a -eq 2 && $exit_code_b -eq 2 && $exit_code_c -eq 2 ]]; then
    tc10_result="pass"
fi
run_test 10 "malformed --id (path traversal / uppercase / slashes) rejected with exit 2" "$tc10_result"

# TC-9: reinforce increments observations +1, updates last_reinforced, confidence unchanged
tc9_result="fail"
# Use tc3-low-conf in pending; observations should be 1
TC9_FILE="${AEGIS_INSTINCT_ROOT}/pending/tc3-low-conf.yaml"
if [[ -f "$TC9_FILE" ]]; then
    obs_before=$(get_field "$TC9_FILE" "observations")
    conf_before=$(get_field "$TC9_FILE" "confidence")
    bash "$TOOL" reinforce --id "tc3-low-conf" > /dev/null 2>&1
    obs_after=$(get_field "$TC9_FILE" "observations")
    conf_after=$(get_field "$TC9_FILE" "confidence")
    last_reinforced=$(get_field "$TC9_FILE" "last_reinforced")
    expected_obs=$(( obs_before + 1 ))
    today=$(date -u +"%Y-%m-%d" 2>/dev/null || date +"%Y-%m-%d")
    if [[ "$obs_after" -eq "$expected_obs" && \
          "$conf_after" == "$conf_before" && \
          "$last_reinforced" == *"$today"* ]]; then
        tc9_result="pass"
    fi
fi
run_test 9 "reinforce: observations+1, last_reinforced=today, confidence unchanged" "$tc9_result"

echo ""
echo "==========================================="
echo "Results: ${PASS} passed, ${FAIL} failed"
echo "==========================================="

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
exit 0
