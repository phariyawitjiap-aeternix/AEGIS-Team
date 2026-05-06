#!/usr/bin/env bash
# aegis-skill-frontmatter-test.sh — Sprint v12-03 acceptance + regression test
#
# Verifies tools/aegis-doc-canon/skill-frontmatter.mjs:
#   --lint   on the live tree (39 skills, all 9 keys present)
#   --lint   on a fixture missing keys → exit 1
#   --backfill on a fixture: idempotent (zero diff on second run)
#   --apply-manifest writes the named values
#   manifest with unknown skill name → reported as error
#   --dry-run skips writes
#   live tree's 12 tool-backed skills have non-empty wires/tests where expected

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
FM_TOOL="${REPO_ROOT}/tools/aegis-doc-canon/skill-frontmatter.mjs"
MANIFEST="${REPO_ROOT}/tools/aegis-doc-canon/skill-graph-manifest.json"
LIVE_SKILLS="${REPO_ROOT}/skills"

[[ -f "$FM_TOOL" ]] || { echo "FATAL: missing $FM_TOOL" >&2; exit 2; }
[[ -d "$LIVE_SKILLS" ]] || { echo "FATAL: missing $LIVE_SKILLS" >&2; exit 2; }
command -v node >/dev/null 2>&1 || { echo "FATAL: node not found" >&2; exit 2; }

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
PASS=0; FAIL=0
pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}FAIL${NC}: $1 -- $2"; FAIL=$((FAIL+1)); }

TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/aegis-skill-fm-XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT INT TERM

echo "================================================="
echo "AEGIS skill-frontmatter — sprint v12-03 acceptance"
echo "================================================="

# ─── T1: live tree passes ──────────────────────────────────────────────────
echo
echo "T1: live tree --lint passes (39 skills, all 9 keys)"
OUT=$(node "$FM_TOOL" --lint --skills-dir "$LIVE_SKILLS" 2>&1)
RC=$?
if [[ $RC -eq 0 ]]; then
    pass "live tree --lint exits 0"
else
    fail "live tree --lint exits 0" "exit=$RC, output:\n$OUT"
fi
if echo "$OUT" | grep -q "all 39 skills satisfy schema"; then
    pass "live tree reports 39 skills satisfy"
else
    fail "live tree reports 39 skills satisfy" "output:\n$OUT"
fi

# ─── T2: live tree backfill is idempotent ──────────────────────────────────
echo
echo "T2: live tree --backfill is idempotent (post-v12-03 backfill)"
OUT=$(node "$FM_TOOL" --backfill --skills-dir "$LIVE_SKILLS" 2>&1)
RC=$?
if [[ $RC -eq 0 ]]; then
    pass "live tree --backfill exits 0"
else
    fail "live tree --backfill exits 0" "exit=$RC, output:\n$OUT"
fi
if echo "$OUT" | grep -q "0 skills backfilled"; then
    pass "live tree --backfill is idempotent (0 changes)"
else
    fail "live tree --backfill is idempotent" "output:\n$OUT"
fi

# ─── Fixture builders ──────────────────────────────────────────────────────
mkdir -p "$TEST_DIR/skills"

write_complete_skill() {
    cat > "$1" <<'EOF'
---
name: test-skill
description: "Test skill"
profile: standard
triggers:
  en: ["test"]
  th: ["ทดสอบ"]
reads: []
writes: []
wires: []
tests: []
supersedes: []
---

# Body
EOF
}

write_missing_graph_keys() {
    cat > "$1" <<'EOF'
---
name: test-skill
description: "Test skill"
profile: standard
triggers:
  en: ["test"]
  th: ["ทดสอบ"]
---

# Body
EOF
}

write_missing_base_key() {
    cat > "$1" <<'EOF'
---
name: test-skill
description: "Test skill, missing profile"
triggers:
  en: ["test"]
  th: []
reads: []
writes: []
wires: []
tests: []
supersedes: []
---

# Body
EOF
}

# ─── T3: fixture with all keys passes ──────────────────────────────────────
echo
echo "T3: fixture with all 9 keys passes lint"
write_complete_skill "$TEST_DIR/skills/complete.md"
OUT=$(node "$FM_TOOL" --lint --skills-dir "$TEST_DIR/skills" 2>&1)
RC=$?
if [[ $RC -eq 0 ]]; then
    pass "complete fixture lints clean"
else
    fail "complete fixture lints clean" "exit=$RC, output:\n$OUT"
fi

# ─── T4: fixture missing graph keys fails lint ─────────────────────────────
echo
echo "T4: fixture missing graph keys fails lint"
write_missing_graph_keys "$TEST_DIR/skills/incomplete.md"
OUT=$(node "$FM_TOOL" --lint --skills-dir "$TEST_DIR/skills" 2>&1)
RC=$?
if [[ $RC -eq 1 ]]; then
    pass "incomplete fixture exits 1"
else
    fail "incomplete fixture exits 1" "exit=$RC, output:\n$OUT"
fi
if echo "$OUT" | grep -q "missing keys"; then
    pass "incomplete fixture reports missing keys"
else
    fail "incomplete fixture reports missing keys" "output:\n$OUT"
fi

# ─── T5: fixture missing base key fails lint ───────────────────────────────
echo
echo "T5: fixture missing base key (profile) fails lint"
rm "$TEST_DIR/skills/incomplete.md"
write_missing_base_key "$TEST_DIR/skills/no-profile.md"
OUT=$(node "$FM_TOOL" --lint --skills-dir "$TEST_DIR/skills" 2>&1)
RC=$?
if [[ $RC -eq 1 ]]; then
    pass "missing-base-key fixture exits 1"
else
    fail "missing-base-key fixture exits 1" "exit=$RC, output:\n$OUT"
fi
if echo "$OUT" | grep -q "profile"; then
    pass "missing-base-key fixture reports profile missing"
else
    fail "missing-base-key fixture reports profile missing" "output:\n$OUT"
fi

# ─── T6: --backfill adds missing graph keys ────────────────────────────────
echo
echo "T6: --backfill adds missing graph keys to fixture"
rm "$TEST_DIR/skills/no-profile.md"
write_missing_graph_keys "$TEST_DIR/skills/incomplete.md"
OUT=$(node "$FM_TOOL" --backfill --skills-dir "$TEST_DIR/skills" 2>&1)
RC=$?
if [[ $RC -eq 0 ]] && echo "$OUT" | grep -q "1 skill backfilled"; then
    pass "--backfill reports 1 skill backfilled"
else
    fail "--backfill reports 1 skill backfilled" "exit=$RC, output:\n$OUT"
fi
# After backfill, lint should pass
LINT_OUT=$(node "$FM_TOOL" --lint --skills-dir "$TEST_DIR/skills" 2>&1)
LINT_RC=$?
if [[ $LINT_RC -eq 0 ]]; then
    pass "fixture passes lint after --backfill"
else
    fail "fixture passes lint after --backfill" "exit=$LINT_RC, output:\n$LINT_OUT"
fi

# ─── T7: --backfill is idempotent on fixture ───────────────────────────────
echo
echo "T7: --backfill is idempotent (second run = no change)"
SHA_BEFORE=$(shasum "$TEST_DIR/skills/incomplete.md" | awk '{print $1}')
node "$FM_TOOL" --backfill --skills-dir "$TEST_DIR/skills" >/dev/null 2>&1
SHA_AFTER=$(shasum "$TEST_DIR/skills/incomplete.md" | awk '{print $1}')
if [[ "$SHA_BEFORE" == "$SHA_AFTER" ]]; then
    pass "second --backfill leaves file byte-identical"
else
    fail "second --backfill leaves file byte-identical" "before=$SHA_BEFORE after=$SHA_AFTER"
fi

# ─── T8: --dry-run does not write ──────────────────────────────────────────
echo
echo "T8: --backfill --dry-run does not write"
write_missing_graph_keys "$TEST_DIR/skills/dryrun.md"
SHA_BEFORE=$(shasum "$TEST_DIR/skills/dryrun.md" | awk '{print $1}')
OUT=$(node "$FM_TOOL" --backfill --dry-run --skills-dir "$TEST_DIR/skills" 2>&1)
SHA_AFTER=$(shasum "$TEST_DIR/skills/dryrun.md" | awk '{print $1}')
if [[ "$SHA_BEFORE" == "$SHA_AFTER" ]]; then
    pass "--dry-run leaves file byte-identical"
else
    fail "--dry-run leaves file byte-identical" "before=$SHA_BEFORE after=$SHA_AFTER"
fi
if echo "$OUT" | grep -q "(--dry-run, no writes)"; then
    pass "--dry-run reports it skipped writes"
else
    fail "--dry-run reports it skipped writes" "output:\n$OUT"
fi

# ─── T9: --apply-manifest writes named values ──────────────────────────────
echo
echo "T9: --apply-manifest writes named values"
write_complete_skill "$TEST_DIR/skills/manifest-target.md"
cat > "$TEST_DIR/manifest.json" <<EOF
{
  "skills": {
    "manifest-target": {
      "writes": [".aegis/brain/test/foo.json"],
      "tests": ["tests/test-skill.sh"]
    }
  }
}
EOF
OUT=$(node "$FM_TOOL" --apply-manifest "$TEST_DIR/manifest.json" --skills-dir "$TEST_DIR/skills" 2>&1)
RC=$?
if [[ $RC -eq 0 ]]; then
    pass "--apply-manifest exits 0"
else
    fail "--apply-manifest exits 0" "exit=$RC, output:\n$OUT"
fi
if grep -q '.aegis/brain/test/foo.json' "$TEST_DIR/skills/manifest-target.md"; then
    pass "--apply-manifest wrote the new writes value"
else
    fail "--apply-manifest wrote the new writes value" "file:\n$(cat "$TEST_DIR/skills/manifest-target.md")"
fi
if grep -q 'tests: \[' "$TEST_DIR/skills/manifest-target.md" && grep -q '"tests/test-skill.sh"' "$TEST_DIR/skills/manifest-target.md"; then
    pass "--apply-manifest wrote the new tests value"
else
    fail "--apply-manifest wrote the new tests value" "file:\n$(cat "$TEST_DIR/skills/manifest-target.md")"
fi

# ─── T10: --apply-manifest reports unknown skill ───────────────────────────
echo
echo "T10: --apply-manifest reports unknown skill"
cat > "$TEST_DIR/bogus.json" <<EOF
{
  "skills": {
    "does-not-exist": { "writes": ["x"] }
  }
}
EOF
OUT=$(node "$FM_TOOL" --apply-manifest "$TEST_DIR/bogus.json" --skills-dir "$TEST_DIR/skills" 2>&1)
RC=$?
if [[ $RC -eq 1 ]]; then
    pass "unknown skill in manifest exits 1"
else
    fail "unknown skill in manifest exits 1" "exit=$RC, output:\n$OUT"
fi
if echo "$OUT" | grep -q "skill file not found"; then
    pass "unknown skill in manifest reports error"
else
    fail "unknown skill in manifest reports error" "output:\n$OUT"
fi

# ─── T11: live tool-backed skills have non-empty graph values ──────────────
echo
echo "T11: live tool-backed skills have non-empty wires (sample: aegis-live-tail)"
if grep -q 'wires: \["PostToolUse:.*:tools/aegis-live-tail/emit.mjs"\]' "$LIVE_SKILLS/aegis-live-tail.md"; then
    pass "aegis-live-tail has correct wires value"
else
    fail "aegis-live-tail has correct wires value" "file:\n$(grep wires: "$LIVE_SKILLS/aegis-live-tail.md")"
fi

# ─── T12: unknown arg rejected ─────────────────────────────────────────────
echo
echo "T12: unknown arg rejected"
OUT=$(node "$FM_TOOL" --bogus 2>&1)
RC=$?
if [[ $RC -eq 2 ]]; then
    pass "unknown arg exits 2"
else
    fail "unknown arg exits 2" "exit=$RC, output:\n$OUT"
fi

# ─── T13: missing mode rejected ────────────────────────────────────────────
echo
echo "T13: missing mode flag rejected"
OUT=$(node "$FM_TOOL" 2>&1)
RC=$?
if [[ $RC -eq 2 ]]; then
    pass "missing mode flag exits 2"
else
    fail "missing mode flag exits 2" "exit=$RC, output:\n$OUT"
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
