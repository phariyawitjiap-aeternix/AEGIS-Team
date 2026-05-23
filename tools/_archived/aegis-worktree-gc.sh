#!/usr/bin/env bash
# =============================================================================
# aegis-worktree-gc.sh
# Worktree garbage collector (S5-07 implementation)
# =============================================================================
# Cleans up orphan AEGIS worktrees + merged branches.
# Pattern: aegis-wt/<agent>-<task-id>-<timestamp>
#
# Usage:
#   ./tools/aegis-worktree-gc.sh                    # dry-run (default)
#   ./tools/aegis-worktree-gc.sh --apply            # actually delete
#   ./tools/aegis-worktree-gc.sh --apply --age 14   # custom age in days
# =============================================================================

# Don't use pipefail — many pipes use grep that may legitimately return no match (exit 1)
set -eu

MODE="dry-run"
AGE_DAYS=7

while [ $# -gt 0 ]; do
    case "$1" in
        --apply) MODE="apply"; shift ;;
        --dry-run) MODE="dry-run"; shift ;;
        --age) AGE_DAYS="$2"; shift 2 ;;
        --help|-h)
            sed -n '2,15p' "$0"
            exit 0
            ;;
        *) echo "Unknown arg: $1" >&2; exit 2 ;;
    esac
done

# Colors
if [ -t 1 ]; then
    C_GREEN='\033[0;32m'
    C_YELLOW='\033[1;33m'
    C_CYAN='\033[0;36m'
    C_RESET='\033[0m'
else
    C_GREEN='' C_YELLOW='' C_CYAN='' C_RESET=''
fi

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

# Verify git available + we're in repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Not a git repository: $PROJECT_ROOT" >&2
    exit 1
fi

echo "AEGIS Worktree GC (mode: ${MODE}, max age: ${AGE_DAYS} days)"
echo

# ────────────────────────────────────────────────────────────────────────────
# 1. Worktrees: find aegis-wt/* older than AGE_DAYS
# ────────────────────────────────────────────────────────────────────────────
echo "${C_CYAN}=== Stale Worktrees ===${C_RESET}"

WORKTREE_COUNT=0
STALE_COUNT=0

# git worktree list output format:
#   /path/to/worktree  HEAD-ABC  [branch-name]
git worktree list --porcelain 2>/dev/null | awk '/^worktree / { print substr($0,10) }' | while IFS= read -r wt_path; do
    # Skip main worktree
    if [ "$wt_path" = "$PROJECT_ROOT" ]; then
        continue
    fi

    # Only process aegis-wt/ pattern
    if [[ "$wt_path" != */aegis-wt/* ]]; then
        continue
    fi

    WORKTREE_COUNT=$((WORKTREE_COUNT + 1))

    # Calculate age (macOS stat differs from GNU stat)
    if [ -d "$wt_path" ]; then
        if [[ "$(uname)" == "Darwin" ]]; then
            mtime=$(stat -f %m "$wt_path")
        else
            mtime=$(stat -c %Y "$wt_path")
        fi
        now=$(date +%s)
        age_days=$(( (now - mtime) / 86400 ))

        if [ "$age_days" -gt "$AGE_DAYS" ]; then
            STALE_COUNT=$((STALE_COUNT + 1))
            echo "  ${C_YELLOW}STALE${C_RESET}: $wt_path (age: ${age_days}d)"

            if [ "$MODE" = "apply" ]; then
                git worktree remove --force "$wt_path" 2>&1 | sed 's/^/    /'
                echo "    ${C_GREEN}REMOVED${C_RESET}"
            fi
        else
            echo "  ${C_GREEN}KEEP${C_RESET}: $wt_path (age: ${age_days}d, < ${AGE_DAYS}d threshold)"
        fi
    fi
done

if [ "$WORKTREE_COUNT" -eq 0 ]; then
    echo "  No aegis-wt/ worktrees found."
fi

# ────────────────────────────────────────────────────────────────────────────
# 2. Branches: find aegis-wt/* already merged into main
# ────────────────────────────────────────────────────────────────────────────
echo
echo "${C_CYAN}=== Merged Branches ===${C_RESET}"

MERGED_COUNT=0

git branch --merged main 2>/dev/null | grep "aegis-wt/" 2>/dev/null | sed 's/^[[:space:]]*//' | while IFS= read -r branch; do
    # Skip current branch
    if [ "$branch" = "$(git branch --show-current)" ]; then
        continue
    fi

    MERGED_COUNT=$((MERGED_COUNT + 1))
    echo "  ${C_YELLOW}MERGED${C_RESET}: $branch"

    if [ "$MODE" = "apply" ]; then
        git branch -d "$branch" 2>&1 | sed 's/^/    /'
        echo "    ${C_GREEN}DELETED${C_RESET}"
    fi
done

if [ "$MERGED_COUNT" -eq 0 ]; then
    echo "  No merged aegis-wt/ branches found."
fi

# ────────────────────────────────────────────────────────────────────────────
# 3. Summary
# ────────────────────────────────────────────────────────────────────────────
echo
echo "${C_CYAN}=== Summary ===${C_RESET}"
if [ "$MODE" = "dry-run" ]; then
    echo "Dry-run complete. Re-run with --apply to actually clean up."
else
    echo "Cleanup complete."
fi

# Best-effort log
LOG_DIR="${PROJECT_ROOT}/.aegis/brain/logs"
if [ -d "$LOG_DIR" ]; then
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "unknown")
    echo "[${TIMESTAMP}] [worktree-gc] mode=${MODE} stale=${STALE_COUNT:-0} merged=${MERGED_COUNT:-0}" >> "${LOG_DIR}/worktree-gc.log" 2>/dev/null || true
fi
