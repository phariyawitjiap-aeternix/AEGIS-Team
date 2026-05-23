#!/usr/bin/env bash
# aegis-multi-tenant-test.sh — Sprint v11-09 acceptance + regression test

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
MT="${REPO_ROOT}/tools/aegis-multi-tenant/mt.mjs"

[[ -f "$MT" ]] || { echo "FATAL: missing $MT" >&2; exit 2; }
command -v node >/dev/null 2>&1 || { echo "FATAL: node missing" >&2; exit 2; }

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
PASS=0; FAIL=0
pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}FAIL${NC}: $1 -- $2"; FAIL=$((FAIL+1)); }

# Isolate HOME so the registry doesn't pollute the user's real ~/.aegis-plus/
# Normalize TMPDIR (some macOS setups have a trailing slash, which produces
# `/foo//bar` paths that don't compare equal to node's resolved single-slash form).
_TMP="${TMPDIR:-/tmp}"; _TMP="${_TMP%/}"
TEST_DIR=$(mktemp -d "$_TMP/aegis-multi-tenant-XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT INT TERM
export HOME="$TEST_DIR/fake-home"
mkdir -p "$HOME"

# Build 2 fake AEGIS projects on disk
for name in alpha beta; do
  P="$TEST_DIR/$name"
  mkdir -p "$P/.aegis/brain/activity" "$P/.aegis/brain/issues"
  echo "11.0" > "$P/AEGIS_VERSION"
  # alpha also has a misleading project-level VERSION file (e.g. its app's
  # semver). mt.mjs must NOT use this as the AEGIS version when AEGIS_VERSION
  # is present, and must NOT use it as a fallback when the project lacks
  # install.sh/CLAUDE.md (i.e. is not the meta repo).
  [[ "$name" == "alpha" ]] && echo "1.2.3" > "$P/VERSION"
  TODAY=$(date -u +%Y-%m-%d)
  echo "{\"ts\":\"${TODAY}T10:00:00Z\",\"tool\":\"Edit\",\"target\":\"src/${name}.ts\",\"persona\":\"spider-man\",\"status\":\"ok\"}" \
    > "$P/.aegis/brain/activity/${TODAY}.jsonl"
done
# Add an open issue to alpha
cat > "$TEST_DIR/alpha/.aegis/brain/issues/ALP-1.yaml" <<EOF
id: ALP-1
title: Add forbidden-word check
status: in_progress
assignee: spider-man
EOF
# Add a done issue to beta
cat > "$TEST_DIR/beta/.aegis/brain/issues/BET-1.yaml" <<EOF
id: BET-1
title: Refactor cache layer
status: done
assignee: thor
EOF

echo "============================================"
echo "AEGIS multi-tenant — sprint v11-09 acceptance"
echo "============================================"

# ── Group 1: register ───────────────────────────────────────────────────
echo ""
echo "--- Group 1: register ---"

OUT=$(node "$MT" register --path "$TEST_DIR/alpha" --name alpha --role pilot 2>&1)
if echo "$OUT" | grep -q "registered: alpha"; then
  pass "1.a register first project"
else
  fail "1.a register" "$OUT"
fi

OUT=$(node "$MT" register --path "$TEST_DIR/beta" --name beta --role production 2>&1)
if echo "$OUT" | grep -q "registered: beta"; then
  pass "1.b register second project"
else
  fail "1.b register beta" "$OUT"
fi

# 1.c — duplicate name rejected
RC=0
node "$MT" register --path "$TEST_DIR/alpha" --name alpha 2>/dev/null || RC=$?
if [[ "$RC" == "2" ]]; then
  pass "1.c duplicate name rejected"
else
  fail "1.c dup name" "rc=$RC"
fi

# 1.d — non-existent path rejected
RC=0
node "$MT" register --path "$TEST_DIR/does-not-exist" --name x 2>/dev/null || RC=$?
if [[ "$RC" == "2" ]]; then
  pass "1.d non-existent path rejected"
else
  fail "1.d bad path" "rc=$RC"
fi

# 1.e — non-AEGIS dir rejected
mkdir -p "$TEST_DIR/not-aegis"
RC=0
node "$MT" register --path "$TEST_DIR/not-aegis" --name nope 2>/dev/null || RC=$?
if [[ "$RC" == "2" ]]; then
  pass "1.e non-AEGIS dir rejected"
else
  fail "1.e non-aegis" "rc=$RC"
fi

# 1.f — registry persisted to ~/.aegis-plus/projects.yaml
if [[ -f "$HOME/.aegis-plus/projects.yaml" ]] && grep -q "name: alpha" "$HOME/.aegis-plus/projects.yaml"; then
  pass "1.f registry written under HOME/.aegis-plus/"
else
  fail "1.f persisted" "$(cat "$HOME/.aegis-plus/projects.yaml" 2>&1)"
fi

# ── Group 2: list / where ───────────────────────────────────────────────
echo ""
echo "--- Group 2: list / where ---"

LIST_OUT=$(node "$MT" list)
if echo "$LIST_OUT" | grep -q "alpha" && echo "$LIST_OUT" | grep -q "beta" && echo "$LIST_OUT" | grep -q "pilot" && echo "$LIST_OUT" | grep -q "production"; then
  pass "2.a list shows both projects with roles"
else
  fail "2.a list" "$LIST_OUT"
fi

# 2.b — list --json valid
JSON=$(node "$MT" list --json)
if echo "$JSON" | node -e 'const a=JSON.parse(require("fs").readFileSync(0,"utf8")); if(!Array.isArray(a)||a.length!==2) process.exit(1); console.log("ok")' 2>/dev/null; then
  pass "2.b list --json valid array of 2"
else
  fail "2.b json" "$JSON"
fi

# 2.b.1 — version reported is from AEGIS_VERSION, not the project's VERSION file
ALPHA_V=$(echo "$JSON" | node -e 'const a=JSON.parse(require("fs").readFileSync(0,"utf8")); console.log((a.find(p=>p.name==="alpha")||{}).version||"")')
if [[ "$ALPHA_V" == "11.0" ]]; then
  pass "2.b.1 list reports AEGIS_VERSION (11.0), not project VERSION (1.2.3)"
else
  fail "2.b.1 version source" "got=$ALPHA_V expected=11.0"
fi

# 2.b.3 — meta-tagged version "X.Y (meta)" must not be truncated in text view
META_DIR_FAKE="$TEST_DIR/fake-meta"
mkdir -p "$META_DIR_FAKE/.aegis"
echo "11.0" > "$META_DIR_FAKE/VERSION"
touch "$META_DIR_FAKE/install.sh" "$META_DIR_FAKE/CLAUDE.md"
node "$MT" register --path "$META_DIR_FAKE" --name fakemeta --role meta >/dev/null
TEXT=$(node "$MT" list)
if echo "$TEXT" | grep -qE "fakemeta\s+meta\s+11\.0 \(meta\)\s+yes"; then
  pass "2.b.3 '(meta)' tag not clipped in list text output"
else
  fail "2.b.3 meta tag clipping" "$(echo "$TEXT" | grep fakemeta)"
fi

# 2.b.2 — non-meta project without AEGIS_VERSION must show "?", NOT fall back to a stray VERSION file
GAMMA="$TEST_DIR/gamma"
mkdir -p "$GAMMA/.aegis/brain"
echo "9.9.9" > "$GAMMA/VERSION"
node "$MT" register --path "$GAMMA" --name gamma --role experiment >/dev/null
JSON2=$(node "$MT" list --json)
GAMMA_V=$(echo "$JSON2" | node -e 'const a=JSON.parse(require("fs").readFileSync(0,"utf8")); console.log((a.find(p=>p.name==="gamma")||{}).version||"")')
if [[ "$GAMMA_V" == "?" ]]; then
  pass "2.b.2 non-meta project without AEGIS_VERSION → reports '?' (no misleading fallback)"
else
  fail "2.b.2 fallback isolation" "got=$GAMMA_V expected=?"
fi

# 2.c — where alpha returns the path
WHERE=$(node "$MT" where alpha)
if [[ "$WHERE" == "$TEST_DIR/alpha" ]]; then
  pass "2.c where alpha returns the path"
else
  fail "2.c where" "got=$WHERE expected=$TEST_DIR/alpha"
fi

# 2.d — where on unknown name → exit 2
RC=0
node "$MT" where DOESNOTEXIST >/dev/null 2>&1 || RC=$?
if [[ "$RC" == "2" ]]; then
  pass "2.d where unknown → exit 2"
else
  fail "2.d where unknown" "rc=$RC"
fi

# ── Group 3: cross-project activity ─────────────────────────────────────
echo ""
echo "--- Group 3: activity --all-projects ---"

OUT=$(node "$MT" activity --all-projects --since 1d 2>&1)
if echo "$OUT" | grep -q "alpha" && echo "$OUT" | grep -q "beta"; then
  pass "3.a aggregates events from both projects"
else
  fail "3.a aggregate" "$OUT"
fi

# Each event line carries the project label
if echo "$OUT" | grep -qE "\{alpha\s*\}" && echo "$OUT" | grep -qE "\{beta\s*\}"; then
  pass "3.b event lines tagged with {project} marker"
else
  fail "3.b project tag" "$OUT"
fi

# 3.c — JSON shape
JSON=$(node "$MT" activity --all-projects --since 1d --json)
if echo "$JSON" | node -e 'const a=JSON.parse(require("fs").readFileSync(0,"utf8")); if(!Array.isArray(a)||a.length<2) process.exit(1); if(!a.every(r=>r.project)) process.exit(1); console.log("ok")' 2>/dev/null; then
  pass "3.c --json output array carries 'project' field on every record"
else
  fail "3.c activity json" "$JSON"
fi

# 3.d — without --all-projects → reject (single-project use covered by view.mjs)
RC=0
node "$MT" activity --since 1d >/dev/null 2>&1 || RC=$?
if [[ "$RC" == "2" ]]; then
  pass "3.d activity without --all-projects → exit 2"
else
  fail "3.d single-project rejected" "rc=$RC"
fi

# ── Group 4: cross-project issues ───────────────────────────────────────
echo ""
echo "--- Group 4: issues --all-projects ---"

OUT=$(node "$MT" issues --all-projects)
if echo "$OUT" | grep -q "ALP-1" && echo "$OUT" | grep -q "BET-1"; then
  pass "4.a issues across projects (alpha + beta)"
else
  fail "4.a issues" "$OUT"
fi

# Filter status=in_progress shows ALP-1 only
OUT=$(node "$MT" issues --all-projects --status in_progress)
if echo "$OUT" | grep -q "ALP-1" && ! echo "$OUT" | grep -q "BET-1"; then
  pass "4.b --status in_progress filters to ALP-1 only"
else
  fail "4.b status filter" "$OUT"
fi

# 4.c — JSON shape
JSON=$(node "$MT" issues --all-projects --json)
if echo "$JSON" | node -e 'const a=JSON.parse(require("fs").readFileSync(0,"utf8")); if(!Array.isArray(a)||a.length!==2) process.exit(1); console.log("ok")' 2>/dev/null; then
  pass "4.c --json valid array of 2"
else
  fail "4.c issues json" "$JSON"
fi

# ── Group 5: tolerates missing path ─────────────────────────────────────
echo ""
echo "--- Group 5: missing-path tolerance ---"

# Delete alpha's directory and ensure list flags it without crashing
rm -rf "$TEST_DIR/alpha"
LIST_OUT=$(node "$MT" list 2>&1)
if echo "$LIST_OUT" | grep -q "alpha" && echo "$LIST_OUT" | grep -q "no"; then
  pass "5.a list flags deleted project as EXISTS=no"
else
  fail "5.a missing dir" "$LIST_OUT"
fi

# 5.b — activity skips deleted project, still works on beta
OUT=$(node "$MT" activity --all-projects --since 1d 2>&1)
if echo "$OUT" | grep -q "beta" && ! echo "$OUT" | grep -q "alpha"; then
  pass "5.b activity skips deleted project, still aggregates remainder"
else
  fail "5.b skip deleted" "$OUT"
fi

# ── Group 6: v15-25 removal of cwd / run (use native instead) ────────────
echo ""
echo "--- Group 6: cwd / run removed in v15-25 → exit 2 with migration hint ---"

# 6.a — `mt cwd` removed → exit 2, message mentions `mt where`
RC=0
OUT=$(node "$MT" cwd beta 2>&1) || RC=$?
if [[ "$RC" == "2" ]] && echo "$OUT" | grep -q "removed in v15-25" && echo "$OUT" | grep -q "mt where"; then
  pass "6.a cwd removed → exit 2 with mt where migration hint"
else
  fail "6.a cwd removal" "rc=$RC out=$OUT"
fi

# 6.b — `mt run` removed → exit 2, message mentions `mt where`
RC=0
OUT=$(node "$MT" run beta --dry-run -- agents list 2>&1) || RC=$?
if [[ "$RC" == "2" ]] && echo "$OUT" | grep -q "removed in v15-25" && echo "$OUT" | grep -q "mt where"; then
  pass "6.b run removed → exit 2 with mt where migration hint"
else
  fail "6.b run removal" "rc=$RC out=$OUT"
fi

echo ""
echo "============================================"
echo "RESULTS: ${PASS} passed, ${FAIL} failed"
echo "============================================"
[[ $FAIL -eq 0 ]] && { echo -e "${GREEN}ALL PASSED${NC}"; exit 0; } || { echo -e "${RED}FAILURES${NC}"; exit 1; }
