#!/usr/bin/env bash
# aegis-sdk-readiness-check.sh -- Reports SDK feature availability for AEGIS.
#
# Non-blocking scanner that checks which SDK features AEGIS depends on
# are available in the current runtime. Useful for deciding which
# integration paths (ADR-006 phases) are viable.
#
# Exit codes:
#   0  Report generated (does not imply all features available)
#   1  Usage error
#
# Usage:
#   bash tools/aegis-sdk-readiness-check.sh [--json] [--check <feature>]
#
# Features checked:
#   memory_20250818     Claude's built-in cross-session memory tool
#   agent_teams         Experimental agent teams support (CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS)
#   code_execution      Code execution tool (code_execution_20260120)
#   worktree_isolation  Git worktree isolation for agents
#   adaptive_thinking   Adaptive thinking / effort levels
#   prompt_caching      Prompt caching for repeated context
#
# Sprint: sprint-v9-06 / PATH B (SDK-adjacent prep)
# ADR: ADR-006 (Nick Fury proxy dispatch + memory integration)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
JSON_MODE=false
CHECK_FEATURE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --json)   JSON_MODE=true;        shift ;;
        --check)  CHECK_FEATURE="$2";    shift 2 ;;
        -h|--help)
            echo "Usage: aegis-sdk-readiness-check.sh [--json] [--check <feature>]"
            echo ""
            echo "Reports which SDK features AEGIS depends on are available."
            echo ""
            echo "Features: memory_20250818, agent_teams, code_execution,"
            echo "          worktree_isolation, adaptive_thinking, prompt_caching"
            exit 0 ;;
        *) echo "ERROR: Unknown arg: $1" >&2; exit 1 ;;
    esac
done

# ── Feature detection functions ───────────────────────────────────────────

check_memory_tool() {
    # memory_20250818 is detected by checking if the Claude Code runtime
    # exposes the tool. From a bash context, we can only check:
    # 1. Does the env suggest it's available?
    # 2. Does the agent config reference it?
    local status="unavailable"
    local evidence="no detection method from bash context"

    # Check if any agent definition references memory tool
    if grep -rq "memory_20250818\|memory_tool\|/memories" "$REPO_ROOT/.claude/agents/" 2>/dev/null; then
        evidence="referenced in agent definitions but runtime availability unknown from bash"
    fi

    # Check if MEMORY.md or memory directory exists (indicates past usage)
    if [[ -d "$HOME/.claude/projects" ]]; then
        local mem_dirs
        mem_dirs=$(find "$HOME/.claude/projects" -name "MEMORY.md" -maxdepth 3 2>/dev/null | head -1)
        if [[ -n "$mem_dirs" ]]; then
            status="likely_available"
            evidence="MEMORY.md exists at $mem_dirs (indicates active memory integration)"
        fi
    fi

    echo "$status|$evidence"
}

check_agent_teams() {
    local status="unavailable"
    local evidence=""

    if [[ "${CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS:-}" == "1" ]]; then
        status="available"
        evidence="CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 in environment"
    elif grep -q "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS.*1" "$REPO_ROOT/.claude/settings.json" 2>/dev/null; then
        status="configured"
        evidence="set in settings.json but env not verified"
    else
        evidence="CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS not set"
    fi

    echo "$status|$evidence"
}

check_code_execution() {
    local status="unavailable"
    local evidence="code_execution_20260120 availability unknown from bash"

    # Check if any agent references code execution
    if grep -rq "code_execution" "$REPO_ROOT/.claude/agents/" 2>/dev/null; then
        status="referenced"
        evidence="referenced in agent definitions; runtime availability depends on Claude Code version"
    fi

    echo "$status|$evidence"
}

check_worktree_isolation() {
    local status="unavailable"
    local evidence=""

    # Check if git worktree is available
    if git worktree list >/dev/null 2>&1; then
        status="git_available"
        evidence="git worktree command works; agent-level isolation depends on SDK support"
    fi

    # Check if isolation config exists
    if grep -rq "isolation.*worktree\|worktree.*isolation" "$REPO_ROOT/.claude/agents/" 2>/dev/null; then
        status="referenced"
        evidence="referenced in agent definitions; SDK-level enforcement unverified"
    fi

    echo "$status|$evidence"
}

check_adaptive_thinking() {
    local status="likely_available"
    local evidence="adaptive thinking is a model capability, not a tool; available with Claude 4+ models"

    echo "$status|$evidence"
}

check_prompt_caching() {
    local status="likely_available"
    local evidence="prompt caching is a platform feature; available through Anthropic API; Claude Code handles automatically"

    echo "$status|$evidence"
}

# ── Run checks ────────────────────────────────────────────────────────────

declare -a FEATURES=(
    "memory_20250818"
    "agent_teams"
    "code_execution"
    "worktree_isolation"
    "adaptive_thinking"
    "prompt_caching"
)

declare -a STATUSES=()
declare -a EVIDENCES=()

for feat in "${FEATURES[@]}"; do
    if [[ -n "$CHECK_FEATURE" && "$feat" != "$CHECK_FEATURE" ]]; then
        continue
    fi

    case "$feat" in
        memory_20250818)     result=$(check_memory_tool) ;;
        agent_teams)         result=$(check_agent_teams) ;;
        code_execution)      result=$(check_code_execution) ;;
        worktree_isolation)  result=$(check_worktree_isolation) ;;
        adaptive_thinking)   result=$(check_adaptive_thinking) ;;
        prompt_caching)      result=$(check_prompt_caching) ;;
    esac

    status="${result%%|*}"
    evidence="${result#*|}"
    STATUSES+=("$status")
    EVIDENCES+=("$evidence")
done

# ── Output ────────────────────────────────────────────────────────────────

if [[ "$JSON_MODE" == true ]]; then
    # Write features as newline-delimited to a temp file for safe parsing
    _json_tmp=$(mktemp "${TMPDIR:-/tmp}/aegis-sdk-XXXXXX")
    for (( i=0; i<${#FEATURES[@]}; i++ )); do
        echo "${FEATURES[$i]}	${STATUSES[$i]}	${EVIDENCES[$i]}" >> "$_json_tmp"
    done
    python3 - "$_json_tmp" <<'PYEOF'
import json, sys
path = sys.argv[1]
report = {"features": {}}
statuses_list = []
with open(path) as f:
    for line in f:
        parts = line.strip().split("\t", 2)
        if len(parts) == 3:
            feat, status, evidence = parts
            report["features"][feat] = {"status": status, "evidence": evidence}
            statuses_list.append(status)
available_count = sum(1 for s in statuses_list if s in ("available", "likely_available", "configured"))
report["summary"] = {
    "total": len(statuses_list),
    "available_or_likely": available_count,
    "readiness_pct": round(available_count / max(len(statuses_list), 1) * 100, 1),
}
print(json.dumps(report, indent=2))
PYEOF
    rm -f "$_json_tmp"
else
    echo "=== AEGIS SDK Readiness Check ==="
    echo ""
    echo "Checking ${#FEATURES[@]} features for ADR-006 integration readiness:"
    echo ""

    available_count=0
    for (( i=0; i<${#FEATURES[@]}; i++ )); do
        feat="${FEATURES[$i]}"
        status="${STATUSES[$i]}"
        evidence="${EVIDENCES[$i]}"

        case "$status" in
            available|likely_available|configured)
                icon="[OK]"
                available_count=$(( available_count + 1 ))
                ;;
            referenced)
                icon="[??]"
                ;;
            *)
                icon="[--]"
                ;;
        esac

        printf "  %-22s %s  %s\n" "$feat" "$icon" "$status"
        if [[ -n "$evidence" ]]; then
            printf "    %s\n" "$evidence"
        fi
        echo ""
    done

    echo "Summary: $available_count/${#FEATURES[@]} features available or likely available"
fi

exit 0
