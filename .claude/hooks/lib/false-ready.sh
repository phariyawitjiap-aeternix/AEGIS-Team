#!/usr/bin/env bash
# AEGIS on-stop module: false-ready.sh
# Golden Rule #4: false-ready guard.
# Scans transcript for Agent tool_use entries without matching tool_result.
# Sourced by on-stop.sh orchestrator.
#
# Args: $1 = transcript_path, $2 = activity log path
# Output: stdout warning/violation banners

false_ready_check() {
    local TRANSCRIPT_PATH="${1:-}"
    local LOG="${2:-}"

    if [[ -z "$TRANSCRIPT_PATH" || ! -f "$TRANSCRIPT_PATH" ]]; then
        return 0
    fi

    local FR_RESULT
    FR_RESULT=$(python3 - "$TRANSCRIPT_PATH" <<'PYEOF' 2>/dev/null || echo "error"
import sys, json, re
try:
    with open(sys.argv[1]) as f:
        lines = f.readlines()
    tool_uses = {}   # id -> {name, desc}
    tool_results = set()
    recent_texts = []
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
                recent_texts.append(block.get('text', ''))  # keep a small tail window
                if len(recent_texts) > 4:
                    recent_texts.pop(0)
    last_text = recent_texts[-1] if recent_texts else ''
    unmatched = [(uid, meta) for uid, meta in tool_uses.items() if uid not in tool_results]
    # Completion-claim detector (shared by both cases)
    claim_patterns = [
        r'\b(all\s+)?done\b',
        r'\bcomplete[d]?\b',
        r'\bfinished\b',
        r'\bshipped\b',
        r'\bready\s+to\s+(ship|merge|deploy)\b',
        r'\bpipeline\s+complete\b',
        r'✅',  # checkmark
    ]
    tail = last_text[-1500:]
    has_claim = any(re.search(p, tail, re.IGNORECASE) for p in claim_patterns)
    # Case A: spawned agents whose tool_result never came back.
    if unmatched:
        first_desc = unmatched[0][1]['desc']
        sev = 'violation' if has_claim else 'warning'
        print(f'{sev}|{len(unmatched)}|{has_claim}|{first_desc}')
        sys.exit(0)
    # Case B: a real subagent dispatch was ANNOUNCED but no Agent/Task tool_use
    # exists at all -> the team was role-played inline, not actually spawned.
    if len(tool_uses) == 0:
        dispatch_patterns = [
            r'spawn(ing|s)?\s+(the\s+)?(team|sub-?agents?)',
            r'🖥️',
            r'dispatch(es|ing|ed)?\s+(nick\s*fury|captain\s*america|iron\s*man|loki|thor|spider-?man|coulson|beast|war\s*machine|black\s*panther|wasp|hulk)',
            r'→\s*\[[^\]]+\]\s*:',   # agent task list  → [Iron Man]: ...
        ]
        scan = '\n'.join(recent_texts)[-3000:]
        if any(re.search(p, scan, re.IGNORECASE) for p in dispatch_patterns):
            sev = 'violation' if has_claim else 'warning'
            print(f'dispatch_claim|{sev}|{has_claim}')
            sys.exit(0)
    print('clean')
    sys.exit(0)
except Exception as ex:
    print('error:' + str(ex)[:80])
PYEOF
)

    case "$FR_RESULT" in
        violation\|*|warning\|*)
            local SEV CNT CLAIM DESC SEV_UPPER
            SEV=$(echo "$FR_RESULT" | cut -d'|' -f1)
            CNT=$(echo "$FR_RESULT" | cut -d'|' -f2)
            CLAIM=$(echo "$FR_RESULT" | cut -d'|' -f3)
            DESC=$(echo "$FR_RESULT" | cut -d'|' -f4)
            SEV_UPPER=$(echo "$SEV" | tr '[:lower:]' '[:upper:]')
            if [[ -n "$LOG" && -f "$LOG" ]]; then
                local TS
                TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "unknown")
                echo "[${TS}] [HOOK:on-stop] FALSE_READY_${SEV_UPPER} -- ${CNT} unmatched Agent tool_use (no result); completion_claim=${CLAIM}; first=\"${DESC}\"" >> "$LOG" 2>/dev/null || true
            fi
            echo ""
            if [[ "$SEV" == "violation" ]]; then
                echo "AEGIS FALSE-READY GUARD -- Golden Rule #4 violation"
                echo ""
                echo "  ${CNT} spawned agent(s) have NO tool_result, yet the"
                echo "  last response contains a completion claim (done/shipped/"
                echo "  ready). Orchestrator declared success with agents still"
                echo "  running. This is the false-ready pattern Rule #4 bans."
                echo ""
                echo "  First unmatched: ${DESC}"
                echo "  Logged to: .aegis/brain/logs/activity.log"
            else
                echo "AEGIS false-ready check -- unmatched agent(s)"
                echo ""
                echo "  ${CNT} spawned agent(s) have no tool_result in the"
                echo "  transcript. This may be OK (background run still pending,"
                echo "  or Ctrl+C interrupt) -- but verify before closing session."
                echo ""
                echo "  First unmatched: ${DESC}"
            fi
            ;;
        dispatch_claim\|*)
            local SEV CLAIM SEV_UPPER
            SEV=$(echo "$FR_RESULT" | cut -d'|' -f2)
            CLAIM=$(echo "$FR_RESULT" | cut -d'|' -f3)
            SEV_UPPER=$(echo "$SEV" | tr '[:lower:]' '[:upper:]')
            if [[ -n "$LOG" && -f "$LOG" ]]; then
                local TS
                TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "unknown")
                echo "[${TS}] [HOOK:on-stop] FALSE_READY_DISPATCH_${SEV_UPPER} -- team spawn announced but no Agent tool_use in transcript; completion_claim=${CLAIM}" >> "$LOG" 2>/dev/null || true
            fi
            echo ""
            if [[ "$SEV" == "violation" ]]; then
                echo "AEGIS FALSE-READY GUARD -- dispatch claimed, none spawned"
                echo ""
                echo "  The response announces a subagent team (Spawning team /"
                echo "  Nick Fury dispatches ...) AND claims completion, but there"
                echo "  is no Agent tool_use in the transcript -- the team was"
                echo "  role-played inline, not actually spawned. Either fire the"
                echo "  Agent tool, or drop the spawn language and say plainly"
                echo "  'running inline as <persona>'."
            else
                echo "AEGIS false-ready check -- dispatch announced, no Agent tool fired"
                echo ""
                echo "  The response announces a team spawn but no Agent tool was"
                echo "  fired (yet). OK if this is a cross-turn /goal loop that"
                echo "  dispatches next turn -- otherwise say 'running inline as"
                echo "  <persona>' so the mode is honest."
            fi
            ;;
    esac
}

# Allow direct invocation for testing
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    false_ready_check "$@"
fi
