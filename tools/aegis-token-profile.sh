#!/usr/bin/env bash
# aegis-token-profile.sh — Bash vs Read/Grep/Glob token accounting
#
# Designed for two modes:
#   1. HOOK MODE (stdin):  Called from PostToolUse hook — receives JSON event on stdin,
#                          appends one JSONL line to the day's profile log.
#   2. SUMMARY MODE (--summary): Reads the day's (or --date YYYY-MM-DD) profile log
#                                and prints a category breakdown with percentages.
#
# Token estimation: chars / 4 (rough GPT/Claude tokenizer approximation).
#
# Output file: .aegis/brain/metrics/token-profile-<date>.jsonl
#
# Categories:
#   Bash | Read | Grep | Glob | Edit | Write | Agent | Other
#
# Sprint: sprint-v10-02 / Story A (2pt)
# Answers Loki's killshot: "What % of AEGIS tokens is Bash vs Read/Grep/Glob?"

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
METRICS_DIR="$REPO_ROOT/.aegis/brain/metrics"
mkdir -p "$METRICS_DIR"

# ── Mode detection ──────────────────────────────────────────────────────────

MODE="hook"
SUMMARY_DATE=""
OUTPUT_FORMAT="text"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --summary)  MODE="summary"; shift ;;
        --date)     SUMMARY_DATE="$2"; shift 2 ;;
        --json)     OUTPUT_FORMAT="json"; shift ;;
        --help|-h)
            echo "Usage:"
            echo "  echo '{tool_event_json}' | aegis-token-profile.sh    # hook mode"
            echo "  aegis-token-profile.sh --summary [--date YYYY-MM-DD] [--json]"
            exit 0
            ;;
        *) shift ;;
    esac
done

# ── Helper: estimate tokens from character count ────────────────────────────

estimate_tokens() {
    local char_count="${1:-0}"
    echo $(( (char_count + 3) / 4 ))
}

# ── Helper: categorize tool name ────────────────────────────────────────────

categorize_tool() {
    local tool="$1"
    case "$tool" in
        Bash)           echo "Bash" ;;
        Read)           echo "Read" ;;
        Grep)           echo "Grep" ;;
        Glob)           echo "Glob" ;;
        Edit|MultiEdit) echo "Edit" ;;
        Write)          echo "Write" ;;
        Agent|SendMessage|TeamCreate|TeamDelete) echo "Agent" ;;
        *)              echo "Other" ;;
    esac
}

# ── HOOK MODE ───────────────────────────────────────────────────────────────

if [[ "$MODE" == "hook" ]]; then
    INPUT=$(cat 2>/dev/null || echo "{}")

    # Parse tool event JSON
    TOOL_NAME=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_name', 'unknown'))
except:
    print('unknown')
" 2>/dev/null || echo "unknown")

    INPUT_CHARS=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    ti = d.get('tool_input', {})
    print(len(json.dumps(ti)))
except:
    print(0)
" 2>/dev/null || echo "0")

    RESPONSE_CHARS=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    tr = d.get('tool_response', {})
    print(len(json.dumps(tr) if isinstance(tr, dict) else len(str(tr))))
except:
    print(0)
" 2>/dev/null || echo "0")

    # Estimate tokens
    INPUT_TOKENS=$(estimate_tokens "$INPUT_CHARS")
    RESPONSE_TOKENS=$(estimate_tokens "$RESPONSE_CHARS")
    TOTAL_TOKENS=$((INPUT_TOKENS + RESPONSE_TOKENS))

    # Categorize
    CATEGORY=$(categorize_tool "$TOOL_NAME")

    # Write JSONL entry
    TODAY=$(date -u +"%Y-%m-%d" 2>/dev/null || echo "unknown")
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "unknown")
    PROFILE_LOG="$METRICS_DIR/token-profile-${TODAY}.jsonl"

    echo "{\"ts\":\"$TIMESTAMP\",\"tool\":\"$TOOL_NAME\",\"category\":\"$CATEGORY\",\"input_chars\":$INPUT_CHARS,\"response_chars\":$RESPONSE_CHARS,\"input_tokens\":$INPUT_TOKENS,\"response_tokens\":$RESPONSE_TOKENS,\"total_tokens\":$TOTAL_TOKENS}" >> "$PROFILE_LOG"

    exit 0
fi

# ── SUMMARY MODE ────────────────────────────────────────────────────────────

if [[ "$MODE" == "summary" ]]; then
    if [[ -z "$SUMMARY_DATE" ]]; then
        SUMMARY_DATE=$(date -u +"%Y-%m-%d" 2>/dev/null || echo "unknown")
    fi

    PROFILE_LOG="$METRICS_DIR/token-profile-${SUMMARY_DATE}.jsonl"

    if [[ ! -f "$PROFILE_LOG" ]]; then
        echo "No token profile data for $SUMMARY_DATE"
        echo "File not found: $PROFILE_LOG"
        exit 0
    fi

    # Aggregate using python3
    python3 - "$PROFILE_LOG" "$OUTPUT_FORMAT" "$SUMMARY_DATE" <<'PYEOF'
import sys, json

log_file = sys.argv[1]
output_format = sys.argv[2]
date = sys.argv[3]

categories = {}
total_calls = 0
grand_total_tokens = 0

with open(log_file) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            entry = json.loads(line)
        except json.JSONDecodeError:
            continue

        cat = entry.get("category", "Other")
        tokens = entry.get("total_tokens", 0)
        input_t = entry.get("input_tokens", 0)
        response_t = entry.get("response_tokens", 0)

        if cat not in categories:
            categories[cat] = {"calls": 0, "input_tokens": 0, "response_tokens": 0, "total_tokens": 0}

        categories[cat]["calls"] += 1
        categories[cat]["input_tokens"] += input_t
        categories[cat]["response_tokens"] += response_t
        categories[cat]["total_tokens"] += tokens
        total_calls += 1
        grand_total_tokens += tokens

if output_format == "json":
    result = {
        "date": date,
        "total_calls": total_calls,
        "grand_total_tokens": grand_total_tokens,
        "categories": {}
    }
    for cat in sorted(categories.keys()):
        d = categories[cat]
        pct = (d["total_tokens"] / grand_total_tokens * 100) if grand_total_tokens > 0 else 0
        result["categories"][cat] = {
            "calls": d["calls"],
            "input_tokens": d["input_tokens"],
            "response_tokens": d["response_tokens"],
            "total_tokens": d["total_tokens"],
            "pct_of_total": round(pct, 1)
        }
    print(json.dumps(result, indent=2))
else:
    # Text table
    print(f"Token Profile Summary — {date}")
    print(f"{'='*60}")
    print(f"Total tool calls: {total_calls}")
    print(f"Total estimated tokens: {grand_total_tokens:,}")
    print()
    print(f"{'Category':<12} {'Calls':>6} {'Input Tok':>10} {'Resp Tok':>10} {'Total Tok':>10} {'%':>6}")
    print(f"{'-'*12} {'-'*6} {'-'*10} {'-'*10} {'-'*10} {'-'*6}")

    for cat in sorted(categories.keys()):
        d = categories[cat]
        pct = (d["total_tokens"] / grand_total_tokens * 100) if grand_total_tokens > 0 else 0
        print(f"{cat:<12} {d['calls']:>6} {d['input_tokens']:>10,} {d['response_tokens']:>10,} {d['total_tokens']:>10,} {pct:>5.1f}%")

    print(f"{'-'*12} {'-'*6} {'-'*10} {'-'*10} {'-'*10} {'-'*6}")
    print(f"{'TOTAL':<12} {total_calls:>6} {'':>10} {'':>10} {grand_total_tokens:>10,} {'100.0':>5}%")
    print()

    # Loki's killshot answer
    bash_tokens = categories.get("Bash", {}).get("total_tokens", 0)
    read_tokens = categories.get("Read", {}).get("total_tokens", 0)
    grep_tokens = categories.get("Grep", {}).get("total_tokens", 0)
    glob_tokens = categories.get("Glob", {}).get("total_tokens", 0)

    native_tokens = read_tokens + grep_tokens + glob_tokens
    if grand_total_tokens > 0:
        bash_pct = bash_tokens / grand_total_tokens * 100
        native_pct = native_tokens / grand_total_tokens * 100
    else:
        bash_pct = 0
        native_pct = 0

    print(f"Loki's Killshot Answer:")
    print(f"  Bash tokens:              {bash_tokens:>10,} ({bash_pct:.1f}%)")
    print(f"  Read+Grep+Glob tokens:    {native_tokens:>10,} ({native_pct:.1f}%)")
    if bash_pct < 30:
        print(f"  Verdict: Bash < 30% — RTK value DROPS SHARPLY")
    elif bash_pct > 60:
        print(f"  Verdict: Bash > 60% — RTK has STRONG value proposition")
    else:
        print(f"  Verdict: Bash 30-60% — RTK has MODERATE value, measure more sessions")

PYEOF

    exit 0
fi
