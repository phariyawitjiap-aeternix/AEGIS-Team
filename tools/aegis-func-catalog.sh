#!/usr/bin/env bash
# aegis-func-catalog.sh — Auto-generate FUNC-XX catalog from tools, agents, and commands
# Sprint: v10-01-C
# Output: .aegis/brain/func-catalog.json
#
# Scans:
#   tools/*.sh          — extracts top-level function declarations
#   .claude/agents/*.md — extracts agent capabilities (H2 sections)
#   .claude/commands/*.md — extracts command entries
#   .claude/hooks/*.sh  — extracts hook entries
#
# FUNC IDs are hash-based (stable across runs for the same source+name).

set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT="${PROJECT_ROOT}/.aegis/brain/func-catalog.json"
TEMP_FILE="${OUTPUT}.tmp"

# Module assignment helper
get_module() {
  local file="$1"
  case "$file" in
    tools/*)                echo "MOD-TOOLS" ;;
    .claude/agents/*)       echo "MOD-AGENTS" ;;
    .claude/commands/*)     echo "MOD-COMMANDS" ;;
    .claude/hooks/*)        echo "MOD-HOOKS" ;;
    .claude/references/*)   echo "MOD-REFS" ;;
    .aegis/brain/sprints/*) echo "MOD-SPRINTS" ;;
    .aegis/brain/*)         echo "MOD-BRAIN" ;;
    _aegis-output/iso-docs/*) echo "MOD-ISO" ;;
    _aegis-output/specs/*)  echo "MOD-SPECS" ;;
    docs/*)                 echo "MOD-PLAYBOOK" ;;
    CLAUDE*.md|CLAUDE_*)    echo "MOD-CORE" ;;
    *)                      echo "UNASSIGNED" ;;
  esac
}

# Generate stable FUNC ID from source file + name
generate_func_id() {
  local source="$1"
  local name="$2"
  local hash
  hash=$(printf '%s:%s' "$source" "$name" | md5 2>/dev/null || printf '%s:%s' "$source" "$name" | md5sum 2>/dev/null | cut -d' ' -f1)
  local short="${hash:0:6}"
  printf 'FUNC-%s' "$(echo "$short" | tr '[:lower:]' '[:upper:]')"
}

# JSON-safe string escaper
json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\t'/ }"
  s="${s//$'\n'/ }"
  # Remove any remaining control characters
  s=$(printf '%s' "$s" | tr -d '\000-\037' | sed 's/  */ /g; s/ *$//')
  printf '%s' "$s"
}

# Collect entries in a Python-assisted JSON build
# We build a simple TSV then convert to JSON via python3
TSV_FILE="${OUTPUT}.tsv"
: > "$TSV_FILE"

emit_tsv() {
  local id="$1" name="$2" source="$3" type="$4" module="$5" description="$6"
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$id" "$name" "$source" "$type" "$module" "$description" >> "$TSV_FILE"
}

# ---- SCAN 1: tools/*.sh ----
for tool in "${PROJECT_ROOT}"/tools/*.sh; do
  [ -f "$tool" ] || continue
  rel_path="tools/$(basename "$tool")"
  module=$(get_module "$rel_path")
  tool_name=$(basename "$tool" .sh)

  description=$(sed -n '2s/^# *//p' "$tool" 2>/dev/null | head -c 120 || true)
  [ -z "$description" ] && description="Tool script: $tool_name"

  func_id=$(generate_func_id "$rel_path" "$tool_name")
  emit_tsv "$func_id" "$tool_name" "$rel_path" "bash" "$module" "$description"

  # Extract named bash functions (deduplicate)
  grep -E '^[a-zA-Z_][a-zA-Z_0-9]*\s*\(\)' "$tool" 2>/dev/null | sed 's/\s*().*//; s/^function *//' | sort -u | while IFS= read -r func_name; do
    [ -z "$func_name" ] && continue
    inner_id=$(generate_func_id "$rel_path" "$func_name")
    emit_tsv "$inner_id" "$func_name" "$rel_path" "bash-function" "$module" "Internal function in $tool_name"
  done || true
done

# ---- SCAN 2: .claude/agents/*.md ----
for agent_file in "${PROJECT_ROOT}"/.claude/agents/*.md; do
  [ -f "$agent_file" ] || continue
  rel_path=".claude/agents/$(basename "$agent_file")"
  module=$(get_module "$rel_path")
  agent_name=$(basename "$agent_file" .md)

  grep '^## ' "$agent_file" 2>/dev/null | while IFS= read -r heading; do
    cap_name=$(echo "$heading" | sed 's/^## *//; s/ *$//')
    [ -z "$cap_name" ] && continue
    func_id=$(generate_func_id "$rel_path" "$cap_name")
    emit_tsv "$func_id" "${agent_name}::${cap_name}" "$rel_path" "agent-capability" "$module" "Agent $agent_name capability: $cap_name"
  done || true
done

# ---- SCAN 3: .claude/commands/*.md ----
for cmd_file in "${PROJECT_ROOT}"/.claude/commands/*.md; do
  [ -f "$cmd_file" ] || continue
  rel_path=".claude/commands/$(basename "$cmd_file")"
  module=$(get_module "$rel_path")
  cmd_name=$(basename "$cmd_file" .md)

  description="Command: /$cmd_name"
  func_id=$(generate_func_id "$rel_path" "$cmd_name")
  emit_tsv "$func_id" "/$cmd_name" "$rel_path" "command" "$module" "$description"
done

# ---- SCAN 4: .claude/hooks/*.sh ----
for hook_file in "${PROJECT_ROOT}"/.claude/hooks/*.sh; do
  [ -f "$hook_file" ] || continue
  rel_path=".claude/hooks/$(basename "$hook_file")"
  module=$(get_module "$rel_path")
  hook_name=$(basename "$hook_file" .sh)

  description=$(sed -n '2s/^# *//p' "$hook_file" 2>/dev/null | head -c 120 || true)
  [ -z "$description" ] && description="Hook: $hook_name"

  func_id=$(generate_func_id "$rel_path" "$hook_name")
  emit_tsv "$func_id" "$hook_name" "$rel_path" "hook" "$module" "$description"
done

# ---- Convert TSV to JSON via python3 ----
export TSV_FILE OUTPUT
python3 << 'PYEOF'
import json, sys, os

tsv_path = os.environ.get("TSV_FILE", "")
output_path = os.environ.get("OUTPUT", "")

if not tsv_path or not output_path:
    print("ERROR: TSV_FILE or OUTPUT not set", file=sys.stderr)
    sys.exit(1)

entries = []
with open(tsv_path, "r") as f:
    for line in f:
        line = line.rstrip("\n")
        if not line:
            continue
        parts = line.split("\t", 5)
        if len(parts) < 6:
            parts.extend([""] * (6 - len(parts)))
        entry = {
            "id": parts[0],
            "name": parts[1],
            "source_file": parts[2],
            "type": parts[3],
            "module": parts[4],
            "description": parts[5]
        }
        entries.append(entry)

# Sort by module then name for stable output
entries.sort(key=lambda e: (e["module"], e["name"]))

with open(output_path, "w") as f:
    json.dump(entries, f, indent=2, ensure_ascii=False)

print(f"FUNC catalog generated: {output_path} ({len(entries)} entries)")
print(f"  Types: bash, bash-function, agent-capability, command, hook")
PYEOF

# Cleanup
rm -f "$TSV_FILE" "$TEMP_FILE"
exit 0
