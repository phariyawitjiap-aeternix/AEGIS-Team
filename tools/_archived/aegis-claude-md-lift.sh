#!/usr/bin/env bash
# =============================================================================
# aegis-claude-md-lift.sh
# CLAUDE_*.md migration: lift framework rules to plugin (S14-04 implementation)
# =============================================================================
# Detects v8.x root CLAUDE_*.md files, classifies framework vs user content,
# backs up customizations, removes framework files (now lives in plugin).
#
# v8.x root state:
#   CLAUDE.md, CLAUDE_safety.md, CLAUDE_agents.md, CLAUDE_skills.md, CLAUDE_lessons.md
#
# v9 target state:
#   project/CLAUDE.md (user-owned, project-specific only, optional)
#   Framework rules: ~/.claude/plugins/aegis/CLAUDE_*.md (loaded by plugin runtime)
#
# Usage:
#   ./tools/aegis-claude-md-lift.sh                # dry-run (default)
#   ./tools/aegis-claude-md-lift.sh --apply        # actually lift + backup
#   ./tools/aegis-claude-md-lift.sh --rollback     # restore from backup
# =============================================================================

set -eu

MODE="dry-run"
SKIP_CONFIRM=false

while [ $# -gt 0 ]; do
    case "$1" in
        --apply) MODE="apply"; shift ;;
        --dry-run) MODE="dry-run"; shift ;;
        --rollback) MODE="rollback"; shift ;;
        --yes|-y) SKIP_CONFIRM=true; shift ;;
        --help|-h)
            sed -n '2,20p' "$0"
            exit 0
            ;;
        *) echo "Unknown arg: $1" >&2; exit 2 ;;
    esac
done

if [ -t 1 ]; then
    C_GREEN='\033[0;32m' C_YELLOW='\033[1;33m' C_RED='\033[0;31m' C_CYAN='\033[0;36m' C_RESET='\033[0m'
else
    C_GREEN='' C_YELLOW='' C_RED='' C_CYAN='' C_RESET=''
fi

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

BACKUP_DIR="${PROJECT_ROOT}/.aegis-backup/v8-claude-md-$(date '+%Y%m%d-%H%M%S')"
USER_CLAUDE_MD="${PROJECT_ROOT}/CLAUDE.md.user"

FRAMEWORK_FILES=(
    "CLAUDE.md"
    "CLAUDE_safety.md"
    "CLAUDE_agents.md"
    "CLAUDE_skills.md"
    "CLAUDE_lessons.md"
)

log_info()  { echo "${C_GREEN}[INFO]${C_RESET}  $*"; }
log_warn()  { echo "${C_YELLOW}[WARN]${C_RESET}  $*"; }
log_error() { echo "${C_RED}[ERROR]${C_RESET} $*" >&2; }

# ────────────────────────────────────────────────────────────────────────────
# Detect v8.x state
# ────────────────────────────────────────────────────────────────────────────
detect_state() {
    echo "${C_CYAN}=== Current State ===${C_RESET}"
    local found=0
    for f in "${FRAMEWORK_FILES[@]}"; do
        if [ -f "${PROJECT_ROOT}/$f" ]; then
            local lines=$(wc -l < "${PROJECT_ROOT}/$f")
            echo "  EXISTS: $f ($lines lines)"
            found=$((found + 1))
        else
            echo "  MISSING: $f"
        fi
    done

    if [ -f "$USER_CLAUDE_MD" ]; then
        echo "  EXISTS: CLAUDE.md.user (preserved customizations)"
    fi

    return $found
}

# ────────────────────────────────────────────────────────────────────────────
# Classify content (heuristic: framework = ~75% match, user = >25% custom)
# ────────────────────────────────────────────────────────────────────────────
classify_file() {
    local file=$1
    # Without plugin defaults to compare against, use heuristic:
    # - If file has user-added "## Custom" or "## My" sections: user customizations exist
    # - If file matches known v8.x defaults (template-like): framework only
    if grep -qiE "^## (custom|my |project-specific|local)" "$file" 2>/dev/null; then
        echo "user-customized"
    elif grep -qE "^# AEGIS v[0-9]" "$file" 2>/dev/null; then
        echo "framework-default"
    else
        echo "unknown"
    fi
}

# ────────────────────────────────────────────────────────────────────────────
# Apply migration
# ────────────────────────────────────────────────────────────────────────────
cmd_apply() {
    log_info "Backing up to: $BACKUP_DIR"

    if [ "$MODE" != "dry-run" ]; then
        mkdir -p "$BACKUP_DIR"
    fi

    local user_content=""
    local has_customizations=false

    for f in "${FRAMEWORK_FILES[@]}"; do
        local full="${PROJECT_ROOT}/$f"
        [ ! -f "$full" ] && continue

        local class=$(classify_file "$full")
        echo
        echo "${C_CYAN}Processing: $f${C_RESET}"
        echo "  Classification: $class"

        case "$class" in
            user-customized)
                log_warn "  User customizations detected -- preserving"
                # Extract custom sections to user content
                local custom=$(awk '
                    /^## (custom|my |Custom|My |Project-Specific|Local)/i { in_section=1; print; next }
                    /^## / && in_section { in_section=0 }
                    in_section { print }
                ' "$full")

                if [ -n "$custom" ]; then
                    user_content="${user_content}

# === From $f ===

${custom}"
                    has_customizations=true
                fi
                ;;
            framework-default)
                log_info "  Framework default -- safe to remove"
                ;;
            *)
                log_warn "  Cannot classify -- preserving as backup only"
                ;;
        esac

        if [ "$MODE" = "apply" ]; then
            cp "$full" "${BACKUP_DIR}/$f"
            log_info "  Backed up: ${BACKUP_DIR}/$f"
            rm "$full"
            log_info "  Removed: $f"
        else
            log_info "  [DRY-RUN] Would backup + remove: $f"
        fi
    done

    # Write CLAUDE.md.user with preserved customizations
    if [ "$has_customizations" = true ]; then
        echo
        if [ "$MODE" = "apply" ]; then
            cat > "${PROJECT_ROOT}/CLAUDE.md" <<EOF
# Project CLAUDE.md (User-Owned)

> AEGIS framework rules now load from plugin: ~/.claude/plugins/aegis/
> This file is YOUR project-specific rules only.
> Customizations preserved from v8.x CLAUDE_*.md files below.
${user_content}
EOF
            log_info "Wrote CLAUDE.md with preserved user customizations"
        else
            log_info "[DRY-RUN] Would write CLAUDE.md with preserved customizations"
        fi
    fi

    # Manifest
    if [ "$MODE" = "apply" ]; then
        cat > "${BACKUP_DIR}/manifest.json" <<EOF
{
  "operation": "claude-md-lift",
  "from_version": "8.x",
  "to_version": "9.0",
  "migration_date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "files_processed": [$(for f in "${FRAMEWORK_FILES[@]}"; do echo -n "\"$f\","; done | sed 's/,$//')],
  "user_customizations_preserved": ${has_customizations},
  "rollback_command": "${0##*/} --rollback"
}
EOF
        log_info "Manifest: ${BACKUP_DIR}/manifest.json"
    fi
}

# ────────────────────────────────────────────────────────────────────────────
# Rollback
# ────────────────────────────────────────────────────────────────────────────
cmd_rollback() {
    log_info "Looking for most recent backup..."
    local LATEST_BACKUP=$(ls -1d "${PROJECT_ROOT}"/.aegis-backup/v8-claude-md-* 2>/dev/null | tail -1)

    if [ -z "$LATEST_BACKUP" ]; then
        log_error "No backup found at .aegis-backup/v8-claude-md-*"
        exit 1
    fi

    log_info "Restoring from: $LATEST_BACKUP"

    for f in "${FRAMEWORK_FILES[@]}"; do
        if [ -f "${LATEST_BACKUP}/$f" ]; then
            cp "${LATEST_BACKUP}/$f" "${PROJECT_ROOT}/$f"
            log_info "  Restored: $f"
        fi
    done

    log_info "Rollback complete. Backup retained at: $LATEST_BACKUP"
}

# ────────────────────────────────────────────────────────────────────────────
# Main
# ────────────────────────────────────────────────────────────────────────────
echo "AEGIS CLAUDE_*.md Lift (mode: ${MODE})"
echo

case "$MODE" in
    rollback) cmd_rollback ;;
    *)
        detect_state
        echo

        if [ "$MODE" = "apply" ] && [ "$SKIP_CONFIRM" = false ]; then
            printf "${C_YELLOW}About to lift framework files (backup will be created). Continue? [y/N] ${C_RESET}"
            read -r answer
            case "$answer" in
                [yY][eE][sS]|[yY]) ;;
                *) log_info "Aborted."; exit 0 ;;
            esac
        fi

        cmd_apply
        echo
        echo "${C_GREEN}Done.${C_RESET}"
        if [ "$MODE" = "dry-run" ]; then
            echo "Re-run with --apply to actually migrate."
        fi
        ;;
esac
