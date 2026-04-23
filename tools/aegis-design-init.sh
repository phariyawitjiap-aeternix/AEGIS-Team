#!/usr/bin/env bash
# AEGIS Design Init Wizard (S3-02)
#
# Creates a DESIGN.md at the target location. Non-interactive per spec §5.2.
# All choices determined by CLI flags -- no stdin reads, no prompts.
#
# Usage:
#   tools/aegis-design-init.sh --vibe <keyword>   # pick by vibe keyword
#   tools/aegis-design-init.sh --from <slug>      # copy from library
#   tools/aegis-design-init.sh --blank            # empty 9-section skeleton
#   tools/aegis-design-init.sh --output <path>    # default: ./DESIGN.md
#
# Vibe keywords: minimal, bold, warm, dark, elegant, terminal, enterprise, ai
#
# Exit: 0 = success, 1 = error

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LIBRARY_DIR="${REPO_ROOT}/.aegis/brain/design-library"
LINT_TOOL="${SCRIPT_DIR}/aegis-design-lint.sh"

# Vibe-to-library mapping: "keyword:first_slug"
# Per spec §3.4: each vibe picks first match from priority list
VIBE_MAP="minimal:linear bold:xai warm:claude dark:cursor elegant:stripe terminal:warp enterprise:cohere ai:claude"

MODE=""
FROM_SLUG=""
VIBE_KEYWORD=""
OUTPUT_PATH=""

usage() {
    sed -n '3,18p' "$0" | sed 's/^# \{0,1\}//'
    exit 1
}

while [ $# -gt 0 ]; do
    case "$1" in
        --vibe)
            [ $# -lt 2 ] && { echo "ERROR: --vibe requires a keyword" >&2; exit 1; }
            MODE="vibe"
            VIBE_KEYWORD="$2"
            shift 2
            ;;
        --from)
            [ $# -lt 2 ] && { echo "ERROR: --from requires a slug" >&2; exit 1; }
            MODE="from"
            FROM_SLUG="$2"
            shift 2
            ;;
        --blank)
            MODE="blank"
            shift
            ;;
        --output)
            [ $# -lt 2 ] && { echo "ERROR: --output requires a path" >&2; exit 1; }
            OUTPUT_PATH="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "ERROR: unknown argument: $1" >&2
            exit 1
            ;;
    esac
done

# Default mode is blank when no mode specified
if [ -z "$MODE" ]; then
    MODE="blank"
fi

# Default output path
if [ -z "$OUTPUT_PATH" ]; then
    OUTPUT_PATH="./DESIGN.md"
fi

# -------------------------------------------------------------------
# Guard: refuse to overwrite existing file
# -------------------------------------------------------------------
if [ -f "$OUTPUT_PATH" ]; then
    echo "ERROR: DESIGN.md already exists at ${OUTPUT_PATH} -- use --output to write elsewhere or remove existing file"
    exit 1
fi

# -------------------------------------------------------------------
# Resolve slug from vibe keyword
# -------------------------------------------------------------------
resolve_vibe() {
    local keyword="$1"
    local kw_lower
    kw_lower=$(echo "$keyword" | tr '[:upper:]' '[:lower:]')
    for pair in $VIBE_MAP; do
        vibe="${pair%%:*}"
        slug="${pair##*:}"
        if [ "$vibe" = "$kw_lower" ]; then
            echo "$slug"
            return 0
        fi
    done
    echo ""
}

# -------------------------------------------------------------------
# Blank skeleton template
# -------------------------------------------------------------------
emit_blank() {
    cat << 'SKELETON'
# DESIGN.md

## 1. Theme
<!-- TODO: Describe the overall visual atmosphere -->

## 2. Colors
<!-- TODO: Define color palette with semantic names -->

## 3. Typography
<!-- TODO: Define font families, sizes, weights -->

## 4. Components
<!-- TODO: Define component styles and states -->

## 5. Layout
<!-- TODO: Define spacing, grid, alignment -->

## 6. Depth
<!-- TODO: Define shadows, elevation, layering -->

## 7. Do's and Don'ts
<!-- TODO: Visual guardrails -->

## 8. Responsive
<!-- TODO: Breakpoints and adaptive behavior -->

## 9. Agent Prompt Guide
<!-- TODO: Copy-paste prompts for coding agents -->
SKELETON
}

# -------------------------------------------------------------------
# Execute mode
# -------------------------------------------------------------------
case "$MODE" in

    blank)
        mkdir -p "$(dirname "$OUTPUT_PATH")" 2>/dev/null || true
        emit_blank > "$OUTPUT_PATH"
        chmod 644 "$OUTPUT_PATH"
        echo "DESIGN.md created at ${OUTPUT_PATH} -- customize sections before building"
        ;;

    from)
        if [ -z "$FROM_SLUG" ]; then
            echo "ERROR: --from requires a slug" >&2
            exit 1
        fi
        # Validate slug name (no path traversal)
        case "$FROM_SLUG" in
            ""|*"/"*|*".."*)
                echo "ERROR: invalid slug '${FROM_SLUG}'" >&2
                exit 1
                ;;
        esac
        source_file="${LIBRARY_DIR}/${FROM_SLUG}/DESIGN.md"
        if [ ! -f "$source_file" ]; then
            echo "ERROR: slug '${FROM_SLUG}' not found in library (${source_file})" >&2
            echo "       Available slugs: claude vercel linear raycast stripe cursor replicate cohere xai warp" >&2
            echo "       Run: tools/aegis-design-fetch.sh --list" >&2
            exit 1
        fi
        mkdir -p "$(dirname "$OUTPUT_PATH")" 2>/dev/null || true
        cp "$source_file" "$OUTPUT_PATH"
        chmod 644 "$OUTPUT_PATH"
        echo "DESIGN.md created at ${OUTPUT_PATH} -- customize sections before building"
        ;;

    vibe)
        if [ -z "$VIBE_KEYWORD" ]; then
            echo "ERROR: --vibe requires a keyword" >&2
            exit 1
        fi
        resolved_slug="$(resolve_vibe "$VIBE_KEYWORD")"
        if [ -z "$resolved_slug" ]; then
            echo "ERROR: unknown vibe keyword '${VIBE_KEYWORD}'" >&2
            echo "       Valid vibes: minimal, bold, warm, dark, elegant, terminal, enterprise, ai" >&2
            exit 1
        fi
        source_file="${LIBRARY_DIR}/${resolved_slug}/DESIGN.md"
        if [ ! -f "$source_file" ]; then
            echo "ERROR: vibe '${VIBE_KEYWORD}' maps to slug '${resolved_slug}' but library file not found (${source_file})" >&2
            echo "       Seed the library first: tools/aegis-design-fetch.sh --seed-all" >&2
            exit 1
        fi
        mkdir -p "$(dirname "$OUTPUT_PATH")" 2>/dev/null || true
        cp "$source_file" "$OUTPUT_PATH"
        chmod 644 "$OUTPUT_PATH"
        echo "DESIGN.md created at ${OUTPUT_PATH} (vibe: ${VIBE_KEYWORD} -> ${resolved_slug}) -- customize sections before building"
        ;;

    *)
        echo "ERROR: unknown mode '${MODE}'" >&2
        exit 1
        ;;
esac

# -------------------------------------------------------------------
# Post-init lint (warn but don't fail on lint errors -- blank is valid structure)
# -------------------------------------------------------------------
if [ -x "$LINT_TOOL" ]; then
    lint_output=$("$LINT_TOOL" --file "$OUTPUT_PATH" 2>&1) || lint_exit=$?
    lint_exit=${lint_exit:-0}
    if [ "$lint_exit" -ne 0 ]; then
        echo "WARN: lint check on ${OUTPUT_PATH} reported issues:"
        echo "$lint_output"
        echo "      (This is a warning only -- the file was still created)"
    fi
fi

exit 0
