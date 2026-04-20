#!/usr/bin/env bash
# AEGIS Brain Write -- Write to brain with automatic MEMORY.md regeneration
# Part of Sprint v9-04 (Memory Tool Integration -- Tier 1 Foundation)
#
# Usage (as standalone):
#   ./tools/aegis-brain-write.sh <brain-relative-path> <content>
#   ./tools/aegis-brain-write.sh resonance/new-pattern.md "# Pattern content..."
#   ./tools/aegis-brain-write.sh instincts/pending/new-instinct.yaml "$(cat instinct.yaml)"
#   echo "content" | ./tools/aegis-brain-write.sh learnings/raw/2026-04-20-lesson.md -
#
# Usage (as sourced library):
#   source tools/aegis-brain-write.sh
#   brain_write "resonance/new-pattern.md" "# Content here"
#   brain_append "logs/custom.log" "[timestamp] log entry"
#
# Protocol (per ADR-002):
#   1. Write to file (authoritative)
#   2. Regenerate MEMORY.md index
#   3. Log the write to activity.log
#   (Step 4 -- memory_20250818 cache update -- deferred until SDK wiring in S4-02)
#
# Exit codes:
#   0 = success
#   1 = write failed
#   2 = usage error

set -euo pipefail

# --- Resolve paths ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BRAIN_DIR="${REPO_ROOT}/.aegis/brain"
SYNC_SCRIPT="${SCRIPT_DIR}/aegis-brain-sync.sh"
LOG_FILE="${BRAIN_DIR}/logs/activity.log"

# --- Library functions (available when sourced) ---

# Write a file to the brain, regenerate MEMORY.md, log the write
# Arguments: $1 = brain-relative path, $2 = content
brain_write() {
    local rel_path="$1"
    local content="$2"
    local full_path="${BRAIN_DIR}/${rel_path}"
    local dir
    dir=$(dirname "$full_path")
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "unknown")

    # Ensure parent directory exists
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
    fi

    # Step 1: Write to file (authoritative, per ADR-002)
    # Why printf over echo: echo strips/interprets leading "-n"/"-e" and varies across shells.
    # Why tmp+mv: atomic replace so concurrent sync/write cannot truncate mid-flight.
    printf '%s\n' "$content" > "${full_path}.tmp"
    mv "${full_path}.tmp" "$full_path"

    # Step 2: Regenerate MEMORY.md (if sync script exists)
    if [[ -x "$SYNC_SCRIPT" ]]; then
        "$SYNC_SCRIPT" > /dev/null 2>&1 || true
    fi

    # Step 3: Log the write
    if [[ -d "$(dirname "${LOG_FILE}")" ]]; then
        echo "[${timestamp}] [TOOL:brain-write] Wrote: .aegis/brain/${rel_path} ($(printf '%s' "$content" | wc -c | tr -d ' ') bytes)" >> "${LOG_FILE}" 2>/dev/null || true
    fi

    # Step 4: memory_20250818 cache update (DEFERRED -- S4-02)
    # When SDK is wired, this will call:
    #   memory_subtype=$(path_to_subtype "$rel_path")
    #   memory_tool.write(content, type='project', subtype=memory_subtype)
    # For now, file write is sufficient (cache populated on next session start)

    echo "brain_write: .aegis/brain/${rel_path} (${timestamp})"
}

# Append to a brain file (for logs, learnings, etc.)
# Arguments: $1 = brain-relative path, $2 = content to append
brain_append() {
    local rel_path="$1"
    local content="$2"
    local full_path="${BRAIN_DIR}/${rel_path}"
    local dir
    dir=$(dirname "$full_path")
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "unknown")

    # Ensure parent directory exists
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
    fi

    # Step 1: Append to file (printf for echo-flag safety; append need not be atomic)
    printf '%s\n' "$content" >> "$full_path"

    # Step 2: Regenerate MEMORY.md only for non-log files
    if [[ "$rel_path" != logs/* ]] && [[ -x "$SYNC_SCRIPT" ]]; then
        "$SYNC_SCRIPT" > /dev/null 2>&1 || true
    fi

    # Step 3: Log (skip if writing to activity.log itself to avoid recursion)
    if [[ "$rel_path" != "logs/activity.log" ]] && [[ -d "$(dirname "${LOG_FILE}")" ]]; then
        echo "[${timestamp}] [TOOL:brain-append] Appended to: .aegis/brain/${rel_path}" >> "${LOG_FILE}" 2>/dev/null || true
    fi
}

# Map a brain-relative path to memory_20250818 subtype
# Arguments: $1 = brain-relative path
# Returns: subtype string (for future S4-02 integration)
path_to_subtype() {
    local rel_path="$1"
    case "$rel_path" in
        instincts/promoted/*)   echo "instinct-promoted" ;;
        instincts/active/*)     echo "instinct-active" ;;
        instincts/pending/*)    echo "instinct-pending" ;;
        resonance/*)            echo "resonance" ;;
        sprints/current/*)      echo "sprint-active" ;;
        sprints/sprint-*)       echo "sprint-archived" ;;
        retrospectives/*)       echo "retro" ;;
        handoffs/*)             echo "handoff" ;;
        learnings/*)            echo "learning" ;;
        logs/*)                 echo "log-no-cache" ;;
        *)                      echo "unknown" ;;
    esac
}

# --- CLI mode (when run directly, not sourced) ---

# Detect if being sourced or run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Running directly
    if [[ $# -lt 2 ]]; then
        echo "Usage: aegis-brain-write.sh <brain-relative-path> <content|->" >&2
        echo "" >&2
        echo "Examples:" >&2
        echo "  ./tools/aegis-brain-write.sh resonance/note.md '# Note content'" >&2
        echo "  echo 'content' | ./tools/aegis-brain-write.sh learnings/raw/lesson.md -" >&2
        echo "" >&2
        echo "Source as library:" >&2
        echo "  source tools/aegis-brain-write.sh" >&2
        echo "  brain_write 'resonance/note.md' '# Content'" >&2
        exit 2
    fi

    REL_PATH="$1"
    CONTENT="$2"

    # Support piped input with '-'
    if [[ "$CONTENT" == "-" ]]; then
        CONTENT=$(cat)
    fi

    brain_write "$REL_PATH" "$CONTENT"
fi
