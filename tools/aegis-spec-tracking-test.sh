#!/usr/bin/env bash
# AEGIS Test — aegis-spec-tracking-test.sh (S2-06)
#
# Tests that _aegis-output/specs/ is tracked by git while other
# _aegis-output/ subdirectories remain ignored.
# 4 test cases per spec §4.4.
# Exit 0: all pass  |  Exit 1: one or more failures
#
# Usage:
#   bash tools/aegis-spec-tracking-test.sh
#   bash tools/aegis-spec-tracking-test.sh --verbose

set -uo pipefail

VERBOSE=0
[[ "${1:-}" == "--verbose" ]] && VERBOSE=1

PASS=0
FAIL=0

REPO_ROOT="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel 2>/dev/null || pwd)"

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

# ── Temp files for real-path git check-ignore tests ──────────────────────
# git check-ignore requires actual files to exist on disk
TMPDIR_BASE=$(mktemp -d 2>/dev/null || mktemp -d -t 'aegis-spec-track-test')
trap 'rm -rf "$TMPDIR_BASE"' EXIT

echo "aegis-spec-tracking-test.sh — 4 Test Cases"
echo "============================================="

# TC-1: _aegis-output/specs/test.md is NOT gitignored (exit != 0)
tc1_result="fail"
SPEC_FILE="${REPO_ROOT}/_aegis-output/specs/tc1-test-tracking.md"
echo "# TC-1 test spec" > "$SPEC_FILE"
trap 'rm -f "$SPEC_FILE"' EXIT
if ! git -C "$REPO_ROOT" check-ignore -q "_aegis-output/specs/tc1-test-tracking.md" 2>/dev/null; then
    tc1_result="pass"
fi
rm -f "$SPEC_FILE"
run_test 1 "_aegis-output/specs/test.md is NOT gitignored (specs tracked)" "$tc1_result"

# TC-2: _aegis-output/deployments/foo.txt IS gitignored (exit 0)
tc2_result="fail"
mkdir -p "${REPO_ROOT}/_aegis-output/deployments"
DEPLOY_FILE="${REPO_ROOT}/_aegis-output/deployments/tc2-test.txt"
echo "deploy artifact" > "$DEPLOY_FILE"
if git -C "$REPO_ROOT" check-ignore -q "_aegis-output/deployments/tc2-test.txt" 2>/dev/null; then
    tc2_result="pass"
fi
rm -f "$DEPLOY_FILE"
run_test 2 "_aegis-output/deployments/foo.txt IS gitignored (deployments not tracked)" "$tc2_result"

# TC-3: _aegis-output/research/bar.md IS gitignored (exit 0)
tc3_result="fail"
mkdir -p "${REPO_ROOT}/_aegis-output/research"
RESEARCH_FILE="${REPO_ROOT}/_aegis-output/research/tc3-test.md"
echo "research artifact" > "$RESEARCH_FILE"
if git -C "$REPO_ROOT" check-ignore -q "_aegis-output/research/tc3-test.md" 2>/dev/null; then
    tc3_result="pass"
fi
rm -f "$RESEARCH_FILE"
run_test 3 "_aegis-output/research/bar.md IS gitignored (research not tracked)" "$tc3_result"

# TC-4: Nested spec _aegis-output/specs/nested/deep.md is NOT gitignored
tc4_result="fail"
mkdir -p "${REPO_ROOT}/_aegis-output/specs/nested"
NESTED_FILE="${REPO_ROOT}/_aegis-output/specs/nested/deep.md"
echo "# deep nested spec" > "$NESTED_FILE"
if ! git -C "$REPO_ROOT" check-ignore -q "_aegis-output/specs/nested/deep.md" 2>/dev/null; then
    tc4_result="pass"
fi
rm -f "$NESTED_FILE"
rmdir "${REPO_ROOT}/_aegis-output/specs/nested" 2>/dev/null || true
run_test 4 "_aegis-output/specs/nested/deep.md is NOT gitignored (deep specs tracked)" "$tc4_result"

echo ""
echo "============================================="
echo "Results: ${PASS} passed, ${FAIL} failed"
echo "============================================="

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
exit 0
