#!/usr/bin/env bash
# AEGIS Test — aegis-block0-f-gate-test.sh (S3-03)
#
# Tests the BLOCK 0F gate logic: UI task + DESIGN.md detection.
# Simulates the path-based filtering procedure defined in nick-fury.md BLOCK 0F.
#
# 8 test cases per spec §5.3/§5.4.
# Exit 0: all pass  |  Exit 1: one or more failures
#
# Usage:
#   bash tools/aegis-block0-f-gate-test.sh
#   bash tools/aegis-block0-f-gate-test.sh --verbose

set -uo pipefail

VERBOSE=0
[[ "${1:-}" == "--verbose" ]] && VERBOSE=1

PASS=0
FAIL=0
SKIP=0

# ── BLOCK 0F gate logic (inline implementation matching nick-fury.md spec) ─
# Returns: "PASS", "FAIL", or "NOT_APPLICABLE"
# Arguments: priority files... (where priority is P1-P10 int, e.g. "3")
# DESIGN_MD_PATH must be set by caller (path to test DESIGN.md or empty string)
block0f_check() {
    local priority="$1"
    shift
    local files=("$@")

    # EXCLUDE patterns (checked FIRST)
    is_excluded() {
        local p="$1"
        [[ "$p" =~ \.(test|spec|stories)\.(tsx|jsx|css|scss|js|ts)$ ]] && return 0
        [[ "$p" =~ \.config\.(tsx|jsx|js|ts|mjs|cjs)$ ]] && return 0
        [[ "$p" =~ (^|/)'__tests__'/ ]] && return 0
        [[ "$p" =~ (^|/)'__mocks__'/ ]] && return 0
        [[ "$p" =~ (^|/)setupTests\. ]] && return 0
        return 1
    }

    # INCLUDE UI patterns (checked after EXCLUDE passes)
    is_ui_file() {
        local p="$1"
        [[ "$p" =~ \.(tsx|jsx|css|scss|vue|svelte)$ ]] && return 0
        [[ "$p" =~ (^|/)src/components/ ]] && return 0
        [[ "$p" =~ (^|/)src/pages/ ]] && return 0
        [[ "$p" =~ (^|/)src/styles/ ]] && return 0
        [[ "$p" =~ (^|/)src/ui/ ]] && return 0
        [[ "$p" =~ (^|/)app/components/ ]] && return 0
        return 1
    }

    # Filter files: exclude first, then check UI patterns
    local ui_count=0
    for f in "${files[@]}"; do
        if is_excluded "$f"; then
            continue
        fi
        if is_ui_file "$f"; then
            ui_count=$((ui_count + 1))
        fi
    done

    # If no UI files remain, NOT_APPLICABLE
    if [[ "$ui_count" -eq 0 ]]; then
        echo "NOT_APPLICABLE"
        return
    fi

    # Priority check: below P3 (numeric > 3) = NOT_APPLICABLE
    # P3 = priority level 3; P4, P5... are lower priority
    if [[ "$priority" -gt 3 ]]; then
        echo "NOT_APPLICABLE"
        return
    fi

    # Check for DESIGN.md
    if [[ -z "${DESIGN_MD_PATH:-}" || ! -f "${DESIGN_MD_PATH}" ]]; then
        echo "FAIL"
        return
    fi

    # Run lint in strict mode
    local lint_out
    lint_out=$(bash "$(dirname "$0")/aegis-design-lint.sh" --strict --file "${DESIGN_MD_PATH}" 2>&1) || {
        echo "FAIL"
        return
    }
    echo "PASS"
}

# ── Test runner ───────────────────────────────────────────────────────────
run_test() {
    local num="$1"
    local desc="$2"
    local expected="$3"
    local actual="$4"

    if [[ "$actual" == "$expected" ]]; then
        PASS=$((PASS + 1))
        [[ $VERBOSE -eq 1 ]] && echo "  PASS [TC-${num}]: ${desc} (got: ${actual})"
    else
        FAIL=$((FAIL + 1))
        echo "  FAIL [TC-${num}]: ${desc}"
        echo "         expected: ${expected}"
        echo "         got:      ${actual}"
    fi
}

# ── Temporary directory for test artifacts ────────────────────────────────
TMPDIR_BASE=$(mktemp -d 2>/dev/null || mktemp -d -t 'aegis-b0f-test')
trap 'rm -rf "$TMPDIR_BASE"' EXIT

# Valid DESIGN.md (9 sections with real content)
VALID_DESIGN="${TMPDIR_BASE}/valid_design.md"
cat > "$VALID_DESIGN" << 'EOF'
# DESIGN.md

## 1. Theme
Dark terminal aesthetic with emerald accent.

## 2. Colors
Primary: #10b981 (emerald-500). Background: #0a0a0a.

## 3. Typography
Font: JetBrains Mono. Base size: 14px. Weight: 400.

## 4. Components
Buttons use --primary token. Cards have 1px border.

## 5. Layout
8px grid. Max content width: 1200px.

## 6. Depth
Shadows: 0 2px 8px rgba(0,0,0,0.4). Z-index scale: 10/20/30.

## 7. Do's and Don'ts
Do: use design tokens. Don't: hardcode colors.

## 8. Responsive
Mobile first. Breakpoints: 640px / 1024px / 1280px.

## 9. Agent Prompt Guide
When building components, always reference DESIGN.md tokens.
EOF

# Malformed DESIGN.md (missing sections)
BAD_DESIGN="${TMPDIR_BASE}/bad_design.md"
cat > "$BAD_DESIGN" << 'EOF'
# DESIGN.md

## 1. Theme
Some theme info.

## 2. Colors
Some colors.
EOF

echo "BLOCK 0F Gate — 8 Test Cases"
echo "=============================="

# TC-1: UI task without DESIGN.md -> FAIL
unset DESIGN_MD_PATH
result=$(block0f_check 1 "src/components/Button.tsx")
run_test 1 "UI task (Button.tsx) without DESIGN.md -> FAIL" "FAIL" "$result"

# TC-2: UI task with valid DESIGN.md -> PASS
export DESIGN_MD_PATH="$VALID_DESIGN"
result=$(block0f_check 1 "src/components/Card.tsx")
run_test 2 "UI task (Card.tsx) with valid DESIGN.md -> PASS" "PASS" "$result"

# TC-3: UI task with malformed DESIGN.md -> FAIL
export DESIGN_MD_PATH="$BAD_DESIGN"
result=$(block0f_check 1 "src/components/Nav.tsx")
run_test 3 "UI task with malformed DESIGN.md -> FAIL" "FAIL" "$result"

# TC-4: Non-UI task (pure logic) -> NOT_APPLICABLE
unset DESIGN_MD_PATH
result=$(block0f_check 1 "src/utils/math.ts")
run_test 4 "Non-UI task (math.ts) -> NOT_APPLICABLE" "NOT_APPLICABLE" "$result"

# TC-5: Mixed files (UI + non-UI) -> FAIL (any UI file activates gate)
unset DESIGN_MD_PATH
result=$(block0f_check 1 "src/utils/math.ts" "src/components/Card.tsx")
run_test 5 "Mixed files (math.ts + Card.tsx) without DESIGN.md -> FAIL" "FAIL" "$result"

# TC-6: Low-priority UI task (P4 = priority 4 > 3 threshold) -> NOT_APPLICABLE
unset DESIGN_MD_PATH
result=$(block0f_check 4 "src/components/Button.tsx")
run_test 6 "P4 UI task (below P3 threshold) -> NOT_APPLICABLE" "NOT_APPLICABLE" "$result"

# TC-7: P3 UI task with valid DESIGN.md -> PASS
export DESIGN_MD_PATH="$VALID_DESIGN"
result=$(block0f_check 3 "src/components/Button.tsx")
run_test 7 "P3 UI task with valid DESIGN.md -> PASS" "PASS" "$result"

# TC-8: CSS-only change -> FAIL (no DESIGN.md)
unset DESIGN_MD_PATH
result=$(block0f_check 1 "styles/theme.css")
run_test 8 "CSS-only change (styles/theme.css) without DESIGN.md -> FAIL" "FAIL" "$result"

# ── Bonus: EXCLUDE pattern tests (ensure test files are never gated) ───────
# TC-E1: *.test.tsx -> NOT_APPLICABLE (excluded before INCLUDE check)
unset DESIGN_MD_PATH
result=$(block0f_check 1 "src/components/Button.test.tsx")
run_test "E1" "Excluded *.test.tsx -> NOT_APPLICABLE" "NOT_APPLICABLE" "$result"

# TC-E2: __tests__/ directory -> NOT_APPLICABLE
unset DESIGN_MD_PATH
result=$(block0f_check 1 "__tests__/Button.tsx")
run_test "E2" "Excluded __tests__/Button.tsx -> NOT_APPLICABLE" "NOT_APPLICABLE" "$result"

# TC-E3: *.stories.tsx -> NOT_APPLICABLE
unset DESIGN_MD_PATH
result=$(block0f_check 1 "src/components/Button.stories.tsx")
run_test "E3" "Excluded *.stories.tsx -> NOT_APPLICABLE" "NOT_APPLICABLE" "$result"

echo ""
echo "=============================="
echo "Results: ${PASS} passed, ${FAIL} failed, ${SKIP} skipped"
echo "=============================="

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
exit 0
