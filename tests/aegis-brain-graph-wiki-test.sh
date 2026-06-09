#!/usr/bin/env bash
# aegis-brain-graph-wiki-test.sh — Sprint v12-06 acceptance + regression test
#
# Verifies wiki.mjs + staleness.mjs:
#   - wiki produces ≥ 60 files on real meta (39 skills + ~25 sprints + index)
#   - second wiki run is byte-equal-skip (0 written)
#   - --check exit 1 on stale fixture, exit 0 on fresh
#   - PROJECT_INDEX.md has expected sections
#   - per-skill page has WIRES + IMPLEMENTS sections
#   - staleness silent on fresh graph
#   - staleness fires when graph predates a source change
#   - staleness always exits 0 (fail-OPEN)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
WIKI="${REPO_ROOT}/tools/aegis-brain-graph/wiki.mjs"
STALE="${REPO_ROOT}/tools/aegis-brain-graph/staleness.mjs"
BUILD="${REPO_ROOT}/tools/aegis-brain-graph/build.mjs"
INDEX="${REPO_ROOT}/PROJECT_INDEX.md"
WIKI_DIR="${REPO_ROOT}/_aegis-output/wiki"

[[ -f "$WIKI"  ]] || { echo "FATAL: missing $WIKI"  >&2; exit 2; }
[[ -f "$STALE" ]] || { echo "FATAL: missing $STALE" >&2; exit 2; }
command -v node >/dev/null 2>&1 || { echo "FATAL: node not found" >&2; exit 2; }

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
PASS=0; FAIL=0
pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}FAIL${NC}: $1 -- $2"; FAIL=$((FAIL+1)); }

TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/aegis-graph-wiki-XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT INT TERM

echo "================================================="
echo "AEGIS brain-graph wiki + staleness — sprint v12-06"
echo "================================================="

# Make sure live tree graph is fresh
node "$BUILD" --full --root "$REPO_ROOT" --quiet

# ─── T1: wiki on real meta ─────────────────────────────────────────────────
echo
echo "T1: wiki on real meta produces ≥ 60 files"
OUT=$(node "$WIKI" --root "$REPO_ROOT" 2>&1)
RC=$?
if [[ $RC -eq 0 ]]; then
    pass "wiki exits 0"
else
    fail "wiki exits 0" "exit=$RC, output:\n$OUT"
fi
WIKI_COUNT=$(ls "$WIKI_DIR" 2>/dev/null | wc -l | tr -d ' ')
if [[ $WIKI_COUNT -ge 60 ]]; then
    pass "wiki produced ≥ 60 files (actual: $WIKI_COUNT)"
else
    fail "wiki produced ≥ 60 files" "actual: $WIKI_COUNT"
fi
[[ -f "$INDEX" ]] && pass "PROJECT_INDEX.md exists" || fail "PROJECT_INDEX.md exists" ""

# ─── T2: PROJECT_INDEX.md has expected sections ────────────────────────────
echo
echo "T2: PROJECT_INDEX.md has all expected sections"
for section in "## Skills" "## Sprints" "## Tools" "## Hooks" "## Governance Docs"; do
    if grep -q "$section" "$INDEX"; then
        pass "PROJECT_INDEX has section '$section'"
    else
        fail "PROJECT_INDEX has section '$section'" ""
    fi
done

# ─── T3: per-skill page has expected sections ──────────────────────────────
echo
echo "T3: skill-aegis-live-tail.md has expected sections"
SKILL_PAGE="$WIKI_DIR/skill-aegis-live-tail.md"
[[ -f "$SKILL_PAGE" ]] && pass "skill page exists" || fail "skill page exists" ""
for section in "## Triggers" "## Wires" "## Tests"; do
    if grep -q "$section" "$SKILL_PAGE"; then
        pass "skill page has section '$section'"
    else
        fail "skill page has section '$section'" "page:\n$(cat "$SKILL_PAGE")"
    fi
done

# ─── T4: wiki determinism (second run is 0 written) ────────────────────────
echo
echo "T4: wiki is byte-equal-skip on second run"
OUT=$(node "$WIKI" --root "$REPO_ROOT" 2>&1)
if echo "$OUT" | grep -q "0 files written"; then
    pass "second wiki run writes 0 files"
else
    fail "second wiki run writes 0 files" "output:\n$OUT"
fi

# ─── T5: --check exits 0 on fresh wiki ─────────────────────────────────────
echo
echo "T5: --check exits 0 when wiki is fresh"
OUT=$(node "$WIKI" --root "$REPO_ROOT" --check 2>&1)
RC=$?
if [[ $RC -eq 0 ]]; then
    pass "--check on fresh wiki exits 0"
else
    fail "--check on fresh wiki exits 0" "exit=$RC, output:\n$OUT"
fi

# ─── T6: --check exits 1 on stale wiki ─────────────────────────────────────
echo
echo "T6: --check exits 1 after manual staleness"
echo "TAMPERED" > "$WIKI_DIR/skill-aegis-live-tail.md"
OUT=$(node "$WIKI" --root "$REPO_ROOT" --check 2>&1)
RC=$?
if [[ $RC -eq 1 ]]; then
    pass "--check on tampered wiki exits 1"
else
    fail "--check on tampered wiki exits 1" "exit=$RC, output:\n$OUT"
fi
# Restore by re-running write mode
node "$WIKI" --root "$REPO_ROOT" --quiet

# ─── T7: --json output is parseable ────────────────────────────────────────
echo
echo "T7: --json output parses"
JSON_OUT=$(node "$WIKI" --root "$REPO_ROOT" --json 2>&1)
if echo "$JSON_OUT" | node -e 'let d="";process.stdin.on("data",c=>d+=c);process.stdin.on("end",()=>{const j=JSON.parse(d); if(typeof j.unchanged !== "number") process.exit(7);})'; then
    pass "--json output parses"
else
    fail "--json output parses" "output:\n$JSON_OUT"
fi

# ─── T8: staleness silent on fresh graph ───────────────────────────────────
echo
echo "T8: staleness silent on fresh graph"
OUT=$(node "$STALE" --root "$REPO_ROOT" 2>&1)
RC=$?
if [[ $RC -eq 0 ]]; then
    pass "staleness exits 0 on fresh graph"
else
    fail "staleness exits 0 on fresh graph" "exit=$RC"
fi
if [[ -z "$OUT" ]]; then
    pass "staleness silent on fresh graph (no output)"
else
    fail "staleness silent on fresh graph" "got: $OUT"
fi

# ─── T9: staleness fires when graph is older than HEAD by ≥ threshold ──────
echo
echo "T9: staleness fires when graph predates HEAD"
# Build a fixture with: a graph dated 24 hours in the past, source files newer than meta.source_mtime_max
mkdir -p "$TEST_DIR/.aegis/brain/graph"
mkdir -p "$TEST_DIR/.git/refs/heads"
mkdir -p "$TEST_DIR/skills"
echo "test" > "$TEST_DIR/skills/x.md"
# Initialize a real git repo with one commit so git log works
(cd "$TEST_DIR" && git init -q && git config user.email "t@t" && git config user.name "t" && git add -A && git commit -q -m "init")
# Write a fake meta.json saying graph was built 24 hours ago
PAST_ISO=$(node -e "process.stdout.write(new Date(Date.now() - 24*3600*1000).toISOString())")
PAST_MS=$(node -e "process.stdout.write(String(Date.now() - 24*3600*1000))")
cat > "$TEST_DIR/.aegis/brain/graph/meta.json" <<EOF
{
  "built_at": "$PAST_ISO",
  "source_mtime_max": $PAST_MS,
  "node_count": 1,
  "edge_count": 0,
  "builder_version": "1.0.0"
}
EOF
# Touch a skill file to make it newer than source_mtime_max
touch "$TEST_DIR/skills/x.md"
OUT=$(node "$STALE" --root "$TEST_DIR" 2>&1)
RC=$?
if [[ $RC -eq 0 ]] && echo "$OUT" | grep -q "behind HEAD"; then
    pass "staleness fires when graph is stale (output: $OUT)"
else
    fail "staleness fires when graph is stale" "exit=$RC, output:\n$OUT"
fi

# ─── T10: staleness --json shape ───────────────────────────────────────────
echo
echo "T10: staleness --json reports stale=true"
JSON_OUT=$(node "$STALE" --root "$TEST_DIR" --json 2>&1)
if echo "$JSON_OUT" | jq -e '.stale == true' >/dev/null 2>&1; then
    pass "staleness --json reports stale=true on stale fixture"
else
    fail "staleness --json reports stale=true on stale fixture" "output:\n$JSON_OUT"
fi

# ─── T11: staleness exits 0 even on missing graph (fail-OPEN) ──────────────
echo
echo "T11: staleness fail-OPEN on missing graph"
EMPTY_DIR=$(mktemp -d)
trap 'rm -rf "$EMPTY_DIR" "$TEST_DIR"' EXIT INT TERM
OUT=$(node "$STALE" --root "$EMPTY_DIR" 2>&1)
RC=$?
if [[ $RC -eq 0 ]]; then
    pass "staleness exits 0 on missing graph (fail-OPEN)"
else
    fail "staleness exits 0 on missing graph" "exit=$RC, output:\n$OUT"
fi

# ─── T12: live tree wiki passes lint (markdown well-formed) ────────────────
echo
# Count derived from the filesystem — never hardcode (was "39"/"≥36" while the
# tree held 38, a silent drift waiting to break).
EXPECTED_SKILLS=$(ls -1 "${REPO_ROOT}"/skills/*.md 2>/dev/null | wc -l | tr -d ' ')
echo "T12: PROJECT_INDEX.md mentions all ${EXPECTED_SKILLS} skills"
SKILL_LINKS=$(grep -cE "_aegis-output/wiki/skill-" "$INDEX")
if [[ $SKILL_LINKS -ge $EXPECTED_SKILLS ]]; then
    pass "PROJECT_INDEX links to ≥ ${EXPECTED_SKILLS} skill pages (actual: $SKILL_LINKS)"
else
    fail "PROJECT_INDEX links to ≥ ${EXPECTED_SKILLS} skill pages" "actual: $SKILL_LINKS"
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
