#!/usr/bin/env bash
# test-f2-01-command-shims.sh — Tests for F2-01 command consolidation 29→12
# Updated v10-05: shims are now REMOVED, tests verify they are gone.
# Bash 3.2 compatible.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/aegis-test-harness-template.sh"

CMD_DIR="${SCRIPT_DIR}/../.claude/commands"
CLAUDE_MD="${SCRIPT_DIR}/../CLAUDE.md"
CHAIN_MD="${SCRIPT_DIR}/../.claude/references/command-chain.md"

echo "=== F2-01: Command Consolidation 29→12 (v10-05: shims removed) ==="
echo ""

# TC-01: All 16 canonical command files exist and are non-empty.
# (Was 12; goal/decisions/linear added post-v10-05, upgrade promoted into the
# user-facing surface — see CLAUDE.md "## Quick Commands" 5 user + 11 team = 16.)
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
    "aegis-upgrade"
    "aegis-goal"
    "aegis-decisions"
    "aegis-linear"
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

# TC-02: All 18 deprecated shim files are REMOVED (v10-05)
REMOVED_SHIMS=(
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
    "aegis-reengineer"
)

STALE_SHIM=0
for cmd in "${REMOVED_SHIMS[@]}"; do
    f="${CMD_DIR}/${cmd}.md"
    if [[ -f "$f" ]]; then
        FAIL "TC-02 shim still exists (should be removed): ${cmd}.md"
        STALE_SHIM=1
    fi
done
if [[ $STALE_SHIM -eq 0 ]]; then
    PASS "TC-02 all 18 deprecated shim files confirmed removed"
fi

# TC-03: Only canonical command files remain in commands dir
TOTAL_CMD_FILES=$(find "$CMD_DIR" -name "aegis-*.md" -type f | wc -l | tr -d ' ')
# CANONICALS now lists all 16 (incl. aegis-upgrade) — no +1 fudge needed.
EXPECTED_MAX=${#CANONICALS[@]}
if [[ "$TOTAL_CMD_FILES" -le "$EXPECTED_MAX" ]]; then
    PASS "TC-03 commands dir has only canonical files (${TOTAL_CMD_FILES} found, max ${EXPECTED_MAX})"
else
    FAIL "TC-03 unexpected files in commands dir: found ${TOTAL_CMD_FILES}, expected <= ${EXPECTED_MAX}"
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

# TC-05: command-chain.md documents shim removal
if grep -q "removed v10-05" "$CHAIN_MD" 2>/dev/null; then
    PASS "TC-05 command-chain.md documents shim removal"
else
    FAIL "TC-05 command-chain.md does not document shim removal"
fi

# TC-06: CLAUDE.md "## Quick Commands" section lists exactly 16 commands.
# (Restructured into "### User-facing (5)" + "### Team-facing (11)" subsections.
# The section-capture lookahead must stop at the next LEVEL-2 heading "\n## "
# — NOT at the "### " subsections, or it would capture only the intro blockquote
# and count 0.)
TABLE_COUNT=$(python3 - "$CLAUDE_MD" <<'PYEOF' 2>/dev/null
import sys, re
with open(sys.argv[1]) as f:
    content = f.read()
m = re.search(r'## Quick Commands\n(.*?)(?=\n## |\Z)', content, re.DOTALL)
if not m:
    print(0)
    sys.exit(0)
table = m.group(1)
count = 0
for line in table.split('\n'):
    stripped = line.strip()
    if stripped.startswith('|') and '/aegis-' in stripped and not stripped.startswith('| Command'):
        count += 1
print(count)
PYEOF
)
assert_eq "$TABLE_COUNT" "16" "TC-06 CLAUDE.md Quick Commands has exactly 16 entries (5 user + 11 team)"

# TC-07: CLAUDE.md no longer references "17 legacy aliases"
if grep -q "17 legacy aliases" "$CLAUDE_MD" 2>/dev/null; then
    FAIL "TC-07 CLAUDE.md still references '17 legacy aliases'"
else
    PASS "TC-07 CLAUDE.md shim reference updated"
fi

# TC-08: No archived agents directory exists
ARCHIVED_DIR="${SCRIPT_DIR}/../.claude/agents/_archived"
if [[ -d "$ARCHIVED_DIR" ]]; then
    FAIL "TC-08 _archived/ agent directory still exists"
else
    PASS "TC-08 _archived/ agent directory confirmed removed"
fi

test_results
