#!/usr/bin/env bash
# aegis-upgrade-identity-test.sh — Regression tests for identity-file
# extraction in tools/aegis-upgrade.sh
#
# Two bugs surfaced by /aegis-upgrade --yes against a downstream project
# whose .aegis/brain/resonance/project-identity.md uses markdown-bold rows
# (e.g. "- **Name**: Rizz Lab") and whose project name contains spaces:
#
#   Bug A (markdown-bold mismatch):
#     The original regex `^- *name:|^Name:` did not match `- **Name**:`.
#     Combined with `set -o pipefail`, grep returning no match killed the
#     whole pipeline and the upgrade aborted with no useful message.
#
#   Bug B (multi-word project name):
#     `PROJECT_ARG="--project-name $NAME"` passed unquoted to install.sh:
#         bash install.sh --upgrade --target-dir "$DIR" $PROFILE_ARG $PROJECT_ARG
#     With NAME="Rizz Lab", word-splitting turned it into
#         ... --project-name Rizz Lab
#     and install.sh died with `Unknown option: Lab`.
#
# Fix:
#   - Regex extended to tolerate `- **Name**:` / `- **Profile**:` markdown-bold
#   - Args switched to a bash array so multi-word values survive expansion
#   - `|| true` / `${VAR:-}` defaults absorb empty-grep + set -e/pipefail
#
# This test extracts the live identity-extraction block from the script,
# stubs install.sh to capture argv, and asserts the wrapper passes the right
# args for both plain and markdown-bold identity files, including multi-word
# names.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
UPGRADE_SH="${SCRIPT_DIR}/../tools/aegis-upgrade.sh"

if [[ ! -f "$UPGRADE_SH" ]]; then
  echo "FATAL: cannot locate aegis-upgrade.sh at $UPGRADE_SH" >&2
  exit 2
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
PASS_COUNT=0
FAIL_COUNT=0
pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS_COUNT=$((PASS_COUNT+1)); }
fail() { echo -e "${RED}FAIL${NC}: $1 -- $2"; FAIL_COUNT=$((FAIL_COUNT+1)); }

TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/aegis-upgrade-identity-XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT INT TERM

echo "============================================"
echo "AEGIS upgrade -- identity-extraction regression"
echo "============================================"

# Extract just the identity-extraction block: from `EXTRA_ARGS=()` through
# the closing `fi` of the if-isfile guard. We do NOT include the
# `info "Running:" ...` line that follows — it references $SOURCE_DIR which
# is not set up in the unit-test harness for tests 1-3, 5, 6.
EXTRACT_BLOCK=$(awk '
  /^EXTRA_ARGS=\(\)/  { capture=1 }
  capture             { print }
  capture && /^fi$/   { exit }
' "$UPGRADE_SH")

# Extract from EXTRA_ARGS=() through the install.sh bash call (closing `fi`
# of the if/else block that branches on EXTRA_ARGS length). This is what
# Test 4 exercises — a regression guard against any rewrite that
# re-introduces unquoted/string args.
#
# Stops at the third `fi` because the script structure is now:
#   1st fi — closes `if [[ -f "$IDFILE" ]]; then ... fi` (identity extraction)
#   2nd fi — closes `if [[ -f "$LOG" ]]; then ... fi`     (pre-install log)
#   3rd fi — closes `if [[ ${#EXTRA_ARGS[@]} -gt 0 ]]`    (install.sh call)
EXTRACT_FULL=$(awk '
  /^EXTRA_ARGS=\(\)/                      { capture=1; n_fi=0 }
  capture                                  { print }
  capture && /^fi$/                        { n_fi++; if (n_fi == 3) exit }
' "$UPGRADE_SH")

if [[ -z "$EXTRACT_BLOCK" ]]; then
  fail "extract identity block" "could not locate EXTRA_ARGS=()...info block in upgrade.sh"
  echo "RESULTS: $PASS_COUNT passed, $FAIL_COUNT failed"
  exit 1
fi

# Helper: write an identity file, run the extracted block under a fake
# TARGET_DIR, then echo the resulting EXTRA_ARGS array as a tab-separated
# string. We compare this string against what we expect.
run_extraction() {
  local target_dir="$1"
  bash -c "
    set -euo pipefail
    TARGET_DIR='$target_dir'
    $EXTRACT_BLOCK
    # Print one element per line. Guard \"\${EXTRA_ARGS[@]}\" with a length
    # check — bash 3.2 (macOS) errors on empty array expansion under set -u.
    if [[ \${#EXTRA_ARGS[@]} -gt 0 ]]; then
      for a in \"\${EXTRA_ARGS[@]}\"; do
        printf '%s\n' \"\$a\"
      done
    fi
  "
}

mk_target() {
  local dir="$1" body="$2"
  mkdir -p "$dir/.aegis/brain/resonance"
  printf '%s\n' "$body" > "$dir/.aegis/brain/resonance/project-identity.md"
}

# ────────────────────────────────────────────────────────────────────────
# Test 1: plain "- name:" / "- profile:" — historical happy path
# ────────────────────────────────────────────────────────────────────────
echo ""
echo "--- Test 1: plain identity rows ---"
T1="$TEST_DIR/plain"
mk_target "$T1" "- name: simple
- profile: developer"
out=$(run_extraction "$T1")
expected=$'--project-name\nsimple\n--profile\ndeveloper'
if [[ "$out" == "$expected" ]]; then
  pass "plain rows produce --project-name simple --profile developer"
else
  fail "plain rows" "got=$(printf '%q' "$out") expected=$(printf '%q' "$expected")"
fi

# ────────────────────────────────────────────────────────────────────────
# Test 2: markdown-bold "- **Name**:" / "- **Profile**:" (Bug A)
# ────────────────────────────────────────────────────────────────────────
echo ""
echo "--- Test 2: markdown-bold rows (Bug A) ---"
T2="$TEST_DIR/bold"
mk_target "$T2" "- **Name**: BoldProject
- **Profile**: developer"
out=$(run_extraction "$T2")
expected=$'--project-name\nBoldProject\n--profile\ndeveloper'
if [[ "$out" == "$expected" ]]; then
  pass "markdown-bold rows extract correctly"
else
  fail "markdown-bold rows" "got=$(printf '%q' "$out") expected=$(printf '%q' "$expected")"
fi

# ────────────────────────────────────────────────────────────────────────
# Test 3: multi-word project name "Rizz Lab" (Bug B)
# Ensures the wrapper produces ONE array element "Rizz Lab", not two.
# ────────────────────────────────────────────────────────────────────────
echo ""
echo "--- Test 3: multi-word project name (Bug B) ---"
T3="$TEST_DIR/multiword"
mk_target "$T3" "- **Name**: Rizz Lab
- **Profile**: developer"
out=$(run_extraction "$T3")
expected=$'--project-name\nRizz Lab\n--profile\ndeveloper'
if [[ "$out" == "$expected" ]]; then
  pass "multi-word project name preserved as single argument"
else
  fail "multi-word project name" "got=$(printf '%q' "$out") expected=$(printf '%q' "$expected")"
fi

# ────────────────────────────────────────────────────────────────────────
# Test 4: end-to-end argv check — run a stubbed install.sh via the live
# script wrapper and assert the stub sees the right argv.
# ────────────────────────────────────────────────────────────────────────
echo ""
echo "--- Test 4: install.sh stub receives correct argv (multi-word) ---"
T4="$TEST_DIR/e2e"
mk_target "$T4" "- **Name**: Rizz Lab
- **Profile**: developer"
# Pretend the target has the minimum scaffolding the wrapper checks for.
mkdir -p "$T4/.claude" "$T4/.aegis/brain/logs"
echo '{}' > "$T4/.claude/settings.json"
touch "$T4/.aegis/brain/logs/activity.log"

# Build a fake source dir with a stub install.sh that captures argv.
SRC="$TEST_DIR/src"
mkdir -p "$SRC"
cat > "$SRC/install.sh" <<'STUB'
#!/usr/bin/env bash
# Stub install.sh: capture argv, exit 0, do not modify anything.
printf '%s\n' "$@" > "$ARGV_FILE"
STUB
chmod +x "$SRC/install.sh"

# Run the FULL extracted block — array build AND the bash invocation
# of install.sh — under stubs. This is the regression guard for Bug B:
# if anyone reverts the array-based call to unquoted strings, the stub
# will see "Rizz" + "Lab" as separate argv elements and the test fails.
# We also stub `info` since it's defined elsewhere in the script.
ARGV_FILE="$TEST_DIR/argv.out"
bash -c "
  set -euo pipefail
  export ARGV_FILE='$ARGV_FILE'
  TARGET_DIR='$T4'
  SOURCE_DIR='$SRC'
  # The extracted block now includes the pre-install log step which
  # references TARGET_AEGIS_VER and SOURCE_VERSION. Stub them so set -u
  # is happy; values don't matter for argv assertion.
  TARGET_AEGIS_VER='9.0'
  SOURCE_VERSION='9.0'
  info() { :; }   # stub
  $EXTRACT_FULL
" >/dev/null 2>"$TEST_DIR/e2e.err"
e2e_exit=$?

if [[ $e2e_exit -ne 0 ]]; then
  fail "e2e stubbed install.sh" "exit=$e2e_exit stderr=$(cat "$TEST_DIR/e2e.err")"
elif [[ ! -f "$ARGV_FILE" ]]; then
  fail "e2e stubbed install.sh" "stub never wrote argv file"
else
  argv_seen=$(cat "$ARGV_FILE")
  expected_argv=$'--upgrade\n--target-dir\n'"$T4"$'\n--project-name\nRizz Lab\n--profile\ndeveloper'
  if [[ "$argv_seen" == "$expected_argv" ]]; then
    pass "install.sh stub received --project-name 'Rizz Lab' as ONE argument"
  else
    fail "e2e argv" "got=$(printf '%q' "$argv_seen") expected=$(printf '%q' "$expected_argv")"
  fi
fi

# ────────────────────────────────────────────────────────────────────────
# Test 5: missing identity file is tolerated (set -e + pipefail safe)
# ────────────────────────────────────────────────────────────────────────
echo ""
echo "--- Test 5: missing identity file does not abort ---"
T5="$TEST_DIR/missing"
mkdir -p "$T5/.aegis/brain/resonance"  # dir exists, file does not
out=$(run_extraction "$T5" 2>"$TEST_DIR/missing.err") || true
err=$(cat "$TEST_DIR/missing.err")
# Empty output is fine — we just need no shell error.
if [[ -z "$err" || ! "$err" =~ "pipefail"|"unbound variable" ]]; then
  if [[ -z "$out" ]]; then
    pass "missing identity file → empty EXTRA_ARGS, clean exit"
  else
    fail "missing identity file" "EXTRA_ARGS unexpectedly populated: $(printf '%q' "$out")"
  fi
else
  fail "missing identity file" "shell error in stderr: $err"
fi

# ────────────────────────────────────────────────────────────────────────
# Test 6: identity file with quotes around the name — quotes stripped
# ────────────────────────────────────────────────────────────────────────
echo ""
echo "--- Test 6: quoted name has quotes stripped ---"
T6="$TEST_DIR/quoted"
mk_target "$T6" "- name: \"Foo Bar\"
- profile: developer"
out=$(run_extraction "$T6")
expected=$'--project-name\nFoo Bar\n--profile\ndeveloper'
if [[ "$out" == "$expected" ]]; then
  pass "double-quoted name has quotes stripped, spaces preserved"
else
  fail "quoted name" "got=$(printf '%q' "$out") expected=$(printf '%q' "$expected")"
fi

echo ""
echo "============================================"
echo "RESULTS: ${PASS_COUNT} passed, ${FAIL_COUNT} failed"
echo "============================================"

if [[ $FAIL_COUNT -gt 0 ]]; then
  echo -e "${RED}AEGIS-UPGRADE IDENTITY TESTS: FAILURES${NC}"
  exit 1
fi
echo -e "${GREEN}AEGIS-UPGRADE IDENTITY TESTS: ALL PASSED${NC}"
exit 0
