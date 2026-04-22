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
