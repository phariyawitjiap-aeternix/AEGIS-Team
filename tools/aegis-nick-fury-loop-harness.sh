#!/usr/bin/env bash
# aegis-nick-fury-loop-harness.sh (S2-07) -- Validates Nick Fury's decision
# loop infrastructure is wired correctly.
#
# This harness does NOT spawn a real Nick Fury agent (that requires Claude
# Code runtime). Instead, it validates the infrastructure that the decision
# loop depends on:
#   1. Decision audit log is writable and accepts entries
#   2. Judgment fallback counter works with flock atomicity
#   3. Team chat log is writable
#   4. Sprint state (plan + kanban) is readable
#   5. Brain directories exist and are structured
#   6. Decision source priority chain files exist
#   7. Activity log is writable
#   8. Heartbeat log is writable
#   9. Scan protocol inputs are accessible
#  10. Decision Matrix signals can be checked
#
# Exit codes:
#   0  All infrastructure checks pass
#   1  One or more checks fail
#
# Usage:
#   bash tools/aegis-nick-fury-loop-harness.sh [--verbose]
#
# Sprint: sprint-v9-06 / S2-07

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "${SCRIPT_DIR}/aegis-test-harness-template.sh"

VERBOSE=false
[[ "${1:-}" == "--verbose" ]] && VERBOSE=true

echo "=== S2-07: Nick Fury Decision Loop Infrastructure Harness ==="
echo ""

# ── 1. Decision audit log infrastructure ──────────────────────────────────

LOG_DIR="$REPO_ROOT/.aegis/brain/logs"
DECISION_LOG="$LOG_DIR/decision-audit.log"

# TC-01: Log directory exists
assert_file_exists "$REPO_ROOT/tools/aegis-log-decision.sh" "TC-01 aegis-log-decision.sh exists"

# TC-02: Decision log accepts an entry (use a test-specific session)
export CLAUDE_SESSION_ID="test-s2-07-$$"
_log_out=$(bash "$REPO_ROOT/tools/aegis-log-decision.sh" \
    --question "S2-07 harness validation" \
    --source "framework" \
    --confidence 1.0 \
    --answer "harness test entry" 2>&1) || true
if echo "$_log_out" | grep -q "logged D-"; then
    PASS "TC-02 decision log accepts entry"
else
    FAIL "TC-02 decision log did not accept entry: $_log_out"
fi

# TC-03: Entry appears in the log file
if [[ -f "$DECISION_LOG" ]] && tail -1 "$DECISION_LOG" | grep -q "S2-07 harness"; then
    PASS "TC-03 entry persisted to decision-audit.log"
else
    FAIL "TC-03 entry not found in decision-audit.log"
fi

# ── 2. Judgment fallback counter with flock ───────────────────────────────

# TC-04: Judgment source triggers counter (uses test session)
_j_out=$(bash "$REPO_ROOT/tools/aegis-log-decision.sh" \
    --question "S2-07 judgment test" \
    --source "judgment" \
    --confidence 0.5 \
    --answer "test" \
    --reasoning "harness validation" 2>&1) || true
COUNTER_FILE="$REPO_ROOT/.aegis/brain/metrics/judgment-fallback-counter.json"
if [[ -f "$COUNTER_FILE" ]]; then
    _jcount=$(python3 -c "import json; print(json.load(open('$COUNTER_FILE'))['judgment_count'])" 2>/dev/null || echo "0")
    if [[ "$_jcount" -gt 0 ]]; then
        PASS "TC-04 judgment counter incremented (count=$_jcount)"
    else
        FAIL "TC-04 judgment counter did not increment"
    fi
else
    FAIL "TC-04 judgment counter file not created"
fi

# TC-05: Counter file has .lock companion (flock evidence)
if [[ -f "${COUNTER_FILE}.lock" ]]; then
    PASS "TC-05 flock .lock file exists (atomicity evidence)"
else
    FAIL "TC-05 flock .lock file missing"
fi

# ── 3. Team chat log infrastructure ───────────────────────────────────────

# TC-06: Team chat tool exists
assert_file_exists "$REPO_ROOT/tools/aegis-team-chat.sh" "TC-06 aegis-team-chat.sh exists"

# TC-07: Team chat accepts a log entry
_chat_out=$(bash "$REPO_ROOT/tools/aegis-team-chat.sh" \
    --from "nick-fury" \
    --to "harness" \
    --type "NOTE" \
    --msg "S2-07 validation" 2>&1) || true
# Team chat outputs the formatted message on success; check for our content
if echo "$_chat_out" | grep -q "S2-07 validation"; then
    PASS "TC-07 team-chat tool ran successfully"
else
    FAIL "TC-07 team-chat did not produce expected output: $_chat_out"
fi

# ── 4. Sprint state readability ───────────────────────────────────────────

SPRINT_DIR="$REPO_ROOT/.aegis/brain/sprints/current"

# TC-08: Current sprint symlink/dir exists
if [[ -d "$SPRINT_DIR" ]] || [[ -L "$SPRINT_DIR" ]]; then
    PASS "TC-08 current sprint dir/symlink exists"
else
    FAIL "TC-08 current sprint dir missing at $SPRINT_DIR"
fi

# TC-09: Sprint plan is readable
if [[ -f "$SPRINT_DIR/plan.md" ]] && [[ -s "$SPRINT_DIR/plan.md" ]]; then
    PASS "TC-09 sprint plan.md exists and is non-empty"
else
    FAIL "TC-09 sprint plan.md missing or empty"
fi

# TC-10: Kanban board is readable
if [[ -f "$SPRINT_DIR/kanban.md" ]] && [[ -s "$SPRINT_DIR/kanban.md" ]]; then
    PASS "TC-10 kanban.md exists and is non-empty"
else
    FAIL "TC-10 kanban.md missing or empty"
fi

# ── 5. Brain directory structure ──────────────────────────────────────────

BRAIN="$REPO_ROOT/.aegis/brain"

# TC-11: Core brain directories exist
_brain_ok=true
for d in logs metrics resonance learnings instincts handoffs retrospectives sprints state; do
    if [[ ! -d "$BRAIN/$d" ]]; then
        [[ "$VERBOSE" == true ]] && echo "    missing: $BRAIN/$d"
        _brain_ok=false
    fi
done
if [[ "$_brain_ok" == true ]]; then
    PASS "TC-11 all 9 core brain directories exist"
else
    FAIL "TC-11 one or more brain directories missing"
fi

# ── 6. Decision source priority chain ─────────────────────────────────────

# TC-12: Promoted instincts directory exists
if [[ -d "$BRAIN/instincts/promoted" ]]; then
    PASS "TC-12 promoted instincts dir exists"
else
    FAIL "TC-12 promoted instincts dir missing"
fi

# TC-13: Resonance directory has project-identity
if [[ -f "$BRAIN/resonance/project-identity.md" ]]; then
    PASS "TC-13 project-identity.md exists in resonance"
else
    FAIL "TC-13 project-identity.md missing"
fi

# TC-14: Architecture decisions file exists (ADR chain)
if [[ -f "$BRAIN/resonance/architecture-decisions.md" ]]; then
    PASS "TC-14 architecture-decisions.md exists"
else
    FAIL "TC-14 architecture-decisions.md missing"
fi

# ── 7. Activity log writability ───────────────────────────────────────────

ACTIVITY_LOG="$LOG_DIR/activity.log"

# TC-15: Activity log directory is writable
_test_line="[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [HARNESS:S2-07] infrastructure validation"
echo "$_test_line" >> "$ACTIVITY_LOG" 2>/dev/null
if tail -1 "$ACTIVITY_LOG" 2>/dev/null | grep -q "HARNESS:S2-07"; then
    PASS "TC-15 activity.log is writable"
else
    FAIL "TC-15 activity.log not writable"
fi

# ── 8. Heartbeat log writability ──────────────────────────────────────────

HB_LOG="$LOG_DIR/heartbeat.log"

# TC-16: Heartbeat log accepts entry
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [HARNESS:S2-07] heartbeat test" >> "$HB_LOG" 2>/dev/null
if tail -1 "$HB_LOG" 2>/dev/null | grep -q "HARNESS:S2-07"; then
    PASS "TC-16 heartbeat.log is writable"
else
    FAIL "TC-16 heartbeat.log not writable"
fi

# ── 9. Scan protocol inputs ──────────────────────────────────────────────

# TC-17: Git is available (scan needs git status)
if git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    PASS "TC-17 git repo is accessible for scan"
else
    FAIL "TC-17 not inside a git repo"
fi

# TC-18: Roadmap exists (progress tracking)
if [[ -f "$BRAIN/sprints/roadmap.md" ]]; then
    PASS "TC-18 roadmap.md exists for progress tracking"
else
    FAIL "TC-18 roadmap.md missing"
fi

# ── 10. Decision Matrix signal checks ────────────────────────────────────

# TC-19: Progress tool exists
assert_file_exists "$REPO_ROOT/tools/aegis-progress.sh" "TC-19 aegis-progress.sh exists"

# TC-20: CLAUDE.md exists (Nick Fury's reference doc)
assert_file_exists "$REPO_ROOT/CLAUDE.md" "TC-20 CLAUDE.md exists"

echo ""
test_results
