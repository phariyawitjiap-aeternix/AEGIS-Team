#!/usr/bin/env bash
# AEGIS Brain Sync -- Regenerates MEMORY.md index from .aegis/brain/ state
# Part of Sprint v9-04 (Memory Tool Integration -- Tier 1 Foundation)
#
# Usage:
#   ./tools/aegis-brain-sync.sh              # regenerate MEMORY.md
#   ./tools/aegis-brain-sync.sh --validate   # validate brain structure (no writes)
#   ./tools/aegis-brain-sync.sh --dry-run    # show what would be written
#
# Per ADR-002: File system = source of truth. This script reads file state
# and generates the MEMORY.md index that memory_20250818 can cache.
#
# Exit codes:
#   0 = success
#   1 = validation error (missing required files)
#   2 = usage error

set -euo pipefail

# --- Resolve paths ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BRAIN_DIR="${REPO_ROOT}/.aegis/brain"
MEMORY_FILE="${BRAIN_DIR}/MEMORY.md"
LOG_FILE="${BRAIN_DIR}/logs/activity.log"

# --- Parse arguments ---
MODE="sync"
case "${1:-}" in
    --validate) MODE="validate" ;;
    --dry-run)  MODE="dry-run" ;;
    --help|-h)
        echo "Usage: aegis-brain-sync.sh [--validate|--dry-run|--help]"
        echo ""
        echo "Regenerates .aegis/brain/MEMORY.md index from brain file state."
        echo "  (no args)    Regenerate MEMORY.md"
        echo "  --validate   Check brain structure, report issues, do not write"
        echo "  --dry-run    Show generated MEMORY.md without writing"
        exit 0
        ;;
    "") ;;
    *) echo "Unknown argument: $1. Use --help for usage." >&2; exit 2 ;;
esac

# --- Validation ---
ERRORS=()

# Required directories
for dir in resonance instincts instincts/promoted instincts/pending instincts/active logs sprints; do
    if [[ ! -d "${BRAIN_DIR}/${dir}" ]]; then
        ERRORS+=("Missing directory: .aegis/brain/${dir}")
    fi
done

# Required resonance files
for f in project-identity.md evolved-patterns.md anti-patterns.md architecture-decisions.md team-conventions.md; do
    if [[ ! -f "${BRAIN_DIR}/resonance/${f}" ]]; then
        ERRORS+=("Missing resonance file: .aegis/brain/resonance/${f}")
    fi
done

# Sprint symlink
if [[ ! -L "${BRAIN_DIR}/sprints/current" ]]; then
    ERRORS+=("Missing symlink: .aegis/brain/sprints/current (should point to active sprint)")
fi

# Activity log
if [[ ! -f "${LOG_FILE}" ]]; then
    ERRORS+=("Missing log file: .aegis/brain/logs/activity.log")
fi

if [[ ${#ERRORS[@]} -gt 0 ]]; then
    echo "Brain validation FAILED (${#ERRORS[@]} issue(s)):" >&2
    for e in "${ERRORS[@]}"; do
        echo "  - ${e}" >&2
    done
    if [[ "$MODE" == "validate" ]]; then
        exit 1
    fi
    echo "Continuing with sync despite errors (best-effort)..." >&2
fi

if [[ "$MODE" == "validate" ]]; then
    if [[ ${#ERRORS[@]} -eq 0 ]]; then
        echo "Brain validation PASSED. All required files and directories present."
    fi
    exit 0
fi

# --- Count brain contents ---
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "unknown")

# Patterns
PATTERN_COUNT=$(grep -c "^## P-" "${BRAIN_DIR}/resonance/evolved-patterns.md" 2>/dev/null || echo "0")
PATTERN_RANGE=""
if [[ "$PATTERN_COUNT" -gt 0 ]]; then
    FIRST=$(grep -m1 "^## P-" "${BRAIN_DIR}/resonance/evolved-patterns.md" | grep -oE "P-[0-9]+" || echo "?")
    LAST=$(grep "^## P-" "${BRAIN_DIR}/resonance/evolved-patterns.md" | tail -1 | grep -oE "P-[0-9]+" || echo "?")
    PATTERN_RANGE=" (${FIRST} to ${LAST})"
fi

# Anti-patterns
ANTI_COUNT=$(grep -c "^## A-" "${BRAIN_DIR}/resonance/anti-patterns.md" 2>/dev/null || echo "0")
ANTI_RANGE=""
if [[ "$ANTI_COUNT" -gt 0 ]]; then
    FIRST=$(grep -m1 "^## A-" "${BRAIN_DIR}/resonance/anti-patterns.md" | grep -oE "A-[0-9]+" || echo "?")
    LAST=$(grep "^## A-" "${BRAIN_DIR}/resonance/anti-patterns.md" | tail -1 | grep -oE "A-[0-9]+" || echo "?")
    ANTI_RANGE=" (${FIRST} to ${LAST})"
fi

# ADRs
ADR_COUNT=$(grep -c "^## ADR-" "${BRAIN_DIR}/resonance/architecture-decisions.md" 2>/dev/null || echo "0")
ADR_RANGE=""
if [[ "$ADR_COUNT" -gt 0 ]]; then
    FIRST=$(grep -m1 "^## ADR-" "${BRAIN_DIR}/resonance/architecture-decisions.md" | grep -oE "ADR-[0-9]+" || echo "?")
    LAST=$(grep "^## ADR-" "${BRAIN_DIR}/resonance/architecture-decisions.md" | tail -1 | grep -oE "ADR-[0-9]+" || echo "?")
    ADR_RANGE=" (${FIRST} to ${LAST})"
fi

# Instincts
PROMOTED_COUNT=$(find "${BRAIN_DIR}/instincts/promoted" \( -name "*.yaml" -o -name "*.yml" \) 2>/dev/null | wc -l | tr -d ' ')
ACTIVE_COUNT=$(find "${BRAIN_DIR}/instincts/active" \( -name "*.yaml" -o -name "*.yml" \) 2>/dev/null | wc -l | tr -d ' ')
PENDING_COUNT=$(find "${BRAIN_DIR}/instincts/pending" \( -name "*.yaml" -o -name "*.yml" \) 2>/dev/null | wc -l | tr -d ' ')

# Promoted instinct details
PROMOTED_LIST=""
if [[ "$PROMOTED_COUNT" -gt 0 ]]; then
    while IFS= read -r f; do
        name=$(basename "$f" .yaml)
        name=$(basename "$name" .yml)
        # Extract first line of pattern: field as summary (YAML multi-line block scalar)
        desc=$(awk '/^pattern:/{found=1; next} found && /^[^ ]/{exit} found{gsub(/^[[:space:]]+/,""); print; exit}' "$f" 2>/dev/null || echo "")
        if [[ -z "$desc" ]]; then
            desc="(no pattern description)"
        fi
        # Extract confidence
        conf=$(grep -m1 "^confidence:" "$f" 2>/dev/null | awk '{print $2}' || echo "?")
        PROMOTED_LIST="${PROMOTED_LIST}\n- **${name}** -- ${desc} (confidence: ${conf})"
    done < <(find "${BRAIN_DIR}/instincts/promoted" -name "*.yaml" -o -name "*.yml" 2>/dev/null | sort)
fi

# Pending instinct details
PENDING_LIST=""
if [[ "$PENDING_COUNT" -gt 0 ]]; then
    while IFS= read -r f; do
        name=$(basename "$f" .yaml)
        name=$(basename "$name" .yml)
        desc=$(awk '/^pattern:/{found=1; next} found && /^[^ ]/{exit} found{gsub(/^[[:space:]]+/,""); print; exit}' "$f" 2>/dev/null || echo "")
        if [[ -z "$desc" ]]; then
            desc="(no pattern description)"
        fi
        PENDING_LIST="${PENDING_LIST}\n- **${name}** -- ${desc}"
    done < <(find "${BRAIN_DIR}/instincts/pending" -name "*.yaml" -o -name "*.yml" 2>/dev/null | sort)
fi

# Sprint info
SPRINT_NAME="unknown"
if [[ -L "${BRAIN_DIR}/sprints/current" ]]; then
    SPRINT_NAME=$(readlink "${BRAIN_DIR}/sprints/current" | sed 's|.*/||')
fi

# Handoffs (most recent 3)
HANDOFF_LIST=""
HANDOFF_COUNT=0
if [[ -d "${BRAIN_DIR}/handoffs" ]]; then
    while IFS= read -r f; do
        [[ -z "$f" ]] && continue
        [[ "$(basename "$f")" == ".gitkeep" ]] && continue
        [[ "$(basename "$f")" == "TEMPLATE.md" ]] && continue
        name=$(basename "$f")
        HANDOFF_LIST="${HANDOFF_LIST}\n- [${name}](handoffs/${name})"
        HANDOFF_COUNT=$((HANDOFF_COUNT + 1))
    done < <(find "${BRAIN_DIR}/handoffs" -name "*.md" -not -name "TEMPLATE.md" 2>/dev/null | sort -r | head -3)
fi

# Retrospectives
RETRO_COUNT=0
RETRO_LIST=""
if [[ -d "${BRAIN_DIR}/retrospectives" ]]; then
    RETRO_COUNT=$(find "${BRAIN_DIR}/retrospectives" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
fi

# Resonance file listing
RESONANCE_LIST=""
for f in "${BRAIN_DIR}"/resonance/*.md; do
    [[ ! -f "$f" ]] && continue
    name=$(basename "$f")
    # Extract first heading as description
    desc=$(grep -m1 "^# " "$f" 2>/dev/null | sed 's/^# //' || echo "")
    if [[ -z "$desc" ]]; then
        desc="(no heading)"
    fi
    RESONANCE_LIST="${RESONANCE_LIST}\n- [${name}](resonance/${name}) -- ${desc}"
done

# Project name from identity
PROJECT_NAME=$(grep -m1 "^## Name" "${BRAIN_DIR}/resonance/project-identity.md" -A1 2>/dev/null | tail -1 | sed 's/^[[:space:]]*//' || echo "AEGIS")

# --- Generate MEMORY.md ---
CONTENT="# AEGIS Project Brain Memory Index

> Auto-generated by \`aegis-brain-sync\`. Do not edit manually.
> Last sync: ${TIMESTAMP}
> Source of truth: \`.aegis/brain/\` (file system, per ADR-002)
> Scope: **repo-scoped** (checked into git, shared with team). User-scoped memory under \`~/.claude/projects/.../memory/\` is a separate Claude Code system and is NOT managed by AEGIS tools.

## Quick Status

| Dimension | Value |
|-----------|-------|
| Project | ${PROJECT_NAME} |
| Active Sprint | ${SPRINT_NAME} |
| Promoted Instincts | ${PROMOTED_COUNT} |
| Active Instincts | ${ACTIVE_COUNT} |
| Pending Instincts | ${PENDING_COUNT} |
| Evolved Patterns | ${PATTERN_COUNT}${PATTERN_RANGE} |
| Anti-Patterns | ${ANTI_COUNT}${ANTI_RANGE} |
| Architecture Decisions | ${ADR_COUNT}${ADR_RANGE} |
| Retrospectives | ${RETRO_COUNT} |
| Handoffs | ${HANDOFF_COUNT} |

## Promoted Instincts (always load)
$(echo -e "${PROMOTED_LIST:-\n(none)}")

## Pending Instincts (load on relevance)
$(echo -e "${PENDING_LIST:-\n(none)}")

## Resonance Files
$(echo -e "${RESONANCE_LIST}")

## Active Sprint

- **Sprint**: ${SPRINT_NAME}
- **Kanban**: [sprints/current/kanban.md](sprints/current/kanban.md)
- **Plan**: [sprints/current/plan.md](sprints/current/plan.md)

## Recent Handoffs
$(echo -e "${HANDOFF_LIST:-\n(none)}")

## Learnings

- **Raw**: [learnings/raw/](learnings/raw/)

## Logs (not cached -- file only)

- [logs/activity.log](logs/activity.log) -- Append-only session activity"

# --- Output ---
if [[ "$MODE" == "dry-run" ]]; then
    echo "$CONTENT"
    echo ""
    echo "--- DRY RUN: Would write above to ${MEMORY_FILE} ---"
    exit 0
fi

# Write MEMORY.md (atomic: tmp + rename)
printf '%s\n' "$CONTENT" > "${MEMORY_FILE}.tmp"
mv "${MEMORY_FILE}.tmp" "${MEMORY_FILE}"

# Log
if [[ -d "$(dirname "${LOG_FILE}")" ]]; then
    echo "[${TIMESTAMP}] [TOOL:brain-sync] MEMORY.md regenerated (${PATTERN_COUNT} patterns, ${ANTI_COUNT} anti-patterns, ${ADR_COUNT} ADRs, ${PROMOTED_COUNT} promoted instincts)" >> "${LOG_FILE}" 2>/dev/null || true
fi

echo "Brain sync complete. MEMORY.md regenerated at ${MEMORY_FILE}"
echo "  Patterns: ${PATTERN_COUNT} | Anti-patterns: ${ANTI_COUNT} | ADRs: ${ADR_COUNT}"
echo "  Promoted: ${PROMOTED_COUNT} | Active: ${ACTIVE_COUNT} | Pending: ${PENDING_COUNT}"
echo "  Sprint: ${SPRINT_NAME} | Handoffs: ${HANDOFF_COUNT} | Retros: ${RETRO_COUNT}"
