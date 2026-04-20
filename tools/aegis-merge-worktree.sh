#!/usr/bin/env bash
# AEGIS Worktree Merge Script (Sprint v9-05, S5-04)
#
# Merges a completed agent worktree back into the main branch.
# Handles: branch detection, merge strategy, conflict reporting, cleanup.
#
# Usage:
#   ./tools/aegis-merge-worktree.sh <worktree-branch-or-path> [--task <TASK-ID>] [--dry-run] [--force-cleanup]
#
# Examples:
#   ./tools/aegis-merge-worktree.sh aegis-wt/spider-man-S2-04-20260420T103000
#   ./tools/aegis-merge-worktree.sh aegis-wt/spider-man-S2-04-20260420T103000 --task S2-04 --dry-run
#   ./tools/aegis-merge-worktree.sh aegis-wt/spider-man-S2-04-20260420T103000 --force-cleanup
#
# Prerequisites:
#   - Worktree must exist (created by Claude Code Agent with isolation: "worktree")
#   - Review approval is checked if --task is given (optional, can be skipped)
#   - Clean working tree on main (no uncommitted changes)
#
# Exit codes:
#   0 = merge successful (or dry-run clean)
#   1 = merge failed (conflicts, missing worktree, etc.)
#   2 = usage error
#   3 = conflicts detected (in dry-run mode, informational)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# Use current git repo root (not necessarily the AEGIS-Team repo)
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [[ -z "$REPO_ROOT" ]]; then
    REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
fi
BRAIN_DIR="${REPO_ROOT}/.aegis/brain"
LOG_FILE="${BRAIN_DIR}/logs/activity.log"

# --- Parse arguments ---
WORKTREE_REF=""
TASK_ID=""
DRY_RUN=false
FORCE_CLEANUP=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --task)
            TASK_ID="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --force-cleanup)
            FORCE_CLEANUP=true
            shift
            ;;
        --help|-h)
            echo "Usage: aegis-merge-worktree.sh <worktree-branch-or-path> [--task <TASK-ID>] [--dry-run] [--force-cleanup]"
            echo ""
            echo "Options:"
            echo "  --task <ID>       Check for review approval in .aegis/brain/tasks/<ID>/review.md"
            echo "  --dry-run         Check for conflicts without merging"
            echo "  --force-cleanup   Remove worktree even if merge fails"
            echo ""
            echo "Examples:"
            echo "  ./tools/aegis-merge-worktree.sh aegis-wt/spider-man-S2-04-20260420T103000"
            echo "  ./tools/aegis-merge-worktree.sh aegis-wt/spider-man-S2-04-20260420T103000 --task S2-04 --dry-run"
            exit 0
            ;;
        -*)
            echo "ERROR: Unknown option: $1" >&2
            exit 2
            ;;
        *)
            if [[ -z "$WORKTREE_REF" ]]; then
                WORKTREE_REF="$1"
            else
                echo "ERROR: Unexpected argument: $1" >&2
                exit 2
            fi
            shift
            ;;
    esac
done

if [[ -z "$WORKTREE_REF" ]]; then
    echo "ERROR: Worktree branch or path required." >&2
    echo "Usage: aegis-merge-worktree.sh <worktree-branch-or-path> [--task <TASK-ID>] [--dry-run]" >&2
    exit 2
fi

# --- Utility functions ---
log_info()  { echo "[INFO]  $1"; }
log_warn()  { echo "[WARN]  $1"; }
log_error() { echo "[ERROR] $1" >&2; }
log_activity() {
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "unknown")
    if [[ -d "$(dirname "${LOG_FILE}")" ]]; then
        echo "[${timestamp}] [TOOL:merge-worktree] $1" >> "${LOG_FILE}" 2>/dev/null || true
    fi
}

# --- Step 0: Resolve worktree branch ---
cd "$REPO_ROOT" || { log_error "Cannot cd to repo root: $REPO_ROOT"; exit 1; }

# Determine if the ref is a path or a branch name
WORKTREE_BRANCH="$WORKTREE_REF"
WORKTREE_PATH=""

# Check if it's a worktree path
if git worktree list 2>/dev/null | grep -qF "$WORKTREE_REF"; then
    WORKTREE_PATH=$(git worktree list 2>/dev/null | grep -F "$WORKTREE_REF" | awk '{print $1}')
    WORKTREE_BRANCH=$(git worktree list 2>/dev/null | grep -F "$WORKTREE_REF" | awk '{print $3}' | tr -d '[]')
    log_info "Resolved worktree path: $WORKTREE_PATH -> branch: $WORKTREE_BRANCH"
fi

# Validate branch exists
if ! git rev-parse --verify "$WORKTREE_BRANCH" > /dev/null 2>&1; then
    log_error "Branch '$WORKTREE_BRANCH' does not exist."
    log_error "Available worktrees:"
    git worktree list 2>/dev/null | grep "aegis-wt/" || echo "  (none)"
    exit 1
fi

log_info "Merging worktree branch: $WORKTREE_BRANCH"

# --- Step 1: Check review approval (optional) ---
if [[ -n "$TASK_ID" ]]; then
    REVIEW_FILE="${BRAIN_DIR}/tasks/${TASK_ID}/review.md"
    if [[ -f "$REVIEW_FILE" ]]; then
        if grep -qi "APPROVED\|APPROVE\|LGTM\|PASS" "$REVIEW_FILE" 2>/dev/null; then
            log_info "Review approval found for task $TASK_ID"
        else
            log_warn "Review file exists but no APPROVED/LGTM/PASS found in $REVIEW_FILE"
            log_warn "Proceeding anyway (review check is advisory, not blocking)"
        fi
    else
        log_warn "No review file found at $REVIEW_FILE (task $TASK_ID)"
        log_warn "Proceeding anyway (review check is advisory)"
    fi
fi

# --- Step 2: Check main is clean ---
MAIN_BRANCH="main"
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")

if [[ "$CURRENT_BRANCH" != "$MAIN_BRANCH" ]]; then
    log_info "Currently on branch '$CURRENT_BRANCH', will checkout '$MAIN_BRANCH' for merge"
fi

if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
    log_error "Working tree is dirty. Commit or stash changes before merging."
    git status --short
    exit 1
fi

# --- Step 3: Detect conflicts ---
log_info "Checking for conflicts..."

# Get list of files changed in the worktree branch since it diverged from main
MERGE_BASE=$(git merge-base "$MAIN_BRANCH" "$WORKTREE_BRANCH" 2>/dev/null || echo "")
if [[ -z "$MERGE_BASE" ]]; then
    log_error "Cannot find merge base between '$MAIN_BRANCH' and '$WORKTREE_BRANCH'"
    exit 1
fi

# Files changed in worktree
WT_FILES=$(git diff --name-only "$MERGE_BASE".."$WORKTREE_BRANCH" 2>/dev/null || echo "")
# Files changed in main since divergence
MAIN_FILES=$(git diff --name-only "$MERGE_BASE".."$MAIN_BRANCH" 2>/dev/null || echo "")

# Find overlapping files (potential conflicts)
CONFLICT_FILES=""
if [[ -n "$WT_FILES" ]] && [[ -n "$MAIN_FILES" ]]; then
    CONFLICT_FILES=$(comm -12 <(echo "$WT_FILES" | sort) <(echo "$MAIN_FILES" | sort) 2>/dev/null || echo "")
fi

if [[ -n "$WT_FILES" ]]; then
    WT_FILE_COUNT=$(echo "$WT_FILES" | grep -c "." || true)
else
    WT_FILE_COUNT=0
fi
if [[ -n "$CONFLICT_FILES" ]]; then
    CONFLICT_COUNT=$(echo "$CONFLICT_FILES" | grep -c "." || true)
else
    CONFLICT_COUNT=0
fi

log_info "Worktree changes: $WT_FILE_COUNT files"
if [[ -n "$CONFLICT_FILES" ]]; then
    log_warn "Potential conflicts in $CONFLICT_COUNT files:"
    echo "$CONFLICT_FILES" | while read -r f; do
        [[ -z "$f" ]] && continue
        echo "  - $f"
    done
fi

# --- Step 4: Dry-run reporting ---
if $DRY_RUN; then
    echo ""
    echo "=== DRY RUN REPORT ==="
    echo "Worktree branch: $WORKTREE_BRANCH"
    echo "Merge base: $(echo "$MERGE_BASE" | head -c 8)"
    echo "Files changed: $WT_FILE_COUNT"
    echo "Potential conflicts: $CONFLICT_COUNT"
    if [[ -n "$WT_FILES" ]]; then
        echo ""
        echo "Changed files:"
        echo "$WT_FILES" | while read -r f; do
            [[ -z "$f" ]] && continue
            echo "  + $f"
        done
    fi
    if [[ "$CONFLICT_COUNT" -gt 0 ]]; then
        echo ""
        echo "WARNING: $CONFLICT_COUNT files changed in both main and worktree."
        echo "Manual conflict resolution may be needed."
        log_activity "Dry-run: $WORKTREE_BRANCH has $WT_FILE_COUNT changes, $CONFLICT_COUNT potential conflicts"
        exit 3
    fi
    log_activity "Dry-run: $WORKTREE_BRANCH has $WT_FILE_COUNT changes, no conflicts"
    exit 0
fi

# --- Step 5: Merge ---
log_info "Checking out $MAIN_BRANCH..."
git checkout "$MAIN_BRANCH" 2>/dev/null || {
    log_error "Failed to checkout $MAIN_BRANCH"
    exit 1
}

# Rebase worktree branch onto current HEAD if its base is stale.
# Why: Claude Code's isolation feature snapshots from session-start HEAD, not spawn HEAD.
# Without this, every worktree merge is non-ff and phantom add/add conflicts are likely
# even when the semantic changes don't overlap (see learning 2026-04-20_worktree-isolation-runtime-quirks).
# If the rebase itself fails, we abort it cleanly and fall through to the original merge
# path — that merge will surface the REAL conflict for manual resolution.
MAIN_HEAD=$(git rev-parse "$MAIN_BRANCH")
WORKTREE_BASE_SHA=$(git merge-base "$MAIN_BRANCH" "$WORKTREE_BRANCH")
if [[ "$WORKTREE_BASE_SHA" != "$MAIN_HEAD" ]]; then
    BEHIND_COUNT=$(git rev-list --count "${WORKTREE_BASE_SHA}..${MAIN_HEAD}" 2>/dev/null || echo "?")
    log_info "Worktree base is ${BEHIND_COUNT} commits behind ${MAIN_BRANCH}; rebasing before merge..."
    if git rebase "$MAIN_BRANCH" "$WORKTREE_BRANCH" > /dev/null 2>&1; then
        log_info "Rebase successful; merge will be fast-forward."
    else
        log_warn "Rebase failed (real conflict). Aborting rebase; merge step will surface it."
        git rebase --abort 2>/dev/null || true
        git checkout "$MAIN_BRANCH" 2>/dev/null || true
    fi
fi

# Extract agent name and task from branch for commit message
AGENT_NAME=$(echo "$WORKTREE_BRANCH" | sed 's|aegis-wt/||' | cut -d'-' -f1-2 2>/dev/null || echo "agent")
MERGE_TASK=${TASK_ID:-$(echo "$WORKTREE_BRANCH" | grep -oE '[A-Z][0-9]+-[0-9]+' 2>/dev/null || echo "unknown")}

log_info "Merging $WORKTREE_BRANCH into $MAIN_BRANCH (--no-ff)..."
MERGE_MSG="merge: ${MERGE_TASK} via worktree (${AGENT_NAME})"

if git merge --no-ff "$WORKTREE_BRANCH" -m "$MERGE_MSG" 2>/dev/null; then
    log_info "Merge successful: $MERGE_MSG"
    log_activity "Merged: $WORKTREE_BRANCH into $MAIN_BRANCH ($WT_FILE_COUNT files)"
else
    log_error "Merge failed. Conflicts detected."
    echo ""
    echo "=== CONFLICT REPORT ==="
    git diff --name-only --diff-filter=U 2>/dev/null || echo "(could not list conflicted files)"
    echo ""
    echo "Resolution options:"
    echo "  1. Resolve conflicts manually, then: git add <files> && git commit"
    echo "  2. Abort merge: git merge --abort"
    echo "  3. Spawn Iron Man for automated resolution (Nick Fury handles this)"
    log_activity "CONFLICT: $WORKTREE_BRANCH merge failed, manual resolution needed"

    if $FORCE_CLEANUP; then
        log_warn "Force-cleanup requested. Aborting merge and cleaning up."
        git merge --abort 2>/dev/null || true
    fi
    exit 1
fi

# --- Step 6: Cleanup worktree ---
log_info "Cleaning up worktree..."

if [[ -n "$WORKTREE_PATH" ]] && [[ -d "$WORKTREE_PATH" ]]; then
    # Escalate force levels: plain → -f (dirty worktree) → -f -f (process-held lock).
    # Why -f -f: Claude Code's agent process can retain the git worktree lock past
    # tool-call return; plain --force is rejected with "cannot remove a locked working tree".
    # See learning 2026-04-20_worktree-isolation-runtime-quirks.
    if ! git worktree remove "$WORKTREE_PATH" 2>/dev/null; then
        if ! git worktree remove -f "$WORKTREE_PATH" 2>/dev/null; then
            if git worktree remove -f -f "$WORKTREE_PATH" 2>/dev/null; then
                log_info "Removed worktree (required -f -f for process-held lock)"
            else
                log_warn "Could not remove worktree at $WORKTREE_PATH. Manual cleanup needed: rm -rf $WORKTREE_PATH && git worktree prune"
            fi
        fi
    fi
fi

# Delete the branch (it's merged now)
if git branch -d "$WORKTREE_BRANCH" 2>/dev/null; then
    log_info "Deleted merged branch: $WORKTREE_BRANCH"
else
    log_warn "Could not delete branch $WORKTREE_BRANCH (may already be deleted or not fully merged)"
fi

# --- Done ---
echo ""
echo "=== MERGE COMPLETE ==="
echo "Branch: $WORKTREE_BRANCH -> $MAIN_BRANCH"
echo "Commit: $(git log -1 --oneline 2>/dev/null)"
echo "Files: $WT_FILE_COUNT changed"
log_activity "Complete: $WORKTREE_BRANCH merged and cleaned up ($WT_FILE_COUNT files)"
