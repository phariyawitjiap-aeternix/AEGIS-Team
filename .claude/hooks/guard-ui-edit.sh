#!/usr/bin/env bash
# AEGIS Hook — guard-ui-edit.sh (S3-04)
# Blocks Edit/Write/MultiEdit on UI files when DESIGN.md is absent at repo root.
# Prevents agents from writing UI code without a design contract.
#
# Hook type: PreToolUse
# Matcher:   Edit|Write|MultiEdit
#
# Input:  JSON on stdin  { "tool_name": "Edit|Write|MultiEdit", "tool_input": { "file_path": "..." } }
# Output: JSON on stdout { "decision": "block", "reason": "..." }  (exit 2 to block)
# Exit 0: allow  |  Exit 2: block
#
# Pattern evaluation order:
#   1. EXCLUDE patterns checked FIRST (fail-safe — if any match, exit 0 immediately)
#   2. INCLUDE UI patterns checked second
#   3. If INCLUDE matches AND no DESIGN.md at repo root: exit 2 (block)
#   4. Otherwise: exit 0 (allow)

set -euo pipefail

INPUT=$(cat)

TOOL=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_name',''))" 2>/dev/null || echo "")
FILE=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null || echo "")

# Only act on write-family tools
case "$TOOL" in
    Edit|Write|MultiEdit) ;;
    *) exit 0 ;;
esac

[[ -z "$FILE" ]] && exit 0

# ── Logging helper (best-effort, never fail the hook) ─────────────────────
LOG=".aegis/brain/logs/activity.log"
log_decision() {
    local decision="$1"
    local reason="$2"
    if [[ -f "$LOG" || -d "$(dirname "$LOG")" ]]; then
        local ts
        ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "unknown")
        echo "[${ts}] [HOOK:guard-ui-edit] ${decision} — ${TOOL} ${FILE}${reason:+ | ${reason}}" >> "$LOG" 2>/dev/null || true
    fi
}

# ── STEP 1: EXCLUDE patterns (checked FIRST — fail-safe) ─────────────────
# If a file matches any exclusion, it is NOT a UI file for gate purposes.
# This ensures test/spec/story/config files never trigger the gate.

# Pattern matching via bash regex against the full file path
is_excluded() {
    local path="$1"
    # *.test.{tsx,jsx,css,scss}
    [[ "$path" =~ \.(test|spec|stories)\.(tsx|jsx|css|scss|js|ts)$ ]] && return 0
    # *.config.{tsx,js,ts}
    [[ "$path" =~ \.config\.(tsx|jsx|js|ts|mjs|cjs)$ ]] && return 0
    # **/__tests__/**
    [[ "$path" =~ (^|/)'__tests__'/ ]] && return 0
    # **/__mocks__/**
    [[ "$path" =~ (^|/)'__mocks__'/ ]] && return 0
    # **/setupTests.*
    [[ "$path" =~ (^|/)setupTests\. ]] && return 0
    return 1
}

if is_excluded "$FILE"; then
    log_decision "ALLOW" "excluded (test/spec/stories/config/setup pattern)"
    exit 0
fi

# ── STEP 2: INCLUDE UI patterns ───────────────────────────────────────────
# If the file does NOT match any UI pattern, allow unconditionally.

is_ui_file() {
    local path="$1"
    # UI file extensions
    [[ "$path" =~ \.(tsx|jsx|css|scss|vue|svelte)$ ]] && return 0
    # UI source directories
    [[ "$path" =~ (^|/)src/components/ ]] && return 0
    [[ "$path" =~ (^|/)src/pages/ ]] && return 0
    [[ "$path" =~ (^|/)src/styles/ ]] && return 0
    [[ "$path" =~ (^|/)src/ui/ ]] && return 0
    [[ "$path" =~ (^|/)app/components/ ]] && return 0
    return 1
}

if ! is_ui_file "$FILE"; then
    log_decision "ALLOW" "non-UI file (no INCLUDE pattern match)"
    exit 0
fi

# ── STEP 3: UI file detected — check for DESIGN.md ───────────────────────
# Resolve project root: use AEGIS_REPO_ROOT env if set, otherwise cwd.
REPO_ROOT="${AEGIS_REPO_ROOT:-$(pwd)}"
DESIGN_MD="${REPO_ROOT}/DESIGN.md"

if [[ -f "$DESIGN_MD" ]]; then
    log_decision "ALLOW" "UI file, DESIGN.md present"
    exit 0
fi

# ── STEP 4: BLOCK ────────────────────────────────────────────────────────
log_decision "BLOCK" "UI file, DESIGN.md missing"
echo '{"decision":"block","reason":"DESIGN.md required before UI code per BLOCK 0F. Run: bash tools/aegis-design-init.sh --blank --output DESIGN.md"}'
exit 2
