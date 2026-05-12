#!/usr/bin/env bash
# tools/aegis-brain-checkpoint/snapshot.sh
# ────────────────────────────────────────────────────────────────────────────
# Take a snapshot of .aegis/brain/ into the shadow-git store.
# Adapted from Hermes tools/checkpoint_manager.py auto-before-destructive flow.
#
# Sprint:  v14-02 (S14-02-01)
#
# Usage:
#   bash tools/aegis-brain-checkpoint/snapshot.sh [reason]
#
# Returns:
#   0 — snapshot taken OR no-op (no changes to commit)
#   1 — error (e.g., rsync failed)
#
# Idempotency: git commit on identical content is a no-op (returns nothing
# new in log). No explicit per-turn marker needed — git's natural dedup
# means repeated snapshots of unchanged content cost ~zero.
# ────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
# shellcheck source=./store.sh
source "${SCRIPT_DIR}/store.sh"

REASON="${1:-manual-snapshot}"

# Ensure store exists
ckpt_init

# Acquire flock so concurrent worktree writes don't collide
ckpt_lock_acquire

trap ckpt_lock_release EXIT

if [[ ! -d "$AEGIS_CKPT_BRAIN_DIR" ]]; then
    echo "snapshot: .aegis/brain/ not found — nothing to snapshot" >&2
    exit 0
fi

# rsync brain → store working tree, excluding the store itself.
# We rsync to "brain/" subdir inside the store so git doesn't see the store dir
# as part of the tree.
TARGET="${AEGIS_CKPT_STORE_DIR}/brain"
mkdir -p "$TARGET"

# Use rsync if available (handles deletes, fast), else fall back to cp+find.
if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete \
        --exclude='.brain-checkpoints' \
        --exclude='.git' \
        "${AEGIS_CKPT_BRAIN_DIR}/" "${TARGET}/" >/dev/null
else
    # Fallback: rm -rf + cp -r (slower, no dedup)
    rm -rf "${TARGET:?}/"*
    (cd "$AEGIS_CKPT_BRAIN_DIR" && cp -r . "$TARGET/" 2>/dev/null || true)
fi

# Stage + commit. git commit returns non-zero if nothing to commit; treat as no-op.
TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
COMMIT_MSG="${TS} ${REASON}"

cd "$AEGIS_CKPT_STORE_DIR"
git add brain/ >/dev/null

# Detect "nothing to commit" cleanly
if git diff --cached --quiet; then
    # No changes — silent success
    exit 0
fi

git commit -q -m "$COMMIT_MSG"

# Update manifest
NEW_COUNTER=$(($(ckpt_counter) + 1))
ckpt_manifest_update "$NEW_COUNTER" "$TS"

# Print compact confirmation (1 line, suitable for hook output)
SHORT=$(git rev-parse --short HEAD)
echo "snapshot: ${SHORT} #${NEW_COUNTER} ${REASON}"
