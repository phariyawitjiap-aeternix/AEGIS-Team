#!/usr/bin/env bash
# tests/run-all.sh — single entry point for the full AEGIS test suite.
#
# Runs every `tests/aegis-*-test.sh` sequentially. Exits non-zero on the FIRST
# failure (`--fail-fast`, default) OR after running all and tallying
# (`--continue`).
#
# Usage:
#   bash tests/run-all.sh                  # fail-fast, human output
#   bash tests/run-all.sh --continue       # run all, tally at end
#   bash tests/run-all.sh --quiet          # only print failures + summary
#   bash tests/run-all.sh --list           # just list tests, don't run
#   bash tests/run-all.sh --filter <regex> # only run tests matching regex
#
# Exit codes:
#   0 — all tests pass
#   1 — at least one test failed
#   2 — usage / no tests found
#
# Spec: SPRINT_RULES Rule 3 + DoD §5 — single top-level entry point that
# CI calls. Created in sprint-v13-01 Phase D.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "$REPO_ROOT"

MODE="fail-fast"
QUIET=0
LIST_ONLY=0
FILTER=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --fail-fast) MODE="fail-fast"; shift ;;
        --continue)  MODE="continue"; shift ;;
        --quiet)     QUIET=1; shift ;;
        --list)      LIST_ONLY=1; shift ;;
        --filter)    FILTER="$2"; shift 2 ;;
        -h|--help)
            sed -n '2,17p' "${BASH_SOURCE[0]}" | sed 's/^# \?//'
            exit 0 ;;
        *) echo "Unknown arg: $1" >&2; exit 2 ;;
    esac
done

# Collect test files. Use a portable read-loop (mapfile is bash 4+; macOS
# default bash is 3.2). Drop -perm: BSD find accepts `-perm +111` but GNU
# find removed `+` in 2005 (PR #142 caught the Linux CI break). Filter by
# name+type+shell test instead — sufficient since CI chmod's tests upfront.
TESTS=()
while IFS= read -r line; do
    [[ -n "$line" && -x "$line" ]] && TESTS+=("$line")
done < <(find tests -maxdepth 1 -name 'aegis-*-test.sh' -type f 2>/dev/null | sort)

if [[ -n "$FILTER" ]]; then
    FILTERED=()
    for t in "${TESTS[@]}"; do
        if [[ "$t" =~ $FILTER ]]; then FILTERED+=("$t"); fi
    done
    TESTS=("${FILTERED[@]}")
fi

if [[ ${#TESTS[@]} -eq 0 ]]; then
    echo "no tests found in tests/ (filter='$FILTER')" >&2
    exit 2
fi

if [[ $LIST_ONLY -eq 1 ]]; then
    printf '%s\n' "${TESTS[@]}"
    exit 0
fi

# ─── Colors ────────────────────────────────────────────────────────────────
if [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]; then
    RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'; NC=$'\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; NC=''
fi

# ─── Known-failures list (Phase D · graduates as Phase B fixes each) ──────
KNOWN_FAILURES=()
KNOWN_FAILURE_FILE="${REPO_ROOT}/tests/_known-failures.txt"
if [[ -f "$KNOWN_FAILURE_FILE" ]]; then
    while IFS= read -r line; do
        # Strip leading whitespace + comments + blank lines
        line="${line#"${line%%[![:space:]]*}"}"
        [[ -z "$line" || "$line" =~ ^# ]] && continue
        KNOWN_FAILURES+=("$line")
    done < "$KNOWN_FAILURE_FILE"
fi

is_known_failure() {
    local name="$1"
    for kf in "${KNOWN_FAILURES[@]+"${KNOWN_FAILURES[@]}"}"; do
        [[ "$kf" == "$name" ]] && return 0
    done
    return 1
}

# ─── Run loop ──────────────────────────────────────────────────────────────
PASS_COUNT=0
FAIL_COUNT=0
KNOWN_FAIL_COUNT=0
FAILED_TESTS=()
KNOWN_FAILED_TESTS=()
START_TS=$(date +%s)

for test_file in "${TESTS[@]}"; do
    test_name=$(basename "$test_file" .sh)
    if [[ $QUIET -eq 0 ]]; then
        printf "→ %-50s ... " "$test_name"
    fi
    # Run test, capture output + exit code
    if OUT=$(bash "$test_file" 2>&1); then
        rc=0
    else
        rc=$?
    fi
    if [[ $rc -eq 0 ]]; then
        PASS_COUNT=$((PASS_COUNT + 1))
        [[ $QUIET -eq 0 ]] && echo "${GREEN}PASS${NC}"
    elif is_known_failure "$test_name"; then
        KNOWN_FAIL_COUNT=$((KNOWN_FAIL_COUNT + 1))
        KNOWN_FAILED_TESTS+=("$test_name")
        [[ $QUIET -eq 0 ]] && echo "${YELLOW}KNOWN_FAILURE${NC} (exit=$rc · graduate via Phase B)"
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
        FAILED_TESTS+=("$test_name")
        [[ $QUIET -eq 0 ]] && echo "${RED}FAIL${NC} (exit=$rc)"
        # Show last 20 lines of failing test output
        echo "${YELLOW}-- last 20 lines of $test_name output --${NC}" >&2
        echo "$OUT" | tail -20 >&2
        echo "${YELLOW}-- end --${NC}" >&2
        if [[ "$MODE" == "fail-fast" ]]; then
            break
        fi
    fi
done

END_TS=$(date +%s)
ELAPSED=$((END_TS - START_TS))
TOTAL=$((PASS_COUNT + FAIL_COUNT + KNOWN_FAIL_COUNT))

echo
echo "================================================================"
if [[ $FAIL_COUNT -eq 0 ]]; then
    if [[ $KNOWN_FAIL_COUNT -eq 0 ]]; then
        echo "${GREEN}ALL TESTS PASS${NC} — $PASS_COUNT/$TOTAL in ${ELAPSED}s"
    else
        echo "${GREEN}TESTS PASS${NC} (with $KNOWN_FAIL_COUNT known-failure${KNOWN_FAIL_COUNT:+s}) — $PASS_COUNT pass, $KNOWN_FAIL_COUNT known-failure (of $TOTAL run) in ${ELAPSED}s"
        echo "Known failures (graduate via tests/_known-failures.txt):"
        for n in "${KNOWN_FAILED_TESTS[@]+"${KNOWN_FAILED_TESTS[@]}"}"; do echo "  - $n"; done
    fi
else
    echo "${RED}TESTS FAILED${NC} — $FAIL_COUNT failed, $PASS_COUNT passed, $KNOWN_FAIL_COUNT known-failure (of $TOTAL run) in ${ELAPSED}s"
    echo "Failed (NOT in _known-failures.txt — fix or document):"
    for n in "${FAILED_TESTS[@]}"; do echo "  - $n"; done
    if [[ $KNOWN_FAIL_COUNT -gt 0 ]]; then
        echo "Known failures (separate, expected):"
        for n in "${KNOWN_FAILED_TESTS[@]+"${KNOWN_FAILED_TESTS[@]}"}"; do echo "  - $n"; done
    fi
fi
echo "================================================================"

[[ $FAIL_COUNT -eq 0 ]] && exit 0 || exit 1
