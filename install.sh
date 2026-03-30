#!/usr/bin/env bash
# ============================================================================
# AEGIS v8.2.1 Installer
# Creates/updates the AEGIS framework. See .claude/references/update-protocol.md
# ============================================================================

set -euo pipefail

VERSION="8.2.1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --------------------------------------------------------------------------
# Verify source files exist
# --------------------------------------------------------------------------
if [[ ! -f "$SCRIPT_DIR/CLAUDE.md" ]]; then
    echo -e "\033[0;31m[ERROR]\033[0m Cannot find AEGIS source files in $SCRIPT_DIR"
    echo -e "\033[0;31m[ERROR]\033[0m Make sure you're running install.sh from the aegis-hq repo"
    exit 1
fi

# --------------------------------------------------------------------------
# Defaults
# --------------------------------------------------------------------------
PROFILE="standard"
PROJECT_NAME=""
UPGRADE=false
TARGET_DIR="$(pwd)"

# --------------------------------------------------------------------------
# Colors
# --------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# --------------------------------------------------------------------------
# Helpers
# --------------------------------------------------------------------------
info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

usage() {
    cat <<USAGE
${BOLD}AEGIS v${VERSION} Installer${NC}

Usage: $(basename "$0") [OPTIONS]

Options:
  --profile <minimal|standard|full>   Skill profile (default: standard)
  --project-name "Name"               Project name for branding
  --target-dir /path/to/project       Target directory (default: current dir)
  --upgrade                           Upgrade existing installation
  -h, --help                          Show this help message

Examples:
  $(basename "$0") --profile minimal --project-name "My API"
  $(basename "$0") --upgrade --profile full
  $(basename "$0") --target-dir /path/to/project --profile standard

USAGE
    exit 0
}

# --------------------------------------------------------------------------
# Parse Arguments
# --------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --profile)
            PROFILE="$2"
            if [[ ! "$PROFILE" =~ ^(minimal|standard|full)$ ]]; then
                error "Invalid profile: $PROFILE. Must be minimal, standard, or full."
            fi
            shift 2
            ;;
        --project-name)
            PROJECT_NAME="$2"
            shift 2
            ;;
        --target-dir)
            TARGET_DIR="$2"
            shift 2
            ;;
        --upgrade)
            UPGRADE=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            error "Unknown option: $1. Use --help for usage."
            ;;
    esac
done

# --------------------------------------------------------------------------
# Pre-flight Checks
# --------------------------------------------------------------------------
echo ""
echo -e "${BOLD}${CYAN}================================================${NC}"
echo -e "${BOLD}${CYAN}  AEGIS v${VERSION} Installer${NC}"
echo -e "${BOLD}${CYAN}================================================${NC}"
echo ""

info "Profile: ${BOLD}${PROFILE}${NC}"
info "Target:  ${BOLD}${TARGET_DIR}${NC}"
if [[ -n "$PROJECT_NAME" ]]; then
    info "Project: ${BOLD}${PROJECT_NAME}${NC}"
fi
if [[ "$UPGRADE" == true ]]; then
    info "Mode:    ${BOLD}Upgrade${NC}"
fi
echo ""

# Check dependencies
info "Checking dependencies..."

if ! command -v git &>/dev/null; then
    error "git is required but not installed. Install it first."
fi
success "git found: $(git --version)"

if ! command -v tmux &>/dev/null; then
    warn "tmux not found. Agent team split-pane view won't be available."
    warn "Teams still work in in-process mode (Shift+Down to see agents)."
    warn "Install with: brew install tmux (macOS) or apt install tmux (Linux)"
else
    success "tmux found: $(tmux -V)"
fi

# Check if claude CLI is available
if ! command -v claude &>/dev/null; then
    error "Claude Code CLI is REQUIRED but not found."
    echo "  Install with: npm install -g @anthropic-ai/claude-code"
    echo "  Requires Node.js 18+: brew install node"
    exit 1
else
    success "claude CLI found: $(claude --version 2>&1 | head -1)"
fi

# Check CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS env var
if [[ "${CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS:-}" != "1" ]]; then
    warn "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS is NOT set."
    echo ""
    echo "  This env var is REQUIRED for AEGIS Agent Teams to work."
    echo "  Without it, team commands (/aegis-team-*) won't spawn agents."
    echo ""

    # Detect shell config file
    SHELL_RC=""
    if [[ -f "$HOME/.zshrc" ]]; then
        SHELL_RC="$HOME/.zshrc"
    elif [[ -f "$HOME/.bashrc" ]]; then
        SHELL_RC="$HOME/.bashrc"
    fi

    if [[ -n "$SHELL_RC" ]]; then
        # Check if already in rc file but not sourced
        if grep -q 'CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS' "$SHELL_RC" 2>/dev/null; then
            info "Found in $SHELL_RC but not sourced. Run: source $SHELL_RC"
        else
            echo "  Adding to $SHELL_RC..."
            echo 'export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1' >> "$SHELL_RC"
            success "Added to $SHELL_RC"
            echo "  Run 'source $SHELL_RC' or open a new terminal for it to take effect."
        fi
    else
        echo "  Add this to your shell config (~/.zshrc or ~/.bashrc):"
        echo '    export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1'
    fi

    # Set for current session
    export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
    echo ""
else
    success "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1"
fi

# --------------------------------------------------------------------------
# Upgrade Check
# --------------------------------------------------------------------------
if [[ "$UPGRADE" == true ]]; then
    if [[ ! -f "${TARGET_DIR}/CLAUDE.md" ]]; then
        error "No existing AEGIS installation found in ${TARGET_DIR}. Remove --upgrade flag for fresh install."
    fi
    info "Upgrading existing installation..."
    # Back up existing files
    BACKUP_DIR="${TARGET_DIR}/_aegis-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    for f in CLAUDE.md CLAUDE_safety.md CLAUDE_agents.md CLAUDE_skills.md CLAUDE_lessons.md; do
        if [[ -f "${TARGET_DIR}/${f}" ]]; then
            cp "${TARGET_DIR}/${f}" "${BACKUP_DIR}/${f}"
        fi
    done
    # Back up .claude/ config (settings, agents, commands, etc.)
    if [[ -d "${TARGET_DIR}/.claude" ]]; then
        cp -r "${TARGET_DIR}/.claude" "${BACKUP_DIR}/.claude"
    fi
    # Back up skills/
    if [[ -d "${TARGET_DIR}/skills" ]]; then
        cp -r "${TARGET_DIR}/skills" "${BACKUP_DIR}/skills"
    fi
    success "Existing files backed up to ${BACKUP_DIR}"
fi

# --------------------------------------------------------------------------
# Directory Structure
# --------------------------------------------------------------------------
info "Creating directory structure..."

directories=(
    "${TARGET_DIR}/_aegis-brain"
    "${TARGET_DIR}/_aegis-brain/resonance"
    "${TARGET_DIR}/_aegis-brain/learnings"
    "${TARGET_DIR}/_aegis-brain/logs"
    "${TARGET_DIR}/_aegis-brain/retrospectives"
    "${TARGET_DIR}/_aegis-brain/tasks"
    "${TARGET_DIR}/_aegis-brain/skill-cache"
    "${TARGET_DIR}/_aegis-brain/metrics"
    "${TARGET_DIR}/_aegis-brain/learnings/raw"
    "${TARGET_DIR}/_aegis-output"
    "${TARGET_DIR}/_aegis-output/reviews"
    "${TARGET_DIR}/_aegis-output/adversarial"
    "${TARGET_DIR}/_aegis-output/scans"
    "${TARGET_DIR}/_aegis-output/architecture"
    "${TARGET_DIR}/_aegis-output/architecture/archive"
    "${TARGET_DIR}/_aegis-output/design"
    "${TARGET_DIR}/_aegis-output/content"
    "${TARGET_DIR}/_aegis-output/specs"
    "${TARGET_DIR}/_aegis-output/breakdown"
    "${TARGET_DIR}/_aegis-output/research"
    "${TARGET_DIR}/_aegis-output/qa"
    "${TARGET_DIR}/_aegis-output/qa/results"
    "${TARGET_DIR}/_aegis-output/iso-docs"
    "${TARGET_DIR}/_aegis-output/sessions"
    "${TARGET_DIR}/_aegis-brain/sprints"
    "${TARGET_DIR}/_aegis-brain/sprints/current"
    "${TARGET_DIR}/_aegis-brain/handoffs"
    "${TARGET_DIR}/_aegis-brain/backlog"
    "${TARGET_DIR}/skills"
    "${TARGET_DIR}/.claude"
    "${TARGET_DIR}/.claude/agents"
    "${TARGET_DIR}/.claude/commands"
    "${TARGET_DIR}/.claude/references"
    "${TARGET_DIR}/.claude/teams"
    "${TARGET_DIR}/docs"
    "${TARGET_DIR}/docs/decisions"
)

for dir in "${directories[@]}"; do
    mkdir -p "$dir"
done
success "Directory structure created"

# --------------------------------------------------------------------------
# Initialize counters.json (sequential ID system)
# --------------------------------------------------------------------------
if [[ ! -f "${TARGET_DIR}/_aegis-brain/counters.json" ]]; then
    info "Initializing counters.json for sequential IDs..."
    cat > "${TARGET_DIR}/_aegis-brain/counters.json" << 'COUNTERS'
{
  "project_key": "PROJ",
  "counters": {"US":0,"J":0,"E":0,"T":0,"ST":0,"DOC":0,"ADR":0,"TD":0,"REL":0,"HO":0},
  "last_updated": "1970-01-01T00:00:00"
}
COUNTERS
    success "counters.json initialized"
else
    if [[ "$UPGRADE" == true ]]; then
        info "Preserving existing counters.json (upgrade mode)"
    fi
    success "counters.json already exists"
fi

# --------------------------------------------------------------------------
# Git Init (if not already a repo)
# --------------------------------------------------------------------------
if [[ ! -d "${TARGET_DIR}/.git" ]]; then
    info "Initializing git repository..."
    git -C "$TARGET_DIR" init -b main
    success "Git repository initialized"
else
    success "Git repository already exists"
fi

# --------------------------------------------------------------------------
# .gitignore
# --------------------------------------------------------------------------
info "Creating .gitignore..."

cat > "${TARGET_DIR}/.gitignore" <<'GITIGNORE'
# AEGIS Framework
_aegis-output/*.tmp
_aegis-output/.cache/
*.log
!_aegis-brain/logs/activity.log

# Environment & Secrets
.env
.env.*
*.key
*.pem
*secret*
credentials.*

# OS
.DS_Store
Thumbs.db

# Dependencies
node_modules/
__pycache__/
*.pyc
.venv/
vendor/

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# Build
dist/
build/
*.o
*.so
GITIGNORE

success ".gitignore created"

# --------------------------------------------------------------------------
# Brain Resonance Files
# --------------------------------------------------------------------------
info "Initializing brain resonance files..."

cat > "${TARGET_DIR}/_aegis-brain/resonance/project-state.md" <<RESONANCE
# Project State Resonance
> Auto-generated by AEGIS installer on $(date +%Y-%m-%d)

## Project
- Name: ${PROJECT_NAME:-"(unnamed)"}
- Profile: ${PROFILE}
- AEGIS Version: ${VERSION}
- Created: $(date +%Y-%m-%d)

## Current State
- Phase: initialization
- Active Branch: main
- Autonomy Level: L1 (human approves every action)

## Key Decisions
(none yet -- decisions will be logged here by /aegis-retro)

## Active Tasks
(none yet)

## Blockers
(none)
RESONANCE

cat > "${TARGET_DIR}/_aegis-brain/resonance/team-state.md" <<TEAMSTATE
# Team State Resonance
> Auto-generated by AEGIS installer on $(date +%Y-%m-%d)

## Active Agents
(none -- agents spawn on demand)

## Last Pipeline Run
(none)

## Session Count
0

## Cumulative Lessons
- Patterns: 0
- Anti-patterns: 0
TEAMSTATE

success "Brain resonance files created"

# --------------------------------------------------------------------------
# Copy CLAUDE*.md files from source
# --------------------------------------------------------------------------
info "Installing CLAUDE*.md files..."

claude_files=("CLAUDE.md" "CLAUDE_safety.md" "CLAUDE_agents.md" "CLAUDE_skills.md" "CLAUDE_lessons.md")

for f in "${claude_files[@]}"; do
    src="${SCRIPT_DIR}/${f}"
    dst="${TARGET_DIR}/${f}"
    if [[ -f "$src" ]]; then
        if [[ "$UPGRADE" == true && "$f" == "CLAUDE_lessons.md" && -f "$dst" ]]; then
            info "Preserving ${f} (user patterns — backup has copy)"
        else
            cp "$src" "$dst"
        fi
    else
        warn "Source file not found: ${src} — skipping"
    fi
done
success "CLAUDE*.md files installed"

# --------------------------------------------------------------------------
# Copy .claude/ config files (agents, commands, references, teams)
# --------------------------------------------------------------------------
info "Installing agent definitions, commands, references, and teams..."

copy_dir_contents() {
    local src_dir="$1"
    local dst_dir="$2"
    local label="$3"

    if [[ ! -d "$src_dir" ]]; then
        warn "Source directory not found: ${src_dir} — skipping ${label}"
        return
    fi

    local count=0
    for f in "$src_dir"/*; do
        [[ -f "$f" ]] || continue
        cp "$f" "$dst_dir/"
        count=$((count + 1))
    done
    success "${count} ${label} installed"
}

copy_dir_contents "${SCRIPT_DIR}/.claude/agents"     "${TARGET_DIR}/.claude/agents"     "agent definitions"
copy_dir_contents "${SCRIPT_DIR}/.claude/commands"    "${TARGET_DIR}/.claude/commands"   "commands"
copy_dir_contents "${SCRIPT_DIR}/.claude/references"  "${TARGET_DIR}/.claude/references" "reference files"
copy_dir_contents "${SCRIPT_DIR}/.claude/teams"       "${TARGET_DIR}/.claude/teams"      "team configs"

# Copy settings.json (but not settings.local.json which has user-specific config)
if [[ -f "${SCRIPT_DIR}/.claude/settings.json" ]]; then
    cp "${SCRIPT_DIR}/.claude/settings.json" "${TARGET_DIR}/.claude/settings.json"
    success "settings.json installed"
else
    warn "settings.json not found in source — skipping"
fi

# --------------------------------------------------------------------------
# Copy skill files based on profile (full files, not stubs)
# --------------------------------------------------------------------------
info "Installing skills for profile: ${PROFILE}..."

# Skill lists per profile
minimal_skills=("ai-personas" "orchestrator" "code-review" "code-standards" "git-workflow" "bug-lifecycle" "project-navigator")
standard_skills=("super-spec" "test-architect" "security-audit" "tech-debt-tracker" "sprint-tracker" "api-docs" "sprint-manager" "kanban-board" "work-breakdown")
full_skills=("aegis-distill" "aegis-observe" "adversarial-review" "code-coverage" "retrospective" "course-correction" "skill-marketplace" "aegis-builder" "qa-pipeline" "iso-29110-docs")

copy_skill() {
    local name="$1"
    local src="${SCRIPT_DIR}/skills/${name}.md"
    local dst="${TARGET_DIR}/skills/${name}.md"

    # sprint-tracker.md was upgraded to sprint-manager content; copy under the new name
    if [[ "$name" == "sprint-manager" && ! -f "$src" ]]; then
        src="${SCRIPT_DIR}/skills/sprint-tracker.md"
    fi

    if [[ -f "$src" ]]; then
        cp "$src" "$dst"
    else
        warn "Skill source not found: ${src}"
    fi
}

# Always install minimal skills
for skill in "${minimal_skills[@]}"; do
    copy_skill "$skill"
done

# Install standard skills if profile is standard or full
if [[ "$PROFILE" == "standard" || "$PROFILE" == "full" ]]; then
    for skill in "${standard_skills[@]}"; do
        copy_skill "$skill"
    done
fi

# Install full skills if profile is full
if [[ "$PROFILE" == "full" ]]; then
    for skill in "${full_skills[@]}"; do
        copy_skill "$skill"
    done
fi

# Count skills installed
skill_count=$(ls -1 "${TARGET_DIR}/skills/"*.md 2>/dev/null | wc -l | tr -d ' ')
success "${skill_count} skills installed (full definitions, not stubs)"

# --------------------------------------------------------------------------
# Copy ISO 29110 Document Templates
# --------------------------------------------------------------------------
info "Installing ISO 29110 document templates..."

iso_doc_dirs=(
    "PM-01-project-plan"
    "PM-02-progress-status"
    "PM-03-change-requests"
    "PM-04-meeting-records"
    "SI-01-requirements-spec"
    "SI-02-design-doc"
    "SI-03-traceability"
    "SI-04-test-plan"
    "SI-05-test-report"
    "SI-06-acceptance"
    "SI-07-configuration"
)

iso_count=0
for doc_dir in "${iso_doc_dirs[@]}"; do
    src_dir="${SCRIPT_DIR}/_aegis-output/iso-docs/${doc_dir}"
    dst_dir="${TARGET_DIR}/_aegis-output/iso-docs/${doc_dir}"

    if [[ ! -d "$src_dir" ]]; then
        warn "ISO doc template not found: ${src_dir} -- skipping"
        continue
    fi

    # On upgrade, preserve existing ISO docs (user may have customized them)
    if [[ "$UPGRADE" == true && -d "$dst_dir" ]]; then
        info "Preserving existing ${doc_dir} (upgrade mode)"
        continue
    fi

    mkdir -p "$dst_dir"
    for f in "$src_dir"/*; do
        [[ -f "$f" ]] || continue
        cp "$f" "$dst_dir/"
    done
    iso_count=$((iso_count + 1))
done

# Copy doc-registry.json
if [[ -f "${SCRIPT_DIR}/_aegis-output/iso-docs/doc-registry.json" ]]; then
    if [[ "$UPGRADE" == true && -f "${TARGET_DIR}/_aegis-output/iso-docs/doc-registry.json" ]]; then
        info "Preserving existing doc-registry.json (upgrade mode)"
    else
        cp "${SCRIPT_DIR}/_aegis-output/iso-docs/doc-registry.json" "${TARGET_DIR}/_aegis-output/iso-docs/doc-registry.json"
    fi
fi

success "${iso_count} ISO 29110 document templates installed"

# --------------------------------------------------------------------------
# Initial Activity Log + Welcome Data (new installs only)
# --------------------------------------------------------------------------
if [[ "$UPGRADE" != true ]]; then
    info "Creating initial activity log and welcome data..."

    # Activity log with install entry
    cat > "${TARGET_DIR}/_aegis-brain/logs/activity.log" <<ACTLOG
# AEGIS Activity Log — Append Only
# Format: [ISO-8601] [AGENT_EMOJI] [STATUS] — [message]
# ---
[$(date +%Y-%m-%dT%H:%M:%S)] 🧬 INSTALL | version=${VERSION} | profile=${PROFILE} | project=${PROJECT_NAME:-"unnamed"}
[$(date +%Y-%m-%dT%H:%M:%S)] 🧬 SESSION_READY | Run /aegis-start to activate Mother Brain
ACTLOG

    # Heartbeat log so dashboard shows "installed" not "dead"
    echo "[$(date '+%Y-%m-%d %H:%M')] PULSE | status=installed | agents=0 | context=0%" \
      > "${TARGET_DIR}/_aegis-brain/logs/heartbeat.log"

    # Create a welcome sprint (sprint-0) with initial kanban
    mkdir -p "${TARGET_DIR}/_aegis-brain/sprints/sprint-0/daily"

    cat > "${TARGET_DIR}/_aegis-brain/sprints/sprint-0/plan.md" <<PLAN
# Sprint 0 — Getting Started

## Sprint Goal
Set up the project and run the first /aegis-start session.

## Tasks
| ID | Title | Pts | Assignee | Priority |
|----|-------|-----|----------|----------|
| SETUP-001 | Run /aegis-start for the first time | 1 | @human | high |
| SETUP-002 | Describe your project (Mother Brain asks at P10) | 1 | @human | high |
| SETUP-003 | Run /super-spec to create BRD + SRS | 3 | @sage | medium |
PLAN

    cat > "${TARGET_DIR}/_aegis-brain/sprints/sprint-0/kanban.md" <<KANBAN
# Sprint 0 — Getting Started

> Updated: $(date '+%Y-%m-%d %H:%M') | First install

## TODO (3 tasks, 5 pts)

| ID | Title | Pts | Assignee | Priority |
|----|-------|-----|----------|----------|
| SETUP-001 | Run /aegis-start for the first time | 1 | @human | high |
| SETUP-002 | Describe your project (Mother Brain asks at P10) | 1 | @human | high |
| SETUP-003 | Run /super-spec to create BRD + SRS | 3 | @sage | medium |

## IN_PROGRESS (0 tasks, 0 pts)

| ID | Title | Pts | Assignee | Priority |
|----|-------|-----|----------|----------|

## DONE (0 tasks, 0 pts)

| ID | Title | Pts | Assignee | Priority |
|----|-------|-----|----------|----------|
KANBAN

    cat > "${TARGET_DIR}/_aegis-brain/sprints/sprint-0/metrics.json" <<METRICS
{
  "sprint": "sprint-0",
  "started": "$(date +%Y-%m-%d)",
  "planned_end": "$(date +%Y-%m-%d)",
  "actual_end": null,
  "goal": "Set up the project and run the first /aegis-start session",
  "capacity_pts": 5,
  "committed_pts": 5,
  "completed_pts": 0,
  "daily_burndown": [
    { "date": "$(date +%Y-%m-%d)", "day": 1, "remaining": 5, "completed": 0 }
  ],
  "velocity_history": [],
  "tasks": { "TODO": 3, "IN_PROGRESS": 0, "IN_REVIEW": 0, "QA": 0, "DONE": 0, "BLOCKED": 0 },
  "carry_over": { "count": 0, "points": 0, "task_ids": [] }
}
METRICS

    # Symlink current → sprint-0
    ln -sfn sprint-0 "${TARGET_DIR}/_aegis-brain/sprints/current"

    # Token usage + benchmarks (empty but valid structure)
    cat > "${TARGET_DIR}/_aegis-brain/metrics/token-usage.json" <<'TOKENS'
{
  "sprints": {},
  "trend": { "tokens_per_point": [], "improvement_pct": 0 }
}
TOKENS

    cat > "${TARGET_DIR}/_aegis-brain/metrics/benchmarks.json" <<'BENCH'
{
  "sprints": {},
  "baseline": null
}
BENCH

    success "Welcome data created (sprint-0 kanban + activity log)"
else
    info "Upgrade mode: preserving existing brain data"
fi

# --------------------------------------------------------------------------
# Summary
# --------------------------------------------------------------------------
echo ""
echo -e "${BOLD}${GREEN}================================================${NC}"
echo -e "${BOLD}${GREEN}  AEGIS v${VERSION} Installation Complete!${NC}"
echo -e "${BOLD}${GREEN}================================================${NC}"
echo ""
echo -e "${BOLD}Profile:${NC}    ${PROFILE}"
if [[ -n "$PROJECT_NAME" ]]; then
echo -e "${BOLD}Project:${NC}    ${PROJECT_NAME}"
fi
echo -e "${BOLD}Location:${NC}   ${TARGET_DIR}"
echo -e "${BOLD}Skills:${NC}     ${skill_count} loaded"
echo -e "${BOLD}ISO Docs:${NC}   ${iso_count} templates"
echo ""
echo -e "${BOLD}Directory Structure:${NC}"
echo "  ${TARGET_DIR}/"
echo "  ├── CLAUDE.md              # Hub (load every session)"
echo "  ├── CLAUDE_safety.md       # Safety rules"
echo "  ├── CLAUDE_agents.md       # Agent personas"
echo "  ├── CLAUDE_skills.md       # Skill catalog"
echo "  ├── CLAUDE_lessons.md      # Patterns & anti-patterns"
echo "  ├── _aegis-brain/          # Persistent memory"
echo "  │   ├── resonance/         # Session continuity"
echo "  │   ├── learnings/         # Accumulated knowledge"
echo "  │   ├── logs/              # Agent logs"
echo "  │   ├── tasks/             # Task tracking"
echo "  │   ├── skill-cache/       # Reusable patterns"
echo "  │   └── retrospectives/    # Session retros"
echo "  ├── _aegis-output/         # Pipeline outputs"
echo "  │   └── iso-docs/          # ISO 29110 templates"
echo "  ├── skills/                # Skill definitions"
echo "  └── .claude/               # Claude CLI config"
echo ""
echo -e "${BOLD}Next Steps:${NC}"
echo "  1. Open the project in Claude Code"
echo "  2. Run: /aegis-start"
echo "  3. The framework will load CLAUDE.md automatically"
echo "  4. Start working -- agents spawn on demand"
echo ""
if [[ "$UPGRADE" == true ]]; then
echo -e "${YELLOW}Note: Your previous files were backed up to:${NC}"
echo "  ${BACKUP_DIR}"
echo ""
fi
echo -e "${CYAN}Happy building! -- AEGIS v${VERSION}${NC}"
echo ""
