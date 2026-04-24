#!/usr/bin/env bash
# aegis-upgrade.sh — upgrade an AEGIS installation to the latest framework
#
# Run from inside a downstream project that has AEGIS installed.
# Resolves the AEGIS source repo, shows a diff summary, confirms with the
# user, then invokes <source>/install.sh --upgrade --target-dir <cwd>.
#
# Usage:
#   bash tools/aegis-upgrade.sh                         # interactive
#   bash tools/aegis-upgrade.sh --source /path/to/AEGIS-Team
#   bash tools/aegis-upgrade.sh --check-only            # dry-run (show diff, exit)
#   bash tools/aegis-upgrade.sh --yes                   # skip confirmation
#
# Source resolution (in order):
#   1. --source <path>
#   2. $AEGIS_SOURCE env var
#   3. ~/Documents/AEGIS-Team (canonical default)
#   4. ~/AEGIS-Team
#   5. Sibling directory of CWD (../AEGIS-Team)
#
# Safety:
#   - Verifies source is a valid AEGIS repo (install.sh + CLAUDE.md + tools/)
#   - Verifies target looks like an AEGIS project (CLAUDE.md + .aegis/)
#   - Refuses to upgrade AEGIS-Team to itself (same-repo sanity check)
#   - install.sh --upgrade creates a _aegis-backup-<ts>/ before overwriting
#   - Post-upgrade, hook paths auto-normalize via install.sh's built-in step

set -euo pipefail

SOURCE=""
CHECK_ONLY=false
YES=false
TARGET_DIR="$(pwd)"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --source)     SOURCE="$2"; shift 2 ;;
        --check-only) CHECK_ONLY=true; shift ;;
        --yes|-y)     YES=true; shift ;;
        --target-dir) TARGET_DIR="$2"; shift 2 ;;
        -h|--help)
            grep -E "^#" "$0" | head -30 | sed 's/^# \?//'
            exit 0
            ;;
        *) echo "Unknown arg: $1" >&2; exit 1 ;;
    esac
done

# ── Colors ─────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# ── Resolve source ─────────────────────────────────────────────────────────
resolve_source() {
    if [[ -n "$SOURCE" ]]; then
        [[ -d "$SOURCE" ]] || error "Source not found: $SOURCE"
        echo "$SOURCE"; return
    fi
    if [[ -n "${AEGIS_SOURCE:-}" && -d "$AEGIS_SOURCE" ]]; then
        echo "$AEGIS_SOURCE"; return
    fi
    for candidate in \
        "$HOME/Documents/AEGIS-Team" \
        "$HOME/AEGIS-Team" \
        "$(dirname "$TARGET_DIR")/AEGIS-Team"; do
        if [[ -d "$candidate/.claude" && -f "$candidate/install.sh" ]]; then
            echo "$candidate"; return
        fi
    done
    error "Could not locate AEGIS source. Pass --source <path> or set AEGIS_SOURCE=/path/to/AEGIS-Team"
}

SOURCE_DIR="$(resolve_source)"
SOURCE_DIR="$(cd "$SOURCE_DIR" && pwd)"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

# ── Validate source + target ───────────────────────────────────────────────
[[ -f "$SOURCE_DIR/install.sh" ]] || error "Source is not a valid AEGIS repo (no install.sh): $SOURCE_DIR"
[[ -f "$SOURCE_DIR/CLAUDE.md" ]]   || error "Source is not a valid AEGIS repo (no CLAUDE.md): $SOURCE_DIR"
[[ -f "$SOURCE_DIR/VERSION" ]]     || error "Source has no VERSION file: $SOURCE_DIR"

[[ -f "$TARGET_DIR/CLAUDE.md" ]]   || error "Target is not an AEGIS project (no CLAUDE.md): $TARGET_DIR"
[[ -d "$TARGET_DIR/.aegis" || -d "$TARGET_DIR/.claude" ]] || error "Target is not an AEGIS project (no .aegis/ or .claude/): $TARGET_DIR"

if [[ "$SOURCE_DIR" == "$TARGET_DIR" ]]; then
    error "Refusing to upgrade AEGIS source to itself. Run install.sh --upgrade --target-dir <other-project> instead."
fi

# ── Banner ─────────────────────────────────────────────────────────────────
SOURCE_VERSION="$(cat "$SOURCE_DIR/VERSION" 2>/dev/null | tr -d '[:space:]')"
TARGET_VERSION="$(cat "$TARGET_DIR/VERSION" 2>/dev/null | tr -d '[:space:]' || echo "unknown")"
TARGET_AEGIS_VER="$(cat "$TARGET_DIR/AEGIS_VERSION" 2>/dev/null | tr -d '[:space:]' || echo "$TARGET_VERSION")"

echo ""
echo -e "${BOLD}${YELLOW}    .-=~~~~~~~~~~=-.    ${NC}"
echo -e "${BOLD}${YELLOW}   /  .  .  .  .  .  \\  ${NC}"
echo -e "${BOLD}${YELLOW}  |      /-\\          | ${NC}"
echo -e "${BOLD}${YELLOW}  |     / A \\         | ${NC}"
echo -e "${BOLD}${YELLOW}  |    /-----\\        | ${NC}"
echo -e "${BOLD}${YELLOW}   \\  .         .   /  ${NC}"
echo -e "${BOLD}${YELLOW}    \\   .     .    /   ${NC}"
echo -e "${BOLD}${YELLOW}     \\     .     /     ${NC}"
echo -e "${BOLD}${YELLOW}      \\         /      ${NC}"
echo -e "${BOLD}${YELLOW}       \\_______/       ${NC}"
echo ""
echo -e "${BOLD}${YELLOW}     A E G I S   Upgrade${NC}"
echo ""
info "Source:  ${BOLD}${SOURCE_DIR}${NC} (v${SOURCE_VERSION})"
info "Target:  ${BOLD}${TARGET_DIR}${NC} (currently v${TARGET_AEGIS_VER})"
echo ""

# ── Diff summary (what will change) ────────────────────────────────────────
info "Analyzing changes..."

# Counts
SRC_AGENTS=$(ls "$SOURCE_DIR/.claude/agents"/*.md 2>/dev/null | wc -l | tr -d ' ')
TGT_AGENTS=$(ls "$TARGET_DIR/.claude/agents"/*.md 2>/dev/null | wc -l | tr -d ' ')
SRC_CMDS=$(ls "$SOURCE_DIR/.claude/commands"/*.md 2>/dev/null | wc -l | tr -d ' ')
TGT_CMDS=$(ls "$TARGET_DIR/.claude/commands"/*.md 2>/dev/null | wc -l | tr -d ' ')
SRC_HOOKS=$(ls "$SOURCE_DIR/.claude/hooks"/*.sh 2>/dev/null | wc -l | tr -d ' ')
TGT_HOOKS=$(ls "$TARGET_DIR/.claude/hooks"/*.sh 2>/dev/null | wc -l | tr -d ' ')
SRC_TOOLS=$(ls "$SOURCE_DIR/tools"/*.sh 2>/dev/null | wc -l | tr -d ' ')
TGT_TOOLS=$(ls "$TARGET_DIR/tools"/*.sh 2>/dev/null | wc -l | tr -d ' ')
SRC_ISO=$(ls -d "$SOURCE_DIR/_aegis-output/iso-docs"/*/ 2>/dev/null | wc -l | tr -d ' ')
TGT_ISO=$(ls -d "$TARGET_DIR/_aegis-output/iso-docs"/*/ 2>/dev/null | wc -l | tr -d ' ')

echo ""
echo -e "${BOLD}  Component           Current      After        Change${NC}"
delta_marker() {
    local cur="$1" next="$2"
    if [[ "$cur" -lt "$next" ]]; then
        printf "${GREEN}+%d${NC}" "$((next - cur))"
    elif [[ "$cur" -gt "$next" ]]; then
        printf "${YELLOW}-%d${NC}" "$((cur - next))"
    else
        printf "(same)"
    fi
}
ver_delta() {
    if [[ "$1" = "$2" ]]; then printf "(same)"; else printf "${GREEN}upgrade${NC}"; fi
}
printf "  %-20s %-12s -> %-12s  " "Version"   "v${TARGET_AEGIS_VER}" "v${SOURCE_VERSION}"; ver_delta   "$TARGET_AEGIS_VER" "$SOURCE_VERSION"; echo ""
printf "  %-20s %-12s -> %-12s  " "Agents"    "$TGT_AGENTS"         "$SRC_AGENTS";         delta_marker "$TGT_AGENTS" "$SRC_AGENTS"; echo ""
printf "  %-20s %-12s -> %-12s  " "Commands"  "$TGT_CMDS"           "$SRC_CMDS";           delta_marker "$TGT_CMDS"   "$SRC_CMDS";   echo ""
printf "  %-20s %-12s -> %-12s  " "Hooks"     "$TGT_HOOKS"          "$SRC_HOOKS";          delta_marker "$TGT_HOOKS"  "$SRC_HOOKS";  echo ""
printf "  %-20s %-12s -> %-12s  " "Tools"     "$TGT_TOOLS"          "$SRC_TOOLS";          delta_marker "$TGT_TOOLS"  "$SRC_TOOLS";  echo ""
printf "  %-20s %-12s -> %-12s  " "ISO docs"  "$TGT_ISO"            "$SRC_ISO";            delta_marker "$TGT_ISO"    "$SRC_ISO";    echo ""
echo ""

# Hook-path bug detection
if [[ -f "$TARGET_DIR/.claude/settings.json" ]]; then
    REL_COUNT=$(grep -cE '"command": "bash \.claude/hooks' "$TARGET_DIR/.claude/settings.json" 2>/dev/null || echo 0)
    if [[ "$REL_COUNT" -gt 0 ]]; then
        warn "Target has ${BOLD}${REL_COUNT}${NC} hook command(s) with relative paths (causes recurring Stop hook errors)"
        info "Upgrade will anchor these to \$CLAUDE_PROJECT_DIR automatically"
    else
        success "Hook paths already anchored (no relative-path bug)"
    fi

    # Shared task-list-ID detection
    SHARED_ID=$(python3 -c "
import json, sys
with open(sys.argv[1]) as f: d = json.load(f)
print(d.get('env', {}).get('CLAUDE_CODE_TASK_LIST_ID', ''))
" "$TARGET_DIR/.claude/settings.json" 2>/dev/null || echo "")
    if [[ "$SHARED_ID" == "aegis-shared-tasks" ]]; then
        warn "Target uses the shared task list ID ${BOLD}aegis-shared-tasks${NC} (tasks leak across all AEGIS projects)"
        info "Upgrade will rewrite it to ${BOLD}aegis-tasks-$(basename "$TARGET_DIR" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g')${NC}"
    fi
fi

echo ""
info "A backup will be created at: ${BOLD}${TARGET_DIR}/_aegis-backup-<timestamp>/${NC}"
echo ""

# ── Check-only mode ────────────────────────────────────────────────────────
if [[ "$CHECK_ONLY" == "true" ]]; then
    info "Check-only mode — no changes applied. Re-run without --check-only to upgrade."
    exit 0
fi

# ── Confirm ────────────────────────────────────────────────────────────────
if [[ "$YES" != "true" ]]; then
    read -rp "Proceed with upgrade? [y/N] " ans
    [[ "$ans" == "y" || "$ans" == "Y" ]] || { info "Aborted."; exit 0; }
fi

# ── Invoke source install.sh --upgrade ─────────────────────────────────────
# Preserve profile + project name from target if available
PROFILE_ARG=""
PROJECT_ARG=""
if [[ -f "$TARGET_DIR/.aegis/brain/resonance/project-identity.md" ]]; then
    NAME=$(grep -iE "^- *name:|^Name:" "$TARGET_DIR/.aegis/brain/resonance/project-identity.md" 2>/dev/null | head -1 | sed -E 's/^[^:]*: *//' | tr -d '"')
    [[ -n "$NAME" ]] && PROJECT_ARG="--project-name $NAME"
    PROFILE=$(grep -iE "^- *profile:|^Profile:" "$TARGET_DIR/.aegis/brain/resonance/project-identity.md" 2>/dev/null | head -1 | sed -E 's/^[^:]*: *//' | tr -d '"' | awk '{print $1}')
    [[ -n "$PROFILE" ]] && PROFILE_ARG="--profile $PROFILE"
fi

echo ""
info "Running: bash '$SOURCE_DIR/install.sh' --upgrade --target-dir '$TARGET_DIR' $PROFILE_ARG $PROJECT_ARG"
echo ""

bash "$SOURCE_DIR/install.sh" --upgrade --target-dir "$TARGET_DIR" $PROFILE_ARG $PROJECT_ARG

# ── Record upgrade in target's brain log ───────────────────────────────────
LOG="$TARGET_DIR/.aegis/brain/logs/activity.log"
if [[ -f "$LOG" ]]; then
    TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "[${TS}] [UPGRADE] from v${TARGET_AEGIS_VER} to v${SOURCE_VERSION} (source=${SOURCE_DIR})" >> "$LOG" 2>/dev/null || true
fi

echo ""
success "Upgrade complete. Restart Claude Code to pick up new hooks and settings."
