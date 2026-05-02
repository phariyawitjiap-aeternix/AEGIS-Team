#!/usr/bin/env bash
# install-copy-subdirs-test.sh — Regression test for install.sh copy_dir_contents
#
# Bug surfaced after the RizzLab upgrade: every Claude Code Stop hook in
# downstream projects errored with
#     .claude/hooks/lib/quality-check.sh: No such file or directory
# because install.sh's copy_dir_contents iterates `$src_dir/*` and skips
# anything that's not a regular file. The hooks/lib/ subdirectory (which
# carries quality-check, mbp-scan, false-ready, queue-banner) therefore
# never reached downstream projects — even though on-stop.sh sources
# those files directly.
#
# Fix: copy_dir_contents now also recursively copies subdirectories.
#
# This test extracts the live function from install.sh, runs it against a
# tmpdir source that contains both top-level files AND a `lib/` subdir
# with sub-files, and asserts the destination ends up with both.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_SH="${SCRIPT_DIR}/../install.sh"

if [[ ! -f "$INSTALL_SH" ]]; then
  echo "FATAL: cannot locate install.sh at $INSTALL_SH" >&2
  exit 2
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
PASS_COUNT=0
FAIL_COUNT=0
pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS_COUNT=$((PASS_COUNT+1)); }
fail() { echo -e "${RED}FAIL${NC}: $1 -- $2"; FAIL_COUNT=$((FAIL_COUNT+1)); }

TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/install-copy-subdirs-XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT INT TERM

echo "============================================"
echo "install.sh copy_dir_contents subdir regression"
echo "============================================"

# Extract the live copy_dir_contents() function (start through closing brace
# at column 1). Stop at the next blank line — works for the current shape.
EXTRACT=$(awk '
  /^copy_dir_contents\(\) {/ { capture=1 }
  capture                     { print }
  capture && /^}$/            { exit }
' "$INSTALL_SH")

if [[ -z "$EXTRACT" ]]; then
  fail "extract copy_dir_contents" "could not find the function in install.sh"
  echo "RESULTS: $PASS_COUNT passed, $FAIL_COUNT failed"
  exit 1
fi

# Build a source tree that mirrors meta's hooks/ shape:
#   src_hooks/
#     on-stop.sh                   ← top-level file
#     guard-bash.sh                ← top-level file
#     lib/                          ← subdirectory
#       quality-check.sh
#       mbp-scan.sh
SRC="$TEST_DIR/src_hooks"
DST="$TEST_DIR/dst_hooks"
mkdir -p "$SRC/lib" "$DST"
echo "echo on-stop"      > "$SRC/on-stop.sh"
echo "echo guard-bash"   > "$SRC/guard-bash.sh"
echo "echo quality"      > "$SRC/lib/quality-check.sh"
echo "echo mbp-scan"     > "$SRC/lib/mbp-scan.sh"

# Stub the helpers the function uses (success/warn) so the extracted
# function runs standalone.
RUN_OUT="$TEST_DIR/run.out"
bash -c "
  set -uo pipefail
  warn()    { echo \"WARN: \$*\"; }
  success() { echo \"OK: \$*\"; }
  $EXTRACT
  copy_dir_contents '$SRC' '$DST' 'hooks'
" >"$RUN_OUT" 2>&1

# ────────────────────────────────────────────────────────────────────────
# Test 1: top-level files copied
# ────────────────────────────────────────────────────────────────────────
echo ""
echo "--- Test 1: top-level files copied ---"
if [[ -f "$DST/on-stop.sh" && -f "$DST/guard-bash.sh" ]]; then
  pass "on-stop.sh and guard-bash.sh copied to dst"
else
  fail "top-level files" "missing in dst (on-stop.sh exists=$(test -f "$DST/on-stop.sh" && echo y || echo n), guard-bash.sh exists=$(test -f "$DST/guard-bash.sh" && echo y || echo n))"
fi

# ────────────────────────────────────────────────────────────────────────
# Test 2: lib/ subdirectory and its files copied (THE regression target)
# ────────────────────────────────────────────────────────────────────────
echo ""
echo "--- Test 2: lib/ subdirectory copied recursively ---"
if [[ -f "$DST/lib/quality-check.sh" && -f "$DST/lib/mbp-scan.sh" ]]; then
  pass "lib/quality-check.sh and lib/mbp-scan.sh copied to dst"
else
  fail "subdirectory copy" "missing files: quality-check exists=$(test -f "$DST/lib/quality-check.sh" && echo y || echo n), mbp-scan exists=$(test -f "$DST/lib/mbp-scan.sh" && echo y || echo n)"
fi

# ────────────────────────────────────────────────────────────────────────
# Test 3: file contents preserved through the copy
# ────────────────────────────────────────────────────────────────────────
echo ""
echo "--- Test 3: subdir file contents intact ---"
if [[ "$(cat "$DST/lib/quality-check.sh" 2>/dev/null)" == "echo quality" ]]; then
  pass "lib/quality-check.sh contents preserved"
else
  fail "contents preserved" "got=$(cat "$DST/lib/quality-check.sh" 2>/dev/null) expected='echo quality'"
fi

# ────────────────────────────────────────────────────────────────────────
# Test 4: success message reports the subdirectory count
# ────────────────────────────────────────────────────────────────────────
echo ""
echo "--- Test 4: success message reports +1 subdirectory ---"
if grep -qE 'OK:.*hooks installed.*1 subdirector' "$RUN_OUT"; then
  pass "success message includes subdirectory count"
else
  fail "success message" "expected '+1 subdirectories' in: $(cat "$RUN_OUT" | tail -3)"
fi

# ────────────────────────────────────────────────────────────────────────
# Test 5: missing source directory still warns and returns cleanly
# ────────────────────────────────────────────────────────────────────────
echo ""
echo "--- Test 5: missing source directory handled cleanly ---"
MISSING_OUT="$TEST_DIR/missing.out"
bash -c "
  set -uo pipefail
  warn()    { echo \"WARN: \$*\"; }
  success() { echo \"OK: \$*\"; }
  $EXTRACT
  copy_dir_contents '$TEST_DIR/does-not-exist' '$DST' 'phantom'
" >"$MISSING_OUT" 2>&1
if grep -q "WARN: Source directory not found" "$MISSING_OUT"; then
  pass "missing source dir produces a warn, not an error"
else
  fail "missing source dir" "expected warn, got: $(cat "$MISSING_OUT")"
fi

echo ""
echo "============================================"
echo "RESULTS: ${PASS_COUNT} passed, ${FAIL_COUNT} failed"
echo "============================================"

if [[ $FAIL_COUNT -gt 0 ]]; then
  echo -e "${RED}INSTALL COPY-SUBDIRS TESTS: FAILURES${NC}"
  exit 1
fi
echo -e "${GREEN}INSTALL COPY-SUBDIRS TESTS: ALL PASSED${NC}"
exit 0
