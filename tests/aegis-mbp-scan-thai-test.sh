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

# Run the scanner against a fixture. Returns "violation" / "clean" / "no_text" via stdout.
# We bypass the bash wrapper — call the python block directly the way mbp_scan does.
run_scan() {
    local fixture_text="$1"
    local transcript="$TEST_DIR/transcript.jsonl"
    mk_transcript "$transcript" "$fixture_text"
    # Mirror the mbp-scan internals exactly to test the python block in isolation.
    python3 - "$transcript" <<'PYEOF' 2>/dev/null
import sys, json, re
try:
    with open(sys.argv[1]) as f:
        lines = f.readlines()
    last_text = ''
    for line in reversed(lines):
        try:
            e = json.loads(line)
        except Exception:
            continue
        if e.get('type') == 'assistant' or (e.get('message', {}).get('role') == 'assistant'):
            msg = e.get('message', {})
            content = msg.get('content', [])
            if isinstance(content, list):
                for block in content:
                    if isinstance(block, dict) and block.get('type') == 'text':
                        last_text = block.get('text', '')
                        break
            elif isinstance(content, str):
                last_text = content
            if last_text:
                break
    if not last_text:
        print('no_text'); sys.exit(0)
    tail = last_text[-2000:]
    closing = last_text[-400:]
    option_patterns = [
        r'Options?:\s*\n\s*[-\*]\s*["\x27]',
        r'Options?:\s*\n\s*A\s*[\)\.]',
        r'\n\s*A\)\s*.+?\n\s*B\)',
        r'\n\s*1\.\s*.+?\n\s*2\.\s*.+?\n\s*3\.',
        r'\S+\s+หรือ\s+\S+\s+หรือ\s+\S+',
        r'\S+\s*[·•/]\s*\S+\s*[·•/]\s*\S+\s*\?',
    ]
    open_patterns = [
        r'\?\s*$',
        r'(what|which|how).{0,40}(do you|would you|should).{0,60}\?',
        r'(let me know|tell me|your call)',
    ]
    soft_ask_patterns = [
        r'recommend\s+(running\s+)?[\\\/]?aegis-',
        r'recommend\s+\w+\s+after\s+you',
        r'natural\s+(continuation|next\s+step|next\s+sprint)',
        r'next\s+chain\s+step\s*:',
        r'(sprint\s+\d+\s+planning|planning\s+(is|would\s+be))\s+the\s+natural',
        r'after\s+you\s+(decide|confirm|approve|review)\s+(on\s+)?the',
        r'what\s+(would\s+you\s+like|do\s+you\s+want|should\s+(i|we)\s+do)\s+(to\s+do\s+)?next\s*\??',
        r"(what's|whats)\s+next\s*\??",
        r'next\s+action\s*\??',
        r'pick\s+(by\s+name|one|any)',
        r'anything\s+else',
        r'your\s+call\s*[—\-:]',
        r'let\s+me\s+know\s+(if|when|what)',
        r'ต้องการ.{0,20}อะไร.{0,5}ต่อ',
        r'(ต่อไป|ทำ).{0,5}(จะ)?\s*ทำ\s*อะไร\s*(ต่อ|ดี)?',
        r'อยาก.{0,15}(ทำ|ให้ทำ).{0,15}อะไร',
        r'(ทำ|จัดการ|ไป).{0,5}อันไหน.{0,20}(ก่อน|ดี)',
        r'(เลือก|pick).{0,15}(ตาม|by).{0,5}(ใจ|name|อารมณ์)',
        r'หรือ.{0,5}มี.{0,15}อย่างอื่น',
        r'พิมพ์.{0,30}(imperative|by-name|ตรง.?ๆ)',
        r'จะให้ผม.{0,15}ทำ\s*(อะไร|อันไหน)',
        r'บอก\s*ผม',
        r'ถ้า.{0,30}เจอ.{0,40}(บอก|พิมพ์|ส่ง)',
        r'→\s*ผม.{0,30}จะ',
        r'ถ้า.{0,40}(อยากให้|ต้องการให้)\s*ผม',
        # Round 3 — 2026-05-08 dual-window screenshots
        r'\bSay\s+the\s+word\b',
        r'\b[Nn]ext:\s+\w[^.\n]{1,80},\s+or\s+(run|use|do|invoke)\b',
        r',\s+or\s+run\s+[/\\][a-z][a-z0-9-]*',
        r'\b(can|could|may)\s+also\s+(end|stop|pause|run|do)\b',
        r'queued\s+for\s+you\s*\([^)]{0,60}decisions?\b',
    ]
    has_option = any(re.search(p, tail, re.IGNORECASE|re.MULTILINE) for p in option_patterns)
    has_open = any(re.search(p, tail.strip(), re.IGNORECASE|re.MULTILINE) for p in open_patterns)
    has_soft_ask = any(re.search(p, tail, re.IGNORECASE|re.MULTILINE) for p in soft_ask_patterns)
    closing_open = any(re.search(p, closing.strip(), re.IGNORECASE|re.MULTILINE) for p in open_patterns)
    closing_soft = any(re.search(p, closing, re.IGNORECASE|re.MULTILINE) for p in soft_ask_patterns)
    if (has_option and has_open) or has_soft_ask or (closing_open and closing_soft):
        print('violation')
    else:
        print('clean')
except Exception as ex:
    print('error:' + str(ex)[:80])
PYEOF
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
