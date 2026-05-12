#!/usr/bin/env bash
# tools/aegis-decision-search.sh
# ────────────────────────────────────────────────────────────────────────────
# Dedicated search wrapper over .aegis/brain/logs/decision-audit.log.
#
# Sprint:  v14-02 (S14-02-02)
# Builds on: tools/aegis-brain-search.sh (v10-06) which already indexes
# decision-audit.log as source_type='decisions' in the FTS5 index.
#
# Usage:
#   aegis-decision-search.sh "MBP escalation"
#   aegis-decision-search.sh --source framework "v14 plan"
#   aegis-decision-search.sh --source judgment "approve"
#   aegis-decision-search.sh --since 2026-05-01 --limit 5 "hermes"
#   aegis-decision-search.sh --json "sprint"
#   aegis-decision-search.sh --tail 5            # just print last 5 decisions
#
# Sources recognized (matches aegis-log-decision.sh schema):
#   instinct:* | resonance:* | adr:* | identity | framework |
#   retro:* | judgment | auto-defer-to-captain
# ────────────────────────────────────────────────────────────────────────────

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BRAIN_SEARCH="$SCRIPT_DIR/aegis-brain-search.sh"
DECISION_LOG="$REPO_ROOT/.aegis/brain/logs/decision-audit.log"

# Defaults
SOURCE_FILTER=""
SINCE_FILTER=""
LIMIT=10
FORMAT="text"
QUERY=""
TAIL_N=""

usage() {
  cat <<EOF
Usage: aegis-decision-search.sh [options] <query>
       aegis-decision-search.sh --tail <N>

Search the AEGIS decision-audit log via the FTS5 brain index.

Options:
  --source <name>        Filter by decision source (framework, judgment, instinct:*, etc.)
  --since YYYY-MM-DD     Only decisions on or after this date
  --limit <N>            Max results (default: 10)
  --json                 Output JSONL (one decision per line)
  --tail <N>             Skip search; print last N decisions chronologically
  --help                 Show this help

Examples:
  aegis-decision-search.sh "MBP escalation"
  aegis-decision-search.sh --source framework "v14"
  aegis-decision-search.sh --source judgment --since 2026-05-01 ""
  aegis-decision-search.sh --tail 5
  aegis-decision-search.sh --json "hermes" | jq .

Requires: aegis-brain-search.sh + an up-to-date brain index
(bash tools/aegis-brain-index.sh --incremental).
EOF
}

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --source) SOURCE_FILTER="$2"; shift 2 ;;
    --since)  SINCE_FILTER="$2";  shift 2 ;;
    --limit)  LIMIT="$2";         shift 2 ;;
    --json)   FORMAT="json";      shift ;;
    --tail)   TAIL_N="$2";        shift 2 ;;
    --help|-h) usage; exit 0 ;;
    --*)      echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    *)        QUERY="${QUERY:+$QUERY }$1"; shift ;;
  esac
done

# ─── Tail mode: skip FTS5, just print last N from log ───────────────────────
if [[ -n "$TAIL_N" ]]; then
  if ! [[ "$TAIL_N" =~ ^[1-9][0-9]*$ ]]; then
    echo "Error: --tail must be a positive integer" >&2
    exit 2
  fi
  if [[ ! -f "$DECISION_LOG" ]]; then
    echo "Error: decision-audit.log not found at $DECISION_LOG" >&2
    exit 1
  fi
  if [[ "$FORMAT" = "json" ]]; then
    tail -n "$TAIL_N" "$DECISION_LOG"
  else
    tail -n "$TAIL_N" "$DECISION_LOG" | while IFS= read -r line; do
      # Pretty-format each JSONL entry
      if command -v jq >/dev/null 2>&1; then
        printf '%s\n' "$line" | jq -r '"\(.ts)  \(.decision_id)  [\(.source) · conf=\(.confidence)]  \(.question)\n                                  → \(.answer | .[0:120])\n"'
      else
        printf '%s\n\n' "$line"
      fi
    done
  fi
  exit 0
fi

# ─── Search mode ─────────────────────────────────────────────────────────────
if [[ -z "$QUERY" ]]; then
  echo "Error: query is required (use --tail N for chronological dump)" >&2
  usage >&2
  exit 2
fi

# Build brain-search args
SEARCH_ARGS=(--type decisions --limit "$LIMIT")
[[ -n "$SINCE_FILTER" ]] && SEARCH_ARGS+=(--since "$SINCE_FILTER")

# Always pull JSON from brain-search so we can post-filter by source.
SEARCH_ARGS+=(--json)

# Call brain-search and post-filter
RAW=$(bash "$BRAIN_SEARCH" "${SEARCH_ARGS[@]}" "$QUERY" 2>/dev/null) || {
  echo "Error: brain-search failed (is the index built? run: bash tools/aegis-brain-index.sh --incremental)" >&2
  exit 1
}

# Each line is a JSON object with at minimum: rank, source_type, source_path, line_number, snippet, ts
# We need to extract the source field from the original log entry. We do that by re-reading
# the corresponding line of decision-audit.log via line_number.

emit_filtered() {
  while IFS= read -r json; do
    [[ -z "$json" ]] && continue

    # Pull line_number from the brain-search result
    if command -v jq >/dev/null 2>&1; then
      ln=$(printf '%s' "$json" | jq -r '.line_number // 0' 2>/dev/null)
    else
      ln=$(printf '%s' "$json" | grep -oE '"line_number":[[:space:]]*[0-9]+' | grep -oE '[0-9]+' | head -1)
    fi
    [[ -z "$ln" || "$ln" = "0" ]] && continue

    # Re-read original decision JSONL line
    decision_line=$(sed -n "${ln}p" "$DECISION_LOG" 2>/dev/null)
    [[ -z "$decision_line" ]] && continue

    # Apply source filter (post-filter)
    if [[ -n "$SOURCE_FILTER" ]]; then
      if command -v jq >/dev/null 2>&1; then
        src=$(printf '%s' "$decision_line" | jq -r '.source // ""' 2>/dev/null)
      else
        src=$(printf '%s' "$decision_line" | grep -oE '"source":[[:space:]]*"[^"]*"' | sed -E 's/.*"source":[[:space:]]*"([^"]*)".*/\1/')
      fi
      [[ "$src" != "$SOURCE_FILTER" ]] && continue
    fi

    if [[ "$FORMAT" = "json" ]]; then
      printf '%s\n' "$decision_line"
    else
      # Pretty-print
      if command -v jq >/dev/null 2>&1; then
        printf '%s' "$decision_line" | jq -r '"\(.ts)  \(.decision_id)  [\(.source) · conf=\(.confidence)]\n  Q: \(.question)\n  A: \(.answer | .[0:160])\n"'
      else
        printf '%s\n\n' "$decision_line"
      fi
    fi
  done
}

OUTPUT=$(printf '%s' "$RAW" | emit_filtered)

if [[ -z "$OUTPUT" ]]; then
  if [[ "$FORMAT" != "json" ]]; then
    echo "No matching decisions${SOURCE_FILTER:+ (source=$SOURCE_FILTER)} for query: $QUERY"
  fi
  exit 0
fi

printf '%s' "$OUTPUT"
[[ "$FORMAT" != "json" ]] && echo ""
