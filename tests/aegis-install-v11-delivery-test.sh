#!/usr/bin/env bash
# aegis-install-v11-delivery-test.sh — Guard against install.sh skipping v11 artifacts.
#
# Today's bug: install.sh's hardcoded skill manifest + tool delivery loop
# only handled single-file tools. After v11 P1 shipped, the 5 v11 skills
# (aegis-live-tail / aegis-activity-logger / aegis-issue-thread /
# aegis-parallel-dispatch / aegis-plus-pilot) plus the 5 multi-file tool
# packages they ship in were silently absent from every fresh install /
# upgrade — including the kam-tong-ham pilot bootstrap.
#
# Fix: add v11 skills to standard tier + new tool_packages array.
#
# This test fresh-installs into a tmpdir + asserts everything lands.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
INSTALL_SH="${REPO_ROOT}/install.sh"

[[ -f "$INSTALL_SH" ]] || { echo "FATAL: missing $INSTALL_SH" >&2; exit 2; }

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
PASS=0; FAIL=0
pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}FAIL${NC}: $1 -- $2"; FAIL=$((FAIL+1)); }

TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/aegis-install-v11-XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT INT TERM

PILOT="$TEST_DIR/pilot"
mkdir -p "$PILOT"
# install.sh does a `git rev-parse` early — give it a real repo.
( cd "$PILOT" && git init -q && git commit -q --allow-empty -m "init" )

echo "============================================"
echo "AEGIS install — v11 artifact delivery"
echo "============================================"

# Run a fresh install with profile=standard.
INSTALL_OUT="$TEST_DIR/install.out"
if bash "$INSTALL_SH" --target-dir "$PILOT" --project-name "fixture" --profile standard \
     >"$INSTALL_OUT" 2>&1; then
    pass "1.a install.sh fresh standard install exits 0"
else
    fail "1.a install exit" "rc=$? tail: $(tail -20 "$INSTALL_OUT")"
fi

# ── Group 1: v11 skills ─────────────────────────────────────────────────
echo ""
echo "--- Group 1: v11 skills landed ---"
for s in aegis-live-tail aegis-activity-logger aegis-issue-thread aegis-parallel-dispatch aegis-plus-pilot; do
    if [[ -f "$PILOT/skills/${s}.md" ]]; then
        pass "skill: ${s}.md present"
    else
        fail "skill: ${s}" "missing in $PILOT/skills/"
    fi
done

# ── Group 2: v11 tool packages ──────────────────────────────────────────
echo ""
echo "--- Group 2: v11 tool packages landed ---"
declare -a expected_files=(
    "aegis-live-tail/emit.mjs"
    "aegis-live-tail/watch.mjs"
    "aegis-live-tail/format.mjs"
    "aegis-live-tail/start.sh"
    "aegis-activity-logger/log.mjs"
    "aegis-activity-logger/view.mjs"
    "aegis-activity-logger/stats.mjs"
    "aegis-issue-thread/issue.mjs"
    "aegis-parallel-dispatch/dispatch.mjs"
    "aegis-parallel-dispatch/examples/parallel-review.md"
    "aegis-plus-pilot/bootstrap.sh"
    "aegis-plus-pilot/daily-eod.sh"
    "aegis-plus-pilot/gate-check.sh"
)
for f in "${expected_files[@]}"; do
    if [[ -f "$PILOT/tools/$f" ]]; then
        pass "tool: $f present"
    else
        fail "tool: $f" "missing"
    fi
done

# ── Group 3: executable bits set ────────────────────────────────────────
echo ""
echo "--- Group 3: executable bits ---"
for f in aegis-live-tail/emit.mjs aegis-issue-thread/issue.mjs aegis-plus-pilot/bootstrap.sh; do
    if [[ -x "$PILOT/tools/$f" ]]; then
        pass "executable: $f"
    else
        fail "executable: $f" "not +x"
    fi
done

# ── Group 4: hooks chained correctly ────────────────────────────────────
echo ""
echo "--- Group 4: PostToolUse hook wiring ---"
if grep -q "aegis-live-tail/emit.mjs" "$PILOT/.claude/settings.json"; then
    pass "live-tail emit hook wired in settings.json"
else
    fail "live-tail hook" "not in settings.json"
fi
if grep -q "aegis-activity-logger/log.mjs" "$PILOT/.claude/settings.json"; then
    pass "activity-logger log hook wired in settings.json"
else
    fail "activity-logger hook" "not in settings.json"
fi

# ── Group 5: install banner reflects VERSION ────────────────────────────
echo ""
echo "--- Group 5: banner version ---"
EXPECTED_V=$(cat "$REPO_ROOT/VERSION" | tr -d '[:space:]')
if grep -qE "AEGIS[[:space:]]+v${EXPECTED_V//./\\.}" "$INSTALL_OUT"; then
    pass "install banner displays v${EXPECTED_V}"
else
    fail "banner version" "expected v${EXPECTED_V}, got: $(grep -E 'AEGIS.*v[0-9]' "$INSTALL_OUT" | head -2)"
fi

echo ""
echo "============================================"
echo "RESULTS: ${PASS} passed, ${FAIL} failed"
echo "============================================"
[[ $FAIL -eq 0 ]] && { echo -e "${GREEN}ALL PASSED${NC}"; exit 0; } || { echo -e "${RED}FAILURES${NC}"; exit 1; }
