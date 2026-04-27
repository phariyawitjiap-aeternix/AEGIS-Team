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
    # SOFT-ASK patterns (v10-04): catches the JingJai-style stops where the
    # agent hands the next action back to the human as a recommendation
    # instead of executing it or routing through Nick Fury. These fire on
    # their own (no need for an option-menu pattern alongside).
    soft_ask_patterns = [
        r'recommend\s+(running\s+)?[\\\\/]?aegis-',
        r'recommend\s+\w+\s+after\s+you',
        r'natural\s+(continuation|next\s+step|next\s+sprint)',
        r'next\s+chain\s+step\s*:',
        r'(sprint\s+\d+\s+planning|planning\s+(is|would\s+be))\s+the\s+natural',
        r'after\s+you\s+(decide|confirm|approve|review)\s+(on\s+)?the',
    ]
    has_option = any(re.search(p, tail, re.IGNORECASE|re.MULTILINE) for p in option_patterns)
    has_open = any(re.search(p, tail.strip(), re.IGNORECASE|re.MULTILINE) for p in open_patterns)
    has_soft_ask = any(re.search(p, tail, re.IGNORECASE|re.MULTILINE) for p in soft_ask_patterns)
    # Two ways to fire: classic A/B menu + open question, OR soft-ask pattern alone
    # (soft-ask is by itself a violation: rec + wait without execution).
    if (has_option and has_open) or has_soft_ask:
        print('violation')
    else:
        print('clean')
except Exception as ex:
    print('error:' + str(ex)[:80])
" 2>/dev/null || echo "error")

    if [[ "$MBP_VIOLATION" == "violation" ]]; then
        if [[ -f "$LOG" ]]; then
            TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "unknown")
            echo "[${TS}] [HOOK:on-stop] MBP_VIOLATION_BLOCKED — option menu detected, hook returning decision=block (Golden Rule #7)" >> "$LOG" 2>/dev/null || true
        fi

        # HARD BLOCK: return decision=block JSON to force the agent to retry
        # without the option menu. The current response stays visible to the user
        # but the agent immediately produces a corrective response per the
        # feedback in the "reason" field. This is the Stop-hook intercept pattern
        # documented in Claude Code hooks spec.
        #
        # Skip if AEGIS_MBP_BLOCK_DISABLE=1 (escape hatch for legitimate menus,
        # e.g., explicit slash command output that needs A/B/C semantics).
        # Also skip if stop_hook_active is true (prevent block loop).
        if [[ "${AEGIS_MBP_BLOCK_DISABLE:-0}" == "1" ]] || [[ "$STOP_HOOK_ACTIVE" == "True" ]]; then
            echo "" >&2
            echo "⚠️  AEGIS MBP CHECK — option menu detected (logged, NOT blocked: AEGIS_MBP_BLOCK_DISABLE=1 or stop_hook_active)" >&2
        else
            cat <<'BLOCK_JSON'
{
  "decision": "block",
  "reason": "AEGIS MBP Golden Rule #7 violation — your last response ended with an option menu (A/B/C/numbered list) PLUS an open question to the human. This is the #1 observed MBP failure pattern. You MUST NOT ask the human to pick from a menu. Instead, do ONE of these and produce a NEW response that takes action: (1) Decide autonomously per the Decision Matrix and execute the chosen path. (2) Route the question through Nick Fury via QUESTION_TO_BRAIN — he scans state and decides. (3) If it is genuinely Identity / Irreversible-scope / External-access / Explicit-approval-gate, write to .aegis/brain/human-queue.md via tools/aegis-queue-human.sh and CONTINUE with everything else you can do. The current option-menu response was already shown to the user; produce a corrective response that picks one path and acts. To bypass this block for a legitimate menu (rare — e.g., literal slash-command output), set AEGIS_MBP_BLOCK_DISABLE=1."
}
BLOCK_JSON
            exit 0
        fi
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

# ── Instinct auto-reinforce at session end (F3-02) ───────────────────────
if [[ -x "tools/aegis-instinct-auto-reinforce.sh" ]]; then
    echo ""
    echo "Instinct auto-reinforce..."
    bash tools/aegis-instinct-auto-reinforce.sh 2>/dev/null || true
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

# ── Grand-total progress banner ───────────────────────────────────────────
# Shows overall completion % so the user sees where we are in the roadmap,
# not just the current session's wins.
if [[ -x "tools/aegis-progress.sh" ]]; then
    echo ""
    bash tools/aegis-progress.sh --bar 2>/dev/null || true
fi

# ── Team chat tail — last 5 inter-agent events this session ───────────────
# Surfaces the internal team dialogue so the user sees what actually happened
# between spawns (dispatch, verdicts, handoffs) instead of only the final result.
CHAT_TODAY=".aegis/brain/conversations/$(date -u +%Y-%m-%d)/chat.log"
if [[ -f "$CHAT_TODAY" ]]; then
    CHAT_COUNT=$(wc -l < "$CHAT_TODAY" | tr -d ' ')
    if [[ "$CHAT_COUNT" -gt 0 ]]; then
        echo ""
        echo "┌─ 💬 Team chat (last 5 of $CHAT_COUNT today) ────────────────────┐"
        tail -5 "$CHAT_TODAY" | python3 -c "
import sys, json
icons = {'DISPATCH':'📤','REPORT':'📥','VERDICT':'⚖️ ','QUESTION':'❓','ANSWER':'💡','STATUS':'💓','HANDOFF':'🔁','BLOCKED':'🛑','NOTE':'📝'}
for line in sys.stdin:
    try:
        e = json.loads(line)
        icon = icons.get(e.get('type','NOTE'), '•')
        time = e.get('ts','')[11:19]
        task = f\"[{e['task']}] \" if e.get('task') else ''
        msg = (e.get('msg','')[:50]).ljust(50)
        line_str = f'│ {icon} {time} {e[\"from\"][:12]:<12} → {e[\"to\"][:12]:<12} {task}{msg} │'
        print(line_str[:80])
    except Exception:
        continue
" 2>/dev/null || true
        echo "└─────────────────────────────────────────────────────────────────┘"
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
