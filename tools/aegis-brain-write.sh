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

# --- Threat scan (S14-01-02 — Hermes parity) ---
# Adapted from Hermes tools/memory_tool.py:_MEMORY_THREAT_PATTERNS.
# Scans content before write to block prompt injection / exfiltration / persistence
# patterns from being baked into the brain (which gets injected into system prompts).
#
# Returns 0 if content is clean, 1 if blocked (with error to stderr).
# Honors `# scan-exempt: <reason>` first-line opt-out.

# 12 threat patterns (mirrors patterns: section of aegis-brain-threat-patterns.yaml)
# Format: "id|pattern" — checked case-insensitively against content.
_aegis_threat_patterns=(
    "prompt_injection|ignore[[:space:]]+(previous|all|above|prior)[[:space:]]+instructions"
    "role_hijack|you[[:space:]]+are[[:space:]]+now[[:space:]]+"
    "deception_hide|do[[:space:]]+not[[:space:]]+tell[[:space:]]+the[[:space:]]+user"
    "sys_prompt_override|system[[:space:]]+prompt[[:space:]]+override"
    "disregard_rules|disregard[[:space:]]+(your|all|any)[[:space:]]+(instructions|rules|guidelines)"
    "bypass_restrictions|act[[:space:]]+as[[:space:]]+(if|though)[[:space:]]+you[[:space:]]+(have[[:space:]]+no|don.{1,2}t[[:space:]]+have)[[:space:]]+(restrictions|limits|rules)"
    "exfil_curl|curl[[:space:]]+[^[:space:]]*\\\$\\{?[a-zA-Z_]*(KEY|TOKEN|SECRET|PASSWORD|CREDENTIAL|API)"
    "exfil_wget|wget[[:space:]]+[^[:space:]]*\\\$\\{?[a-zA-Z_]*(KEY|TOKEN|SECRET|PASSWORD|CREDENTIAL|API)"
    "read_secrets|cat[[:space:]]+[^[:space:]]*(\\.env|credentials|\\.netrc|\\.pgpass|\\.npmrc|\\.pypirc)"
    "ssh_backdoor|authorized_keys"
    "ssh_access|\\\$HOME/\\.ssh/|~/\\.ssh/"
    "aegis_env|(\\\$HOME|~)/\\.aegis/[^[:space:]]*\\.env"
)

# 10 invisible Unicode codepoints (mirrors invisible_chars: section).
# We check via `grep -P` PCRE if available, else fall back to printf+sed.
_aegis_invisible_chars=(
    $'\xe2\x80\x8b'  # U+200B  zero-width space
    $'\xe2\x80\x8c'  # U+200C  zero-width non-joiner
    $'\xe2\x80\x8d'  # U+200D  zero-width joiner
    $'\xe2\x81\xa0'  # U+2060  word joiner
    $'\xef\xbb\xbf'  # U+FEFF  BOM / zero-width no-break space
    $'\xe2\x80\xaa'  # U+202A  LRE
    $'\xe2\x80\xab'  # U+202B  RLE
    $'\xe2\x80\xac'  # U+202C  PDF
    $'\xe2\x80\xad'  # U+202D  LRO
    $'\xe2\x80\xae'  # U+202E  RLO
)

# Globally allow disabling the scan via env var (rare — for CI fixtures).
# Default: enabled.
_aegis_scan_enabled() {
    [[ "${AEGIS_BRAIN_SCAN_DISABLED:-}" != "1" ]]
}

# Check if content is exempt (first line matches `# scan-exempt: <reason>`).
_aegis_is_scan_exempt() {
    local content="$1"
    local first_line
    first_line="$(printf '%s' "$content" | head -n1)"
    [[ "$first_line" =~ ^[[:space:]]*#[[:space:]]*scan-exempt:[[:space:]]+.+ ]]
}

# Run the scan. Echoes block reason to stderr + returns 1 if blocked, 0 if clean.
_aegis_threat_scan() {
    local content="$1"
    local rel_path="${2:-(unknown)}"

    _aegis_scan_enabled || return 0

    if _aegis_is_scan_exempt "$content"; then
        # Honored opt-out — log to activity but allow.
        if [[ -d "$(dirname "${LOG_FILE}")" ]]; then
            local ts
            ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "unknown")
            echo "[${ts}] [TOOL:brain-write] scan-exempt honored for ${rel_path}" >> "${LOG_FILE}" 2>/dev/null || true
        fi
        return 0
    fi

    # Pattern check (case-insensitive ERE).
    for spec in "${_aegis_threat_patterns[@]}"; do
        local pid="${spec%%|*}"
        local pattern="${spec#*|}"
        if printf '%s' "$content" | grep -E -i -q "$pattern"; then
            echo "BLOCKED: brain content matches threat pattern '${pid}'" >&2
            echo "        Path:    .aegis/brain/${rel_path}" >&2
            echo "        Pattern: ${pattern}" >&2
            echo "        Brain content is injected into the system prompt; injection/exfil/persistence patterns are not allowed." >&2
            echo "        If this is a legitimate write (e.g., learnings/ documenting a past attack), prepend:" >&2
            echo "            # scan-exempt: <one-line reason>" >&2
            return 1
        fi
    done

    # Invisible-char check.
    for ch in "${_aegis_invisible_chars[@]}"; do
        if printf '%s' "$content" | grep -F -q "$ch"; then
            echo "BLOCKED: brain content contains invisible Unicode character" >&2
            echo "        Path: .aegis/brain/${rel_path}" >&2
            echo "        Invisible characters can hide injection payloads from human review." >&2
            return 1
        fi
    done

    return 0
}

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

    # Step 0 (S14-01-02): threat scan before any disk write.
    if ! _aegis_threat_scan "$content" "$rel_path"; then
        return 1
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

    # Step 4: memory_20250818 cache update via main-agent proxy (S4-02 proxy pattern).
    # Subagents lack memory_20250818 in their tool set (see learning
    # 2026-04-20_subagent-tool-availability). Instead, emit a structured directive
    # on stdout that the main orchestrator parses and actions via its own memory tool.
    # Harmless when unparsed (just an extra log line); actionable when a main agent reads it.
    local subtype
    subtype=$(path_to_subtype "$rel_path" 2>/dev/null || echo "unknown")
    local bytes
    bytes=$(printf '%s' "$content" | wc -c | tr -d ' ')
    echo "AEGIS_MEMORY_WRITE: {\"path\":\"${rel_path}\",\"subtype\":\"${subtype}\",\"bytes\":${bytes},\"timestamp\":\"${timestamp}\"}"

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

    # Step 0 (S14-01-02): threat scan on appended content too.
    # Logs (logs/* paths) skip scan — they are append-heavy and don't go into prompts.
    if [[ "$rel_path" != logs/* ]]; then
        if ! _aegis_threat_scan "$content" "$rel_path"; then
            return 1
        fi
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

# Detect sourced vs executed across bash and zsh.
# bash: BASH_SOURCE[0] differs from $0 when sourced.
# zsh:  BASH_SOURCE is unset (nounset would fire) — use ZSH_EVAL_CONTEXT,
#       which gains a ":file" segment when the current context is a sourced file.
_aegis_run_cli=0
if [[ -n "${ZSH_VERSION:-}" ]]; then
    case "${ZSH_EVAL_CONTEXT:-}" in
        *:file*) _aegis_run_cli=0 ;;
        *)       _aegis_run_cli=1 ;;
    esac
elif [[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]]; then
    _aegis_run_cli=1
fi

if [[ "$_aegis_run_cli" == "1" ]]; then
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
