#!/usr/bin/env bash
# tools/aegis-brain-checkpoint/rollback.sh
# ────────────────────────────────────────────────────────────────────────────
# Inspect + restore brain checkpoints. Adapted from Hermes /rollback command.
#
# Sprint:  v14-02 (S14-02-01)
#
# Usage:
#   bash tools/aegis-brain-checkpoint/rollback.sh list           # show last 20 checkpoints
#   bash tools/aegis-brain-checkpoint/rollback.sh diff <N>        # diff against HEAD
#   bash tools/aegis-brain-checkpoint/rollback.sh restore <N>     # restore brain to checkpoint N
#   bash tools/aegis-brain-checkpoint/rollback.sh restore <N> <file>  # restore single file
#
# N is the 1-based ordinal from `list` output (1 = most recent).
# ────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
# shellcheck source=./store.sh
source "${SCRIPT_DIR}/store.sh"

LIMIT=20

# Resolve N → commit SHA
ckpt_resolve_n() {
    local n="$1"
    if ! [[ "$n" =~ ^[0-9]+$ ]] || [[ "$n" -lt 1 ]]; then
        echo "Error: N must be a positive integer (got '$n')" >&2
        return 2
    fi
    cd "$AEGIS_CKPT_STORE_DIR"
    # Get commit at index N (1-based, most recent first)
    local sha
    sha=$(git rev-list HEAD --max-count="$LIMIT" | sed -n "${n}p")
    if [[ -z "$sha" ]]; then
        echo "Error: checkpoint #$n not found (have $(git rev-list --count HEAD --max-count=$LIMIT) within limit)" >&2
        return 1
    fi
    echo "$sha"
}

action="${1:-list}"

ckpt_init

case "$action" in
    list)
        cd "$AEGIS_CKPT_STORE_DIR"
        total=$(git rev-list --count HEAD)
        echo "Brain checkpoints (showing last ${LIMIT} of ${total} total)"
        echo "─────────────────────────────────────────────────────────────────"
        # Format: N  short-sha  iso-ts  reason
        i=0
        git log --max-count="$LIMIT" --format='%H|%cI|%s' HEAD 2>/dev/null | \
        while IFS='|' read -r sha cts msg; do
            i=$((i+1))
            short=$(printf '%.7s' "$sha")
            # Trim the timestamp prefix from message if present (snapshot.sh adds it)
            clean_msg=$(printf '%s' "$msg" | sed -E 's/^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:.Z]+[[:space:]]+//')
            printf '  %3d  %s  %s  %s\n' "$i" "$short" "$cts" "$clean_msg"
        done
        ;;

    diff)
        n="${2:-}"
        if [[ -z "$n" ]]; then echo "Usage: rollback.sh diff <N>" >&2; exit 2; fi
        sha=$(ckpt_resolve_n "$n")
        cd "$AEGIS_CKPT_STORE_DIR"
        # Sync current brain into store first so diff reflects on-disk state
        TARGET="${AEGIS_CKPT_STORE_DIR}/brain"
        mkdir -p "$TARGET"
        if command -v rsync >/dev/null 2>&1; then
            rsync -a --delete --exclude='.brain-checkpoints' --exclude='.git' \
                "${AEGIS_CKPT_BRAIN_DIR}/" "${TARGET}/" >/dev/null
        fi
        git diff "$sha" -- brain/ | head -200
        ;;

    restore)
        n="${2:-}"
        file="${3:-}"
        if [[ -z "$n" ]]; then echo "Usage: rollback.sh restore <N> [file]" >&2; exit 2; fi
        sha=$(ckpt_resolve_n "$n")
        cd "$AEGIS_CKPT_STORE_DIR"

        # Take a pre-rollback snapshot (so rollback itself is undoable)
        ckpt_lock_release  # avoid recursive lock
        bash "${SCRIPT_DIR}/snapshot.sh" "pre-rollback-of-#${n}" >/dev/null || true

        # Materialize the checkpoint to a temp dir
        TMP_RESTORE=$(mktemp -d)
        git --work-tree="$TMP_RESTORE" checkout "$sha" -- brain/ 2>/dev/null

        if [[ -n "$file" ]]; then
            # Single-file restore
            src="${TMP_RESTORE}/brain/${file}"
            dst="${AEGIS_CKPT_BRAIN_DIR}/${file}"
            if [[ ! -e "$src" ]]; then
                echo "Error: '${file}' not in checkpoint #${n}" >&2
                rm -rf "$TMP_RESTORE"
                exit 1
            fi
            mkdir -p "$(dirname "$dst")"
            cp -f "$src" "$dst"
            echo "restored: .aegis/brain/${file} ← checkpoint #${n} (${sha:0:7})"
        else
            # Full brain restore
            if command -v rsync >/dev/null 2>&1; then
                rsync -a --delete \
                    --exclude='.brain-checkpoints' \
                    "${TMP_RESTORE}/brain/" "${AEGIS_CKPT_BRAIN_DIR}/" >/dev/null
            else
                # Fallback: cp
                rm -rf "${AEGIS_CKPT_BRAIN_DIR:?}/"*
                (cd "${TMP_RESTORE}/brain" && cp -r . "$AEGIS_CKPT_BRAIN_DIR/")
            fi
            echo "restored: full brain ← checkpoint #${n} (${sha:0:7})"
        fi

        rm -rf "$TMP_RESTORE"
        echo "Note: pre-rollback snapshot taken — run 'rollback.sh restore 1' to undo this rollback."
        ;;

    *)
        cat >&2 <<EOF
Usage:
  rollback.sh list                  — show last 20 checkpoints
  rollback.sh diff <N>              — diff checkpoint N against current brain
  rollback.sh restore <N>           — restore full brain from checkpoint N
  rollback.sh restore <N> <file>    — restore single file from checkpoint N

N is the 1-based ordinal from 'list' (1 = most recent).
EOF
        exit 2
        ;;
esac
