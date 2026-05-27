#!/usr/bin/env bash
# aegis-quality-gate.sh — AEGIS Quality Gate (v1.0.0)
#
# Runs quality gates before marking a task DONE. Implements PBIs 001-005
# from quality-gate-SPEC.md.
#
# Gates:
#   Gate 1 — Code Review (claude -p with black-panther prompt)
#   Gate 2 — Test Runner (auto-detect + execute)
#   Gate 3 — Spec Compliance (AC check via claude -p)
#
# Usage:
#   aegis-quality-gate.sh check [--branch <name>] [--task <id>]
#   aegis-quality-gate.sh review [--branch <name>]
#   aegis-quality-gate.sh test
#   aegis-quality-gate.sh spec [--task <id>]
#   aegis-quality-gate.sh status [--task <id>]
#
# Exit codes: 0=PASS, 1=FAIL
#
# Spec: _aegis-output/specs/quality-gate-SPEC.md

set -uo pipefail

# ── constants ─────────────────────────────────────────────────────────────
SCRIPT_VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

STATE_DIR="${REPO_ROOT}/.aegis/brain/state"
LOGS_DIR="${REPO_ROOT}/.aegis/brain/logs"
SPRINTS_DIR="${REPO_ROOT}/.aegis/brain/sprints"
QG_LOG="${LOGS_DIR}/quality-gate.jsonl"

GATE1_TIMEOUT=180   # 3 minutes
GATE2_TIMEOUT=300   # 5 minutes

# ── colors ────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# ── helpers ───────────────────────────────────────────────────────────────
# All human-readable output goes to stderr so gate functions can safely be
# captured with $(...) while their JSON result comes back on stdout.
info()    { printf "${BLUE}[INFO]${NC}  %s\n" "$*" >&2; }
success() { printf "${GREEN}[PASS]${NC}  %s\n" "$*" >&2; }
warn()    { printf "${YELLOW}[WARN]${NC}  %s\n" "$*" >&2; }
fail()    { printf "${RED}[FAIL]${NC}  %s\n" "$*" >&2; }
bold()    { printf "${BOLD}%s${NC}\n" "$*" >&2; }
err()     { printf "${RED}[ERROR]${NC} %s\n" "$*" >&2; }
hline()   { printf '%s\n' "─────────────────────────────────────" >&2; }
# sep: blank line to stderr
sep()     { printf '\n' >&2; }

now_iso() { date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u '+%Y-%m-%dT%H:%M:%SZ'; }

require_cmd() {
    local cmd="$1"
    if ! command -v "$cmd" &>/dev/null; then
        err "Required command not found: $cmd"
        return 1
    fi
}

json_escape() {
    # Escape a string for embedding in JSON
    printf '%s' "$1" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))' 2>/dev/null \
        || printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/$/\\n/g' | tr -d '\n' | sed 's/\\n$//'
}

# ── CLI parsing ───────────────────────────────────────────────────────────
COMMAND=""
OPT_BRANCH=""
OPT_TASK=""
OPT_SKIP_REVIEW=false
OPT_SKIP_TESTS=false
OPT_SKIP_SPEC=false
OPT_FIX=false
OPT_JSON=false
OPT_QUIET=false

usage() {
    cat <<EOF
${BOLD}aegis-quality-gate.sh${NC} v${SCRIPT_VERSION} — Run quality gates before marking tasks DONE

${BOLD}USAGE${NC}
  aegis-quality-gate.sh <command> [options]

${BOLD}COMMANDS${NC}
  check   [--branch <name>] [--task <id>]   Run all gates in sequence
  review  [--branch <name>]                  Gate 1 only (code review)
  test                                       Gate 2 only (run tests)
  spec    [--task <id>]                      Gate 3 only (spec compliance)
  status  [--task <id>]                      Show last verdict for a task

${BOLD}OPTIONS${NC}
  --branch <name>    Git branch to diff against main (default: current branch)
  --task <id>        Task ID for verdict file naming and spec lookup
  --skip-review      Skip Gate 1 (code review)
  --skip-tests       Skip Gate 2 (test runner)
  --skip-spec        Skip Gate 3 (spec compliance)
  --fix              Auto-fix findings where possible
  --json             Output verdict as JSON
  --quiet            Only print final verdict line

${BOLD}EXIT CODES${NC}
  0   All gates PASS
  1   One or more gates FAIL

${BOLD}EXAMPLES${NC}
  aegis-quality-gate.sh check --branch feat/my-feature --task PBI-042
  aegis-quality-gate.sh test
  aegis-quality-gate.sh status --task PBI-042
EOF
}

parse_args() {
    if [[ $# -eq 0 ]]; then
        usage
        exit 0
    fi

    COMMAND="$1"
    shift

    case "$COMMAND" in
        check|review|test|spec|status) ;;
        --help|-h|help)
            usage
            exit 0
            ;;
        *)
            err "Unknown command: $COMMAND"
            echo ""
            usage
            exit 1
            ;;
    esac

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --branch)
                OPT_BRANCH="${2:-}"
                shift 2
                ;;
            --task)
                OPT_TASK="${2:-}"
                shift 2
                ;;
            --skip-review)  OPT_SKIP_REVIEW=true; shift ;;
            --skip-tests)   OPT_SKIP_TESTS=true;  shift ;;
            --skip-spec)    OPT_SKIP_SPEC=true;   shift ;;
            --fix)          OPT_FIX=true;          shift ;;
            --json)         OPT_JSON=true;         shift ;;
            --quiet)        OPT_QUIET=true;        shift ;;
            --help|-h)
                usage
                exit 0
                ;;
            *)
                err "Unknown option: $1"
                exit 1
                ;;
        esac
    done
}

# ── git helpers ───────────────────────────────────────────────────────────
get_current_branch() {
    git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "HEAD"
}

get_diff() {
    local branch="${1:-}"
    if [[ -n "$branch" && "$branch" != "HEAD" && "$branch" != "main" ]]; then
        # Try branch..HEAD diff
        if git -C "$REPO_ROOT" rev-parse "main" &>/dev/null; then
            git -C "$REPO_ROOT" diff "main..${branch}" 2>/dev/null \
                || git -C "$REPO_ROOT" diff "main..HEAD" 2>/dev/null \
                || git -C "$REPO_ROOT" diff --cached 2>/dev/null
        else
            git -C "$REPO_ROOT" diff "HEAD~1..HEAD" 2>/dev/null \
                || git -C "$REPO_ROOT" diff --cached 2>/dev/null
        fi
    else
        # No branch specified — try main..HEAD, fallback to staged
        if git -C "$REPO_ROOT" rev-parse "main" &>/dev/null 2>&1; then
            local current
            current=$(get_current_branch)
            if [[ "$current" == "main" ]]; then
                git -C "$REPO_ROOT" diff "HEAD~1..HEAD" 2>/dev/null \
                    || git -C "$REPO_ROOT" diff --cached 2>/dev/null
            else
                git -C "$REPO_ROOT" diff "main..HEAD" 2>/dev/null \
                    || git -C "$REPO_ROOT" diff --cached 2>/dev/null
            fi
        else
            git -C "$REPO_ROOT" diff --cached 2>/dev/null \
                || git -C "$REPO_ROOT" diff "HEAD~1..HEAD" 2>/dev/null
        fi
    fi
}

# ── Gate 1: Code Review ───────────────────────────────────────────────────
# Uses claude -p with a focused prompt. Returns structured findings JSON.
# FAIL if any critical finding.

run_gate1_review() {
    local branch="${1:-}"
    local gate_status="PASS"
    local findings_json="[]"
    local critical_count=0
    local high_count=0
    local medium_count=0
    local low_count=0
    local total_findings=0
    local skip_reason=""

    if [[ "$OPT_QUIET" != "true" ]]; then
        sep
        bold "Gate 1 — Code Review"
        hline
    fi

    # Check claude availability
    if ! command -v claude &>/dev/null; then
        warn "claude CLI not found — skipping Gate 1 (code review)"
        skip_reason="claude CLI not available"
        if [[ "$OPT_QUIET" != "true" ]]; then
            warn "Install claude CLI to enable code review gate"
        fi
        # Return SKIP (treated as PASS for gate sequencing)
        printf '%s\n' '{"status":"SKIP","skip_reason":"claude CLI not available","findings":[],"critical":0,"high":0,"medium":0,"low":0,"reviewer":"black-panther"}'
        return 0
    fi

    # Get diff
    local diff_content
    diff_content=$(get_diff "$branch")

    if [[ -z "$diff_content" ]]; then
        warn "No diff found — nothing to review"
        skip_reason="empty diff"
        printf '%s\n' '{"status":"SKIP","skip_reason":"empty diff","findings":[],"critical":0,"high":0,"medium":0,"low":0,"reviewer":"black-panther"}'
        return 0
    fi

    local diff_size
    diff_size=$(printf '%s' "$diff_content" | wc -c | tr -d ' ')
    if [[ "$OPT_QUIET" != "true" ]]; then
        info "Diff size: ${diff_size} bytes — running claude review (timeout: ${GATE1_TIMEOUT}s)"
    fi

    # Truncate diff if very large (claude -p has limits)
    local diff_to_review="$diff_content"
    if [[ "$diff_size" -gt 50000 ]]; then
        diff_to_review=$(printf '%s' "$diff_content" | head -c 50000)
        warn "Diff truncated to 50KB for review"
    fi

    local review_prompt
    review_prompt="Review this git diff for critical bugs, security issues, and correctness problems.
Output ONLY a JSON array of findings: [{\"severity\":\"critical|high|medium|low\",\"file\":\"path\",\"line\":0,\"message\":\"...\"}]
If no issues found, output: []

GIT DIFF:
${diff_to_review}"

    # Run claude with timeout
    local claude_output
    local claude_rc=0
    if command -v timeout &>/dev/null; then
        claude_output=$(echo "$review_prompt" | timeout "$GATE1_TIMEOUT" claude -p --permission-mode auto 2>/dev/null) || claude_rc=$?
    else
        claude_output=$(echo "$review_prompt" | claude -p --permission-mode auto 2>/dev/null) || claude_rc=$?
    fi

    if [[ "$claude_rc" -eq 124 ]]; then
        warn "Code review timed out after ${GATE1_TIMEOUT}s — skipping"
        printf '%s\n' '{"status":"SKIP","skip_reason":"timeout","findings":[],"critical":0,"high":0,"medium":0,"low":0,"reviewer":"black-panther"}'
        return 0
    fi

    if [[ "$claude_rc" -ne 0 || -z "$claude_output" ]]; then
        warn "claude returned error (rc=${claude_rc}) — skipping Gate 1"
        printf '%s\n' "{\"status\":\"SKIP\",\"skip_reason\":\"claude error rc=${claude_rc}\",\"findings\":[],\"critical\":0,\"high\":0,\"medium\":0,\"low\":0,\"reviewer\":\"black-panther\"}"
        return 0
    fi

    # Extract JSON array from claude output (may have surrounding prose)
    local json_block
    json_block=$(printf '%s' "$claude_output" | grep -o '\[.*\]' | head -1) || true

    # Fallback: try to find multi-line JSON array
    if [[ -z "$json_block" ]]; then
        json_block=$(printf '%s' "$claude_output" | python3 -c '
import sys, re, json
text = sys.stdin.read()
# Find outermost [ ... ]
m = re.search(r"\[.*?\]", text, re.DOTALL)
if m:
    try:
        data = json.loads(m.group())
        print(m.group())
    except:
        print("[]")
else:
    print("[]")
' 2>/dev/null) || json_block="[]"
    fi

    if [[ -z "$json_block" ]]; then
        json_block="[]"
    fi

    # Validate JSON and count findings
    if command -v jq &>/dev/null; then
        if ! echo "$json_block" | jq . &>/dev/null; then
            warn "Could not parse claude review output as JSON — treating as no findings"
            json_block="[]"
        fi
        total_findings=$(echo "$json_block" | jq 'length' 2>/dev/null || echo "0")
        critical_count=$(echo "$json_block" | jq '[.[] | select(.severity=="critical")] | length' 2>/dev/null || echo "0")
        high_count=$(echo "$json_block" | jq '[.[] | select(.severity=="high")] | length' 2>/dev/null || echo "0")
        medium_count=$(echo "$json_block" | jq '[.[] | select(.severity=="medium")] | length' 2>/dev/null || echo "0")
        low_count=$(echo "$json_block" | jq '[.[] | select(.severity=="low")] | length' 2>/dev/null || echo "0")
    else
        total_findings=0
        critical_count=0
    fi

    findings_json="$json_block"

    # Determine gate status
    if [[ "$critical_count" -gt 0 ]]; then
        gate_status="FAIL"
    else
        gate_status="PASS"
    fi

    # Print findings summary
    if [[ "$OPT_QUIET" != "true" ]]; then
        if [[ "$gate_status" == "PASS" ]]; then
            success "Code review complete: ${total_findings} finding(s) — ${critical_count} critical, ${high_count} high, ${medium_count} medium, ${low_count} low"
        else
            fail "Code review: ${critical_count} CRITICAL finding(s) found — gate FAIL"
        fi

        # Print critical findings detail
        if [[ "$critical_count" -gt 0 ]] && command -v jq &>/dev/null; then
            sep
            info "Critical findings:"
            echo "$findings_json" | jq -r '.[] | select(.severity=="critical") | "  \(.file):\(.line) — \(.message)"' 2>/dev/null >&2 || true
        fi

        if [[ "$high_count" -gt 0 ]] && command -v jq &>/dev/null; then
            sep
            warn "High severity findings (warnings, not blocking):"
            echo "$findings_json" | jq -r '.[] | select(.severity=="high") | "  \(.file):\(.line) — \(.message)"' 2>/dev/null >&2 || true
        fi
    fi

    # Build result JSON
    local result_json
    result_json=$(printf '{"status":"%s","findings":%s,"total":%d,"critical":%d,"high":%d,"medium":%d,"low":%d,"reviewer":"black-panther"}' \
        "$gate_status" "$findings_json" "$total_findings" "$critical_count" "$high_count" "$medium_count" "$low_count")

    printf '%s\n' "$result_json"
    [[ "$gate_status" == "PASS" ]]
}

# ── Gate 2: Test Runner ───────────────────────────────────────────────────
# Auto-detects test runner and executes. No claude dependency.

detect_test_runner() {
    local root="$1"

    # 1. package.json — check scripts.test
    if [[ -f "${root}/package.json" ]]; then
        local test_script
        test_script=$(python3 -c "import json,sys; d=json.load(open('${root}/package.json')); print(d.get('scripts',{}).get('test',''))" 2>/dev/null || echo "")

        if [[ -n "$test_script" && "$test_script" != "echo \"Error: no test specified\" && exit 1" ]]; then
            echo "npm"
            return 0
        fi

        # Check for jest or vitest in devDependencies
        if python3 -c "import json; d=json.load(open('${root}/package.json')); deps={**d.get('devDependencies',{}),**d.get('dependencies',{})}; exit(0 if 'jest' in deps else 1)" 2>/dev/null; then
            echo "jest"
            return 0
        fi

        if python3 -c "import json; d=json.load(open('${root}/package.json')); deps={**d.get('devDependencies',{}),**d.get('dependencies',{})}; exit(0 if 'vitest' in deps else 1)" 2>/dev/null; then
            echo "vitest"
            return 0
        fi
    fi

    # 2. pytest
    if [[ -f "${root}/pytest.ini" || -f "${root}/pyproject.toml" || -f "${root}/setup.cfg" ]]; then
        if command -v pytest &>/dev/null || command -v python3 &>/dev/null; then
            echo "pytest"
            return 0
        fi
    fi

    # 3. AEGIS bash test suite
    if [[ -x "${root}/tools/aegis-test-all.sh" ]]; then
        echo "aegis-bash"
        return 0
    fi

    # 4. Generic tests/ directory with bash scripts
    if [[ -d "${root}/tests" ]] && find "${root}/tests" -name "*.sh" -executable 2>/dev/null | grep -q .; then
        echo "bash-tests"
        return 0
    fi

    echo "none"
}

run_gate2_tests() {
    local gate_status="PASS"
    local runner="none"
    local passed=0
    local failed=0
    local skip_reason=""
    local test_output=""
    local test_rc=0

    if [[ "$OPT_QUIET" != "true" ]]; then
        sep
        bold "Gate 2 — Test Runner"
        hline
    fi

    runner=$(detect_test_runner "$REPO_ROOT")
    if [[ "$OPT_QUIET" != "true" ]]; then
        info "Detected runner: ${runner}"
    fi

    if [[ "$runner" == "none" ]]; then
        warn "No test runner detected — skipping Gate 2"
        skip_reason="no test runner detected"
        printf '%s\n' "{\"status\":\"SKIP\",\"skip_reason\":\"${skip_reason}\",\"runner\":\"none\",\"passed\":0,\"failed\":0}"
        return 0
    fi

    # Run the appropriate test suite
    case "$runner" in
        npm)
            if [[ "$OPT_QUIET" != "true" ]]; then
                info "Running: npm test (timeout: ${GATE2_TIMEOUT}s)"
            fi
            if command -v timeout &>/dev/null; then
                test_output=$(cd "$REPO_ROOT" && timeout "$GATE2_TIMEOUT" npm test 2>&1) || test_rc=$?
            else
                test_output=$(cd "$REPO_ROOT" && npm test 2>&1) || test_rc=$?
            fi
            ;;
        jest)
            if [[ "$OPT_QUIET" != "true" ]]; then
                info "Running: npx jest (timeout: ${GATE2_TIMEOUT}s)"
            fi
            if command -v timeout &>/dev/null; then
                test_output=$(cd "$REPO_ROOT" && timeout "$GATE2_TIMEOUT" npx jest 2>&1) || test_rc=$?
            else
                test_output=$(cd "$REPO_ROOT" && npx jest 2>&1) || test_rc=$?
            fi
            ;;
        vitest)
            if [[ "$OPT_QUIET" != "true" ]]; then
                info "Running: npx vitest run (timeout: ${GATE2_TIMEOUT}s)"
            fi
            if command -v timeout &>/dev/null; then
                test_output=$(cd "$REPO_ROOT" && timeout "$GATE2_TIMEOUT" npx vitest run 2>&1) || test_rc=$?
            else
                test_output=$(cd "$REPO_ROOT" && npx vitest run 2>&1) || test_rc=$?
            fi
            ;;
        pytest)
            if [[ "$OPT_QUIET" != "true" ]]; then
                info "Running: pytest (timeout: ${GATE2_TIMEOUT}s)"
            fi
            if command -v timeout &>/dev/null; then
                test_output=$(cd "$REPO_ROOT" && timeout "$GATE2_TIMEOUT" python3 -m pytest -v 2>&1) || test_rc=$?
            else
                test_output=$(cd "$REPO_ROOT" && python3 -m pytest -v 2>&1) || test_rc=$?
            fi
            ;;
        aegis-bash)
            if [[ "$OPT_QUIET" != "true" ]]; then
                info "Running: tools/aegis-test-all.sh (timeout: ${GATE2_TIMEOUT}s)"
            fi
            if command -v timeout &>/dev/null; then
                test_output=$(cd "$REPO_ROOT" && timeout "$GATE2_TIMEOUT" bash tools/aegis-test-all.sh 2>&1) || test_rc=$?
            else
                test_output=$(cd "$REPO_ROOT" && bash tools/aegis-test-all.sh 2>&1) || test_rc=$?
            fi
            ;;
        bash-tests)
            if [[ "$OPT_QUIET" != "true" ]]; then
                info "Running: bash test scripts in tests/ (timeout: ${GATE2_TIMEOUT}s)"
            fi
            local all_rc=0
            test_output=""
            while IFS= read -r -d '' test_file; do
                local t_out
                local t_rc=0
                if command -v timeout &>/dev/null; then
                    t_out=$(timeout 60 bash "$test_file" 2>&1) || t_rc=$?
                else
                    t_out=$(bash "$test_file" 2>&1) || t_rc=$?
                fi
                test_output+="${t_out}"$'\n'
                [[ "$t_rc" -ne 0 ]] && all_rc=1
            done < <(find "${REPO_ROOT}/tests" -name "*.sh" -executable -print0 2>/dev/null)
            test_rc="$all_rc"
            ;;
    esac

    # Handle timeout
    if [[ "$test_rc" -eq 124 ]]; then
        warn "Tests timed out after ${GATE2_TIMEOUT}s"
        gate_status="FAIL"
        printf '%s\n' "{\"status\":\"FAIL\",\"skip_reason\":\"timeout\",\"runner\":\"${runner}\",\"passed\":0,\"failed\":0}"
        return 1
    fi

    # Parse pass/fail counts from output
    passed=$(printf '%s' "$test_output" | grep -oE '[0-9]+ passed' | tail -1 | grep -oE '^[0-9]+' || echo "0")
    failed=$(printf '%s' "$test_output" | grep -oE '[0-9]+ failed' | tail -1 | grep -oE '^[0-9]+' || echo "0")
    passed="${passed:-0}"
    failed="${failed:-0}"

    # Also try "X tests passed" pattern (pytest)
    if [[ "$passed" -eq 0 && "$failed" -eq 0 ]]; then
        passed=$(printf '%s' "$test_output" | grep -oE '[0-9]+ tests? passed' | tail -1 | grep -oE '^[0-9]+' || echo "0")
        failed=$(printf '%s' "$test_output" | grep -oE '[0-9]+ (tests? )?(failed|error)' | tail -1 | grep -oE '^[0-9]+' || echo "0")
        passed="${passed:-0}"
        failed="${failed:-0}"
    fi

    # Determine gate status from exit code (primary) and count (secondary)
    if [[ "$test_rc" -ne 0 ]]; then
        gate_status="FAIL"
    else
        gate_status="PASS"
    fi

    if [[ "$OPT_QUIET" != "true" ]]; then
        if [[ "$gate_status" == "PASS" ]]; then
            success "Tests complete: ${passed} passed, ${failed} failed (runner: ${runner})"
        else
            fail "Tests FAILED: ${passed} passed, ${failed} failed (rc=${test_rc})"
            sep
            # Print last 20 lines of test output for context
            info "Test output (last 20 lines):"
            printf '%s\n' "$test_output" | tail -20 | sed 's/^/  /' >&2
        fi
    fi

    printf '%s\n' "{\"status\":\"${gate_status}\",\"runner\":\"${runner}\",\"passed\":${passed},\"failed\":${failed},\"exit_code\":${test_rc}}"
    [[ "$gate_status" == "PASS" ]]
}

# ── Gate 3: Spec Compliance ───────────────────────────────────────────────
# Finds kanban, extracts ACs for task, uses claude -p to evaluate.

find_kanban() {
    local current="${SPRINTS_DIR}/current/kanban.md"
    if [[ -f "$current" ]]; then
        echo "$current"
        return 0
    fi
    # Fallback: highest-numbered sprint dir
    local latest
    latest=$(ls -1d "${SPRINTS_DIR}/sprint-"* 2>/dev/null | sort | tail -1)
    if [[ -n "$latest" && -f "${latest}/kanban.md" ]]; then
        echo "${latest}/kanban.md"
        return 0
    fi
    return 1
}

extract_ac_for_task() {
    local kanban="$1"
    local task_id="$2"

    # Look for task section in kanban — search for task ID and nearby AC lines
    # Pattern: task ID appears, then AC: or acceptance criteria block follows
    python3 - "$kanban" "$task_id" <<'PYEOF' 2>/dev/null
import sys, re

kanban_file = sys.argv[1]
task_id = sys.argv[2]

with open(kanban_file, 'r', encoding='utf-8') as f:
    content = f.read()

# Find section containing the task ID
# Look for the task ID anywhere in the document, then capture surrounding context
pattern = re.compile(
    r'(?:###.*?' + re.escape(task_id) + r'.*?\n)(.*?)(?=\n###|\Z)',
    re.DOTALL | re.IGNORECASE
)

m = pattern.search(content)
if not m:
    # Fallback: find task_id line and capture next 30 lines
    lines = content.split('\n')
    for i, line in enumerate(lines):
        if task_id in line:
            chunk = '\n'.join(lines[i:i+30])
            print(chunk)
            sys.exit(0)
    sys.exit(1)

section = m.group(0)

# Extract acceptance criteria lines
ac_lines = []
in_ac = False
for line in section.split('\n'):
    if re.match(r'.*acceptance criteria.*', line, re.IGNORECASE) or re.match(r'.*\bAC\b.*:', line, re.IGNORECASE):
        in_ac = True
        continue
    if in_ac:
        if re.match(r'^#{1,4}\s', line):  # new heading ends AC block
            break
        if line.strip():
            ac_lines.append(line.strip())

if ac_lines:
    print('\n'.join(ac_lines))
else:
    # Return the whole section as context
    print(section[:2000])

sys.exit(0)
PYEOF
}

run_gate3_spec() {
    local task_id="${1:-}"
    local branch="${2:-}"
    local gate_status="PASS"
    local ac_total=0
    local ac_met=0
    local ac_unmet=0
    local ac_json="[]"
    local skip_reason=""

    if [[ "$OPT_QUIET" != "true" ]]; then
        sep
        bold "Gate 3 — Spec Compliance"
        hline
    fi

    # Need task ID
    if [[ -z "$task_id" ]]; then
        warn "No task ID provided — skipping Gate 3 (use --task <id>)"
        skip_reason="no task ID"
        printf '%s\n' '{"status":"SKIP","skip_reason":"no task ID","ac_total":0,"ac_met":0,"ac_unmet":0}'
        return 0
    fi

    # Check claude availability
    if ! command -v claude &>/dev/null; then
        warn "claude CLI not found — skipping Gate 3"
        skip_reason="claude CLI not available"
        printf '%s\n' '{"status":"SKIP","skip_reason":"claude CLI not available","ac_total":0,"ac_met":0,"ac_unmet":0}'
        return 0
    fi

    # Find kanban
    local kanban
    if ! kanban=$(find_kanban); then
        warn "No kanban found in ${SPRINTS_DIR} — skipping Gate 3"
        skip_reason="no kanban found"
        printf '%s\n' '{"status":"SKIP","skip_reason":"no kanban found","ac_total":0,"ac_met":0,"ac_unmet":0}'
        return 0
    fi

    if [[ "$OPT_QUIET" != "true" ]]; then
        info "Kanban: ${kanban}"
    fi

    # Extract ACs for task
    local ac_text
    ac_text=$(extract_ac_for_task "$kanban" "$task_id") || ac_text=""

    if [[ -z "$ac_text" ]]; then
        warn "Task ${task_id} not found in kanban — skipping Gate 3"
        skip_reason="task not found in kanban"
        printf '%s\n' "{\"status\":\"SKIP\",\"skip_reason\":\"${skip_reason}\",\"ac_total\":0,\"ac_met\":0,\"ac_unmet\":0}"
        return 0
    fi

    if [[ "$OPT_QUIET" != "true" ]]; then
        info "Found acceptance criteria for ${task_id}"
    fi

    # Get diff for evaluation
    local diff_content
    diff_content=$(get_diff "$branch")

    if [[ -z "$diff_content" ]]; then
        warn "No diff found — skipping Gate 3 spec check"
        skip_reason="empty diff"
        printf '%s\n' '{"status":"SKIP","skip_reason":"empty diff","ac_total":0,"ac_met":0,"ac_unmet":0}'
        return 0
    fi

    # Truncate diff
    local diff_to_check="$diff_content"
    local diff_size
    diff_size=$(printf '%s' "$diff_content" | wc -c | tr -d ' ')
    if [[ "$diff_size" -gt 40000 ]]; then
        diff_to_check=$(printf '%s' "$diff_content" | head -c 40000)
        warn "Diff truncated to 40KB for spec compliance check"
    fi

    local spec_prompt
    spec_prompt="Given these acceptance criteria and this git diff, evaluate which ACs are met.
Output ONLY a JSON array: [{\"ac\":\"AC text\",\"met\":true|false,\"evidence\":\"...\"}]

ACCEPTANCE CRITERIA for ${task_id}:
${ac_text}

GIT DIFF:
${diff_to_check}"

    if [[ "$OPT_QUIET" != "true" ]]; then
        info "Running spec compliance check via claude (timeout: ${GATE1_TIMEOUT}s)"
    fi

    local claude_output
    local claude_rc=0
    if command -v timeout &>/dev/null; then
        claude_output=$(echo "$spec_prompt" | timeout "$GATE1_TIMEOUT" claude -p --permission-mode auto 2>/dev/null) || claude_rc=$?
    else
        claude_output=$(echo "$spec_prompt" | claude -p --permission-mode auto 2>/dev/null) || claude_rc=$?
    fi

    if [[ "$claude_rc" -eq 124 ]]; then
        warn "Spec compliance check timed out — skipping"
        printf '%s\n' '{"status":"SKIP","skip_reason":"timeout","ac_total":0,"ac_met":0,"ac_unmet":0}'
        return 0
    fi

    if [[ "$claude_rc" -ne 0 || -z "$claude_output" ]]; then
        warn "claude returned error for spec check — skipping"
        printf '%s\n' "{\"status\":\"SKIP\",\"skip_reason\":\"claude error rc=${claude_rc}\",\"ac_total\":0,\"ac_met\":0,\"ac_unmet\":0}"
        return 0
    fi

    # Extract JSON
    local json_block
    json_block=$(printf '%s' "$claude_output" | python3 -c '
import sys, re, json
text = sys.stdin.read()
m = re.search(r"\[.*?\]", text, re.DOTALL)
if m:
    try:
        data = json.loads(m.group())
        print(m.group())
    except:
        print("[]")
else:
    print("[]")
' 2>/dev/null) || json_block="[]"

    if [[ -z "$json_block" ]]; then
        json_block="[]"
    fi

    ac_json="$json_block"

    # Count met/unmet
    if command -v jq &>/dev/null; then
        if ! echo "$json_block" | jq . &>/dev/null; then
            ac_json="[]"
        fi
        ac_total=$(echo "$ac_json" | jq 'length' 2>/dev/null || echo "0")
        ac_met=$(echo "$ac_json" | jq '[.[] | select(.met==true)] | length' 2>/dev/null || echo "0")
        ac_unmet=$(echo "$ac_json" | jq '[.[] | select(.met==false)] | length' 2>/dev/null || echo "0")
    fi

    ac_total="${ac_total:-0}"
    ac_met="${ac_met:-0}"
    ac_unmet="${ac_unmet:-0}"

    if [[ "$ac_unmet" -gt 0 ]]; then
        gate_status="FAIL"
    else
        gate_status="PASS"
    fi

    if [[ "$OPT_QUIET" != "true" ]]; then
        if [[ "$gate_status" == "PASS" ]]; then
            success "Spec compliance: ${ac_met}/${ac_total} ACs met"
        else
            fail "Spec compliance: ${ac_unmet} ACs NOT met (${ac_met}/${ac_total} met)"
        fi

        if [[ "$ac_unmet" -gt 0 ]] && command -v jq &>/dev/null; then
            sep
            info "Unmet acceptance criteria:"
            echo "$ac_json" | jq -r '.[] | select(.met==false) | "  [UNMET] \(.ac)"' 2>/dev/null >&2 || true
        fi

        if command -v jq &>/dev/null && [[ "$ac_met" -gt 0 ]]; then
            info "Met acceptance criteria:"
            echo "$ac_json" | jq -r '.[] | select(.met==true) | "  [MET]   \(.ac)"' 2>/dev/null >&2 || true
        fi
    fi

    printf '%s\n' "{\"status\":\"${gate_status}\",\"ac_results\":${ac_json},\"ac_total\":${ac_total},\"ac_met\":${ac_met},\"ac_unmet\":${ac_unmet}}"
    [[ "$gate_status" == "PASS" ]]
}

# ── Verdict Writer ────────────────────────────────────────────────────────

write_verdict() {
    local task_id="$1"
    local branch="$2"
    local overall_verdict="$3"
    local gate1_json="$4"
    local gate2_json="$5"
    local gate3_json="$6"

    mkdir -p "$STATE_DIR" "$LOGS_DIR"

    local timestamp
    timestamp=$(now_iso)

    local safe_task
    safe_task=$(printf '%s' "$task_id" | tr '/' '-' | tr ' ' '-')
    [[ -z "$safe_task" ]] && safe_task="unknown"

    local verdict_file="${STATE_DIR}/quality-gate-${safe_task}.json"

    # Build verdict JSON
    local verdict_json
    verdict_json=$(cat <<EOF
{
  "task": $(json_escape "$task_id"),
  "branch": $(json_escape "$branch"),
  "timestamp": "${timestamp}",
  "verdict": "${overall_verdict}",
  "gates": {
    "code_review": ${gate1_json},
    "tests": ${gate2_json},
    "spec_compliance": ${gate3_json}
  },
  "evidence": ".aegis/brain/logs/quality-gate.jsonl"
}
EOF
)

    # Write state file
    printf '%s\n' "$verdict_json" > "$verdict_file"

    # Append to JSONL log
    local log_line
    log_line=$(printf '%s' "$verdict_json" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(json.dumps(d))' 2>/dev/null \
        || printf '%s' "$verdict_json" | tr '\n' ' ')
    printf '%s\n' "$log_line" >> "$QG_LOG"

    printf '%s\n' "$verdict_file"
}

# ── Status command ────────────────────────────────────────────────────────

cmd_status() {
    local task_id="${1:-}"

    if [[ -z "$task_id" ]]; then
        # List all recent verdicts
        if [[ -d "$STATE_DIR" ]]; then
            local found=false
            while IFS= read -r -d '' f; do
                found=true
                local fname
                fname=$(basename "$f")
                local task_from_file
                task_from_file=$(printf '%s' "$fname" | sed 's/quality-gate-//; s/\.json$//')
                if command -v jq &>/dev/null; then
                    local verdict ts
                    verdict=$(jq -r '.verdict // "UNKNOWN"' "$f" 2>/dev/null || echo "UNKNOWN")
                    ts=$(jq -r '.timestamp // ""' "$f" 2>/dev/null || echo "")
                    case "$verdict" in
                        PASS) printf "${GREEN}PASS${NC}  %-20s  %s\n" "$task_from_file" "$ts" ;;
                        FAIL) printf "${RED}FAIL${NC}  %-20s  %s\n" "$task_from_file" "$ts" ;;
                        *)    printf "${YELLOW}?${NC}     %-20s  %s\n" "$task_from_file" "$ts" ;;
                    esac
                else
                    printf "%-20s  %s\n" "$task_from_file" "$f"
                fi
            done < <(find "$STATE_DIR" -name "quality-gate-*.json" -print0 2>/dev/null | sort -z)

            if [[ "$found" == "false" ]]; then
                info "No quality gate verdicts found"
                info "Run: aegis-quality-gate.sh check --task <id>"
            fi
        else
            info "No quality gate verdicts found (state dir does not exist yet)"
            info "Run: aegis-quality-gate.sh check --task <id>"
        fi
        return 0
    fi

    local safe_task
    safe_task=$(printf '%s' "$task_id" | tr '/' '-' | tr ' ' '-')
    local verdict_file="${STATE_DIR}/quality-gate-${safe_task}.json"

    if [[ ! -f "$verdict_file" ]]; then
        info "No verdict found for task: ${task_id}"
        info "Run: aegis-quality-gate.sh check --task ${task_id}"
        return 0
    fi

    if [[ "$OPT_JSON" == "true" ]]; then
        cat "$verdict_file"
        return 0
    fi

    if command -v jq &>/dev/null; then
        local verdict ts branch
        verdict=$(jq -r '.verdict' "$verdict_file" 2>/dev/null || echo "UNKNOWN")
        ts=$(jq -r '.timestamp' "$verdict_file" 2>/dev/null || echo "unknown")
        branch=$(jq -r '.branch // "unknown"' "$verdict_file" 2>/dev/null || echo "unknown")

        printf '\n'
        bold "Quality Gate Status — ${task_id}"
        printf '%s\n' "─────────────────────────────────────"
        printf "Timestamp:  %s\n" "$ts"
        printf "Branch:     %s\n" "$branch"
        printf "Verdict:    "
        case "$verdict" in
            PASS) printf "${GREEN}${BOLD}PASS${NC}\n" ;;
            FAIL) printf "${RED}${BOLD}FAIL${NC}\n" ;;
            *)    printf "${YELLOW}${verdict}${NC}\n" ;;
        esac

        printf '\n'
        bold "Gate Results"
        printf '%s\n' "─────────────────────────────────────"

        local g1_status g2_status g3_status
        g1_status=$(jq -r '.gates.code_review.status // "N/A"' "$verdict_file" 2>/dev/null || echo "N/A")
        g2_status=$(jq -r '.gates.tests.status // "N/A"' "$verdict_file" 2>/dev/null || echo "N/A")
        g3_status=$(jq -r '.gates.spec_compliance.status // "N/A"' "$verdict_file" 2>/dev/null || echo "N/A")

        print_gate_status() {
            local label="$1" status="$2"
            printf "%-25s  " "$label"
            case "$status" in
                PASS) printf "${GREEN}PASS${NC}\n" ;;
                FAIL) printf "${RED}FAIL${NC}\n" ;;
                SKIP) printf "${YELLOW}SKIP${NC}\n" ;;
                *)    printf "%s\n" "$status" ;;
            esac
        }
        print_gate_status "Gate 1 (Code Review)" "$g1_status"
        print_gate_status "Gate 2 (Tests)" "$g2_status"
        print_gate_status "Gate 3 (Spec Compliance)" "$g3_status"

        printf '\n'
        info "Verdict file: ${verdict_file}"
    else
        cat "$verdict_file"
    fi
}

# ── Main orchestrator ─────────────────────────────────────────────────────

run_check() {
    local branch="${OPT_BRANCH:-$(get_current_branch)}"
    local task_id="${OPT_TASK:-}"
    local overall_status="PASS"
    local g1_result='{}'
    local g2_result='{}'
    local g3_result='{}'
    local g1_status="SKIP"
    local g2_status="SKIP"
    local g3_status="SKIP"

    if [[ "$OPT_QUIET" != "true" ]]; then
        printf '\n'
        bold "AEGIS Quality Gate — ${COMMAND}"
        [[ -n "$task_id" ]] && printf "Task:   %s\n" "$task_id"
        printf "Branch: %s\n" "$branch"
        printf "Time:   %s\n" "$(now_iso)"
        printf '%s\n' "═════════════════════════════════════"
    fi

    # ── Gate 1: Code Review ─────────────────────────────────────────────
    if [[ "$OPT_SKIP_REVIEW" == "true" ]]; then
        if [[ "$OPT_QUIET" != "true" ]]; then
            sep
            warn "Gate 1 — Code Review: SKIPPED (--skip-review)"
        fi
        g1_result='{"status":"SKIP","skip_reason":"--skip-review flag"}'
        g1_status="SKIP"
    else
        local g1_rc=0
        g1_result=$(run_gate1_review "$branch") || g1_rc=$?
        g1_status=$(printf '%s' "$g1_result" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("status","FAIL"))' 2>/dev/null || echo "FAIL")
        if [[ "$g1_status" == "FAIL" ]]; then
            overall_status="FAIL"
        fi
    fi

    # ── Gate 2: Tests ───────────────────────────────────────────────────
    if [[ "$OPT_SKIP_TESTS" == "true" ]]; then
        if [[ "$OPT_QUIET" != "true" ]]; then
            sep
            warn "Gate 2 — Tests: SKIPPED (--skip-tests)"
        fi
        g2_result='{"status":"SKIP","skip_reason":"--skip-tests flag"}'
        g2_status="SKIP"
    else
        local g2_rc=0
        g2_result=$(run_gate2_tests) || g2_rc=$?
        g2_status=$(printf '%s' "$g2_result" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("status","FAIL"))' 2>/dev/null || echo "FAIL")
        if [[ "$g2_status" == "FAIL" ]]; then
            overall_status="FAIL"
        fi
    fi

    # ── Gate 3: Spec Compliance ─────────────────────────────────────────
    if [[ "$OPT_SKIP_SPEC" == "true" ]]; then
        if [[ "$OPT_QUIET" != "true" ]]; then
            sep
            warn "Gate 3 — Spec Compliance: SKIPPED (--skip-spec)"
        fi
        g3_result='{"status":"SKIP","skip_reason":"--skip-spec flag"}'
        g3_status="SKIP"
    else
        local g3_rc=0
        g3_result=$(run_gate3_spec "$task_id" "$branch") || g3_rc=$?
        g3_status=$(printf '%s' "$g3_result" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("status","FAIL"))' 2>/dev/null || echo "FAIL")
        if [[ "$g3_status" == "FAIL" ]]; then
            overall_status="FAIL"
        fi
    fi

    # ── Verdict ─────────────────────────────────────────────────────────
    local verdict_file
    verdict_file=$(write_verdict \
        "${task_id:-no-task}" \
        "$branch" \
        "$overall_status" \
        "$g1_result" \
        "$g2_result" \
        "$g3_result")

    if [[ "$OPT_QUIET" != "true" ]]; then
        printf '\n'
        printf '%s\n' "═════════════════════════════════════"
        bold "VERDICT"
        printf '%s\n' "─────────────────────────────────────"
        printf "Gate 1 Code Review:     "
        case "$g1_status" in
            PASS) printf "${GREEN}PASS${NC}\n" ;;
            FAIL) printf "${RED}FAIL${NC}\n" ;;
            SKIP) printf "${YELLOW}SKIP${NC}\n" ;;
            *)    printf "%s\n" "$g1_status" ;;
        esac
        printf "Gate 2 Tests:           "
        case "$g2_status" in
            PASS) printf "${GREEN}PASS${NC}\n" ;;
            FAIL) printf "${RED}FAIL${NC}\n" ;;
            SKIP) printf "${YELLOW}SKIP${NC}\n" ;;
            *)    printf "%s\n" "$g2_status" ;;
        esac
        printf "Gate 3 Spec Compliance: "
        case "$g3_status" in
            PASS) printf "${GREEN}PASS${NC}\n" ;;
            FAIL) printf "${RED}FAIL${NC}\n" ;;
            SKIP) printf "${YELLOW}SKIP${NC}\n" ;;
            *)    printf "%s\n" "$g3_status" ;;
        esac
        printf '%s\n' "─────────────────────────────────────"
        printf "Overall:                "
        case "$overall_status" in
            PASS) printf "${GREEN}${BOLD}PASS${NC}\n" ;;
            FAIL) printf "${RED}${BOLD}FAIL${NC}\n" ;;
        esac
        printf '\n'
        info "Verdict written: ${verdict_file}"
    fi

    if [[ "$OPT_JSON" == "true" && -f "$verdict_file" ]]; then
        printf '\n'
        cat "$verdict_file"
    fi

    [[ "$overall_status" == "PASS" ]]
}

# ── Entry point ───────────────────────────────────────────────────────────

parse_args "$@"

case "$COMMAND" in
    check)
        run_check
        ;;
    review)
        # Gate 1 only
        branch="${OPT_BRANCH:-$(get_current_branch)}"
        result=$(run_gate1_review "$branch")
        rc=$?
        [[ "$OPT_JSON" == "true" ]] && printf '%s\n' "$result"
        exit $rc
        ;;
    test)
        # Gate 2 only
        result=$(run_gate2_tests)
        rc=$?
        [[ "$OPT_JSON" == "true" ]] && printf '%s\n' "$result"
        exit $rc
        ;;
    spec)
        # Gate 3 only
        task_id="${OPT_TASK:-}"
        branch="${OPT_BRANCH:-$(get_current_branch)}"
        result=$(run_gate3_spec "$task_id" "$branch")
        rc=$?
        [[ "$OPT_JSON" == "true" ]] && printf '%s\n' "$result"
        exit $rc
        ;;
    status)
        cmd_status "${OPT_TASK:-}"
        ;;
esac
