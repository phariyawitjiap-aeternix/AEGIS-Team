#!/usr/bin/env bash
# aegis-autopilot.sh — Non-stop autonomous execution wrapper for AEGIS.
#
# Loops Claude Code headless sessions automatically, reading handoff briefs
# between sessions so the AI team works non-stop without human intervention.
# Stops when the project signals completion, the budget is exhausted, or a
# safety cap is hit.
#
# Usage:
#   tools/aegis-autopilot.sh [flags]
#
# Flags:
#   --budget <float>         Max cumulative USD (default 5.00, max 1000)
#   --max-iterations <int>   Max session loops (default 10, max 100)
#   --max-failures <int>     Consecutive failures before abort (default 3)
#   --cooldown <int>         Seconds between sessions (default 10)
#   --permission-mode <str>  default | acceptEdits | auto (default acceptEdits)
#   --allowed-tools <str>    Tool whitelist passed to claude
#   --initial-prompt <str>   Override first-session prompt
#   --project-dir <path>     Target project directory (default: pwd)
#   --max-turns <int>        Max turns per claude session (default 200)
#   --session-timeout <int>  Max seconds per session (default 1800)
#   --stall-threshold <int>  Consecutive zero-delta sessions before STALL (default 2)
#   --dry-run                Print config + first prompt, do not execute
#   --verbose                Stream session output to stdout
#   -h, --help               Show this usage
#
# Exit codes:
#   0   Project complete
#   1   Too many consecutive failures
#   2   Budget exhausted
#   3   Max iterations reached
#   4   Stall detected
#   5   Session timeout
#   130 SIGINT (Ctrl+C)

set -euo pipefail

# ── ANSI colors ──────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ── Helpers ──────────────────────────────────────────────────────────────────
err()     { printf "${RED}ERROR:${NC} %s\n" "$*" >&2; }
warn()    { printf "${YELLOW}WARN:${NC}  %s\n" "$*"; }
info()    { printf "${GREEN}INFO:${NC}  %s\n" "$*"; }
section() { printf "${BLUE}── %s${NC}\n" "$*"; }

die() {
    err "$*"
    exit 1
}

# ── Defaults ─────────────────────────────────────────────────────────────────
BUDGET=""
NO_BUDGET=true
MAX_ITERATIONS=10
MAX_FAILURES=3
COOLDOWN=3
PERMISSION_MODE="auto"
ALLOWED_TOOLS=""
INITIAL_PROMPT=""
PROJECT_DIR=""
MAX_TURNS=200
SESSION_TIMEOUT=1800
STALL_THRESHOLD=2
DRY_RUN=false
VERBOSE=false

SCRIPT_VERSION="1.0.0"

# ── Parse arguments ───────────────────────────────────────────────────────────
usage() {
    cat <<EOF
${BOLD}AEGIS Autopilot v${SCRIPT_VERSION}${NC}

Non-stop autonomous Claude Code execution loop.

${BOLD}USAGE${NC}
  tools/aegis-autopilot.sh [flags]

${BOLD}FLAGS${NC}
  --budget <float>         Max cumulative USD spend (max: 1000). Enables budget gate.
  --no-budget              Disable budget gate (default — for subscription plans)
  --max-iterations <int>   Max session loops (default: 10, max: 100)
  --max-failures <int>     Consecutive failures before abort (default: 3)
  --cooldown <int>         Seconds between sessions 0-300 (default: 3)
  --permission-mode <str>  default | acceptEdits | auto (default: auto)
  --allowed-tools <str>    Tool whitelist passed to claude --allowedTools
  --initial-prompt <str>   Override first-session prompt
  --project-dir <path>     Target project directory (default: current dir)
  --max-turns <int>        Max turns per claude session (default: 200)
  --session-timeout <int>  Max seconds per session (default: 1800 = 30min)
  --stall-threshold <int>  Consecutive zero-delta sessions before STALL (default: 2)
  --dry-run                Print config + first prompt only, do not execute
  --verbose                Stream session output to stdout
  -h, --help               Show this help

${BOLD}EXIT CODES${NC}
  0   Project complete
  1   Too many consecutive failures
  2   Budget exhausted
  3   Max iterations reached
  4   Stall detected (no git changes across N sessions)
  5   Session timeout
  130 SIGINT (Ctrl+C)

${BOLD}EXAMPLES${NC}
  # Run overnight with a \$20 budget
  tools/aegis-autopilot.sh --budget 20 --max-iterations 30

  # Dry-run to inspect config and first prompt
  tools/aegis-autopilot.sh --budget 10 --dry-run

  # Verbose with custom first-session prompt
  tools/aegis-autopilot.sh --initial-prompt "Run /aegis-sprint standup first." --verbose
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --budget)           BUDGET="$2"; NO_BUDGET=false; shift 2 ;;
        --no-budget)        NO_BUDGET=true;                shift ;;
        --max-iterations)   MAX_ITERATIONS="$2";   shift 2 ;;
        --max-failures)     MAX_FAILURES="$2";     shift 2 ;;
        --cooldown)         COOLDOWN="$2";         shift 2 ;;
        --permission-mode)  PERMISSION_MODE="$2";  shift 2 ;;
        --allowed-tools)    ALLOWED_TOOLS="$2";    shift 2 ;;
        --initial-prompt)   INITIAL_PROMPT="$2";   shift 2 ;;
        --project-dir)      PROJECT_DIR="$2";      shift 2 ;;
        --max-turns)        MAX_TURNS="$2";        shift 2 ;;
        --session-timeout)  SESSION_TIMEOUT="$2";  shift 2 ;;
        --stall-threshold)  STALL_THRESHOLD="$2";  shift 2 ;;
        --dry-run)          DRY_RUN=true;          shift ;;
        --verbose)          VERBOSE=true;          shift ;;
        -h|--help)          usage ;;
        *) die "Unknown argument: $1. Use --help for usage." ;;
    esac
done

# ── Resolve project dir ───────────────────────────────────────────────────────
if [[ -z "$PROJECT_DIR" ]]; then
    PROJECT_DIR="$(pwd)"
fi
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

# ── Validate dependencies ─────────────────────────────────────────────────────
if ! command -v jq &>/dev/null; then
    err "jq is required but not found. Install: brew install jq  (macOS) or  apt-get install jq  (Linux)"
    exit 1
fi

if ! command -v claude &>/dev/null; then
    err "claude CLI not found. Install: https://claude.ai/download"
    exit 1
fi

# Resolve timeout command: prefer GNU timeout, fall back to gtimeout (macOS
# coreutils brew install), and finally to a pure-bash wrapper so the script
# is usable on a fresh macOS without forcing an install step.
TIMEOUT_CMD=""
if command -v timeout &>/dev/null; then
    TIMEOUT_CMD="timeout"
elif command -v gtimeout &>/dev/null; then
    TIMEOUT_CMD="gtimeout"
else
    warn "timeout/gtimeout not found. Session timeout will be implemented via background kill."
    warn "For proper timeout support: brew install coreutils  (macOS) or apt-get install coreutils  (Linux)"
    TIMEOUT_CMD="__bash_timeout"
fi

# Pure-bash timeout wrapper: spawns a killer in background, runs command
# in foreground so stdout/stderr redirections work normally.
__bash_timeout() {
    local secs="$1"
    shift
    # Launch killer that targets our own PID's child (the command below).
    # We write the child PID to a temp file so the killer can read it.
    local pidfile
    pidfile="$(mktemp)"
    (
        sleep "$secs"
        local cpid
        cpid="$(cat "$pidfile" 2>/dev/null)" || true
        if [[ -n "$cpid" ]]; then
            kill "$cpid" 2>/dev/null || true
        fi
    ) &
    local killer_pid=$!
    # Run command in background so we can capture its PID, then wait
    "$@" &
    local child_pid=$!
    echo "$child_pid" > "$pidfile"
    wait "$child_pid" 2>/dev/null
    local rc=$?
    kill "$killer_pid" 2>/dev/null || true
    wait "$killer_pid" 2>/dev/null || true
    rm -f "$pidfile"
    # 143 = killed by SIGTERM (from our killer) → map to 124 like GNU timeout
    if (( rc == 143 )); then
        return 124
    fi
    return $rc
}

# ── Validate arguments ────────────────────────────────────────────────────────

# Budget: > 0 and <= 1000 (skipped when --no-budget / no --budget given)
if [[ "$NO_BUDGET" == "false" ]]; then
    if ! jq -e --arg v "$BUDGET" 'def num: tonumber? // null; ($v | num) != null and ($v | num) > 0 and ($v | num) <= 1000' &>/dev/null <<<"null"; then
        die "Invalid --budget: must be a number > 0 and <= 1000 (got: $BUDGET)"
    fi
    BUDGET_OK=$(jq -n --arg v "$BUDGET" '($v|tonumber) > 0 and ($v|tonumber) <= 1000')
    [[ "$BUDGET_OK" == "true" ]] || die "--budget must be > 0 and <= 1000 (got: $BUDGET)"
fi

# max-iterations: integer 1-100
[[ "$MAX_ITERATIONS" =~ ^[0-9]+$ ]] || die "--max-iterations must be a positive integer (got: $MAX_ITERATIONS)"
(( MAX_ITERATIONS > 0 && MAX_ITERATIONS <= 100 )) || die "--max-iterations must be between 1 and 100 (got: $MAX_ITERATIONS)"

# max-failures
[[ "$MAX_FAILURES" =~ ^[0-9]+$ ]] || die "--max-failures must be a positive integer (got: $MAX_FAILURES)"
(( MAX_FAILURES > 0 )) || die "--max-failures must be >= 1 (got: $MAX_FAILURES)"

# cooldown: 0-300
[[ "$COOLDOWN" =~ ^[0-9]+$ ]] || die "--cooldown must be a non-negative integer (got: $COOLDOWN)"
(( COOLDOWN >= 0 && COOLDOWN <= 300 )) || die "--cooldown must be between 0 and 300 (got: $COOLDOWN)"

# permission-mode: only default, acceptEdits, auto allowed
case "$PERMISSION_MODE" in
    default|acceptEdits|auto) ;;
    bypassPermissions)
        die "--permission-mode bypassPermissions is blocked in v1 (safety policy). Use acceptEdits or auto."
        ;;
    *)
        die "--permission-mode must be one of: default, acceptEdits, auto (got: $PERMISSION_MODE)"
        ;;
esac

# max-turns
[[ "$MAX_TURNS" =~ ^[0-9]+$ ]] || die "--max-turns must be a positive integer (got: $MAX_TURNS)"
(( MAX_TURNS > 0 )) || die "--max-turns must be > 0 (got: $MAX_TURNS)"

# session-timeout
[[ "$SESSION_TIMEOUT" =~ ^[0-9]+$ ]] || die "--session-timeout must be a positive integer (got: $SESSION_TIMEOUT)"
(( SESSION_TIMEOUT > 0 )) || die "--session-timeout must be > 0 (got: $SESSION_TIMEOUT)"

# stall-threshold
[[ "$STALL_THRESHOLD" =~ ^[0-9]+$ ]] || die "--stall-threshold must be a positive integer (got: $STALL_THRESHOLD)"
(( STALL_THRESHOLD > 0 )) || die "--stall-threshold must be > 0 (got: $STALL_THRESHOLD)"

# project-dir must contain CLAUDE.md
[[ -d "$PROJECT_DIR" ]] || die "--project-dir does not exist: $PROJECT_DIR"
[[ -f "$PROJECT_DIR/CLAUDE.md" ]] || die "No CLAUDE.md found in $PROJECT_DIR. Is this an AEGIS project?"

# ── Runtime state ─────────────────────────────────────────────────────────────
RUN_TIMESTAMP="$(date '+%Y%m%d-%H%M%S')"
LOG_DIR="$PROJECT_DIR/.aegis/brain/logs"
LOG_FILE="$LOG_DIR/autopilot-${RUN_TIMESTAMP}.log"
JSONL_FILE="$LOG_DIR/autopilot-sessions.jsonl"
COMPLETE_FILE="$PROJECT_DIR/.aegis/brain/state/project-complete.json"
HANDOFFS_DIR="$PROJECT_DIR/.aegis/brain/handoffs"

CUMULATIVE_COST="0"
ITERATION=0
CONSECUTIVE_FAILURES=0
CONSECUTIVE_ZERO_DELTA=0
CLAUDE_PID=""
INTERRUPTED=false
TOTAL_TURNS=0
AUTOPILOT_START_EPOCH="$(date '+%s')"

mkdir -p "$LOG_DIR"

# ── Logging helpers ───────────────────────────────────────────────────────────
log() {
    local msg="$*"
    local ts
    ts="$(date '+%Y-%m-%d %H:%M:%S')"
    printf '[%s] %s\n' "$ts" "$msg" | tee -a "$LOG_FILE"
}

log_session_jsonl() {
    local iter="$1" session_id="$2" cost="$3" cumulative="$4"
    local turns="$5" terminal_reason="$6" duration_s="$7" exit_reason="$8"
    local ts
    ts="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    jq -c -n \
        --argjson iteration    "$iter" \
        --arg     session_id   "$session_id" \
        --arg     cost         "$cost" \
        --arg     cumulative   "$cumulative" \
        --argjson turns        "$turns" \
        --arg     terminal_reason "$terminal_reason" \
        --argjson duration_s   "$duration_s" \
        --arg     exit_reason  "$exit_reason" \
        --arg     timestamp    "$ts" \
        '{iteration: $iteration, session_id: $session_id,
          cost: ($cost|tonumber), cumulative_cost: ($cumulative|tonumber),
          turns: $turns, terminal_reason: $terminal_reason,
          duration_s: $duration_s, exit_reason: $exit_reason,
          timestamp: $timestamp}' \
        >> "$JSONL_FILE"
}

# ── SIGINT handler ────────────────────────────────────────────────────────────
handle_sigint() {
    INTERRUPTED=true
    # Forward signal to the running claude process if we have its PID
    if [[ -n "$CLAUDE_PID" ]]; then
        kill -INT "$CLAUDE_PID" 2>/dev/null || true
    fi
    # Do NOT exit here — let the main loop detect INTERRUPTED after
    # the JSON parse + log block completes (deferred exit).
}
trap handle_sigint SIGINT SIGTERM

# ── Handoff reader ────────────────────────────────────────────────────────────
# Returns path to newest handoff file, or "" if none.
find_latest_handoff() {
    if [[ ! -d "$HANDOFFS_DIR" ]]; then
        echo ""
        return
    fi
    # Date-prefixed filenames: newest = last alphabetically (YYYY-MM-DD-...)
    local newest
    newest="$(ls -1 "$HANDOFFS_DIR"/*.md 2>/dev/null | sort | tail -1)"
    echo "${newest:-}"
}

# Read handoff file, capping at 50KB (keep tail to preserve most-recent state).
read_handoff() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo ""
        return
    fi
    local size
    size="$(wc -c < "$file")"
    local max_bytes=51200  # 50KB
    if (( size > max_bytes )); then
        warn "Handoff file is large ($size bytes > 50KB). Truncating to last 50KB."
        # Keep head (frontmatter ~2KB) + tail (most-recent content)
        local head_bytes=2048
        local tail_bytes=$(( max_bytes - head_bytes ))
        {
            head -c $head_bytes "$file"
            printf '\n\n[... middle truncated for context budget ...]\n\n'
            tail -c $tail_bytes "$file"
        }
    else
        cat "$file"
    fi
}

# Poll for a handoff file newer than a given epoch timestamp. Waits up to 5s.
poll_for_new_handoff() {
    local since_epoch="$1"
    local deadline=$(( $(date '+%s') + 5 ))
    while (( $(date '+%s') < deadline )); do
        if [[ -d "$HANDOFFS_DIR" ]]; then
            local newest
            newest="$(ls -1 "$HANDOFFS_DIR"/*.md 2>/dev/null | sort | tail -1)"
            if [[ -n "$newest" ]]; then
                local file_mtime
                # macOS stat vs GNU stat
                if stat --version &>/dev/null 2>&1; then
                    file_mtime="$(stat -c '%Y' "$newest" 2>/dev/null || echo 0)"
                else
                    file_mtime="$(stat -f '%m' "$newest" 2>/dev/null || echo 0)"
                fi
                if (( file_mtime > since_epoch )); then
                    echo "$newest"
                    return
                fi
            fi
        fi
        sleep 1
    done
    echo ""
}

# ── Prompt builder ────────────────────────────────────────────────────────────
build_prompt() {
    local iter="$1"
    local handoff_content="$2"

    # Session 1 with --initial-prompt override
    if (( iter == 1 )) && [[ -n "$INITIAL_PROMPT" ]]; then
        printf '%s\n' "$INITIAL_PROMPT"
        return
    fi

    # Shared non-stop rules — the #1 thing that breaks autonomy is the agent
    # stopping to "report" remaining work instead of doing it.
    local RULES='NON-STOP RULES (critical):
- Your FIRST action MUST be: invoke the Skill tool with skill="aegis-start". This loads Nick Fury who scans state and drives all work.
- After EACH unit of work completes, Nick Fury IMMEDIATELY re-scans and dispatches the next task. Do NOT pause between tasks. Do NOT wait.
- NEVER end your turn saying "there are remaining items" / "next steps:" / "you could..." and then stop. If there are remaining items, DO THEM. Listing remaining work instead of doing it is a failure.
- NEVER ask "should I continue?" / "ทำต่อมั้ย?" / "want me to...?". The answer is always YES — just continue.
- Do NOT present options or menus to the human. Decide via the Decision Matrix and execute.
- The ONLY reasons to stop a turn: (a) context is genuinely full -> invoke skill="aegis-handoff" then stop, (b) a hard blocker that ONLY the human can clear (credentials, external access, irreversible approval) -> write it to .aegis/brain/human-queue.md and CONTINUE with everything else, (c) the project is fully complete -> create .aegis/brain/state/project-complete.json with {"complete": true, "reason": "..."}.
- Keep working until one of those three is genuinely true. Burn the whole turn doing real work.'

    if [[ -z "$handoff_content" ]]; then
        printf '%s\n\nThis is a fresh session. Begin now.\n' "$RULES"
    else
        printf '%s\n\nYou are resuming from a previous session. Handoff below — /aegis-start will read it and continue from where the last session left off.\n\n---\n%s\n---\n\nBegin now.\n' "$RULES" "$handoff_content"
    fi
}

# ── Stall detection: git diff snapshot ───────────────────────────────────────
get_git_diff_stat() {
    # Returns the raw output of git diff --stat HEAD (empty = no changes)
    git -C "$PROJECT_DIR" diff --stat HEAD 2>/dev/null || echo ""
}

# ── Float arithmetic via jq ───────────────────────────────────────────────────
float_add() {
    jq -n --arg a "$1" --arg b "$2" '($a|tonumber) + ($b|tonumber) | . * 100 | round | . / 100'
}

float_ge() {
    # returns "true" if a >= b
    jq -n --arg a "$1" --arg b "$2" '($a|tonumber) >= ($b|tonumber)'
}

float_percent() {
    jq -n --arg a "$1" --arg b "$2" '(($a|tonumber) / ($b|tonumber) * 1000 | round) / 10'
}

format_duration() {
    local secs="$1"
    local m=$(( secs / 60 ))
    local s=$(( secs % 60 ))
    if (( m > 0 )); then
        printf '%dm %ds' "$m" "$s"
    else
        printf '%ds' "$s"
    fi
}

# ── Banner ────────────────────────────────────────────────────────────────────
print_banner() {
    local budget_fmt="$1"
    printf '\n'
    printf "${BOLD}${BLUE}╔══════════════════════════════════════════════════════╗${NC}\n"
    printf "${BOLD}${BLUE}║  AEGIS Autopilot v%-34s║${NC}\n" "${SCRIPT_VERSION}                   "
    if [[ "$NO_BUDGET" == "true" ]]; then
        printf "${BOLD}${BLUE}║  Budget: %-11s | Max iterations: %-13s║${NC}\n" "unlimited" "$MAX_ITERATIONS      "
    else
        printf "${BOLD}${BLUE}║  Budget: \$%-10s | Max iterations: %-13s║${NC}\n" "$budget_fmt" "$MAX_ITERATIONS      "
    fi
    printf "${BOLD}${BLUE}║  Project: %-43s║${NC}\n" "$(basename "$PROJECT_DIR")                            "
    printf "${BOLD}${BLUE}║  Permission: %-40s║${NC}\n" "$PERMISSION_MODE                               "
    printf "${BOLD}${BLUE}║  Press Ctrl+C to interrupt                           ║${NC}\n"
    printf "${BOLD}${BLUE}╚══════════════════════════════════════════════════════╝${NC}\n"
    printf '\n'
}

# ── Summary ───────────────────────────────────────────────────────────────────
print_summary() {
    local reason="$1" exit_code="$2"
    local total_secs=$(( $(date '+%s') - AUTOPILOT_START_EPOCH ))
    local total_dur
    total_dur="$(format_duration "$total_secs")"

    printf '\n'
    printf "${BOLD}${CYAN}══ Autopilot Complete ═══════════════════════════════════${NC}\n"
    printf "   Reason:   %s\n" "$reason"
    printf "   Sessions: %d | Total cost: \$%s | Total time: %s\n" \
        "$ITERATION" "$CUMULATIVE_COST" "$total_dur"
    printf "   Log:      %s\n" "$LOG_FILE"
    printf "${BOLD}${CYAN}═════════════════════════════════════════════════════════${NC}\n"
    printf '\n'

    log "AUTOPILOT COMPLETE — reason=$reason exit=$exit_code sessions=$ITERATION cost=\$$CUMULATIVE_COST duration=${total_secs}s"
}

# ── Project-complete check ────────────────────────────────────────────────────
check_project_complete() {
    [[ -f "$COMPLETE_FILE" ]] || return 1
    local complete_val
    complete_val="$(jq -r '.complete // false' "$COMPLETE_FILE" 2>/dev/null)" || return 1
    [[ "$complete_val" == "true" ]]
}

get_complete_reason() {
    jq -r '.reason // "no reason given"' "$COMPLETE_FILE" 2>/dev/null || echo "no reason given"
}

# ── DRY RUN ───────────────────────────────────────────────────────────────────
if [[ "$DRY_RUN" == "true" ]]; then
    print_banner "$BUDGET"

    printf "${BOLD}Config (dry-run):${NC}\n"
    printf "  project-dir:      %s\n" "$PROJECT_DIR"
    printf "  budget:           \$%s\n" "$BUDGET"
    printf "  max-iterations:   %d\n" "$MAX_ITERATIONS"
    printf "  max-failures:     %d\n" "$MAX_FAILURES"
    printf "  cooldown:         %ds\n" "$COOLDOWN"
    printf "  permission-mode:  %s\n" "$PERMISSION_MODE"
    printf "  max-turns:        %d\n" "$MAX_TURNS"
    printf "  session-timeout:  %ds\n" "$SESSION_TIMEOUT"
    printf "  stall-threshold:  %d\n" "$STALL_THRESHOLD"
    [[ -n "$ALLOWED_TOOLS" ]] && printf "  allowed-tools:    %s\n" "$ALLOWED_TOOLS"
    [[ -n "$INITIAL_PROMPT" ]] && printf "  initial-prompt:   %s\n" "$INITIAL_PROMPT"
    printf '\n'

    # Build and show first prompt
    local_handoff_file="$(find_latest_handoff)"
    local_handoff_content=""
    if [[ -n "$local_handoff_file" ]]; then
        local_handoff_content="$(read_handoff "$local_handoff_file")"
        printf "${BOLD}First-session handoff:${NC} %s\n\n" "$(basename "$local_handoff_file")"
    fi

    first_prompt="$(build_prompt 1 "$local_handoff_content")"
    printf "${BOLD}First-session prompt:${NC}\n"
    printf '%s\n' "---"
    printf '%s\n' "$first_prompt"
    printf '%s\n' "---"
    printf '\n'

    printf "${GREEN}Dry-run complete. No sessions executed.${NC}\n"
    exit 0
fi

# ── Start log ─────────────────────────────────────────────────────────────────
log "AUTOPILOT START — budget=\$$BUDGET max-iterations=$MAX_ITERATIONS max-failures=$MAX_FAILURES cooldown=${COOLDOWN}s permission=$PERMISSION_MODE timeout=${SESSION_TIMEOUT}s stall-threshold=$STALL_THRESHOLD"
print_banner "$BUDGET"

# ── Main loop ─────────────────────────────────────────────────────────────────
PREV_DIFF_STAT=""
FINAL_EXIT_CODE=0
FINAL_REASON="unknown"

while true; do
    # Deferred SIGINT check (between sessions)
    if [[ "$INTERRUPTED" == "true" ]]; then
        FINAL_REASON="Interrupted by user"
        FINAL_EXIT_CODE=130
        break
    fi

    ITERATION=$(( ITERATION + 1 ))
    SESSION_START_EPOCH="$(date '+%s')"
    SESSION_START_TIME="$(date '+%H:%M:%S')"

    printf "${BOLD}── Session %d/%d ─────────────────────────────────────────${NC}\n" \
        "$ITERATION" "$MAX_ITERATIONS"

    # ── Find handoff ──────────────────────────────────────────────────────────
    handoff_file=""
    handoff_content=""
    if (( ITERATION == 1 )) && [[ -n "$INITIAL_PROMPT" ]]; then
        printf "   Prompt: [custom initial-prompt]\n"
    else
        handoff_file="$(find_latest_handoff)"
        if [[ -n "$handoff_file" ]]; then
            handoff_content="$(read_handoff "$handoff_file")"
            printf "   Prompt: Resuming from handoff %s\n" "$(basename "$handoff_file")"
        else
            printf "   Prompt: [initial — no handoff found]\n"
        fi
    fi

    # ── Build prompt ──────────────────────────────────────────────────────────
    SESSION_PROMPT="$(build_prompt "$ITERATION" "$handoff_content")"

    # ── Capture git diff before session ───────────────────────────────────────
    BEFORE_DIFF="$(get_git_diff_stat)"

    # ── Build claude command ───────────────────────────────────────────────────
    CLAUDE_ARGS=(
        -p "$SESSION_PROMPT"
        --output-format json
        --permission-mode "$PERMISSION_MODE"
        --max-turns "$MAX_TURNS"
    )
    [[ -n "$ALLOWED_TOOLS" ]] && CLAUDE_ARGS+=(--allowedTools "$ALLOWED_TOOLS")

    printf "   Started: %s\n" "$SESSION_START_TIME"
    log "SESSION $ITERATION START — handoff=${handoff_file:-none}"

    # ── Execute session ───────────────────────────────────────────────────────
    SESSION_JSON=""
    SESSION_EXIT=0

    TMPOUT="$(mktemp)"
    if [[ "$VERBOSE" == "true" ]]; then
        $TIMEOUT_CMD "$SESSION_TIMEOUT" claude "${CLAUDE_ARGS[@]}" 2>>"$LOG_FILE" | tee "$TMPOUT" || true
        SESSION_EXIT=${PIPESTATUS[0]}
    else
        $TIMEOUT_CMD "$SESSION_TIMEOUT" claude "${CLAUDE_ARGS[@]}" >"$TMPOUT" 2>>"$LOG_FILE" || SESSION_EXIT=$?
    fi
    SESSION_JSON="$(cat "$TMPOUT" 2>/dev/null || true)"
    rm -f "$TMPOUT"

    CLAUDE_PID=""
    SESSION_END_EPOCH="$(date '+%s')"
    SESSION_DURATION=$(( SESSION_END_EPOCH - SESSION_START_EPOCH ))

    # ── Deferred SIGINT: finish parse+log before exiting ─────────────────────
    # (INTERRUPTED may be true now — we still parse and log before breaking)

    # ── Handle timeout ────────────────────────────────────────────────────────
    TIMED_OUT=false
    if (( SESSION_EXIT == 124 )); then
        TIMED_OUT=true
        warn "Session $ITERATION timed out after ${SESSION_TIMEOUT}s"
        log "SESSION $ITERATION TIMEOUT after ${SESSION_TIMEOUT}s"
    fi

    # ── Parse JSON output ─────────────────────────────────────────────────────
    SESSION_COST="0"
    SESSION_ID="unknown"
    TERMINAL_REASON="unknown"
    NUM_TURNS=0
    PARSE_OK=false

    if [[ -n "$SESSION_JSON" ]]; then
        # Extract the last complete JSON object (claude may emit progress lines)
        LAST_JSON="$(printf '%s' "$SESSION_JSON" | grep -E '^\{.*"total_cost_usd"' | tail -1 2>/dev/null || true)"
        if [[ -z "$LAST_JSON" ]]; then
            # Try the full output as JSON directly
            LAST_JSON="$SESSION_JSON"
        fi

        if jq -e . <<<"$LAST_JSON" &>/dev/null 2>&1; then
            SESSION_COST="$(jq -r '.total_cost_usd // 0' <<<"$LAST_JSON")"
            SESSION_ID="$(jq -r '.session_id // "unknown"' <<<"$LAST_JSON")"
            TERMINAL_REASON="$(jq -r '.terminal_reason // "unknown"' <<<"$LAST_JSON")"
            NUM_TURNS="$(jq -r '.num_turns // 0' <<<"$LAST_JSON")"
            PARSE_OK=true
        fi
    fi

    if [[ "$PARSE_OK" == "false" ]]; then
        warn "Session $ITERATION: could not parse JSON output. Assuming \$5.00 cost (fail-safe)."
        SESSION_COST="5.00"
        TERMINAL_REASON="parse_failed"
        log "SESSION $ITERATION JSON PARSE FAILED — raw output length: ${#SESSION_JSON}"
    fi

    # ── Accumulate cost (jq float arithmetic) ────────────────────────────────
    CUMULATIVE_COST="$(float_add "$CUMULATIVE_COST" "$SESSION_COST")"
    TOTAL_TURNS=$(( TOTAL_TURNS + NUM_TURNS ))

    if [[ "$NO_BUDGET" == "false" ]]; then
        BUDGET_PCT="$(float_percent "$CUMULATIVE_COST" "$BUDGET")"
    else
        BUDGET_PCT="0"
    fi
    SESSION_DUR_FMT="$(format_duration "$SESSION_DURATION")"
    SESSION_END_TIME="$(date '+%H:%M:%S')"

    printf "   Finished: %s (%s)\n" "$SESSION_END_TIME" "$SESSION_DUR_FMT"
    printf "   Cost: \$%s | Turns: %d | Reason: %s\n" \
        "$SESSION_COST" "$NUM_TURNS" "$TERMINAL_REASON"
    if [[ "$NO_BUDGET" == "true" ]]; then
        printf "   Cumulative: \$%s (no budget limit)\n" "$CUMULATIVE_COST"
    else
        printf "   Cumulative: \$%s / \$%s (%s%%)\n" \
            "$CUMULATIVE_COST" "$BUDGET" "$BUDGET_PCT"
    fi
    printf '\n'

    log "SESSION $ITERATION END — cost=\$$SESSION_COST cumulative=\$$CUMULATIVE_COST turns=$NUM_TURNS reason=$TERMINAL_REASON duration=${SESSION_DURATION}s"

    # ── Poll for new handoff written by this session ──────────────────────────
    new_handoff="$(poll_for_new_handoff "$SESSION_START_EPOCH")"
    if [[ -n "$new_handoff" ]]; then
        log "SESSION $ITERATION new handoff detected: $(basename "$new_handoff")"
    fi

    # ── Log to JSONL ──────────────────────────────────────────────────────────
    log_session_jsonl \
        "$ITERATION" "$SESSION_ID" "$SESSION_COST" "$CUMULATIVE_COST" \
        "$NUM_TURNS" "$TERMINAL_REASON" "$SESSION_DURATION" \
        "${INTERRUPTED:+interrupted}"

    # ── Stall detection ───────────────────────────────────────────────────────
    AFTER_DIFF="$(get_git_diff_stat)"
    if [[ "$TERMINAL_REASON" == "completed" ]]; then
        if [[ "$BEFORE_DIFF" == "$AFTER_DIFF" ]]; then
            CONSECUTIVE_ZERO_DELTA=$(( CONSECUTIVE_ZERO_DELTA + 1 ))
            warn "Session $ITERATION completed with zero git changes (${CONSECUTIVE_ZERO_DELTA}/${STALL_THRESHOLD})"
        else
            CONSECUTIVE_ZERO_DELTA=0
        fi
    fi
    PREV_DIFF_STAT="$AFTER_DIFF"

    # ── Failure tracking ──────────────────────────────────────────────────────
    IS_FAILURE=false
    if [[ "$TIMED_OUT" == "true" ]]; then
        IS_FAILURE=true
    elif [[ "$PARSE_OK" == "false" ]]; then
        IS_FAILURE=true
    elif [[ "$TERMINAL_REASON" != "completed" && "$TERMINAL_REASON" != "max_turns" ]]; then
        IS_FAILURE=true
    fi

    if [[ "$IS_FAILURE" == "true" ]]; then
        CONSECUTIVE_FAILURES=$(( CONSECUTIVE_FAILURES + 1 ))
    else
        CONSECUTIVE_FAILURES=0
    fi

    # ── Exit condition checks (priority order) ────────────────────────────────

    # P0: SIGINT (deferred exit — parse+log complete above)
    if [[ "$INTERRUPTED" == "true" ]]; then
        FINAL_REASON="Interrupted by user"
        FINAL_EXIT_CODE=130
        break
    fi

    # P5: Timeout (check before project-complete to ensure we record it)
    if [[ "$TIMED_OUT" == "true" ]]; then
        FINAL_REASON="Session timed out after ${SESSION_TIMEOUT}s"
        FINAL_EXIT_CODE=5
        break
    fi

    # P1: Project complete
    if check_project_complete; then
        complete_reason="$(get_complete_reason)"
        FINAL_REASON="Project complete: $complete_reason"
        FINAL_EXIT_CODE=0
        break
    fi

    # P2: Budget exhausted (skipped with --no-budget)
    if [[ "$NO_BUDGET" == "false" ]] && [[ "$(float_ge "$CUMULATIVE_COST" "$BUDGET")" == "true" ]]; then
        FINAL_REASON="Budget exhausted: \$$CUMULATIVE_COST / \$$BUDGET"
        FINAL_EXIT_CODE=2
        printf "${YELLOW}Budget exhausted: \$%s / \$%s. Stopping.${NC}\n" \
            "$CUMULATIVE_COST" "$BUDGET"
        break
    fi

    # P3: Max iterations
    if (( ITERATION >= MAX_ITERATIONS )); then
        FINAL_REASON="Max iterations reached: $ITERATION/$MAX_ITERATIONS"
        FINAL_EXIT_CODE=3
        printf "${YELLOW}Max iterations reached (%d/%d). Stopping.${NC}\n" \
            "$ITERATION" "$MAX_ITERATIONS"
        break
    fi

    # P4: Consecutive failures
    if (( CONSECUTIVE_FAILURES >= MAX_FAILURES )); then
        FINAL_REASON="Too many consecutive failures: $CONSECUTIVE_FAILURES"
        FINAL_EXIT_CODE=1
        printf "${RED}Too many consecutive failures (%d). Stopping.${NC}\n" \
            "$CONSECUTIVE_FAILURES"
        break
    fi

    # P5: Stall detection
    if (( CONSECUTIVE_ZERO_DELTA >= STALL_THRESHOLD )); then
        FINAL_REASON="Stall detected: $CONSECUTIVE_ZERO_DELTA consecutive sessions with no git changes"
        FINAL_EXIT_CODE=4
        printf "${YELLOW}Stall detected: %d consecutive sessions with zero git changes. Stopping.${NC}\n" \
            "$CONSECUTIVE_ZERO_DELTA"
        break
    fi

    # ── Cooldown before next session ──────────────────────────────────────────
    if (( COOLDOWN > 0 )); then
        printf "   Cooldown: %ds...\n\n" "$COOLDOWN"
        sleep "$COOLDOWN"
    fi

done

# ── Summary and exit ──────────────────────────────────────────────────────────
print_summary "$FINAL_REASON" "$FINAL_EXIT_CODE"

if (( FINAL_EXIT_CODE == 130 )); then
    printf "${YELLOW}Interrupted. State saved. Resume with:${NC}\n"
    if [[ "$NO_BUDGET" == "true" ]]; then
        printf "  tools/aegis-autopilot.sh --max-iterations %d\n\n" "$MAX_ITERATIONS"
    else
        printf "  tools/aegis-autopilot.sh --budget %s --max-iterations %d\n\n" "$BUDGET" "$MAX_ITERATIONS"
    fi
fi

exit "$FINAL_EXIT_CODE"
