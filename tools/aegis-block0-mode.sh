#!/usr/bin/env bash
# AEGIS BLOCK 0 Mode Determiner (Sprint v9-02 S2-03/04)
#
# Pure-function helper that implements the `determine_block0_mode(task)`
# pseudocode from `.claude/references/block-0-lite.md`. Given a task's
# tags (comma-separated) and story points, emits one of:
#   lite      -- skip SI.01 + SI.02 (use for typos/chores/hotfixes)
#   standard  -- skip SI.02 only
#   full      -- enforce all 5 BLOCK 0 checks (default for anything >5pt
#                or tagged security/breaking/feature/refactor)
#
# Usage:
#   ./tools/aegis-block0-mode.sh --points <N> --tags <tag1,tag2,...>
#   ./tools/aegis-block0-mode.sh --task-id PROJ-T-042
#   ./tools/aegis-block0-mode.sh --points 1            # no tags
#
# When `--task-id` is given, reads tags + story points from
# `.aegis/brain/tasks/<id>/meta.json`. Otherwise pass `--points` and
# optional `--tags` directly (useful from agent prompts that already
# have the task context in memory).
#
# Output: one word on stdout (lite / standard / full).
# Exit codes: 0 = mode emitted, 1 = parse error, 2 = usage error.
#
# Precedence:
#   1. Tag override: chore/typo/docs-fix/hotfix -> lite
#   2. Tag override: feature/refactor/security/breaking -> full
#   3. Size: <=1pt -> lite, 2-5pt -> standard, >5pt -> full

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

POINTS=""
TAGS=""
TASK_ID=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --points)  POINTS="${2:-}"; shift 2 ;;
        --tags)    TAGS="${2:-}"; shift 2 ;;
        --task-id) TASK_ID="${2:-}"; shift 2 ;;
        -h|--help)
            sed -n '3,22p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *) echo "ERROR: unknown arg: $1" >&2; exit 2 ;;
    esac
done

# --- Load from meta.json if --task-id given ---
if [[ -n "$TASK_ID" ]]; then
    META="${REPO_ROOT}/.aegis/brain/tasks/${TASK_ID}/meta.json"
    if [[ ! -f "$META" ]]; then
        echo "ERROR: meta.json not found for task: $TASK_ID" >&2
        echo "       expected at: $META" >&2
        exit 1
    fi
    PARSED=$(python3 -c "
import json, sys
try:
    m = json.load(open('$META'))
except Exception as e:
    print('ERROR', e, file=sys.stderr); sys.exit(1)
pts = m.get('story_points') or m.get('points') or m.get('size') or 0
tags = m.get('tags') or []
if isinstance(tags, list):
    tags = ','.join(str(t) for t in tags)
print(f'{pts}|{tags}')
" 2>/dev/null) || { echo "ERROR: failed to parse $META" >&2; exit 1; }
    POINTS="${PARSED%%|*}"
    TAGS="${PARSED##*|}"
fi

# --- Validate ---
if [[ -z "$POINTS" ]]; then
    echo "ERROR: --points <N> required (or --task-id that resolves to points)" >&2
    exit 2
fi
if ! [[ "$POINTS" =~ ^[0-9]+$ ]]; then
    echo "ERROR: --points must be a non-negative integer, got: $POINTS" >&2
    exit 1
fi

# Normalize tags: lowercase, comma-separated, strip spaces
# Use tr for lowercase (macOS bash 3.2 doesn't support ${var,,})
TAGS_LOWER=$(echo "$TAGS" | tr '[:upper:]' '[:lower:]')
TAGS_NORM=$(echo ",${TAGS_LOWER}," | tr -d ' ')

# --- Tag overrides first (per spec precedence) ---
for lite_tag in chore typo docs-fix hotfix; do
    if echo "$TAGS_NORM" | grep -q ",${lite_tag},"; then
        echo "lite"
        exit 0
    fi
done

for full_tag in feature refactor security breaking; do
    if echo "$TAGS_NORM" | grep -q ",${full_tag},"; then
        echo "full"
        exit 0
    fi
done

# --- Size-based default ---
if [[ "$POINTS" -le 1 ]]; then
    echo "lite"
elif [[ "$POINTS" -le 5 ]]; then
    echo "standard"
else
    echo "full"
fi
