#!/usr/bin/env bash
# tests/aegis-commands-registry-test.sh
# ─────────────────────────────────────────────────────────────────────────────
# Test suite for v14-01 S14-01-01: CommandDef registry.
#
# Verifies:
#   1. registry.mjs exports COMMAND_REGISTRY with 14 entries
#   2. render-help.mjs validate exits 0 (registry ⊇ filesystem, frontmatter OK)
#   3. render-help.mjs list outputs 14 names matching .claude/commands/*.md
#   4. render-help.mjs help --json is valid JSON with 14 commands
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

# ─── TC3: Registry has exactly 14 entries via list command ───────────────────
LIST_OUTPUT=$(node "$RENDER" list 2>&1) || {
  fail "TC3" "render-help list failed: $LIST_OUTPUT"
  LIST_OUTPUT=""
}
if [ -n "$LIST_OUTPUT" ]; then
  COUNT=$(echo "$LIST_OUTPUT" | wc -l | tr -d ' ')
  if [ "$COUNT" = "16" ]; then
    pass "TC3 list shows 16 commands"
  else
    fail "TC3" "expected 16, got $COUNT"
  fi
fi

# ─── TC4: Filesystem has 14 .md files matching registry ──────────────────────
FS_NAMES=$(ls .claude/commands/*.md 2>/dev/null | xargs -n1 basename | sed 's/\.md$//' | sort)
FS_COUNT=$(echo "$FS_NAMES" | wc -l | tr -d ' ')
if [ "$FS_COUNT" = "16" ]; then
  pass "TC4 filesystem has 16 command files"
else
  fail "TC4" "filesystem has $FS_COUNT .md files (expected 16)"
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

# ─── TC7: help --json is valid JSON with .commands array of length 14 ────────
JSON_OUTPUT=$(node "$RENDER" help --json 2>&1)
if echo "$JSON_OUTPUT" | node -e "
const d = JSON.parse(require('fs').readFileSync(0, 'utf-8'));
if (!Array.isArray(d.commands) || d.commands.length !== 16) {
  console.error('expected commands array of length 16, got', d.commands?.length);
  process.exit(1);
}
if (!Array.isArray(d.categories) || d.categories.length === 0) {
  console.error('expected categories array');
  process.exit(1);
}
" 2>&1; then
  pass "TC7 help --json valid + 16 commands"
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
