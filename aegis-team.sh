#!/usr/bin/env bash
# ============================================================================
# AEGIS v6.0 -- Agent Team Orchestrator
# Spawns multiple Claude Code instances in tmux panes for parallel agent work
# ============================================================================

set -euo pipefail

VERSION="6.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --------------------------------------------------------------------------
# Colors (matching install.sh scheme)
# --------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# --------------------------------------------------------------------------
# Agent Registry (bash 3.2 compatible — no associative arrays)
# --------------------------------------------------------------------------
get_emoji() {
    case "$1" in
        navi)  echo "🧭" ;;
        sage)  echo "📐" ;;
        bolt)  echo "⚡" ;;
        vigil) echo "🛡️" ;;
        havoc) echo "🔴" ;;
        forge) echo "🔧" ;;
        pixel) echo "🖌️" ;;
        muse)  echo "🎨" ;;
        *)     echo "🤖" ;;
    esac
}

get_role() {
    case "$1" in
        navi)  echo "Session Orchestrator" ;;
        sage)  echo "System Architect" ;;
        bolt)  echo "Code Builder" ;;
        vigil) echo "Quality Reviewer" ;;
        havoc) echo "Adversarial Challenger" ;;
        forge) echo "Research Scanner" ;;
        pixel) echo "UI/UX Specialist" ;;
        muse)  echo "Documentation Writer" ;;
        *)     echo "Agent" ;;
    esac
}

# --------------------------------------------------------------------------
# Team Definitions: team -> "agent:role,agent:role,..."
# --------------------------------------------------------------------------
get_team() {
    case "$1" in
        build)  echo "sage:Architect,bolt:Implementer,vigil:Reviewer" ;;
        review) echo "forge:Scanner,havoc:Challenger,vigil:Reviewer" ;;
        debate) echo "sage:Proposer,bolt:Feasibility,havoc:Challenger,navi:Synthesizer" ;;
        *)      echo "" ;;
    esac
}

# --------------------------------------------------------------------------
# Defaults
# --------------------------------------------------------------------------
TEAM_NAME=""
TASK=""
AGENTS_CSV=""
PROJECT_DIR="$(pwd)"
SESSION_NAME="aegis-team"
KILL=false
ATTACH=false

# --------------------------------------------------------------------------
# Usage
# --------------------------------------------------------------------------
usage() {
    cat <<EOF
${BOLD}AEGIS v${VERSION} -- Agent Team Orchestrator${NC}

Spawn multiple Claude Code agents in tmux panes for parallel work.

${BOLD}USAGE${NC}
  aegis-team.sh --team <name> --task "description"
  aegis-team.sh --team custom --agents "sage,bolt" --task "description"
  aegis-team.sh --kill
  aegis-team.sh --attach

${BOLD}OPTIONS${NC}
  --team <name>         Team type: build | review | debate | custom (required)
  --task <description>  What the team should do (required)
  --agents <list>       Comma-separated agent names for custom team
  --project <path>      Project directory (default: current dir)
  --session <name>      tmux session name (default: aegis-team)
  --kill                Kill existing aegis-team session
  --attach              Attach to existing session
  --help                Show this help

${BOLD}TEAMS${NC}
  ${CYAN}build${NC}    Sage (Architect) -> Bolt (Implementer) -> Vigil (Reviewer)
  ${CYAN}review${NC}   Forge (Scanner) + Havoc (Challenger) + Vigil (Reviewer)
  ${CYAN}debate${NC}   Sage (Proposer) + Bolt (Feasibility) + Havoc (Challenger) + Navi (Synthesizer)
  ${CYAN}custom${NC}   Pick your own agents with --agents

${BOLD}EXAMPLES${NC}
  aegis-team.sh --team build --task "Implement auth system"
  aegis-team.sh --team review --task "Review src/ directory"
  aegis-team.sh --team debate --task "SQL vs NoSQL for this project"
  aegis-team.sh --team custom --agents "sage,bolt" --task "Quick spec and build"

${BOLD}CONTROLS${NC} (inside tmux)
  Ctrl+B o    Switch between panes
  Ctrl+B z    Zoom/unzoom current pane
  Ctrl+B d    Detach from session
EOF
    exit 0
}

# --------------------------------------------------------------------------
# CLI Parsing
# --------------------------------------------------------------------------
if [[ $# -eq 0 ]]; then
    usage
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        --team)
            TEAM_NAME="$2"
            shift 2
            ;;
        --task)
            TASK="$2"
            shift 2
            ;;
        --agents)
            AGENTS_CSV="$2"
            shift 2
            ;;
        --project)
            PROJECT_DIR="$2"
            shift 2
            ;;
        --session)
            SESSION_NAME="$2"
            shift 2
            ;;
        --kill)
            KILL=true
            shift
            ;;
        --attach)
            ATTACH=true
            shift
            ;;
        --help|-h)
            usage
            ;;
        *)
            error "Unknown option: $1 (use --help for usage)"
            ;;
    esac
done

# --------------------------------------------------------------------------
# Kill command
# --------------------------------------------------------------------------
if [[ "$KILL" == true ]]; then
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        tmux kill-session -t "$SESSION_NAME"
        success "Killed session: $SESSION_NAME"
    else
        warn "No session named '$SESSION_NAME' found"
    fi
    exit 0
fi

# --------------------------------------------------------------------------
# Attach command
# --------------------------------------------------------------------------
if [[ "$ATTACH" == true ]]; then
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        exec tmux attach -t "$SESSION_NAME"
    else
        error "No session named '$SESSION_NAME' found. Spawn a team first."
    fi
fi

# --------------------------------------------------------------------------
# Validate required args
# --------------------------------------------------------------------------
[[ -z "$TEAM_NAME" ]] && error "Missing --team. Use --help for usage."
[[ -z "$TASK" ]] && error "Missing --task. Use --help for usage."

# --------------------------------------------------------------------------
# Pre-flight Checks
# --------------------------------------------------------------------------
preflight() {
    info "Running pre-flight checks..."

    # tmux
    if ! command -v tmux &>/dev/null; then
        error "tmux is not installed. Install with: brew install tmux"
    fi

    # claude CLI
    if ! command -v claude &>/dev/null; then
        error "claude CLI is not installed. See: https://docs.anthropic.com/en/docs/claude-code"
    fi

    # Project directory exists
    if [[ ! -d "$PROJECT_DIR" ]]; then
        error "Project directory not found: $PROJECT_DIR"
    fi

    # AEGIS installed in project?
    if [[ ! -f "$PROJECT_DIR/CLAUDE.md" ]]; then
        warn "No CLAUDE.md found in $PROJECT_DIR -- AEGIS may not be installed here"
    fi

    # Agents directory?
    if [[ ! -d "$PROJECT_DIR/.claude/agents" ]]; then
        warn "No .claude/agents/ directory in $PROJECT_DIR"
    fi

    success "Pre-flight checks passed"
}

preflight

# --------------------------------------------------------------------------
# Resolve team agents
# --------------------------------------------------------------------------
resolve_agents() {
    local agents_str=""

    if [[ "$TEAM_NAME" == "custom" ]]; then
        [[ -z "$AGENTS_CSV" ]] && error "--team custom requires --agents <list>"
        # Convert comma-separated names to "name:Role" pairs
        IFS=',' read -ra NAMES <<< "$AGENTS_CSV"
        local parts=()
        for name in "${NAMES[@]}"; do
            name="$(echo "$name" | xargs)" # trim whitespace
            local role
            role="$(get_role "$name")"
            parts+=("${name}:${role}")
        done
        agents_str="$(IFS=','; echo "${parts[*]}")"
    else
        agents_str="$(get_team "$TEAM_NAME")"
        [[ -z "$agents_str" ]] && error "Unknown team: $TEAM_NAME (valid: build, review, debate, custom)"
    fi

    echo "$agents_str"
}

AGENTS_STR="$(resolve_agents)"

# Parse into arrays
IFS=',' read -ra AGENT_PAIRS <<< "$AGENTS_STR"
AGENT_COUNT=${#AGENT_PAIRS[@]}

info "Team '$TEAM_NAME' with $AGENT_COUNT agents:"
for pair in "${AGENT_PAIRS[@]}"; do
    IFS=':' read -r aname arole <<< "$pair"
    local_emoji="$(get_emoji "$aname")"
    echo -e "  ${local_emoji} ${BOLD}${aname}${NC} -- ${arole}"
done

# --------------------------------------------------------------------------
# Handle existing session
# --------------------------------------------------------------------------
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo ""
    warn "Session '$SESSION_NAME' already exists."
    echo -e "  ${DIM}Options:${NC}"
    echo -e "    1) Kill and recreate  ${DIM}(default)${NC}"
    echo -e "    2) Attach to existing"
    echo -e "    3) Abort"
    echo ""
    read -r -p "Choose [1/2/3]: " choice
    case "${choice:-1}" in
        1)
            tmux kill-session -t "$SESSION_NAME"
            info "Killed existing session"
            ;;
        2)
            exec tmux attach -t "$SESSION_NAME"
            ;;
        *)
            info "Aborted"
            exit 0
            ;;
    esac
fi

# --------------------------------------------------------------------------
# Prepare output directory
# --------------------------------------------------------------------------
DATE_DIR="$(date +%Y%m%d)"
OUTPUT_DIR="_aegis-output/${TEAM_NAME}/${DATE_DIR}"
mkdir -p "${PROJECT_DIR}/${OUTPUT_DIR}"
info "Output directory: ${OUTPUT_DIR}/"

# --------------------------------------------------------------------------
# Build teammate list string for prompts
# --------------------------------------------------------------------------
build_teammates_list() {
    local exclude="$1"
    local list=""
    for pair in "${AGENT_PAIRS[@]}"; do
        IFS=':' read -r aname arole <<< "$pair"
        if [[ "$aname" != "$exclude" ]]; then
            list+="  - ${aname} (${arole})"$'\n'
        fi
    done
    echo "$list"
}

# --------------------------------------------------------------------------
# Build prompt for an agent
# --------------------------------------------------------------------------
build_prompt() {
    local agent_name="$1"
    local agent_role="$2"
    local teammates
    teammates="$(build_teammates_list "$agent_name")"

    cat <<PROMPT
You are ${agent_name} (${agent_role}) in an AEGIS ${TEAM_NAME} team.
Read .claude/agents/${agent_name}.md for your persona and constraints.

YOUR TASK:
${TASK}

TEAM MEMBERS WORKING IN PARALLEL:
${teammates}
COORDINATION:
- Write your output to: ${OUTPUT_DIR}/
- Use filenames prefixed with your name: ${agent_name}-*.md
- When done, write a summary to: ${OUTPUT_DIR}/${agent_name}-done.md
- Check teammates' output files in ${OUTPUT_DIR}/ to coordinate
- If you depend on another agent's output, poll for their -done.md file

BEGIN WORK NOW.
PROMPT
}

# --------------------------------------------------------------------------
# Create tmux layout
# --------------------------------------------------------------------------
create_layout() {
    local count="$1"

    # Create the session with the first pane
    tmux new-session -d -s "$SESSION_NAME" -x 220 -y 60

    # Enable pane border status
    tmux set-option -t "$SESSION_NAME" pane-border-status top
    tmux set-option -t "$SESSION_NAME" pane-border-format " #{pane_title} "

    # Set status bar
    tmux set-option -t "$SESSION_NAME" status-style "bg=colour235,fg=colour136"
    tmux set-option -t "$SESSION_NAME" status-left "#[fg=colour46,bold] AEGIS ${TEAM_NAME} team "
    tmux set-option -t "$SESSION_NAME" status-right "#[fg=colour244] %H:%M | Ctrl+B d to detach "

    if [[ $count -eq 1 ]]; then
        # Single pane, nothing to split
        :
    elif [[ $count -eq 2 ]]; then
        # 2 panes side by side
        tmux split-window -h -t "$SESSION_NAME"
    elif [[ $count -eq 3 ]]; then
        # 2 top + 1 bottom (+ optional log pane)
        tmux split-window -h -t "$SESSION_NAME"       # pane 0 | pane 1
        tmux split-window -v -t "$SESSION_NAME.0"      # pane 0 top/bottom, pane 1 right
        # Result: pane 0 (top-left), pane 1 (bottom-left), pane 2 (right)
        # Re-number: after split, panes are 0=top-left, 1=bottom-left, 2=right
        # We want: 0=agent1, 1=agent2, 2=agent3
    elif [[ $count -ge 4 ]]; then
        # 2x2 grid (+ extra panes if >4)
        tmux split-window -h -t "$SESSION_NAME"       # left | right
        tmux split-window -v -t "$SESSION_NAME.0"      # top-left / bottom-left
        tmux split-window -v -t "$SESSION_NAME.2"      # top-right / bottom-right
        # Result: 0=top-left, 1=bottom-left, 2=top-right, 3=bottom-right

        # If more than 4, add extra panes
        local extra=$(( count - 4 ))
        for (( i=0; i<extra; i++ )); do
            tmux split-window -v -t "$SESSION_NAME.$((i % 4))"
        done
    fi

    # Even out the layout
    if [[ $count -ge 3 ]]; then
        tmux select-layout -t "$SESSION_NAME" tiled 2>/dev/null || true
    fi
}

# --------------------------------------------------------------------------
# Spawn agents
# --------------------------------------------------------------------------
spawn_team() {
    local include_log=false
    local total_panes=$AGENT_COUNT

    # Add a log pane for teams with 3+ agents
    if [[ $AGENT_COUNT -ge 3 ]]; then
        include_log=true
        total_panes=$(( AGENT_COUNT + 1 ))
    fi

    info "Creating tmux layout with ${total_panes} panes..."
    create_layout "$total_panes"

    # Small delay to let tmux settle
    sleep 0.5

    # Launch each agent
    local pane_idx=0
    for pair in "${AGENT_PAIRS[@]}"; do
        IFS=':' read -r agent_name agent_role <<< "$pair"

        # Set pane title
        local emoji
        emoji="$(get_emoji "$agent_name")"
        local pane_title
        pane_title="$(echo -e "${emoji}") ${agent_name} -- ${agent_role}"
        tmux select-pane -t "${SESSION_NAME}.${pane_idx}" -T "$pane_title"

        # Build prompt
        local prompt
        prompt="$(build_prompt "$agent_name" "$agent_role")"

        # Write prompt to a temp file (avoids quoting issues with send-keys)
        local prompt_file
        prompt_file="${PROJECT_DIR}/${OUTPUT_DIR}/.prompt-${agent_name}.txt"
        echo "$prompt" > "$prompt_file"

        # Launch claude in the pane
        # Use -p (print mode) which skips the workspace trust dialog
        # --dangerously-skip-permissions bypasses tool permission prompts
        tmux send-keys -t "${SESSION_NAME}.${pane_idx}" \
            "cd '${PROJECT_DIR}' && claude -p --dangerously-skip-permissions < '${prompt_file}'" Enter

        info "  Launched ${agent_name} (${agent_role}) in pane ${pane_idx}"
        pane_idx=$(( pane_idx + 1 ))
    done

    # Activity log pane (for 3+ agent teams)
    if [[ "$include_log" == true ]]; then
        tmux select-pane -t "${SESSION_NAME}.${pane_idx}" -T "Activity Log"

        # Write log watcher script to avoid quoting issues with send-keys
        local log_script="${PROJECT_DIR}/${OUTPUT_DIR}/.activity-log.sh"
        {
            echo '#!/usr/bin/env bash'
            echo "OUTPUT_DIR='${PROJECT_DIR}/${OUTPUT_DIR}'"
            echo "TEAM_NAME='${TEAM_NAME}'"
            echo "AGENT_COUNT='${AGENT_COUNT}'"
            # Build agent names list
            local agent_names=""
            for pair in "${AGENT_PAIRS[@]}"; do
                IFS=':' read -r aname _ <<< "$pair"
                agent_names+="${aname} "
            done
            echo "AGENT_NAMES='${agent_names}'"
            cat <<'LOGSCRIPT'
echo "Activity Log -- watching output directory"
while true; do
    clear
    echo "=== AEGIS Activity Log ==="
    echo ""
    echo "Team: $TEAM_NAME | Agents: $AGENT_COUNT | $(date)"
    echo ""
    echo "Output files:"
    ls -la "$OUTPUT_DIR/" 2>/dev/null | grep -v '\.prompt' | tail -n +2 || echo "  (waiting for output...)"
    echo ""
    echo "Completion status:"
    for name in $AGENT_NAMES; do
        if [[ -f "${OUTPUT_DIR}/${name}-done.md" ]]; then
            echo "  [DONE] ${name}"
        else
            echo "  [....] ${name}"
        fi
    done
    sleep 5
done
LOGSCRIPT
        } > "$log_script"
        chmod +x "$log_script"

        tmux send-keys -t "${SESSION_NAME}.${pane_idx}" \
            "bash '${log_script}'" Enter
    fi

    # Focus on first pane
    tmux select-pane -t "${SESSION_NAME}.0"
}

spawn_team

# --------------------------------------------------------------------------
# Output summary
# --------------------------------------------------------------------------
echo ""
echo -e "${BOLD}${GREEN}AEGIS Team Spawned!${NC}"
echo ""
echo -e "  ${BOLD}Session:${NC}  $SESSION_NAME"
echo -e "  ${BOLD}Team:${NC}     $TEAM_NAME ($AGENT_COUNT agents)"
echo -e "  ${BOLD}Task:${NC}     $TASK"
echo -e "  ${BOLD}Output:${NC}   $OUTPUT_DIR/"
echo ""
echo -e "  ${CYAN}Watch agents work:${NC}"
echo -e "    tmux attach -t $SESSION_NAME"
echo ""
echo -e "  ${CYAN}Controls:${NC}"
echo -e "    Ctrl+B o    Switch pane"
echo -e "    Ctrl+B z    Zoom pane"
echo -e "    Ctrl+B d    Detach"
echo -e "    Ctrl+C      Interrupt agent"
echo ""
echo -e "  ${CYAN}Quick commands:${NC}"
echo -e "    aegis-team.sh --attach              Reattach to session"
echo -e "    aegis-team.sh --kill                 Kill all agents"
echo ""
