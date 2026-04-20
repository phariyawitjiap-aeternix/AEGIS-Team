#!/usr/bin/env bash
# AEGIS Agent Tools Matrix (dogfood-observation #2 -- subagent tool availability pre-flight)
#
# Scans every active agent in .claude/agents/ (ignoring _archived/) and extracts
# the `tools:` list from YAML frontmatter. Outputs a matrix showing which agents
# have which tools, so spec authors can verify before assuming a subagent can
# call tool X.
#
# Modes:
#   (default)    -- print a human-readable table
#   --check <tool>  -- list only agents that have <tool>
#   --agent <name>  -- list only tools for <name>
#   --json          -- emit structured JSON
#
# Exit codes:
#   0 = ok
#   1 = parse error / no agents found
#   2 = usage error

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
AGENTS_DIR="${REPO_ROOT}/.claude/agents"

MODE="table"
FILTER_TOOL=""
FILTER_AGENT=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --check)
            MODE="check"
            FILTER_TOOL="${2:-}"
            [[ -z "$FILTER_TOOL" ]] && { echo "ERROR: --check requires a tool name" >&2; exit 2; }
            shift 2
            ;;
        --agent)
            MODE="agent"
            FILTER_AGENT="${2:-}"
            [[ -z "$FILTER_AGENT" ]] && { echo "ERROR: --agent requires a name" >&2; exit 2; }
            shift 2
            ;;
        --json)
            MODE="json"
            shift
            ;;
        -h|--help)
            cat <<EOF
Usage: aegis-agent-tools-matrix.sh [mode]

Modes:
  (default)          Print a human-readable matrix.
  --check <tool>     List only agents that have <tool>.
  --agent <name>     List only tools for <name>.
  --json             Emit structured JSON { "agent": ["tool1", ...] }.

Examples:
  ./tools/aegis-agent-tools-matrix.sh
  ./tools/aegis-agent-tools-matrix.sh --check memory_20250818
  ./tools/aegis-agent-tools-matrix.sh --agent nick-fury
  ./tools/aegis-agent-tools-matrix.sh --json
EOF
            exit 0
            ;;
        *)
            echo "ERROR: unknown arg: $1" >&2
            exit 2
            ;;
    esac
done

[[ -d "$AGENTS_DIR" ]] || { echo "ERROR: $AGENTS_DIR not found" >&2; exit 1; }

# Collect agent → tool-list via python3 (handles YAML reliably)
# Output: TSV "agent<TAB>tool1,tool2,..."
DATA=$(python3 - "$AGENTS_DIR" <<'PY' 2>/dev/null
import os, re, sys
agents_dir = sys.argv[1]
results = []
for fname in sorted(os.listdir(agents_dir)):
    if not fname.endswith(".md"):
        continue
    path = os.path.join(agents_dir, fname)
    if not os.path.isfile(path):
        continue
    name = fname[:-3]
    try:
        with open(path) as f:
            content = f.read()
    except Exception:
        continue
    # Extract frontmatter (first block between --- ... ---)
    m = re.match(r'^---\n(.*?)\n---', content, re.DOTALL)
    if not m:
        continue
    fm = m.group(1)
    # Find tools: line. Accept: tools: [a, b, c] OR tools:\n  - a\n  - b
    tools = []
    inline = re.search(r'^tools:\s*\[(.*?)\]', fm, re.MULTILINE)
    if inline:
        tools = [t.strip().strip('"').strip("'") for t in inline.group(1).split(",") if t.strip()]
    else:
        block = re.search(r'^tools:\s*\n((?:  *-\s*.+\n?)+)', fm, re.MULTILINE)
        if block:
            for line in block.group(1).splitlines():
                t = line.strip().lstrip("-").strip().strip('"').strip("'")
                if t:
                    tools.append(t)
    results.append((name, tools))
for name, tools in results:
    print(f"{name}\t{','.join(tools)}")
PY
)

[[ -z "$DATA" ]] && { echo "ERROR: no agents with parseable frontmatter found" >&2; exit 1; }

GREEN='\033[0;32m'
RED='\033[0;31m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

case "$MODE" in
    check)
        echo -e "${BOLD}Agents with tool: ${FILTER_TOOL}${NC}"
        echo "─────────────────────────────────────"
        FOUND=0
        while IFS=$'\t' read -r agent tools; do
            if echo ",$tools," | grep -qi ",${FILTER_TOOL},"; then
                echo -e "  ${GREEN}✓${NC} $agent"
                FOUND=$((FOUND + 1))
            fi
        done <<< "$DATA"
        echo "─────────────────────────────────────"
        echo "Total: $FOUND agent(s) have '$FILTER_TOOL'"
        [[ "$FOUND" == "0" ]] && exit 1
        ;;

    agent)
        found_line=""
        while IFS=$'\t' read -r agent tools; do
            if [[ "$agent" == "$FILTER_AGENT" ]]; then
                found_line="$tools"
                break
            fi
        done <<< "$DATA"
        if [[ -z "$found_line" ]]; then
            echo "ERROR: agent '$FILTER_AGENT' not found. Available:" >&2
            echo "$DATA" | cut -f1 | sed 's/^/  /'
            exit 1
        fi
        echo -e "${BOLD}Tools for: ${FILTER_AGENT}${NC}"
        echo "─────────────────────────────────────"
        IFS=',' read -ra tool_arr <<< "$found_line"
        for t in "${tool_arr[@]}"; do
            echo "  - $t"
        done
        echo "─────────────────────────────────────"
        echo "Total: ${#tool_arr[@]} tool(s)"
        ;;

    json)
        echo "{"
        first=1
        while IFS=$'\t' read -r agent tools; do
            [[ -z "$agent" ]] && continue
            [[ "$first" == "0" ]] && echo ","
            first=0
            printf '  "%s": [' "$agent"
            IFS=',' read -ra tool_arr <<< "$tools"
            for i in "${!tool_arr[@]}"; do
                [[ "$i" -gt "0" ]] && printf ', '
                printf '"%s"' "${tool_arr[$i]}"
            done
            printf ']'
        done <<< "$DATA"
        echo ""
        echo "}"
        ;;

    table)
        echo -e "${BOLD}AEGIS Agent → Tools Matrix${NC}"
        echo "─────────────────────────────────────"
        printf "%-20s  %s\n" "Agent" "Tools"
        printf "%-20s  %s\n" "--------------------" "-----"
        while IFS=$'\t' read -r agent tools; do
            [[ -z "$agent" ]] && continue
            # Wrap tools list at ~70 chars for readability
            printf "%-20s  %s\n" "$agent" "$tools"
        done <<< "$DATA"
        echo "─────────────────────────────────────"
        TOTAL=$(echo "$DATA" | wc -l | tr -d ' ')
        echo "$TOTAL agents parsed."
        echo ""
        echo -e "${DIM}Use --check <tool> or --agent <name> to filter; --json for machine-readable.${NC}"
        ;;
esac
