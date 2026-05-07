#!/usr/bin/env bash
# aegis-rtk-upstream-check.sh — RTK upstream issue #427 watcher
#
# Queries the RTK repo for issue #427 status, caches result in
# .aegis/brain/metrics/rtk-upstream.json, and logs state changes
# to activity.log.
#
# Non-blocking: if curl fails, gh is missing, or rate-limited,
# writes WARN and exits 0. Never a gate blocker.
#
# Integration: wired into /aegis-verify as optional check.
#
# Usage:
#   tools/aegis-rtk-upstream-check.sh              # check + cache
#   tools/aegis-rtk-upstream-check.sh --status      # print cached status
#   tools/aegis-rtk-upstream-check.sh --force        # force re-check (ignore cache age)
#
# Sprint: sprint-v10-02 / Story B (1pt)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
METRICS_DIR="$REPO_ROOT/.aegis/brain/metrics"
CACHE_FILE="$METRICS_DIR/rtk-upstream.json"
ACTIVITY_LOG="$REPO_ROOT/.aegis/brain/logs/activity.log"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "unknown")

mkdir -p "$METRICS_DIR"

# ── Parse args ──────────────────────────────────────────────────────────────

MODE="check"
FORCE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --status)  MODE="status"; shift ;;
        --force)   FORCE=true; shift ;;
        --help|-h)
            echo "Usage:"
            echo "  aegis-rtk-upstream-check.sh              # check + cache"
            echo "  aegis-rtk-upstream-check.sh --status      # print cached status"
            echo "  aegis-rtk-upstream-check.sh --force        # force re-check"
            exit 0
            ;;
        *) shift ;;
    esac
done

# ── Status mode: just read cache ────────────────────────────────────────────

if [[ "$MODE" == "status" ]]; then
    if [[ -f "$CACHE_FILE" ]]; then
        echo "RTK Upstream Issue #427 — Cached Status:"
        cat "$CACHE_FILE"
    else
        echo "No cached status. Run aegis-rtk-upstream-check.sh to fetch."
    fi
    exit 0
fi

# ── Check mode: query upstream ──────────────────────────────────────────────

# Cache freshness: skip if checked within 7 days (unless --force)
if [[ -f "$CACHE_FILE" ]] && [[ "$FORCE" != "true" ]]; then
    LAST_CHECK=$(python3 -c "
import json, sys
try:
    with open('$CACHE_FILE') as f:
        d = json.load(f)
    print(d.get('last_checked', ''))
except:
    print('')
" 2>/dev/null || echo "")

    if [[ -n "$LAST_CHECK" ]]; then
        # Check if less than 7 days old
        STALE=$(python3 -c "
from datetime import datetime, timedelta, timezone
try:
    last = datetime.fromisoformat('$LAST_CHECK'.replace('Z', '+00:00'))
    now = datetime.now(timezone.utc)
    print('no' if (now - last) < timedelta(days=7) else 'yes')
except:
    print('yes')
" 2>/dev/null || echo "yes")

        if [[ "$STALE" == "no" ]]; then
            echo "Cache fresh (< 7 days). Use --force to re-check."
            cat "$CACHE_FILE"
            exit 0
        fi
    fi
fi

# Attempt to query via gh CLI
if ! command -v gh &>/dev/null; then
    echo "WARN: gh CLI not available. Cannot check upstream."
    echo "[${TIMESTAMP}] [RTK-UPSTREAM] WARN — gh CLI not available, skipping check" >> "$ACTIVITY_LOG" 2>/dev/null || true
    exit 0
fi

echo "Checking RTK upstream issue #427..."

# Query the issue — RTK is hypothetical, so we handle graceful failure
ISSUE_JSON=""
QUERY_OK=false

# Note: rtk-ai/rtk is the hypothetical repo. This will 404 in practice,
# which is the expected behavior — RTK does not exist yet as a real project.
# The tool is designed to gracefully handle this and cache the failure state.
ISSUE_JSON=$(gh api repos/rtk-ai/rtk/issues/427 2>/dev/null) && QUERY_OK=true || QUERY_OK=false

if [[ "$QUERY_OK" == "true" ]] && [[ -n "$ISSUE_JSON" ]]; then
    # Parse issue state
    STATE=$(echo "$ISSUE_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('state','unknown'))" 2>/dev/null || echo "unknown")
    TITLE=$(echo "$ISSUE_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('title','unknown')[:100])" 2>/dev/null || echo "unknown")
    UPDATED=$(echo "$ISSUE_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('updated_at','unknown'))" 2>/dev/null || echo "unknown")
    LABELS=$(echo "$ISSUE_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(','.join(l['name'] for l in d.get('labels',[])))" 2>/dev/null || echo "")

    # Read previous state for change detection
    PREV_STATE=""
    if [[ -f "$CACHE_FILE" ]]; then
        PREV_STATE=$(python3 -c "import json; d=json.load(open('$CACHE_FILE')); print(d.get('state',''))" 2>/dev/null || echo "")
    fi

    # Write cache
    python3 -c "
import json
cache = {
    'issue': 'rtk-ai/rtk#427',
    'state': '$STATE',
    'title': '''$TITLE''',
    'updated_at': '$UPDATED',
    'labels': '$LABELS',
    'last_checked': '$TIMESTAMP',
    'query_status': 'success'
}
with open('$CACHE_FILE', 'w') as f:
    json.dump(cache, f, indent=2)
print(json.dumps(cache, indent=2))
" 2>/dev/null

    # Log state change
    if [[ -n "$PREV_STATE" ]] && [[ "$PREV_STATE" != "$STATE" ]]; then
        echo "[${TIMESTAMP}] [RTK-UPSTREAM] STATE_CHANGE — #427: $PREV_STATE -> $STATE" >> "$ACTIVITY_LOG" 2>/dev/null || true
        echo "STATE CHANGE DETECTED: $PREV_STATE -> $STATE"
    else
        echo "[${TIMESTAMP}] [RTK-UPSTREAM] CHECK — #427: state=$STATE" >> "$ACTIVITY_LOG" 2>/dev/null || true
    fi
else
    # Query failed (expected for hypothetical repo)
    python3 -c "
import json
cache = {
    'issue': 'rtk-ai/rtk#427',
    'state': 'unknown',
    'title': 'RTK repo not accessible (expected — RTK is hypothetical)',
    'updated_at': 'N/A',
    'labels': '',
    'last_checked': '$TIMESTAMP',
    'query_status': 'not_found'
}
with open('$CACHE_FILE', 'w') as f:
    json.dump(cache, f, indent=2)
print(json.dumps(cache, indent=2))
" 2>/dev/null

    echo "WARN: RTK repo not accessible (expected — issue #427 is for a hypothetical upstream)."
    echo "[${TIMESTAMP}] [RTK-UPSTREAM] WARN — repo not accessible (expected), cached not_found state" >> "$ACTIVITY_LOG" 2>/dev/null || true
fi

exit 0
