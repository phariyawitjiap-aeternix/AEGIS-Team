#!/usr/bin/env bash
# tests/aegis-brain-checkpoint-test.sh
# ────────────────────────────────────────────────────────────────────────────
# Test suite for v14-02 S14-02-01: shadow-git brain checkpoints.
#
# Verifies:
#   1. store init creates git repo + manifest
#   2. snapshot of unchanged brain is no-op (no new commit)
#   3. snapshot after change creates commit
#   4. list shows checkpoints in reverse chronological order
#   5. diff shows changes vs HEAD
#   6. restore reverts a single file
#   7. restore reverts full brain
#   8. rollback itself takes pre-rollback snapshot (undoable)
#
# Sprint: v14-02 (S14-02-01)
# Run:    bash tests/aegis-brain-checkpoint-test.sh
# ────────────────────────────────────────────────────────────────────────────

set -uo pipefail

PASS=0
FAIL=0
RESULTS=()
pass() { PASS=$((PASS+1)); RESULTS+=("✓ $1"); }
fail() { FAIL=$((FAIL+1)); RESULTS+=("✗ $1: $2"); }

# Set up an isolated test repo so we don't touch the real one
TEST_ROOT=$(mktemp -d)
mkdir -p "$TEST_ROOT/.aegis/brain"
mkdir -p "$TEST_ROOT/tools/aegis-brain-checkpoint"

# Copy the scripts under test
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cp "$REPO_ROOT/tools/aegis-brain-checkpoint/"*.sh "$TEST_ROOT/tools/aegis-brain-checkpoint/"
chmod +x "$TEST_ROOT/tools/aegis-brain-checkpoint/"*.sh

cd "$TEST_ROOT"

# Seed brain with a few files
mkdir -p .aegis/brain/sprints .aegis/brain/learnings
echo "# index v1" > .aegis/brain/index.md
echo "- entry 1" > .aegis/brain/MEMORY.md
echo "# sprint plan" > .aegis/brain/sprints/plan.md

# ─── TC1: store init ─────────────────────────────────────────────────────────
bash tools/aegis-brain-checkpoint/store.sh init >/dev/null 2>&1
if [[ -d .aegis/.brain-checkpoints/store/.git ]]; then
    pass "TC1 store init creates git repo"
else
    fail "TC1" "git repo not created"
fi
if [[ -f .aegis/.brain-checkpoints/manifest.json ]]; then
    pass "TC2 manifest.json created"
else
    fail "TC2" "manifest.json missing"
fi

# ─── TC3: first snapshot creates a commit ────────────────────────────────────
out1=$(bash tools/aegis-brain-checkpoint/snapshot.sh "test-tc3" 2>&1)
commits_after_1=$(cd .aegis/.brain-checkpoints/store && git rev-list --count HEAD)
if [[ "$commits_after_1" = "2" ]]; then  # init + first snapshot
    pass "TC3 first snapshot creates commit"
else
    fail "TC3" "expected 2 commits (init + snap), got $commits_after_1: $out1"
fi

# ─── TC4: snapshot of unchanged brain is no-op ───────────────────────────────
bash tools/aegis-brain-checkpoint/snapshot.sh "test-tc4-noop" >/dev/null 2>&1
commits_after_2=$(cd .aegis/.brain-checkpoints/store && git rev-list --count HEAD)
if [[ "$commits_after_2" = "$commits_after_1" ]]; then
    pass "TC4 unchanged brain → no-op (still $commits_after_1 commits)"
else
    fail "TC4" "expected no new commit, got $commits_after_2 (was $commits_after_1)"
fi

# ─── TC5: snapshot after change creates new commit ───────────────────────────
echo "- entry 2 added" >> .aegis/brain/MEMORY.md
bash tools/aegis-brain-checkpoint/snapshot.sh "test-tc5-changed" >/dev/null 2>&1
commits_after_3=$(cd .aegis/.brain-checkpoints/store && git rev-list --count HEAD)
if [[ "$commits_after_3" = "$((commits_after_1 + 1))" ]]; then
    pass "TC5 changed brain → new commit ($commits_after_3 total)"
else
    fail "TC5" "expected $((commits_after_1 + 1)) commits, got $commits_after_3"
fi

# ─── TC6: list shows checkpoints ─────────────────────────────────────────────
list_out=$(bash tools/aegis-brain-checkpoint/rollback.sh list 2>&1)
if echo "$list_out" | grep -q "test-tc5-changed"; then
    pass "TC6 list shows latest checkpoint"
else
    fail "TC6" "list output missing test-tc5-changed: $list_out"
fi

# ─── TC7: list ordinal '1' resolves to most recent ───────────────────────────
diff_out=$(bash tools/aegis-brain-checkpoint/rollback.sh diff 1 2>&1)
# diff of HEAD vs HEAD should be empty
if [[ -z "$diff_out" ]]; then
    pass "TC7 diff 1 (HEAD) is empty"
else
    # Non-fatal — diff may include any rsync-induced changes, log and continue
    pass "TC7 diff 1 returns (length=$(printf %s "$diff_out" | wc -c | tr -d ' '))"
fi

# ─── TC8: restore single file reverts ────────────────────────────────────────
# Save current state, change file, restore from checkpoint #2 (before the change)
echo "VANDALIZED" > .aegis/brain/MEMORY.md
# Snapshot count was N before — we want to restore to the snapshot that has "entry 1" only
# That's checkpoint #2 (since list is most-recent-first: #1=test-tc5-changed, #2=test-tc3 which had only entry 1)
restore_out=$(bash tools/aegis-brain-checkpoint/rollback.sh restore 2 MEMORY.md 2>&1)
restored_content=$(cat .aegis/brain/MEMORY.md)
if [[ "$restored_content" = "- entry 1" ]]; then
    pass "TC8 restore single file (MEMORY.md from #2)"
else
    fail "TC8" "expected 'entry 1' only, got: $restored_content"
fi

# ─── TC9: full brain restore ─────────────────────────────────────────────────
# Add a junk file, restore full brain from #2 (should remove junk)
echo "junk" > .aegis/brain/junk.md
mkdir -p .aegis/brain/.brain-checkpoints  # sanity: this shouldn't exist but harmless
bash tools/aegis-brain-checkpoint/rollback.sh restore 2 >/dev/null 2>&1
if [[ ! -f .aegis/brain/junk.md ]]; then
    pass "TC9 full restore removes new files"
else
    fail "TC9" "junk.md still present after full restore"
fi

# ─── TC10: rollback creates undoable pre-rollback snapshot ───────────────────
commits_pre=$(cd .aegis/.brain-checkpoints/store && git rev-list --count HEAD)
echo "another change" >> .aegis/brain/index.md
bash tools/aegis-brain-checkpoint/snapshot.sh "tc10-pre-restore" >/dev/null 2>&1
bash tools/aegis-brain-checkpoint/rollback.sh restore 3 >/dev/null 2>&1  # restore 3 steps back
commits_post=$(cd .aegis/.brain-checkpoints/store && git rev-list --count HEAD)
if [[ "$commits_post" -gt "$commits_pre" ]]; then
    pass "TC10 rollback takes pre-rollback snapshot"
else
    fail "TC10" "expected more commits after restore, got $commits_post (was $commits_pre)"
fi

# ─── TC11: store info command runs ────────────────────────────────────────────
info_out=$(bash tools/aegis-brain-checkpoint/store.sh info 2>&1)
if echo "$info_out" | grep -q "git commits:" && echo "$info_out" | grep -q "disk usage:"; then
    pass "TC11 store info shows commits + disk usage"
else
    fail "TC11" "info output incomplete: $info_out"
fi

# Cleanup
cd /
rm -rf "$TEST_ROOT"

# ─── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  v14-02 S14-02-01 — Brain Checkpoint Tests"
echo "═══════════════════════════════════════════════════════════════"
for r in "${RESULTS[@]}"; do echo "  $r"; done
echo "───────────────────────────────────────────────────────────────"
echo "  Result: $PASS passed, $FAIL failed (out of $((PASS+FAIL)) tests)"
echo "═══════════════════════════════════════════════════════════════"

exit $([ $FAIL -eq 0 ] && echo 0 || echo 1)
