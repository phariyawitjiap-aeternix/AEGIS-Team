#!/usr/bin/env bash
# test-false-ready-dispatch-claim.sh
# Verify false-ready.sh ALSO catches the inverse false-ready pattern:
#   the response ANNOUNCES a real subagent dispatch ("Spawning team",
#   "Nick Fury dispatches Iron Man", agent task list) but NO Agent/Task
#   tool_use exists in the transcript -> the team was role-played inline,
#   not actually spawned. Closes the policy-without-test gap where AEGIS
#   docs claim "spawns a team" yet the session never fires the Agent tool.
#
# Coverage:
#   TC-01: spawn banner + NO Agent tool_use + completion claim -> violation
#   TC-02: spawn banner + NO Agent tool_use, no claim          -> warning
#   TC-03: spawn banner + REAL Agent tool_use (+result)        -> clean (backed)
#   TC-04: generic "Sprint X dispatched" prose, no persona/team -> clean (no false positive)
#   TC-05: plain inline answer, no dispatch language            -> clean

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIB="$REPO_ROOT/.claude/hooks/lib/false-ready.sh"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

PASS=0
FAIL=0
assert_contains() {
    local name="$1" needle="$2" hay="$3"
    if [[ "$hay" == *"$needle"* ]]; then
        echo "  PASS: $name"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $name"
        echo "    expected to contain: $needle"
        echo "    got: $hay"
        FAIL=$((FAIL + 1))
    fi
}
assert_not_contains() {
    local name="$1" needle="$2" hay="$3"
    if [[ "$hay" != *"$needle"* ]]; then
        echo "  PASS: $name"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $name"
        echo "    expected NOT to contain: $needle"
        echo "    got: $hay"
        FAIL=$((FAIL + 1))
    fi
}

# shellcheck source=/dev/null
source "$LIB"

# ── TC-01: spawn banner + no Agent tool_use + completion claim → violation ──
cat > "$TMP/tc01.jsonl" <<'JSONL'
{"message":{"role":"user","content":[{"type":"text","text":"build the auth module"}]}}
{"message":{"role":"assistant","content":[{"type":"text","text":"🧬 Nick Fury: Decision P2.\n🖥️ Spawning team in tmux...\n   → [Iron Man]: design auth\n   → [Spider-Man]: implement\n\nTeam complete. Auth module shipped. ✅"}]}}
JSONL
OUT_TC01=$(false_ready_check "$TMP/tc01.jsonl" "" 2>&1 || true)
assert_contains "TC-01 flags dispatch-claim violation" "FALSE-READY" "$OUT_TC01"
assert_contains "TC-01 mentions no real dispatch"      "no Agent" "$OUT_TC01"

# ── TC-02: spawn banner + no Agent tool_use, no completion claim → warning ──
cat > "$TMP/tc02.jsonl" <<'JSONL'
{"message":{"role":"user","content":[{"type":"text","text":"build the auth module"}]}}
{"message":{"role":"assistant","content":[{"type":"text","text":"🧬 Nick Fury dispatches Iron Man to design the auth module. Spawning team now."}]}}
JSONL
OUT_TC02=$(false_ready_check "$TMP/tc02.jsonl" "" 2>&1 || true)
assert_contains "TC-02 warns on announced-but-unspawned" "no Agent" "$OUT_TC02"

# ── TC-03: spawn banner + REAL Agent tool_use with result → clean ──
cat > "$TMP/tc03.jsonl" <<'JSONL'
{"message":{"role":"user","content":[{"type":"text","text":"build the auth module"}]}}
{"message":{"role":"assistant","content":[{"type":"text","text":"🖥️ Spawning team. Nick Fury dispatches Iron Man."},{"type":"tool_use","id":"t1","name":"Agent","input":{"subagent_type":"iron-man","description":"design auth"}}]}}
{"message":{"role":"user","content":[{"type":"tool_result","tool_use_id":"t1","content":"done"}]}}
{"message":{"role":"assistant","content":[{"type":"text","text":"Iron Man returned the spec. Team complete."}]}}
JSONL
OUT_TC03=$(false_ready_check "$TMP/tc03.jsonl" "" 2>&1 || true)
assert_not_contains "TC-03 no flag when dispatch is real" "no Agent" "$OUT_TC03"

# ── TC-04: generic 'Sprint X dispatched' prose → no false positive ──
cat > "$TMP/tc04.jsonl" <<'JSONL'
{"message":{"role":"user","content":[{"type":"text","text":"what next?"}]}}
{"message":{"role":"assistant","content":[{"type":"text","text":"Sprint v10-03 dispatched. Nick Fury scanning state. Done."}]}}
JSONL
OUT_TC04=$(false_ready_check "$TMP/tc04.jsonl" "" 2>&1 || true)
assert_not_contains "TC-04 no false positive on generic 'dispatched'" "FALSE-READY" "$OUT_TC04"
assert_not_contains "TC-04 no dispatch-claim flag"                    "no Agent" "$OUT_TC04"

# ── TC-05: plain inline answer, no dispatch language → clean ──
cat > "$TMP/tc05.jsonl" <<'JSONL'
{"message":{"role":"user","content":[{"type":"text","text":"explain the auth flow"}]}}
{"message":{"role":"assistant","content":[{"type":"text","text":"The auth flow validates the token, checks the session, then issues a JWT. Complete."}]}}
JSONL
OUT_TC05=$(false_ready_check "$TMP/tc05.jsonl" "" 2>&1 || true)
assert_not_contains "TC-05 no flag on plain inline answer" "no Agent" "$OUT_TC05"

echo ""
echo "RESULTS: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]]
