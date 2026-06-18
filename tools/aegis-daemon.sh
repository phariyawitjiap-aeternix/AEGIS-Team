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

# ── Terminal-only guard ────────────────────────────────────────────────────
# This daemon launches the interactive `claude` TUI in a loop. That only works
# in a real terminal: the Claude Desktop GUI (and VS Code chat) ships NO `claude`
# CLI binary and has no interactive stdin, so the loop below would spin failing
# every cooldown. Detect that case up front and exit cleanly with guidance.
# Guard is test-safe: it runs only when this file is EXECUTED (the --help path
# above already exited), never when sourced, and prints to stderr + exit 0 so a
# CI runner without `claude` doesn't register a failure.
if ! command -v claude >/dev/null 2>&1 || [[ ! -t 0 ]]; then
    echo "aegis-daemon.sh is terminal-only: it loops the interactive Claude Code TUI." >&2
    echo "The Claude Desktop GUI / VS Code chat has no \`claude\` CLI and no interactive" >&2
    echo "stdin, so this daemon cannot run there. Inside Desktop, just run /aegis-start —" >&2
    echo "the team takes over for the session without a restart loop." >&2
    exit 0
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
