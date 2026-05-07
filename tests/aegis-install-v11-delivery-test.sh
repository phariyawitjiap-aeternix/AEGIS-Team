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
# CI runners lack global git user.{name,email}; set repo-local config so
# `git commit --allow-empty` works. (sprint-v13-01-phase-b-chunk3 — chunk-3
# CI exposed this when install-v11 graduated out of known-failures and the
# test ran for real, revealing every assertion failing because install.sh
# exited early when the dummy repo couldn't even initialize.)
(
  cd "$PILOT" \
    && git init -q \
    && git config user.email "test@aegis.local" \
    && git config user.name "AEGIS Test" \
    && git commit -q --allow-empty -m "init"
) || { echo "FATAL: cannot init test repo at $PILOT" >&2; exit 2; }

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
for s in aegis-live-tail aegis-activity-logger aegis-issue-thread aegis-parallel-dispatch aegis-plus-pilot aegis-approval-gate aegis-router aegis-run-logger aegis-trace-export aegis-multi-tenant aegis-resume; do
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
    "aegis-approval-gate/check.mjs"
    "aegis-approval-gate/grant.mjs"
    "aegis-approval-gate/list.mjs"
    "aegis-approval-gate/revoke.mjs"
    "aegis-approval-gate/lib.mjs"
    "aegis-router/route.mjs"
    "aegis-run-logger/archive.mjs"
    "aegis-run-logger/replay.mjs"
    "aegis-run-logger/list.mjs"
    "aegis-trace-export/export.mjs"
    "aegis-trace-export/validate.mjs"
    "aegis-trace-export/lib.mjs"
    "aegis-multi-tenant/mt.mjs"
    "aegis-resume/checkpoint.mjs"
    "aegis-resume/resume.mjs"
    "aegis-resume/session-start.mjs"
    "aegis-resume/lib.mjs"
    # v12 brain-graph (sprint-v13-01-phase-b-chunk3 — settings.json wires
    # hook.sh + staleness.mjs; lib + build + query + wiki are dependencies).
    "aegis-brain-graph/build.mjs"
    "aegis-brain-graph/hook.sh"
    "aegis-brain-graph/lib.mjs"
    "aegis-brain-graph/query.mjs"
    "aegis-brain-graph/staleness.mjs"
    "aegis-brain-graph/wiki.mjs"
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

# ── Group 4: hooks chained correctly + every wired tool actually delivered ─
echo ""
echo "--- Group 4: PostToolUse hook wiring + delivery ---"
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
if grep -q "aegis-approval-gate/check.mjs" "$PILOT/.claude/settings.json"; then
    pass "approval-gate check hook wired in settings.json"
else
    fail "approval-gate hook" "not in settings.json"
fi
if [[ -f "$PILOT/.aegis/brain/gate-rules.yaml" ]]; then
    pass "gate-rules.yaml seeded under .aegis/brain/"
else
    fail "gate-rules.yaml" "not seeded"
fi
if [[ -f "$PILOT/.aegis/brain/routing/policy.yaml" ]]; then
    pass "routing/policy.yaml seeded under .aegis/brain/"
else
    fail "routing/policy.yaml" "not seeded"
fi
if [[ -f "$PILOT/.aegis/brain/redaction/patterns.yaml" ]]; then
    pass "redaction/patterns.yaml seeded under .aegis/brain/"
else
    fail "redaction/patterns.yaml" "not seeded"
fi

# AEGIS_VERSION pin file (advertised in install.sh tree printout — must exist)
META_V=$(cat "$REPO_ROOT/VERSION" | tr -d '[:space:]')
if [[ -f "$PILOT/AEGIS_VERSION" ]]; then
    PIN=$(cat "$PILOT/AEGIS_VERSION" | tr -d '[:space:]')
    if [[ "$PIN" == "$META_V" ]]; then
        pass "AEGIS_VERSION pin file written and matches meta VERSION ($PIN)"
    else
        fail "AEGIS_VERSION content" "pin=$PIN expected=$META_V"
    fi
else
    fail "AEGIS_VERSION pin" "tree printout claims file but install.sh did not write it"
fi
# Every tools/<name> referenced as a hook command in settings.json must
# exist on disk after install. Catches the "wired but not shipped" bug
# class — we hit this with both aegis-token-profile.sh and the v11 packages.
# Restrict to paths that look like real script files (.sh / .mjs / .js),
# extracted only from "command": ".../tools/..." lines.
WIRED_PATHS=$(grep -E '"command"' "$PILOT/.claude/settings.json" \
              | grep -oE 'tools/[A-Za-z0-9_/-]+\.(sh|mjs|js)' \
              | sort -u)
while IFS= read -r rel; do
    [[ -z "$rel" ]] && continue
    if [[ -e "$PILOT/$rel" ]]; then
        pass "wired tool exists: $rel"
    else
        fail "wired-but-missing" "$rel referenced in settings.json but not delivered"
    fi
done <<< "$WIRED_PATHS"

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
