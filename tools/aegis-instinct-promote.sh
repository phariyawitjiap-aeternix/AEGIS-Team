#!/usr/bin/env bash
# AEGIS Tool — aegis-instinct-promote.sh (S2-05)
#
# Instinct lifecycle manager. Implements the four-tier promotion system:
#   pending -> active -> promoted -> retired
#
# Promotion criteria (per .aegis/brain/instincts/README.md):
#   pending  -> active:   confidence > 0.5 AND observations >= 2
#   active   -> promoted: confidence > 0.8
#   any      -> retired:  --reason required (audit trail)
#
# Usage:
#   aegis-instinct-promote.sh create    --from <resonance-file> [--id <id>] [--cluster <c>]
#   aegis-instinct-promote.sh activate  --id <instinct-id>
#   aegis-instinct-promote.sh promote   --id <instinct-id> [--adr <adr-file>]
#   aegis-instinct-promote.sh reinforce --id <instinct-id>
#   aegis-instinct-promote.sh retire    --id <instinct-id> --reason <text>
#   aegis-instinct-promote.sh list      [--tier pending|active|promoted|retired|all]
#
# Environment override for tests:
#   AEGIS_INSTINCT_ROOT — redirect instinct directory (default: .aegis/brain/instincts)
#   AEGIS_ACTIVITY_LOG  — redirect activity log (default: .aegis/brain/logs/activity.log)

set -euo pipefail

# ── Directory resolution ───────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${AEGIS_REPO_ROOT:-$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || pwd)}"
INSTINCT_ROOT="${AEGIS_INSTINCT_ROOT:-${REPO_ROOT}/.aegis/brain/instincts}"
ACTIVITY_LOG="${AEGIS_ACTIVITY_LOG:-${REPO_ROOT}/.aegis/brain/logs/activity.log}"

TIERS=("pending" "active" "promoted" "retired")

# ── Utility functions ──────────────────────────────────────────────────────
now_iso() {
    date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ"
}

today_iso() {
    date -u +"%Y-%m-%d" 2>/dev/null || date +"%Y-%m-%d"
}

log_activity() {
    local msg="$1"
    local ts
    ts=$(now_iso)
    mkdir -p "$(dirname "$ACTIVITY_LOG")"
    echo "[${ts}] [instinct-promote] ${msg}" >> "$ACTIVITY_LOG" 2>/dev/null || true
}

# Extract a single-line scalar field from a YAML file
get_yaml_field() {
    local file="$1"
    local field="$2"
    grep "^${field}:" "$file" 2>/dev/null | sed "s/^${field}: *//" | tr -d '"' | tr -d "'" | head -1
}

# Set (or replace) a single-line scalar field in a YAML file
set_yaml_field() {
    local file="$1"
    local field="$2"
    local value="$3"
    # Use a temp file for atomic update
    local tmp
    tmp=$(mktemp)
    if grep -q "^${field}:" "$file" 2>/dev/null; then
        sed "s|^${field}:.*|${field}: ${value}|" "$file" > "$tmp"
    else
        # Append field
        cp "$file" "$tmp"
        echo "${field}: ${value}" >> "$tmp"
    fi
    mv "$tmp" "$file"
}

# Find an instinct YAML across all tiers; outputs "tier:filepath" or empty
find_instinct() {
    local id="$1"
    for tier in "${TIERS[@]}"; do
        local f="${INSTINCT_ROOT}/${tier}/${id}.yaml"
        if [[ -f "$f" ]]; then
            echo "${tier}:${f}"
            return 0
        fi
    done
    return 1
}

# Ensure tier directories exist
ensure_dirs() {
    for tier in "${TIERS[@]}"; do
        mkdir -p "${INSTINCT_ROOT}/${tier}"
    done
}

# ── Command: create ────────────────────────────────────────────────────────
cmd_create() {
    local from_file=""
    local id=""
    local cluster="general"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --from)    from_file="$2"; shift 2 ;;
            --id)      id="$2";        shift 2 ;;
            --cluster) cluster="$2";   shift 2 ;;
            *) echo "ERROR: unknown option: $1" >&2; exit 1 ;;
        esac
    done

    if [[ -z "$from_file" ]]; then
        echo "ERROR: --from <resonance-file> required" >&2
        exit 1
    fi

    if [[ ! -f "$from_file" ]]; then
        echo "ERROR: resonance file not found: $from_file" >&2
        exit 1
    fi

    # Generate ID from filename if not provided
    if [[ -z "$id" ]]; then
        local basename
        basename=$(basename "$from_file" .md)
        # Convert to kebab-case: lowercase, replace spaces/underscores with hyphens, strip non-alnum-hyphen
        id=$(echo "$basename" | tr '[:upper:]' '[:lower:]' | tr ' _' '-' | tr -cd '[:alnum:]-')
    fi

    ensure_dirs
    local dest="${INSTINCT_ROOT}/pending/${id}.yaml"

    # Idempotent: if already exists, report and exit 0
    if [[ -f "$dest" ]]; then
        echo "INFO: instinct '${id}' already exists in pending/ — no action taken"
        exit 0
    fi

    # Extract pattern summary: first non-heading paragraph OR content of ## Pattern section
    local pattern_text
    pattern_text=$(python3 - "$from_file" <<'PYEOF'
import sys, re

with open(sys.argv[1]) as f:
    content = f.read()

# Try to find ## Pattern section
m = re.search(r'(?:^|\n)##\s*Pattern\s*\n(.*?)(?=\n##|\Z)', content, re.DOTALL)
if m:
    print(m.group(1).strip()[:400])
    sys.exit(0)

# Fallback: first non-heading, non-empty paragraph
for line in content.split('\n'):
    line = line.strip()
    if line and not line.startswith('#'):
        print(line[:400])
        sys.exit(0)

print("Pattern extracted from: " + sys.argv[1])
PYEOF
2>/dev/null || echo "Pattern from ${from_file}")

    local now
    now=$(today_iso)

    cat > "$dest" << EOF
id: ${id}
status: pending
confidence: 0.3
observations: 1
first_seen: ${now}
last_reinforced: ${now}
cluster: ${cluster}
pattern: |
  ${pattern_text}
rationale: |
  Created from resonance file: ${from_file}
adr_refs: []
retired_reason: ""
retired_date: ""
EOF

    log_activity "CREATE pending/${id}.yaml from ${from_file}"
    echo "Created: ${dest}"
}

# ── Command: activate ─────────────────────────────────────────────────────
cmd_activate() {
    local id=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --id) id="$2"; shift 2 ;;
            *) echo "ERROR: unknown option: $1" >&2; exit 1 ;;
        esac
    done

    [[ -z "$id" ]] && { echo "ERROR: --id <instinct-id> required" >&2; exit 1; }

    local src="${INSTINCT_ROOT}/pending/${id}.yaml"
    if [[ ! -f "$src" ]]; then
        echo "ERROR: pending instinct not found: ${src}" >&2
        exit 1
    fi

    local confidence observations
    confidence=$(get_yaml_field "$src" "confidence")
    observations=$(get_yaml_field "$src" "observations")

    # Validate thresholds: confidence > 0.5 AND observations >= 2
    local conf_ok=0 obs_ok=0
    python3 -c "import sys; sys.exit(0 if float('${confidence}') > 0.5 else 1)" 2>/dev/null && conf_ok=1
    [[ "${observations}" -ge 2 ]] 2>/dev/null && obs_ok=1

    if [[ $conf_ok -eq 0 ]]; then
        echo "REJECTED: confidence (${confidence}) must be > 0.5 to activate" >&2
        exit 1
    fi
    if [[ $obs_ok -eq 0 ]]; then
        echo "REJECTED: observations (${observations}) must be >= 2 to activate" >&2
        exit 1
    fi

    ensure_dirs
    local dest="${INSTINCT_ROOT}/active/${id}.yaml"
    mv "$src" "$dest"
    set_yaml_field "$dest" "status" "active"

    log_activity "ACTIVATE pending/${id} -> active/${id} (confidence=${confidence}, observations=${observations})"
    echo "Activated: ${dest}"
}

# ── Command: promote ──────────────────────────────────────────────────────
cmd_promote() {
    local id=""
    local adr_file=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --id)  id="$2";       shift 2 ;;
            --adr) adr_file="$2"; shift 2 ;;
            *) echo "ERROR: unknown option: $1" >&2; exit 1 ;;
        esac
    done

    [[ -z "$id" ]] && { echo "ERROR: --id <instinct-id> required" >&2; exit 1; }

    local src="${INSTINCT_ROOT}/active/${id}.yaml"
    if [[ ! -f "$src" ]]; then
        echo "ERROR: active instinct not found: ${src}" >&2
        exit 1
    fi

    local confidence
    confidence=$(get_yaml_field "$src" "confidence")

    # Validate: confidence > 0.8
    python3 -c "import sys; sys.exit(0 if float('${confidence}') > 0.8 else 1)" 2>/dev/null || {
        echo "REJECTED: confidence (${confidence}) must be > 0.8 to promote" >&2
        exit 1
    }

    ensure_dirs
    local dest="${INSTINCT_ROOT}/promoted/${id}.yaml"
    mv "$src" "$dest"
    set_yaml_field "$dest" "status" "promoted"

    # Optional ADR enrichment
    if [[ -n "$adr_file" ]]; then
        # Append to adr_refs list (simple sed approach)
        local tmp
        tmp=$(mktemp)
        sed "s|^adr_refs: \[\]|adr_refs: [\"${adr_file}\"]|;s|^adr_refs: \[|adr_refs: [\"${adr_file}\", |" "$dest" > "$tmp"
        mv "$tmp" "$dest"
    fi

    log_activity "PROMOTE active/${id} -> promoted/${id} (confidence=${confidence})"
    echo "Promoted: ${dest}"
}

# ── Command: reinforce ────────────────────────────────────────────────────
cmd_reinforce() {
    local id=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --id) id="$2"; shift 2 ;;
            *) echo "ERROR: unknown option: $1" >&2; exit 1 ;;
        esac
    done

    [[ -z "$id" ]] && { echo "ERROR: --id <instinct-id> required" >&2; exit 1; }

    local location
    location=$(find_instinct "$id") || {
        echo "ERROR: instinct '${id}' not found in any tier" >&2
        exit 1
    }

    local tier file
    tier="${location%%:*}"
    file="${location#*:}"

    local obs
    obs=$(get_yaml_field "$file" "observations")
    local new_obs=$(( obs + 1 ))
    local ts
    ts=$(now_iso)

    set_yaml_field "$file" "observations" "$new_obs"
    set_yaml_field "$file" "last_reinforced" "$ts"

    log_activity "REINFORCE ${tier}/${id} observations=${new_obs} last_reinforced=${ts}"
    echo "Reinforced: ${file} (observations: ${obs} -> ${new_obs})"
}

# ── Command: retire ───────────────────────────────────────────────────────
cmd_retire() {
    local id=""
    local reason=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --id)     id="$2";     shift 2 ;;
            --reason) reason="$2"; shift 2 ;;
            *) echo "ERROR: unknown option: $1" >&2; exit 1 ;;
        esac
    done

    [[ -z "$id" ]] && { echo "ERROR: --id <instinct-id> required" >&2; exit 1; }
    [[ -z "$reason" ]] && { echo "ERROR: --reason <text> required for audit trail" >&2; exit 1; }

    local location
    location=$(find_instinct "$id") || {
        echo "ERROR: instinct '${id}' not found in any tier" >&2
        exit 1
    }

    local tier file
    tier="${location%%:*}"
    file="${location#*:}"

    # Special audit for promoted demotion
    local was_promoted=0
    [[ "$tier" == "promoted" ]] && was_promoted=1

    ensure_dirs
    local dest="${INSTINCT_ROOT}/retired/${id}.yaml"
    mv "$file" "$dest"

    local ts
    ts=$(now_iso)
    set_yaml_field "$dest" "status" "retired"
    set_yaml_field "$dest" "retired_date" "$ts"
    set_yaml_field "$dest" "retired_reason" "\"${reason}\""

    log_activity "RETIRE ${tier}/${id} -> retired/${id} reason=\"${reason}\""

    # Promoted demotion is a notable decision — also log via aegis-log-decision.sh
    if [[ $was_promoted -eq 1 ]]; then
        local log_script="${REPO_ROOT}/tools/aegis-log-decision.sh"
        if [[ -f "$log_script" ]]; then
            bash "$log_script" \
                --decision "RETIRE_PROMOTED_INSTINCT" \
                --rationale "Promoted instinct '${id}' retired: ${reason}" \
                --by "aegis-instinct-promote" 2>/dev/null || true
        fi
    fi

    echo "Retired: ${dest}"
}

# ── Command: list ─────────────────────────────────────────────────────────
cmd_list() {
    local tier_filter="all"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --tier) tier_filter="$2"; shift 2 ;;
            *) echo "ERROR: unknown option: $1" >&2; exit 1 ;;
        esac
    done

    local tiers_to_scan=()
    if [[ "$tier_filter" == "all" ]]; then
        tiers_to_scan=("${TIERS[@]}")
    else
        tiers_to_scan=("$tier_filter")
    fi

    # Header
    printf "%-40s  %-10s  %-10s  %-12s  %-20s\n" \
        "ID" "STATUS" "CONFIDENCE" "OBSERVATIONS" "CLUSTER"
    printf "%s\n" "$(printf '%0.s-' {1..100})"

    local found=0
    for tier in "${tiers_to_scan[@]}"; do
        local tier_dir="${INSTINCT_ROOT}/${tier}"
        [[ -d "$tier_dir" ]] || continue
        for f in "${tier_dir}"/*.yaml; do
            [[ -f "$f" ]] || continue
            local id status confidence observations cluster
            id=$(get_yaml_field "$f" "id")
            status=$(get_yaml_field "$f" "status")
            confidence=$(get_yaml_field "$f" "confidence")
            observations=$(get_yaml_field "$f" "observations")
            cluster=$(get_yaml_field "$f" "cluster")
            printf "%-40s  %-10s  %-10s  %-12s  %-20s\n" \
                "$id" "$status" "$confidence" "$observations" "$cluster"
            found=$(( found + 1 ))
        done
    done

    if [[ $found -eq 0 ]]; then
        echo "(no instincts found for tier: ${tier_filter})"
    fi
}

# ── Command dispatch ──────────────────────────────────────────────────────
if [[ $# -eq 0 ]]; then
    cat >&2 << 'USAGE'
Usage: aegis-instinct-promote.sh <command> [options]

Commands:
  create    --from <resonance-file> [--id <kebab-id>] [--cluster <name>]
  activate  --id <instinct-id>
  promote   --id <instinct-id> [--adr <adr-file>]
  reinforce --id <instinct-id>
  retire    --id <instinct-id> --reason <text>
  list      [--tier pending|active|promoted|retired|all]
USAGE
    exit 1
fi

COMMAND="$1"
shift

case "$COMMAND" in
    create)   cmd_create   "$@" ;;
    activate) cmd_activate "$@" ;;
    promote)  cmd_promote  "$@" ;;
    reinforce) cmd_reinforce "$@" ;;
    retire)   cmd_retire   "$@" ;;
    list)     cmd_list     "$@" ;;
    *)
        echo "ERROR: unknown command: $COMMAND" >&2
        exit 1
        ;;
esac
