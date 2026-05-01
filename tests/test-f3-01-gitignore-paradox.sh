#!/usr/bin/env bash
# test-f3-01-gitignore-paradox.sh — Tests for F3-01 gitignore paradox fix
# Bash 3.2 compatible.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/aegis-test-harness-template.sh"

REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "=== F3-01: gitignore paradox fix ==="
echo ""

# TC-01: _aegis-output/.gitignore is NOT ignored (git check-ignore returns empty / exit 1)
TC01_OUT=$(cd "$REPO_ROOT" && git check-ignore "_aegis-output/.gitignore" 2>/dev/null || true)
if [[ -z "$TC01_OUT" ]]; then
    PASS "TC-01 _aegis-output/.gitignore is not ignored (git check-ignore returns empty)"
else
    FAIL "TC-01 _aegis-output/.gitignore is still ignored: '$TC01_OUT'"
fi

# TC-02: _aegis-output/random-file.txt IS ignored
TC02_OUT=$(cd "$REPO_ROOT" && git check-ignore "_aegis-output/random-file.txt" 2>/dev/null || true)
if [[ -n "$TC02_OUT" ]]; then
    PASS "TC-02 _aegis-output/random-file.txt is ignored (expected)"
else
    FAIL "TC-02 _aegis-output/random-file.txt should be ignored but is not"
fi

# TC-03: _aegis-output/specs/some-spec.md is NOT ignored
TC03_OUT=$(cd "$REPO_ROOT" && git check-ignore "_aegis-output/specs/some-spec.md" 2>/dev/null || true)
if [[ -z "$TC03_OUT" ]]; then
    PASS "TC-03 _aegis-output/specs/some-spec.md is not ignored (tracked path)"
else
    FAIL "TC-03 _aegis-output/specs/some-spec.md is ignored but should not be: '$TC03_OUT'"
fi

test_results
