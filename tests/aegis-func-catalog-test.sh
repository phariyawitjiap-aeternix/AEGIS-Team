#!/usr/bin/env bash
# aegis-func-catalog-test.sh — Idempotency + drift test for FUNC catalog
# Sprint: v10-01-C
#
# Tests:
#   1. Catalog generates without error
#   2. Re-running produces identical output (idempotency)
#   3. Output is valid JSON
#   4. All entries have required fields
#   5. No duplicate FUNC IDs
#   6. Module assignments are valid

set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CATALOG="${PROJECT_ROOT}/.aegis/brain/func-catalog.json"
CATALOG_BACKUP="${CATALOG}.test-backup"
CATALOG_RERUN="${CATALOG}.rerun"
PASS=0
FAIL=0
TESTS=0

assert() {
  TESTS=$((TESTS + 1))
  local label="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    PASS=$((PASS + 1))
    echo "  PASS: $label"
  else
    FAIL=$((FAIL + 1))
    echo "  FAIL: $label"
  fi
}

echo "=== FUNC Catalog Test Suite ==="
echo ""

# --- Test 1: Generation succeeds ---
[ -f "$CATALOG" ] && cp "$CATALOG" "$CATALOG_BACKUP"
bash "${PROJECT_ROOT}/tools/aegis-func-catalog.sh" > /dev/null 2>&1
assert "T1: Catalog generates without error" test -f "$CATALOG"

# --- Test 2: Idempotency ---
cp "$CATALOG" "$CATALOG_RERUN"
bash "${PROJECT_ROOT}/tools/aegis-func-catalog.sh" > /dev/null 2>&1
assert "T2: Re-run produces identical output" diff -q "$CATALOG" "$CATALOG_RERUN"
rm -f "$CATALOG_RERUN"

# --- Test 3: Valid JSON ---
assert "T3: Output is valid JSON" python3 -m json.tool "$CATALOG"

# --- Test 4: All entries have required fields ---
MISSING=$(python3 -c "
import json, sys
d = json.load(open('$CATALOG'))
required = ['id', 'name', 'source_file', 'type', 'module', 'description']
missing = 0
for i, e in enumerate(d):
    for f in required:
        if f not in e or not e[f]:
            missing += 1
            print(f'Entry {i}: missing {f}', file=sys.stderr)
sys.exit(0 if missing == 0 else 1)
" 2>&1)
assert "T4: All entries have required fields" python3 -c "
import json, sys
d = json.load(open('$CATALOG'))
required = ['id', 'name', 'source_file', 'type', 'module', 'description']
for e in d:
    for f in required:
        if f not in e or not e[f]:
            sys.exit(1)
"

# --- Test 5: No duplicate FUNC IDs ---
assert "T5: No duplicate FUNC IDs" python3 -c "
import json, sys
d = json.load(open('$CATALOG'))
ids = [e['id'] for e in d]
dupes = set(x for x in ids if ids.count(x) > 1)
if dupes:
    print(f'Duplicate IDs: {dupes}', file=sys.stderr)
    sys.exit(1)
"

# --- Test 6: Module assignments are valid ---
VALID_MODULES="MOD-CORE MOD-AGENTS MOD-COMMANDS MOD-HOOKS MOD-BRAIN MOD-TOOLS MOD-ISO MOD-REFS MOD-SPRINTS MOD-SPECS MOD-PLAYBOOK UNASSIGNED"
assert "T6: All module assignments are valid" python3 -c "
import json, sys
d = json.load(open('$CATALOG'))
valid = set('$VALID_MODULES'.split())
invalid = set(e['module'] for e in d) - valid
if invalid:
    print(f'Invalid modules: {invalid}', file=sys.stderr)
    sys.exit(1)
"

# --- Cleanup ---
[ -f "$CATALOG_BACKUP" ] && mv "$CATALOG_BACKUP" "$CATALOG"

echo ""
echo "=== Results: $PASS/$TESTS passed, $FAIL failed ==="
[ "$FAIL" -gt 0 ] && exit 1
exit 0
