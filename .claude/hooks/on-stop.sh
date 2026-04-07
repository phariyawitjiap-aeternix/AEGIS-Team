#!/usr/bin/env bash
# AEGIS Hook — on-stop.sh
# Fires when Claude is about to stop the session (Stop event)
# Enforces Golden Rule 6: Run /aegis-retro at session end
# Logs session end + reminds human to run retro
#
# Input:  JSON on stdin { "session_id": "...", "stop_hook_active": false, ... }
# Output: stdout message displayed to user (exit 0 = allow stop)

set -euo pipefail

INPUT=$(cat)
STOP_HOOK_ACTIVE=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('stop_hook_active', False))" 2>/dev/null || echo "False")

# Log session end
LOG="_aegis-brain/logs/activity.log"
if [[ -f "$LOG" ]]; then
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "unknown")
    echo "[${TIMESTAMP}] [HOOK:on-stop] SESSION_END — Claude stopping" >> "$LOG" 2>/dev/null || true
fi

# Don't loop (stop_hook_active prevents infinite recursion)
if [[ "$STOP_HOOK_ACTIVE" == "True" ]]; then
    exit 0
fi

# Remind human
echo ""
echo "┌─────────────────────────────────────────────────────┐"
echo "│  🛡️  AEGIS — Session Ending                          │"
echo "│                                                     │"
echo "│  Golden Rule 6: Run /aegis-retro before you leave   │"
echo "│  This saves lessons, updates resonance, and logs    │"
echo "│  a handoff for the next session.                    │"
echo "│                                                     │"
echo "│  > /aegis-retro                                     │"
echo "└─────────────────────────────────────────────────────┘"

exit 0
