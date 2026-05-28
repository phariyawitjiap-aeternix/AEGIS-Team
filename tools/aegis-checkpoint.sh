#!/usr/bin/env bash
# aegis-checkpoint.sh — Structured state checkpoint for precise session resume.
#
# Complements the markdown handoff (lossy LLM summary) with a lossless JSON
# snapshot of critical state: current task, sprint position, pending decisions,
# branch, last verdict. Research 2026-05-28 identified this as the gap vs
# LangGraph durable state — handoff alone is a summary, this is exact state.
#
# Hybrid approach: handoff for narrative context, checkpoint for exact resume.
#
# Usage:
#   aegis-checkpoint.sh write [--task <id>] [--note <text>]   Capture current state
#   aegis-checkpoint.sh read                                  Print last checkpoint
#   aegis-checkpoint.sh resume                                Human-readable resume brief
#
# Written by /aegis-handoff (alongside the .md), read by /aegis-start.

set -uo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
info() { printf "${BLUE}[INFO]${NC} %s\n" "$*" >&2; }
warn() { printf "${YELLOW}[WARN]${NC} %s\n" "$*" >&2; }

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
STATE_DIR="$PROJECT_DIR/.aegis/brain/state"
CHECKPOINT="$STATE_DIR/checkpoint.json"

command -v jq &>/dev/null || { printf "${RED}ERROR:${NC} jq required\n" >&2; exit 1; }

cmd="${1:-read}"; shift || true

TASK=""; NOTE=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --task) TASK="$2"; shift 2 ;;
        --note) NOTE="$2"; shift 2 ;;
        *) shift ;;
    esac
done

# ── Gather current state ──────────────────────────────────────────────────────
gather() {
    local branch sprint kanban_counts last_verdict last_commit pending_human

    branch="$(git -C "$PROJECT_DIR" branch --show-current 2>/dev/null || echo unknown)"
    last_commit="$(git -C "$PROJECT_DIR" log -1 --format='%h %s' 2>/dev/null || echo none)"

    # Sprint: read current sprint pointer
    sprint="$(cat "$PROJECT_DIR/.aegis/brain/sprints/current" 2>/dev/null | head -1 || echo none)"
    [[ -z "$sprint" ]] && sprint="none"

    # Kanban counts from current sprint
    local kanban="$PROJECT_DIR/.aegis/brain/sprints/current/kanban.md"
    if [[ -f "$kanban" ]]; then
        local todo wip done_c
        # grep -c prints "0" AND exits 1 on no-match — capture stdout only, trust the number
        todo=$(grep -c "TODO" "$kanban" 2>/dev/null); todo=${todo:-0}
        wip=$(grep -c "IN_PROGRESS" "$kanban" 2>/dev/null); wip=${wip:-0}
        done_c=$(grep -c "DONE" "$kanban" 2>/dev/null); done_c=${done_c:-0}
        kanban_counts="{\"todo\":$todo,\"in_progress\":$wip,\"done\":$done_c}"
    else
        kanban_counts="null"
    fi

    # Last quality-gate verdict (any task)
    local latest_verdict_file
    latest_verdict_file="$(ls -t "$STATE_DIR"/quality-gate-*.json 2>/dev/null | head -1)"
    if [[ -n "$latest_verdict_file" ]]; then
        last_verdict="$(jq -c '{task, verdict}' "$latest_verdict_file" 2>/dev/null || echo null)"
    else
        last_verdict="null"
    fi

    # Pending human-queue count
    local hq="$PROJECT_DIR/.aegis/brain/human-queue.md"
    if [[ -f "$hq" ]]; then
        pending_human=$(grep -c "PENDING" "$hq" 2>/dev/null); pending_human=${pending_human:-0}
    else
        pending_human=0
    fi

    jq -n \
        --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --arg branch "$branch" \
        --arg sprint "$sprint" \
        --arg task "$TASK" \
        --arg note "$NOTE" \
        --arg commit "$last_commit" \
        --argjson kanban "$kanban_counts" \
        --argjson verdict "$last_verdict" \
        --argjson pending_human "$pending_human" \
        '{
            timestamp: $ts,
            branch: $branch,
            sprint: $sprint,
            current_task: $task,
            note: $note,
            last_commit: $commit,
            kanban: $kanban,
            last_quality_verdict: $verdict,
            pending_human_items: $pending_human
        }'
}

case "$cmd" in
    write)
        mkdir -p "$STATE_DIR"
        gather > "$CHECKPOINT"
        info "Checkpoint written: $CHECKPOINT"
        jq -C '.' "$CHECKPOINT" >&2
        ;;
    read)
        if [[ -f "$CHECKPOINT" ]]; then
            cat "$CHECKPOINT"
        else
            echo "null"
            warn "No checkpoint found at $CHECKPOINT"
        fi
        ;;
    resume)
        if [[ ! -f "$CHECKPOINT" ]]; then
            warn "No checkpoint to resume from."
            exit 0
        fi
        printf "${GREEN}── Resume Checkpoint ──${NC}\n"
        jq -r '
            "  Saved:    \(.timestamp)",
            "  Branch:   \(.branch)",
            "  Sprint:   \(.sprint)",
            "  Task:     \(.current_task // "(none)")",
            "  Commit:   \(.last_commit)",
            "  Kanban:   \(if .kanban then "TODO=\(.kanban.todo) WIP=\(.kanban.in_progress) DONE=\(.kanban.done)" else "(no board)" end)",
            "  Verdict:  \(if .last_quality_verdict then "\(.last_quality_verdict.task)=\(.last_quality_verdict.verdict)" else "(none)" end)",
            "  Human-Q:  \(.pending_human_items) pending",
            (if .note != "" then "  Note:     \(.note)" else empty end)
        ' "$CHECKPOINT"
        ;;
    -h|--help)
        echo "Usage: aegis-checkpoint.sh write|read|resume [--task <id>] [--note <text>]"
        ;;
    *)
        warn "Unknown command: $cmd (use write|read|resume)"
        exit 1
        ;;
esac
