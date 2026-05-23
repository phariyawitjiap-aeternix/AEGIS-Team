#!/usr/bin/env bash
# aegis-install-upgrade-sweep-test.sh — sprint v15-26 regression.
#
# Tests the upgrade-sweep behavior added to install.sh:
#   T1: stale tools/aegis-foo.sh in target → swept to backup
#   T2: skill no longer in source → swept
#   T3: agent + command + reference + hook → all swept
#   T4: user file (NOT in AEGIS managed paths) → NOT touched
#   T5: tool package subdir (tools/aegis-foo/) → NOT swept (only top-level .sh)
#   T6: file in tools/_archived/ → NOT swept (intentional archive)
#   T7: fresh install (no --upgrade) → no sweep, no backup dir
#   T8: --upgrade with NO stale files → sweep silent, no false-positive removal

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
INSTALL="$REPO_ROOT/install.sh"

[[ -f "$INSTALL" ]] || { echo "FATAL: missing $INSTALL" >&2; exit 2; }

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
PASS=0; FAIL=0
pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}FAIL${NC}: $1 -- $2"; FAIL=$((FAIL+1)); }

TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/aegis-sweep-XXXXXX")
trap 'find "$TEST_DIR" -type f -delete 2>/dev/null; find "$TEST_DIR" -depth -type d -delete 2>/dev/null' EXIT INT TERM

# Build a "fake target" — looks like an installed AEGIS project with extra
# stale files. Then run install.sh --upgrade against it from the REAL source.
build_target() {
    local d="$1"
    mkdir -p "$d/tools" "$d/skills" "$d/.claude/agents" "$d/.claude/commands" "$d/.claude/references" "$d/.claude/hooks" "$d/.aegis/brain/resonance"
    # Required marker for upgrade mode
    touch "$d/CLAUDE.md"
    # Stale files (not in source)
    cat > "$d/tools/aegis-ZZZ-stale-tool.sh" <<'EOF'
#!/usr/bin/env bash
echo "I am stale"
EOF
    chmod +x "$d/tools/aegis-ZZZ-stale-tool.sh"
    cat > "$d/skills/zzz-stale-skill.md" <<'EOF'
---
name: zzz-stale-skill
profile: full
---
stale
EOF
    cat > "$d/.claude/agents/zzz-stale-agent.md" <<'EOF'
---
name: zzz-stale-agent
---
stale
EOF
    cat > "$d/.claude/commands/zzz-stale-command.md" <<'EOF'
stale command
EOF
    cat > "$d/.claude/references/zzz-stale-ref.md" <<'EOF'
stale reference
EOF
    cat > "$d/.claude/hooks/zzz-stale-hook.sh" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
    chmod +x "$d/.claude/hooks/zzz-stale-hook.sh"
    # User content (must NOT be swept)
    cat > "$d/.aegis/brain/resonance/user-project-identity.md" <<'EOF'
user project content
EOF
    mkdir -p "$d/_aegis-output/specs"
    cat > "$d/_aegis-output/specs/user-spec.md" <<'EOF'
user spec
EOF
    # Tool package subdir (must NOT be swept — only top-level aegis-*.sh)
    mkdir -p "$d/tools/aegis-fake-package"
    cat > "$d/tools/aegis-fake-package/runtime.mjs" <<'EOF'
// fake package
EOF
    # Intentional archive (must NOT be swept)
    mkdir -p "$d/tools/_archived"
    cat > "$d/tools/_archived/aegis-old-tool.sh" <<'EOF'
archived
EOF
}

# ── T1-T6: run upgrade then assert ───────────────────────────────────────
echo ""
echo "--- T1-T6: build fixture + run install --upgrade ---"
TARGET="$TEST_DIR/proj1"
build_target "$TARGET"
AEGIS_INSTALL_SKIP_CLAUDE_CHECK=1 bash "$INSTALL" --upgrade --target-dir "$TARGET" >/dev/null 2>&1

# T1: stale tool swept
if [[ ! -f "$TARGET/tools/aegis-ZZZ-stale-tool.sh" ]]; then
    pass "T1: stale tool removed from active tree"
else
    fail "T1: stale tool" "still present at $TARGET/tools/aegis-ZZZ-stale-tool.sh"
fi
# T1b: stale tool moved to swept/
if ls "$TARGET"/_aegis-backup-*/swept/tools/aegis-ZZZ-stale-tool.sh >/dev/null 2>&1; then
    pass "T1b: stale tool preserved in swept/ backup"
else
    fail "T1b: backup preservation" "not found in any _aegis-backup-*/swept/tools/"
fi
# T2: stale skill swept
if [[ ! -f "$TARGET/skills/zzz-stale-skill.md" ]]; then
    pass "T2: stale skill removed"
else
    fail "T2: stale skill" "still present"
fi
# T3a: stale agent swept
if [[ ! -f "$TARGET/.claude/agents/zzz-stale-agent.md" ]]; then
    pass "T3a: stale agent removed"
else
    fail "T3a: stale agent" "still present"
fi
# T3b: stale command swept
if [[ ! -f "$TARGET/.claude/commands/zzz-stale-command.md" ]]; then
    pass "T3b: stale command removed"
else
    fail "T3b: stale command" "still present"
fi
# T3c: stale reference swept
if [[ ! -f "$TARGET/.claude/references/zzz-stale-ref.md" ]]; then
    pass "T3c: stale reference removed"
else
    fail "T3c: stale ref" "still present"
fi
# T3d: stale hook swept
if [[ ! -f "$TARGET/.claude/hooks/zzz-stale-hook.sh" ]]; then
    pass "T3d: stale hook removed"
else
    fail "T3d: stale hook" "still present"
fi
# T4a: user brain content untouched
if [[ -f "$TARGET/.aegis/brain/resonance/user-project-identity.md" ]]; then
    pass "T4a: user brain content preserved"
else
    fail "T4a: brain preservation" "user file accidentally removed"
fi
# T4b: _aegis-output untouched
if [[ -f "$TARGET/_aegis-output/specs/user-spec.md" ]]; then
    pass "T4b: _aegis-output content preserved"
else
    fail "T4b: _aegis-output" "user file accidentally removed"
fi
# T5: tool package subdir NOT swept
if [[ -f "$TARGET/tools/aegis-fake-package/runtime.mjs" ]]; then
    pass "T5: tool package subdir not swept"
else
    fail "T5: package subdir" "incorrectly swept"
fi
# T6: _archived/ subdir NOT swept
if [[ -f "$TARGET/tools/_archived/aegis-old-tool.sh" ]]; then
    pass "T6: _archived/ subdir not swept"
else
    fail "T6: archived" "incorrectly swept"
fi

# ── T7: fresh install (no --upgrade) → no sweep ──────────────────────────
echo ""
echo "--- T7: fresh install does NOT sweep ---"
TARGET2="$TEST_DIR/proj2-fresh"
mkdir -p "$TARGET2"
AEGIS_INSTALL_SKIP_CLAUDE_CHECK=1 bash "$INSTALL" --target-dir "$TARGET2" >/dev/null 2>&1
# Should not have a backup dir at all (since not --upgrade)
if ! ls -d "$TARGET2"/_aegis-backup-* >/dev/null 2>&1; then
    pass "T7: fresh install creates no backup dir"
else
    fail "T7: fresh install" "_aegis-backup-* exists on fresh install"
fi

# ── T8: --upgrade with NO stale files → sweep is silent no-op ────────────
echo ""
echo "--- T8: clean upgrade — no stale files → silent no-op ---"
TARGET3="$TEST_DIR/proj3-clean"
mkdir -p "$TARGET3"
# Run fresh install first to give it a "clean" state matching source
AEGIS_INSTALL_SKIP_CLAUDE_CHECK=1 bash "$INSTALL" --target-dir "$TARGET3" >/dev/null 2>&1
# Now run upgrade — no stale files exist
OUT=$(AEGIS_INSTALL_SKIP_CLAUDE_CHECK=1 bash "$INSTALL" --upgrade --target-dir "$TARGET3" 2>&1)
if echo "$OUT" | grep -qE "Swept [1-9]"; then
    fail "T8: clean upgrade" "swept files on a clean state — false positive! out: $(echo "$OUT" | grep Swept)"
else
    pass "T8: clean upgrade swept 0 files (no false positives)"
fi

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
echo "============================================"
[[ "$FAIL" -gt 0 ]] && exit 1
exit 0
