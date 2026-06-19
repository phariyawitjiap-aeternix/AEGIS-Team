#!/usr/bin/env bash
# aegis-brain-graph-root-anchor-test.sh — regression test for the cwd-drift bug
#
# Driver: 2026-06-19 — a graph build ran while cwd had drifted to
# `.aegis/brain/learnings/`, producing a stray EMPTY graph at
# `.aegis/brain/learnings/.aegis/brain/graph/` (node_count: 0) instead of
# anchoring to the project root. Root cause (3 layers):
#   1. hook.sh invoked build.mjs without --root
#   2. build.mjs defaulted root to process.cwd()
#   3. build() wrote an empty graph unconditionally (clobber risk)
#
# This test asserts build.mjs:
#   T1 — refuses to write a 0-node graph (guard), preserving any existing graph
#   T2 — anchors to $CLAUDE_PROJECT_DIR when run from a subdir without --root
#   T3 — anchors to the git toplevel when CLAUDE_PROJECT_DIR is unset (git only)
#
# Spec: P-012 (anchor hook commands to $CLAUDE_PROJECT_DIR) + spawned-task
# 2026-06-19.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD="${REPO_ROOT}/tools/aegis-brain-graph/build.mjs"

[[ -f "$BUILD" ]] || { echo "FATAL: missing $BUILD" >&2; exit 2; }
command -v node >/dev/null 2>&1 || { echo "FATAL: node not found" >&2; exit 2; }

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
PASS=0; FAIL=0
pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}FAIL${NC}: $1"; FAIL=$((FAIL+1)); }

# mktemp -d portable across macOS/Linux
TMP="$(mktemp -d 2>/dev/null || mktemp -d -t aegis-graph-anchor)"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

# ─── Build a minimal AEGIS fixture that yields >0 nodes ─────────────────────
make_fixture() {
  local root="$1"
  mkdir -p "$root/skills" "$root/tools" "$root/.aegis/brain/learnings"
  cat > "$root/skills/sample.md" <<'EOF'
---
name: sample-skill
---
# Sample Skill
EOF
  cat > "$root/tools/aegis-sample.sh" <<'EOF'
#!/usr/bin/env bash
echo sample
EOF
}

node_count_of() {
  # echo the node_count from a meta.json, or "MISSING" if absent
  local meta="$1"
  [[ -f "$meta" ]] || { echo "MISSING"; return; }
  node -e "process.stdout.write(String(JSON.parse(require('fs').readFileSync('$meta','utf8')).node_count))" 2>/dev/null || echo "PARSE_ERR"
}

# ─── T1: empty-graph guard ──────────────────────────────────────────────────
# Running against a root with no sources must NOT write a graph, and must NOT
# clobber a pre-existing one.
T1="$TMP/t1"
mkdir -p "$T1/.aegis/brain/graph"
# Seed a "real" graph that must survive
printf '{"id":"x"}\n'        > "$T1/.aegis/brain/graph/nodes.ndjson"
printf '{"built_at":"seed","node_count":99}\n' > "$T1/.aegis/brain/graph/meta.json.seed"
cp "$T1/.aegis/brain/graph/meta.json.seed" "$T1/.aegis/brain/graph/meta.json"
# No skills/tools at this root → 0 nodes discovered.
GUARD_OUT="$(node "$BUILD" --full --root "$T1" 2>&1)"
SURV="$(node_count_of "$T1/.aegis/brain/graph/meta.json")"
if [[ "$SURV" == "99" ]]; then
  pass "T1 empty-graph guard: existing 99-node graph preserved (not clobbered)"
else
  fail "T1 empty-graph guard: existing graph was overwritten (node_count now '$SURV')"
fi
if echo "$GUARD_OUT" | grep -qiE 'warn|refus|0 node|skip'; then
  pass "T1 guard emits a warning on 0-node discovery"
else
  fail "T1 guard did not warn on 0-node discovery (got: '$GUARD_OUT')"
fi

# ─── T2: anchor to CLAUDE_PROJECT_DIR from a drifted cwd, no --root ─────────
T2="$TMP/t2"
make_fixture "$T2"
SUBDIR="$T2/.aegis/brain/learnings"
( cd "$SUBDIR" && CLAUDE_PROJECT_DIR="$T2" node "$BUILD" --full --quiet ) >/dev/null 2>&1
ROOT_NC="$(node_count_of "$T2/.aegis/brain/graph/meta.json")"
if [[ "$ROOT_NC" =~ ^[0-9]+$ && "$ROOT_NC" -gt 0 ]]; then
  pass "T2 graph anchored to project root (node_count=$ROOT_NC)"
else
  fail "T2 graph NOT written at project root (node_count='$ROOT_NC')"
fi
if [[ -e "$SUBDIR/.aegis" ]]; then
  fail "T2 STRAY graph created under subdir: $SUBDIR/.aegis"
else
  pass "T2 no stray graph under the drifted cwd"
fi

# ─── T3: anchor to git toplevel when CLAUDE_PROJECT_DIR is unset ────────────
if command -v git >/dev/null 2>&1; then
  T3="$TMP/t3"
  make_fixture "$T3"
  ( cd "$T3" && git init -q && git config user.email t@t && git config user.name t ) >/dev/null 2>&1
  SUB3="$T3/.aegis/brain/learnings"
  ( cd "$SUB3" && unset CLAUDE_PROJECT_DIR && node "$BUILD" --full --quiet ) >/dev/null 2>&1
  NC3="$(node_count_of "$T3/.aegis/brain/graph/meta.json")"
  if [[ "$NC3" =~ ^[0-9]+$ && "$NC3" -gt 0 ]]; then
    pass "T3 graph anchored to git toplevel (node_count=$NC3)"
  else
    fail "T3 graph NOT written at git toplevel (node_count='$NC3')"
  fi
  if [[ -e "$SUB3/.aegis" ]]; then
    fail "T3 STRAY graph created under subdir: $SUB3/.aegis"
  else
    pass "T3 no stray graph under the drifted cwd (git-root path)"
  fi
else
  echo "SKIP: T3 (git not available)"
fi

# ─── Tally ──────────────────────────────────────────────────────────────────
echo "----------------------------------------"
echo -e "Passed: ${GREEN}${PASS}${NC}  Failed: ${RED}${FAIL}${NC}"
[[ "$FAIL" -eq 0 ]] || exit 1
exit 0
