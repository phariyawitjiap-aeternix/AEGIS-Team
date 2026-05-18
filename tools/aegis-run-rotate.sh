#!/usr/bin/env bash
# aegis-run-rotate.sh — Compact .aegis/brain/runs/ transcript archive.
#
# Sprint v15-16 Story C.
#
# Behavior:
#   - gzip transcripts (transcript.ndjson, meta.json) older than ROTATE_DAYS
#     (default 7) — keeps them queryable but reclaims most of the disk
#   - delete run directories older than DELETE_DAYS (default 30) — too old to
#     be useful, kept in git history anyway
#   - silent + idempotent: runs in < 100ms when there's nothing to do
#   - safe to call from SessionStart on every startup
#
# Usage:
#   bash tools/aegis-run-rotate.sh              # default thresholds
#   AEGIS_RUN_ROTATE_DAYS=14 bash ...           # gzip after 14 days
#   AEGIS_RUN_DELETE_DAYS=60 bash ...           # delete after 60 days
#   bash tools/aegis-run-rotate.sh --dry-run    # report-only, no changes
#   bash tools/aegis-run-rotate.sh --verbose    # log every action

set -uo pipefail

REPO_ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
RUNS_DIR="$REPO_ROOT/.aegis/brain/runs"
ROTATE_DAYS="${AEGIS_RUN_ROTATE_DAYS:-7}"
DELETE_DAYS="${AEGIS_RUN_DELETE_DAYS:-30}"

DRY_RUN=false
VERBOSE=false
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --verbose) VERBOSE=true ;;
        --help|-h)
            sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
    esac
done

# Fast exit if runs/ doesn't exist — first session before any archive.
[[ -d "$RUNS_DIR" ]] || exit 0

log() { [[ "$VERBOSE" == "true" ]] && echo "[run-rotate] $*" >&2; }

# Counters
gzipped=0
deleted=0

# ── gzip transcripts older than ROTATE_DAYS ────────────────────────────
# Find pattern: .aegis/brain/runs/<date>-<session>/transcript.ndjson (not .gz)
while IFS= read -r -d '' f; do
    if [[ "$DRY_RUN" == "true" ]]; then
        log "would gzip: $f"
    else
        if gzip -q "$f" 2>/dev/null; then
            log "gzipped: $f"
            gzipped=$((gzipped + 1))
        fi
    fi
done < <(find "$RUNS_DIR" -mindepth 2 -maxdepth 2 -type f \
    \( -name 'transcript.ndjson' -o -name 'meta.json' \) \
    -mtime "+${ROTATE_DAYS}" -print0 2>/dev/null)

# ── delete run dirs older than DELETE_DAYS ─────────────────────────────
# Match the YYYY-MM-DD-<session> dir naming so we don't accidentally
# delete unrelated content if someone manually moved files in.
while IFS= read -r -d '' d; do
    base=$(basename "$d")
    [[ "$base" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}- ]] || continue
    if [[ "$DRY_RUN" == "true" ]]; then
        log "would delete: $d"
    else
        # find -delete is safer than rm -rf — only deletes empty dirs after files cleared
        find "$d" -type f -delete 2>/dev/null
        rmdir "$d" 2>/dev/null && {
            log "deleted: $d"
            deleted=$((deleted + 1))
        }
    fi
done < <(find "$RUNS_DIR" -mindepth 1 -maxdepth 1 -type d \
    -mtime "+${DELETE_DAYS}" -print0 2>/dev/null)

# Summary (only when something happened OR --verbose)
if [[ "$gzipped" -gt 0 || "$deleted" -gt 0 || "$VERBOSE" == "true" ]]; then
    log "summary: gzipped=$gzipped deleted=$deleted (rotate=${ROTATE_DAYS}d delete=${DELETE_DAYS}d)"
fi

exit 0
