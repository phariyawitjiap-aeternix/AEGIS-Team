#!/usr/bin/env bash
# aegis-brain-graph-query-test.sh — Sprint v12-05 acceptance + regression test
#
# Verifies tools/aegis-brain-graph/query.mjs subcommands:
#   - impact, context, detect-changes, mentions, wiring
#   - --json output is parseable
#   - p95 latency < 200ms per query
#   - missing graph → exit 2 with helpful error
#   - invalid subcommand → exit 2

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
QUERY="${REPO_ROOT}/tools/aegis-brain-graph/query.mjs"
BUILD="${REPO_ROOT}/tools/aegis-brain-graph/build.mjs"

[[ -f "$QUERY" ]] || { echo "FATAL: missing $QUERY" >&2; exit 2; }
[[ -f "$BUILD" ]] || { echo "FATAL: missing $BUILD" >&2; exit 2; }
command -v node >/dev/null 2>&1 || { echo "FATAL: node not found" >&2; exit 2; }

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
PASS=0; FAIL=0
pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}FAIL${NC}: $1 -- $2"; FAIL=$((FAIL+1)); }

TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/aegis-graph-query-XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT INT TERM

echo "================================================="
echo "AEGIS brain-graph query — sprint v12-05 acceptance"
echo "================================================="

# Ensure live tree graph is fresh
node "$BUILD" --full --root "$REPO_ROOT" --quiet

# ─── Set up fixture graph ──────────────────────────────────────────────────
mkdir -p "$TEST_DIR/skills" "$TEST_DIR/.claude" "$TEST_DIR/.aegis/brain/sprints/sprint-test-01" "$TEST_DIR/tools/aegis-test"
cat > "$TEST_DIR/skills/test-skill.md" <<'EOF'
---
name: test-skill
description: "Test"
profile: standard
triggers:
  en: ["t"]
  th: []
reads: [".aegis/brain/test-input"]
writes: [".aegis/brain/test-output"]
wires: []
tests: ["tests/test-skill.sh"]
supersedes: []
---
EOF
cat > "$TEST_DIR/.claude/settings.json" <<'EOF'
{
  "hooks": {
    "PostToolUse": [
      { "matcher": "Edit", "hooks": [
        { "type": "command", "command": "node tools/aegis-test/hook.mjs" }
      ]}
    ]
  }
}
EOF
cat > "$TEST_DIR/.aegis/brain/sprints/sprint-test-01/close.md" <<'EOF'
# Sprint test-01

| ID | Story | Pt |
|----|-------|----|
| A | Add skills/test-skill.md and tools/aegis-test/hook.mjs | 1 |
EOF
echo 'console.log("hi");' > "$TEST_DIR/tools/aegis-test/hook.mjs"
mkdir -p "$TEST_DIR/.aegis/brain/learnings"
cat > "$TEST_DIR/.aegis/brain/learnings/test-mention.md" <<'EOF'
# A doc that mentions test-skill
This document references test-skill as the canonical example.
EOF
node "$BUILD" --full --root "$TEST_DIR" --quiet

# ─── T1: impact on real meta ───────────────────────────────────────────────
echo
echo "T1: impact on real meta repo"
START=$(node -e 'process.stdout.write(String(Date.now()))')
OUT=$(node "$QUERY" impact aegis-live-tail --root "$REPO_ROOT" 2>&1)
RC=$?
END=$(node -e 'process.stdout.write(String(Date.now()))')
ELAPSED=$((END - START))
if [[ $RC -eq 0 ]]; then
    pass "impact exits 0"
else
    fail "impact exits 0" "exit=$RC, output:\n$OUT"
fi
if [[ $ELAPSED -lt 200 ]]; then
    pass "impact < 200ms (actual: ${ELAPSED}ms)"
else
    fail "impact < 200ms" "actual: ${ELAPSED}ms"
fi
if echo "$OUT" | grep -q "skill:aegis-live-tail"; then
    pass "impact returns target node"
else
    fail "impact returns target node" "output:\n$OUT"
fi
if echo "$OUT" | grep -qE "(WRITES|TESTS|READS)"; then
    pass "impact traces multiple edge kinds"
else
    fail "impact traces multiple edge kinds" "output:\n$OUT"
fi

# ─── T2: context on real meta ──────────────────────────────────────────────
echo
echo "T2: context on real meta"
OUT=$(node "$QUERY" context aegis-live-tail --root "$REPO_ROOT" 2>&1)
RC=$?
if [[ $RC -eq 0 ]]; then
    pass "context exits 0"
else
    fail "context exits 0" "exit=$RC, output:\n$OUT"
fi
if echo "$OUT" | grep -q "incoming" && echo "$OUT" | grep -q "outgoing"; then
    pass "context groups by incoming/outgoing"
else
    fail "context groups by incoming/outgoing" "output:\n$OUT"
fi
if echo "$OUT" | grep -q "IMPLEMENTS"; then
    pass "context shows IMPLEMENTS edge from sprint"
else
    fail "context shows IMPLEMENTS edge" "output:\n$OUT"
fi

# ─── T3: wiring on real meta ───────────────────────────────────────────────
echo
echo "T3: wiring on real meta"
OUT=$(node "$QUERY" wiring 'PostToolUse:.*' --root "$REPO_ROOT" 2>&1)
RC=$?
if [[ $RC -eq 0 ]] && echo "$OUT" | grep -q "matching hook"; then
    pass "wiring exits 0 with matches"
else
    fail "wiring exits 0 with matches" "exit=$RC, output:\n$OUT"
fi
HOOK_COUNT=$(echo "$OUT" | grep -c "WIRES →")
if [[ $HOOK_COUNT -ge 2 ]]; then
    pass "wiring lists ≥ 2 hook → tool wires (actual: $HOOK_COUNT)"
else
    fail "wiring lists ≥ 2 hook → tool wires" "actual: $HOOK_COUNT, output:\n$OUT"
fi

# ─── T4: mentions on real meta ─────────────────────────────────────────────
echo
echo "T4: mentions on real meta"
OUT=$(node "$QUERY" mentions super-spec --root "$REPO_ROOT" 2>&1)
RC=$?
if [[ $RC -eq 0 ]]; then
    pass "mentions exits 0"
else
    fail "mentions exits 0" "exit=$RC, output:\n$OUT"
fi
if echo "$OUT" | grep -q "mention"; then
    pass "mentions reports count"
else
    fail "mentions reports count" "output:\n$OUT"
fi

# ─── T5: detect-changes on real meta ───────────────────────────────────────
echo
echo "T5: detect-changes on real meta (against HEAD~1)"
OUT=$(node "$QUERY" detect-changes --since HEAD~1 --root "$REPO_ROOT" 2>&1)
RC=$?
if [[ $RC -eq 0 ]]; then
    pass "detect-changes exits 0"
else
    fail "detect-changes exits 0" "exit=$RC, output:\n$OUT"
fi
if echo "$OUT" | grep -q "changed paths since"; then
    pass "detect-changes reports diff summary"
else
    fail "detect-changes reports diff summary" "output:\n$OUT"
fi

# ─── T6: --json output is parseable ────────────────────────────────────────
echo
echo "T6: --json output is parseable"
JSON_OUT=$(node "$QUERY" impact aegis-live-tail --root "$REPO_ROOT" --json 2>&1)
if echo "$JSON_OUT" | node -e 'let d="";process.stdin.on("data",c=>d+=c);process.stdin.on("end",()=>{const j=JSON.parse(d); if(!j.ok || !Array.isArray(j.results)) process.exit(7);})'; then
    pass "impact --json parses with expected shape"
else
    fail "impact --json parses with expected shape" "output:\n$JSON_OUT"
fi

# ─── T7: fixture impact ────────────────────────────────────────────────────
echo
echo "T7: fixture impact returns reachable set"
OUT=$(node "$QUERY" impact test-skill --root "$TEST_DIR" --json 2>&1)
RC=$?
if [[ $RC -eq 0 ]]; then
    pass "fixture impact exits 0"
else
    fail "fixture impact exits 0" "exit=$RC, output:\n$OUT"
fi
COUNT=$(echo "$OUT" | jq '.count')
if [[ $COUNT -ge 2 ]]; then
    pass "fixture impact reachable count ≥ 2 (actual: $COUNT)"
else
    fail "fixture impact reachable count ≥ 2" "actual: $COUNT"
fi

# ─── T8: fixture context ───────────────────────────────────────────────────
echo
echo "T8: fixture context groups by edge kind"
OUT=$(node "$QUERY" context test-skill --root "$TEST_DIR" --json 2>&1)
if echo "$OUT" | jq -e '.outgoing.READS' >/dev/null 2>&1; then
    pass "fixture context shows READS in outgoing"
else
    fail "fixture context shows READS in outgoing" "output:\n$OUT"
fi
if echo "$OUT" | jq -e '.outgoing.WRITES' >/dev/null 2>&1; then
    pass "fixture context shows WRITES in outgoing"
else
    fail "fixture context shows WRITES in outgoing" "output:\n$OUT"
fi
if echo "$OUT" | jq -e '.incoming.IMPLEMENTS' >/dev/null 2>&1; then
    pass "fixture context shows IMPLEMENTS in incoming"
else
    fail "fixture context shows IMPLEMENTS in incoming" "output:\n$OUT"
fi

# ─── T9: fixture mentions ──────────────────────────────────────────────────
echo
echo "T9: fixture mentions finds the brain doc"
OUT=$(node "$QUERY" mentions test-skill --root "$TEST_DIR" --json 2>&1)
COUNT=$(echo "$OUT" | jq '.count')
if [[ $COUNT -ge 1 ]]; then
    pass "fixture mentions count ≥ 1 (actual: $COUNT)"
else
    fail "fixture mentions count ≥ 1" "actual: $COUNT, output:\n$OUT"
fi

# ─── T10: fixture wiring ───────────────────────────────────────────────────
echo
echo "T10: fixture wiring resolves hook → tool"
OUT=$(node "$QUERY" wiring 'PostToolUse:Edit' --root "$TEST_DIR" --json 2>&1)
COUNT=$(echo "$OUT" | jq '.count')
if [[ $COUNT -ge 1 ]]; then
    pass "fixture wiring count ≥ 1 (actual: $COUNT)"
else
    fail "fixture wiring count ≥ 1" "actual: $COUNT, output:\n$OUT"
fi
if echo "$OUT" | jq -e '.hooks[0].wires_to | length' >/dev/null && [[ $(echo "$OUT" | jq '.hooks[0].wires_to | length') -ge 1 ]]; then
    pass "fixture wiring resolves ≥ 1 tool target"
else
    fail "fixture wiring resolves ≥ 1 tool target" "output:\n$OUT"
fi

# ─── T11: missing graph → exit 2 ───────────────────────────────────────────
echo
echo "T11: missing graph exits 2 with helpful error"
EMPTY_DIR=$(mktemp -d)
trap 'rm -rf "$EMPTY_DIR"; rm -rf "$TEST_DIR"' EXIT INT TERM
OUT=$(node "$QUERY" context anything --root "$EMPTY_DIR" 2>&1)
RC=$?
if [[ $RC -eq 2 ]]; then
    pass "missing graph exits 2"
else
    fail "missing graph exits 2" "exit=$RC, output:\n$OUT"
fi
if echo "$OUT" | grep -q "Run.*build"; then
    pass "missing graph shows actionable error"
else
    fail "missing graph shows actionable error" "output:\n$OUT"
fi

# ─── T12: unknown subcommand → exit 2 ──────────────────────────────────────
echo
echo "T12: unknown subcommand exits 2"
OUT=$(node "$QUERY" bogus arg --root "$REPO_ROOT" 2>&1)
RC=$?
if [[ $RC -eq 2 ]]; then
    pass "unknown subcommand exits 2"
else
    fail "unknown subcommand exits 2" "exit=$RC, output:\n$OUT"
fi

# ─── T13: nonexistent target → ok=false ────────────────────────────────────
echo
echo "T13: nonexistent target returns ok=false"
OUT=$(node "$QUERY" context nonexistent-skill-xyz --root "$REPO_ROOT" --json 2>&1)
RC=$?
if [[ $RC -eq 1 ]]; then
    pass "nonexistent target exits 1"
else
    fail "nonexistent target exits 1" "exit=$RC, output:\n$OUT"
fi
if echo "$OUT" | jq -e '.ok == false' >/dev/null 2>&1; then
    pass "nonexistent target reports ok=false in JSON"
else
    fail "nonexistent target reports ok=false in JSON" "output:\n$OUT"
fi

# ─── T14: detect-changes requires --since ──────────────────────────────────
echo
echo "T14: detect-changes without --since exits 2"
OUT=$(node "$QUERY" detect-changes --root "$REPO_ROOT" 2>&1)
RC=$?
if [[ $RC -eq 2 ]]; then
    pass "detect-changes without --since exits 2"
else
    fail "detect-changes without --since exits 2" "exit=$RC"
fi

# ─── Summary ───────────────────────────────────────────────────────────────
echo
echo "================================================="
echo -e "Total: ${GREEN}$PASS pass${NC} / ${RED}$FAIL fail${NC}"
echo "================================================="
if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
exit 0
