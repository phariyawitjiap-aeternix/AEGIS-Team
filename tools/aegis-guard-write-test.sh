#!/usr/bin/env bash
# AEGIS Test — aegis-guard-write-test.sh
#
# Tests the guard-write.sh PreToolUse hook.
# Includes S3-03 design-library immutability cases (N+1, N+2 per spec §8 Security).
# Exit 0: all pass  |  Exit 1: one or more failures
#
# Usage:
#   bash tools/aegis-guard-write-test.sh
#   bash tools/aegis-guard-write-test.sh --verbose

set -uo pipefail

VERBOSE=0
[[ "${1:-}" == "--verbose" ]] && VERBOSE=1

PASS=0
FAIL=0

HOOK=".claude/hooks/guard-write.sh"
REPO_ROOT="$(pwd)"

if [[ ! -f "${REPO_ROOT}/${HOOK}" ]]; then
    echo "ERROR: ${HOOK} not found"
    exit 1
fi

# ── Test runner ───────────────────────────────────────────────────────────
run_test() {
    local num="$1"
    local desc="$2"
    local expected_exit="$3"
    local expected_contains="${4:-}"
    local json_input="$5"
    local env_extras="${6:-}"  # additional env vars as "KEY=VAL KEY2=VAL2"

    local actual_exit=0
    local actual_output
    if [[ -n "$env_extras" ]]; then
        actual_output=$(echo "$json_input" | env $env_extras bash "${REPO_ROOT}/${HOOK}" 2>/dev/null) || actual_exit=$?
    else
        actual_output=$(echo "$json_input" | bash "${REPO_ROOT}/${HOOK}" 2>/dev/null) || actual_exit=$?
    fi

    local ok=1
    [[ "$actual_exit" != "$expected_exit" ]] && ok=0
    [[ -n "$expected_contains" && "$actual_output" != *"$expected_contains"* ]] && ok=0

    if [[ "$ok" -eq 1 ]]; then
        PASS=$((PASS + 1))
        [[ $VERBOSE -eq 1 ]] && echo "  PASS [TC-${num}]: ${desc} (exit=${actual_exit})"
    else
        FAIL=$((FAIL + 1))
        echo "  FAIL [TC-${num}]: ${desc}"
        echo "         expected exit: ${expected_exit}, got: ${actual_exit}"
        if [[ -n "$expected_contains" ]]; then
            echo "         expected output to contain: '${expected_contains}'"
            echo "         actual output: '${actual_output}'"
        fi
    fi
}

echo "guard-write.sh — Test Cases"
echo "============================="

# ── Config protection (existing functionality) ────────────────────────────
run_test 1 \
    "Block .eslintrc edit -> exit 2 + AEGIS Config Protection" \
    "2" "AEGIS Config Protection" \
    '{"tool_name":"Edit","tool_input":{"file_path":".eslintrc"}}'

run_test 2 \
    "Block tsconfig.json edit -> exit 2" \
    "2" "AEGIS Config Protection" \
    '{"tool_name":"Edit","tool_input":{"file_path":"tsconfig.json"}}'

run_test 3 \
    "Block jest.config.js edit -> exit 2" \
    "2" "AEGIS Config Protection" \
    '{"tool_name":"Edit","tool_input":{"file_path":"jest.config.js"}}'

run_test 4 \
    "Allow README.md edit -> exit 0" \
    "0" "" \
    '{"tool_name":"Edit","tool_input":{"file_path":"README.md"}}'

run_test 5 \
    "Allow src/app.ts edit -> exit 0" \
    "0" "" \
    '{"tool_name":"Edit","tool_input":{"file_path":"src/app.ts"}}'

run_test 6 \
    "Allow Bash tool -> exit 0 (hook not applicable)" \
    "0" "" \
    '{"tool_name":"Bash","tool_input":{"command":"ls"}}'

# ── AEGIS self-protection ─────────────────────────────────────────────────
run_test 7 \
    "Block .claude/settings.json edit -> exit 2 + AEGIS Self-Protection" \
    "2" "AEGIS Self-Protection" \
    '{"tool_name":"Edit","tool_input":{"file_path":".claude/settings.json"}}'

# ── S3-03: design-library immutability (N+1, N+2 per spec §8) ────────────
run_test "N+1" \
    "Block .aegis/brain/design-library/stripe/DESIGN.md edit -> exit 2 + AEGIS Self-Protection" \
    "2" "AEGIS Self-Protection" \
    '{"tool_name":"Edit","tool_input":{"file_path":".aegis/brain/design-library/stripe/DESIGN.md"}}'

# N+2: maintainer-mode override allows the edit
# We need a valid grant token: AEGIS_MAINTAINER_MODE="<path>|<nonce>|<expiry>"
# Use a future expiry (year 2099 epoch ≈ 4070908800)
GRANT_PATH=".aegis/brain/design-library/stripe/DESIGN.md"
GRANT_NONCE="test-nonce-$(date +%s)"
GRANT_EXPIRY="4070908800"
GRANT_TOKEN="${GRANT_PATH}|${GRANT_NONCE}|${GRANT_EXPIRY}"

# Clean up any leftover state files from previous runs
mkdir -p ".aegis/brain/state/maintainer-grants" 2>/dev/null || true

run_test "N+2" \
    "Allow design-library edit in maintainer-mode (ADR-004) -> exit 0" \
    "0" "" \
    '{"tool_name":"Edit","tool_input":{"file_path":".aegis/brain/design-library/stripe/DESIGN.md"}}' \
    "AEGIS_MAINTAINER_MODE=${GRANT_TOKEN}"

# Clean up the consumed grant state file
rm -f ".aegis/brain/state/maintainer-grants/${GRANT_NONCE}.used" 2>/dev/null || true

echo ""
echo "============================="
echo "Results: ${PASS} passed, ${FAIL} failed"
echo "============================="

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
exit 0
