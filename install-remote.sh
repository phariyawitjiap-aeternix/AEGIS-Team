#!/usr/bin/env bash
# ============================================================================
# AEGIS v8.4 — Remote Installer (one-liner, no clone needed)
#
# New install:
#   cd ~/Documents/my-project && git init && git commit --allow-empty -m "init"
#   bash <(curl -sL https://raw.githubusercontent.com/phariyawitjiap-aeternix/AEGIS-Team/main/install-remote.sh) --profile full --project-name "My Project"
#
# Upgrade:
#   cd ~/Documents/my-project
#   bash <(curl -sL https://raw.githubusercontent.com/phariyawitjiap-aeternix/AEGIS-Team/main/install-remote.sh) --upgrade
# ============================================================================

set -euo pipefail

VERSION="8.4"
REPO_URL="https://github.com/phariyawitjiap-aeternix/AEGIS-Team.git"
TMP_DIR="/tmp/aegis-install-$$"
TARGET_DIR="$(pwd)"
PROFILE="standard"
PROJECT_NAME=""
UPGRADE=false
PROFILE_EXPLICIT=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; }

# Parse args
while [[ $# -gt 0 ]]; do
    case "$1" in
        --profile)      PROFILE="$2"; PROFILE_EXPLICIT=true; shift 2 ;;
        --project-name) PROJECT_NAME="$2"; shift 2 ;;
        --target-dir)   TARGET_DIR="$2"; shift 2 ;;
        --upgrade)      UPGRADE=true; shift ;;
        --help)
            echo -e "${BOLD}AEGIS v${VERSION} — Remote Installer${NC}"
            echo ""
            echo "Usage:"
            echo "  bash <(curl -sL URL) [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --profile <tier>       minimal | standard | full (default: standard)"
            echo "  --project-name <name>  Project name for brain identity"
            echo "  --target-dir <path>    Target directory (default: current dir)"
            echo "  --upgrade              Update existing install (preserve brain)"
            echo ""
            echo "Profiles:"
            echo "  minimal   7 skills  — quick tasks, small projects"
            echo "  standard  15 skills — normal development (default)"
            echo "  full      all skills — enterprise, full SDLC"
            echo ""
            echo "Examples:"
            echo "  New install:"
            echo "    cd ~/Documents/my-project && git init && git commit --allow-empty -m 'init'"
            echo "    bash <(curl -sL URL) --profile full --project-name \"My App\""
            echo ""
            echo "  Upgrade:"
            echo "    cd ~/Documents/my-project"
            echo "    bash <(curl -sL URL) --upgrade"
            exit 0
            ;;
        *) error "Unknown option: $1"; exit 1 ;;
    esac
done

# On upgrade: auto-detect existing profile from project-identity.md (unless --profile given)
if [[ "$UPGRADE" == true ]] && [[ "$PROFILE_EXPLICIT" == false ]]; then
    IDENTITY_FILE="${TARGET_DIR}/_aegis-brain/resonance/project-identity.md"
    if [[ -f "$IDENTITY_FILE" ]]; then
        DETECTED=$(grep -i "^- Profile:" "$IDENTITY_FILE" | head -1 | sed 's/.*: *//' | tr -d '[:space:]')
        if [[ "$DETECTED" == "full" || "$DETECTED" == "standard" || "$DETECTED" == "minimal" ]]; then
            PROFILE="$DETECTED"
        fi
    fi
fi

echo ""
echo -e "${CYAN}    ╔═══════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}    ║                                               ║${NC}"
echo -e "${CYAN}    ║${NC}${BOLD}${WHITE}    █████  ███████  ██████  ██  ██████     ${NC}${CYAN}║${NC}"
echo -e "${CYAN}    ║${NC}${BOLD}${WHITE}   ██   ██ ██       ██      ██ ██          ${NC}${CYAN}║${NC}"
echo -e "${CYAN}    ║${NC}${BOLD}${WHITE}   ███████ █████    ██  ███ ██  █████      ${NC}${CYAN}║${NC}"
echo -e "${CYAN}    ║${NC}${BOLD}${WHITE}   ██   ██ ██       ██   ██ ██      ██     ${NC}${CYAN}║${NC}"
echo -e "${CYAN}    ║${NC}${BOLD}${WHITE}   ██   ██ ███████   ██████ ██ ██████      ${NC}${CYAN}║${NC}"
echo -e "${CYAN}    ║                                               ║${NC}"
echo -e "${CYAN}    ╠═══════════════════╦═══════╦═══════════════════╣${NC}"
echo -e "${CYAN}    ║                   ║${NC}${BOLD}${YELLOW} ◆ ◆ ◆ ${NC}${CYAN}║                   ║${NC}"
echo -e "${CYAN}    ╚═══════════════════╩═══════╩═══════════════════╝${NC}"
echo ""
echo -e "        ${BOLD}${YELLOW}⚡  v${VERSION}  ·  13 Marvel Agents  ⚡${NC}"
echo -e "       ${CYAN} \"Context is King, Memory is Soul\"${NC}"
echo ""
if [[ "$UPGRADE" == true ]]; then
    echo -e "            ${BOLD}${GREEN}↑  UPGRADE MODE  ↑${NC}"
else
    echo -e "          ${BOLD}${GREEN}★  NEW INSTALLATION  ★${NC}"
fi
echo ""
echo ""
info "Profile: ${BOLD}${PROFILE}${NC}"
info "Target:  ${BOLD}${TARGET_DIR}${NC}"
[[ -n "$PROJECT_NAME" ]] && info "Project: ${BOLD}${PROJECT_NAME}${NC}"
if [[ "$UPGRADE" == true ]]; then
    info "Mode:    ${BOLD}UPGRADE${NC} (preserving brain)"
else
    info "Mode:    ${BOLD}NEW INSTALL${NC}"
fi
echo ""

# Pre-flight checks
info "Checking dependencies..."

if ! command -v git &>/dev/null; then
    error "git is required. Install: brew install git"
    exit 1
fi
success "git found"

if ! command -v node &>/dev/null; then
    error "Node.js is required. Install: brew install node"
    exit 1
fi
success "node found: $(node --version)"

if ! command -v claude &>/dev/null; then
    warn "Claude Code CLI not found. Install: npm install -g @anthropic-ai/claude-code"
else
    success "claude found: $(claude --version 2>&1 | head -1)"
fi

# Clone to temp
info "Downloading AEGIS v${VERSION}..."
rm -rf "$TMP_DIR"
git clone --depth 1 --quiet "$REPO_URL" "$TMP_DIR"
success "Downloaded to temp"

# ── UPGRADE: backup + remove old files ───────────────────────────────────────
if [[ "$UPGRADE" == true ]] && [[ -f "${TARGET_DIR}/CLAUDE.md" ]]; then
    BACKUP_DIR="${TARGET_DIR}/_aegis-backup/$(date +%Y%m%d-%H%M%S)"
    info "Backing up user data to ${BACKUP_DIR}..."
    mkdir -p "$BACKUP_DIR"
    cp -r "${TARGET_DIR}/_aegis-brain/"     "$BACKUP_DIR/" 2>/dev/null || true
    cp -r "${TARGET_DIR}/_aegis-output/iso-docs/" "$BACKUP_DIR/" 2>/dev/null || true
    cp    "${TARGET_DIR}/CLAUDE_lessons.md" "$BACKUP_DIR/" 2>/dev/null || true
    success "Backup complete"

    info "Removing old framework files..."
    rm -rf "${TARGET_DIR}/.claude/agents/"
    rm -rf "${TARGET_DIR}/.claude/commands/"
    rm -rf "${TARGET_DIR}/.claude/references/"
    rm -rf "${TARGET_DIR}/.claude/teams/"
    rm -rf "${TARGET_DIR}/.claude/hooks/"
    rm -f  "${TARGET_DIR}/.claude/settings.json"
    rm -rf "${TARGET_DIR}/skills/"
    rm -f  "${TARGET_DIR}/CLAUDE.md" "${TARGET_DIR}/CLAUDE_agents.md"
    rm -f  "${TARGET_DIR}/CLAUDE_safety.md" "${TARGET_DIR}/CLAUDE_skills.md"

    # Remove files deleted in v8.3
    rm -f "${TARGET_DIR}/install.sh"
    rm -f "${TARGET_DIR}/aegis-team.sh"
    rm -f "${TARGET_DIR}/GETTING_STARTED.md"
    rm -f "${TARGET_DIR}/AEGIS-v6-SPEC-v3.md"

    # Remove old merged references (v6→v8.2 era)
    for ref in review-checklist output-format progress-protocol handoff-protocol \
               auto-learn-protocol shared-intelligence skill-evolution knowledge-pipeline \
               performance-benchmark token-tracking; do
        rm -f "${TARGET_DIR}/.claude/references/${ref}.md"
    done

    success "Old files removed"
fi

# ── INSTALL FRAMEWORK FILES ───────────────────────────────────────────────────
info "Installing AEGIS framework files..."

# Core docs
cp "${TMP_DIR}/CLAUDE.md"        "${TARGET_DIR}/"
cp "${TMP_DIR}/CLAUDE_agents.md" "${TARGET_DIR}/"
cp "${TMP_DIR}/CLAUDE_safety.md" "${TARGET_DIR}/"
cp "${TMP_DIR}/CLAUDE_skills.md" "${TARGET_DIR}/"
# Preserve CLAUDE_lessons.md on upgrade
if [[ "$UPGRADE" != true ]] || [[ ! -f "${TARGET_DIR}/CLAUDE_lessons.md" ]]; then
    cp "${TMP_DIR}/CLAUDE_lessons.md" "${TARGET_DIR}/" 2>/dev/null || true
fi
success "Core docs installed"

# Agents — all 13 Marvel characters
mkdir -p "${TARGET_DIR}/.claude/agents/"
cp "${TMP_DIR}/.claude/agents/"*.md "${TARGET_DIR}/.claude/agents/"
AGENT_COUNT=$(ls "${TARGET_DIR}/.claude/agents/"*.md | wc -l | tr -d ' ')
success "${AGENT_COUNT} agents installed (Nick Fury, Iron Man, Spider-Man, Black Panther, Loki, Beast, Wasp, Songbird, War Machine, Vision, Coulson, Thor, Captain America)"

# Commands
mkdir -p "${TARGET_DIR}/.claude/commands/"
cp "${TMP_DIR}/.claude/commands/"*.md "${TARGET_DIR}/.claude/commands/"
CMD_COUNT=$(ls "${TARGET_DIR}/.claude/commands/"*.md | wc -l | tr -d ' ')
success "${CMD_COUNT} commands installed"

# References
mkdir -p "${TARGET_DIR}/.claude/references/"
cp "${TMP_DIR}/.claude/references/"*.md "${TARGET_DIR}/.claude/references/"
REF_COUNT=$(ls "${TARGET_DIR}/.claude/references/"*.md | wc -l | tr -d ' ')
success "${REF_COUNT} references installed (+ adaptive-thinking-guide, context-editing-protocol)"

# Teams
mkdir -p "${TARGET_DIR}/.claude/teams/"
cp "${TMP_DIR}/.claude/teams/"*.md "${TARGET_DIR}/.claude/teams/"
TEAM_COUNT=$(ls "${TARGET_DIR}/.claude/teams/"*.md | wc -l | tr -d ' ')
success "${TEAM_COUNT} team configs installed"

# Hooks — enforcement scripts (PreToolUse, PostToolUse, Stop)
mkdir -p "${TARGET_DIR}/.claude/hooks/"
cp "${TMP_DIR}/.claude/hooks/"*.sh "${TARGET_DIR}/.claude/hooks/" 2>/dev/null || true
cp "${TMP_DIR}/.claude/hooks/profiles.json" "${TARGET_DIR}/.claude/hooks/" 2>/dev/null || true
chmod +x "${TARGET_DIR}/.claude/hooks/"*.sh 2>/dev/null || true
HOOK_COUNT=$(ls "${TARGET_DIR}/.claude/hooks/"*.sh 2>/dev/null | wc -l | tr -d ' ')
success "${HOOK_COUNT} hooks installed (guard-bash, guard-write, post-tool-use, post-edit-accumulate, on-stop, run-with-flags, tinman-heartbeat)"

# Settings
cp "${TMP_DIR}/.claude/settings.json" "${TARGET_DIR}/.claude/" 2>/dev/null || true
success "settings.json installed"

# ── SKILLS — profile-based selection ─────────────────────────────────────────
mkdir -p "${TARGET_DIR}/skills/"

# Minimal (7): core workflow tools
minimal_skills=(
    ai-personas
    orchestrator
    code-review
    code-standards
    git-workflow
    bug-lifecycle
    project-navigator
)

# Standard (+8 = 15): adds planning, testing, quality tools
standard_skills=(
    super-spec
    test-architect
    security-audit
    tech-debt-tracker
    sprint-tracker
    kanban-board
    work-breakdown
    retrospective
)

# Full (all remaining): advanced + AEGIS-specific tools
full_skills=(
    adversarial-review
    code-coverage
    course-correction
    skill-marketplace
    aegis-builder
    aegis-distill
    aegis-observe
    aegis-doctor
    aegis-reengineer
    design-system-md
    qa-pipeline
    iso-29110-docs
    api-docs
)

copy_skills() {
    for skill in "$@"; do
        src="${TMP_DIR}/skills/${skill}.md"
        if [[ -f "$src" ]]; then
            cp "$src" "${TARGET_DIR}/skills/"
        fi
    done
}

copy_skills "${minimal_skills[@]}"
[[ "$PROFILE" == "standard" || "$PROFILE" == "full" ]] && copy_skills "${standard_skills[@]}"
[[ "$PROFILE" == "full" ]] && copy_skills "${full_skills[@]}"

SKILL_COUNT=$(ls "${TARGET_DIR}/skills/"*.md 2>/dev/null | wc -l | tr -d ' ')
success "${SKILL_COUNT} skills installed (profile: ${PROFILE})"

# ── DIRECTORY STRUCTURE ───────────────────────────────────────────────────────
info "Creating directory structure..."

# Brain
mkdir -p "${TARGET_DIR}/_aegis-brain/tasks"
mkdir -p "${TARGET_DIR}/_aegis-brain/sprints/current"
mkdir -p "${TARGET_DIR}/_aegis-brain/resonance"
mkdir -p "${TARGET_DIR}/_aegis-brain/learnings/raw"
mkdir -p "${TARGET_DIR}/_aegis-brain/skill-cache"
mkdir -p "${TARGET_DIR}/_aegis-brain/metrics"
mkdir -p "${TARGET_DIR}/_aegis-brain/logs"
mkdir -p "${TARGET_DIR}/_aegis-brain/handoffs"
mkdir -p "${TARGET_DIR}/_aegis-brain/backlog"
mkdir -p "${TARGET_DIR}/_aegis-brain/retrospectives"
mkdir -p "${TARGET_DIR}/_aegis-brain/instincts/pending"
mkdir -p "${TARGET_DIR}/_aegis-brain/instincts/active"
mkdir -p "${TARGET_DIR}/_aegis-brain/instincts/promoted"
mkdir -p "${TARGET_DIR}/_aegis-brain/instincts/retired"

# Output
mkdir -p "${TARGET_DIR}/_aegis-output/specs"
mkdir -p "${TARGET_DIR}/_aegis-output/breakdown"
mkdir -p "${TARGET_DIR}/_aegis-output/qa/results"
mkdir -p "${TARGET_DIR}/_aegis-output/reviews"
mkdir -p "${TARGET_DIR}/_aegis-output/research"
mkdir -p "${TARGET_DIR}/_aegis-output/sessions"
mkdir -p "${TARGET_DIR}/_aegis-output/deployments"
mkdir -p "${TARGET_DIR}/_aegis-output/architecture/archive"
mkdir -p "${TARGET_DIR}/_aegis-output/design"
mkdir -p "${TARGET_DIR}/_aegis-output/adversarial"

# ISO docs — BLOCK 0 required directories
mkdir -p "${TARGET_DIR}/_aegis-output/iso-docs/PM-01-project-plan"
mkdir -p "${TARGET_DIR}/_aegis-output/iso-docs/PM-02-progress-status"
mkdir -p "${TARGET_DIR}/_aegis-output/iso-docs/PM-03-change-requests"
mkdir -p "${TARGET_DIR}/_aegis-output/iso-docs/PM-04-meeting-records"
mkdir -p "${TARGET_DIR}/_aegis-output/iso-docs/PM-05-correction-register"
mkdir -p "${TARGET_DIR}/_aegis-output/iso-docs/PM-06-acceptance-record"
mkdir -p "${TARGET_DIR}/_aegis-output/iso-docs/SI-01-requirements-spec"
mkdir -p "${TARGET_DIR}/_aegis-output/iso-docs/SI-02-traceability-matrix"
mkdir -p "${TARGET_DIR}/_aegis-output/iso-docs/SI-03-design-doc"
mkdir -p "${TARGET_DIR}/_aegis-output/iso-docs/SI-04-test-cases"
mkdir -p "${TARGET_DIR}/_aegis-output/iso-docs/SI-05-test-report"
mkdir -p "${TARGET_DIR}/_aegis-output/iso-docs/SI-06-delivery"

success "Directory structure created"

# ── INITIALIZE FILES ──────────────────────────────────────────────────────────

# counters.json
if [[ ! -f "${TARGET_DIR}/_aegis-brain/counters.json" ]]; then
    cat > "${TARGET_DIR}/_aegis-brain/counters.json" << 'COUNTERS'
{
  "project_key": "PROJ",
  "counters": {"US":0,"J":0,"E":0,"T":0,"ST":0,"DOC":0,"ADR":0,"TD":0,"REL":0,"HO":0},
  "last_updated": "2026-01-01T00:00:00"
}
COUNTERS
    success "counters.json initialized"
fi

# activity.log
if [[ ! -f "${TARGET_DIR}/_aegis-brain/logs/activity.log" ]]; then
    echo "# AEGIS Activity Log — Append Only" > "${TARGET_DIR}/_aegis-brain/logs/activity.log"
    echo "# Format: [ISO-8601] [AGENT] [STATUS] — [message]" >> "${TARGET_DIR}/_aegis-brain/logs/activity.log"
    echo "# ---" >> "${TARGET_DIR}/_aegis-brain/logs/activity.log"
    success "activity.log initialized"
fi

# project-identity.md — create on new install, update version+profile on upgrade
IDENTITY_FILE="${TARGET_DIR}/_aegis-brain/resonance/project-identity.md"
if [[ ! -f "$IDENTITY_FILE" ]] && [[ -n "$PROJECT_NAME" ]]; then
    cat > "$IDENTITY_FILE" << IDENTITY
# Project Identity
- Name: ${PROJECT_NAME}
- Created: $(date +%Y-%m-%d)
- Framework: AEGIS v${VERSION}
- Agents: 13 Marvel characters
- Profile: ${PROFILE}
IDENTITY
    success "Project identity created"
elif [[ -f "$IDENTITY_FILE" ]] && [[ "$UPGRADE" == true ]]; then
    # Update version and profile in existing identity file
    sed -i.bak "s/^- Framework: .*/- Framework: AEGIS v${VERSION}/" "$IDENTITY_FILE"
    sed -i.bak "s/^- Profile: .*/- Profile: ${PROFILE}/" "$IDENTITY_FILE"
    rm -f "${IDENTITY_FILE}.bak"
    success "Project identity updated (v${VERSION}, profile: ${PROFILE})"
fi

# .gitignore
if [[ ! -f "${TARGET_DIR}/.gitignore" ]]; then
    cat > "${TARGET_DIR}/.gitignore" << 'GITIGNORE'
_aegis-output/
_aegis-backup/
.env
.env.*
*.key
*.pem
*secret*
.DS_Store
node_modules/
__pycache__/
*.log
!_aegis-brain/logs/activity.log
GITIGNORE
    success ".gitignore created"
fi

# Git init if needed
if [[ ! -d "${TARGET_DIR}/.git" ]]; then
    cd "${TARGET_DIR}" && git init --quiet
    success "Git repository initialized"
fi

# Cleanup
rm -rf "$TMP_DIR"
success "Temp files cleaned up"

# ── SUMMARY ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}================================================${NC}"
echo -e "${BOLD}${GREEN}  AEGIS v${VERSION} — Installation Complete!${NC}"
echo -e "${BOLD}${GREEN}================================================${NC}"
echo ""
echo -e "  ${BOLD}Profile:${NC}   ${PROFILE}"
[[ -n "$PROJECT_NAME" ]] && echo -e "  ${BOLD}Project:${NC}   ${PROJECT_NAME}"
echo -e "  ${BOLD}Location:${NC}  ${TARGET_DIR}"
echo -e "  ${BOLD}Agents:${NC}    ${AGENT_COUNT} Marvel characters"
echo -e "  ${BOLD}Skills:${NC}    ${SKILL_COUNT}"
echo -e "  ${BOLD}Commands:${NC}  ${CMD_COUNT}"
echo ""

if [[ "$UPGRADE" == true ]]; then
    echo -e "${BOLD}What's new in v8.4:${NC}"
    echo "  ${BOLD}4 ECC patterns adopted:${NC}"
    echo "  • Runtime hook profile switching (AEGIS_HOOK_PROFILE=minimal|standard|strict)"
    echo "  • Batched Stop-time format/typecheck (10 edits = 1 tsc run)"
    echo "  • Config protection hook (blocks .eslintrc/biome/tsconfig edits)"
    echo "  • Instinct lifecycle — confidence-scored learned patterns"
    echo "    (pending → active → promoted → retired)"
    echo ""
    echo "  ${BOLD}5 VoltAgent/awesome-design-md patterns adopted:${NC}"
    echo "  • DESIGN.md 9-section visual design system (new skill, Wasp-owned)"
    echo "  • Do's/Don'ts mandatory in every spec (Loki-enforced)"
    echo "  • Agent Prompt Guide footer on every master spec"
    echo "  • Locked H2 skeletons for all ISO 29110 docs"
    echo "  • Matrix tables + soul paragraphs in Iron Man specs"
    echo ""
    echo "  ${BOLD}New commands:${NC} /aegis-instinct  /aegis-evolve"
    echo "  ${BOLD}New skill:${NC}    design-system-md (full profile only)"
    echo "  ${BOLD}New hooks:${NC}    guard-write, post-edit-accumulate, run-with-flags"
    echo ""
    echo -e "  ${BOLD}Previous (v8.3):${NC} Marvel rename, BLOCK 0 gate, 6-gate quality,"
    echo "                    /aegis-doctor, /aegis-reengineer, ultrathink"
    echo ""
fi

echo -e "${BOLD}Next steps:${NC}"
echo "  cd ${TARGET_DIR}"
echo "  claude --dangerously-skip-permissions"
if [[ "$UPGRADE" == true ]]; then
    echo "  > /aegis-doctor      ← verify upgrade"
fi
echo "  > /aegis-start"
echo ""
echo -e "${CYAN}Happy building! — AEGIS v${VERSION} · 13 Marvel Agents · Claude 4.x · 9 Global Patterns${NC}"
