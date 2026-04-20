#!/usr/bin/env bash
# Apply session-start hook to settings.json (run BETWEEN sessions, not mid-session)
# This replaces the old aegis-version-check.sh SessionStart entry with session-start.sh
# which chains version-check + brain-sync + MEMORY.md regen + activity log.
#
# Usage: bash tools/apply-session-hook-settings.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SETTINGS="${REPO_ROOT}/.claude/settings.json"

if [[ ! -f "$SETTINGS" ]]; then
    echo "ERROR: $SETTINGS not found" >&2
    exit 1
fi

# Check if already applied
if grep -q 'session-start\.sh' "$SETTINGS" 2>/dev/null; then
    echo "OK: session-start.sh already configured in settings.json"
    exit 0
fi

# Check if the old hook entry exists
if ! grep -q 'aegis-version-check\.sh' "$SETTINGS" 2>/dev/null; then
    echo "WARNING: Expected aegis-version-check.sh entry not found. Manual edit needed." >&2
    exit 1
fi

# Replace the old entry with the new one
sed -i.bak 's|bash .claude/hooks/aegis-version-check.sh|bash .claude/hooks/session-start.sh|' "$SETTINGS"

# Verify
if grep -q 'session-start\.sh' "$SETTINGS"; then
    echo "OK: SessionStart hook updated to session-start.sh"
    rm -f "${SETTINGS}.bak"
else
    echo "ERROR: sed replacement failed. Restoring backup." >&2
    mv "${SETTINGS}.bak" "$SETTINGS"
    exit 1
fi
