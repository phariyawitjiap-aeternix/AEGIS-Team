#!/usr/bin/env bash
# aegis-daemon.sh — Auto-restart Claude Code interactive sessions.
#
# Opens the full Claude Code TUI. When a session ends (context exhaustion,
# /aegis-handoff, or natural completion), waits briefly and starts a new one.
# User sees everything in real-time — same experience as normal Claude Code,
# but it never stops between sessions.
#
# Usage:
#   bash tools/aegis-daemon.sh [--project-dir <path>] [--cooldown <sec>]
#
# The user can type /aegis-start at each session, or CLAUDE.md Golden Rule #5
# will prompt Claude to do it automatically.

set -uo pipefail

COOLDOWN=10
PROJECT_DIR=""
SESSION_COUNT=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --project-dir)  PROJECT_DIR="$2"; shift 2 ;;
        --cooldown)     COOLDOWN="$2";    shift 2 ;;
        -h|--help)
            echo "Usage: aegis-daemon.sh [--project-dir <path>] [--cooldown <sec>]"
            echo "  Opens Claude Code TUI in a loop. Auto-restarts when session ends."
            echo "  Ctrl+C during cooldown to stop the loop."
            exit 0 ;;
        *) echo "Unknown: $1"; exit 1 ;;
    esac
done

if [[ -n "$PROJECT_DIR" ]]; then
    cd "$PROJECT_DIR" || exit 1
fi

PROJECT_NAME="$(basename "$(pwd)")"

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║  AEGIS Daemon — auto-restart Claude Code TUI    ║"
echo "║  Project: $(printf '%-39s' "$PROJECT_NAME")║"
echo "║  Cooldown: ${COOLDOWN}s between sessions               ║"
echo "║  Ctrl+C during cooldown to stop                 ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

while true; do
    SESSION_COUNT=$((SESSION_COUNT + 1))
    echo "═══ Starting session #${SESSION_COUNT} ═══"
    echo ""

    # Full interactive Claude Code — user sees everything
    claude || true

    echo ""
    echo "═══ Session #${SESSION_COUNT} ended ═══"
    echo "═══ Restarting in ${COOLDOWN}s... (Ctrl+C to stop) ═══"
    echo ""
    sleep "$COOLDOWN"
done
