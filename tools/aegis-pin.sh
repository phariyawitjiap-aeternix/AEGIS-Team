#!/usr/bin/env bash
# tools/aegis-pin.sh
# ────────────────────────────────────────────────────────────────────────────
# 2-axis pinning primitive for instincts and skills.
# Adapted from Hermes-Agent tools/skill_manager_tool.py:_pinned_guard pattern.
#
# Sprint:  v14-03 (S14-03-03)
#
# Semantic split (the "2-axis" innovation):
#   --axis delete  (default) — pin protects against deletion only.
#                              Can still be patched/edited.
#   --axis change  — pin protects against change/promotion. Can still be deleted.
#   --axis both    — pin protects against both.
#
# Storage: .aegis/brain/pins.json (sidecar; idempotent JSONL-style array)
#
# Usage:
#   aegis-pin.sh pin   <type> <id> [--axis delete|change|both] [--reason "..."]
#   aegis-pin.sh unpin <type> <id>
#   aegis-pin.sh list  [--type <type>]
#   aegis-pin.sh check <type> <id> <axis>   # exit 0 = pinned against axis, 1 = not
#
# Types (free-form, but common): instinct | skill | adr | resonance
#
# Integration:
#   - tools/aegis-instinct-auto-reinforce.sh can call `check <type> <id> change`
#     before promoting changes to a pinned instinct.
#   - Future: tools/aegis-curator-pin.sh (if/when curator ships) can defer
#     to this for unified pin semantics.
# ────────────────────────────────────────────────────────────────────────────

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${AEGIS_REPO_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
PINS_FILE="${REPO_ROOT}/.aegis/brain/pins.json"
ACTIVITY_LOG="${REPO_ROOT}/.aegis/brain/logs/activity.log"

usage() {
    cat >&2 <<'EOF'
Usage:
  aegis-pin.sh pin   <type> <id> [--axis delete|change|both] [--reason "..."]
  aegis-pin.sh unpin <type> <id>
  aegis-pin.sh list  [--type <type>] [--json]
  aegis-pin.sh check <type> <id> <axis>

Pin protects against:
  --axis delete  — deletion (default; matches Hermes pin semantic)
  --axis change  — change/promotion (allows deletion)
  --axis both    — deletion + change

Exit codes for `check`:
  0 = pinned against the given axis
  1 = not pinned (or pinned against a different axis only)
  2 = error
EOF
    exit 2
}

# Init pins file if missing (atomic via tempfile)
ensure_pins_file() {
    if [[ ! -f "$PINS_FILE" ]]; then
        mkdir -p "$(dirname "$PINS_FILE")"
        echo '[]' > "$PINS_FILE"
    fi
}

# Append to activity log
log() {
    local msg="$1"
    local ts
    ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "unknown")
    mkdir -p "$(dirname "$ACTIVITY_LOG")" 2>/dev/null || true
    echo "[${ts}] [pin] ${msg}" >> "$ACTIVITY_LOG" 2>/dev/null || true
}

# Validate axis
valid_axis() {
    case "$1" in
        delete|change|both) return 0 ;;
        *) return 1 ;;
    esac
}

# Atomic write of pins.json via tempfile + mv
write_pins() {
    local content="$1"
    local tmp
    tmp=$(mktemp "${PINS_FILE}.tmp.XXXXXX")
    printf '%s' "$content" > "$tmp"
    mv "$tmp" "$PINS_FILE"
}

# Read current pins as JSON (use python3 for safe parsing; jq fallback)
pins_json() {
    if command -v jq >/dev/null 2>&1; then
        cat "$PINS_FILE"
    elif command -v python3 >/dev/null 2>&1; then
        python3 -c "import json; print(json.dumps(json.load(open('$PINS_FILE'))))"
    else
        cat "$PINS_FILE"
    fi
}

# ─── pin <type> <id> [--axis X] [--reason "..."] ─────────────────────────────
cmd_pin() {
    local type="${1:-}"; local id="${2:-}"
    shift 2 2>/dev/null || true
    local axis="delete"
    local reason=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --axis) axis="${2:-}"; shift 2 ;;
            --reason) reason="${2:-}"; shift 2 ;;
            *) usage ;;
        esac
    done
    [[ -z "$type" || -z "$id" ]] && usage
    if ! valid_axis "$axis"; then
        echo "Error: invalid --axis '$axis' (must be: delete|change|both)" >&2
        exit 2
    fi

    ensure_pins_file
    local ts
    ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "unknown")

    # Upsert: remove any existing entry for (type, id), then append new
    local updated
    if command -v python3 >/dev/null 2>&1; then
        updated=$(python3 - "$PINS_FILE" "$type" "$id" "$axis" "$reason" "$ts" <<'PYEOF'
import json, sys
pins_path, type_, id_, axis, reason, ts = sys.argv[1:7]
with open(pins_path) as f: pins = json.load(f)
pins = [p for p in pins if not (p.get('type')==type_ and p.get('id')==id_)]
pins.append({'type': type_, 'id': id_, 'axis': axis, 'reason': reason, 'pinned_at': ts})
print(json.dumps(pins, indent=2))
PYEOF
)
    else
        echo "Error: python3 required for pin operations" >&2
        exit 2
    fi
    write_pins "$updated"
    log "pin ${type}:${id} axis=${axis} reason=\"${reason}\""
    echo "pinned: ${type}/${id} (axis=${axis})"
}

# ─── unpin <type> <id> ───────────────────────────────────────────────────────
cmd_unpin() {
    local type="${1:-}"; local id="${2:-}"
    [[ -z "$type" || -z "$id" ]] && usage
    ensure_pins_file

    local updated
    updated=$(python3 - "$PINS_FILE" "$type" "$id" <<'PYEOF'
import json, sys
pins_path, type_, id_ = sys.argv[1:4]
with open(pins_path) as f: pins = json.load(f)
before = len(pins)
pins = [p for p in pins if not (p.get('type')==type_ and p.get('id')==id_)]
after = len(pins)
print(json.dumps(pins, indent=2))
sys.stderr.write(f"removed {before-after} entry(ies)\n")
PYEOF
)
    write_pins "$updated"
    log "unpin ${type}:${id}"
    echo "unpinned: ${type}/${id}"
}

# ─── list [--type <type>] [--json] ───────────────────────────────────────────
cmd_list() {
    local type_filter=""
    local json_out=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --type) type_filter="${2:-}"; shift 2 ;;
            --json) json_out=1; shift ;;
            *) usage ;;
        esac
    done
    ensure_pins_file

    if [[ "$json_out" = "1" ]]; then
        python3 - "$PINS_FILE" "$type_filter" <<'PYEOF'
import json, sys
pins_path, type_filter = sys.argv[1:3]
with open(pins_path) as f: pins = json.load(f)
if type_filter:
    pins = [p for p in pins if p.get('type')==type_filter]
print(json.dumps(pins, indent=2))
PYEOF
        return
    fi

    # Pretty table
    python3 - "$PINS_FILE" "$type_filter" <<'PYEOF'
import json, sys
pins_path, type_filter = sys.argv[1:3]
with open(pins_path) as f: pins = json.load(f)
if type_filter:
    pins = [p for p in pins if p.get('type')==type_filter]
if not pins:
    print(f"No pins{' for type=' + type_filter if type_filter else ''}")
    sys.exit(0)
print(f"{'TYPE':<12} {'ID':<32} {'AXIS':<8} PINNED_AT             REASON")
print("─" * 80)
for p in pins:
    type_ = p.get('type','?')[:12]
    id_   = p.get('id','?')[:32]
    axis  = p.get('axis','delete')[:8]
    ts    = p.get('pinned_at','?')[:19]
    rea   = (p.get('reason','') or '')[:30]
    print(f"{type_:<12} {id_:<32} {axis:<8} {ts:<22} {rea}")
PYEOF
}

# ─── check <type> <id> <axis> — exit 0 if pinned-against-axis ────────────────
cmd_check() {
    local type="${1:-}"; local id="${2:-}"; local axis="${3:-}"
    if [[ -z "$type" || -z "$id" || -z "$axis" ]]; then usage; fi
    if ! valid_axis "$axis"; then
        echo "Error: invalid axis '$axis'" >&2
        exit 2
    fi
    ensure_pins_file

    local hit
    hit=$(python3 - "$PINS_FILE" "$type" "$id" "$axis" <<'PYEOF'
import json, sys
pins_path, type_, id_, axis = sys.argv[1:5]
with open(pins_path) as f: pins = json.load(f)
for p in pins:
    if p.get('type')==type_ and p.get('id')==id_:
        pinned_axis = p.get('axis', 'delete')
        # 'both' pins against both axes; otherwise exact match
        if pinned_axis == 'both' or pinned_axis == axis:
            print('1')
            sys.exit(0)
print('0')
PYEOF
)
    if [[ "$hit" = "1" ]]; then
        exit 0  # pinned against this axis
    fi
    exit 1   # not pinned (or pinned against different axis)
}

# ─── Dispatch ────────────────────────────────────────────────────────────────
action="${1:-}"
shift 2>/dev/null || true

case "$action" in
    pin)   cmd_pin   "$@" ;;
    unpin) cmd_unpin "$@" ;;
    list)  cmd_list  "$@" ;;
    check) cmd_check "$@" ;;
    --help|-h|help|"") usage ;;
    *) echo "Unknown action: $action" >&2; usage ;;
esac
