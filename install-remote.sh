#!/usr/bin/env bash
# ============================================================================
# AEGIS v15.0 — Remote Installer (one-liner, no clone needed)
#
# One-command new project (recommended):
#   cd ~/Documents
#   bash <(curl -sL https://raw.githubusercontent.com/phariyawitjiap-aeternix/AEGIS-Team/main/install-remote.sh) \
#       --new influencer-creator
#
#   ↑ creates ./influencer-creator/, git init, installs framework, bootstraps
#     Linear (if token available), registers multi-tenant, runs doctor — all
#     in one shot. No local AEGIS-Team checkout needed.
#
# Manual new install (existing dir):
#   cd ~/Documents/my-project && git init
#   bash <(curl -sL .../install-remote.sh) --profile full --project-name "My App"
#
# Upgrade:
#   cd ~/Documents/my-project
#   bash <(curl -sL .../install-remote.sh) --upgrade
# ============================================================================

set -euo pipefail

# VERSION is set after git clone (read from VERSION file in repo).
# Initial value used for early "Downloading AEGIS v..." message before clone.
VERSION="(loading…)"
REPO_URL="https://github.com/phariyawitjiap-aeternix/AEGIS-Team.git"
TMP_DIR="/tmp/aegis-install-$$"
TARGET_DIR="$(pwd)"
PROFILE="standard"
PROJECT_NAME=""
UPGRADE=false
PROFILE_EXPLICIT=false

# v15.1 — one-command setup additions
NEW_PROJECT_SLUG=""    # if set, create dir, init git, full setup
DO_LINEAR=auto         # auto | true | false  (auto = run if token available)
DO_MT=auto             # auto | true | false  (auto = run if mt.mjs installed)
DO_DOCTOR=true         # always run post-install verification

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; }

# Parse args
while [[ $# -gt 0 ]]; do
    case "$1" in
        --new)            NEW_PROJECT_SLUG="$2"; shift 2 ;;
        --profile)        PROFILE="$2"; PROFILE_EXPLICIT=true; shift 2 ;;
        --project-name)   PROJECT_NAME="$2"; shift 2 ;;
        --target-dir)     TARGET_DIR="$2"; shift 2 ;;
        --upgrade)        UPGRADE=true; shift ;;
        --with-linear)    DO_LINEAR=true; shift ;;
        --no-linear)      DO_LINEAR=false; shift ;;
        --with-mt|--with-multi-tenant)
                          DO_MT=true; shift ;;
        --no-mt|--no-multi-tenant)
                          DO_MT=false; shift ;;
        --no-doctor)      DO_DOCTOR=false; shift ;;
        --help)
            echo -e "${BOLD}AEGIS v${VERSION} — Remote Installer${NC}"
            echo ""
            echo "One-command new project (recommended):"
            echo "  cd ~/Documents"
            echo "  bash <(curl -sL URL) --new <project-slug>"
            echo ""
            echo "Options:"
            echo "  --new <slug>           Create new project: mkdir + git init + full setup"
            echo "  --profile <tier>       minimal | standard | full (default: standard)"
            echo "  --project-name <name>  Project display name (default: title-cased slug)"
            echo "  --target-dir <path>    Target directory (default: current dir)"
            echo "  --upgrade              Update existing install (preserve brain)"
            echo "  --with-linear          Force Linear bootstrap (default: auto if token)"
            echo "  --no-linear            Skip Linear bootstrap"
            echo "  --with-mt              Force multi-tenant registration"
            echo "  --no-mt                Skip multi-tenant registration"
            echo "  --no-doctor            Skip post-install verification"
            echo ""
            echo "Profiles:"
            echo "  minimal   7 skills  — quick tasks, small projects"
            echo "  standard  15 skills — normal development (default)"
            echo "  full      all skills — enterprise, full SDLC"
            echo ""
            echo "Examples:"
            echo "  One-command new project:"
            echo "    bash <(curl -sL URL) --new influencer-creator"
            echo ""
            echo "  New install (existing empty dir):"
            echo "    cd ~/Documents/my-project && git init"
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

# ── --new mode: create dir, set names, prep for full setup ──────────────────
if [[ -n "$NEW_PROJECT_SLUG" ]]; then
    # Validate slug (URL-safe, kebab-case)
    if [[ ! "$NEW_PROJECT_SLUG" =~ ^[a-z0-9][a-z0-9-]*[a-z0-9]$ ]] && [[ ${#NEW_PROJECT_SLUG} -gt 1 ]]; then
        error "--new requires a kebab-case slug (a-z, 0-9, hyphens). Got: '$NEW_PROJECT_SLUG'"
        exit 1
    fi
    # Resolve target dir relative to CWD (where the user ran the installer)
    if [[ "$TARGET_DIR" == "$(pwd)" ]]; then
        TARGET_DIR="$(pwd)/$NEW_PROJECT_SLUG"
    fi
    # Create + cd
    mkdir -p "$TARGET_DIR"
    cd "$TARGET_DIR"
    TARGET_DIR="$(pwd)"
    # Title-case the slug for PROJECT_NAME (foo-bar-baz → Foo Bar Baz)
    if [[ -z "$PROJECT_NAME" ]]; then
        PROJECT_NAME="$(printf '%s' "$NEW_PROJECT_SLUG" | tr '-_' '  ' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2)); print}')"
    fi
fi

# On upgrade: auto-detect existing profile from project-identity.md (unless --profile given)
if [[ "$UPGRADE" == true ]] && [[ "$PROFILE_EXPLICIT" == false ]]; then
    # Prefer v9 path; fall back to v8 for legacy installs mid-migration.
    IDENTITY_FILE="${TARGET_DIR}/.aegis/brain/resonance/project-identity.md"
    [[ ! -f "$IDENTITY_FILE" ]] && IDENTITY_FILE="${TARGET_DIR}/_aegis-brain/resonance/project-identity.md"
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
echo -e "        ${BOLD}${YELLOW}⚡  v${VERSION}  ·  10 Marvel Agents  ⚡${NC}"
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
info "Downloading AEGIS..."
rm -rf "$TMP_DIR"
git clone --depth 1 --quiet "$REPO_URL" "$TMP_DIR"
# Read VERSION from cloned repo (single source of truth, S1-01)
if [[ -f "${TMP_DIR}/VERSION" ]]; then
    VERSION="$(cat "${TMP_DIR}/VERSION" | tr -d '[:space:]')"
fi
success "Downloaded AEGIS v${VERSION}"

# ── UPGRADE: backup + remove old files ───────────────────────────────────────
if [[ "$UPGRADE" == true ]] && [[ -f "${TARGET_DIR}/CLAUDE.md" ]]; then
    BACKUP_DIR="${TARGET_DIR}/_aegis-backup/$(date +%Y%m%d-%H%M%S)"
    info "Backing up user data to ${BACKUP_DIR}..."
    mkdir -p "$BACKUP_DIR"
    # Back up both legacy and v9 brain paths so rollback works regardless of state.
    cp -r "${TARGET_DIR}/_aegis-brain/"     "$BACKUP_DIR/" 2>/dev/null || true
    cp -r "${TARGET_DIR}/.aegis/brain/"     "$BACKUP_DIR/aegis-brain/" 2>/dev/null || true
    cp -r "${TARGET_DIR}/_aegis-output/iso-docs/" "$BACKUP_DIR/" 2>/dev/null || true
    cp    "${TARGET_DIR}/CLAUDE_lessons.md" "$BACKUP_DIR/" 2>/dev/null || true
    # v8 settings.json side-copy so the user can diff against v9's scoped model.
    cp    "${TARGET_DIR}/.claude/settings.json" "$BACKUP_DIR/settings.json.v8" 2>/dev/null || true
    success "Backup complete"

    # v8 -> v9 auto-migration of brain path. Move the tree BEFORE install
    # reshapes the rest of the repo so brain-relative writes land in the
    # right spot from step one. Original preserved in $BACKUP_DIR.
    if [[ -d "${TARGET_DIR}/_aegis-brain" ]] && [[ ! -d "${TARGET_DIR}/.aegis/brain" ]]; then
        info "v8 brain detected at _aegis-brain/ -- auto-migrating to .aegis/brain/"
        mkdir -p "${TARGET_DIR}/.aegis"
        # Copy (not move) so the backup still has the original on disk if
        # the user wants to diff or roll back without touching $BACKUP_DIR.
        cp -r "${TARGET_DIR}/_aegis-brain" "${TARGET_DIR}/.aegis/brain"
        # Remove the v8 tree once the copy is verified by presence of a known file.
        if [[ -f "${TARGET_DIR}/.aegis/brain/resonance/project-identity.md" ]] \
          || [[ -d "${TARGET_DIR}/.aegis/brain/resonance" ]]; then
            rm -rf "${TARGET_DIR}/_aegis-brain"
            success "Brain migrated to .aegis/brain/ (v8 path removed; backup retained)"
        else
            # Sanity-check failed -- leave both in place, let the user decide.
            info "Migration copy made but identity check failed; keeping _aegis-brain/ in place"
        fi
    elif [[ -d "${TARGET_DIR}/_aegis-brain" ]] && [[ -d "${TARGET_DIR}/.aegis/brain" ]]; then
        info "Both _aegis-brain/ and .aegis/brain/ present; leaving both untouched"
        info "After install, verify .aegis/brain/ is complete and remove _aegis-brain/ manually"
    fi

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
# Preserve CLAUDE_lessons.md on upgrade -- this is a user-accumulated file.
# BUT v8 versions contain patterns referencing _aegis-brain/* subpaths that
# instruct agents to write to the legacy location. Without patching, agents
# keep creating _aegis-brain/ orphans post-migration. Fix: sed-in-place
# substitute the 8 known brain subpath patterns. Safe because the
# transformation is lossless (v8 path -> v9 path; no content deletion).
if [[ "$UPGRADE" != true ]] || [[ ! -f "${TARGET_DIR}/CLAUDE_lessons.md" ]]; then
    cp "${TMP_DIR}/CLAUDE_lessons.md" "${TARGET_DIR}/" 2>/dev/null || true
elif [[ "$UPGRADE" == true ]] && [[ -f "${TARGET_DIR}/CLAUDE_lessons.md" ]]; then
    # Detect + patch stale v8 brain path refs without clobbering user content
    if grep -q "_aegis-brain/" "${TARGET_DIR}/CLAUDE_lessons.md" 2>/dev/null; then
        info "Patching stale _aegis-brain/ refs in CLAUDE_lessons.md -> .aegis/brain/..."
        cp "${TARGET_DIR}/CLAUDE_lessons.md" "$BACKUP_DIR/CLAUDE_lessons.md.pre-patch" 2>/dev/null || true
        for sub in resonance handoffs learnings tasks sprints retrospectives instincts logs state; do
            sed -i.bak "s|_aegis-brain/${sub}/|.aegis/brain/${sub}/|g" "${TARGET_DIR}/CLAUDE_lessons.md"
        done
        rm -f "${TARGET_DIR}/CLAUDE_lessons.md.bak"
        REMAINING=$(grep -c "_aegis-brain/" "${TARGET_DIR}/CLAUDE_lessons.md" 2>/dev/null || echo "0")
        if [[ "$REMAINING" == "0" ]]; then
            success "CLAUDE_lessons.md path refs migrated to v9 (backup: \$BACKUP_DIR/CLAUDE_lessons.md.pre-patch)"
        else
            info "CLAUDE_lessons.md still contains ${REMAINING} _aegis-brain/ refs (non-path mentions -- left intact)"
        fi
    fi
fi
# VERSION file -- pin the installed AEGIS version so session-start hook can
# detect drift. Always overwrite on install/upgrade because VERSION tracks
# the installed framework, not project state.
if [[ -f "${TMP_DIR}/VERSION" ]]; then
    cp "${TMP_DIR}/VERSION" "${TARGET_DIR}/VERSION"
fi
success "Core docs + VERSION file installed"

# Agents — 10 active Marvel characters (v9 consolidation: Vision -> War Machine,
# Songbird -> Coulson, Wasp retired). Archived prompts preserved under _archived/.
mkdir -p "${TARGET_DIR}/.claude/agents/"
cp "${TMP_DIR}/.claude/agents/"*.md "${TARGET_DIR}/.claude/agents/" 2>/dev/null || true
if [[ -d "${TMP_DIR}/.claude/agents/_archived" ]]; then
    mkdir -p "${TARGET_DIR}/.claude/agents/_archived"
    cp "${TMP_DIR}/.claude/agents/_archived/"*.md "${TARGET_DIR}/.claude/agents/_archived/" 2>/dev/null || true
fi
# v15-13 fix: `ls glob 2>/dev/null` exits non-zero when the glob doesn't
# expand (no matching files); under `set -e` + `pipefail` this aborts the
# script silently. `|| echo 0` makes the pipeline always succeed.
AGENT_COUNT=$(ls "${TARGET_DIR}/.claude/agents/"*.md 2>/dev/null | wc -l | tr -d ' ' || echo 0)
ARCHIVED_COUNT=$(ls "${TARGET_DIR}/.claude/agents/_archived/"*.md 2>/dev/null | wc -l | tr -d ' ' || echo 0)
success "${AGENT_COUNT} active agents installed (Nick Fury, Iron Man, Spider-Man, Black Panther, Loki, Beast, War Machine, Thor, Coulson, Captain America) + ${ARCHIVED_COUNT} archived in _archived/"

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
HOOK_COUNT=$(ls "${TARGET_DIR}/.claude/hooks/"*.sh 2>/dev/null | wc -l | tr -d ' ' || echo 0)
success "${HOOK_COUNT} hooks installed (guard-bash, guard-write, session-start, aegis-version-check, post-tool-use, post-edit-accumulate, on-stop, run-with-flags, tinman-heartbeat)"

# Settings
cp "${TMP_DIR}/.claude/settings.json" "${TARGET_DIR}/.claude/" 2>/dev/null || true
success "settings.json installed"

# ── HELPER TOOLS — tools/aegis-*.sh (new in v9, was missing from installer) ──
# These ship the real v9 behavior: brain sync/write, maintainer grant, BLOCK 0
# mode determiner, worktree merge, test suites, status dashboard, etc.
# Without them, the target project has v9 VERSION but none of the v9 behaviors.
mkdir -p "${TARGET_DIR}/tools/"
cp "${TMP_DIR}/tools/aegis-"*.sh "${TARGET_DIR}/tools/" 2>/dev/null || true
chmod +x "${TARGET_DIR}/tools/aegis-"*.sh 2>/dev/null || true
TOOL_COUNT=$(ls "${TARGET_DIR}/tools/aegis-"*.sh 2>/dev/null | wc -l | tr -d ' ' || echo 0)
success "${TOOL_COUNT} helper tools installed (aegis-brain-sync, aegis-brain-write, aegis-maintainer-grant, aegis-block0-mode, aegis-merge-worktree, aegis-test-all, aegis-pending-items, aegis-agent-tools-matrix, aegis-distill-reset, ...)"

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

SKILL_COUNT=$(ls "${TARGET_DIR}/skills/"*.md 2>/dev/null | wc -l | tr -d ' ' || echo 0)
success "${SKILL_COUNT} skills installed (profile: ${PROFILE})"

# ── DIRECTORY STRUCTURE ───────────────────────────────────────────────────────
info "Creating directory structure..."

# Brain (v9 single-folder layout: .aegis/brain/)
mkdir -p "${TARGET_DIR}/.aegis/brain/tasks"
mkdir -p "${TARGET_DIR}/.aegis/brain/sprints/current"
mkdir -p "${TARGET_DIR}/.aegis/brain/resonance"
mkdir -p "${TARGET_DIR}/.aegis/brain/learnings/raw"
mkdir -p "${TARGET_DIR}/.aegis/brain/skill-cache"
mkdir -p "${TARGET_DIR}/.aegis/brain/metrics"
mkdir -p "${TARGET_DIR}/.aegis/brain/logs"
mkdir -p "${TARGET_DIR}/.aegis/brain/handoffs"
mkdir -p "${TARGET_DIR}/.aegis/brain/backlog"
mkdir -p "${TARGET_DIR}/.aegis/brain/retrospectives"
mkdir -p "${TARGET_DIR}/.aegis/brain/state"
mkdir -p "${TARGET_DIR}/.aegis/brain/state/maintainer-grants"
mkdir -p "${TARGET_DIR}/.aegis/brain/instincts/pending"
mkdir -p "${TARGET_DIR}/.aegis/brain/instincts/active"
mkdir -p "${TARGET_DIR}/.aegis/brain/instincts/promoted"
mkdir -p "${TARGET_DIR}/.aegis/brain/instincts/retired"

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
if [[ ! -f "${TARGET_DIR}/.aegis/brain/counters.json" ]]; then
    cat > "${TARGET_DIR}/.aegis/brain/counters.json" << 'COUNTERS'
{
  "project_key": "PROJ",
  "counters": {"US":0,"J":0,"E":0,"T":0,"ST":0,"DOC":0,"ADR":0,"TD":0,"REL":0,"HO":0},
  "last_updated": "2026-01-01T00:00:00"
}
COUNTERS
    success "counters.json initialized"
fi

# activity.log
if [[ ! -f "${TARGET_DIR}/.aegis/brain/logs/activity.log" ]]; then
    echo "# AEGIS Activity Log — Append Only" > "${TARGET_DIR}/.aegis/brain/logs/activity.log"
    echo "# Format: [ISO-8601] [AGENT] [STATUS] — [message]" >> "${TARGET_DIR}/.aegis/brain/logs/activity.log"
    echo "# ---" >> "${TARGET_DIR}/.aegis/brain/logs/activity.log"
    success "activity.log initialized"
fi

# project-identity.md — create on new install, update version+profile on upgrade.
# Prefer v9 path; fall back to v8 only if v9 doesn't exist (mid-migration edge case).
IDENTITY_FILE="${TARGET_DIR}/.aegis/brain/resonance/project-identity.md"
[[ ! -f "$IDENTITY_FILE" ]] && [[ -f "${TARGET_DIR}/_aegis-brain/resonance/project-identity.md" ]] \
    && IDENTITY_FILE="${TARGET_DIR}/_aegis-brain/resonance/project-identity.md"
if [[ ! -f "$IDENTITY_FILE" ]] && [[ -n "$PROJECT_NAME" ]]; then
    # New install path -- no identity file exists yet, create at v9 location
    IDENTITY_FILE="${TARGET_DIR}/.aegis/brain/resonance/project-identity.md"
    cat > "$IDENTITY_FILE" << IDENTITY
# Project Identity
- Name: ${PROJECT_NAME}
- Created: $(date +%Y-%m-%d)
- Framework: AEGIS v${VERSION}
- Agents: 10 Marvel characters (v9 consolidation)
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

# .gitignore -- create fresh on new install; patch missing v9 patterns on upgrade.
if [[ ! -f "${TARGET_DIR}/.gitignore" ]]; then
    cat > "${TARGET_DIR}/.gitignore" << 'GITIGNORE'
_aegis-output/
_aegis-backup/
.aegis/brain/logs/
.aegis/brain/state/
.claude/settings.json.v8-backup
.claude/worktrees/
.env
.env.*
*.key
*.pem
*secret*
.DS_Store
node_modules/
__pycache__/
*.log
!.aegis/brain/logs/activity.log
GITIGNORE
    success ".gitignore created"
elif [[ "$UPGRADE" == true ]]; then
    # Ensure v9-specific patterns are present. Append only what's missing so
    # we don't clobber project-specific entries the user added.
    GI="${TARGET_DIR}/.gitignore"
    for pat in "_aegis-backup/" ".aegis/brain/logs/" ".aegis/brain/state/" ".claude/settings.json.v8-backup" ".claude/worktrees/"; do
        if ! grep -qxF "$pat" "$GI"; then
            echo "$pat" >> "$GI"
        fi
    done
    success ".gitignore patched with v9 patterns (existing entries preserved)"
fi

# Git init if needed
if [[ ! -d "${TARGET_DIR}/.git" ]]; then
    cd "${TARGET_DIR}" && git init --quiet
    success "Git repository initialized"
fi

# Cleanup
rm -rf "$TMP_DIR"
success "Temp files cleaned up"

# ── POST-INSTALL: Linear, multi-tenant, doctor ───────────────────────────────
# Skip for upgrades (existing project has these wired already).
# Defaults: DO_LINEAR=auto, DO_MT=auto, DO_DOCTOR=true.
LINEAR_STATUS=""
MT_STATUS=""

if [[ "$UPGRADE" != true ]]; then
    # Linear bootstrap — runs if --with-linear set, or auto-detected token available
    if [[ "$DO_LINEAR" != "false" ]] && [[ -f "${TARGET_DIR}/tools/aegis-linear-bootstrap.sh" ]]; then
        # Auto-detect: keychain has aegis-linear-token, OR env LINEAR_API_KEY, OR dotfile exists
        TOKEN_FOUND=false
        if security find-generic-password -s aegis-linear-token -a phariyawit -w >/dev/null 2>&1; then
            TOKEN_FOUND=true
        elif [[ -n "${LINEAR_API_KEY:-}" ]]; then
            TOKEN_FOUND=true
        elif [[ -f "$HOME/.aegis-linear-token" ]]; then
            TOKEN_FOUND=true
        fi

        if [[ "$DO_LINEAR" == "true" ]] || [[ "$TOKEN_FOUND" == "true" ]]; then
            info "Bootstrapping Linear project..."
            if bash "${TARGET_DIR}/tools/aegis-linear-bootstrap.sh" >/dev/null 2>&1; then
                LINEAR_STATUS="✓ Linear bootstrapped"
                success "Linear bootstrapped"
            else
                LINEAR_STATUS="⚠ Linear skipped (run 'bash tools/aegis-linear-bootstrap.sh' later)"
                warn "Linear bootstrap failed — run manually later if needed"
            fi
        else
            LINEAR_STATUS="⊘ Linear skipped (no token detected — set up later if desired)"
            info "Linear skipped — no token detected. Run later: bash tools/aegis-linear-bootstrap.sh"
        fi
    fi

    # Multi-tenant registration — runs if --with-mt or mt.mjs is present
    if [[ "$DO_MT" != "false" ]] && [[ -f "${TARGET_DIR}/tools/aegis-multi-tenant/mt.mjs" ]]; then
        SLUG="${NEW_PROJECT_SLUG:-$(basename "$TARGET_DIR" | tr '[:upper:]' '[:lower:]' | tr '_' '-')}"
        # Skip if already registered
        if node "${TARGET_DIR}/tools/aegis-multi-tenant/mt.mjs" where "$SLUG" >/dev/null 2>&1; then
            MT_STATUS="✓ Multi-tenant already registered as '$SLUG'"
            info "Multi-tenant already registered as '$SLUG'"
        else
            if node "${TARGET_DIR}/tools/aegis-multi-tenant/mt.mjs" register \
                --path "$TARGET_DIR" --name "$SLUG" >/dev/null 2>&1; then
                MT_STATUS="✓ Multi-tenant registered as '$SLUG'"
                success "Registered with multi-tenant as '$SLUG' (use: mt run $SLUG)"
            else
                MT_STATUS="⚠ Multi-tenant registration failed (run manually later)"
                warn "Multi-tenant registration failed — run later: node tools/aegis-multi-tenant/mt.mjs register --path . --name $SLUG"
            fi
        fi
    fi
fi

# Doctor — verify all hook + settings references resolve
if [[ "$DO_DOCTOR" == "true" ]] && [[ -f "${TARGET_DIR}/tools/aegis-doctor.sh" ]]; then
    info "Running post-install verification..."
    if bash "${TARGET_DIR}/tools/aegis-doctor.sh" "$TARGET_DIR" >/dev/null 2>&1; then
        success "Doctor: all references resolve ✓"
    else
        warn "Doctor found orphans — run 'bash tools/aegis-doctor.sh' for details"
    fi
fi

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
    # Use printf (or echo -e) so ${BOLD}/${NC} escape codes render, not print literally.
    printf "%b\n" "${BOLD}What's new in v9.0 (vs v8.4):${NC}"
    printf "%b\n" "  ${BOLD}Agent consolidation (13 → 10):${NC}"
    echo "  • Vision merged into War Machine (QA Lead + Executor combined)"
    echo "  • Songbird absorbed by Coulson (content role merged with compliance docs)"
    echo "  • Wasp retired (UX tasks → Spider-Man + style guide)"
    echo "  • Archived agent prompts preserved in .claude/agents/_archived/"
    echo ""
    printf "%b\n" "  ${BOLD}Brain consolidation + Tier 1 memory layer:${NC}"
    echo "  • New home: .aegis/brain/ (single folder, easy uninstall)"
    echo "  • tools/aegis-brain-sync.sh regenerates MEMORY.md index"
    echo "  • tools/aegis-brain-write.sh atomic write + S4-02 proxy directive"
    echo "  • Session-start hook combines version check + brain sync"
    echo "  • AUTO-MIGRATION: _aegis-brain/ copied to .aegis/brain/ during upgrade"
    echo ""
    printf "%b\n" "  ${BOLD}Worktree isolation (Sprint v9-05):${NC}"
    echo "  • tools/aegis-merge-worktree.sh with stale-ancestor rebase"
    echo "  • Spider-Man default: isolation=worktree for code edits"
    echo ""
    printf "%b\n" "  ${BOLD}ADR-004: AEGIS_MAINTAINER_MODE override channel:${NC}"
    echo "  • tools/aegis-maintainer-grant.sh (human-run, one-shot, 60s TTL)"
    echo "  • guard-write honors valid grants; guard-bash blocks agent self-grants"
    echo ""
    printf "%b\n" "  ${BOLD}BLOCK 0 lite mode (Sprint v9-02):${NC}"
    echo "  • tools/aegis-block0-mode.sh branches lite/standard/full per task"
    echo "  • 1pt chores skip SI.01/SI.02; security/features force full gate"
    echo ""
    printf "%b\n" "  ${BOLD}Hardened permissions (Sprint v9-01):${NC}"
    echo "  • defaultMode acceptEdits (was bypassPermissions)"
    echo "  • 26 deny patterns (was 8), 20 scoped allow (was 60+ wildcards)"
    echo ""
    printf "%b\n" "  ${BOLD}New ops tools:${NC} aegis-test-all,"
    echo "                    aegis-agent-tools-matrix, aegis-pending-items,"
    echo "                    aegis-distill-reset, aegis-block0-mode"
    echo ""
    printf "%b\n" "  ${YELLOW}${BOLD}UPGRADE CHECKLIST (v8 → v9):${NC}"
    echo "    1. Review .claude/settings.json changes"
    echo "       (v8 version backed up to ${BACKUP_DIR:-_aegis-backup/...}/settings.json.v8)"
    echo "    2. Vision/Wasp/Songbird references in your custom specs still work"
    echo "       (agent files moved to _archived/, not deleted)"
    echo "    3. Brain auto-migrated: _aegis-brain/ -> .aegis/brain/"
    echo "       (if both paths still exist, verify .aegis/brain/ is complete"
    echo "        then: rm -rf _aegis-brain)"
    echo "    4. Run /aegis-doctor after upgrade to verify all 10 agents load"
    echo "    5. First /aegis-start will populate brain resonance + re-scan"
    echo "    6. Backup _aegis-backup/<timestamp>/ is gitignored -- keep for rollback"
    echo "       or delete manually when confident"
    echo ""
fi

# Post-install status (only on new install)
if [[ "$UPGRADE" != true ]]; then
    [[ -n "$LINEAR_STATUS" ]] && echo -e "  ${BOLD}Linear:${NC}    ${LINEAR_STATUS}"
    [[ -n "$MT_STATUS" ]] && echo -e "  ${BOLD}Multi-tenant:${NC} ${MT_STATUS}"
    echo ""
fi

echo -e "${BOLD}Next steps:${NC}"
if [[ -n "$NEW_PROJECT_SLUG" ]]; then
    echo "  cd ${TARGET_DIR}"
    echo "  claude              ← open Claude Code in this project"
    echo "  > /aegis-start      ← Nick Fury takes over"
elif [[ "$UPGRADE" == true ]]; then
    echo "  > /aegis-verify --doctor   ← verify upgrade (16 commands, 11 agents)"
    echo "  > /aegis-start"
else
    echo "  cd ${TARGET_DIR}"
    echo "  claude"
    echo "  > /aegis-start"
fi
echo ""
echo -e "${CYAN}Happy building! — AEGIS v${VERSION} · 11 Marvel Agents · 16 commands · CC 2.1.141 ready${NC}"
