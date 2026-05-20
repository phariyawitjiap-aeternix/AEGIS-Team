#!/usr/bin/env bash
# aegis-coverage-screen-test.sh — sprint v15-19.
#
# Tests the tool-boundary screening tool:
#   T1: detect — web-next fixture → "web-next"
#   T2: detect — Unity fixture → "unity"
#   T3: detect — Xcode fixture → "xcode-ios"
#   T4: detect — Godot-CLI (GDScript) fixture → "godot-cli"
#   T5: detect — Terraform fixture → "terraform"
#   T6: detect — Rust fixture → "rust"
#   T7: detect — empty dir → "unknown"
#   T8: screen — Unity fixture writes coverage.json with 4 gaps
#   T9: screen — web-next fixture writes coverage.json with 100% + zero gaps
#   T10: ack — flips ack flag; show no longer prints raw warning header
#   T11: soft-gate — process exit is 0 in all paths even for low-coverage
#   T12: idempotency — running screen twice produces same JSON shape

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TOOL="$REPO_ROOT/tools/aegis-coverage-screen.sh"

[[ -f "$TOOL" ]] || { echo "FATAL: missing $TOOL" >&2; exit 2; }
command -v jq >/dev/null 2>&1 || { echo "FATAL: jq not installed (test env)" >&2; exit 2; }

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
PASS=0; FAIL=0
pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}FAIL${NC}: $1 -- $2"; FAIL=$((FAIL+1)); }

TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/aegis-coverage-XXXXXX")
trap 'find "$TEST_DIR" -type f -delete 2>/dev/null; find "$TEST_DIR" -depth -type d -delete 2>/dev/null' EXIT INT TERM

# ── fixture builders ─────────────────────────────────────────────────────
make_web_next() {
    local d="$TEST_DIR/web-next"; mkdir -p "$d"
    cat > "$d/package.json" <<EOF
{"name":"x","dependencies":{"next":"14.0.0","react":"18.0.0"}}
EOF
    echo "$d"
}

make_unity() {
    local d="$TEST_DIR/unity"; mkdir -p "$d/Assets"
    cat > "$d/Assembly-CSharp.csproj" <<EOF
<Project Sdk="Microsoft.NET.Sdk"/>
EOF
    echo "$d"
}

make_xcode() {
    local d="$TEST_DIR/xcode"; mkdir -p "$d/MyApp.xcodeproj"
    touch "$d/MyApp.xcodeproj/project.pbxproj"
    echo "$d"
}

make_godot_cli() {
    local d="$TEST_DIR/godot-cli"; mkdir -p "$d"
    echo "[application]" > "$d/project.godot"
    # No .csproj → pure GDScript → CLI-buildable
    echo "$d"
}

make_godot_editor() {
    local d="$TEST_DIR/godot-editor"; mkdir -p "$d"
    echo "[application]" > "$d/project.godot"
    echo "<Project/>" > "$d/Game.csproj"
    echo "$d"
}

make_terraform() {
    local d="$TEST_DIR/terraform"; mkdir -p "$d"
    echo "resource \"null_resource\" \"x\" {}" > "$d/main.tf"
    echo "$d"
}

make_rust() {
    local d="$TEST_DIR/rust"; mkdir -p "$d/src"
    cat > "$d/Cargo.toml" <<EOF
[package]
name = "x"
version = "0.1.0"
EOF
    echo "$d"
}

make_empty() {
    local d="$TEST_DIR/empty"; mkdir -p "$d"
    echo "$d"
}

echo "============================================"
echo "AEGIS coverage-screen — sprint v15-19"
echo "============================================"

# ── T1: web-next ─────────────────────────────────────────────────────────
echo ""
echo "--- T1: detect web-next ---"
d=$(make_web_next)
got=$(bash "$TOOL" detect "$d" 2>&1)
if [[ "$got" == "web-next" ]]; then pass "T1: web-next detected"; else fail "T1: web-next" "got '$got'"; fi

# ── T2: Unity ────────────────────────────────────────────────────────────
echo ""
echo "--- T2: detect Unity ---"
d=$(make_unity)
got=$(bash "$TOOL" detect "$d" 2>&1)
if [[ "$got" == "unity" ]]; then pass "T2: unity detected"; else fail "T2: unity" "got '$got'"; fi

# ── T3: Xcode ────────────────────────────────────────────────────────────
echo ""
echo "--- T3: detect Xcode ---"
d=$(make_xcode)
got=$(bash "$TOOL" detect "$d" 2>&1)
if [[ "$got" == "xcode-ios" ]]; then pass "T3: xcode-ios detected"; else fail "T3: xcode-ios" "got '$got'"; fi

# ── T4: Godot CLI ────────────────────────────────────────────────────────
echo ""
echo "--- T4: detect Godot CLI (GDScript) ---"
d=$(make_godot_cli)
got=$(bash "$TOOL" detect "$d" 2>&1)
if [[ "$got" == "godot-cli" ]]; then pass "T4: godot-cli detected"; else fail "T4: godot-cli" "got '$got'"; fi

echo ""
echo "--- T4b: detect Godot Editor (C#) ---"
d=$(make_godot_editor)
got=$(bash "$TOOL" detect "$d" 2>&1)
if [[ "$got" == "godot-editor" ]]; then pass "T4b: godot-editor detected"; else fail "T4b: godot-editor" "got '$got'"; fi

# ── T5: Terraform ────────────────────────────────────────────────────────
echo ""
echo "--- T5: detect Terraform ---"
d=$(make_terraform)
got=$(bash "$TOOL" detect "$d" 2>&1)
if [[ "$got" == "terraform" ]]; then pass "T5: terraform detected"; else fail "T5: terraform" "got '$got'"; fi

# ── T6: Rust ─────────────────────────────────────────────────────────────
echo ""
echo "--- T6: detect Rust ---"
d=$(make_rust)
got=$(bash "$TOOL" detect "$d" 2>&1)
if [[ "$got" == "rust" ]]; then pass "T6: rust detected"; else fail "T6: rust" "got '$got'"; fi

# ── T7: empty dir → unknown ──────────────────────────────────────────────
echo ""
echo "--- T7: detect empty dir → unknown ---"
d=$(make_empty)
got=$(bash "$TOOL" detect "$d" 2>&1)
if [[ "$got" == "unknown" ]]; then pass "T7: unknown detected"; else fail "T7: unknown" "got '$got'"; fi

# ── T8: screen Unity → coverage.json with gaps ───────────────────────────
echo ""
echo "--- T8: screen Unity writes coverage.json with 4 gaps ---"
d=$(make_unity)
bash "$TOOL" screen "$d" >/dev/null 2>&1
json="$d/.aegis/brain/state/coverage.json"
if [[ -f "$json" ]]; then
    coverage=$(jq -r '.coverage_pct' "$json")
    gap_count=$(jq '.gaps | length' "$json")
    if [[ "$coverage" == "60" ]] && [[ "$gap_count" == "4" ]]; then
        pass "T8: unity coverage.json schema correct (60%, 4 gaps)"
    else
        fail "T8: unity coverage schema" "coverage=$coverage gaps=$gap_count"
    fi
else
    fail "T8: unity coverage.json" "file not written at $json"
fi

# ── T9: screen web-next → 100% + zero gaps ───────────────────────────────
echo ""
echo "--- T9: screen web-next writes coverage.json with 100% + zero gaps ---"
d=$(make_web_next)
bash "$TOOL" screen "$d" >/dev/null 2>&1
json="$d/.aegis/brain/state/coverage.json"
if [[ -f "$json" ]]; then
    coverage=$(jq -r '.coverage_pct' "$json")
    gap_count=$(jq '.gaps | length' "$json")
    if [[ "$coverage" == "100" ]] && [[ "$gap_count" == "0" ]]; then
        pass "T9: web-next coverage.json correct (100%, 0 gaps)"
    else
        fail "T9: web-next coverage schema" "coverage=$coverage gaps=$gap_count"
    fi
else
    fail "T9: web-next coverage.json" "file not written"
fi

# ── T10: ack flips flag ──────────────────────────────────────────────────
echo ""
echo "--- T10: ack flips the ack flag to true ---"
d=$(make_unity)
bash "$TOOL" screen "$d" >/dev/null 2>&1
bash "$TOOL" ack "$d" >/dev/null 2>&1
acked=$(jq -r '.ack' "$d/.aegis/brain/state/coverage.json")
if [[ "$acked" == "true" ]]; then pass "T10: ack=true after ack command"; else fail "T10: ack" "got ack=$acked"; fi

# ── T11: soft-gate → process exit 0 even for low-coverage ────────────────
echo ""
echo "--- T11: soft-gate: process always exits 0 ---"
d=$(make_unity)
bash "$TOOL" screen "$d" >/dev/null 2>&1
rc=$?
if [[ "$rc" == "0" ]]; then
    pass "T11: low-coverage Unity exits 0 (soft gate)"
else
    fail "T11: soft-gate" "Unity screen exited $rc, expected 0"
fi

# Also for xcode (even lower coverage)
d=$(make_xcode)
bash "$TOOL" screen "$d" >/dev/null 2>&1
rc=$?
if [[ "$rc" == "0" ]]; then
    pass "T11b: xcode-ios screen exits 0 (soft gate)"
else
    fail "T11b: soft-gate" "xcode-ios screen exited $rc"
fi

# ── T12: idempotency ─────────────────────────────────────────────────────
echo ""
echo "--- T12: screen twice yields same JSON shape (gaps, coverage_pct) ---"
d=$(make_unity)
bash "$TOOL" screen "$d" >/dev/null 2>&1
hash1=$(jq -c '{stack, coverage_pct, gaps_count: (.gaps | length)}' "$d/.aegis/brain/state/coverage.json")
sleep 1
bash "$TOOL" screen "$d" >/dev/null 2>&1
hash2=$(jq -c '{stack, coverage_pct, gaps_count: (.gaps | length)}' "$d/.aegis/brain/state/coverage.json")
if [[ "$hash1" == "$hash2" ]]; then
    pass "T12: second screen produces same shape (idempotent)"
else
    fail "T12: idempotency" "hash1=$hash1 hash2=$hash2"
fi

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
echo "============================================"

if [[ "$FAIL" -gt 0 ]]; then
    exit 1
fi
exit 0
