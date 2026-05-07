#!/usr/bin/env bash
# aegis-shell-footgun-scan.sh — Detect bash footguns that have bitten this codebase.
#
# Purpose:
#   Sprint v13-02 AI-2 (from v13-01 retro). Scans tools/, .claude/hooks/, tests/
#   for known-dangerous bash patterns. Currently checks:
#
#   1. set -e + `[[ ... ]] && X` as the LAST line of a function
#      → silent exit when condition is false (the instinct-promote bug,
#        sprint-v13-01 B/c2 PR #142)
#
#   2. `find -perm +111` → GNU find removed `+` syntax in 2005
#      → silent "no tests found" on Linux CI (run-all.sh bug,
#        sprint-v13-01 B/c2 PR #142)
#
#   3. `sed -i ''` → BSD-only; GNU sed treats `''` as the script
#      → silent no-op on Linux (brain-adversarial-test bug,
#        sprint-v13-01 B/c3 PR #143)
#
# Usage:
#   bash tools/aegis-shell-footgun-scan.sh           # scan repo, exit 0=clean, 1=findings
#   bash tools/aegis-shell-footgun-scan.sh --verbose # show every check + path
#   bash tools/aegis-shell-footgun-scan.sh --paths "tests/aegis-foo.sh"  # scan a subset
#
# Add to CI as a pre-merge gate once the codebase is clean.
# Re-run after any sprint that touches shell scripts.
#
# Spec: SPRINT_RULES Rule 6 (graduate-by-running) + DoD §5.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

VERBOSE=0
SCAN_PATHS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --verbose) VERBOSE=1; shift ;;
    --paths)   shift; while [[ $# -gt 0 && "$1" != --* ]]; do SCAN_PATHS+=("$1"); shift; done ;;
    -h|--help) sed -n '2,28p' "${BASH_SOURCE[0]}" | sed 's/^# \?//'; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "${SCAN_PATHS[*]+x}" ]] || [[ ${#SCAN_PATHS[@]} -eq 0 ]]; then
  cd "$REPO_ROOT"
  while IFS= read -r p; do
    # Self-exclusion: the scanner's own test file contains the patterns it's
    # asserting against (in heredocs), so default-scan skips it. Use --paths
    # explicitly to scan it.
    [[ "$p" == "tests/aegis-shell-footgun-scan-test.sh" ]] && continue
    SCAN_PATHS+=("$p")
  done < <(find tools -maxdepth 2 -name 'aegis-*.sh' -type f 2>/dev/null
           find .claude/hooks -maxdepth 1 -name '*.sh' -type f 2>/dev/null
           find tests -maxdepth 1 -name 'aegis-*-test.sh' -type f 2>/dev/null)
fi

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'; NC=$'\033[0m'
[[ -t 1 ]] || { RED=''; GREEN=''; YELLOW=''; NC=''; }

FOUND_COUNT=0
SCANNED=0

# ─── Check 1: set -e + last-line `[[ ]] && X` inside a function ────────────
check_set_e_short_circuit() {
  local f="$1"
  if ! grep -qE '^[[:space:]]*set -[a-z]*e' "$f" 2>/dev/null; then return; fi

  awk '
    function count_braces(line) {
      n_open = 0; n_close = 0
      for (i=1; i<=length(line); i++) {
        c = substr(line, i, 1)
        if (c == "{") n_open++
        else if (c == "}") n_close++
      }
      brace_depth += (n_open - n_close)
    }
    /^[a-zA-Z_][a-zA-Z_0-9]*[[:space:]]*\(\)/ {
      func_name = $1; sub(/\(\)/, "", func_name)
      in_func = 1; brace_depth = 0; last_line=""; last_line_no=0
      count_braces($0)
      next
    }
    in_func {
      count_braces($0)
      if (brace_depth == 0 && /\}/) {
        if (last_line ~ /^[[:space:]]*\[\[ .* \]\] && [a-z]/) {
          print FILENAME ":" last_line_no ":FOOTGUN-1:" func_name ":" last_line
        }
        in_func = 0
        next
      }
      if (!/^[[:space:]]*$/ && !/^[[:space:]]*#/ && !/^[[:space:]]*\}[[:space:]]*$/) {
        last_line = $0; last_line_no = NR
      }
    }
  ' "$f"
}

# ─── Check 2: find -perm +111 (GNU-incompatible) ───────────────────────────
check_find_perm_plus() {
  local f="$1"
  # Skip lines that begin with a `#` after optional whitespace (comments + docstrings),
  # and case-statement labels like `*FOOTGUN-2*) ...` (false positive in our own scanner).
  grep -nE 'find[[:space:]].*-perm[[:space:]]\+' "$f" 2>/dev/null \
    | grep -vE '^[0-9]+:[[:space:]]*#' \
    | grep -vE '^[0-9]+:[[:space:]]*\*FOOTGUN' \
    | sed "s|^|$f:FOOTGUN-2:|"
}

# ─── Check 3: sed -i '' (BSD-only, breaks on GNU) ──────────────────────────
check_sed_i_empty() {
  local f="$1"
  # Match `sed -i ''` but exclude:
  #   - `sed -i.bak ...` (the portable form)
  #   - lines starting with `#` (comments documenting the pattern)
  #   - lines that already have `|| sed -i ...` cross-platform fallback (same line)
  #   - lines followed within 2 lines by `|| sed -i` (multi-line continuation pattern)
  #   - case-statement labels like `*FOOTGUN-3*) ... "sed -i ''" ...` (false positive
  #     in our own scanner that documents the pattern)
  grep -nE "sed[[:space:]]+-i[[:space:]]+''" "$f" 2>/dev/null \
    | grep -vE '^[0-9]+:[[:space:]]*#' \
    | grep -vF '|| sed -i' \
    | grep -vE '^[0-9]+:[[:space:]]*\*FOOTGUN' \
    | while IFS= read -r match; do
        line_no=$(echo "$match" | cut -d: -f1)
        # Look at the next 2 lines for `|| sed -i` (continuation pattern)
        lookback=$(sed -n "$((line_no+1)),$((line_no+2))p" "$f" 2>/dev/null)
        if echo "$lookback" | grep -qF '|| sed -i'; then
          continue
        fi
        echo "$f:FOOTGUN-3:$match"
      done
}

# ─── Run all checks ────────────────────────────────────────────────────────
echo "============================================"
echo "AEGIS shell-footgun scan"
echo "  Scanning ${#SCAN_PATHS[@]} files"
echo "============================================"
echo ""

declare -a FINDINGS=()
for f in "${SCAN_PATHS[@]+"${SCAN_PATHS[@]}"}"; do
  SCANNED=$((SCANNED + 1))
  [[ $VERBOSE -eq 1 ]] && echo "  scan: $f"

  while IFS= read -r finding; do
    [[ -z "$finding" ]] && continue
    FINDINGS+=("$finding")
    FOUND_COUNT=$((FOUND_COUNT + 1))
  done < <(
    check_set_e_short_circuit "$f"
    check_find_perm_plus "$f"
    check_sed_i_empty "$f"
  )
done

echo ""
echo "============================================"
if [[ $FOUND_COUNT -eq 0 ]]; then
  echo "${GREEN}CLEAN${NC} — scanned ${SCANNED} files, 0 footguns found"
  echo "============================================"
  exit 0
fi

echo "${RED}FOOTGUNS FOUND (${FOUND_COUNT})${NC} — scanned ${SCANNED} files"
echo "============================================"
for finding in "${FINDINGS[@]}"; do
  case "$finding" in
    *FOOTGUN-1*) cat_label="${YELLOW}set -e + && short-circuit${NC}" ;;
    *FOOTGUN-2*) cat_label="${YELLOW}find -perm + (GNU-incompatible)${NC}" ;;
    *FOOTGUN-3*) cat_label="${YELLOW}sed -i '' (BSD-only)${NC}" ;;
    *)           cat_label="UNKNOWN" ;;
  esac
  echo "  ${cat_label}: $finding"
done

echo ""
echo "Fix references:"
echo "  FOOTGUN-1: add explicit \`return 0\` at end of function (see instinct-promote-test fix)"
echo "  FOOTGUN-2: drop \`-perm\` or use shell test (see run-all.sh fix)"
echo "  FOOTGUN-3: use \`sed -i.bak ... && rm file.bak\` (see brain-adversarial-test fix)"

exit 1
