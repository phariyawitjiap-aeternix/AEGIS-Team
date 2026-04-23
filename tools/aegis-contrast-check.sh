#!/usr/bin/env bash
# AEGIS Contrast Check (S3-06 -- D-037 Fix 3)
#
# Parses section 2 (Colors) of a DESIGN.md for hex color pairs
# and computes WCAG contrast ratios using embedded Python3.
#
# Usage:
#   tools/aegis-contrast-check.sh --file <DESIGN.md path>
#   tools/aegis-contrast-check.sh --pair "#000000" "#FFFFFF"
#
# Output: per-pair line: hex-fg vs hex-bg -> ratio -> AA/AAA/FAIL
# Exit:   0 if all pairs pass AA (4.5:1 normal text), 1 if any fail
#
# Pair format in DESIGN.md:
#   "#RRGGBB on #RRGGBB"   (anywhere in section 2 body)

set -euo pipefail

# -------------------------------------------------------------------
# Argument parsing
# -------------------------------------------------------------------
TARGET_FILE=""
PAIR_FG=""
PAIR_BG=""

while [ $# -gt 0 ]; do
    case "$1" in
        --file)
            [ $# -lt 2 ] && { echo "FAIL: --file requires a path argument" >&2; exit 1; }
            TARGET_FILE="$2"
            shift 2
            ;;
        --pair)
            [ $# -lt 3 ] && { echo "FAIL: --pair requires two hex arguments" >&2; exit 1; }
            PAIR_FG="$2"
            PAIR_BG="$3"
            shift 3
            ;;
        -h|--help)
            sed -n '3,18p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            echo "FAIL: unknown argument: $1" >&2
            exit 1
            ;;
    esac
done

# -------------------------------------------------------------------
# Python3 WCAG contrast computation (embedded)
# -------------------------------------------------------------------
PYTHON_CONTRAST=$(cat << 'PYEOF'
import sys
import re

def hex_to_rgb(h):
    h = h.lstrip('#')
    if len(h) == 3:
        h = ''.join(c*2 for c in h)
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def linearize(c):
    c = c / 255.0
    if c <= 0.03928:
        return c / 12.92
    return ((c + 0.055) / 1.055) ** 2.4

def luminance(r, g, b):
    return 0.2126 * linearize(r) + 0.7152 * linearize(g) + 0.0722 * linearize(b)

def contrast_ratio(hex1, hex2):
    r1, g1, b1 = hex_to_rgb(hex1)
    r2, g2, b2 = hex_to_rgb(hex2)
    L1 = luminance(r1, g1, b1)
    L2 = luminance(r2, g2, b2)
    lighter = max(L1, L2)
    darker  = min(L1, L2)
    return (lighter + 0.05) / (darker + 0.05)

def wcag_level(ratio):
    if ratio >= 7.0:
        return "AAA"
    elif ratio >= 4.5:
        return "AA"
    else:
        return "FAIL"

pairs = []
for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    parts = line.split()
    if len(parts) != 2:
        print(f"ERROR: expected 2 hex values, got {len(parts)}: {line}", file=sys.stderr)
        sys.exit(2)
    fg, bg = parts
    try:
        ratio = contrast_ratio(fg, bg)
        level = wcag_level(ratio)
        pairs.append((fg, bg, ratio, level))
        print(f"{fg} vs {bg} -> {ratio:.2f}:1 -> {level}")
    except Exception as e:
        print(f"ERROR computing contrast for {fg}/{bg}: {e}", file=sys.stderr)
        sys.exit(2)

any_fail = any(p[3] == "FAIL" for p in pairs)
sys.exit(1 if any_fail else 0)
PYEOF
)

# -------------------------------------------------------------------
# --pair mode: single pair from command line
# -------------------------------------------------------------------
if [ -n "$PAIR_FG" ] && [ -n "$PAIR_BG" ]; then
    echo "${PAIR_FG} ${PAIR_BG}" | python3 -c "$PYTHON_CONTRAST"
    exit $?
fi

# -------------------------------------------------------------------
# --file mode: parse DESIGN.md section 2 for hex pairs
# -------------------------------------------------------------------
if [ -z "$TARGET_FILE" ]; then
    echo "FAIL: --file <path> or --pair <fg> <bg> is required" >&2
    exit 1
fi

if [ ! -f "$TARGET_FILE" ]; then
    echo "FAIL: file not found: ${TARGET_FILE}" >&2
    exit 1
fi

# Extract section 2 (Colors) body: lines from "## 2." or "## Colors" up to next "## "
# Then grep for "#RRGGBB on #RRGGBB" patterns (case-insensitive hex)
HEX_PATTERN='#[0-9A-Fa-f]{6}\b.*\bon\b.*#[0-9A-Fa-f]{6}'

# Find section 2 start line
sec2_start=$(awk '/^## .*[Cc]olor/{print NR; exit}' "$TARGET_FILE")
if [ -z "$sec2_start" ]; then
    echo "FAIL: No Colors section (## ...Color...) found in ${TARGET_FILE}" >&2
    exit 1
fi

# Find next ## section after sec2
sec2_end=$(awk -v s="$sec2_start" 'NR > s && /^## /{print NR; exit}' "$TARGET_FILE")
if [ -z "$sec2_end" ]; then
    sec2_end=$(wc -l < "$TARGET_FILE")
fi

# Extract section 2 body and grep for hex pairs
section2=$(awk -v s="$sec2_start" -v e="$sec2_end" 'NR>s && NR<e' "$TARGET_FILE")

# Build pairs list: extract first and second hex from each matching line
pairs_input=$(echo "$section2" | grep -Ei '#[0-9A-Fa-f]{6}' | \
    grep -Ei ' on ' | \
    grep -oEi '#[0-9A-Fa-f]{6}[^#]*on[^#]*#[0-9A-Fa-f]{6}' | \
    while IFS= read -r match; do
        fg=$(echo "$match" | grep -oEi '#[0-9A-Fa-f]{6}' | head -1)
        bg=$(echo "$match" | grep -oEi '#[0-9A-Fa-f]{6}' | tail -1)
        if [ -n "$fg" ] && [ -n "$bg" ] && [ "$fg" != "$bg" ]; then
            echo "$fg $bg"
        fi
    done)

if [ -z "$pairs_input" ]; then
    echo "INFO: No hex pairs (\"#RRGGBB on #RRGGBB\") found in Colors section -- nothing to check"
    exit 0
fi

echo "$pairs_input" | python3 -c "$PYTHON_CONTRAST"
exit $?
