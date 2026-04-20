#!/usr/bin/env bash
# AEGIS Status Brief
# One-command health dashboard for the repo. Answers "where am I, what's
# dirty, what's next" without requiring multiple `git` / `cat` commands.
#
# Prints a compact status block. Does not modify state. Safe to run anytime.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "$REPO_ROOT"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

echo -e "${BOLD}AEGIS status${NC}"
echo "─────────────────────────────────────"

# --- Git state ---
BRANCH=$(git branch --show-current 2>/dev/null || echo "?")
LAST_COMMIT=$(git log -1 --format='%h %s' 2>/dev/null || echo "?")
AHEAD=$(git log --oneline origin/"$BRANCH"..HEAD 2>/dev/null | wc -l | tr -d ' ' || echo "?")
DIRTY_COUNT=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ' || echo "?")

echo -e "${BOLD}Git${NC}"
echo "  branch:      $BRANCH"
echo "  last commit: $LAST_COMMIT"
if [[ "$AHEAD" != "0" && "$AHEAD" != "?" ]]; then
    echo -e "  ahead of origin/$BRANCH by ${YELLOW}${AHEAD}${NC} commits"
else
    echo "  ahead of origin: 0"
fi
if [[ "$DIRTY_COUNT" != "0" && "$DIRTY_COUNT" != "?" ]]; then
    echo -e "  dirty files: ${YELLOW}${DIRTY_COUNT}${NC}"
    git status --porcelain 2>/dev/null | head -5 | sed 's/^/    /'
    [[ "$DIRTY_COUNT" -gt 5 ]] && echo "    ... ($((DIRTY_COUNT - 5)) more)"
else
    echo -e "  working tree: ${GREEN}clean${NC}"
fi

# --- Brain state ---
echo ""
echo -e "${BOLD}Brain${NC}"
MEMORY_FILE="${REPO_ROOT}/.aegis/brain/MEMORY.md"
if [[ -f "$MEMORY_FILE" ]]; then
    LAST_SYNC=$(grep -m1 'Last sync:' "$MEMORY_FILE" 2>/dev/null | sed 's/.*Last sync: //' || echo "?")
    echo "  last sync:     $LAST_SYNC"
else
    echo -e "  ${RED}MEMORY.md missing${NC}"
fi
LEARNING_COUNT=$(find .aegis/brain/learnings -maxdepth 1 -name '*.md' -type f 2>/dev/null | wc -l | tr -d ' ')
RETRO_COUNT=$(find .aegis/brain/retrospectives -name '*.md' -type f 2>/dev/null | wc -l | tr -d ' ')
HANDOFF_COUNT=$(find .aegis/brain/handoffs -name '*.md' -not -name TEMPLATE.md -not -name .gitkeep -type f 2>/dev/null | wc -l | tr -d ' ')
echo "  learnings:     $LEARNING_COUNT"
echo "  retrospectives: $RETRO_COUNT"
echo "  handoffs:      $HANDOFF_COUNT"

# --- Distill counter state ---
echo ""
echo -e "${BOLD}Distill reminder (S6-01)${NC}"
DISTILL_STATE=".aegis/brain/state/distill-state.json"
if [[ -f "$DISTILL_STATE" ]]; then
    COUNT=$(python3 -c "import json; print(json.load(open('$DISTILL_STATE'))['sessions_since_last_distill'])" 2>/dev/null || echo "?")
    THRESHOLD=$(python3 -c "import json; print(json.load(open('$DISTILL_STATE'))['threshold'])" 2>/dev/null || echo "?")
    LAST_RUN=$(python3 -c "import json; v=json.load(open('$DISTILL_STATE'))['last_distill_at']; print(v or 'never')" 2>/dev/null || echo "?")
    if [[ "$COUNT" != "?" && "$THRESHOLD" != "?" && "$COUNT" -ge "$THRESHOLD" ]] 2>/dev/null; then
        echo -e "  sessions since distill: ${YELLOW}${COUNT}${NC} / ${THRESHOLD}  ${YELLOW}(over threshold -- consider /aegis-distill)${NC}"
    else
        echo "  sessions since distill: ${COUNT:-0} / ${THRESHOLD:-3}"
    fi
    echo "  last distill:           $LAST_RUN"
else
    echo -e "  ${DIM}no state yet (will be created on next /aegis-start)${NC}"
fi

# --- Maintainer grant state ---
echo ""
echo -e "${BOLD}Maintainer grants (ADR-004)${NC}"
GRANT_DIR=".aegis/brain/state/maintainer-grants"
if [[ -d "$GRANT_DIR" ]]; then
    USED_COUNT=$(find "$GRANT_DIR" -maxdepth 1 -name '*.used' -type f 2>/dev/null | wc -l | tr -d ' ')
    echo "  consumed grants on disk: $USED_COUNT"
else
    echo -e "  ${DIM}no grants issued${NC}"
fi
if [[ -n "${AEGIS_MAINTAINER_MODE:-}" ]]; then
    echo -e "  ${YELLOW}live grant in env${NC} (first 16 chars shown):"
    echo "    ${AEGIS_MAINTAINER_MODE:0:16}..."
else
    echo "  env flag:                not set"
fi

# --- Open questions / backlog pointer ---
echo ""
echo -e "${BOLD}Backlog${NC}"
BACKLOG=".claude/references/v9-follow-ups.md"
if [[ -f "$BACKLOG" ]]; then
    LAST_UPDATED=$(grep -m1 '^> Last updated:' "$BACKLOG" 2>/dev/null | sed 's/^> Last updated: //' || echo "?")
    echo "  file:         $BACKLOG"
    echo "  last updated: $LAST_UPDATED"
else
    echo -e "  ${RED}v9-follow-ups.md missing${NC}"
fi

echo ""
echo "─────────────────────────────────────"
echo -e "${DIM}Tip: run ./tools/aegis-test-all.sh for the test suites.${NC}"
