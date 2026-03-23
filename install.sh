#!/usr/bin/env bash
# ============================================================================
# AEGIS v6.0 Installer
# Creates the full AEGIS framework directory structure and configuration
# ============================================================================

set -euo pipefail

VERSION="6.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --------------------------------------------------------------------------
# Verify source files exist
# --------------------------------------------------------------------------
if [[ ! -f "$SCRIPT_DIR/CLAUDE.md" ]]; then
    echo -e "\033[0;31m[ERROR]\033[0m Cannot find AEGIS source files in $SCRIPT_DIR"
    echo -e "\033[0;31m[ERROR]\033[0m Make sure you're running install.sh from the AEGIS-Team repo"
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
    error "tmux is REQUIRED for AEGIS Agent Teams but not found."
    echo "  Install with: brew install tmux (macOS) or apt install tmux (Linux)"
    echo "  tmux is core to AEGIS — agents communicate via tmux panes."
    exit 1
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
    "${TARGET_DIR}/_aegis-output"
    "${TARGET_DIR}/_aegis-output/reviews"
    "${TARGET_DIR}/_aegis-output/adversarial"
    "${TARGET_DIR}/_aegis-output/scans"
    "${TARGET_DIR}/_aegis-output/architecture"
    "${TARGET_DIR}/_aegis-output/design"
    "${TARGET_DIR}/_aegis-output/content"
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
standard_skills=("super-spec" "test-architect" "security-audit" "tech-debt-tracker" "sprint-tracker" "api-docs")
full_skills=("aegis-distill" "aegis-observe" "adversarial-review" "code-coverage" "retrospective" "course-correction" "skill-marketplace" "aegis-builder")

copy_skill() {
    local name="$1"
    local src="${SCRIPT_DIR}/skills/${name}.md"
    local dst="${TARGET_DIR}/skills/${name}.md"

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
echo "  │   └── retrospectives/    # Session retros"
echo "  ├── _aegis-output/         # Pipeline outputs"
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
