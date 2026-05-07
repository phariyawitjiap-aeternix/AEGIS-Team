#!/usr/bin/env bash
# aegis-apply-mbp-guard.sh — one-shot between-session applier for MBP guard settings.
#
# Applies the AskUserQuestion PreToolUse matcher to .claude/settings.json.
# Safe, idempotent, makes a backup. Must be run BETWEEN Claude Code sessions
# (mid-session edits to settings.json are blocked by guard-write.sh).
#
# Usage: bash tools/aegis-apply-mbp-guard.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

SETTINGS=".claude/settings.json"
PATCH="tools/settings-mbp-guard.json"
BACKUP=".claude/settings.json.pre-mbp-backup"

if [[ ! -f "$SETTINGS" ]]; then
    echo "❌ $SETTINGS not found" >&2
    exit 1
fi

if [[ ! -f "$PATCH" ]]; then
    echo "❌ $PATCH not found (staging file missing)" >&2
    exit 1
fi

# Check idempotency — already applied?
if grep -q "guard-ask-user" "$SETTINGS"; then
    echo "✓ MBP guard already applied — no changes needed"
    exit 0
fi

# Safety: ensure no running Claude Code session
if pgrep -f "claude-code" &>/dev/null; then
    echo "⚠️  Claude Code appears to be running. Stop it first, then re-run this script."
    echo "    (Mid-session edits to settings.json are blocked by guard-write.sh.)"
    exit 2
fi

# Backup current
cp "$SETTINGS" "$BACKUP"
echo "✓ Backed up current settings → $BACKUP"

# Apply patch
cp "$PATCH" "$SETTINGS"
echo "✓ Applied MBP guard patch → $SETTINGS"

# Verify
if grep -q "guard-ask-user" "$SETTINGS"; then
    echo "✓ Verified: AskUserQuestion matcher wired"
else
    echo "❌ Verification failed — rolling back"
    cp "$BACKUP" "$SETTINGS"
    exit 3
fi

echo ""
echo "🛡️  MBP Layer 2 complete. Restart Claude Code to activate."
echo "    Rollback if needed: cp $BACKUP $SETTINGS"
