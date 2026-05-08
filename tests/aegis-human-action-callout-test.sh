#!/usr/bin/env bash
# aegis-human-action-callout-test.sh — pin format for human-action callouts.
#
# When a response genuinely requires the human to take an action the agent
# cannot execute (click URL to open/merge a PR, approve an External-Access
# gate, switch a token, paste a config, run a command in another terminal),
# the action MUST be a heading-level callout (## 👉 / 🚨 / ⚠️) with
# step-by-step instructions, placed as the LAST block of the response.
#
# See GUARDRAILS Sign "Human-action callout missing" + auto-memory
# feedback_human_action_callout.md.
#
# Detection logic:
#   - TRIGGER: response contains an unambiguous user-action URL
#     (pull/new/, issues/new, /settings/, /branches/) — these mean the
#     user is being asked to navigate somewhere and do something
#   - CALLOUT: last 1200 chars contain ^#{1,3}\s*(👉|🚨|⚠️|⚡|❗)
#   - VIOLATION = trigger present + callout missing
#
# Why: Burying URLs inline OR providing them without step-by-step causes
# the action to be missed. User flagged 2026-05-08: "เค้าอาจจะไม่รู้เท่าคุณ".

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

command -v python3 >/dev/null 2>&1 || { echo "FATAL: python3 not found" >&2; exit 2; }

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
PASS=0; FAIL=0
pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}FAIL${NC}: $1 -- $2"; FAIL=$((FAIL+1)); }

# Run the detector against a fixture. Returns:
#   missing_callout — has trigger URL, no callout heading at end
#   has_callout     — has trigger URL AND callout heading at end
#   no_trigger      — no action-required URL pattern in response
run_detect() {
    local fixture="$1"
    python3 - <<PYEOF "$fixture"
import sys, re
text = sys.argv[1]

# Action-required URL patterns (unambiguous "go-do-this-yourself" URLs).
# These are URLs where the human is being directed to navigate and act.
trigger_url = re.search(
    r'https?://[^\s)]*?(?:pull/new/|/issues/new|/settings(?:/[a-z_-]+)?|/branches(?:/[^\s)]*)?)',
    text,
    re.IGNORECASE
)
if not trigger_url:
    print('no_trigger')
    sys.exit(0)

# Callout heading pattern: ^#{1,3} <emoji> (last 1200 chars only — must be
# the FINAL block of the response, not buried mid-message)
closing = text[-1200:]
callout_emoji = r'(?:👉|🚨|⚠️|⚡|❗|🔴|🟠)'
has_callout = re.search(
    r'^#{1,3}\s*' + callout_emoji,
    closing,
    re.MULTILINE
)
if has_callout:
    print('has_callout')
else:
    print('missing_callout')
PYEOF
}

assert_violation() {
    local label="$1" fixture="$2"
    local result
    result=$(run_detect "$fixture")
    if [[ "$result" == "missing_callout" ]]; then
        pass "$label"
    else
        fail "$label" "expected missing_callout, got: $result"
    fi
}

assert_compliant() {
    local label="$1" fixture="$2"
    local result
    result=$(run_detect "$fixture")
    if [[ "$result" == "has_callout" ]]; then
        pass "$label"
    else
        fail "$label" "expected has_callout, got: $result"
    fi
}

assert_no_trigger() {
    local label="$1" fixture="$2"
    local result
    result=$(run_detect "$fixture")
    if [[ "$result" == "no_trigger" ]]; then
        pass "$label"
    else
        fail "$label" "expected no_trigger, got: $result"
    fi
}

echo "================================================="
echo "AEGIS Human-action callout format test"
echo "================================================="

# ─── Violations: trigger URL present, callout missing ─────────────────────
echo
echo "Violations expected — URL present but no heading callout at end:"

assert_violation \
    "V1 — PR-create URL inline mid-paragraph" \
    "Branch is pushed and ready. Open https://github.com/foo/bar/pull/new/feature to finalize. CI will run on merge."

assert_violation \
    "V2 — PR URL at end as bare link, no heading" \
    "All gates green. PR ready: https://github.com/foo/bar/pull/new/branch-name"

assert_violation \
    "V3 — settings URL buried mid-message" \
    "Configuration was attempted but the API blocked it. Go to https://github.com/foo/bar/settings/branches to enable. Note: branch protection is active."

assert_violation \
    "V4 — branches URL with nearby instruction but no heading" \
    "Cleanup pending — visit https://github.com/foo/bar/branches and delete the merged branch manually."

# ─── Compliant: trigger URL present, properly formatted callout at end ────
echo
echo "Compliant expected — URL inside heading callout as last block:"

assert_compliant \
    "C1 — proper ## 👉 callout with PR-create URL last block" \
    $'Status: branch pushed.\n\n## 👉 สิ่งที่ต้องทำต่อ (Human action required)\n\n**Why:** gh CLI token quirk\n\n**Steps:**\n1. Open https://github.com/foo/bar/pull/new/branch\n2. Paste body\n3. Click Create pull request\n\n**Expected:** PR opens with CI running.'

assert_compliant \
    "C2 — ## 🚨 urgency variant with settings URL" \
    $'API merge failed.\n\n## 🚨 Human action required\n\nOpen https://github.com/foo/bar/settings/branches and adjust protection rule.'

assert_compliant \
    "C3 — ### ⚠️ deeper heading also accepted" \
    $'Patch applied.\n\n### ⚠️ Manual step\n\n1. Visit https://github.com/foo/bar/issues/new\n2. Paste template'

# ─── No trigger: response doesn't ask for human action ────────────────────
echo
echo "No trigger expected — no action-URL pattern in message:"

assert_no_trigger \
    "N1 — pure status report no URL" \
    "PR #152 merged. main HEAD is 8afe7ad. CI green 8/8."

assert_no_trigger \
    "N2 — code reference URL (commit/blob/tree) not action" \
    "See commit https://github.com/foo/bar/commit/abc123 for the regex change. Refactored in https://github.com/foo/bar/blob/main/src/util.ts."

assert_no_trigger \
    "N3 — existing PR reference (not pull/new) is informational" \
    "Resolved as PR #100 — https://github.com/foo/bar/pull/100 closed the regression."

assert_no_trigger \
    "N4 — declarative completion no URLs" \
    "Done. Branch merged. Memory updated. Three new patterns added to mbp-scan."

# ─── Summary ──────────────────────────────────────────────────────────────
echo
echo "================================================="
echo -e "Total: ${GREEN}$PASS pass${NC} / ${RED}$FAIL fail${NC}"
echo "================================================="
[[ $FAIL -gt 0 ]] && exit 1
exit 0
