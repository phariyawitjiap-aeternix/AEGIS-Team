#!/usr/bin/env bash
# AEGIS v15-28 tools smoke test
# Validates the session-continuity + verification tools shipped in v15-28:
#   aegis-autopilot.sh, aegis-daemon.sh, aegis-checkpoint.sh,
#   aegis-credential-scan.sh, aegis-quality-gate.sh
#
# These tools wrap `claude` for real work — this suite checks the parts that
# DON'T need a live claude: arg parsing, validation, gates that refuse unsafe
# input, credential detection, checkpoint write/read round-trip. No network.
#
# Exits 0 if all assertions pass, 1 otherwise. Uses an isolated temp project
# so it never touches the real brain.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TOOLS="${REPO_ROOT}/tools"

PASS=0
FAIL=0
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() { echo -e "  ${GREEN}PASS${NC} $1"; PASS=$((PASS+1)); }
fail() { echo -e "  ${RED}FAIL${NC} $1"; FAIL=$((FAIL+1)); }
info() { echo -e "${YELLOW}==>${NC} $1"; }

# Isolated temp project
TMP="$(mktemp -d)"
cleanup() { rm -rf "$TMP" 2>/dev/null || true; }
trap cleanup EXIT
mkdir -p "$TMP/.aegis/brain/state" "$TMP/.aegis/brain/handoffs" "$TMP/tools"
( cd "$TMP" && git init -q 2>/dev/null && git commit --allow-empty -m init -q 2>/dev/null )
echo "# test" > "$TMP/CLAUDE.md"

# ── aegis-autopilot.sh ────────────────────────────────────────────────────────
info "aegis-autopilot.sh argument validation"

# --help exits 0
if bash "$TOOLS/aegis-autopilot.sh" --help >/dev/null 2>&1; then
    pass "autopilot --help exits 0"
else
    fail "autopilot --help should exit 0"
fi

# bypassPermissions blocked
if bash "$TOOLS/aegis-autopilot.sh" --permission-mode bypassPermissions --dry-run --project-dir "$TMP" >/dev/null 2>&1; then
    fail "autopilot should reject bypassPermissions"
else
    pass "autopilot rejects bypassPermissions"
fi

# negative budget rejected
if bash "$TOOLS/aegis-autopilot.sh" --budget -5 --dry-run --project-dir "$TMP" >/dev/null 2>&1; then
    fail "autopilot should reject negative budget"
else
    pass "autopilot rejects negative budget"
fi

# budget over hard cap rejected
if bash "$TOOLS/aegis-autopilot.sh" --budget 2000 --dry-run --project-dir "$TMP" >/dev/null 2>&1; then
    fail "autopilot should reject budget > 1000"
else
    pass "autopilot rejects budget > 1000"
fi

# dry-run with no budget flag succeeds (default no-budget)
if bash "$TOOLS/aegis-autopilot.sh" --dry-run --project-dir "$TMP" >/dev/null 2>&1; then
    pass "autopilot --dry-run defaults to no-budget"
else
    fail "autopilot --dry-run should succeed by default"
fi

# ── aegis-checkpoint.sh ───────────────────────────────────────────────────────
info "aegis-checkpoint.sh write/read round-trip"

CLAUDE_PROJECT_DIR="$TMP" bash "$TOOLS/aegis-checkpoint.sh" write --task "T-1" --note "smoke" >/dev/null 2>&1
if [[ -f "$TMP/.aegis/brain/state/checkpoint.json" ]]; then
    pass "checkpoint write creates checkpoint.json"
else
    fail "checkpoint write should create checkpoint.json"
fi

# valid JSON with expected fields
if command -v jq &>/dev/null; then
    CP_TASK=$(jq -r '.current_task' "$TMP/.aegis/brain/state/checkpoint.json" 2>/dev/null)
    if [[ "$CP_TASK" == "T-1" ]]; then
        pass "checkpoint captures current_task"
    else
        fail "checkpoint current_task wrong: $CP_TASK"
    fi
fi

# resume prints the brief (capture first to avoid pipefail interaction)
RESUME_OUT=$(CLAUDE_PROJECT_DIR="$TMP" bash "$TOOLS/aegis-checkpoint.sh" resume 2>&1 || true)
if printf '%s' "$RESUME_OUT" | grep -q "Resume Checkpoint"; then
    pass "checkpoint resume prints brief"
else
    fail "checkpoint resume should print brief"
fi

# ── aegis-credential-scan.sh ──────────────────────────────────────────────────
info "aegis-credential-scan.sh detection"

printf 'FOO_API_KEY=\nBAR_TOKEN=\nLOG_LEVEL=\n' > "$TMP/.env.example"
printf 'FOO_API_KEY=sk-real\n' > "$TMP/.env"

# scan finds 2 credential keys (LOG_LEVEL filtered)
SCAN_OUT=$(bash "$TOOLS/aegis-credential-scan.sh" scan --project-dir "$TMP" 2>&1)
if echo "$SCAN_OUT" | grep -q "FOO_API_KEY" && echo "$SCAN_OUT" | grep -q "BAR_TOKEN"; then
    pass "credential scan finds declared keys"
else
    fail "credential scan should find FOO_API_KEY + BAR_TOKEN"
fi
if echo "$SCAN_OUT" | grep -q "LOG_LEVEL"; then
    fail "credential scan should filter LOG_LEVEL"
else
    pass "credential scan filters non-secret LOG_LEVEL"
fi

# check: FOO set, BAR missing -> exit 1
if bash "$TOOLS/aegis-credential-scan.sh" check --project-dir "$TMP" >/dev/null 2>&1; then
    fail "credential check should exit 1 when keys missing"
else
    pass "credential check exits 1 when keys missing"
fi

# check JSON: missing=[BAR_TOKEN], set=[FOO_API_KEY]
if command -v jq &>/dev/null; then
    CHECK_JSON=$(bash "$TOOLS/aegis-credential-scan.sh" check --project-dir "$TMP" --json 2>/dev/null || true)
    MISS=$(echo "$CHECK_JSON" | jq -r '.missing[0]' 2>/dev/null)
    SET=$(echo "$CHECK_JSON" | jq -r '.set[0]' 2>/dev/null)
    if [[ "$MISS" == "BAR_TOKEN" && "$SET" == "FOO_API_KEY" ]]; then
        pass "credential check JSON classifies set vs missing"
    else
        fail "credential check JSON wrong: missing=$MISS set=$SET"
    fi
fi

# all set -> exit 0
printf 'FOO_API_KEY=sk-real\nBAR_TOKEN=tok\n' > "$TMP/.env"
if bash "$TOOLS/aegis-credential-scan.sh" check --project-dir "$TMP" >/dev/null 2>&1; then
    pass "credential check exits 0 when all set"
else
    fail "credential check should exit 0 when all set"
fi

# ── aegis-quality-gate.sh ─────────────────────────────────────────────────────
info "aegis-quality-gate.sh CLI"

if bash "$TOOLS/aegis-quality-gate.sh" --help >/dev/null 2>&1; then
    pass "quality-gate --help exits 0"
else
    fail "quality-gate --help should exit 0"
fi

# status on unknown task handles gracefully (exit 0)
if CLAUDE_PROJECT_DIR="$TMP" bash "$TOOLS/aegis-quality-gate.sh" status --task NOPE >/dev/null 2>&1; then
    pass "quality-gate status handles missing verdict"
else
    fail "quality-gate status should not error on missing verdict"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo -e "v15-28 tools: ${GREEN}${PASS} passed${NC}, ${RED}${FAIL} failed${NC}"
[[ "$FAIL" -eq 0 ]] && exit 0 || exit 1
