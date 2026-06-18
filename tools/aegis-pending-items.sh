#!/usr/bin/env bash
# AEGIS Pending Items Scanner (dogfood-observation #3 -- spec freshness audit)
#
# Scans .claude/references/*.md and surfaces every unchecked acceptance-
# criteria item (`- [ ]`). Output grouped by spec file with line numbers
# so a human or agent can jump straight to each item and decide:
#   (a) still truly pending -> leave alone
#   (b) actually shipped -> tick the box (drift correction)
#   (c) blocked on external -> annotate why
#
# This is the "list the work" primitive. Heuristic drift-detection is a
# larger tool; this one just enumerates.
#
# Flags:
#   (default)   pretty-print grouped by file
#   --count     print one line per file: "N  filename"
#   --plain     no color / no headers, one "file:line:text" per line (grep-like)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
REFS_DIR="${REPO_ROOT}/.claude/references"

MODE="pretty"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --count) MODE="count"; shift ;;
        --plain) MODE="plain"; shift ;;
        -h|--help)
            cat <<EOF
Usage: aegis-pending-items.sh [flag]

Surfaces every unchecked ([ ]) acceptance-criteria item across
.claude/references/*.md. Useful as a spec-freshness audit primitive.

Flags:
  (default)  Pretty-print: grouped by file with line numbers.
  --count    One line per file: count + filename.
  --plain    grep-like: file:line:text (good for piping to xargs / fzf).
EOF
            exit 0
            ;;
        *) echo "ERROR: unknown arg: $1" >&2; exit 2 ;;
    esac
done

[[ -d "$REFS_DIR" ]] || { echo "ERROR: $REFS_DIR not found" >&2; exit 1; }

# Collect all unchecked items via grep -n
# Pattern: lines that are "-_[_]_" (not "- [x]" or "- [X]" or "- [~]")
# We accept " - [ ] " after optional leading whitespace.
RAW=$(grep -rn -E '^\s*-\s\[\s\]\s' "$REFS_DIR" --include='*.md' 2>/dev/null || true)
if [[ -z "$RAW" ]]; then
    echo "No unchecked items found."
    exit 0
fi

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'
# Disable color when stdout is not a real terminal (Claude Code Bash tool /
# Claude Desktop GUI / VS Code chat) so raw ANSI escapes never leak into chat
# as literal `[1m`. Matches repo convention. Test-safe: plain-text assertions pass.
[ -t 1 ] || { GREEN=''; YELLOW=''; BOLD=''; DIM=''; NC=''; }

case "$MODE" in
    plain)
        # grep-compatible output: file:line:text (strip the checkbox prefix)
        echo "$RAW" | sed -E 's|^'"$REPO_ROOT"'/||' | sed -E 's|(:[0-9]+:)\s*-\s\[\s\]\s*|\1|'
        ;;

    count)
        echo "$RAW" | awk -F: '{print $1}' | sort | uniq -c | sort -rn | while read -r n f; do
            printf "%3s  %s\n" "$n" "${f#${REPO_ROOT}/}"
        done
        ;;

    pretty|*)
        echo -e "${BOLD}Unchecked acceptance-criteria items in .claude/references/${NC}"
        echo "──────────────────────────────────────────────────────────"
        TOTAL=0
        current_file=""
        while IFS=: read -r file line rest; do
            rel="${file#${REPO_ROOT}/}"
            if [[ "$rel" != "$current_file" ]]; then
                [[ -n "$current_file" ]] && echo ""
                echo -e "${BOLD}${rel}${NC}"
                current_file="$rel"
            fi
            # Strip leading "- [ ] " from the captured text
            clean=$(echo "$rest" | sed -E 's|^\s*-\s\[\s\]\s*||')
            printf "  ${DIM}L%-4s${NC} %s\n" "$line" "$clean"
            TOTAL=$((TOTAL + 1))
        done <<< "$RAW"
        echo ""
        echo "──────────────────────────────────────────────────────────"
        echo -e "Total unchecked items: ${YELLOW}${TOTAL}${NC}"
        echo -e "${DIM}Tip: run with --plain for grep-compatible output, --count for per-file summary.${NC}"
        ;;
esac
