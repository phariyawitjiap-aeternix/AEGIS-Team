#!/usr/bin/env bash
# aegis-mbp-scan-thai-test.sh — regression test for the 2026-05-07 enforcement gap
#
# Before this test, mbp-scan.sh used English-only patterns AND a strict
# AND-gate (option AND open). Result: Thai-language "ต้องการอะไรต่อ — X หรือ Y"
# endings produced by the agent in real sessions slipped through every time.
# The user manually flagged this on 2026-05-07 after watching it recur for
# the Nth time.
#
# This test pins the violation patterns — every fixture below was either
# verbatim from my session output or a near-miss that should also catch.
# Run before any future change to mbp-scan to prevent silent regression.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SCAN="${REPO_ROOT}/.claude/hooks/lib/mbp-scan.sh"

[[ -f "$SCAN" ]] || { echo "FATAL: missing $SCAN" >&2; exit 2; }
command -v python3 >/dev/null 2>&1 || { echo "FATAL: python3 not found" >&2; exit 2; }

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
PASS=0; FAIL=0
pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}FAIL${NC}: $1 -- $2"; FAIL=$((FAIL+1)); }

TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/aegis-mbp-scan-thai-XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT INT TERM

# Build a fake transcript file with one assistant text block whose content
# is the fixture we want to scan. The mbp-scan reads JSONL transcript and
# pulls the LAST assistant text block, so we just need one line.
mk_transcript() {
    local outfile="$1"
    local fixture="$2"
    # Use python to construct a properly-escaped JSONL line
    python3 - "$outfile" "$fixture" <<'PYEOF'
import sys, json
out, text = sys.argv[1], sys.argv[2]
entry = {"type": "assistant", "message": {"role": "assistant", "content": [{"type": "text", "text": text}]}}
with open(out, "w") as f:
    f.write(json.dumps(entry) + "\n")
PYEOF
}

# Run the scanner against a fixture. Returns "violation" / "clean" / "no_text".
# Calls the REAL mbp_scan from lib/mbp-scan.sh — NOT a duplicated copy. This
# is deliberate: a prior duplicated python block drifted out of sync (it never
# got Round 4/5 patterns), so fixtures passed against stale logic. Sourcing the
# real hook makes the test track the shipped patterns forever.
SCAN_LIB="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)/.claude/hooks/lib/mbp-scan.sh"
# shellcheck disable=SC1090
source "$SCAN_LIB"
run_scan() {
    local fixture_text="$1"
    local transcript="$TEST_DIR/transcript.jsonl"
    mk_transcript "$transcript" "$fixture_text"
    # Force the real block decision: clear the disable/active gates so mbp_scan
    # emits the block JSON + returns 1 on a genuine violation.
    local out rc
    out=$(AEGIS_MBP_BLOCK_DISABLE=0 STOP_HOOK_ACTIVE=False mbp_scan "$transcript" "" 2>/dev/null)
    rc=$?
    if [[ "$rc" -eq 1 ]] || echo "$out" | grep -q '"decision": "block"'; then
        echo "violation"
    else
        echo "clean"
    fi
}

assert_violation() {
    local label="$1"
    local fixture="$2"
    local result
    result=$(run_scan "$fixture")
    if [[ "$result" == "violation" ]]; then
        pass "$label"
    else
        fail "$label" "expected violation, got: $result"
    fi
}

assert_clean() {
    local label="$1"
    local fixture="$2"
    local result
    result=$(run_scan "$fixture")
    if [[ "$result" == "clean" ]]; then
        pass "$label"
    else
        fail "$label" "expected clean, got: $result"
    fi
}

echo "================================================="
echo "AEGIS MBP-scan Thai + closing-ask regression test"
echo "================================================="

# ─── Violations: actual phrasings from 2026-05-07 session ──────────────────

echo
echo "Violations expected — Thai endings (verbatim from real session):"
assert_violation \
    "Thai V1 — ต้องการอะไรต่อ + 2 options" \
    "เสร็จแล้ว ต่อจากนี้\n\nต้องการอะไรต่อ — กลับไปทำงาน pilot · หรือมีอย่างอื่นค้างที่อยากเช็ค?"
assert_violation \
    "Thai V2 — ต่อไปจะทำอะไร + dual choice" \
    "Net session\n\nต่อไปจะทำอะไร — flag noise cleanup ข้างบน หรือกลับไปทำ pilot work เลยก็ได้"
assert_violation \
    "Thai V3 — ต้องการให้ทำอะไรต่อ + pick by name" \
    "ทำเสร็จแล้ว\n\nต้องการให้ทำอะไรต่อ — pick by name (e.g. untrack graph/ / distill memory / scope L2) แล้วผมจัดการได้"
assert_violation \
    "Thai V4 — อยากให้ทำอะไรต่อ" \
    "งานเสร็จ\n\nอยากให้ทำอะไรต่อในรอบนี้?"
assert_violation \
    "Thai V5 — เลือกตามใจ" \
    "นี่คือ A/B/C path · เลือกตามใจครับ"
assert_violation \
    "Thai V6 — ทำอันไหนก่อนดี" \
    "งานเหลือ 3 อย่าง — ทำอันไหนก่อนดีครับ?"
assert_violation \
    "Thai V7 — พิมพ์ imperative ตรง ๆ" \
    "ของที่ต้องทำ: X, Y, Z. ถ้าจะให้ผมรัน — พิมพ์ imperative ตรง ๆ ครับ"
assert_violation \
    "Thai V8 — หรือมีอย่างอื่นค้าง" \
    "เสร็จเรียบร้อย · ต้องการอะไรต่อ หรือมีอย่างอื่นค้างที่อยากเช็คมั้ย?"
assert_violation \
    "Thai V9 — X หรือ Y หรือ Z question" \
    "ตอนนี้สามารถทำได้: A หรือ B หรือ C นะครับ?"
assert_violation \
    "Thai V10 — จะให้ผมทำอะไร" \
    "พร้อมเดินหน้า — จะให้ผมทำอันไหนก่อนครับ"
# Round 2 fixtures — caught me 2026-05-07 right after PR #135 shipped
# (the rule is recursive: when a new phrasing slips through, pin it).
assert_violation \
    "Thai V11 — บอกผม → ผมจะ (arrow-conditional handoff)" \
    "ถ้ายังเจอผมหยุดถามแบบเก่า — phrasing ใหม่ที่ regex ยังไม่ครอบ · บอกผม → ผมจะเพิ่ม fixture + extend regex → ปิดต่อ · ครั้งนี้ structural fix ตามจริง ไม่ใช่ promise"
assert_violation \
    "Thai V12 — ถ้าเจอ X บอกผม" \
    "ทำเสร็จแล้ว · ถ้ายังเจอ bug ก็บอกผมได้"
assert_violation \
    "Thai V13 — ถ้าอยากให้ผม" \
    "ทุกอย่างเข้าที่ · ถ้าอยากให้ผมทำต่อ ก็เริ่มได้"

echo
echo "Violations expected — English (regression of v10-04 + new patterns):"
assert_violation \
    "EN V1 — what's next" \
    "Done with v12. What's next?"
assert_violation \
    "EN V2 — pick by name" \
    "Items pending: A, B, C, D. Pick by name and I'll act."
assert_violation \
    "EN V3 — soft-ask 'recommend running'" \
    "I recommend running /aegis-retro after you decide on the spec."
assert_violation \
    "EN V4 — what would you like next" \
    "Ready when you are. What would you like to do next?"
assert_violation \
    "EN V5 — anything else" \
    "Cleanup landed. Anything else you want me to handle?"
assert_violation \
    "EN V6 — classic A/B menu + ?" \
    $'Two paths:\n\nA) ship now\nB) defer\n\nWhich do you want?'

# ─── Round 3 — verbatim from 2026-05-08 dual-window screenshots ────────────
# User caught me regressing AGAIN despite Round 1+2 fixtures. The new
# phrasings that slipped through the existing regex:
#   1. "Next: X, or run /Y" — RizzLab brain-commit handoff
#   2. "Say the word"        — kam-tong-ham PR-merge handoff (English idiom)
#   3. "(can|could) also (end|pause) here" — passive option closing
#   4. "Still queued for you (separate decisions)" — soft TODO menu
# Each is a distinct shape; the regex update must cover all 4.
echo
echo "Violations expected — Round 3 (2026-05-08 dual-window screenshots):"
assert_violation \
    "Round3 V1 — RizzLab 'Next: X, or run /aegis-handoff'" \
    "Brain edits are uncommitted (12 files). Next: commit the brain delta, or run /aegis-handoff to pause without ending. The session can also end here."
assert_violation \
    "Round3 V2 — kam-tong-ham 'Say the word' PR merge handoff" \
    "PR #29 verified locally. Same approval pattern as PR #28. Say the word."
assert_violation \
    "Round3 V3 — 'can also end here' passive option" \
    "All sections green. The session can also end here — handoff already exists."
assert_violation \
    "Round3 V4 — 'Still queued for you (separate decisions)' soft TODO menu" \
    "Sprint closed. Still queued for you (separate decisions): HQ-006 and HQ-004."

# Round 5 — 2026-05-28 "recap + Next: <doable actions>" handoff. The agent
# lists work it can do RIGHT NOW under a recap/Next: header, then stops.
echo
echo "Violations expected — Round 5 (recap + Next: doable actions):"
assert_violation \
    "Round5 V1 — recap + Next: review/test/merge/deploy" \
    "recap: Goal: upgrade ATN-Bot's data pipeline. P0/P2 fixes are shipped and live (revision 00040); a background agent is implementing the bigger P1-D items on branch feat/pipeline-p1d. Next: review its diff, run tests, then merge and deploy."
assert_violation \
    "Round5 V2 — Next: review the PR and merge it" \
    "Background agent done. Next: review the PR and merge it."
assert_violation \
    "Round5 V3 — Next steps: run tests, then deploy" \
    "Summary done. Next steps: run tests, then deploy."

# Round 5 CLEAN — past-tense reports of completed work must NOT trigger.
echo
echo "Clean expected — Round 5 past-tense reports (must NOT trigger):"
assert_clean \
    "Round5 CLEAN 1 — reviewed/ran/deployed (past tense)" \
    "I reviewed the diff, ran tests, then deployed it. All green."
assert_clean \
    "Round5 CLEAN 2 — merged and deployed (past tense)" \
    "Merged PR #21 and deployed to production successfully."

# Round 3 CLEAN — the CORRECT declarative-pending phrasing for External
# Access gates must NOT trigger. This is the rewrite the agent should use:
echo
echo "Clean expected — Round 3 declarative-pending (must NOT trigger):"
assert_clean \
    "Round3 CLEAN 1 — declarative-pending External Access" \
    "Will run \`gh pr merge 29 --rebase --delete-branch\` on your by-name go (External Access gate per playbook). Continuing other work meanwhile."
assert_clean \
    "Round3 CLEAN 2 — declarative brain-commit autonomous" \
    "Brain delta committed (12 files). Handoff written. Session ending."

echo
echo "Clean expected — must NOT trigger (false-positive guard):"
assert_clean \
    "CLEAN 1 — pure status with closing period" \
    "v12 shipped 39/39 pt. All sprints CLOSED. Roadmap honest."
assert_clean \
    "CLEAN 2 — rhetorical question mid-message, action-statement closing" \
    "Why does this fail? Because the regex was substring-matched. Fix is to anchor it. Patched."
assert_clean \
    "CLEAN 3 — code block with question marks" \
    "Run: \`grep -E '\\?' file.txt\`. Then commit."
assert_clean \
    "CLEAN 4 — Thai prose ending in period" \
    "งานเสร็จเรียบร้อย ทุก pilot upgrade ผ่าน · ทั้งสอง branch merge แล้ว"
assert_clean \
    "CLEAN 5 — single Thai option but no question/handoff" \
    "ทำได้หลายทาง · เลือกที่เหมาะที่สุดสำหรับ project ของคุณ"

# ─── Summary ───────────────────────────────────────────────────────────────
echo
echo "================================================="
echo -e "Total: ${GREEN}$PASS pass${NC} / ${RED}$FAIL fail${NC}"
echo "================================================="
if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
exit 0
