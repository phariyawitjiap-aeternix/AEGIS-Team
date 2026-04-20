#!/usr/bin/env bash
# =============================================================================
# aegis-migrate-v9.sh
# AEGIS v8.x -> v9 umbrella migration (S14-01 implementation)
# =============================================================================
# Orchestrates all v9 migration steps:
#   1. Folder consolidation (_aegis-brain/ -> .aegis/brain/)
#   2. Settings hardening (bypassPermissions -> acceptEdits)  [manual]
#   3. CLAUDE_*.md lift (5 files -> plugin)                    [requires plugin]
#   4. Plugin install                                          [requires plugin SDK]
#
# Usage:
#   ./tools/aegis-migrate-v9.sh                  # dry-run (default)
#   ./tools/aegis-migrate-v9.sh --apply          # apply all available steps
#   ./tools/aegis-migrate-v9.sh --apply --step consolidate  # specific step
#   ./tools/aegis-migrate-v9.sh --rollback       # rollback all steps
# =============================================================================

set -eu

MODE="dry-run"
STEP="all"

while [ $# -gt 0 ]; do
    case "$1" in
        --apply) MODE="apply"; shift ;;
        --dry-run) MODE="dry-run"; shift ;;
        --rollback) MODE="rollback"; shift ;;
        --step) STEP="$2"; shift 2 ;;
        --help|-h)
            sed -n '2,20p' "$0"
            exit 0
            ;;
        *) echo "Unknown arg: $1" >&2; exit 2 ;;
    esac
done

if [ -t 1 ]; then
    C_GREEN='\033[0;32m' C_YELLOW='\033[1;33m' C_RED='\033[0;31m' C_CYAN='\033[0;36m' C_BOLD='\033[1m' C_RESET='\033[0m'
else
    C_GREEN='' C_YELLOW='' C_RED='' C_CYAN='' C_BOLD='' C_RESET=''
fi

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOOLS_DIR="${PROJECT_ROOT}/tools"
cd "$PROJECT_ROOT"

echo "${C_BOLD}AEGIS v8.x -> v9 Migration${C_RESET}"
echo "Mode: ${MODE} | Step: ${STEP}"
echo

# ────────────────────────────────────────────────────────────────────────────
# Step assessment
# ────────────────────────────────────────────────────────────────────────────
assess() {
    echo "${C_CYAN}=== Migration Assessment ===${C_RESET}"

    # Step 1: Folder consolidation
    if [ -d "${PROJECT_ROOT}/_aegis-brain" ]; then
        echo "  ${C_YELLOW}STEP 1${C_RESET} Folder consolidation: PENDING (.aegis/brain/ not yet created)"
    elif [ -d "${PROJECT_ROOT}/.aegis/brain" ]; then
        echo "  ${C_GREEN}STEP 1${C_RESET} Folder consolidation: ✅ DONE"
    else
        echo "  ${C_RED}STEP 1${C_RESET} Folder consolidation: ⚠️  No brain found"
    fi

    # Step 2: Settings hardening
    if grep -q '"defaultMode": "bypassPermissions"' "${PROJECT_ROOT}/.claude/settings.json" 2>/dev/null; then
        echo "  ${C_YELLOW}STEP 2${C_RESET} Settings hardening: PENDING (still bypassPermissions)"
    elif grep -q '"defaultMode": "acceptEdits"' "${PROJECT_ROOT}/.claude/settings.json" 2>/dev/null; then
        echo "  ${C_GREEN}STEP 2${C_RESET} Settings hardening: ✅ DONE"
    else
        echo "  ${C_RED}STEP 2${C_RESET} Settings hardening: ⚠️  No settings.json"
    fi

    # Step 3: CLAUDE_*.md lift
    local md_count=0
    for f in CLAUDE.md CLAUDE_safety.md CLAUDE_agents.md CLAUDE_skills.md CLAUDE_lessons.md; do
        [ -f "${PROJECT_ROOT}/$f" ] && md_count=$((md_count + 1))
    done
    if [ "$md_count" -eq 0 ]; then
        echo "  ${C_GREEN}STEP 3${C_RESET} CLAUDE_*.md lift: ✅ DONE (no framework files at root)"
    elif [ "$md_count" -eq 5 ]; then
        echo "  ${C_YELLOW}STEP 3${C_RESET} CLAUDE_*.md lift: PENDING ($md_count framework files at root)"
    else
        echo "  ${C_YELLOW}STEP 3${C_RESET} CLAUDE_*.md lift: PARTIAL ($md_count of 5 files at root)"
    fi

    # Step 4: Plugin install
    if command -v claude > /dev/null && claude plugin list 2>/dev/null | grep -q "aegis"; then
        echo "  ${C_GREEN}STEP 4${C_RESET} Plugin install: ✅ DONE"
    else
        echo "  ${C_YELLOW}STEP 4${C_RESET} Plugin install: PENDING (claude plugin install aegis)"
    fi

    echo
}

# ────────────────────────────────────────────────────────────────────────────
# Step 1: Folder consolidation
# ────────────────────────────────────────────────────────────────────────────
step_consolidate() {
    echo "${C_CYAN}=== Step 1: Folder Consolidation ===${C_RESET}"

    if [ ! -d "${PROJECT_ROOT}/_aegis-brain" ] && [ -d "${PROJECT_ROOT}/.aegis/brain" ]; then
        echo "${C_GREEN}Already consolidated. Skipping.${C_RESET}"
        return 0
    fi

    if [ "$MODE" = "apply" ]; then
        "$TOOLS_DIR/aegis-migrate-consolidate.sh" --apply --gitignore-mode shared --yes
    else
        "$TOOLS_DIR/aegis-migrate-consolidate.sh"
    fi
}

# ────────────────────────────────────────────────────────────────────────────
# Step 2: Settings hardening
# ────────────────────────────────────────────────────────────────────────────
step_settings() {
    echo "${C_CYAN}=== Step 2: Settings Hardening ===${C_RESET}"

    if [ ! -f "${TOOLS_DIR}/v9-proposed-settings.json" ]; then
        echo "${C_RED}Missing: tools/v9-proposed-settings.json${C_RESET}"
        return 1
    fi

    if grep -q '"defaultMode": "acceptEdits"' "${PROJECT_ROOT}/.claude/settings.json" 2>/dev/null; then
        echo "${C_GREEN}Already hardened. Skipping.${C_RESET}"
        return 0
    fi

    echo "${C_YELLOW}⚠️  This step REQUIRES manual execution between sessions.${C_RESET}"
    echo "Reason: .claude/settings.json is protected by guard-write.sh hook (correct behavior)."
    echo
    echo "Manual steps:"
    echo "  1. Close Claude Code"
    echo "  2. cp .claude/settings.json .claude/settings.json.v8-backup"
    echo "  3. cp tools/v9-proposed-settings.json .claude/settings.json"
    echo "  4. Restart Claude Code"
    echo
    echo "See: tools/v9-permission-migration-guide.md for detailed guide"
}

# ────────────────────────────────────────────────────────────────────────────
# Step 3: CLAUDE_*.md lift
# ────────────────────────────────────────────────────────────────────────────
step_claude_md() {
    echo "${C_CYAN}=== Step 3: CLAUDE_*.md Lift ===${C_RESET}"

    if [ "$MODE" = "apply" ]; then
        "$TOOLS_DIR/aegis-claude-md-lift.sh" --apply --yes
    else
        "$TOOLS_DIR/aegis-claude-md-lift.sh"
    fi
}

# ────────────────────────────────────────────────────────────────────────────
# Step 4: Plugin install
# ────────────────────────────────────────────────────────────────────────────
step_plugin() {
    echo "${C_CYAN}=== Step 4: Plugin Install ===${C_RESET}"

    if ! command -v claude > /dev/null; then
        echo "${C_RED}claude CLI not found. Install Claude Code first.${C_RESET}"
        return 1
    fi

    echo "Plugin install requires Claude Code Plugin marketplace (not yet GA)."
    echo
    echo "Manual steps when available:"
    echo "  claude plugin install aegis@9.0.0"
    echo "  aegis init"
    echo
    echo "Status: PENDING (Sprint v9-10 plugin scaffold not yet built)"
}

# ────────────────────────────────────────────────────────────────────────────
# Rollback
# ────────────────────────────────────────────────────────────────────────────
cmd_rollback() {
    echo "${C_CYAN}=== Rolling Back v9 Migration ===${C_RESET}"

    echo
    echo "Step 4 (Plugin uninstall):"
    echo "  Manual: claude plugin uninstall aegis"

    echo
    echo "Step 3 (CLAUDE_*.md restore):"
    "$TOOLS_DIR/aegis-claude-md-lift.sh" --rollback || echo "  (no backup found, skipping)"

    echo
    echo "Step 2 (Settings restore):"
    if [ -f "${PROJECT_ROOT}/.claude/settings.json.v8-backup" ]; then
        echo "  ${C_YELLOW}MANUAL${C_RESET}: cp .claude/settings.json.v8-backup .claude/settings.json"
    else
        echo "  No v8 backup found"
    fi

    echo
    echo "Step 1 (Folder rollback):"
    if [ "$MODE" = "apply" ]; then
        "$TOOLS_DIR/aegis-migrate-consolidate.sh" --rollback
    else
        echo "  [DRY-RUN] Would run: aegis-migrate-consolidate.sh --rollback"
    fi
}

# ────────────────────────────────────────────────────────────────────────────
# Main dispatch
# ────────────────────────────────────────────────────────────────────────────
case "$MODE" in
    rollback)
        cmd_rollback
        ;;
    *)
        assess

        case "$STEP" in
            all)
                step_consolidate
                echo
                step_settings
                echo
                step_claude_md
                echo
                step_plugin
                ;;
            consolidate) step_consolidate ;;
            settings)    step_settings ;;
            claude-md)   step_claude_md ;;
            plugin)      step_plugin ;;
            *) echo "${C_RED}Unknown step: $STEP${C_RESET}"; exit 2 ;;
        esac

        echo
        if [ "$MODE" = "dry-run" ]; then
            echo "${C_GREEN}Dry-run complete.${C_RESET} Re-run with --apply to apply available steps."
        fi
        ;;
esac
