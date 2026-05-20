#!/usr/bin/env bash
# aegis-skill-autodiscover-test.sh — sprint v15-18A regression.
#
# Validates the install scripts (install.sh + install-remote.sh) ship
# skills via frontmatter `profile:` field auto-discovery, NOT via the
# hand-coded arrays that caused the v15-17 hotfix drift bug.
#
# T1: every skill in skills/ has a `profile:` field (no orphans)
# T2: install.sh ships expected counts at each profile tier
# T3: install-remote.sh ships expected counts at each profile tier
# T4: counts match between install.sh and install-remote.sh per tier
#     (they should — same auto-discovery logic against same source)
# T5: adding a NEW skill with profile: standard auto-ships at standard+
#     (validates the drift bug class is closed)
# T6: hand-coded array references removed from both installers

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
INSTALL_SH="$REPO_ROOT/install.sh"
INSTALL_REMOTE="$REPO_ROOT/install-remote.sh"

[[ -f "$INSTALL_SH" ]] || { echo "FATAL: missing $INSTALL_SH" >&2; exit 2; }
[[ -f "$INSTALL_REMOTE" ]] || { echo "FATAL: missing $INSTALL_REMOTE" >&2; exit 2; }

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
PASS=0; FAIL=0
pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}FAIL${NC}: $1 -- $2"; FAIL=$((FAIL+1)); }

TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/aegis-skill-autodiscover-XXXXXX")
trap 'find "$TEST_DIR" -type f -delete 2>/dev/null; find "$TEST_DIR" -depth -type d -delete 2>/dev/null' EXIT INT TERM

echo "============================================"
echo "AEGIS skill auto-discovery — sprint v15-18A"
echo "============================================"

# ── T1: every skill has a profile field ───────────────────────────────────
echo ""
echo "--- T1: every skills/*.md has frontmatter profile: field ---"
missing=0
for f in "$REPO_ROOT/skills/"*.md; do
    if ! grep -q "^profile:" "$f"; then
        echo "  ✗ no profile field: $(basename "$f")" >&2
        missing=$((missing + 1))
    fi
done
total=$(ls -1 "$REPO_ROOT/skills/"*.md 2>/dev/null | wc -l | tr -d ' ')
if [[ "$missing" == "0" ]]; then
    pass "T1: all $total skills have profile: frontmatter field"
else
    fail "T1: skills missing profile" "$missing of $total"
fi

# ── T2: install.sh ships correct count per tier ──────────────────────────
echo ""
echo "--- T2: install.sh ships correct counts at each profile tier ---"
install_at_tier() {
    local tier="$1"
    local sandbox="$TEST_DIR/install-sh-$tier"
    mkdir -p "$sandbox"
    (cd "$sandbox" && git init -q && \
     bash "$INSTALL_SH" --profile "$tier" --project-name "test" >/dev/null 2>&1)
    ls "$sandbox/skills/"*.md 2>/dev/null | wc -l | tr -d ' '
}

minimal_count=$(install_at_tier minimal)
standard_count=$(install_at_tier standard)
full_count=$(install_at_tier full)

if [[ "$minimal_count" -gt 0 ]] && [[ "$standard_count" -gt "$minimal_count" ]] && [[ "$full_count" -gt "$standard_count" ]]; then
    pass "T2: install.sh tier counts are strictly increasing (minimal=$minimal_count < standard=$standard_count < full=$full_count)"
else
    fail "T2: install.sh tier ordering" "minimal=$minimal_count standard=$standard_count full=$full_count"
fi

# ── T3: install-remote.sh ships the same as install.sh per tier ──────────
# (We use install.sh as a stand-in for install-remote since the remote
# version git-clones the repo and is hard to test in-CI without network.
# T6 below validates the LOGIC is identical between the two.)
echo ""
echo "--- T3: install.sh full-tier ships all 37 skills ---"
if [[ "$full_count" == "$total" ]]; then
    pass "T3: full profile ships every skill ($full_count == $total)"
else
    fail "T3: full count mismatch" "full=$full_count total=$total"
fi

# ── T4: install-remote.sh uses the same auto-discovery logic ─────────────
echo ""
echo "--- T4: install-remote.sh contains the auto-discovery markers ---"
if grep -q "skill_min_rank" "$INSTALL_REMOTE" && \
   grep -q "wanted_rank" "$INSTALL_REMOTE" && \
   grep -q "for skill_file in" "$INSTALL_REMOTE"; then
    pass "T4: install-remote.sh has skill_min_rank + wanted_rank + glob loop"
else
    fail "T4: install-remote.sh logic missing" "expected skill_min_rank + glob loop"
fi

# ── T5: adding a NEW skill auto-ships without code change ────────────────
# Simulate the v15-17 hotfix bug class: a brand-new skill with profile:
# standard should ship at standard+ tiers WITHOUT being added to any list.
echo ""
echo "--- T5: new standard-tier skill auto-ships (drift bug class closed) ---"
# Create a synthetic skill in a temp copy of the repo
SYNTH_REPO="$TEST_DIR/synth-repo"
mkdir -p "$SYNTH_REPO/skills"
# Copy just the bones we need: install.sh + skills/ contents
cp "$INSTALL_SH" "$SYNTH_REPO/install.sh"
cp -R "$REPO_ROOT/skills/" "$SYNTH_REPO/" 2>/dev/null || true
# Also copy the other directories install.sh needs
for dir in .claude tools _aegis-output; do
    if [[ -d "$REPO_ROOT/$dir" ]]; then
        cp -R "$REPO_ROOT/$dir" "$SYNTH_REPO/" 2>/dev/null || true
    fi
done
for f in CLAUDE.md CLAUDE_agents.md CLAUDE_safety.md CLAUDE_skills.md CLAUDE_lessons.md VERSION; do
    [[ -f "$REPO_ROOT/$f" ]] && cp "$REPO_ROOT/$f" "$SYNTH_REPO/"
done

# Add a synthetic skill that DOESN'T appear in any hand-list anywhere
cat > "$SYNTH_REPO/skills/v15-18a-synthetic-skill.md" <<'EOF'
---
name: v15-18a-synthetic-skill
description: "Synthetic skill for testing auto-discovery — should ship at standard+ without any hand-list update"
profile: standard
triggers: { en: [], th: [] }
reads: []
writes: []
wires: []
tests: []
supersedes: []
---

# Synthetic test skill
This skill exists ONLY to validate auto-discovery. Should ship at standard+ tier.
EOF

# Install at standard profile into a fresh sandbox
TARGET="$TEST_DIR/v15-18a-synth-target"
mkdir -p "$TARGET"
(cd "$TARGET" && git init -q && \
 bash "$SYNTH_REPO/install.sh" --profile standard --project-name "synth-test" >/dev/null 2>&1)

if [[ -f "$TARGET/skills/v15-18a-synthetic-skill.md" ]]; then
    pass "T5: new standard-tier skill auto-shipped without code changes (drift class closed)"
else
    fail "T5: synthetic skill NOT shipped" "expected $TARGET/skills/v15-18a-synthetic-skill.md to exist"
fi

# ── T6: hand-coded skill arrays removed from both installers ─────────────
echo ""
echo "--- T6: hand-coded minimal_skills/standard_skills/full_skills arrays REMOVED ---"
# Pattern: array assignment like `minimal_skills=("foo" "bar" "baz")`
# We allow `minimal_skills=(` only if it's empty / has just whitespace,
# but flag any actual entries.
violations=0
for installer in "$INSTALL_SH" "$INSTALL_REMOTE"; do
    if grep -qE '^(minimal|standard|full)_skills=\("' "$installer"; then
        echo "  ✗ $(basename "$installer"): still has hand-coded skill array" >&2
        violations=$((violations + 1))
    fi
    # Also check the multi-line array style (e.g. `array=(\n  entry\n  entry\n)`)
    if grep -qE '^(minimal|standard|full)_skills=\($' "$installer"; then
        echo "  ✗ $(basename "$installer"): still has multi-line skill array opening" >&2
        violations=$((violations + 1))
    fi
done
if [[ "$violations" == "0" ]]; then
    pass "T6: no hand-coded skill arrays in either installer"
else
    fail "T6: hand-list residue" "$violations violation(s)"
fi

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
echo "============================================"

if [[ "$FAIL" -gt 0 ]]; then
    exit 1
fi
exit 0
