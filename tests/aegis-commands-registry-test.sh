#!/usr/bin/env bash
# tests/aegis-commands-registry-test.sh
# ─────────────────────────────────────────────────────────────────────────────
# Test suite for v14-01 S14-01-01: CommandDef registry.
#
# Verifies:
#   1. registry.mjs exports COMMAND_REGISTRY with one entry per command (count derived)
#   2. render-help.mjs validate exits 0 (registry ⊇ filesystem, frontmatter OK)
#   3. render-help.mjs list outputs names matching .claude/commands/*.md (count derived)
#   4. render-help.mjs help --json is valid JSON whose .commands length == filesystem count
#   5. resolveCommand() handles aliases (test via inline node script)
#
# Sprint: v14-01 (S14-01-01)
# Run:    bash tests/aegis-commands-registry-test.sh
# ─────────────────────────────────────────────────────────────────────────────

set -uo pipefail

# Resolve repo root regardless of where the test is invoked from.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

REGISTRY="tools/aegis-commands/registry.mjs"
RENDER="tools/aegis-commands/render-help.mjs"

# Canonical command count derived from the filesystem (the source of truth) —
# never hardcode it (was pinned to "16"; would silently break the moment a
# command is added/removed). Every source below must AGREE with this number.
EXPECTED_CMDS=$(ls .claude/commands/*.md 2>/dev/null | wc -l | tr -d ' ')

PASS=0
FAIL=0
RESULTS=()

pass() { PASS=$((PASS+1)); RESULTS+=("✓ $1"); }
fail() { FAIL=$((FAIL+1)); RESULTS+=("✗ $1: $2"); }

# ─── TC1: Registry file exists ───────────────────────────────────────────────
if [ -f "$REGISTRY" ]; then
  pass "TC1 registry.mjs exists"
else
  fail "TC1" "registry.mjs not found at $REGISTRY"
fi

# ─── TC2: Render-help file exists + executable ───────────────────────────────
if [ -f "$RENDER" ]; then
  pass "TC2 render-help.mjs exists"
else
  fail "TC2" "render-help.mjs not found at $RENDER"
fi

# ─── TC3: Registry list count == filesystem command count (EXPECTED_CMDS) ────
LIST_OUTPUT=$(node "$RENDER" list 2>&1) || {
  fail "TC3" "render-help list failed: $LIST_OUTPUT"
  LIST_OUTPUT=""
}
if [ -n "$LIST_OUTPUT" ]; then
  COUNT=$(echo "$LIST_OUTPUT" | wc -l | tr -d ' ')
  if [ "$COUNT" = "$EXPECTED_CMDS" ]; then
    pass "TC3 list shows $EXPECTED_CMDS commands (matches filesystem)"
  else
    fail "TC3" "registry list shows $COUNT, filesystem has $EXPECTED_CMDS"
  fi
fi

# ─── TC4: Filesystem command count (the source of truth; sanity floor) ───────
FS_NAMES=$(ls .claude/commands/*.md 2>/dev/null | xargs -n1 basename | sed 's/\.md$//' | sort)
FS_COUNT=$(echo "$FS_NAMES" | wc -l | tr -d ' ')
# Sanity floor (catches an empty/broken commands dir) — exact agreement between
# sources is enforced by TC3/TC6/TC7 against EXPECTED_CMDS, not by a pinned literal.
if [ "$FS_COUNT" -ge 12 ]; then
  pass "TC4 filesystem has $FS_COUNT command files (≥12 floor)"
else
  fail "TC4" "filesystem has only $FS_COUNT .md files (expected ≥12)"
fi

# ─── TC5: Validate command exits 0 (registry ⊇ filesystem, frontmatter OK) ──
VALIDATE_OUTPUT=$(node "$RENDER" validate 2>&1)
VALIDATE_EXIT=$?
if [ $VALIDATE_EXIT -eq 0 ]; then
  pass "TC5 validate exits 0"
else
  fail "TC5" "validate exited $VALIDATE_EXIT: $VALIDATE_OUTPUT"
fi

# ─── TC6: Registry names == filesystem names ─────────────────────────────────
REG_NAMES=$(echo "$LIST_OUTPUT" | sort)
if [ "$REG_NAMES" = "$FS_NAMES" ]; then
  pass "TC6 registry names == filesystem names"
else
  fail "TC6" "registry/filesystem name mismatch:\nregistry: $REG_NAMES\nfilesystem: $FS_NAMES"
fi

# ─── TC7: help --json .commands length == filesystem count (EXPECTED_CMDS) ───
JSON_OUTPUT=$(node "$RENDER" help --json 2>&1)
if echo "$JSON_OUTPUT" | EXPECTED_CMDS="$EXPECTED_CMDS" node -e "
const d = JSON.parse(require('fs').readFileSync(0, 'utf-8'));
const expected = Number(process.env.EXPECTED_CMDS);
if (!Array.isArray(d.commands) || d.commands.length !== expected) {
  console.error('expected commands array of length', expected, 'got', d.commands?.length);
  process.exit(1);
}
if (!Array.isArray(d.categories) || d.categories.length === 0) {
  console.error('expected categories array');
  process.exit(1);
}
" 2>&1; then
  pass "TC7 help --json valid + $EXPECTED_CMDS commands (matches filesystem)"
else
  fail "TC7" "JSON parse or shape check failed"
fi

# ─── TC8: resolveCommand handles aliases ──────────────────────────────────────
ALIAS_TEST=$(node --input-type=module -e "
import { resolveCommand } from './tools/aegis-commands/registry.mjs';
const result = resolveCommand('check');  // alias for aegis-verify
if (!result || result.name !== 'aegis-verify') {
  console.error('expected check->aegis-verify, got', result?.name);
  process.exit(1);
}
const slashed = resolveCommand('/aegis-status');
if (!slashed || slashed.name !== 'aegis-status') {
  console.error('expected /aegis-status->aegis-status, got', slashed?.name);
  process.exit(1);
}
console.log('OK');
" 2>&1)
if [ "$ALIAS_TEST" = "OK" ]; then
  pass "TC8 resolveCommand handles aliases + slashes"
else
  fail "TC8" "alias resolution failed: $ALIAS_TEST"
fi

# ─── TC9: aegis-upgrade has frontmatter (the bug fix) ────────────────────────
UPGRADE_FM=$(head -7 .claude/commands/aegis-upgrade.md | grep -E "^name: aegis-upgrade$" || true)
if [ -n "$UPGRADE_FM" ]; then
  pass "TC9 aegis-upgrade.md has frontmatter (bug fix)"
else
  fail "TC9" "aegis-upgrade.md still missing frontmatter"
fi

# ─── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  v14-01 S14-01-01 — CommandDef Registry Tests"
echo "═══════════════════════════════════════════════════════════════"
for r in "${RESULTS[@]}"; do echo "  $r"; done
echo "───────────────────────────────────────────────────────────────"
echo "  Result: $PASS passed, $FAIL failed (out of $((PASS+FAIL)) tests)"
echo "═══════════════════════════════════════════════════════════════"

exit $([ $FAIL -eq 0 ] && echo 0 || echo 1)
