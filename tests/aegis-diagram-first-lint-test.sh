#!/usr/bin/env bash
# aegis-diagram-first-lint-test.sh — sprint v15-17.
#
# Validates the diagram-first-reflex skill is present + wired into the
# 5 most-affected personas. Spot-checks recent sprint plans for mermaid
# presence in structural sections (advisory, not strict — older sprints
# pre-date the habit and won't be retrofitted).

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
PASS=0; FAIL=0
pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}FAIL${NC}: $1 -- $2"; FAIL=$((FAIL+1)); }
warn() { echo -e "${YELLOW}WARN${NC}: $1"; }

echo "============================================"
echo "AEGIS diagram-first-reflex lint — sprint v15-17"
echo "============================================"

# ── T1: skill file exists with required frontmatter fields ───────────────
echo ""
echo "--- T1: skills/diagram-first-reflex.md present + wired ---"
SKILL="$REPO_ROOT/skills/diagram-first-reflex.md"
if [[ ! -f "$SKILL" ]]; then
    fail "T1: skill file missing" "expected $SKILL"
else
    if grep -q "^name: diagram-first-reflex" "$SKILL" \
        && grep -q "Trigger / Anti-trigger matrix" "$SKILL" \
        && grep -q "Per-persona defaults" "$SKILL"; then
        pass "T1: skill file present with required sections"
    else
        fail "T1: skill structure" "missing one of: name, trigger matrix, persona defaults"
    fi
fi

# ── T2: 5 personas wire the reflex section ──────────────────────────────
echo ""
echo "--- T2: 5 personas have Diagram-First Reflex section ---"
EXPECTED_PERSONAS=(
    "nick-fury"
    "captain-america"
    "iron-man"
    "loki"
    "coulson"
)
missing=0
for persona in "${EXPECTED_PERSONAS[@]}"; do
    f="$REPO_ROOT/.claude/agents/${persona}.md"
    if [[ ! -f "$f" ]]; then
        echo "  ✗ missing persona file: $f" >&2
        missing=$((missing + 1))
        continue
    fi
    if ! grep -q "Diagram-First Reflex" "$f"; then
        echo "  ✗ $persona: no Diagram-First Reflex section" >&2
        missing=$((missing + 1))
        continue
    fi
    if ! grep -q '```mermaid' "$f"; then
        echo "  ✗ $persona: section exists but no mermaid example" >&2
        missing=$((missing + 1))
    fi
done
if [[ "$missing" == "0" ]]; then
    pass "T2: all 5 personas wired with mermaid example"
else
    fail "T2: persona wiring" "$missing of ${#EXPECTED_PERSONAS[@]} missing"
fi

# ── T3: CLAUDE.md mentions the reflex ───────────────────────────────────
echo ""
echo "--- T3: CLAUDE.md surfaces the habit ---"
if grep -q "Diagram-First Reflex" "$REPO_ROOT/CLAUDE.md" \
    && grep -q "skills/diagram-first-reflex.md" "$REPO_ROOT/CLAUDE.md"; then
    pass "T3: CLAUDE.md documents reflex + links to skill"
else
    fail "T3: CLAUDE.md missing" "expected 'Diagram-First Reflex' section + skill link"
fi

# ── T4: skill file's per-persona table covers all 11 personas ───────────
echo ""
echo "--- T4: per-persona defaults cover all 11 personas ---"
ALL_PERSONAS=(
    "Nick Fury" "Captain America" "Iron Man" "Loki" "Coulson"
    "Spider-Man" "War Machine" "Black Panther" "Thor" "Beast" "Wasp"
)
covered=0
uncovered=()
for p in "${ALL_PERSONAS[@]}"; do
    if grep -q "$p" "$SKILL"; then
        covered=$((covered + 1))
    else
        uncovered+=("$p")
    fi
done
if [[ "$covered" == "${#ALL_PERSONAS[@]}" ]]; then
    pass "T4: all ${#ALL_PERSONAS[@]} personas have a default diagram type"
else
    fail "T4: persona coverage" "$covered/${#ALL_PERSONAS[@]} covered; missing: ${uncovered[*]}"
fi

# ── T5: trigger + anti-trigger matrices both present ────────────────────
echo ""
echo "--- T5: trigger AND anti-trigger matrices both documented ---"
trig_count=$(grep -c "Trigger (USE mermaid)" "$SKILL" 2>/dev/null || echo 0)
anti_count=$(grep -c "Anti-trigger (USE prose)" "$SKILL" 2>/dev/null || echo 0)
if [[ "$trig_count" -ge 1 && "$anti_count" -ge 1 ]]; then
    pass "T5: both trigger + anti-trigger sections documented"
else
    fail "T5: matrices incomplete" "trigger=$trig_count anti=$anti_count (each should be ≥1)"
fi

# ── T6: skill mentions Markdown-compat (renders in GH/Linear/Notion) ────
echo ""
echo "--- T6: skill notes Markdown-fence compatibility ---"
if grep -q '```mermaid' "$SKILL" && grep -qE "GitHub|Linear|Notion|brain-graph" "$SKILL"; then
    pass "T6: skill confirms Mermaid-in-Markdown compatibility"
else
    fail "T6: compatibility note" "missing GitHub/Linear/Notion/brain-graph mention"
fi

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
echo "============================================"

if [[ "$FAIL" -gt 0 ]]; then
    exit 1
fi
exit 0
