#!/usr/bin/env bash
# AEGIS Distill Counter Reset (Sprint v9-06 S6-01 Pattern A)
# Zeroes .aegis/brain/state/distill-state.json so the session-start
# reminder stops firing. Called as the last step of /aegis-distill.
#
# Safe to run anytime; it just writes a fresh state. If the state file
# is missing, one is created.
#
# Exit codes:
#   0 = reset written successfully

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
STATE_DIR="${REPO_ROOT}/.aegis/brain/state"
STATE_FILE="${STATE_DIR}/distill-state.json"
THRESHOLD="${AEGIS_DISTILL_THRESHOLD:-3}"
NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "unknown")

mkdir -p "$STATE_DIR"
TMP="${STATE_FILE}.tmp"
cat > "$TMP" <<EOF
{
  "sessions_since_last_distill": 0,
  "last_distill_at": "${NOW}",
  "threshold": ${THRESHOLD}
}
EOF
mv "$TMP" "$STATE_FILE"

echo "Distill counter reset."
echo "  file:      ${STATE_FILE#${REPO_ROOT}/}"
echo "  threshold: ${THRESHOLD}"
echo "  last_run:  ${NOW}"
