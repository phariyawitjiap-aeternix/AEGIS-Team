#!/usr/bin/env bash
# AEGIS Unified Test Runner
# Runs every shippable test suite in the repo and reports a summary.
# Suitable for CI, pre-commit hooks, or a manual "is-everything-green" check.
#
# Exit codes:
#   0 = all suites passed
#   1 = at least one suite failed
#   2 = a suite's test script is missing or non-executable

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "$REPO_ROOT"

# Suites to run: "label:path"
# Label is printed in the summary; path is relative to repo root.
SUITES=(
    "brain-adversarial:tools/aegis-brain-adversarial-test.sh"
    "maintainer-mode:tools/aegis-maintainer-test.sh"
    "distill-counter:tools/aegis-distill-counter-test.sh"
    "block0-mode:tools/aegis-block0-mode-test.sh"
)

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

TOTAL_PASS=0
TOTAL_FAIL=0
TOTAL_MISSING=0
OVERALL_RC=0

# Per-suite rows for the summary table
declare -a SUMMARY_ROWS

for suite in "${SUITES[@]}"; do
    label="${suite%%:*}"
    path="${suite##*:}"
    echo ""
    echo -e "${BOLD}▶ ${label}${NC} (${path})"
    echo "─────────────────────────────────────"

    if [[ ! -x "$path" ]]; then
        echo -e "${RED}MISSING${NC}: $path not found or not executable"
        SUMMARY_ROWS+=("${label}|MISSING|0|0")
        TOTAL_MISSING=$((TOTAL_MISSING + 1))
        OVERALL_RC=2
        continue
    fi

    # Capture output and parse "X passed, Y failed" line
    output=$(bash "$path" 2>&1)
    rc=$?

    # Tee to stdout for live view
    echo "$output" | tail -15

    # Extract pass/fail counts (handles both "X passed, Y failed" and "RESULTS: X passed, Y failed, Z skipped")
    pass_count=$(echo "$output" | grep -oE '[0-9]+ passed' | tail -1 | grep -oE '^[0-9]+' || echo "0")
    fail_count=$(echo "$output" | grep -oE '[0-9]+ failed' | tail -1 | grep -oE '^[0-9]+' || echo "0")

    TOTAL_PASS=$((TOTAL_PASS + pass_count))
    TOTAL_FAIL=$((TOTAL_FAIL + fail_count))

    if [[ "$rc" == "0" ]]; then
        status="${GREEN}PASS${NC}"
        SUMMARY_ROWS+=("${label}|PASS|${pass_count}|${fail_count}")
    else
        status="${RED}FAIL${NC}"
        SUMMARY_ROWS+=("${label}|FAIL|${pass_count}|${fail_count}")
        [[ "$OVERALL_RC" != "2" ]] && OVERALL_RC=1
    fi
    echo -e "Suite result: ${status} (${pass_count} passed / ${fail_count} failed)"
done

# --- Summary table ---
echo ""
echo "═════════════════════════════════════════"
echo -e "${BOLD}Summary${NC}"
echo "═════════════════════════════════════════"
printf "%-25s  %-8s  %-8s  %s\n" "Suite" "Status" "Passed" "Failed"
printf "%-25s  %-8s  %-8s  %s\n" "-------------------------" "--------" "--------" "--------"
for row in "${SUMMARY_ROWS[@]}"; do
    IFS='|' read -r label status pass fail <<< "$row"
    case "$status" in
        PASS)    color="${GREEN}PASS${NC}" ;;
        FAIL)    color="${RED}FAIL${NC}" ;;
        MISSING) color="${YELLOW}MISSING${NC}" ;;
        *)       color="$status" ;;
    esac
    printf "%-25s  %-17b  %-8s  %s\n" "$label" "$color" "$pass" "$fail"
done
echo "─────────────────────────────────────────"
echo -e "Totals: ${GREEN}${TOTAL_PASS} passed${NC}, ${RED}${TOTAL_FAIL} failed${NC}, ${YELLOW}${TOTAL_MISSING} missing${NC}"

if [[ "$OVERALL_RC" == "0" ]]; then
    echo -e "${GREEN}${BOLD}ALL SUITES GREEN${NC}"
elif [[ "$OVERALL_RC" == "1" ]]; then
    echo -e "${RED}${BOLD}SOME TESTS FAILED${NC}"
else
    echo -e "${YELLOW}${BOLD}SOME SUITES MISSING${NC}"
fi

exit "$OVERALL_RC"
