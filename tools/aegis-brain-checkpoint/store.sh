#!/usr/bin/env bash
# tools/aegis-brain-checkpoint/store.sh
# ────────────────────────────────────────────────────────────────────────────
# Shadow-git store for brain checkpoints. Adapted from Hermes-Agent
# tools/checkpoint_manager.py (shared shadow git, content-addressable).
#
# Sprint:  v14-02 (S14-02-01)
# Layout:
#   .aegis/.brain-checkpoints/
#   ├── store/         — git repo (working tree = staging copy of .aegis/brain/)
#   ├── manifest.json  — checkpoint metadata (counter, last-snapshot ts)
#   └── lock           — flock advisory lock
#
# Idempotent — safe to call multiple times.
# ────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

BRAIN_DIR="${REPO_ROOT}/.aegis/brain"
CKPT_BASE="${REPO_ROOT}/.aegis/.brain-checkpoints"
STORE_DIR="${CKPT_BASE}/store"
MANIFEST="${CKPT_BASE}/manifest.json"
LOCK_FILE="${CKPT_BASE}/lock"

# Export for snapshot.sh / rollback.sh
export AEGIS_CKPT_BRAIN_DIR="$BRAIN_DIR"
export AEGIS_CKPT_BASE="$CKPT_BASE"
export AEGIS_CKPT_STORE_DIR="$STORE_DIR"
export AEGIS_CKPT_MANIFEST="$MANIFEST"
export AEGIS_CKPT_LOCK_FILE="$LOCK_FILE"

# Init the checkpoint store if it doesn't exist. Safe to call always.
ckpt_init() {
    mkdir -p "$CKPT_BASE" "$STORE_DIR"

    if [[ ! -d "$STORE_DIR/.git" ]]; then
        (
            cd "$STORE_DIR"
            git init -q
            git config user.email "checkpoint@aegis.local"
            git config user.name "AEGIS Checkpoint"
            git config gc.auto 256          # auto-pack every ~256 loose objects
            git config gc.reflogExpire 30d
            git config gc.reflogExpireUnreachable 30d
            # Empty initial commit so HEAD exists
            git commit --allow-empty -q -m "init brain checkpoint store"
        )
    fi

    if [[ ! -f "$MANIFEST" ]]; then
        echo '{"version": 1, "counter": 0, "last_snapshot_at": null}' > "$MANIFEST"
    fi
}

# Acquire flock (returns the fd via stdout for caller to track).
# Falls back gracefully if flock is unavailable.
ckpt_lock_acquire() {
    if command -v flock >/dev/null 2>&1; then
        exec 9>"$LOCK_FILE"
        flock -x 9
    fi
}

ckpt_lock_release() {
    if command -v flock >/dev/null 2>&1; then
        # fd 9 closed automatically by sub-shell exit; explicit just in case
        exec 9>&- 2>/dev/null || true
    fi
}

# Update manifest (atomic via temp + mv)
ckpt_manifest_update() {
    local counter="$1"
    local ts="$2"
    local tmp
    tmp=$(mktemp "${MANIFEST}.tmp.XXXXXX")
    if command -v jq >/dev/null 2>&1; then
        jq --arg ts "$ts" --argjson c "$counter" \
            '.counter = $c | .last_snapshot_at = $ts' "$MANIFEST" > "$tmp"
    else
        # Hand-roll JSON (no jq) — keep field order stable
        printf '{"version": 1, "counter": %s, "last_snapshot_at": "%s"}\n' \
            "$counter" "$ts" > "$tmp"
    fi
    mv "$tmp" "$MANIFEST"
}

# Read counter from manifest
ckpt_counter() {
    if [[ ! -f "$MANIFEST" ]]; then
        echo 0
        return
    fi
    if command -v jq >/dev/null 2>&1; then
        jq -r '.counter // 0' "$MANIFEST"
    else
        # Hand-roll extraction
        grep -oE '"counter":[[:space:]]*[0-9]+' "$MANIFEST" \
            | grep -oE '[0-9]+' || echo 0
    fi
}

# If sourced as a library: stop here. If run as CLI: invoke action.
if [[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]]; then
    action="${1:-init}"
    case "$action" in
        init)
            ckpt_init
            echo "Brain checkpoint store ready at ${CKPT_BASE}"
            ;;
        info)
            ckpt_init
            counter=$(ckpt_counter)
            last_ts=$(grep -oE '"last_snapshot_at":[[:space:]]*"[^"]*"' "$MANIFEST" 2>/dev/null \
                | grep -oE '"[^"]*"$' | tr -d '"' || echo "(never)")
            commits=$(cd "$STORE_DIR" && git rev-list --count HEAD 2>/dev/null || echo 0)
            size=$(du -sh "$CKPT_BASE" 2>/dev/null | cut -f1 || echo "?")
            printf 'Checkpoint store info\n'
            printf '  path:          %s\n' "$CKPT_BASE"
            printf '  counter:       %s\n' "$counter"
            printf '  git commits:   %s\n' "$commits"
            printf '  last snapshot: %s\n' "$last_ts"
            printf '  disk usage:    %s\n' "$size"
            ;;
        *)
            echo "Usage: store.sh [init|info]" >&2
            exit 2
            ;;
    esac
fi
