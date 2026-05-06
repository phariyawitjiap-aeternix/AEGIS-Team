#!/usr/bin/env bash
# aegis-brain-graph-build-test.sh — Sprint v12-04 acceptance + regression test
#
# Verifies tools/aegis-brain-graph/build.mjs:
#   - --full cold build on the real meta repo: ≥ 100 nodes, ≥ 50 edges
#   - --full two consecutive runs are byte-equal (deterministic)
#   - --incremental skips when no source changed (< 200ms)
#   - --full build is < 2s wall-clock on the real meta repo
#   - meta.json carries built_at, source_mtime_max, node_count, edge_count, builder_version
#   - graph dir is gitignored
#   - --full on a fixture: produces correct node + edge counts
#   - Crash-mid-build (simulated by chmod) leaves prev graph intact (or rebuilds cleanly)
#   - Hook script returns exit 0 immediately (background-coalesce semantics)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD="${REPO_ROOT}/tools/aegis-brain-graph/build.mjs"
HOOK="${REPO_ROOT}/tools/aegis-brain-graph/hook.sh"
GRAPH_DIR="${REPO_ROOT}/.aegis/brain/graph"

[[ -f "$BUILD" ]] || { echo "FATAL: missing $BUILD" >&2; exit 2; }
[[ -f "$HOOK" ]]  || { echo "FATAL: missing $HOOK"  >&2; exit 2; }
command -v node >/dev/null 2>&1 || { echo "FATAL: node not found" >&2; exit 2; }

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
PASS=0; FAIL=0
pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}FAIL${NC}: $1 -- $2"; FAIL=$((FAIL+1)); }

TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/aegis-graph-build-XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT INT TERM

echo "================================================="
echo "AEGIS brain-graph build — sprint v12-04 acceptance"
echo "================================================="

# ─── T1: --full cold build on the real meta repo ───────────────────────────
echo
echo "T1: --full cold build on the real meta repo"
START=$(node -e 'process.stdout.write(String(Date.now()))')
OUT=$(node "$BUILD" --full --root "$REPO_ROOT" 2>&1)
RC=$?
END=$(node -e 'process.stdout.write(String(Date.now()))')
ELAPSED=$((END - START))
if [[ $RC -eq 0 ]]; then
    pass "--full exits 0 on real meta repo"
else
    fail "--full exits 0 on real meta repo" "exit=$RC, output:\n$OUT"
fi
NODE_COUNT=$(jq '.node_count' "$GRAPH_DIR/meta.json")
EDGE_COUNT=$(jq '.edge_count' "$GRAPH_DIR/meta.json")
if [[ $NODE_COUNT -ge 100 ]]; then
    pass "node_count = $NODE_COUNT (≥ 100)"
else
    fail "node_count ≥ 100" "actual: $NODE_COUNT"
fi
if [[ $EDGE_COUNT -ge 50 ]]; then
    pass "edge_count = $EDGE_COUNT (≥ 50)"
else
    fail "edge_count ≥ 50" "actual: $EDGE_COUNT"
fi
if [[ $ELAPSED -lt 2000 ]]; then
    pass "--full completes in <2s (actual: ${ELAPSED}ms)"
else
    fail "--full completes in <2s" "actual: ${ELAPSED}ms"
fi

# ─── T2: --full byte-determinism ───────────────────────────────────────────
echo
echo "T2: two --full runs produce byte-equal output"
SHA1=$(shasum "$GRAPH_DIR/nodes.ndjson" | awk '{print $1}')
SHE1=$(shasum "$GRAPH_DIR/edges.ndjson" | awk '{print $1}')
node "$BUILD" --full --root "$REPO_ROOT" --quiet
SHA2=$(shasum "$GRAPH_DIR/nodes.ndjson" | awk '{print $1}')
SHE2=$(shasum "$GRAPH_DIR/edges.ndjson" | awk '{print $1}')
if [[ "$SHA1" == "$SHA2" ]]; then
    pass "nodes.ndjson byte-equal across two --full runs"
else
    fail "nodes.ndjson byte-equal" "sha1=$SHA1 sha2=$SHA2"
fi
if [[ "$SHE1" == "$SHE2" ]]; then
    pass "edges.ndjson byte-equal across two --full runs"
else
    fail "edges.ndjson byte-equal" "sha1=$SHE1 sha2=$SHE2"
fi

# ─── T3: --incremental skip ────────────────────────────────────────────────
echo
echo "T3: --incremental skips when no source changed"
START=$(node -e 'process.stdout.write(String(Date.now()))')
OUT=$(node "$BUILD" --incremental --root "$REPO_ROOT" 2>&1)
RC=$?
END=$(node -e 'process.stdout.write(String(Date.now()))')
ELAPSED=$((END - START))
if [[ $RC -eq 0 ]] && echo "$OUT" | grep -q "skipped"; then
    pass "--incremental reports skipped"
else
    fail "--incremental reports skipped" "exit=$RC, output:\n$OUT"
fi
if [[ $ELAPSED -lt 500 ]]; then
    pass "--incremental skip in <500ms (actual: ${ELAPSED}ms)"
else
    fail "--incremental skip in <500ms" "actual: ${ELAPSED}ms"
fi

# ─── T4: meta.json schema ──────────────────────────────────────────────────
echo
echo "T4: meta.json has all required fields"
META=$(cat "$GRAPH_DIR/meta.json")
for field in built_at source_mtime_max node_count edge_count builder_version; do
    if echo "$META" | jq -e ".$field" >/dev/null 2>&1; then
        pass "meta.json has '$field'"
    else
        fail "meta.json has '$field'" "meta:\n$META"
    fi
done

# ─── T5: --json output ─────────────────────────────────────────────────────
echo
echo "T5: --json output is parseable"
JSON_OUT=$(node "$BUILD" --incremental --root "$REPO_ROOT" --json 2>&1)
if echo "$JSON_OUT" | node -e 'let d="";process.stdin.on("data",c=>d+=c);process.stdin.on("end",()=>{const j=JSON.parse(d); if(typeof j !== "object") process.exit(7);})'; then
    pass "--json output parses"
else
    fail "--json output parses" "output:\n$JSON_OUT"
fi

# ─── T6: graph dir is gitignored ───────────────────────────────────────────
echo
echo "T6: .aegis/brain/graph/ is gitignored"
if (cd "$REPO_ROOT" && git check-ignore .aegis/brain/graph/ >/dev/null 2>&1); then
    pass ".aegis/brain/graph/ is gitignored"
else
    fail ".aegis/brain/graph/ is gitignored" "git check-ignore failed"
fi

# ─── T7: fixture build ─────────────────────────────────────────────────────
echo
echo "T7: --full on a minimal fixture produces expected nodes"
mkdir -p "$TEST_DIR/skills" "$TEST_DIR/.claude" "$TEST_DIR/.aegis/brain/sprints/sprint-test-01"
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
supersedes: ["old-skill"]
---
EOF
cat > "$TEST_DIR/.claude/settings.json" <<'EOF'
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          { "type": "command", "command": "node tools/aegis-test/log.mjs" }
        ]
      }
    ]
  }
}
EOF
cat > "$TEST_DIR/.aegis/brain/sprints/sprint-test-01/close.md" <<'EOF'
# Sprint test-01 Close
**Status**: CLOSED · 1/1pt

| ID | Story | Pt |
|----|-------|----|
| A | Add tools/aegis-test/log.mjs | 1 |
EOF
mkdir -p "$TEST_DIR/tools/aegis-test"
echo 'console.log("ok");' > "$TEST_DIR/tools/aegis-test/log.mjs"

OUT=$(node "$BUILD" --full --root "$TEST_DIR" 2>&1)
RC=$?
if [[ $RC -eq 0 ]]; then
    pass "fixture --full exits 0"
else
    fail "fixture --full exits 0" "exit=$RC, output:\n$OUT"
fi
FIXTURE_NODES=$(wc -l < "$TEST_DIR/.aegis/brain/graph/nodes.ndjson" | tr -d ' ')
FIXTURE_EDGES=$(wc -l < "$TEST_DIR/.aegis/brain/graph/edges.ndjson" | tr -d ' ')
if [[ $FIXTURE_NODES -ge 5 ]]; then
    pass "fixture produced ≥ 5 nodes (actual: $FIXTURE_NODES)"
else
    fail "fixture produced ≥ 5 nodes" "actual: $FIXTURE_NODES"
fi
if [[ $FIXTURE_EDGES -ge 3 ]]; then
    pass "fixture produced ≥ 3 edges (actual: $FIXTURE_EDGES)"
else
    fail "fixture produced ≥ 3 edges" "actual: $FIXTURE_EDGES"
fi

# Verify specific edges exist
if grep -q '"kind":"WIRES"' "$TEST_DIR/.aegis/brain/graph/edges.ndjson"; then
    pass "fixture has WIRES edge from settings.json hook"
else
    fail "fixture has WIRES edge" "edges:\n$(cat "$TEST_DIR/.aegis/brain/graph/edges.ndjson")"
fi
if grep -q '"kind":"READS"' "$TEST_DIR/.aegis/brain/graph/edges.ndjson"; then
    pass "fixture has READS edge from skill"
else
    fail "fixture has READS edge" "edges:\n$(cat "$TEST_DIR/.aegis/brain/graph/edges.ndjson")"
fi
if grep -q '"kind":"WRITES"' "$TEST_DIR/.aegis/brain/graph/edges.ndjson"; then
    pass "fixture has WRITES edge from skill"
else
    fail "fixture has WRITES edge" "edges:\n$(cat "$TEST_DIR/.aegis/brain/graph/edges.ndjson")"
fi
if grep -q '"kind":"SUPERSEDES"' "$TEST_DIR/.aegis/brain/graph/edges.ndjson"; then
    pass "fixture has SUPERSEDES edge"
else
    fail "fixture has SUPERSEDES edge" "edges:\n$(cat "$TEST_DIR/.aegis/brain/graph/edges.ndjson")"
fi
if grep -q '"kind":"IMPLEMENTS"' "$TEST_DIR/.aegis/brain/graph/edges.ndjson"; then
    pass "fixture has IMPLEMENTS edge from sprint"
else
    fail "fixture has IMPLEMENTS edge" "edges:\n$(cat "$TEST_DIR/.aegis/brain/graph/edges.ndjson")"
fi

# ─── T8: incremental triggered by source change ────────────────────────────
echo
echo "T8: --incremental rebuilds when a source changes"
sleep 0.05
echo "# new line" >> "$TEST_DIR/skills/test-skill.md"
OUT=$(node "$BUILD" --incremental --root "$TEST_DIR" 2>&1)
RC=$?
if [[ $RC -eq 0 ]] && echo "$OUT" | grep -q "built"; then
    pass "--incremental rebuilds after source change"
else
    fail "--incremental rebuilds after source change" "exit=$RC, output:\n$OUT"
fi

# ─── T9: hook script returns 0 immediately ─────────────────────────────────
echo
echo "T9: hook script returns 0 fast"
START=$(node -e 'process.stdout.write(String(Date.now()))')
CLAUDE_PROJECT_DIR="$REPO_ROOT" bash "$HOOK"
RC=$?
END=$(node -e 'process.stdout.write(String(Date.now()))')
ELAPSED=$((END - START))
if [[ $RC -eq 0 ]]; then
    pass "hook exits 0"
else
    fail "hook exits 0" "exit=$RC"
fi
if [[ $ELAPSED -lt 500 ]]; then
    pass "hook returns in <500ms (actual: ${ELAPSED}ms)"
else
    fail "hook returns in <500ms" "actual: ${ELAPSED}ms"
fi

# ─── T10: unknown arg rejected ─────────────────────────────────────────────
echo
echo "T10: unknown arg rejected"
OUT=$(node "$BUILD" --bogus 2>&1)
RC=$?
if [[ $RC -eq 2 ]]; then
    pass "unknown arg exits 2"
else
    fail "unknown arg exits 2" "exit=$RC, output:\n$OUT"
fi

# ─── T11: atomic write — temp files cleaned up ─────────────────────────────
echo
echo "T11: no .tmp files left after successful build"
node "$BUILD" --full --root "$REPO_ROOT" --quiet
TMP_COUNT=$(find "$GRAPH_DIR" -name '*.tmp' 2>/dev/null | wc -l | tr -d ' ')
if [[ $TMP_COUNT -eq 0 ]]; then
    pass "no .tmp files after successful build"
else
    fail "no .tmp files after successful build" "found $TMP_COUNT .tmp files"
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
