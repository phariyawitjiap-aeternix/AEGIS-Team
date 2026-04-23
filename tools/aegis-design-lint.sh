#!/usr/bin/env bash
# AEGIS Design Linter (S3-02)
#
# Validates that a DESIGN.md contains all 9 required sections in order.
#
# Usage:
#   tools/aegis-design-lint.sh                       # lint ./DESIGN.md
#   tools/aegis-design-lint.sh --file <path>         # lint specific file
#   tools/aegis-design-lint.sh --verbose             # show all 9 sections status
#   tools/aegis-design-lint.sh --strict              # also require content in each section
#   tools/aegis-design-lint.sh --strict --file <path>
#
# Exit: 0 = pass, 1 = fail
# Pure bash + grep/awk -- no external linting frameworks.

set -uo pipefail

# -------------------------------------------------------------------
# 9-section definitions: "name:pattern" (pattern is grep-E, case-insensitive)
# Pattern matches against lines starting with "## "
# -------------------------------------------------------------------
SECTIONS="Theme:Theme Colors:Color Typography:Typo Components:Compon Layout:Layout Depth:Depth Dos:Do Responsive:Respon Agent:Agent"

TARGET_FILE=""
VERBOSE=0
STRICT=0

# Parse arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --file)
            [ $# -lt 2 ] && { echo "FAIL: --file requires a path argument" >&2; exit 1; }
            TARGET_FILE="$2"
            shift 2
            ;;
        --verbose)
            VERBOSE=1
            shift
            ;;
        --strict)
            STRICT=1
            shift
            ;;
        -h|--help)
            sed -n '3,17p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            echo "FAIL: unknown argument: $1" >&2
            exit 1
            ;;
    esac
done

# Default file
if [ -z "$TARGET_FILE" ]; then
    TARGET_FILE="./DESIGN.md"
fi

# -------------------------------------------------------------------
# Existence / emptiness checks
# -------------------------------------------------------------------
if [ ! -f "$TARGET_FILE" ]; then
    echo "FAIL: DESIGN.md not found at ${TARGET_FILE}"
    exit 1
fi

if [ ! -s "$TARGET_FILE" ]; then
    echo "FAIL: DESIGN.md is empty (${TARGET_FILE})"
    exit 1
fi

# -------------------------------------------------------------------
# Section scanning: find all "## " lines with their line numbers
# -------------------------------------------------------------------

# Build arrays of found sections: name + line number
# We store: "lineno:sectionname" for each ## header found

found_count=0
last_section_idx=0
fail_msgs=""

# Convert SECTIONS into arrays (bash 3.2 compatible: use space-delimited string)
section_names=""
section_patterns=""
for entry in $SECTIONS; do
    sname="${entry%%:*}"
    spat="${entry##*:}"
    section_names="${section_names} ${sname}"
    section_patterns="${section_patterns} ${spat}"
done

# We iterate sections in order, scanning forward through the file for each
# The scan tracks a "start line" cursor to enforce ordering.

file_line_count=$(wc -l < "$TARGET_FILE")
cursor_line=1  # we must find each section after this line number
idx=0

found_section_lines=""  # "sname:lineno" space-separated

for entry in $SECTIONS; do
    sname="${entry%%:*}"
    spat="${entry##*:}"
    idx=$((idx + 1))

    # Search for this section's ## header, case-insensitive, from cursor_line onward
    # awk: print line number of first match at or after cursor_line
    found_lineno=$(awk -v pat="${spat}" -v start="$cursor_line" 'BEGIN{IGNORECASE=1} NR>=start && /^## / && tolower($0) ~ tolower(pat) {print NR; exit}' "$TARGET_FILE" 2>/dev/null) || found_lineno=""

    if [ -z "$found_lineno" ]; then
        # Get the last successfully-found section's name and lineno from found_section_lines
        # Format: " Name:lineno Name2:lineno2 ..." (space-separated tokens, each "name:lineno")
        _last_token=""
        _prev_name=""
        _prev_lineno=""
        if [ -n "$found_section_lines" ]; then
            _last_token="$(echo "$found_section_lines" | tr ' ' '\n' | grep -v '^$' | tail -1)"
            _prev_name="${_last_token%%:*}"
            _prev_lineno="${_last_token##*:}"
        fi

        # Check if the section exists earlier in the file (before cursor = out-of-order)
        early_lineno=$(awk -v pat="${spat}" 'BEGIN{IGNORECASE=1} /^## / && tolower($0) ~ tolower(pat) {print NR; exit}' "$TARGET_FILE" 2>/dev/null) || early_lineno=""
        if [ -n "$early_lineno" ] && [ "$early_lineno" -lt "$cursor_line" ]; then
            # Section is present but appeared before a section that should come first
            if [ -n "$_prev_name" ] && [ -n "$_prev_lineno" ]; then
                msg="FAIL: Section \"${sname}\" (line ${early_lineno}) appears before \"${_prev_name}\" (line ${_prev_lineno}) -- sections must follow canonical order"
            else
                msg="FAIL: Section \"${sname}\" (line ${early_lineno}) appears before expected position -- sections must follow canonical order"
            fi
        else
            # Genuinely missing (not found anywhere in the file)
            if [ -n "$_prev_name" ]; then
                msg="FAIL: Missing section \"${sname}\" -- expected after \"${_prev_name}\""
            else
                msg="FAIL: Missing section \"${sname}\""
            fi
        fi
        fail_msgs="${fail_msgs}|${msg}"
        if [ $VERBOSE -eq 1 ]; then
            echo "  MISSING: ${sname}"
        fi
    else
        found_section_lines="${found_section_lines} ${sname}:${found_lineno}"
        found_count=$((found_count + 1))
        cursor_line=$((found_lineno + 1))
        if [ $VERBOSE -eq 1 ]; then
            echo "  FOUND at line ${found_lineno}: ${sname}"
        fi
    fi
done

# -------------------------------------------------------------------
# Report structural failures
# -------------------------------------------------------------------
if [ -n "$fail_msgs" ]; then
    echo "$fail_msgs" | tr '|' '\n' | grep -v '^$'
    exit 1
fi

if [ $VERBOSE -eq 1 ]; then
    echo "Structure: all 9 sections present and in order"
fi

# -------------------------------------------------------------------
# Strict mode: each section must have >=1 non-empty, non-comment line
# -------------------------------------------------------------------
if [ $STRICT -eq 1 ]; then
    strict_fail=0

    # Parse section header line numbers from found_section_lines
    # found_section_lines: " Theme:5 Colors:12 ..."
    prev_lineno=""
    prev_name=""
    section_list="$found_section_lines"

    # Build a list of (name, start_line, end_line) tuples
    # We iterate pairs: current section ends at (next section start - 1) or EOF

    section_arr=""
    for token in $section_list; do
        sname="${token%%:*}"
        sline="${token##*:}"
        section_arr="${section_arr} ${sname}:${sline}"
    done

    idx=0
    section_count=$(echo "$section_arr" | tr ' ' '\n' | grep -c ':') || section_count=0

    for token in $section_arr; do
        sname="${token%%:*}"
        sline="${token##*:}"
        idx=$((idx + 1))

        # Determine end line (start of next section - 1, or EOF)
        next_start=""
        tok_idx=0
        for t2 in $section_arr; do
            tok_idx=$((tok_idx + 1))
            if [ "$tok_idx" -eq $((idx + 1)) ]; then
                next_start="${t2##*:}"
                break
            fi
        done

        if [ -z "$next_start" ]; then
            end_line=$file_line_count
        else
            end_line=$((next_start - 1))
        fi

        body_start=$((sline + 1))

        if [ "$body_start" -gt "$end_line" ]; then
            # Section has no lines at all after its header
            echo "FAIL (strict): Section \"${sname}\" has no content -- only comments/blanks"
            strict_fail=$((strict_fail + 1))
            continue
        fi

        # Count content lines: not blank, not starting with <!--
        content_count=$(awk -v s="$body_start" -v e="$end_line" \
            'NR>=s && NR<=e && /[^ \t]/ && !/^[ \t]*<!--/ {count++} END{print count+0}' \
            "$TARGET_FILE" 2>/dev/null) || content_count=0

        if [ "$content_count" -eq 0 ]; then
            echo "FAIL (strict): Section \"${sname}\" has no content -- only comments/blanks"
            strict_fail=$((strict_fail + 1))
        elif [ $VERBOSE -eq 1 ]; then
            echo "  CONTENT OK: ${sname} (${content_count} content lines)"
        fi
    done

    if [ "$strict_fail" -gt 0 ]; then
        exit 1
    fi

    if [ $VERBOSE -eq 1 ]; then
        echo "Strict: all 9 sections have content"
    fi
fi

echo "PASS: DESIGN.md is valid (${TARGET_FILE})"
exit 0
