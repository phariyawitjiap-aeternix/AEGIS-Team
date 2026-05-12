#!/usr/bin/env bash
# tools/aegis-goal/judge.sh
# ────────────────────────────────────────────────────────────────────────────
# POC judge for Persistent Goals (Ralph-loop pattern). Adapted from Hermes
# `/goal` lightweight judge model after each turn.
#
# Sprint:  v14-04 (S14-04-01) — POC tooling, NOT production
#
# Two modes:
#   --mode heuristic  (default) — keyword grep on response. Free, instant.
#                                 Suitable for testing the loop mechanics +
#                                 dry-run measurement before paying for real
#                                 judge calls.
#   --mode llm        — placeholder for real Claude call via routing/policy.yaml.
#                       Returns error in v14-04; wire up at measurement-campaign time.
#
# Usage:
#   echo "<response text>" | bash tools/aegis-goal/judge.sh --goal "<goal>"
#   bash tools/aegis-goal/judge.sh --goal "..." --response-file response.txt
#
# Output (single JSON line on stdout):
#   {"verdict": "yes|no|unclear", "mode": "heuristic|llm", "reason": "..."}
#
# Exit codes:
#   0 — judgment rendered (stdout has JSON)
#   1 — error (e.g., --mode llm but no integration available)
#   2 — usage error
# ────────────────────────────────────────────────────────────────────────────

set -uo pipefail

MODE="heuristic"
GOAL=""
RESPONSE_FILE=""
RESPONSE=""

usage() {
    cat >&2 <<'EOF'
Usage:
  judge.sh --goal "<text>" [--mode heuristic|llm] [--response-file <path>]
  echo "<response>" | judge.sh --goal "<text>"

Modes:
  heuristic (default) — keyword scan for done/complete/finished/etc.
  llm                 — real LLM call (NOT WIRED in v14-04 POC; returns error)

Output: single-line JSON {"verdict":"yes|no|unclear","mode":"...","reason":"..."}
EOF
    exit 2
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --goal)          GOAL="${2:-}";          shift 2 ;;
        --mode)          MODE="${2:-}";          shift 2 ;;
        --response-file) RESPONSE_FILE="${2:-}"; shift 2 ;;
        --help|-h)       usage ;;
        *)               usage ;;
    esac
done

[[ -z "$GOAL" ]] && usage

# Read response from file or stdin
if [[ -n "$RESPONSE_FILE" ]]; then
    [[ ! -f "$RESPONSE_FILE" ]] && { echo "Error: response file not found: $RESPONSE_FILE" >&2; exit 2; }
    RESPONSE=$(cat "$RESPONSE_FILE")
else
    if [[ -t 0 ]]; then
        echo "Error: no response provided (use --response-file or pipe via stdin)" >&2
        exit 2
    fi
    RESPONSE=$(cat)
fi

# ─── Mode: heuristic ─────────────────────────────────────────────────────────
heuristic_judge() {
    # Pattern set: positive completion signals.
    # Tuned by reading the start of common AEGIS retro outputs + Claude end-of-turn
    # summaries. Bias toward unclear over yes to minimize false-positive
    # auto-stops in the POC measurement.
    local response="$1"
    local goal="$2"

    # Strong positive — explicit completion language at start of line
    if echo "$response" | grep -qiE '^[[:space:]]*(✓|✅|done|complete|completed|finished|all green|all tests pass|shipped)' \
       || echo "$response" | grep -qiE 'sprint.*closed|all (steps|tasks|stories) (done|complete|shipped)'; then
        printf '{"verdict":"yes","mode":"heuristic","reason":"strong-completion-signal"}\n'
        return
    fi

    # Strong negative — explicit work-remaining language
    if echo "$response" | grep -qiE '(next step|carry.forward|TODO|in.progress|partial|deferred|blocked|stuck|error|failed)'; then
        printf '{"verdict":"no","mode":"heuristic","reason":"work-remaining-signal"}\n'
        return
    fi

    # Goal-keyword overlap (last-resort positive signal)
    # Take first 3 keywords from goal (>3 chars, alnum), check if any appear in response
    local keywords
    keywords=$(echo "$goal" | tr -cs 'a-zA-Z0-9' '\n' | awk 'length($0) > 3' | head -3)
    local hits=0
    for kw in $keywords; do
        if echo "$response" | grep -qiF "$kw"; then
            hits=$((hits + 1))
        fi
    done

    if [[ "$hits" -ge 2 ]]; then
        printf '{"verdict":"unclear","mode":"heuristic","reason":"keyword-overlap-but-no-completion-marker"}\n'
    else
        printf '{"verdict":"unclear","mode":"heuristic","reason":"insufficient-signal"}\n'
    fi
}

# ─── Mode: llm (not wired in v14-04 POC) ─────────────────────────────────────
llm_judge() {
    cat >&2 <<EOF
Error: --mode llm is NOT wired in v14-04 POC.

To enable real LLM judging:
  1. Wire this script to call Claude via the existing routing/policy.yaml
  2. Use Haiku tier per v14-series-plan §S14-04-01 budget guidance
  3. Prompt template:
       Goal: <goal>
       Response: <response>
       Question: Has the goal been achieved by this response? Answer in JSON
       with shape {"verdict":"yes|no|unclear","reason":"<one-line>"}.
  4. Update the measurement methodology doc to record real API costs
  5. Re-enable this code path after passing the gated External Access check

See: .aegis/brain/learnings/v14-04-goal-pattern-methodology.md
EOF
    exit 1
}

# ─── Dispatch ────────────────────────────────────────────────────────────────
case "$MODE" in
    heuristic) heuristic_judge "$RESPONSE" "$GOAL" ;;
    llm)       llm_judge ;;
    *)         echo "Error: invalid --mode '$MODE'" >&2; exit 2 ;;
esac
