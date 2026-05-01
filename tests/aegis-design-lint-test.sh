#!/usr/bin/env bash
# AEGIS Design Lint Tests (S3-02, spec §4.3)
# 12 test cases
#
# Usage: bash tools/aegis-design-lint-test.sh
# Exit: 0 if all pass, 1 if any fail

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LINT="${SCRIPT_DIR}/../tools/aegis-design-lint.sh"
INIT="${SCRIPT_DIR}/../tools/aegis-design-init.sh"
LIBRARY_DIR="${REPO_ROOT}/.aegis/brain/design-library"

pass=0
fail=0

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

ok() {
    local name="$1"
    echo "  PASS: TC-${name}"
    pass=$((pass + 1))
}

ko() {
    local name="$1"
    local reason="$2"
    echo "  FAIL: TC-${name} -- ${reason}"
    fail=$((fail + 1))
}

# Helper: write a full valid DESIGN.md
write_valid() {
    local path="$1"
    cat > "$path" << 'EOF'
# DESIGN.md

## 1. Theme
A warm editorial theme with terracotta accents.

## 2. Colors
Primary: #D97757, Background: #FAF9F7

## 3. Typography
Georgia serif headings, system sans body.

## 4. Components
Buttons with 6px radius, border-based cards.

## 5. Layout
Max-width 720px, 48px section gaps.

## 6. Depth
Minimal shadows, 1px borders for definition.

## 7. Do's and Don'ts
Do use generous whitespace. Don't use pure black.

## 8. Responsive
Mobile: 24px padding. Desktop: 48px padding.

## 9. Agent Prompt Guide
"Build warm editorial UI with terracotta accent."
EOF
}

echo "=== aegis-design-lint-test.sh ==="
echo ""

# -----------------------------------------------------------------
# TC-01: Happy path -- all 9 sections in order (library file)
# -----------------------------------------------------------------
echo "TC-01: Happy path -- all 9 sections from library"
lib_file="${LIBRARY_DIR}/stripe/DESIGN.md"
if [ -f "$lib_file" ]; then
    if "$LINT" --file "$lib_file" >/dev/null 2>&1; then
        ok "01"
    else
        ko "01" "stripe library file failed lint unexpectedly"
    fi
else
    # Fallback: use a valid file we create
    tmp01="${TMPDIR}/tc01.md"
    write_valid "$tmp01"
    if "$LINT" --file "$tmp01" >/dev/null 2>&1; then
        ok "01"
    else
        ko "01" "valid file failed lint"
    fi
fi

# -----------------------------------------------------------------
# TC-02: Missing Theme section
# -----------------------------------------------------------------
echo "TC-02: Missing Theme section"
tmp02="${TMPDIR}/tc02.md"
cat > "$tmp02" << 'EOF'
# DESIGN.md

## 2. Colors
Primary: #D97757

## 3. Typography
Georgia serif.

## 4. Components
Buttons with 6px radius.

## 5. Layout
Max-width 720px.

## 6. Depth
Minimal shadows.

## 7. Do's and Don'ts
Do use whitespace.

## 8. Responsive
Mobile: 24px padding.

## 9. Agent Prompt Guide
Warm editorial UI.
EOF
out02=$("$LINT" --file "$tmp02" 2>&1) || true
if ! "$LINT" --file "$tmp02" >/dev/null 2>&1; then
    if echo "$out02" | grep -qi "Theme\|Missing"; then
        ok "02"
    else
        ko "02" "exit 1 but output missing 'Theme'/'Missing'. Got: $out02"
    fi
else
    ko "02" "should have failed (missing Theme), but passed"
fi

# -----------------------------------------------------------------
# TC-03: Missing Colors section
# -----------------------------------------------------------------
echo "TC-03: Missing Colors section"
tmp03="${TMPDIR}/tc03.md"
cat > "$tmp03" << 'EOF'
# DESIGN.md

## 1. Theme
Warm editorial.

## 3. Typography
Georgia serif.

## 4. Components
Buttons.

## 5. Layout
Grid layout.

## 6. Depth
Shadows.

## 7. Do's and Don'ts
Guardrails.

## 8. Responsive
Mobile.

## 9. Agent Prompt Guide
Guide.
EOF
out03=$("$LINT" --file "$tmp03" 2>&1) || true
if ! "$LINT" --file "$tmp03" >/dev/null 2>&1; then
    if echo "$out03" | grep -qi "Color\|Missing"; then
        ok "03"
    else
        ko "03" "exit 1 but output missing 'Color'/'Missing'. Got: $out03"
    fi
else
    ko "03" "should have failed (missing Colors), but passed"
fi

# -----------------------------------------------------------------
# TC-04: Missing Typography section
# -----------------------------------------------------------------
echo "TC-04: Missing Typography section"
tmp04="${TMPDIR}/tc04.md"
cat > "$tmp04" << 'EOF'
# DESIGN.md

## 1. Theme
Warm.

## 2. Colors
Palette.

## 4. Components
Buttons.

## 5. Layout
Grid.

## 6. Depth
Shadows.

## 7. Do's and Don'ts
Guardrails.

## 8. Responsive
Mobile.

## 9. Agent Prompt Guide
Guide.
EOF
out04=$("$LINT" --file "$tmp04" 2>&1) || true
if ! "$LINT" --file "$tmp04" >/dev/null 2>&1; then
    if echo "$out04" | grep -qi "Typo\|Missing"; then
        ok "04"
    else
        ko "04" "exit 1 but missing 'Typo'/'Missing'. Got: $out04"
    fi
else
    ko "04" "should fail (missing Typography)"
fi

# -----------------------------------------------------------------
# TC-05: Missing Components section
# -----------------------------------------------------------------
echo "TC-05: Missing Components section"
tmp05="${TMPDIR}/tc05.md"
cat > "$tmp05" << 'EOF'
# DESIGN.md

## 1. Theme
Warm.

## 2. Colors
Palette.

## 3. Typography
Fonts.

## 5. Layout
Grid.

## 6. Depth
Shadows.

## 7. Do's and Don'ts
Guardrails.

## 8. Responsive
Mobile.

## 9. Agent Prompt Guide
Guide.
EOF
out05=$("$LINT" --file "$tmp05" 2>&1) || true
if ! "$LINT" --file "$tmp05" >/dev/null 2>&1; then
    if echo "$out05" | grep -qi "Compon\|Missing"; then
        ok "05"
    else
        ko "05" "exit 1 but missing 'Compon'/'Missing'. Got: $out05"
    fi
else
    ko "05" "should fail (missing Components)"
fi

# -----------------------------------------------------------------
# TC-06: Missing Responsive section
# -----------------------------------------------------------------
echo "TC-06: Missing Responsive section"
tmp06="${TMPDIR}/tc06.md"
cat > "$tmp06" << 'EOF'
# DESIGN.md

## 1. Theme
Warm.

## 2. Colors
Palette.

## 3. Typography
Fonts.

## 4. Components
Buttons.

## 5. Layout
Grid.

## 6. Depth
Shadows.

## 7. Do's and Don'ts
Guardrails.

## 9. Agent Prompt Guide
Guide.
EOF
out06=$("$LINT" --file "$tmp06" 2>&1) || true
if ! "$LINT" --file "$tmp06" >/dev/null 2>&1; then
    if echo "$out06" | grep -qi "Respon\|Missing"; then
        ok "06"
    else
        ko "06" "exit 1 but missing 'Respon'/'Missing'. Got: $out06"
    fi
else
    ko "06" "should fail (missing Responsive)"
fi

# -----------------------------------------------------------------
# TC-07: Missing Agent Prompt Guide
# -----------------------------------------------------------------
echo "TC-07: Missing Agent Prompt Guide"
tmp07="${TMPDIR}/tc07.md"
cat > "$tmp07" << 'EOF'
# DESIGN.md

## 1. Theme
Warm.

## 2. Colors
Palette.

## 3. Typography
Fonts.

## 4. Components
Buttons.

## 5. Layout
Grid.

## 6. Depth
Shadows.

## 7. Do's and Don'ts
Guardrails.

## 8. Responsive
Mobile.
EOF
out07=$("$LINT" --file "$tmp07" 2>&1) || true
if ! "$LINT" --file "$tmp07" >/dev/null 2>&1; then
    if echo "$out07" | grep -qi "Agent\|Missing"; then
        ok "07"
    else
        ko "07" "exit 1 but missing 'Agent'/'Missing'. Got: $out07"
    fi
else
    ko "07" "should fail (missing Agent Prompt Guide)"
fi

# -----------------------------------------------------------------
# TC-08: Out-of-order sections (Layout before Components)
# -----------------------------------------------------------------
echo "TC-08: Out-of-order sections (Layout before Components)"
tmp08="${TMPDIR}/tc08.md"
cat > "$tmp08" << 'EOF'
# DESIGN.md

## 1. Theme
Warm.

## 2. Colors
Palette.

## 3. Typography
Fonts.

## 5. Layout
Grid here first (wrong order).

## 4. Components
Buttons after layout (wrong).

## 6. Depth
Shadows.

## 7. Do's and Don'ts
Guardrails.

## 8. Responsive
Mobile.

## 9. Agent Prompt Guide
Guide.
EOF
out08=$("$LINT" --file "$tmp08" 2>&1) || true
if ! "$LINT" --file "$tmp08" >/dev/null 2>&1; then
    if echo "$out08" | grep -qi "appears before"; then
        ok "08"
    else
        ko "08" "exit 1 but missing 'appears before' out-of-order message. Got: $out08"
    fi
else
    ko "08" "should fail (out-of-order sections)"
fi

# -----------------------------------------------------------------
# TC-09: Empty file
# -----------------------------------------------------------------
echo "TC-09: Empty file"
tmp09="${TMPDIR}/tc09.md"
: > "$tmp09"  # create zero-byte file
out09=$("$LINT" --file "$tmp09" 2>&1) || true
if ! "$LINT" --file "$tmp09" >/dev/null 2>&1; then
    if echo "$out09" | grep -qi "empty\|not found"; then
        ok "09"
    else
        ko "09" "exit 1 but missing 'empty' in output. Got: $out09"
    fi
else
    ko "09" "should fail (empty file)"
fi

# -----------------------------------------------------------------
# TC-10: File not found
# -----------------------------------------------------------------
echo "TC-10: File not found"
out10=$("$LINT" --file "${TMPDIR}/does-not-exist.md" 2>&1) || true
if ! "$LINT" --file "${TMPDIR}/does-not-exist.md" >/dev/null 2>&1; then
    if echo "$out10" | grep -qi "not found\|FAIL"; then
        ok "10"
    else
        ko "10" "exit 1 but missing 'not found'. Got: $out10"
    fi
else
    ko "10" "should fail (file not found)"
fi

# -----------------------------------------------------------------
# TC-11: Blank template passes default lint
# -----------------------------------------------------------------
echo "TC-11: Blank template passes default lint"
tmp11="${TMPDIR}/tc11.md"
bash "$INIT" --blank --output "$tmp11" >/dev/null 2>&1
if "$LINT" --file "$tmp11" >/dev/null 2>&1; then
    ok "11"
else
    out11=$("$LINT" --file "$tmp11" 2>&1) || true
    ko "11" "blank template failed lint. Got: $out11"
fi

# -----------------------------------------------------------------
# TC-12: Case-insensitive header matching
# -----------------------------------------------------------------
echo "TC-12: Case-insensitive header matching"
tmp12="${TMPDIR}/tc12.md"
cat > "$tmp12" << 'EOF'
# DESIGN.md

## THEME
Dark and bold theme.

## colors
Primary: #000000

## TYPOGRAPHY
System sans-serif.

## COMPONENTS
Buttons and cards.

## layout
Grid system.

## DEPTH
Shadows and elevation.

## DO'S AND DON'TS
Visual guardrails here.

## responsive
Mobile-first design.

## AGENT PROMPT GUIDE
Use dark palette.
EOF
if "$LINT" --file "$tmp12" >/dev/null 2>&1; then
    ok "12"
else
    out12=$("$LINT" --file "$tmp12" 2>&1) || true
    ko "12" "case-insensitive headers should pass. Got: $out12"
fi

# -----------------------------------------------------------------
# Summary
# -----------------------------------------------------------------
echo ""
echo "=== Results: ${pass}/12 passed, ${fail}/12 failed ==="

if [ "$fail" -gt 0 ]; then
    exit 1
fi
exit 0
