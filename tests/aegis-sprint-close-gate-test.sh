#!/usr/bin/env bash
# aegis-sprint-close-gate-test.sh — sprint v15-20 Story B regression.
#
# Tests tools/aegis-sprint-close-gate.sh:
#   T1: 100%-coverage project → gate silent, exit 0
#   T2: Unity-style 60%-coverage project, 0 playtest files → warns, lists missing
#   T3: GUI project with playtest file pass=true → marked verified
#   T4: GUI project with playtest file pass=false → marked failing
#   T5: GUI project with playtest missing verified_by → marked unclear
#   T6: report mode emits parseable summary
#   T7: soft gate — always exits 0

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TOOL="$REPO_ROOT/tools/aegis-sprint-close-gate.sh"

[[ -f "$TOOL" ]] || { echo "FATAL: missing $TOOL" >&2; exit 2; }

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
PASS=0; FAIL=0
pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}FAIL${NC}: $1 -- $2"; FAIL=$((FAIL+1)); }

TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/aegis-gate-XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT INT TERM

# Build a synthetic project with sprints/current/kanban.md
make_project() {
    local d="$TEST_DIR/$1"
    local coverage_pct="$2"
    mkdir -p "$d/.aegis/brain/sprints/current" "$d/.aegis/brain/state" "$d/_aegis-output/playtests"
    cat > "$d/.aegis/brain/state/coverage.json" <<EOF
{
  "schema": "aegis-coverage-v1",
  "coverage_pct": $coverage_pct,
  "coverage": $(awk "BEGIN { printf \"%.2f\", $coverage_pct / 100 }"),
  "ack": false,
  "gaps": []
}
EOF
    cat > "$d/.aegis/brain/sprints/current/kanban.md" <<'EOF'
# Sprint Kanban

## DONE

| Story | Title |
|---|---|
| S03-02 | Enemy AI |
| S04-01 | Parallax layer 1 |

## BLOCKED

_none_
EOF
    echo "$d"
}

# ── T1: 100%-coverage → silent ───────────────────────────────────────────
echo ""
echo "--- T1: 100%-coverage project → gate skipped ---"
d=$(make_project "p1-web" "100")
OUT=$(bash "$TOOL" check "$d" 2>&1)
rc=$?
if [[ "$rc" == "0" ]] && echo "$OUT" | grep -q "skipped"; then
    pass "T1: 100% coverage → gate skipped"
else
    fail "T1: 100% coverage" "rc=$rc out=$OUT"
fi

# ── T2: Unity 60%, 0 playtests → warn ────────────────────────────────────
echo ""
echo "--- T2: 60% coverage + 0 playtests → warn + missing list ---"
d=$(make_project "p2-unity" "60")
OUT=$(bash "$TOOL" check "$d" 2>&1)
if echo "$OUT" | grep -q "missing playtest file:.*2" && echo "$OUT" | grep -q "S03-02" && echo "$OUT" | grep -q "S04-01"; then
    pass "T2: 60% coverage flags 2 missing playtests"
else
    fail "T2: 60% missing flag" "out=$OUT"
fi

# ── T3: playtest pass=true → verified ────────────────────────────────────
echo ""
echo "--- T3: playtest pass=true → counted as verified ---"
d=$(make_project "p3-unity" "60")
cat > "$d/_aegis-output/playtests/S03-02.md" <<'EOF'
verified_by: jiap
date: 2026-05-21
pass: true
notes: Played in Unity Editor, enemy AI works.
EOF
OUT=$(bash "$TOOL" check "$d" 2>&1)
if echo "$OUT" | grep -q "verified by human playtest:.*1"; then
    pass "T3: pass=true counted as verified"
else
    fail "T3: verified count" "out=$OUT"
fi

# ── T4: pass=false → failing ─────────────────────────────────────────────
echo ""
echo "--- T4: playtest pass=false → counted as failing ---"
d=$(make_project "p4-unity" "60")
cat > "$d/_aegis-output/playtests/S03-02.md" <<'EOF'
verified_by: jiap
date: 2026-05-21
pass: false
notes: AI doesn't trigger.
EOF
OUT=$(bash "$TOOL" check "$d" 2>&1)
if echo "$OUT" | grep -q "FAIL:.*1"; then
    pass "T4: pass=false counted as failing"
else
    fail "T4: failing count" "out=$OUT"
fi

# ── T5: missing verified_by → unclear ────────────────────────────────────
echo ""
echo "--- T5: missing verified_by → counted as unclear ---"
d=$(make_project "p5-unity" "60")
cat > "$d/_aegis-output/playtests/S03-02.md" <<'EOF'
date: 2026-05-21
pass: true
notes: ...
EOF
OUT=$(bash "$TOOL" check "$d" 2>&1)
if echo "$OUT" | grep -q "unclear.*1"; then
    pass "T5: missing verifier counted as unclear"
else
    fail "T5: unclear count" "out=$OUT"
fi

# ── T6: report mode parseable ────────────────────────────────────────────
echo ""
echo "--- T6: report mode emits parseable summary ---"
d=$(make_project "p6-unity" "60")
cat > "$d/_aegis-output/playtests/S03-02.md" <<'EOF'
verified_by: jiap
date: 2026-05-21
pass: true
EOF
OUT=$(bash "$TOOL" report "$d" 2>&1)
if echo "$OUT" | grep -qE "verified=1/2.*coverage=60%"; then
    pass "T6: report emits parseable verified=1/2 coverage=60%"
else
    fail "T6: report format" "out=$OUT"
fi

# ── T7: soft gate (exit 0) ───────────────────────────────────────────────
echo ""
echo "--- T7: soft gate — exit 0 even with all stories missing ---"
d=$(make_project "p7-unity" "60")
bash "$TOOL" check "$d" >/dev/null 2>&1
rc=$?
if [[ "$rc" == "0" ]]; then
    pass "T7: exit 0 on all-missing case (soft gate)"
else
    fail "T7: soft gate" "rc=$rc"
fi

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
echo "============================================"
[[ "$FAIL" -gt 0 ]] && exit 1
exit 0
