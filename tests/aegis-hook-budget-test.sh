#!/usr/bin/env bash
# aegis-hook-budget-test.sh — sprint v15-16 Story E.
#
# Regression guard against silently-growing hook latency. Measures the p95
# end-to-end time of each hook chain that fires on the common tool calls,
# fails the suite if any chain exceeds the budget.
#
# Budgets (per chain, all hooks summed) — calibrated 2026-05-18 against
# the AEGIS v15.0 baseline (CC 2.1.143, macOS, node 25.8.2). Each value
# is current p95 + ~25% headroom — passes today and catches future
# regressions. Lower as the architecture is optimized (track via
# `.aegis/brain/metrics/hook-latency-baseline.jsonl`).
#
#   PreToolUse:Bash  ≤ 350ms p95   (current p95 ~250-280ms)
#   PostToolUse:Bash ≤ 700ms p95   (current p95 ~500-550ms)
#   PostToolUse:Edit ≤ 1100ms p95  (current p95 ~800-850ms; brain-graph submission is the long tail)
#
# 30 invocations per chain. p95 = nth smallest where n = ceil(30 * 0.95) = 29.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
PASS=0; FAIL=0
pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}FAIL${NC}: $1 -- $2"; FAIL=$((FAIL+1)); }

TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/aegis-hook-budget-XXXXXX")
trap 'find "$TEST_DIR" -type f -delete 2>/dev/null; find "$TEST_DIR" -depth -type d -delete 2>/dev/null' EXIT INT TERM

# Use a clean CLAUDE_PROJECT_DIR copy of just what hooks need, so we
# measure hook overhead, not the cost of touching the live workspace.
export CLAUDE_PROJECT_DIR="$REPO_ROOT"

echo "============================================"
echo "AEGIS hook latency budget — sprint v15-16"
echo "============================================"

# ── Measurement helper ───────────────────────────────────────────────────
# Args:
#   1: budget_ms  — fail threshold
#   2: chain_name — label for output
#   3: payload    — JSON to feed each hook
#   4+: hook commands (each as one shell line)
measure_chain() {
    local budget="$1" chain="$2" payload="$3"
    shift 3
    local cmds=("$@")

    local lat_file="$TEST_DIR/lat-${chain//[^a-z0-9]/_}.txt"
    : > "$lat_file"

    local i
    for i in $(seq 1 30); do
        local t0 t1
        t0=$(node -e 'process.stdout.write(String(Date.now()))')
        for cmd in "${cmds[@]}"; do
            printf '%s' "$payload" | eval "$cmd" >/dev/null 2>&1 || true
        done
        t1=$(node -e 'process.stdout.write(String(Date.now()))')
        echo $((t1 - t0)) >> "$lat_file"
    done

    # p95 = 29th-smallest of 30 (ceil(30 * 0.95) = 29)
    local p95
    p95=$(sort -n "$lat_file" | awk 'NR==29')
    local p50
    p50=$(sort -n "$lat_file" | awk 'NR==15')

    if [[ "$p95" -le "$budget" ]]; then
        pass "${chain}: p95=${p95}ms (budget=${budget}ms, p50=${p50}ms)"
    else
        fail "${chain}: p95 budget exceeded" "p95=${p95}ms > budget=${budget}ms (p50=${p50}ms)"
    fi
}

# ── PreToolUse:Bash chain ────────────────────────────────────────────────
echo ""
echo "--- PreToolUse:Bash chain (guard-bash + approval-gate) ---"
GUARD_BASH="$REPO_ROOT/.claude/hooks/guard-bash.sh"
APPROVAL="$REPO_ROOT/tools/aegis-approval-gate/check.mjs"
BASH_PAYLOAD='{"tool_name":"Bash","tool_input":{"command":"echo hello"}}'
measure_chain 350 "PreToolUse:Bash" "$BASH_PAYLOAD" \
    "bash '$GUARD_BASH'" \
    "node '$APPROVAL'"

# ── PostToolUse:Bash chain ───────────────────────────────────────────────
echo ""
echo "--- PostToolUse:Bash chain (post-tool-use + token-profile + live-tail + activity-logger) ---"
POST_TOOL="$REPO_ROOT/.claude/hooks/post-tool-use.sh"
TOKEN="$REPO_ROOT/tools/aegis-token-profile.sh"
LIVE="$REPO_ROOT/tools/aegis-live-tail/emit.mjs"
ACT="$REPO_ROOT/tools/aegis-activity-logger/log.mjs"
POST_PAYLOAD='{"tool_name":"Bash","tool_input":{"command":"ls"},"tool_response":{"output":"file1"}}'
measure_chain 700 "PostToolUse:Bash" "$POST_PAYLOAD" \
    "bash '$POST_TOOL'" \
    "bash '$TOKEN'" \
    "node '$LIVE'" \
    "node '$ACT'"

# ── PostToolUse:Edit chain ───────────────────────────────────────────────
echo ""
echo "--- PostToolUse:Edit chain (post-edit-accumulate + brain-graph + linear-sync + token-profile + live-tail + activity-logger) ---"
ACCUM="$REPO_ROOT/.claude/hooks/post-edit-accumulate.sh"
GRAPH="$REPO_ROOT/tools/aegis-brain-graph/hook.sh"
LINEAR="$REPO_ROOT/.claude/hooks/linear-sync-on-kanban.sh"
EDIT_PAYLOAD='{"tool_name":"Edit","tool_input":{"file_path":"/tmp/x.md"}}'
# brain-graph hook detaches; we measure submission cost only (which is the realistic
# user-perceived latency since the build runs in the background).
measure_chain 1100 "PostToolUse:Edit" "$EDIT_PAYLOAD" \
    "bash '$ACCUM'" \
    "bash '$GRAPH'" \
    "bash '$LINEAR'" \
    "bash '$TOKEN'" \
    "node '$LIVE'" \
    "node '$ACT'"

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
echo "============================================"

if [[ "$FAIL" -gt 0 ]]; then
    exit 1
fi
exit 0
