#!/usr/bin/env bash
# aegis-test-harness-template.sh — Source this, do not execute directly.
# Usage: source tools/aegis-test-harness-template.sh
#
# Exports:
#   $TEST_TMPDIR   -- mktemp -d result, auto-cleaned on exit
#   PASS "label"   -- increment pass counter, print green
#   FAIL "label"   -- increment fail counter, print red, continue
#   FAIL_FAST "l"  -- increment fail counter, print red, exit immediately
#   assert_eq   actual expected "label"
#   assert_neq  actual expected "label"
#   assert_exit expected_code "label" command [args...]
#   assert_file_exists  path "label"
#   assert_file_absent  path "label"
#   assert_file_contains  path pattern "label"
#   assert_file_not_contains  path pattern "label"
#   assert_stdout_contains  pattern "label" command [args...]
#   assert_stderr_contains  pattern "label" command [args...]
#   test_results  -- print summary, exit 0 if all pass, exit 1 if any fail
#
# Bash 3.2 compatible.

_AEGIS_TEST_PASS=0
_AEGIS_TEST_FAIL=0
TEST_TMPDIR=$(mktemp -d "${TMPDIR:-/tmp}/aegis-test-XXXXXX")

_cleanup() {
    rm -rf "$TEST_TMPDIR" 2>/dev/null || true
}
trap '_cleanup' EXIT INT TERM

PASS() {
    _AEGIS_TEST_PASS=$(( _AEGIS_TEST_PASS + 1 ))
    printf "  PASS: %s\n" "$1"
}

FAIL() {
    _AEGIS_TEST_FAIL=$(( _AEGIS_TEST_FAIL + 1 ))
    printf "  FAIL: %s\n" "$1" >&2
}

FAIL_FAST() {
    FAIL "$1"
    test_results
    exit 1
}

assert_eq() {
    if [[ "$1" == "$2" ]]; then PASS "$3"; else FAIL "$3 | expected='$2' got='$1'"; fi
}

assert_neq() {
    if [[ "$1" != "$2" ]]; then PASS "$3"; else FAIL "$3 | expected not '$2' but got it"; fi
}

assert_exit() {
    local expected="$1" label="$2"; shift 2
    local actual=0
    "$@" >/dev/null 2>&1 || actual=$?
    assert_eq "$actual" "$expected" "$label"
}

assert_file_exists() {
    if [[ -f "$1" ]]; then PASS "$2"; else FAIL "$2 | file missing: $1"; fi
}

assert_file_absent() {
    if [[ ! -f "$1" ]]; then PASS "$2"; else FAIL "$2 | file should not exist: $1"; fi
}

assert_file_contains() {
    if grep -qF "$2" "$1" 2>/dev/null; then PASS "$3"; else FAIL "$3 | pattern '$2' not found in $1"; fi
}

assert_file_not_contains() {
    if grep -qF "$2" "$1" 2>/dev/null; then FAIL "$3 | unexpected pattern '$2' found in $1"; else PASS "$3"; fi
}

assert_stdout_contains() {
    local pattern="$1" label="$2"; shift 2
    local out
    out=$("$@" 2>/dev/null) || true
    if echo "$out" | grep -qF "$pattern"; then PASS "$label"; else FAIL "$label | stdout missing '$pattern'"; fi
}

assert_stderr_contains() {
    local pattern="$1" label="$2"; shift 2
    local err
    err=$("$@" 2>&1 1>/dev/null) || true
    if echo "$err" | grep -qF "$pattern"; then PASS "$label"; else FAIL "$label | stderr missing '$pattern'"; fi
}

test_results() {
    echo ""
    echo "======================================="
    echo "  Results: ${_AEGIS_TEST_PASS} passed, ${_AEGIS_TEST_FAIL} failed"
    echo "======================================="
    if [[ $_AEGIS_TEST_FAIL -gt 0 ]]; then
        return 1
    fi
    return 0
}
