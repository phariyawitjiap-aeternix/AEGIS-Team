#!/usr/bin/env bash
# AEGIS BLOCK 0 Lite-Mode Security Path Override (Sprint v9-02 S2-04)
#
# Implements Loki's pre-review security-path scan. When a task is tagged
# lite or standard but its diff touches security-sensitive paths, this
# script overrides block0_mode to full, increments the override counter,
# and emits a [LOKI:override] log line to activity.log.
#
# Usage (task meta.json mode):
#   ./tools/aegis-s204-override.sh --task-id <ID>
#   (reads task from .aegis/brain/tasks/<ID>/meta.json)
#
# Usage (direct paths mode):
#   ./tools/aegis-s204-override.sh --paths "<file1 file2 ...>"
#   (accepts space-separated file path list; honours AEGIS_TEST_META env var)
#
# Environment overrides (for testing):
#   COUNTER_FILE   — override counter path
#   ACTIVITY_LOG   — activity log path
#   TASKS_DIR      — tasks directory
#   SECURITY_PATHS_SH — security paths registry script
#   AEGIS_TEST_META   — meta.json path when using --paths mode
#
# Exit codes:
#   0 = success (override applied OR no override needed)
#   1 = usage/parse error
#   2 = internal error

set -euo pipefail

# ---------------------------------------------------------------------------
# Resolve paths (allow env overrides for testing)
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

COUNTER_FILE="${COUNTER_FILE:-${REPO_ROOT}/.aegis/brain/state/override-counter.json}"
ACTIVITY_LOG="${ACTIVITY_LOG:-${REPO_ROOT}/.aegis/brain/logs/activity.log}"
TASKS_DIR="${TASKS_DIR:-${REPO_ROOT}/.aegis/brain/tasks}"
SECURITY_PATHS_SH="${SECURITY_PATHS_SH:-${SCRIPT_DIR}/aegis-security-paths.sh}"

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------
usage() {
  echo "Usage: $0 --task-id <ID> | --paths \"<file1 file2 ...>\"" >&2
  exit 1
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
TASK_ID=""
PATHS_ARG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --task-id)
      TASK_ID="${2:-}"
      [[ -z "$TASK_ID" ]] && { echo "ERROR: --task-id requires a value" >&2; usage; }
      shift 2
      ;;
    --paths)
      PATHS_ARG="${2:-}"
      [[ -z "$PATHS_ARG" ]] && { echo "ERROR: --paths requires a value" >&2; usage; }
      shift 2
      ;;
    *)
      echo "ERROR: unknown argument: $1" >&2
      usage
      ;;
  esac
done

if [[ -z "$TASK_ID" && -z "$PATHS_ARG" ]]; then
  usage
fi

# ---------------------------------------------------------------------------
# Resolve meta.json path
# ---------------------------------------------------------------------------
META_JSON=""
if [[ -n "$TASK_ID" ]]; then
  META_JSON="${TASKS_DIR}/${TASK_ID}/meta.json"
  if [[ ! -f "$META_JSON" ]]; then
    echo "ERROR: meta.json not found: ${META_JSON}" >&2
    exit 2
  fi
elif [[ -n "${AEGIS_TEST_META:-}" ]]; then
  META_JSON="${AEGIS_TEST_META}"
fi

# ---------------------------------------------------------------------------
# Extract block0_mode from a meta.json file; returns "full" if absent
# ---------------------------------------------------------------------------
get_mode_from_meta() {
  local meta="$1"
  local mode
  mode=$(grep -o '"block0_mode"[[:space:]]*:[[:space:]]*"[^"]*"' "$meta" 2>/dev/null \
    | grep -o '"[^"]*"$' | tr -d '"') || true
  if [[ -z "$mode" ]]; then
    echo "full"
  else
    echo "$mode"
  fi
}

# ---------------------------------------------------------------------------
# Map regex pattern to category name
# ---------------------------------------------------------------------------
pattern_to_category() {
  local pattern="$1"
  case "$pattern" in
    *"auth/"*) echo "auth" ;;
    *"credentials/"*) echo "credentials" ;;
    *"\.env"*) echo "env" ;;
    *"secrets/"*) echo "secrets" ;;
    *"\.ssh/"*) echo "ssh" ;;
    *"tokens/"*) echo "tokens" ;;
    *"\.claude/agents/"*) echo "agent-prompts" ;;
    *"password"*) echo "credentials" ;;
    *"secret"*) echo "secrets" ;;
    *"api-key"*) echo "credentials" ;;
    *) echo "unknown" ;;
  esac
}

# ---------------------------------------------------------------------------
# Match file list against security patterns.
# Prints "category:path" for first match, or nothing if no match.
# ---------------------------------------------------------------------------
find_security_match() {
  local files_list="$1"
  local pattern category

  while IFS= read -r pattern; do
    [[ -z "$pattern" ]] && continue
    # Use newline-delimited iteration to handle paths with spaces
    while IFS= read -r file_path; do
      [[ -z "$file_path" ]] && continue
      if echo "$file_path" | grep -qE "$pattern"; then
        category=$(pattern_to_category "$pattern")
        echo "${category}:${file_path}"
        return 0
      fi
    done <<< "$files_list"
  done < <(bash "$SECURITY_PATHS_SH")

  return 0
}

# ---------------------------------------------------------------------------
# Initialize override counter if missing
# ---------------------------------------------------------------------------
init_counter_if_missing() {
  if [[ ! -f "$COUNTER_FILE" ]]; then
    mkdir -p "$(dirname "$COUNTER_FILE")"
    COUNTER_FILE_PY="$COUNTER_FILE" \
    python3 - <<'PYEOF'
import json, os
data = {
    'total_overrides': 0,
    'last_override_at': None,
    'by_category': {
        'auth': 0, 'credentials': 0, 'env': 0,
        'secrets': 0, 'ssh': 0, 'tokens': 0, 'agent-prompts': 0
    },
    'recent': []
}
with open(os.environ['COUNTER_FILE_PY'], 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
PYEOF
  fi
}

# ---------------------------------------------------------------------------
# Perform the atomic counter update (pure python3; flock when available)
# ---------------------------------------------------------------------------
do_counter_update() {
  local task_id="$1"
  local was_mode="$2"
  local trigger_path="$3"
  local category="$4"
  local now_iso="$5"
  local tmp_file
  tmp_file=$(mktemp "${COUNTER_FILE}.tmp.XXXXXX")

  COUNTER_FILE_PY="$COUNTER_FILE" \
  TMP_FILE_PY="$tmp_file" \
  TASK_ID_PY="$task_id" \
  WAS_MODE_PY="$was_mode" \
  TRIGGER_PATH_PY="$trigger_path" \
  CATEGORY_PY="$category" \
  NOW_ISO_PY="$now_iso" \
  python3 - <<'PYEOF' 2>&1
import json, os

counter_file = os.environ['COUNTER_FILE_PY']
tmp_file     = os.environ['TMP_FILE_PY']
task_id      = os.environ['TASK_ID_PY']
was_mode     = os.environ['WAS_MODE_PY']
trigger_path = os.environ['TRIGGER_PATH_PY']
category     = os.environ['CATEGORY_PY']
now_iso      = os.environ['NOW_ISO_PY']

with open(counter_file) as f:
    data = json.load(f)

data['total_overrides'] = data.get('total_overrides', 0) + 1
data['last_override_at'] = now_iso

by_cat = data.get('by_category', {})
if category in by_cat:
    by_cat[category] = by_cat.get(category, 0) + 1
data['by_category'] = by_cat

new_entry = {
    'ts': now_iso,
    'task_id': task_id,
    'was_mode': was_mode,
    'triggered_by_path': trigger_path,
    'category': category
}
recent = data.get('recent', [])
recent.insert(0, new_entry)
if len(recent) > 10:
    recent = recent[:10]
data['recent'] = recent

with open(tmp_file, 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
PYEOF

  mv "${tmp_file}" "${COUNTER_FILE}"
}

# ---------------------------------------------------------------------------
# Increment override counter with flock atomicity (macOS fallback to LWW)
# ---------------------------------------------------------------------------
increment_counter() {
  local task_id="$1"
  local was_mode="$2"
  local trigger_path="$3"
  local category="$4"
  local now_iso
  now_iso=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local lock_file="${COUNTER_FILE}.lock"

  init_counter_if_missing

  if command -v flock >/dev/null 2>&1; then
    (
      flock -x -w 5 200 || {
        echo "WARNING: flock timeout; falling back to last-writer-wins" >&2
      }
      do_counter_update "$task_id" "$was_mode" "$trigger_path" "$category" "$now_iso"
    ) 200>"${lock_file}"
  else
    echo "WARNING: flock not available; using last-writer-wins for counter update" >&2
    do_counter_update "$task_id" "$was_mode" "$trigger_path" "$category" "$now_iso"
  fi

  rm -f "${lock_file}" 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# Rewrite meta.json with block0_mode=full + block0_override audit object
# ---------------------------------------------------------------------------
rewrite_meta() {
  local meta="$1"
  local was_mode="$2"
  local trigger_path="$3"
  local now_iso
  now_iso=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  META_PATH_PY="$meta" \
  WAS_MODE_PY="$was_mode" \
  NOW_ISO_PY="$now_iso" \
  TRIGGER_PATH_PY="$trigger_path" \
  python3 - <<'PYEOF' 2>/dev/null || { echo "ERROR: python3 required for meta.json rewrite" >&2; exit 2; }
import json, os

meta         = os.environ['META_PATH_PY']
was_mode     = os.environ['WAS_MODE_PY']
now_iso      = os.environ['NOW_ISO_PY']
trigger_path = os.environ['TRIGGER_PATH_PY']

with open(meta) as f:
    data = json.load(f)
data['block0_mode'] = 'full'
data['block0_override'] = {
    'original_mode': was_mode,
    'overridden_by': 'loki',
    'overridden_at': now_iso,
    'reason': 'security-sensitive path: ' + trigger_path
}
with open(meta, 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
PYEOF
}

# ---------------------------------------------------------------------------
# Append [LOKI:override] line to activity.log
# ---------------------------------------------------------------------------
log_override() {
  local task_id="$1"
  local was_mode="$2"
  local trigger_path="$3"
  local category="$4"
  local now_iso
  now_iso=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local log_line="[${now_iso}] [LOKI:override] task=${task_id} mode ${was_mode}->full paths=[${trigger_path}] category=${category}"

  mkdir -p "$(dirname "$ACTIVITY_LOG")"
  echo "$log_line" >> "$ACTIVITY_LOG"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  local current_mode="lite"
  local files_to_scan=""

  # Determine mode and file list
  if [[ -n "$TASK_ID" ]]; then
    current_mode=$(get_mode_from_meta "$META_JSON")
    # Try to read changed_files from meta.json
    files_to_scan=$(META_JSON_PY="$META_JSON" python3 - <<'PYEOF' 2>/dev/null
import json, os
try:
    with open(os.environ['META_JSON_PY']) as f:
        d = json.load(f)
    print('\n'.join(d.get('changed_files', [])))
except Exception:
    print('')
PYEOF
) || files_to_scan=""
  else
    # --paths mode
    files_to_scan="$PATHS_ARG"
    # Determine mode from meta.json if available
    if [[ -n "$META_JSON" && -f "$META_JSON" ]]; then
      current_mode=$(get_mode_from_meta "$META_JSON")
    fi
    # If no meta.json, treat as lite (scan always applies)
  fi

  # Already full — nothing to do
  if [[ "$current_mode" == "full" ]]; then
    echo "NO_OVERRIDE mode=full (already maximum enforcement)"
    exit 0
  fi

  # Find first security-sensitive path match
  local match_result
  match_result=$(find_security_match "$files_to_scan")

  if [[ -z "$match_result" ]]; then
    echo "NO_OVERRIDE mode=${current_mode} (no security-sensitive paths detected)"
    exit 0
  fi

  local category="${match_result%%:*}"
  local trigger_path="${match_result#*:}"
  local effective_task_id="${TASK_ID:-unknown}"

  # Apply override to meta.json if we have one
  if [[ -n "$META_JSON" && -f "$META_JSON" ]]; then
    rewrite_meta "$META_JSON" "$current_mode" "$trigger_path"
  fi

  # Increment counter
  increment_counter "$effective_task_id" "$current_mode" "$trigger_path" "$category"

  # Log to activity.log
  log_override "$effective_task_id" "$current_mode" "$trigger_path" "$category"

  echo "OVERRIDE task=${effective_task_id} was=${current_mode} now=full triggered_by=${trigger_path} category=${category}"
  echo "[LOKI:override] task=${effective_task_id} was=${current_mode} now=full triggered_by=${trigger_path} category=${category} reason=security-sensitive path detected"
}

main "$@"
