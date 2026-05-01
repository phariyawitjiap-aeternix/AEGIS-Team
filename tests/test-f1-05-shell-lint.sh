#!/usr/bin/env bash
# test-f1-05-shell-lint.sh — Tests for F1-05 shell-command pre-flight linter
# Bash 3.2 compatible.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/aegis-test-harness-template.sh"

LINTER="${SCRIPT_DIR}/../tools/aegis-shell-lint.sh"

echo "=== F1-05: Shell-command pre-flight linter ==="
echo ""

# TC-01: Spec references known-good commands (realpath, jq, git) → exit 0, no UNKNOWN
TC01_SPEC="${TEST_TMPDIR}/tc01-spec.md"
cat > "$TC01_SPEC" <<'EOF'
# Test spec

Use `realpath` to resolve paths.
Run `jq` to parse JSON.
Clone with `git clone`.

```bash
realpath -m /some/path
jq '.key' file.json
git status
```
EOF

TC01_EXIT=0
TC01_OUT=$(bash "$LINTER" --file "$TC01_SPEC" 2>&1) || TC01_EXIT=$?
assert_eq "$TC01_EXIT" "0" "TC-01 known commands exit 0"
if echo "$TC01_OUT" | grep -q "UNKNOWN"; then
    FAIL "TC-01 unexpected UNKNOWN in output: $TC01_OUT"
else
    PASS "TC-01 no UNKNOWN warnings for known commands"
fi

# TC-02: Spec references greadpath (typo) → exit 1, output contains greadpath
TC02_SPEC="${TEST_TMPDIR}/tc02-spec.md"
cat > "$TC02_SPEC" <<'EOF'
# Test spec with typo

Use `greadpath -m /some/path` to resolve symlinks.
EOF

TC02_EXIT=0
TC02_OUT=$(bash "$LINTER" --file "$TC02_SPEC" 2>&1) || TC02_EXIT=$?
assert_eq "$TC02_EXIT" "1" "TC-02 typo command exits 1"
if echo "$TC02_OUT" | grep -q "greadpath"; then
    PASS "TC-02 output identifies greadpath as unknown"
else
    FAIL "TC-02 greadpath not flagged in output: $TC02_OUT"
fi

# TC-03: Spec references customtool with fallback nearby → exit 0 (fallback detected)
TC03_SPEC="${TEST_TMPDIR}/tc03-spec.md"
cat > "$TC03_SPEC" <<'EOF'
# Test spec with fallback

Run `customtool --process` if available, with fallback to python3 if unavailable.
EOF

TC03_EXIT=0
TC03_OUT=$(bash "$LINTER" --file "$TC03_SPEC" 2>&1) || TC03_EXIT=$?
assert_eq "$TC03_EXIT" "0" "TC-03 command with fallback detected exits 0"

# TC-04: Empty file → exit 0, no false positives
TC04_SPEC="${TEST_TMPDIR}/tc04-spec.md"
touch "$TC04_SPEC"

TC04_EXIT=0
TC04_OUT=$(bash "$LINTER" --file "$TC04_SPEC" 2>&1) || TC04_EXIT=$?
assert_eq "$TC04_EXIT" "0" "TC-04 empty file exits 0"
if echo "$TC04_OUT" | grep -q "UNKNOWN"; then
    FAIL "TC-04 false positive UNKNOWN on empty file: $TC04_OUT"
else
    PASS "TC-04 no false positives on empty file"
fi

test_results
