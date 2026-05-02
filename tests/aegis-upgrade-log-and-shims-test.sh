#!/usr/bin/env bash
# aegis-upgrade-log-and-shims-test.sh — Regression tests for two follow-up
# defects of /aegis-upgrade surfaced in the RizzLab upgrade run.
#
# Bug #4 — post-install log entry never landed:
#   The wrapper wrote the activity-log entry AFTER `bash install.sh` returned.
#   When the wrapper is run from the target project's local copy of
#   tools/aegis-upgrade.sh (the common case), install.sh copies tools/*
#   from source to target — including this script — and bash may have
#   read only part of it into memory. The mid-flight overwrite can then
#   truncate execution, dropping any post-install step.
#   Fix: write the log entry BEFORE calling install.sh, so the audit
#   trail is preserved regardless of what install.sh does to the file.
#
# Bug #5 — install.sh tree-printout claimed shims still ship:
#   `install.sh:852` echoed
#       "└── commands/   # 12 canonical commands + 18 deprecation shims"
#   That was true pre-v10-05. v10-05 ("honest cleanup") removed the
#   legacy shims. The downstream install ends up with 13 canonical
#   commands and zero shims, but the printout still advertised 18 shims —
#   a doc/reality skew that misled the recent upgrade postmortem.
#   Fix: the line now says "13 canonical commands (legacy shims removed
#   in v10-05)".

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
UPGRADE_SH="${REPO_ROOT}/tools/aegis-upgrade.sh"
INSTALL_SH="${REPO_ROOT}/install.sh"

for f in "$UPGRADE_SH" "$INSTALL_SH"; do
  if [[ ! -f "$f" ]]; then
    echo "FATAL: cannot locate $f" >&2
    exit 2
  fi
done

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
PASS_COUNT=0
FAIL_COUNT=0
pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS_COUNT=$((PASS_COUNT+1)); }
fail() { echo -e "${RED}FAIL${NC}: $1 -- $2"; FAIL_COUNT=$((FAIL_COUNT+1)); }

TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/aegis-upgrade-followup-XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT INT TERM

echo "============================================"
echo "AEGIS upgrade -- log-ordering + shims regression"
echo "============================================"

# ────────────────────────────────────────────────────────────────────────
# Bug #4: log entry ordering
#
# Strategy: locate the line numbers of (a) the LOG-write block and
# (b) the bash install.sh invocation in tools/aegis-upgrade.sh. Assert
# (a) appears BEFORE (b). Also stub-run the entire log+install sequence
# under a fake install.sh that DELETES tools/aegis-upgrade.sh before
# returning — proving the log entry survives a mid-flight overwrite.
# ────────────────────────────────────────────────────────────────────────

echo ""
echo "--- Test 1: log-write block precedes install.sh invocation ---"
LOG_LINE=$(grep -nE '^LOG="\$TARGET_DIR/.aegis/brain/logs/activity.log"$' "$UPGRADE_SH" | head -1 | cut -d: -f1)
INSTALL_LINE=$(grep -nE '^[[:space:]]+bash "\$SOURCE_DIR/install.sh" --upgrade' "$UPGRADE_SH" | head -1 | cut -d: -f1)

if [[ -z "$LOG_LINE" || -z "$INSTALL_LINE" ]]; then
  fail "locate ordering markers" "LOG_LINE='$LOG_LINE' INSTALL_LINE='$INSTALL_LINE'"
elif [[ "$LOG_LINE" -lt "$INSTALL_LINE" ]]; then
  pass "LOG block (line $LOG_LINE) precedes install.sh call (line $INSTALL_LINE)"
else
  fail "log ordering" "LOG block at line $LOG_LINE NOT before install.sh at line $INSTALL_LINE"
fi

echo ""
echo "--- Test 2: log entry survives mid-flight overwrite of upgrade.sh ---"
# Build a minimal target with .aegis/brain/logs/activity.log
T="$TEST_DIR/target"
mkdir -p "$T/.aegis/brain/logs" "$T/.aegis/brain/resonance" "$T/.claude" "$T/tools"
echo "9.0" > "$T/AEGIS_VERSION"
echo "9.0" > "$T/VERSION"
echo "# stub CLAUDE.md for AEGIS validity check" > "$T/CLAUDE.md"
echo '{}' > "$T/.claude/settings.json"
touch "$T/.aegis/brain/logs/activity.log"
# Identity-file (markdown-bold form) so the wrapper builds EXTRA_ARGS
cat > "$T/.aegis/brain/resonance/project-identity.md" <<'IDENT'
# Project Identity
- **Name**: Test Target
- **Profile**: developer
IDENT

# Stub source repo with a malicious install.sh that overwrites the target's
# local tools/aegis-upgrade.sh (simulating the v10-05 → current behavior)
# and exits with TRUNCATED exit status to mimic mid-flight kill.
SRC="$TEST_DIR/src"
mkdir -p "$SRC/tools" "$SRC/.claude/agents" "$SRC/.claude/commands" "$SRC/.claude/hooks"
echo "9.0" > "$SRC/VERSION"
cp "$UPGRADE_SH" "$SRC/tools/aegis-upgrade.sh"
chmod +x "$SRC/tools/aegis-upgrade.sh"
# Required scaffolding for the wrapper's source-validity check + the
# wc -l pipelines that run under `set -e -o pipefail` (an empty glob
# expansion would trip pipefail).
touch "$SRC/.claude/agents/stub.md" \
      "$SRC/.claude/commands/stub.md" \
      "$SRC/.claude/hooks/stub.sh" \
      "$SRC/tools/stub.sh"
# Mirror the same scaffolding under the target so its `ls` calls also
# succeed under pipefail. Includes _aegis-output/iso-docs/<dir>/ which the
# wrapper greps for via `ls -d .../*/`.
mkdir -p "$T/.claude/agents" "$T/.claude/commands" "$T/.claude/hooks" \
         "$T/_aegis-output/iso-docs/stub-doc"
mkdir -p "$SRC/_aegis-output/iso-docs/stub-doc"
touch "$T/.claude/agents/stub.md" \
      "$T/.claude/commands/stub.md" \
      "$T/.claude/hooks/stub.sh" \
      "$T/tools/stub.sh"
cat > "$SRC/CLAUDE.md" <<'EOF'
# AEGIS test source
EOF
cat > "$SRC/install.sh" <<'INSTALL'
#!/usr/bin/env bash
# Stub install.sh: overwrite the target's tools/aegis-upgrade.sh (mimicking
# the real install.sh's behavior of copying tools/*) AND exit 0 so the
# wrapper does not propagate a failure code.
TARGET=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target-dir) TARGET="$2"; shift 2 ;;
    *) shift ;;
  esac
done
mkdir -p "$TARGET/tools"
# Write a clearly-different version into the target's tools/aegis-upgrade.sh
echo "#!/usr/bin/env bash" > "$TARGET/tools/aegis-upgrade.sh"
echo "echo OVERWRITTEN" >> "$TARGET/tools/aegis-upgrade.sh"
chmod +x "$TARGET/tools/aegis-upgrade.sh"
exit 0
INSTALL
chmod +x "$SRC/install.sh"

# Place a copy of the real wrapper at the target so we can run it AS IF
# we were the downstream project upgrading itself. AEGIS_SOURCE points the
# wrapper at our stub source.
cp "$UPGRADE_SH" "$T/tools/aegis-upgrade.sh"
chmod +x "$T/tools/aegis-upgrade.sh"

# Run the wrapper in --yes mode against the stub source.
RUN_OUT="$TEST_DIR/run.out"
RUN_ERR="$TEST_DIR/run.err"
( cd "$T" && AEGIS_SOURCE="$SRC" bash "$T/tools/aegis-upgrade.sh" --yes ) \
    >"$RUN_OUT" 2>"$RUN_ERR" || true

# Critical assertion: the activity-log MUST contain an [UPGRADE] entry,
# regardless of how cleanly the wrapper exited after install.sh.
if grep -q '\[UPGRADE\]' "$T/.aegis/brain/logs/activity.log"; then
  pass "[UPGRADE] log entry written even though install.sh overwrote upgrade.sh"
else
  fail "log survives overwrite" "no [UPGRADE] entry in $T/.aegis/brain/logs/activity.log
stdout=$(cat "$RUN_OUT" | tail -5)
stderr=$(cat "$RUN_ERR" | tail -5)"
fi

# Confirm the overwrite actually happened (sanity check on the test fixture)
if grep -q "echo OVERWRITTEN" "$T/tools/aegis-upgrade.sh"; then
  pass "stub install.sh did overwrite target's tools/aegis-upgrade.sh"
else
  fail "stub overwrite sanity" "target tools/aegis-upgrade.sh was NOT overwritten — test setup wrong"
fi

# ────────────────────────────────────────────────────────────────────────
# Bug #5: install.sh tree-printout no longer claims 18 deprecation shims
# ────────────────────────────────────────────────────────────────────────

echo ""
echo "--- Test 3: install.sh tree-printout no longer references shims ---"
# The stale claim. Should NOT appear anywhere in install.sh.
if grep -qE 'deprecation shims|18 deprecat|18 shims|12 canonical commands' "$INSTALL_SH"; then
  fail "stale shims comment" "install.sh still mentions 12 canonical / 18 shims:"
  grep -nE 'deprecation shims|18 deprecat|18 shims|12 canonical commands' "$INSTALL_SH"
else
  pass "install.sh has no '12 canonical / 18 deprecation shims' text"
fi

# Positive assertion: the new wording is present
if grep -qE 'legacy shims removed in v10-05' "$INSTALL_SH"; then
  pass "install.sh tree-printout mentions v10-05 cleanup"
else
  fail "new shims comment" "install.sh tree-printout missing the 'legacy shims removed in v10-05' note"
fi

# ────────────────────────────────────────────────────────────────────────
# Sanity: count of .claude/commands/ in the source matches the printout claim
# ────────────────────────────────────────────────────────────────────────

echo ""
echo "--- Test 4: command count on disk matches install.sh's claim ---"
ON_DISK=$(find "$REPO_ROOT/.claude/commands" -maxdepth 1 -name 'aegis-*.md' | wc -l | tr -d ' ')
CLAIMED=$(grep -oE '[0-9]+ canonical commands' "$INSTALL_SH" | head -1 | awk '{print $1}')
if [[ "$ON_DISK" == "$CLAIMED" ]]; then
  pass "$ON_DISK canonical commands on disk == $CLAIMED in install.sh printout"
else
  fail "command count drift" "on-disk=$ON_DISK install.sh-printout=$CLAIMED"
fi

echo ""
echo "============================================"
echo "RESULTS: ${PASS_COUNT} passed, ${FAIL_COUNT} failed"
echo "============================================"

if [[ $FAIL_COUNT -gt 0 ]]; then
  echo -e "${RED}AEGIS-UPGRADE FOLLOWUP TESTS: FAILURES${NC}"
  exit 1
fi
echo -e "${GREEN}AEGIS-UPGRADE FOLLOWUP TESTS: ALL PASSED${NC}"
exit 0
