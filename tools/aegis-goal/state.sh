#!/usr/bin/env bash
# tools/aegis-goal/state.sh
# ────────────────────────────────────────────────────────────────────────────
# Per-session goal state for Persistent Goals POC.
# Adapted from Hermes SessionDB.state_meta keyed by goal:<session_id>.
#
# Sprint:  v14-04 (S14-04-01) — POC tooling
#
# Storage: .aegis/brain/state/goal-<session_id>.yaml
# Schema:
#   session_id: <id>
#   goal: <text>
#   status: active | paused | achieved | cleared
#   turn_count: <int>
#   max_turns: 20
#   created_at: ISO8601
#   updated_at: ISO8601
#   judge_history: [{turn, verdict, reason, ts}, ...]
#
# Usage:
#   state.sh init <session_id> <goal>           — create new state
#   state.sh load <session_id>                  — print current state (YAML)
#   state.sh tick <session_id> <verdict> <reason>  — increment turn + record verdict
#   state.sh set-status <session_id> <status>   — paused|achieved|cleared
#   state.sh clear <session_id>                 — delete state file
# ────────────────────────────────────────────────────────────────────────────

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${AEGIS_REPO_ROOT:-$(cd "${SCRIPT_DIR}/../.." && pwd)}"
STATE_DIR="${REPO_ROOT}/.aegis/brain/state"

usage() {
    cat >&2 <<'EOF'
Usage:
  state.sh init       <session_id> <goal-text>
  state.sh load       <session_id>
  state.sh tick       <session_id> <verdict:yes|no|unclear> <reason>
  state.sh set-status <session_id> <active|paused|achieved|cleared>
  state.sh clear      <session_id>
EOF
    exit 2
}

state_path() {
    echo "${STATE_DIR}/goal-${1}.yaml"
}

ensure_state_dir() {
    mkdir -p "$STATE_DIR"
}

now_iso() {
    date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "unknown"
}

# Atomic write (tempfile + mv)
atomic_write() {
    local path="$1"
    local content="$2"
    local tmp
    tmp=$(mktemp "${path}.tmp.XXXXXX")
    printf '%s' "$content" > "$tmp"
    mv "$tmp" "$path"
}

cmd_init() {
    local sid="${1:-}"; local goal="${2:-}"
    [[ -z "$sid" || -z "$goal" ]] && usage
    ensure_state_dir
    local sp; sp=$(state_path "$sid")
    if [[ -f "$sp" ]]; then
        echo "State for session '$sid' already exists at $sp" >&2
        exit 1
    fi
    local ts; ts=$(now_iso)
    # Escape goal for YAML (single line, double-quoted with backslash escaping)
    local safe_goal
    safe_goal=$(printf '%s' "$goal" | sed 's/\\/\\\\/g; s/"/\\"/g')
    atomic_write "$sp" "session_id: ${sid}
goal: \"${safe_goal}\"
status: active
turn_count: 0
max_turns: 20
created_at: ${ts}
updated_at: ${ts}
judge_history: []
"
    echo "goal-state init: ${sp}"
}

cmd_load() {
    local sid="${1:-}"
    [[ -z "$sid" ]] && usage
    local sp; sp=$(state_path "$sid")
    if [[ ! -f "$sp" ]]; then
        echo "No goal state for session '$sid'" >&2
        exit 1
    fi
    cat "$sp"
}

cmd_tick() {
    local sid="${1:-}"; local verdict="${2:-}"; local reason="${3:-}"
    [[ -z "$sid" || -z "$verdict" ]] && usage
    case "$verdict" in
        yes|no|unclear) ;;
        *) echo "Error: verdict must be yes|no|unclear" >&2; exit 2 ;;
    esac
    local sp; sp=$(state_path "$sid")
    [[ ! -f "$sp" ]] && { echo "No goal state for session '$sid'" >&2; exit 1; }

    # Python helper for YAML mutation (simpler than awk-ing YAML)
    local updated
    updated=$(python3 - "$sp" "$verdict" "$reason" "$(now_iso)" <<'PYEOF'
import sys, json
path, verdict, reason, ts = sys.argv[1:5]

# Minimal YAML parser — relies on our known schema
with open(path) as f:
    raw = f.read()

# Parse: split on top-level keys
state = {}
in_history = False
history_lines = []
for line in raw.split('\n'):
    if line.startswith('judge_history:'):
        in_history = True
        # Strip trailing literal "[]" if present (empty array)
        if line.strip() == 'judge_history: []':
            state['judge_history'] = []
            in_history = False
        else:
            state['judge_history'] = []
        continue
    if in_history:
        if line.startswith('  - ') or line.startswith('    '):
            history_lines.append(line)
            continue
        in_history = False
    if ': ' in line:
        k, v = line.split(': ', 1)
        state[k.strip()] = v.strip().strip('"')

# Increment turn_count + append history
turn = int(state.get('turn_count', '0')) + 1
state['turn_count'] = turn
state['updated_at'] = ts

# Build the new YAML
goal = state.get('goal', '')
out = f"""session_id: {state.get('session_id', '')}
goal: \"{goal}\"
status: {state.get('status', 'active')}
turn_count: {turn}
max_turns: {state.get('max_turns', '20')}
created_at: {state.get('created_at', ts)}
updated_at: {ts}
judge_history:
  - turn: {turn}
    verdict: {verdict}
    reason: \"{reason}\"
    ts: {ts}
"""
# Preserve prior history lines if present
for h in history_lines:
    out += h + '\n'

print(out, end='')
PYEOF
)
    atomic_write "$sp" "$updated"

    # Check stop conditions
    local turn_count; turn_count=$(grep -E '^turn_count:' "$sp" | awk '{print $2}')
    local max_turns;  max_turns=$(grep -E '^max_turns:'  "$sp" | awk '{print $2}')
    local status_was; status_was="active"

    if [[ "$verdict" = "yes" ]]; then
        # Mark achieved
        python3 - "$sp" "achieved" <<'PYEOF'
import sys
path, new_status = sys.argv[1:3]
with open(path) as f: lines = f.readlines()
out = []
for line in lines:
    if line.startswith('status:'):
        out.append(f'status: {new_status}\n')
    else:
        out.append(line)
with open(path, 'w') as f: f.writelines(out)
PYEOF
        echo "goal-state tick: verdict=yes turn=${turn_count} → ACHIEVED"
        return
    fi

    if [[ "$turn_count" -ge "$max_turns" ]]; then
        python3 - "$sp" "exhausted" <<'PYEOF'
import sys
path, new_status = sys.argv[1:3]
with open(path) as f: lines = f.readlines()
out = []
for line in lines:
    if line.startswith('status:'):
        out.append(f'status: {new_status}\n')
    else:
        out.append(line)
with open(path, 'w') as f: f.writelines(out)
PYEOF
        echo "goal-state tick: verdict=${verdict} turn=${turn_count}/${max_turns} → EXHAUSTED"
        return
    fi

    echo "goal-state tick: verdict=${verdict} turn=${turn_count}/${max_turns} → continue"
}

cmd_set_status() {
    local sid="${1:-}"; local new_status="${2:-}"
    [[ -z "$sid" || -z "$new_status" ]] && usage
    case "$new_status" in
        active|paused|achieved|cleared|exhausted) ;;
        *) echo "Error: invalid status '$new_status'" >&2; exit 2 ;;
    esac
    local sp; sp=$(state_path "$sid")
    [[ ! -f "$sp" ]] && { echo "No goal state for session '$sid'" >&2; exit 1; }
    python3 - "$sp" "$new_status" "$(now_iso)" <<'PYEOF'
import sys
path, new_status, ts = sys.argv[1:4]
with open(path) as f: lines = f.readlines()
out = []
for line in lines:
    if line.startswith('status:'):
        out.append(f'status: {new_status}\n')
    elif line.startswith('updated_at:'):
        out.append(f'updated_at: {ts}\n')
    else:
        out.append(line)
with open(path, 'w') as f: f.writelines(out)
PYEOF
    echo "goal-state set-status: ${sid} → ${new_status}"
}

cmd_clear() {
    local sid="${1:-}"
    [[ -z "$sid" ]] && usage
    local sp; sp=$(state_path "$sid")
    if [[ -f "$sp" ]]; then
        rm -f "$sp"
        echo "goal-state cleared: ${sp}"
    else
        echo "No goal state for session '$sid' (no-op)"
    fi
}

action="${1:-}"
shift 2>/dev/null || true

case "$action" in
    init)       cmd_init       "$@" ;;
    load)       cmd_load       "$@" ;;
    tick)       cmd_tick       "$@" ;;
    set-status) cmd_set_status "$@" ;;
    clear)      cmd_clear      "$@" ;;
    --help|-h|"") usage ;;
    *) echo "Unknown action: $action" >&2; usage ;;
esac
