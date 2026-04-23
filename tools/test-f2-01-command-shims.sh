#!/usr/bin/env bash
# test-f2-01-command-shims.sh — Tests for F2-01 command consolidation 29→12
# Bash 3.2 compatible.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/aegis-test-harness-template.sh"

CMD_DIR="${SCRIPT_DIR}/../.claude/commands"
CLAUDE_MD="${SCRIPT_DIR}/../CLAUDE.md"
CHAIN_MD="${SCRIPT_DIR}/../.claude/references/command-chain.md"

echo "=== F2-01: Command Consolidation 29→12 ==="
echo ""

# TC-01: All 12 canonical command files exist and are non-empty
CANONICALS=(
    "aegis-start"
    "aegis-status"
    "aegis-retro"
    "aegis-handoff"
    "aegis-sprint"
    "aegis-pipeline"
    "aegis-team"
    "aegis-breakdown"
    "aegis-verify"
    "aegis-deploy"
    "aegis-memory"
    "aegis-mode"
)

MISSING_CANONICAL=0
for cmd in "${CANONICALS[@]}"; do
    f="${CMD_DIR}/${cmd}.md"
    if [[ ! -f "$f" ]]; then
        FAIL "TC-01 canonical missing: ${cmd}.md"
        MISSING_CANONICAL=1
    elif [[ ! -s "$f" ]]; then
        FAIL "TC-01 canonical empty: ${cmd}.md"
        MISSING_CANONICAL=1
    fi
done
if [[ $MISSING_CANONICAL -eq 0 ]]; then
    PASS "TC-01 all 12 canonical command files exist and non-empty"
fi

# TC-02: All 17 shim files exist and contain "DEPRECATED"
SHIMS=(
    "aegis-kanban"
    "aegis-dashboard"
    "aegis-context"
    "aegis-qa"
    "aegis-flow"
    "aegis-team-build"
    "aegis-team-review"
    "aegis-team-debate"
    "aegis-doctor"
    "aegis-launch"
    "aegis-adr"
    "aegis-instinct"
    "aegis-distill"
    "aegis-evolve"
    "aegis-ingest"
    "aegis-lint"
    "aegis-compliance"
)

MISSING_SHIM=0
for cmd in "${SHIMS[@]}"; do
    f="${CMD_DIR}/${cmd}.md"
    if [[ ! -f "$f" ]]; then
        FAIL "TC-02 shim missing: ${cmd}.md"
        MISSING_SHIM=1
    elif ! grep -q "DEPRECATED" "$f" 2>/dev/null; then
        FAIL "TC-02 shim does not contain DEPRECATED: ${cmd}.md"
        MISSING_SHIM=1
    fi
done

# Also check reengineer (deprecation-only)
REFILE="${CMD_DIR}/aegis-reengineer.md"
if [[ ! -f "$REFILE" ]]; then
    FAIL "TC-02 reengineer shim missing"
    MISSING_SHIM=1
elif ! grep -q "DEPRECATED" "$REFILE" 2>/dev/null; then
    FAIL "TC-02 reengineer shim does not contain DEPRECATED"
    MISSING_SHIM=1
fi

if [[ $MISSING_SHIM -eq 0 ]]; then
    PASS "TC-02 all 17 shim files exist and contain DEPRECATED"
fi

# TC-03: Each shim references its canonical replacement
declare -a SHIM_CANONICAL_PAIRS
SHIM_CANONICAL_PAIRS=(
    "aegis-kanban:aegis-status"
    "aegis-dashboard:aegis-status"
    "aegis-context:aegis-status"
    "aegis-qa:aegis-pipeline"
    "aegis-flow:aegis-pipeline"
    "aegis-team-build:aegis-team"
    "aegis-team-review:aegis-team"
    "aegis-team-debate:aegis-team"
    "aegis-doctor:aegis-verify"
    "aegis-launch:aegis-deploy"
    "aegis-adr:aegis-memory"
    "aegis-instinct:aegis-memory"
    "aegis-distill:aegis-memory"
    "aegis-evolve:aegis-memory"
    "aegis-ingest:aegis-memory"
    "aegis-lint:aegis-memory"
    "aegis-compliance:aegis-memory"
)

BAD_REF=0
for pair in "${SHIM_CANONICAL_PAIRS[@]}"; do
    shim="${pair%%:*}"
    canonical="${pair##*:}"
    f="${CMD_DIR}/${shim}.md"
    if [[ -f "$f" ]] && ! grep -q "$canonical" "$f" 2>/dev/null; then
        FAIL "TC-03 ${shim}.md does not reference ${canonical}"
        BAD_REF=1
    fi
done
if [[ $BAD_REF -eq 0 ]]; then
    PASS "TC-03 all shims reference their canonical replacement"
fi

# TC-04: /aegis-team.md exists with build/review/debate subcommands
TEAM_FILE="${CMD_DIR}/aegis-team.md"
if [[ ! -f "$TEAM_FILE" ]]; then
    FAIL "TC-04 aegis-team.md missing"
else
    MISSING_SUB=0
    for sub in "build" "review" "debate"; do
        if ! grep -q "$sub" "$TEAM_FILE" 2>/dev/null; then
            FAIL "TC-04 aegis-team.md missing subcommand: $sub"
            MISSING_SUB=1
        fi
    done
    if [[ $MISSING_SUB -eq 0 ]]; then
        PASS "TC-04 aegis-team.md exists with build/review/debate subcommands"
    fi
fi

# TC-05: command-chain.md does not reference deprecated command names as primary entries
# Check that team-build, team-review, team-debate, aegis-qa (standalone), etc. are not
# listed as primary commands (they may appear in the deprecated table only)
CHAIN_VIOLATIONS=0
# These patterns in command-chain.md as PRIMARY entries (not in deprecated table) = violation
# We check that the old names only appear in the deprecated-shims table section
# by checking that lines before "Deprecated Commands" don't have old names as pipe entries
python3 - "$CHAIN_MD" <<'PYEOF' 2>/dev/null
import sys, re
with open(sys.argv[1]) as f:
    content = f.read()
# Split at deprecated section
parts = content.split('### Deprecated Commands')
primary_section = parts[0]
# Check that primary section does not reference old command names as primary entries
old_names = [
    '/aegis-team-build', '/aegis-team-review', '/aegis-team-debate',
    '/aegis-kanban', '/aegis-dashboard', '/aegis-context', '/aegis-doctor',
    '/aegis-launch', '/aegis-adr', '/aegis-instinct',
    '/aegis-distill', '/aegis-evolve', '/aegis-ingest', '/aegis-lint',
    '/aegis-compliance',
]
found = []
for name in old_names:
    # Look for table entries (lines with | name |) in primary section
    for line in primary_section.split('\n'):
        if name in line and '|' in line:
            found.append(name)
            break
if found:
    print('VIOLATIONS: ' + ', '.join(found))
    sys.exit(1)
else:
    sys.exit(0)
PYEOF
if [[ $? -eq 0 ]]; then
    PASS "TC-05 command-chain.md does not reference deprecated names as primary entries"
else
    FAIL "TC-05 command-chain.md references deprecated command names as primary entries"
fi

# TC-06: CLAUDE.md Quick Commands table has exactly 12 entries
TABLE_COUNT=$(python3 - "$CLAUDE_MD" <<'PYEOF' 2>/dev/null
import sys, re
with open(sys.argv[1]) as f:
    content = f.read()
# Find the Quick Commands table
m = re.search(r'## Quick Commands\n(.*?)(?=\n##|\Z)', content, re.DOTALL)
if not m:
    print(0)
    sys.exit(0)
table = m.group(1)
# Count pipe-delimited rows that look like command entries (start with | /)
count = 0
for line in table.split('\n'):
    stripped = line.strip()
    if stripped.startswith('|') and '/aegis-' in stripped and not stripped.startswith('| Command'):
        count += 1
print(count)
PYEOF
)
assert_eq "$TABLE_COUNT" "12" "TC-06 CLAUDE.md Quick Commands has exactly 12 entries"

# TC-07: No shim file exceeds 20 lines (they are stubs, not logic)
LONG_SHIMS=0
for cmd in "${SHIMS[@]}" "aegis-reengineer"; do
    f="${CMD_DIR}/${cmd}.md"
    if [[ -f "$f" ]]; then
        LINE_COUNT=$(wc -l < "$f" | tr -d ' ')
        if [[ "$LINE_COUNT" -gt 20 ]]; then
            FAIL "TC-07 ${cmd}.md too long: ${LINE_COUNT} lines (max 20)"
            LONG_SHIMS=1
        fi
    fi
done
if [[ $LONG_SHIMS -eq 0 ]]; then
    PASS "TC-07 all shim files are 20 lines or fewer"
fi

test_results
