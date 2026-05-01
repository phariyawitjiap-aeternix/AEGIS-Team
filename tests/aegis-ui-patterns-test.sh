#!/usr/bin/env bash
# AEGIS Test — aegis-ui-patterns-test.sh (S3-05)
#
# Tests tools/aegis-ui-patterns.sh SSOT file.
# 7 test cases per spec §2.4.
# Exit 0: all pass  |  Exit 1: one or more failures
#
# Usage:
#   bash tools/aegis-ui-patterns-test.sh
#   bash tools/aegis-ui-patterns-test.sh --verbose

set -uo pipefail

VERBOSE=0
[[ "${1:-}" == "--verbose" ]] && VERBOSE=1

PASS=0
FAIL=0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATTERNS_FILE="${SCRIPT_DIR}/../tools/aegis-ui-patterns.sh"

# Verify the SSOT file exists
if [[ ! -f "$PATTERNS_FILE" ]]; then
    echo "ERROR: $PATTERNS_FILE not found"
    exit 1
fi

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

echo "aegis-ui-patterns.sh — 7 Test Cases"
echo "======================================"

# TC-1: Source sets UI_INCLUDE_EXTENSIONS, array non-empty (>= 6)
tc1_result="fail"
(
    # shellcheck source=./aegis-ui-patterns.sh
    source "$PATTERNS_FILE"
    [[ ${#UI_INCLUDE_EXTENSIONS[@]} -ge 6 ]]
) && tc1_result="pass"
run_test 1 "source sets UI_INCLUDE_EXTENSIONS (>= 6 entries)" "$tc1_result"

# TC-2: Source sets UI_INCLUDE_DIRS, array non-empty (>= 5)
tc2_result="fail"
(
    # shellcheck source=./aegis-ui-patterns.sh
    source "$PATTERNS_FILE"
    [[ ${#UI_INCLUDE_DIRS[@]} -ge 5 ]]
) && tc2_result="pass"
run_test 2 "source sets UI_INCLUDE_DIRS (>= 5 entries)" "$tc2_result"

# TC-3: Source sets UI_EXCLUDE_SUFFIXES, array non-empty (>= 3)
tc3_result="fail"
(
    # shellcheck source=./aegis-ui-patterns.sh
    source "$PATTERNS_FILE"
    [[ ${#UI_EXCLUDE_SUFFIXES[@]} -ge 3 ]]
) && tc3_result="pass"
run_test 3 "source sets UI_EXCLUDE_SUFFIXES (>= 3 entries)" "$tc3_result"

# TC-4: is_ui_file returns 0 for src/components/Foo.tsx
tc4_result="fail"
(
    # shellcheck source=./aegis-ui-patterns.sh
    source "$PATTERNS_FILE"
    is_ui_file "src/components/Foo.tsx"
) && tc4_result="pass"
run_test 4 "is_ui_file returns 0 for src/components/Foo.tsx" "$tc4_result"

# TC-5: is_excluded_file returns 0 for Button.test.tsx
tc5_result="fail"
(
    # shellcheck source=./aegis-ui-patterns.sh
    source "$PATTERNS_FILE"
    is_excluded_file "Button.test.tsx"
) && tc5_result="pass"
run_test 5 "is_excluded_file returns 0 for Button.test.tsx" "$tc5_result"

# TC-6: Source works from /tmp cwd (different working directory)
tc6_result="fail"
(
    cd /tmp
    # shellcheck source=/dev/null
    source "$PATTERNS_FILE"
    # Arrays populated and functions callable from /tmp
    [[ ${#UI_INCLUDE_EXTENSIONS[@]} -ge 6 ]] && is_ui_file "src/components/Foo.tsx"
) && tc6_result="pass"
run_test 6 "source works from /tmp cwd (cross-cwd sourcing)" "$tc6_result"

# TC-7: Source works under set -u (nounset) — no unset-variable error
tc7_result="fail"
bash_out=$(bash -c "set -u; source '${PATTERNS_FILE}'; echo ok" 2>&1) && \
    [[ "$bash_out" == *"ok"* ]] && tc7_result="pass"
run_test 7 "source under set -u causes no unset-variable error" "$tc7_result"

echo ""
echo "======================================"
echo "Results: ${PASS} passed, ${FAIL} failed"
echo "======================================"

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
exit 0
