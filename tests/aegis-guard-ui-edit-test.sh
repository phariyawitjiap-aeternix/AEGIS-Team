#!/usr/bin/env bash
# AEGIS Test — aegis-guard-ui-edit-test.sh (S3-04)
#
# Tests the guard-ui-edit.sh PreToolUse hook.
# 8 test cases per spec §6.3.
# Exit 0: all pass  |  Exit 1: one or more failures
#
# Usage:
#   bash tools/aegis-guard-ui-edit-test.sh
#   bash tools/aegis-guard-ui-edit-test.sh --verbose

set -uo pipefail

VERBOSE=0
[[ "${1:-}" == "--verbose" ]] && VERBOSE=1

PASS=0
FAIL=0

HOOK=".claude/hooks/guard-ui-edit.sh"
REPO_ROOT="$(pwd)"

# Verify hook exists
if [[ ! -f "${REPO_ROOT}/${HOOK}" ]]; then
    echo "ERROR: ${HOOK} not found at ${REPO_ROOT}/${HOOK}"
    exit 1
fi

# ── Temporary directory for test DESIGN.md ────────────────────────────────
TMPDIR_BASE=$(mktemp -d 2>/dev/null || mktemp -d -t 'aegis-ui-test')
trap 'rm -rf "$TMPDIR_BASE"' EXIT

# ── Test runner ───────────────────────────────────────────────────────────
run_test() {
    local num="$1"
    local desc="$2"
    local expected_exit="$3"
    local expected_contains="${4:-}"
    local tool_name="$5"
    local file_path="$6"
    local design_md_path="${7:-}"  # optional: path to DESIGN.md to use, or empty

    # Build JSON input
    local json_input
    json_input=$(python3 -c "
import json, sys
print(json.dumps({
    'tool_name': sys.argv[1],
    'tool_input': {'file_path': sys.argv[2]}
}))
" "$tool_name" "$file_path")

    # Run hook with controlled AEGIS_REPO_ROOT so it looks for DESIGN.md in the right place
    local actual_exit=0
    local actual_output
    actual_output=$(echo "$json_input" | AEGIS_REPO_ROOT="${design_md_path:-${TMPDIR_BASE}/no-design}" \
        bash "${REPO_ROOT}/${HOOK}" 2>/dev/null) || actual_exit=$?

    # Check exit code
    local ok=1
    if [[ "$actual_exit" != "$expected_exit" ]]; then
        ok=0
    fi

    # Check output contains expected string (if provided)
    if [[ -n "$expected_contains" && "$actual_output" != *"$expected_contains"* ]]; then
        ok=0
    fi

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

# ── Create a test repo root WITH a DESIGN.md ─────────────────────────────
DESIGN_ROOT="${TMPDIR_BASE}/with-design"
mkdir -p "$DESIGN_ROOT"
cat > "${DESIGN_ROOT}/DESIGN.md" << 'EOF'
# DESIGN.md — Test

## 1. Theme
Dark terminal aesthetic.

## 2. Colors
Primary: emerald.

## 3. Typography
JetBrains Mono.

## 4. Components
Buttons use tokens.

## 5. Layout
8px grid.

## 6. Depth
Shadows: standard.

## 7. Do's and Don'ts
Do: use tokens. Don't: hardcode.

## 8. Responsive
Mobile first.

## 9. Agent Prompt Guide
Reference DESIGN.md always.
EOF

# ── No-design root (DESIGN.md absent) ─────────────────────────────────────
NO_DESIGN_ROOT="${TMPDIR_BASE}/no-design"
mkdir -p "$NO_DESIGN_ROOT"

echo "guard-ui-edit.sh — 13 Test Cases (8 core + 4 exclusion + 1 path-traversal S3-09)"
echo "=================================="

# TC-1: Block .tsx edit without DESIGN.md
run_test 1 \
    "Edit src/components/Button.tsx without DESIGN.md -> block (exit 2)" \
    "2" "DESIGN.md required" \
    "Edit" "src/components/Button.tsx" \
    "$NO_DESIGN_ROOT"

# TC-2: Block .css write without DESIGN.md
run_test 2 \
    "Write styles/main.css without DESIGN.md -> block (exit 2)" \
    "2" "DESIGN.md required" \
    "Write" "styles/main.css" \
    "$NO_DESIGN_ROOT"

# TC-3: Block .vue edit without DESIGN.md
run_test 3 \
    "Edit views/Home.vue without DESIGN.md -> block (exit 2)" \
    "2" "DESIGN.md required" \
    "Edit" "views/Home.vue" \
    "$NO_DESIGN_ROOT"

# TC-4: Allow .tsx edit WITH DESIGN.md
run_test 4 \
    "Edit src/components/Button.tsx WITH DESIGN.md -> allow (exit 0)" \
    "0" "" \
    "Edit" "src/components/Button.tsx" \
    "$DESIGN_ROOT"

# TC-5: Allow .ts edit (non-UI file)
run_test 5 \
    "Edit src/utils/math.ts (non-UI) without DESIGN.md -> allow (exit 0)" \
    "0" "" \
    "Edit" "src/utils/math.ts" \
    "$NO_DESIGN_ROOT"

# TC-6: Allow .json edit (non-UI file)
run_test 6 \
    "Edit config/settings.json (non-UI) without DESIGN.md -> allow (exit 0)" \
    "0" "" \
    "Edit" "config/settings.json" \
    "$NO_DESIGN_ROOT"

# TC-7: Block .svelte edit without DESIGN.md
run_test 7 \
    "Edit routes/+page.svelte without DESIGN.md -> block (exit 2)" \
    "2" "DESIGN.md required" \
    "Edit" "routes/+page.svelte" \
    "$NO_DESIGN_ROOT"

# TC-8: Allow Bash tool (non-write tool — not in Edit|Write|MultiEdit)
run_test 8 \
    "Bash tool (ls) -> allow (exit 0, hook not applicable)" \
    "0" "" \
    "Bash" "ls" \
    "$NO_DESIGN_ROOT"

# ── Bonus exclusion tests ─────────────────────────────────────────────────
# TC-E1: *.test.tsx excluded -> allow even without DESIGN.md
run_test "E1" \
    "Edit Button.test.tsx (excluded) without DESIGN.md -> allow (exit 0)" \
    "0" "" \
    "Edit" "src/components/Button.test.tsx" \
    "$NO_DESIGN_ROOT"

# TC-E2: *.stories.tsx excluded -> allow
run_test "E2" \
    "Edit Button.stories.tsx (excluded) without DESIGN.md -> allow (exit 0)" \
    "0" "" \
    "Edit" "src/components/Button.stories.tsx" \
    "$NO_DESIGN_ROOT"

# TC-E3: __tests__/ directory excluded -> allow
run_test "E3" \
    "Edit __tests__/Button.tsx (excluded) without DESIGN.md -> allow (exit 0)" \
    "0" "" \
    "Edit" "__tests__/Button.tsx" \
    "$NO_DESIGN_ROOT"

# TC-E4: *.config.ts excluded -> allow (jest.config.ts would otherwise match .ts)
run_test "E4" \
    "Edit jest.config.ts (excluded) without DESIGN.md -> allow (exit 0)" \
    "0" "" \
    "Edit" "jest.config.ts" \
    "$NO_DESIGN_ROOT"

# ── Path traversal test (S3-09) ───────────────────────────────────────────
# TC-PT1: Path traversal via ../../../ should be canonicalized and allowed
# because the resolved path is outside the repo root.
# When AEGIS_REPO_ROOT is set to NO_DESIGN_ROOT, the path
# src/components/../../../etc/passwd.tsx resolves to /etc/passwd.tsx which
# is outside NO_DESIGN_ROOT — so the hook exits 0 (outside-repo allow).
run_test "PT1" \
    "Path traversal src/components/../../../etc/passwd.tsx -> allow (resolved outside repo, exit 0)" \
    "0" "" \
    "Edit" "src/components/../../../etc/passwd.tsx" \
    "$NO_DESIGN_ROOT"

echo ""
echo "=================================="
echo "Results: ${PASS} passed, ${FAIL} failed"
echo "=================================="

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
exit 0
