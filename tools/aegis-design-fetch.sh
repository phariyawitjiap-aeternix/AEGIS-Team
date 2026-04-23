#!/usr/bin/env bash
# AEGIS Design Fetch Tool (S3-01)
#
# Fetch DESIGN.md files from the VoltAgent/awesome-design-md upstream library.
#
# Usage:
#   tools/aegis-design-fetch.sh --project <slug> [--output <path>]
#   tools/aegis-design-fetch.sh --list
#   tools/aegis-design-fetch.sh --check <slug>
#   tools/aegis-design-fetch.sh --seed-all
#   tools/aegis-design-fetch.sh --verify-library
#
# Upstream URL:
#   https://raw.githubusercontent.com/VoltAgent/awesome-design-md/main/design-md/<upstream-slug>/README.md
#
# Note: the upstream repo uses README.md (not DESIGN.md) as the file name.
# Some spec slugs differ from upstream slugs: linear -> linear.app, xai -> x.ai
# Content is stored locally as DESIGN.md for AEGIS library conventions.
#
# Exit codes: 0 = success, 1 = fetch/check error, 2 = usage error

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Single-point-of-change: upstream base URL
AEGIS_DESIGN_LIBRARY_URL="https://raw.githubusercontent.com/VoltAgent/awesome-design-md/main/design-md"

LIBRARY_DIR="${REPO_ROOT}/.aegis/brain/design-library"

# Canonical 10 slugs (AEGIS local slug -> upstream slug mapping)
# Format: "local_slug:upstream_slug"
CANONICAL_SLUGS="claude:claude vercel:vercel linear:linear.app raycast:raycast stripe:stripe cursor:cursor replicate:replicate cohere:cohere xai:x.ai warp:warp"

# -------------------------------------------------------------------
# helpers
# -------------------------------------------------------------------

usage() {
    sed -n '3,20p' "$0" | sed 's/^# \{0,1\}//'
    exit 2
}

# Map local slug to upstream slug
upstream_slug_for() {
    local local_slug="$1"
    for pair in $CANONICAL_SLUGS; do
        local lslug="${pair%%:*}"
        local uslug="${pair##*:}"
        if [ "$lslug" = "$local_slug" ]; then
            echo "$uslug"
            return 0
        fi
    done
    # Unknown slug: use as-is
    echo "$local_slug"
}

# Map upstream slug to local slug
local_slug_for() {
    local upstream="$1"
    for pair in $CANONICAL_SLUGS; do
        local lslug="${pair%%:*}"
        local uslug="${pair##*:}"
        if [ "$uslug" = "$upstream" ]; then
            echo "$lslug"
            return 0
        fi
    done
    echo "$upstream"
}

fetch_slug() {
    local local_slug="$1"
    local output_path="$2"
    local upstream_slug
    upstream_slug="$(upstream_slug_for "$local_slug")"
    local url="${AEGIS_DESIGN_LIBRARY_URL}/${upstream_slug}/README.md"

    # Check upstream availability BEFORE creating any directories
    http_code=$(curl -sL -o /dev/null -w "%{http_code}" "$url" 2>/dev/null) || {
        echo "ERROR: Fetch failed for '${local_slug}' -- check network or slug validity" >&2
        return 1
    }

    if [ "$http_code" = "404" ]; then
        echo "ERROR: DESIGN.md not found for '${local_slug}' (upstream slug '${upstream_slug}')" >&2
        echo "       Verify slug at https://github.com/VoltAgent/awesome-design-md/tree/main/design-md" >&2
        echo "       Upstream path may have changed -- verify ${AEGIS_DESIGN_LIBRARY_URL} structure" >&2
        return 1
    fi

    if [ "$http_code" != "200" ]; then
        echo "ERROR: Fetch failed for '${local_slug}' -- upstream returned HTTP ${http_code}" >&2
        echo "       Upstream path may have changed -- verify ${AEGIS_DESIGN_LIBRARY_URL} structure" >&2
        return 1
    fi

    # Only create directory after confirming upstream availability
    mkdir -p "$(dirname "$output_path")"

    curl -fsSL "$url" -o "$output_path" 2>/dev/null || {
        echo "ERROR: Fetch failed for '${local_slug}' -- check network or slug validity" >&2
        return 1
    }

    chmod 644 "$output_path"
    echo "Saved: $output_path"
}

# -------------------------------------------------------------------
# parse args
# -------------------------------------------------------------------

MODE=""
TARGET_SLUG=""
OUTPUT_PATH=""

if [ $# -eq 0 ]; then usage; fi

while [ $# -gt 0 ]; do
    case "$1" in
        --project)
            [ $# -lt 2 ] && { echo "ERROR: --project requires a slug argument" >&2; exit 2; }
            MODE="project"
            TARGET_SLUG="$2"
            shift 2
            ;;
        --slug)
            # alias for --project (spec mentions --slug)
            [ $# -lt 2 ] && { echo "ERROR: --slug requires a slug argument" >&2; exit 2; }
            MODE="project"
            TARGET_SLUG="$2"
            shift 2
            ;;
        --output)
            [ $# -lt 2 ] && { echo "ERROR: --output requires a path argument" >&2; exit 2; }
            OUTPUT_PATH="$2"
            shift 2
            ;;
        --list)
            MODE="list"
            shift
            ;;
        --check)
            [ $# -lt 2 ] && { echo "ERROR: --check requires a slug argument" >&2; exit 2; }
            MODE="check"
            TARGET_SLUG="$2"
            shift 2
            ;;
        --seed-all)
            MODE="seed-all"
            shift
            ;;
        --verify-library)
            MODE="verify-library"
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "ERROR: unknown argument: $1" >&2
            exit 2
            ;;
    esac
done

# -------------------------------------------------------------------
# execute
# -------------------------------------------------------------------

case "$MODE" in

    list)
        if [ ! -d "$LIBRARY_DIR" ]; then
            echo "Library directory not found: $LIBRARY_DIR" >&2
            exit 1
        fi
        count=0
        for dir in "$LIBRARY_DIR"/*/; do
            if [ -d "$dir" ]; then
                slug="$(basename "$dir")"
                # Skip README.md as a slug
                if [ "$slug" != "README.md" ]; then
                    echo "$slug"
                    count=$((count + 1))
                fi
            fi
        done
        echo "(${count} slugs in local library)"
        ;;

    check)
        if [ -z "$TARGET_SLUG" ]; then
            echo "ERROR: --check requires a slug" >&2
            exit 2
        fi
        upstream_slug="$(upstream_slug_for "$TARGET_SLUG")"
        url="${AEGIS_DESIGN_LIBRARY_URL}/${upstream_slug}/README.md"
        http_code=$(curl -sI -o /dev/null -w "%{http_code}" "$url" 2>/dev/null) || {
            echo "ERROR: network error checking '${TARGET_SLUG}'" >&2
            exit 1
        }
        if [ "$http_code" = "200" ]; then
            echo "OK: '${TARGET_SLUG}' is reachable upstream (HTTP ${http_code})"
            exit 0
        else
            echo "FAIL: '${TARGET_SLUG}' not found upstream (HTTP ${http_code})" >&2
            echo "      Verify at https://github.com/VoltAgent/awesome-design-md/tree/main/design-md" >&2
            exit 1
        fi
        ;;

    project)
        if [ -z "$TARGET_SLUG" ]; then
            echo "ERROR: --project requires a slug" >&2
            exit 2
        fi
        # Validate slug is not empty or suspicious
        case "$TARGET_SLUG" in
            ""|*"/"*|*".."*)
                echo "ERROR: invalid slug '${TARGET_SLUG}' -- slugs must not contain path separators" >&2
                exit 1
                ;;
        esac
        if [ -z "$OUTPUT_PATH" ]; then
            OUTPUT_PATH="${LIBRARY_DIR}/${TARGET_SLUG}/DESIGN.md"
        fi
        fetch_slug "$TARGET_SLUG" "$OUTPUT_PATH"
        ;;

    seed-all)
        echo "Seeding design library with 10 canonical slugs..."
        ok=0
        fail=0
        for pair in $CANONICAL_SLUGS; do
            local_slug="${pair%%:*}"
            output="${LIBRARY_DIR}/${local_slug}/DESIGN.md"
            if fetch_slug "$local_slug" "$output"; then
                ok=$((ok + 1))
            else
                fail=$((fail + 1))
                echo "SKIP: ${local_slug} (fetch failed -- upstream content may be behind web app)" >&2
            fi
        done
        echo ""
        echo "Seed complete: ${ok}/10 succeeded, ${fail}/10 failed"
        if [ "$fail" -gt 0 ]; then
            echo "Note: Some files may require manual seeding if upstream moved content behind a web app."
            echo "      Verify: ${AEGIS_DESIGN_LIBRARY_URL} structure"
        fi
        exit 0
        ;;

    verify-library)
        if [ ! -d "$LIBRARY_DIR" ]; then
            echo "ERROR: library directory not found: $LIBRARY_DIR" >&2
            exit 1
        fi

        any_stale=0
        checked=0

        # Collect local slugs from directory listing
        for dir in "$LIBRARY_DIR"/*/; do
            [ -d "$dir" ] || continue
            local_slug="$(basename "$dir")"
            [ -f "$dir/DESIGN.md" ] || continue

            upstream_slug="$(upstream_slug_for "$local_slug")"
            url="${AEGIS_DESIGN_LIBRARY_URL}/${upstream_slug}/README.md"

            http_code=$(curl -sI -o /dev/null -w "%{http_code}" "$url" 2>/dev/null) || http_code="000"
            checked=$((checked + 1))

            if [ "$http_code" = "200" ]; then
                echo "OK: ${local_slug} (upstream slug: ${upstream_slug})"
            else
                echo "STALE: ${local_slug} -- upstream URL returned ${http_code}. Re-fetch with --project ${local_slug} or verify upstream repo structure."
                any_stale=$((any_stale + 1))
            fi
        done

        echo ""
        echo "Verified ${checked} entries. Stale: ${any_stale}"

        if [ "$any_stale" -gt 0 ]; then
            exit 1
        fi
        exit 0
        ;;

    *)
        echo "ERROR: no mode specified" >&2
        usage
        ;;
esac
