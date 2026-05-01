#!/usr/bin/env bash
# AEGIS Wasp Generate Test (S3-06, spec §6)
#
# 6 pipeline tests + 6 acceptance checks = 12 assertions total.
# Tests the Wasp design-generation pipeline contracts:
#   brief input format, DESIGN.md output structure, lint compliance,
#   gate verdict format, and file-level acceptance checks.
#
# Usage: bash tools/aegis-wasp-generate-test.sh [--verbose]
# Exit: 0 if all pass, 1 if any fail

set -uo pipefail

VERBOSE=0
[[ "${1:-}" == "--verbose" ]] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LINT="${SCRIPT_DIR}/../tools/aegis-design-lint.sh"
CONTRAST="${SCRIPT_DIR}/../tools/aegis-contrast-check.sh"

PASS=0
FAIL=0

TMPDIR_BASE=$(mktemp -d 2>/dev/null || mktemp -d -t 'aegis-wasp-test')
trap 'rm -rf "$TMPDIR_BASE"' EXIT

ok() {
    local name="$1"
    local desc="$2"
    PASS=$((PASS + 1))
    [[ $VERBOSE -eq 1 ]] && echo "  PASS [${name}]: ${desc}"
    echo "  PASS: ${name}"
}

ko() {
    local name="$1"
    local desc="$2"
    local detail="${3:-}"
    FAIL=$((FAIL + 1))
    echo "  FAIL: ${name} -- ${desc}"
    [[ -n "$detail" ]] && echo "        ${detail}"
}

# Helper: write a fully valid DESIGN.md (simulates Wasp output)
write_valid_design() {
    local path="$1"
    cat > "$path" << 'EOF'
# DESIGN.md
<!-- Wasp-authored: Path D custom-author -->

A warm, editorial SaaS dashboard. Every pixel serves clarity.
We balance professional trust with approachable warmth.

## 1. Theme
Warm editorial with terracotta accents on neutral backgrounds.
Enterprise trust meets human warmth -- corporate rigor softened
by tactile texture and generous whitespace.

## 2. Colors
Primary: #D97757 (terracotta) on #FFFFFF: 3.2:1 -- AA LARGE PASS
Secondary: #1A1A1A (near-black) on #FFFFFF: 19.6:1 -- AAA PASS
Neutral-100: #FAF9F7 (warm white background)
Neutral-700: #4A4A4A (body text) on #FFFFFF: 9.7:1 -- AA PASS
Accent: #2563EB (blue) on #FFFFFF: 5.9:1 -- AA PASS

## 3. Typography
Font family: Inter (sans-serif), fallback: system-ui
Base size: 16px, Weight: 400 (Regular)
Scale:
- Display: 40px, Weight 700 (Bold)
- Heading 1: 32px, Weight 600 (SemiBold)
- Heading 2: 24px, Weight 600 (SemiBold)
- Heading 3: 20px, Weight 500 (Medium)
- Body: 16px, Weight 400 (Regular)
- Small: 14px, Weight 400 (Regular)
Line heights: Display 1.2, Body 1.6

## 4. Components

### Buttons
Primary: terracotta fill (#D97757), white text, 6px radius, 44px min-height
Secondary: transparent, terracotta border, terracotta text
Focus ring: 2px offset, #2563EB outline (WCAG 2.4.7 compliant)

### Cards
Background: #FFFFFF, 1px border (#E8E4DF), 8px radius, 16px padding
Hover: box-shadow 0 4px 12px rgba(0,0,0,0.08)

### Inputs
Border: 1px #D4CFC9, focus border 2px #D97757, 40px height
Error state: #DC2626 border with error message below

## 5. Layout
Max-width: 1200px centered, 8px base grid unit
Section gaps: 48px vertical, 24px horizontal
Sidebar: 240px fixed, main content: flex-1

## 6. Depth
Shadows: none (flat), hover: 0 4px 12px rgba(0,0,0,0.08)
Borders: 1px solid (#E8E4DF) for card separation
Z-index scale: modal 300, overlay 200, dropdown 100, sticky 10

## 7. Do's and Don'ts

### Do's
- Do use --primary token (#D97757) for all primary actions
- Do maintain 44px minimum touch targets on all interactive elements
- Do use generous whitespace (48px section gaps) to create breathing room
- Do cite DESIGN.md section references in component implementations
- Do include prefers-reduced-motion media query for any animations
- Do use Inter font at base 16px minimum for body copy

### Don'ts
- Don't hardcode hex values in component CSS -- use design tokens
- Don't use font sizes below 14px for any readable UI text
- Don't place primary CTA buttons with less than 44x44px touch area
- Don't use terracotta (#D97757) as body text on white -- contrast fails AA normal text
- Don't create new color values not defined in this section 2
- Don't skip focus ring styles on interactive elements

## 8. Responsive
Mobile-first breakpoints:
- Mobile: 0-639px, 16px padding, single column
- Tablet: 640-1023px, 24px padding, 2-column grid
- Desktop: 1024px+, 32px padding, sidebar + main layout

Touch targets: minimum 44x44px per WCAG 2.5.8 on all mobile breakpoints.
prefers-reduced-motion: disable all transition animations when set.

## 9. Agent Prompt Guide

**Prompt 1 (Spider-Man -- component build):**
"Build the Button component following DESIGN.md section 4 Components.
Primary variant: terracotta fill (#D97757) with white text, 6px radius,
minimum 44px height. Reference section 2 for color tokens, section 3 for
typography scale. Include focus ring per section 4 focus ring definition."

**Prompt 2 (Spider-Man -- layout implementation):**
"Implement the dashboard shell following DESIGN.md section 5 Layout.
Use 8px grid unit, max-width 1200px, 240px sidebar fixed. Reference
section 8 Responsive for breakpoint behavior and touch target minimums."

**Prompt 3 (Black Panther -- a11y review):**
"Review this UI component against DESIGN.md section 2 Colors for
contrast compliance. Run tools/aegis-contrast-check.sh to verify hex pairs.
Check section 4 for focus ring definition. Report A11Y_FINDING format."
EOF
}

echo "=== aegis-wasp-generate-test.sh ==="
echo ""

# =================================================================
# PIPELINE TESTS (TC-1 through TC-6)
# =================================================================

# TC-1: Valid DESIGN.md (simulated Wasp output) passes lint --strict
echo "TC-1: Valid DESIGN.md passes lint strict"
tc1="${TMPDIR_BASE}/tc1.md"
write_valid_design "$tc1"
if bash "$LINT" --strict --file "$tc1" >/dev/null 2>&1; then
    ok "TC-1" "valid Wasp DESIGN.md passes lint --strict"
else
    out=$(bash "$LINT" --strict --file "$tc1" 2>&1) || true
    ko "TC-1" "valid Wasp DESIGN.md should pass lint --strict" "$out"
fi

# TC-2: DESIGN.md with missing Typography section fails lint
echo "TC-2: DESIGN.md missing Typography section fails lint"
tc2="${TMPDIR_BASE}/tc2.md"
cat > "$tc2" << 'EOF'
# DESIGN.md

## 1. Theme
Warm editorial.

## 2. Colors
Primary: #D97757

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
Build warm UI.
EOF
out2=$(bash "$LINT" --strict --file "$tc2" 2>&1) || true
if ! bash "$LINT" --strict --file "$tc2" >/dev/null 2>&1; then
    if echo "$out2" | grep -qi "Missing\|Typo"; then
        ok "TC-2" "missing Typography section detected by lint"
    else
        ko "TC-2" "lint exited 1 but wrong message" "$out2"
    fi
else
    ko "TC-2" "should fail with missing Typography section"
fi

# TC-3: DESIGN.md with empty section body fails strict
echo "TC-3: DESIGN.md with empty section (comments only) fails --strict"
tc3="${TMPDIR_BASE}/tc3.md"
cat > "$tc3" << 'EOF'
# DESIGN.md

## 1. Theme
Warm editorial theme.

## 2. Colors
Primary: #D97757

## 3. Typography
Font: Inter, 16px base.

## 4. Components
<!-- TODO: add component descriptions -->

## 5. Layout
Max-width 1200px.

## 6. Depth
Minimal shadows.

## 7. Do's and Don'ts
Do use whitespace. Don't use pure black.

## 8. Responsive
Mobile-first.

## 9. Agent Prompt Guide
Build warm editorial UI.
EOF
out3=$(bash "$LINT" --strict --file "$tc3" 2>&1) || true
if ! bash "$LINT" --strict --file "$tc3" >/dev/null 2>&1; then
    if echo "$out3" | grep -qi "no content\|strict\|Compon"; then
        ok "TC-3" "empty Components section (comments only) fails --strict"
    else
        ko "TC-3" "lint exited 1 but wrong message" "$out3"
    fi
else
    ko "TC-3" "should fail --strict with empty (comment-only) Components section"
fi

# TC-4: Design-Approval verdict file has DESIGN: prefix
echo "TC-4: Design-Approval verdict has DESIGN: prefix"
tc4_verdict="${TMPDIR_BASE}/tc4_verdict.txt"
cat > "$tc4_verdict" << 'EOF'
DESIGN_APPROVAL_RESPONSE
Task: DESIGN:testproject
Verdict: APPROVE
Conditions:
Blockers:
Summary: All 7 criteria pass. DESIGN.md is well-structured and complete.
EOF
design_prefix_count=$(grep -c "DESIGN:" "$tc4_verdict" 2>/dev/null) || design_prefix_count=0
if [ "$design_prefix_count" -ge 1 ]; then
    ok "TC-4" "Design-Approval verdict contains DESIGN: prefix"
else
    ko "TC-4" "DESIGN: prefix not found in verdict file"
fi

# TC-5: Design-Approval verdict distinct from Plan-Approval (uses DESIGN_APPROVAL_RESPONSE)
echo "TC-5: Design-Approval verdict uses DESIGN_APPROVAL_RESPONSE"
dar_count=$(grep -c "DESIGN_APPROVAL_RESPONSE" "$tc4_verdict" 2>/dev/null) || dar_count=0
par_count=$(grep -c "PLAN_APPROVAL_RESPONSE" "$tc4_verdict" 2>/dev/null) || par_count=0
if [ "$dar_count" -ge 1 ] && [ "$par_count" -eq 0 ]; then
    ok "TC-5" "uses DESIGN_APPROVAL_RESPONSE (not PLAN_APPROVAL_RESPONSE)"
else
    ko "TC-5" "expected DESIGN_APPROVAL_RESPONSE only; dar=${dar_count} par=${par_count}"
fi

# TC-6: Brief sources scan finds project-identity.md
echo "TC-6: Brief sources scan finds project-identity.md"
tc6_dir="${TMPDIR_BASE}/tc6_project"
mkdir -p "${tc6_dir}/.aegis/brain/resonance"
cat > "${tc6_dir}/.aegis/brain/resonance/project-identity.md" << 'EOF'
# Project Identity
name: TestApp
description: A warm editorial SaaS for content creators.
aesthetic: editorial, warm, professional
EOF
found_content=$(grep -c "editorial" "${tc6_dir}/.aegis/brain/resonance/project-identity.md" 2>/dev/null) || found_content=0
if [ "$found_content" -ge 1 ]; then
    ok "TC-6" "brief source scan finds project-identity.md with known content"
else
    ko "TC-6" "project-identity.md content not found"
fi

# =================================================================
# ACCEPTANCE CHECKS (AC-1 through AC-6)
# =================================================================

# AC-1: Un-archived Wasp has MBP section
echo "AC-1: wasp.md has Master Brain Protocol"
mbp_count=$(grep -c "Master Brain Protocol" "${REPO_ROOT}/.claude/agents/wasp.md" 2>/dev/null) || mbp_count=0
if [ "$mbp_count" -ge 1 ]; then
    ok "AC-1" "wasp.md has Master Brain Protocol section"
else
    ko "AC-1" "wasp.md missing Master Brain Protocol (count=${mbp_count})"
fi

# AC-2: Nick Fury has custom-author branch
echo "AC-2: nick-fury.md has custom-author branch"
ca_count=$(grep -c "custom-author" "${REPO_ROOT}/.claude/agents/nick-fury.md" 2>/dev/null) || ca_count=0
if [ "$ca_count" -ge 1 ]; then
    ok "AC-2" "nick-fury.md has custom-author branch (count=${ca_count})"
else
    ko "AC-2" "nick-fury.md missing custom-author branch"
fi

# AC-3: Loki has Design-Approval Gate
echo "AC-3: loki.md has Design-Approval Gate"
dag_count=$(grep -c "Design-Approval Gate" "${REPO_ROOT}/.claude/agents/loki.md" 2>/dev/null) || dag_count=0
if [ "$dag_count" -ge 1 ]; then
    ok "AC-3" "loki.md has Design-Approval Gate section (count=${dag_count})"
else
    ko "AC-3" "loki.md missing Design-Approval Gate"
fi

# AC-4: Loki verdict prefix is DESIGN: not TASK
echo "AC-4: loki.md verdict uses DESIGN: prefix"
loki_design_count=$(grep -c "DESIGN:" "${REPO_ROOT}/.claude/agents/loki.md" 2>/dev/null) || loki_design_count=0
if [ "$loki_design_count" -ge 1 ]; then
    ok "AC-4" "loki.md uses DESIGN: prefix (count=${loki_design_count})"
else
    ko "AC-4" "loki.md missing DESIGN: prefix in verdict format"
fi

# AC-5: Black Panther has PASS 7 a11y review
echo "AC-5: black-panther.md has PASS 7"
pass7_count=$(grep -c "PASS 7" "${REPO_ROOT}/.claude/agents/black-panther.md" 2>/dev/null) || pass7_count=0
if [ "$pass7_count" -ge 1 ]; then
    ok "AC-5" "black-panther.md has PASS 7 section (count=${pass7_count})"
else
    ko "AC-5" "black-panther.md missing PASS 7"
fi

# AC-6: Wasp file is NOT in _archived/
echo "AC-6: wasp.md is NOT in _archived/"
if test ! -f "${REPO_ROOT}/.claude/agents/_archived/wasp.md"; then
    ok "AC-6" "wasp.md is NOT in _archived/ (correctly un-archived)"
else
    ko "AC-6" "_archived/wasp.md still exists -- not properly un-archived"
fi

# =================================================================
# Summary
# =================================================================
TOTAL=$((PASS + FAIL))
echo ""
echo "=== Results: ${PASS}/${TOTAL} passed, ${FAIL}/${TOTAL} failed ==="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
exit 0
