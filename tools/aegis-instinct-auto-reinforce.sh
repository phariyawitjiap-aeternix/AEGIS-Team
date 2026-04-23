#!/usr/bin/env bash
# aegis-instinct-auto-reinforce.sh (F3-02) — Instinct auto-promotion pipeline.
#
# Reads decision-audit.log for entries where source starts with instinct:
# and source_id is non-empty. For each unique instinct ID cited, runs
# aegis-instinct-promote.sh reinforce --id <id> once per session.
#
# Session dedup via /tmp sentinel files (cleared on reboot).
#
# Usage:
#   tools/aegis-instinct-auto-reinforce.sh
#
# Environment:
#   CLAUDE_SESSION_ID — session identifier (default: "default")
#   AEGIS_INSTINCT_ROOT — override instinct directory
#   AEGIS_ACTIVITY_LOG — override activity log path
#
# Bash 3.2 compatible.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${AEGIS_REPO_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
SESSION_ID="${CLAUDE_SESSION_ID:-default}"
AUDIT_LOG="${REPO_ROOT}/.aegis/brain/logs/decision-audit.log"
ACTIVITY_LOG="${AEGIS_ACTIVITY_LOG:-${REPO_ROOT}/.aegis/brain/logs/activity.log}"
PROMOTE_SCRIPT="${SCRIPT_DIR}/aegis-instinct-promote.sh"
SENTINEL_LIST="/tmp/.aegis-auto-reinforced-${SESSION_ID}.list"

log_activity() {
    local msg="$1"
    local ts
    ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "unknown")
    mkdir -p "$(dirname "$ACTIVITY_LOG")" 2>/dev/null || true
    echo "[${ts}] [instinct-auto-reinforce] ${msg}" >> "$ACTIVITY_LOG" 2>/dev/null || true
}

# Check prerequisites
if [[ ! -f "$AUDIT_LOG" ]]; then
    echo "No decision-audit.log found — nothing to reinforce"
    exit 0
fi

if [[ ! -f "$PROMOTE_SCRIPT" ]]; then
    echo "WARN: aegis-instinct-promote.sh not found at $PROMOTE_SCRIPT" >&2
    exit 0
fi

# Extract unique instinct IDs from decision-audit.log
# Filter: source starts with "instinct:" AND source_id is non-empty
INSTINCT_IDS=$(python3 - "$AUDIT_LOG" <<'PYEOF' 2>/dev/null
import json, sys

log_path = sys.argv[1]
ids = set()
try:
    with open(log_path) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                entry = json.loads(line)
            except (json.JSONDecodeError, ValueError):
                continue
            source = entry.get('source', '')
            source_id = entry.get('source_id', '')
            if source.startswith('instinct:') and source_id:
                ids.add(source_id)
except (IOError, OSError):
    pass
for id_ in sorted(ids):
    print(id_)
PYEOF
)

if [[ -z "$INSTINCT_IDS" ]]; then
    echo "No instinct-sourced decisions found in audit log"
    exit 0
fi

REINFORCED=()
SKIPPED=()

# Process each unique instinct ID
while IFS= read -r instinct_id; do
    [[ -z "$instinct_id" ]] && continue

    # Check session sentinel
    sentinel="/tmp/.aegis-reinforced-${instinct_id}.flag"
    if [[ -f "$sentinel" ]]; then
        SKIPPED+=("$instinct_id")
        continue
    fi

    # Run reinforce
    if bash "$PROMOTE_SCRIPT" reinforce --id "$instinct_id" >/dev/null 2>&1; then
        touch "$sentinel"
        # Also record in session list for test verification
        echo "$instinct_id" >> "$SENTINEL_LIST" 2>/dev/null || true
        REINFORCED+=("$instinct_id")
        log_activity "REINFORCE ${instinct_id} (auto from audit log)"
    else
        # Graceful skip — instinct may not exist yet, or already at max tier
        log_activity "SKIP reinforce ${instinct_id} (not found or error — graceful)"
        echo "WARN: could not reinforce instinct '${instinct_id}' — skipping" >&2
    fi

done <<EOF
$INSTINCT_IDS
EOF

# Summary
REINFORCED_COUNT=${#REINFORCED[@]}
SKIPPED_COUNT=${#SKIPPED[@]}

if [[ $REINFORCED_COUNT -gt 0 ]]; then
    REINFORCED_LIST=$(printf "%s " "${REINFORCED[@]}" | sed 's/ $//')
    echo "Auto-reinforced ${REINFORCED_COUNT} instinct(s): ${REINFORCED_LIST}"
fi
if [[ $SKIPPED_COUNT -gt 0 ]]; then
    echo "Skipped ${SKIPPED_COUNT} (already reinforced this session)"
fi
if [[ $REINFORCED_COUNT -eq 0 && $SKIPPED_COUNT -eq 0 ]]; then
    echo "No instincts reinforced"
fi

exit 0
