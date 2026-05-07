#!/usr/bin/env bash
# aegis-pattern-mine-test.sh — Sprint v10-07 acceptance + regression test
#
# Verifies tools/aegis-pattern-mine/{mine,propose}.mjs:
#   - mine on crafted fixture produces ≥1 cluster meeting thresholds
#   - mine output is byte-equal across two runs (determinism)
#   - mine respects --min-occurrences and --min-sprints
#   - mine excludes test-fixture questions by default; --include-test-fixtures restores
#   - propose writes top-N candidates to instincts/_proposed/<id>.yaml
#   - propose is idempotent: re-running on same report = "unchanged"
#   - propose filters out clusters already covered by promoted instincts
#   - --json output parses
#   - missing report exits 1 with helpful error
#   - unknown args exit 2

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
MINE="${REPO_ROOT}/tools/aegis-pattern-mine/mine.mjs"
PROPOSE="${REPO_ROOT}/tools/aegis-pattern-mine/propose.mjs"
RULES_SRC="${REPO_ROOT}/tools/aegis-pattern-mine/normalizer-rules.yaml"

[[ -f "$MINE" ]] || { echo "FATAL: missing $MINE" >&2; exit 2; }
[[ -f "$PROPOSE" ]] || { echo "FATAL: missing $PROPOSE" >&2; exit 2; }
command -v node >/dev/null 2>&1 || { echo "FATAL: node not found" >&2; exit 2; }

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
PASS=0; FAIL=0
pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}FAIL${NC}: $1 -- $2"; FAIL=$((FAIL+1)); }

TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/aegis-pattern-mine-XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT INT TERM

echo "================================================="
echo "AEGIS pattern-mine — sprint v10-07 acceptance"
echo "================================================="

# ─── Build a crafted fixture ───────────────────────────────────────────────
mkdir -p "$TEST_DIR/.aegis/brain/logs" \
         "$TEST_DIR/.aegis/brain/state" \
         "$TEST_DIR/.aegis/brain/instincts" \
         "$TEST_DIR/tools/aegis-pattern-mine"
cp "$RULES_SRC" "$TEST_DIR/tools/aegis-pattern-mine/normalizer-rules.yaml"

# Crafted decision-audit.log — chosen so the normalizer cleanly clusters:
#   K1: "ship N-pt sprint as one or split?" (4 occurrences, 4 sprints) — normalizer collapses Npt → <n>pt
#   K2: "open sprint v<x>-<y> next?"        (3 occurrences, 3 sprints) — normalizer collapses sprint IDs → <sprint>
#   K3: "happy path?"                        (1 occurrence)             — below threshold (control)
#   K4 (test fixture): "tc test judgment 1"  (3 occurrences, 1 sprint=unknown) — excluded by default
cat > "$TEST_DIR/.aegis/brain/logs/decision-audit.log" <<'EOF'
{"ts":"2026-04-01T00:00:00Z","decision_id":"D-001","question":"Ship 8pt sprint as one or split?","source":"judgment","source_id":"sprint-v9-04","confidence":0.9,"answer":"ship as one — split adds rebase pain","reasoning":"r"}
{"ts":"2026-04-15T00:00:00Z","decision_id":"D-002","question":"Ship 13pt sprint as one or split?","source":"judgment","source_id":"sprint-v10-01","confidence":0.85,"answer":"ship as one — split adds rebase pain","reasoning":"r"}
{"ts":"2026-04-20T00:00:00Z","decision_id":"D-003","question":"Ship 5pt sprint as one or split?","source":"judgment","source_id":"sprint-v10-06","confidence":0.95,"answer":"ship as one — split adds rebase pain","reasoning":"r"}
{"ts":"2026-04-25T00:00:00Z","decision_id":"D-004","question":"Ship 32pt sprint as one or split?","source":"judgment","source_id":"sprint-v11-08","confidence":0.92,"answer":"split — too big to review","reasoning":"r"}
{"ts":"2026-04-05T00:00:00Z","decision_id":"D-010","question":"Open sprint v9-02 next?","source":"judgment","source_id":"sprint-v9-02","confidence":0.7,"answer":"yes","reasoning":"r"}
{"ts":"2026-04-12T00:00:00Z","decision_id":"D-011","question":"Open sprint v9-04 next?","source":"judgment","source_id":"sprint-v9-04","confidence":0.8,"answer":"yes","reasoning":"r"}
{"ts":"2026-05-01T00:00:00Z","decision_id":"D-012","question":"Open sprint v10-09 next?","source":"judgment","source_id":"sprint-v10-09","confidence":0.75,"answer":"yes","reasoning":"r"}
{"ts":"2026-05-02T00:00:00Z","decision_id":"D-020","question":"Happy path?","source":"judgment","source_id":"sprint-v10-06","confidence":1.0,"answer":"works","reasoning":"r"}
{"ts":"2026-05-03T00:00:00Z","decision_id":"D-031","question":"TC test judgment 1","source":"judgment","source_id":"test","confidence":0.5,"answer":"x","reasoning":"r"}
{"ts":"2026-05-03T00:00:00Z","decision_id":"D-032","question":"TC test judgment 1","source":"judgment","source_id":"test","confidence":0.5,"answer":"x","reasoning":"r"}
{"ts":"2026-05-03T00:00:00Z","decision_id":"D-033","question":"TC test judgment 1","source":"judgment","source_id":"test","confidence":0.5,"answer":"x","reasoning":"r"}
{"ts":"2026-04-10T00:00:00Z","decision_id":"D-100","question":"What kind of cake?","source":"adr:sprint-v9-02","confidence":0.7,"answer":"chocolate","reasoning":"r"}
EOF

# ─── T1: mine on fixture produces expected clusters ────────────────────────
echo
echo "T1: mine on fixture produces expected clusters"
OUT=$(node "$MINE" --root "$TEST_DIR" 2>&1)
RC=$?
if [[ $RC -eq 0 ]]; then
    pass "mine exits 0"
else
    fail "mine exits 0" "exit=$RC, output:\n$OUT"
fi
COUNT=$(jq '.cluster_count' "$TEST_DIR/.aegis/brain/state/pattern-mine-report.json")
if [[ $COUNT -eq 2 ]]; then
    pass "mine produces 2 clusters (K1 ship-sprint + K2 allow-list)"
else
    fail "mine produces 2 clusters" "got $COUNT — report: $(jq '.clusters[] | .normalized_question' "$TEST_DIR/.aegis/brain/state/pattern-mine-report.json")"
fi
TOP_OCC=$(jq '.clusters[0].occurrences' "$TEST_DIR/.aegis/brain/state/pattern-mine-report.json")
if [[ $TOP_OCC -eq 4 ]]; then
    pass "top cluster has 4 occurrences (K1)"
else
    fail "top cluster has 4 occurrences" "got $TOP_OCC"
fi
TOP_SPRINTS=$(jq '.clusters[0].sprints_seen | length' "$TEST_DIR/.aegis/brain/state/pattern-mine-report.json")
if [[ $TOP_SPRINTS -ge 3 ]]; then
    pass "top cluster has ≥3 sprints"
else
    fail "top cluster has ≥3 sprints" "got $TOP_SPRINTS"
fi

# ─── T2: byte-deterministic output ─────────────────────────────────────────
echo
echo "T2: two consecutive mine runs produce byte-equal output"
SHA1=$(jq -S '. | del(.generated_at_iso)' "$TEST_DIR/.aegis/brain/state/pattern-mine-report.json" | shasum | awk '{print $1}')
node "$MINE" --root "$TEST_DIR" --quiet
SHA2=$(jq -S '. | del(.generated_at_iso)' "$TEST_DIR/.aegis/brain/state/pattern-mine-report.json" | shasum | awk '{print $1}')
if [[ "$SHA1" == "$SHA2" ]]; then
    pass "report content (excluding timestamp) is byte-equal"
else
    fail "report content byte-equal" "sha1=$SHA1 sha2=$SHA2"
fi

# ─── T3: --include-test-fixtures restores test entries ─────────────────────
echo
echo "T3: --include-test-fixtures restores TC test cluster"
OUT=$(node "$MINE" --root "$TEST_DIR" --include-test-fixtures --min-sprints 1 --quiet --json 2>&1)
COUNT_INC=$(echo "$OUT" | jq '.cluster_count')
if [[ $COUNT_INC -ge 3 ]]; then
    pass "including test fixtures bumps cluster count (got $COUNT_INC ≥ 3)"
else
    fail "including test fixtures bumps cluster count" "got $COUNT_INC"
fi

# Reset to default-filtered report
node "$MINE" --root "$TEST_DIR" --quiet

# ─── T4: --min-occurrences threshold respected ─────────────────────────────
echo
echo "T4: raising --min-occurrences excludes K2 (3) but keeps K1 (4)"
OUT=$(node "$MINE" --root "$TEST_DIR" --min-occurrences 4 --json --quiet 2>&1)
COUNT_HI=$(echo "$OUT" | jq '.cluster_count')
if [[ $COUNT_HI -eq 1 ]]; then
    pass "--min-occurrences 4 leaves only K1"
else
    fail "--min-occurrences 4 leaves only K1" "got $COUNT_HI clusters"
fi
node "$MINE" --root "$TEST_DIR" --quiet  # reset

# ─── T5: --json output parses ──────────────────────────────────────────────
echo
echo "T5: --json output is parseable"
JSON_OUT=$(node "$MINE" --root "$TEST_DIR" --json 2>&1)
if echo "$JSON_OUT" | node -e 'let d="";process.stdin.on("data",c=>d+=c);process.stdin.on("end",()=>{const j=JSON.parse(d); if(!j.ok || typeof j.cluster_count !== "number") process.exit(7);})'; then
    pass "--json output parses with expected shape"
else
    fail "--json output parses" "output:\n$JSON_OUT"
fi

# ─── T6: propose writes top-N to _proposed/ ────────────────────────────────
echo
echo "T6: propose writes top-3 to _proposed/"
OUT=$(node "$PROPOSE" --root "$TEST_DIR" --top-n 3 2>&1)
RC=$?
if [[ $RC -eq 0 ]]; then
    pass "propose exits 0"
else
    fail "propose exits 0" "exit=$RC"
fi
PROPOSED_COUNT=$(ls "$TEST_DIR/.aegis/brain/instincts/_proposed/" 2>/dev/null | wc -l | tr -d ' ')
# Should write 2 (K1 + K2; K3-K5 below threshold)
if [[ $PROPOSED_COUNT -eq 2 ]]; then
    pass "propose wrote 2 candidates (matches cluster_count)"
else
    fail "propose wrote 2 candidates" "got $PROPOSED_COUNT — files: $(ls "$TEST_DIR/.aegis/brain/instincts/_proposed/")"
fi

# ─── T7: propose is idempotent ─────────────────────────────────────────────
echo
echo "T7: propose is idempotent on identical report"
SHA_BEFORE=$(find "$TEST_DIR/.aegis/brain/instincts/_proposed/" -name "*.yaml" -exec shasum {} + | sort | shasum | awk '{print $1}')
OUT2=$(node "$PROPOSE" --root "$TEST_DIR" --top-n 3 2>&1)
SHA_AFTER=$(find "$TEST_DIR/.aegis/brain/instincts/_proposed/" -name "*.yaml" -exec shasum {} + | sort | shasum | awk '{print $1}')
if [[ "$SHA_BEFORE" == "$SHA_AFTER" ]]; then
    pass "second propose run leaves files unchanged (idempotent)"
else
    fail "propose idempotency" "before=$SHA_BEFORE after=$SHA_AFTER"
fi
if echo "$OUT2" | grep -q "0 written"; then
    pass "propose reports 0 new writes on second run"
else
    fail "propose reports 0 new writes" "output:\n$OUT2"
fi

# ─── T8: propose filters out promoted instincts ────────────────────────────
echo
echo "T8: propose skips clusters covered by promoted instincts"
# Pick the K1 normalized question, plant a promoted instinct that matches it
TOP_NORM=$(jq -r '.clusters[0].normalized_question' "$TEST_DIR/.aegis/brain/state/pattern-mine-report.json")
cat > "$TEST_DIR/.aegis/brain/instincts/already-promoted.yaml" <<EOF
status: promoted
name: ship-sprint-as-one
trigger_pattern: "${TOP_NORM}"
recommendation: "ship as one — split adds rebase pain"
confidence: 0.95
EOF

# Wipe _proposed/ and re-run propose
rm -rf "$TEST_DIR/.aegis/brain/instincts/_proposed"
mkdir -p "$TEST_DIR/.aegis/brain/instincts/_proposed"
OUT=$(node "$PROPOSE" --root "$TEST_DIR" --top-n 3 2>&1)
PROPOSED_AFTER=$(ls "$TEST_DIR/.aegis/brain/instincts/_proposed/" 2>/dev/null | wc -l | tr -d ' ')
# Should write only 1 now (K2; K1 is covered by promoted)
if [[ $PROPOSED_AFTER -eq 1 ]]; then
    pass "propose skipped K1 (covered by already-promoted), wrote only K2"
else
    fail "propose skipped K1" "got $PROPOSED_AFTER candidates — output:\n$OUT"
fi
if echo "$OUT" | grep -q "1 skipped (already promoted)"; then
    pass "propose reports skip count"
else
    fail "propose reports skip count" "output:\n$OUT"
fi

# ─── T9: missing report → exit 1 ───────────────────────────────────────────
echo
echo "T9: propose with no report exits 1"
EMPTY_DIR=$(mktemp -d)
trap 'rm -rf "$EMPTY_DIR" "$TEST_DIR"' EXIT INT TERM
OUT=$(node "$PROPOSE" --root "$EMPTY_DIR" 2>&1)
RC=$?
if [[ $RC -eq 1 ]]; then
    pass "missing report exits 1"
else
    fail "missing report exits 1" "exit=$RC, output:\n$OUT"
fi
if echo "$OUT" | grep -qE "report not found|run mine"; then
    pass "missing report shows actionable error"
else
    fail "missing report shows actionable error" "output:\n$OUT"
fi

# ─── T10: unknown args exit 2 ──────────────────────────────────────────────
echo
echo "T10: unknown arg rejected"
OUT=$(node "$MINE" --bogus 2>&1)
RC=$?
if [[ $RC -eq 2 ]]; then
    pass "mine unknown arg exits 2"
else
    fail "mine unknown arg exits 2" "exit=$RC"
fi
OUT=$(node "$PROPOSE" --bogus 2>&1)
RC=$?
if [[ $RC -eq 2 ]]; then
    pass "propose unknown arg exits 2"
else
    fail "propose unknown arg exits 2" "exit=$RC"
fi

# ─── T11: live tree mine succeeds (smoke test on real data) ────────────────
echo
echo "T11: live tree mine succeeds (real meta — accept any non-error)"
OUT=$(node "$MINE" --root "$REPO_ROOT" --quiet --json 2>&1)
RC=$?
if [[ $RC -eq 0 ]]; then
    pass "live mine on real meta exits 0"
else
    fail "live mine on real meta exits 0" "exit=$RC, output:\n$OUT"
fi
LIVE_AUDIT=$(echo "$OUT" | jq '.audit_lines_total')
if [[ $LIVE_AUDIT -gt 0 ]]; then
    pass "live mine reads decision-audit.log ($LIVE_AUDIT lines)"
elif [[ "${CI:-}" = "true" ]]; then
    # CI fresh checkout has no accumulated decision-audit history. Mine reads
    # the (empty) log successfully — that's still "reads decision-audit.log",
    # just zero entries to mine. Pass with note.
    # (sprint-v13-01-phase-b-chunk3 — flip from CI-fail to advisory.)
    pass "live mine reads decision-audit.log (0 lines — CI fresh checkout)"
else
    fail "live mine reads decision-audit.log" "audit_lines=$LIVE_AUDIT"
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
