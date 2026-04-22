#!/usr/bin/env bash
# AEGIS Hook — on-stop.sh
# Fires when Claude is about to stop the session (Stop event)
# Enforces Golden Rule 6: Run /aegis-retro at session end
# Logs session end + reminds human to run retro
#
# Input:  JSON on stdin { "session_id": "...", "stop_hook_active": false, ... }
# Output: stdout message displayed to user (exit 0 = allow stop)

set -euo pipefail

INPUT=$(cat)
STOP_HOOK_ACTIVE=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('stop_hook_active', False))" 2>/dev/null || echo "False")

# Log session end
LOG=".aegis/brain/logs/activity.log"
if [[ -f "$LOG" ]]; then
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "unknown")
    echo "[${TIMESTAMP}] [HOOK:on-stop] SESSION_END — Claude stopping" >> "$LOG" 2>/dev/null || true
fi

# ── Batched format/typecheck ──────────────────────────────────────────────
# Pattern adopted from ECC. Runs a single format + typecheck pass over all
# files edited during this response, instead of per-edit (expensive).
# Skipped if stop_hook_active (prevents loops) or if no accumulator file.
if [[ "$STOP_HOOK_ACTIVE" != "True" ]]; then
    SESSION_ID="${CLAUDE_SESSION_ID:-default}"
    ACC_FILE="/tmp/aegis-edits/${SESSION_ID}.txt"
    if [[ -f "$ACC_FILE" ]]; then
        # Dedupe and extract file types we can check
        ALL_FILES=$(sort -u "$ACC_FILE" 2>/dev/null || true)
        TS_FILES=$(echo "$ALL_FILES" | grep -E '\.(ts|tsx|js|jsx|mjs|cjs)$' || true)
        PY_FILES=$(echo "$ALL_FILES" | grep -E '\.py$' || true)

        BATCH_COUNT=$(echo "$ALL_FILES" | grep -c . 2>/dev/null || echo 0)

        if [[ "$BATCH_COUNT" -gt 0 ]]; then
            echo ""
            echo "🔍 AEGIS batched quality check (${BATCH_COUNT} file(s) edited this turn)..."

            # TS/JS: try biome, fall back to prettier + tsc
            if [[ -n "$TS_FILES" ]]; then
                if [[ -f "biome.json" || -f "biome.jsonc" ]] && command -v npx &>/dev/null; then
                    echo "  ├─ biome check..."
                    echo "$TS_FILES" | xargs npx --no-install biome check --write 2>&1 | tail -3 || true
                fi
                if [[ -f "tsconfig.json" ]] && command -v npx &>/dev/null; then
                    echo "  ├─ tsc --noEmit..."
                    npx --no-install tsc --noEmit 2>&1 | tail -5 || true
                fi
            fi

            # Python: try ruff, fall back silently
            if [[ -n "$PY_FILES" ]]; then
                if command -v ruff &>/dev/null; then
                    echo "  ├─ ruff check..."
                    echo "$PY_FILES" | xargs ruff check 2>&1 | tail -5 || true
                fi
            fi

            echo "  └─ done"
        fi

        # Clean up accumulator for this session
        rm -f "$ACC_FILE" 2>/dev/null || true
    fi
fi

# Don't loop (stop_hook_active prevents infinite recursion)
if [[ "$STOP_HOOK_ACTIVE" == "True" ]]; then
    exit 0
fi

# ── Master Brain Protocol violation scan ──────────────────────────────────────
# Scans the last assistant message in the transcript for the classic MBP
# violation pattern: option menu handed back to the user instead of routed
# through Nick Fury. Pattern signatures:
#   - "Options:" followed by A) / B) / C) or "- quoted-word"
#   - Message ending in "?" or "what do you want/prefer/think"
# If detected, logs to activity.log and shows a reminder to the user.
TRANSCRIPT_PATH=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('transcript_path', ''))" 2>/dev/null || echo "")

if [[ -n "$TRANSCRIPT_PATH" && -f "$TRANSCRIPT_PATH" ]]; then
    MBP_VIOLATION=$(python3 -c "
import sys, json, re
try:
    with open('$TRANSCRIPT_PATH') as f:
        lines = f.readlines()
    # Find the very last assistant text turn
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
        print('no_text')
        sys.exit(0)
    # Scan last 2000 chars for option-menu patterns
    tail = last_text[-2000:]
    option_patterns = [
        r'Options?:\s*\n\s*[-\*]\s*[\"\\']',
        r'Options?:\s*\n\s*A\s*[\)\.]',
        r'\n\s*A\)\s*.+?\n\s*B\)',
        r'\n\s*1\.\s*.+?\n\s*2\.\s*.+?\n\s*3\.',
    ]
    open_patterns = [
        r'\?\s*\$',
        r'(what|which|how).{0,40}(do you|would you|should).{0,60}\?',
        r'(let me know|tell me|your call)',
    ]
    has_option = any(re.search(p, tail, re.IGNORECASE|re.MULTILINE) for p in option_patterns)
    has_open = any(re.search(p, tail.strip(), re.IGNORECASE|re.MULTILINE) for p in open_patterns)
    if has_option and has_open:
        print('violation')
    else:
        print('clean')
except Exception as ex:
    print('error:' + str(ex)[:80])
" 2>/dev/null || echo "error")

    if [[ "$MBP_VIOLATION" == "violation" ]]; then
        if [[ -f "$LOG" ]]; then
            TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "unknown")
            echo "[${TS}] [HOOK:on-stop] MBP_VIOLATION — last response ended with option menu + open question (Golden Rule #7)" >> "$LOG" 2>/dev/null || true
        fi
        echo ""
        echo "┌─────────────────────────────────────────────────────────────┐"
        echo "│  ⚠️  AEGIS MBP CHECK — Golden Rule #7 violation detected     │"
        echo "│                                                             │"
        echo "│  The last response ended with an option menu (A/B/C) +      │"
        echo "│  an open question to you. Per Master Brain Protocol,        │"
        echo "│  decisions should route through Nick Fury via               │"
        echo "│  QUESTION_TO_BRAIN — not handed back to the human.          │"
        echo "│                                                             │"
        echo "│  See: .claude/references/context-rules.md §MBP              │"
        echo "│  Logged to: .aegis/brain/logs/activity.log                  │"
        echo "└─────────────────────────────────────────────────────────────┘"
    fi

    # ── Golden Rule #4: false-ready guard ─────────────────────────────────────
    # Scans the transcript for Task/Agent tool_use entries without a matching
    # tool_result — i.e., spawned agents whose reports never came back before
    # the orchestrator ended the turn. Strongly warns if the last assistant
    # text also contains a completion claim ("done", "complete", "shipped", etc.)
    # while unmatched agents exist.
    FR_RESULT=$(python3 -c "
import sys, json, re
try:
    with open('$TRANSCRIPT_PATH') as f:
        lines = f.readlines()
    tool_uses = {}   # id → {name, desc}
    tool_results = set()
    last_text = ''
    for line in lines:
        try:
            e = json.loads(line)
        except Exception:
            continue
        msg = e.get('message', {})
        content = msg.get('content', [])
        if not isinstance(content, list):
            continue
        for block in content:
            if not isinstance(block, dict):
                continue
            btype = block.get('type', '')
            if btype == 'tool_use' and block.get('name') in ('Task', 'Agent'):
                ti = block.get('input', {}) or {}
                tool_uses[block.get('id', '')] = {
                    'name': block.get('name'),
                    'desc': (ti.get('description') or ti.get('subagent_type') or '?')[:40],
                }
            elif btype == 'tool_result':
                tool_results.add(block.get('tool_use_id', ''))
            elif btype == 'text':
                last_text = block.get('text', '')  # keep updating; last wins
    unmatched = [(uid, meta) for uid, meta in tool_uses.items() if uid not in tool_results]
    if not unmatched:
        print('clean')
        sys.exit(0)
    # Check for completion-claim text in last assistant turn
    claim_patterns = [
        r'\b(all\s+)?done\b',
        r'\bcomplete[d]?\b',
        r'\bfinished\b',
        r'\bshipped\b',
        r'\bready\s+to\s+(ship|merge|deploy)\b',
        r'\bpipeline\s+complete\b',
        r'\\u2705',  # ✅ checkmark
    ]
    tail = last_text[-1500:]
    has_claim = any(re.search(p, tail, re.IGNORECASE) for p in claim_patterns)
    # Output format: 'violation|count|claim|first-desc'
    first_desc = unmatched[0][1]['desc'] if unmatched else ''
    sev = 'violation' if has_claim else 'warning'
    print(f'{sev}|{len(unmatched)}|{has_claim}|{first_desc}')
except Exception as ex:
    print('error:' + str(ex)[:80])
" 2>/dev/null || echo "error")

    case "$FR_RESULT" in
        violation\|*|warning\|*)
            SEV=$(echo "$FR_RESULT" | cut -d'|' -f1)
            CNT=$(echo "$FR_RESULT" | cut -d'|' -f2)
            CLAIM=$(echo "$FR_RESULT" | cut -d'|' -f3)
            DESC=$(echo "$FR_RESULT" | cut -d'|' -f4)
            SEV_UPPER=$(echo "$SEV" | tr '[:lower:]' '[:upper:]')
            if [[ -f "$LOG" ]]; then
                TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "unknown")
                echo "[${TS}] [HOOK:on-stop] FALSE_READY_${SEV_UPPER} — ${CNT} unmatched Agent tool_use (no result); completion_claim=${CLAIM}; first=\"${DESC}\"" >> "$LOG" 2>/dev/null || true
            fi
            echo ""
            if [[ "$SEV" == "violation" ]]; then
                echo "┌─────────────────────────────────────────────────────────────┐"
                echo "│  🚨 AEGIS FALSE-READY GUARD — Golden Rule #4 violation       │"
                echo "│                                                             │"
                printf "│  %-57s│\n" "${CNT} spawned agent(s) have NO tool_result, yet the"
                echo "│  last response contains a completion claim (done/shipped/   │"
                echo "│  ready). Orchestrator declared success with agents still    │"
                echo "│  running. This is the false-ready pattern Rule #4 bans.     │"
                echo "│                                                             │"
                printf "│  First unmatched: %-41s│\n" "${DESC}"
                echo "│  Logged to: .aegis/brain/logs/activity.log                  │"
                echo "└─────────────────────────────────────────────────────────────┘"
            else
                echo "┌─────────────────────────────────────────────────────────────┐"
                echo "│  ⚠️  AEGIS false-ready check — unmatched agent(s)            │"
                echo "│                                                             │"
                printf "│  %-57s│\n" "${CNT} spawned agent(s) have no tool_result in the"
                echo "│  transcript. This may be OK (background run still pending,  │"
                echo "│  or Ctrl+C interrupt) — but verify before closing session.  │"
                echo "│                                                             │"
                printf "│  First unmatched: %-41s│\n" "${DESC}"
                echo "└─────────────────────────────────────────────────────────────┘"
            fi
            ;;
    esac
fi

# ── Human Action Queue — bilingual banner ─────────────────────────────────
# Show pending items from .aegis/brain/human-queue.md so the user doesn't
# have to hunt through retros/handoffs to find what genuinely needs them.
# Only surfaces when pending count > 0.
QUEUE=".aegis/brain/human-queue.md"
if [[ -f "$QUEUE" ]]; then
    PENDING_COUNT=$(python3 -c "
import re
with open('$QUEUE') as f:
    c = f.read()
m = re.search(r'<!-- PENDING_START -->(.*?)<!-- PENDING_END -->', c, re.DOTALL)
if m:
    inner = m.group(1)
    print(len(re.findall(r'^### \[', inner, re.MULTILINE)))
else:
    print(0)
" 2>/dev/null || echo "0")

    if [[ "$PENDING_COUNT" -gt 0 ]]; then
        echo ""
        echo "┌─────────────────────────────────────────────────────────────┐"
        echo "│  👤 HUMAN QUEUE / คิวรอ human — ${PENDING_COUNT} pending item(s)          │"
        echo "├─────────────────────────────────────────────────────────────┤"
        python3 <<PYEOF
import re
with open('$QUEUE') as f:
    c = f.read()
m = re.search(r'<!-- PENDING_START -->(.*?)<!-- PENDING_END -->', c, re.DOTALL)
if m:
    for entry in re.finditer(r'### \[(\d{4}-\d{2}-\d{2})\] (\w+) — (.+?) / (.+?)$', m.group(1), re.MULTILINE):
        date, cat, en, th = entry.groups()
        line_en = f"│  [{cat}] {en}"
        line_th = f"│  [{cat}] {th}"
        print(line_en[:63].ljust(63) + "│")
        print(line_th[:63].ljust(63) + "│")
        print("│" + " " * 61 + "│")
PYEOF
        echo "│  See: .aegis/brain/human-queue.md                           │"
        echo "└─────────────────────────────────────────────────────────────┘"
    fi
fi

# Remind human
echo ""
echo "┌─────────────────────────────────────────────────────┐"
echo "│  🛡️  AEGIS — Session Ending                          │"
echo "│                                                     │"
echo "│  Golden Rule 6: Run /aegis-retro before you leave   │"
echo "│  This saves lessons, updates resonance, and logs    │"
echo "│  a handoff for the next session.                    │"
echo "│                                                     │"
echo "│  > /aegis-retro                                     │"
echo "└─────────────────────────────────────────────────────┘"

exit 0
