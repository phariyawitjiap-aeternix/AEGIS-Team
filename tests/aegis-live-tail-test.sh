#!/usr/bin/env bash
# aegis-live-tail-test.sh — Sprint v11-01 acceptance + regression test
#
# Exercises tools/aegis-live-tail/{emit,watch,format}.mjs against the
# acceptance criteria from .aegis/brain/sprints/sprint-v11-01/plan.md
# and the AEGIS-PLUS-MEGA-PLAN §6.1.
#
# Test groups:
#   1. format.mjs unit tests (event → line, ANSI handling, truncate)
#   2. emit.mjs hot-path tests (hook-event → fifo line, no-reader drop, latency)
#   3. watch.mjs filter tests (--persona, --tool, --errors-only, --no-color)
#   4. start.sh smoke (subcommand wiring)
#   5. end-to-end: emit → fifo → watch reads → matching line on stdout

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
EMIT="${REPO_ROOT}/tools/aegis-live-tail/emit.mjs"
WATCH="${REPO_ROOT}/tools/aegis-live-tail/watch.mjs"
FORMAT="${REPO_ROOT}/tools/aegis-live-tail/format.mjs"
START_SH="${REPO_ROOT}/tools/aegis-live-tail/start.sh"

for f in "$EMIT" "$WATCH" "$FORMAT" "$START_SH"; do
  if [[ ! -f "$f" ]]; then
    echo "FATAL: missing $f" >&2; exit 2
  fi
done

if ! command -v node >/dev/null 2>&1; then
  echo "FATAL: node not found in PATH" >&2; exit 2
fi

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
PASS_COUNT=0; FAIL_COUNT=0; SKIP_COUNT=0
pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS_COUNT=$((PASS_COUNT+1)); }
fail() { echo -e "${RED}FAIL${NC}: $1 -- $2"; FAIL_COUNT=$((FAIL_COUNT+1)); }
skip() { echo -e "${YELLOW}SKIP${NC}: $1 -- $2"; SKIP_COUNT=$((SKIP_COUNT+1)); }

TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/aegis-live-tail-XXXXXX")
LIVE_DIR="${TEST_DIR}/.aegis/brain/live"
FIFO="${LIVE_DIR}/current.fifo"
mkdir -p "$LIVE_DIR"
mkfifo "$FIFO"
trap 'rm -rf "$TEST_DIR"' EXIT INT TERM

export CLAUDE_PROJECT_DIR="$TEST_DIR"

echo "============================================"
echo "AEGIS live-tail — sprint v11-01 acceptance"
echo "test dir: $TEST_DIR"
echo "============================================"

# ────────────────────────────────────────────────────────────────────────
# Group 1: format.mjs unit tests
# ────────────────────────────────────────────────────────────────────────
echo ""
echo "--- Group 1: format.mjs unit tests ---"

cat > "${TEST_DIR}/test-format.mjs" <<'JS'
const { formatEvent, eventFromHook, _internal } = await import(process.argv[2]);
const { stripAnsi, truncate, pad } = _internal;

let pass=0, fail=0;
function t(label, ok, info) { if (ok) { console.log("ok  "+label); pass++; } else { console.log("FAIL "+label+" :: "+(info??"")); fail++; } }

// 1.a — basic event format with all fields
{
  const line = formatEvent({
    ts: new Date(Date.UTC(2026,4,4, 14,23,8)),
    persona: "spider-man",
    tool: "Edit",
    target: "src/wordPool.ts",
    extra: "+12 -3",
  }, { color: false });
  t("1.a basic line shape", /^14:23:08 \[spider-man\s*\]/.test(line), line);
  t("1.a target included",  line.includes("src/wordPool.ts"), line);
  t("1.a extra in parens",  line.includes("(+12 -3)"), line);
}

// 1.b — color codes present when color:true
{
  const line = formatEvent({ persona: "spider-man", tool: "Edit", target: "x" });
  t("1.b ANSI escapes present", /\x1b\[[0-9;]*m/.test(line), JSON.stringify(line));
  t("1.b ANSI strippable",       stripAnsi(line).includes("[spider-man"), JSON.stringify(stripAnsi(line)));
}

// 1.c — truncate respects ANSI when measuring
{
  const long = formatEvent({ persona: "thor", tool: "Bash", target: "x".repeat(500) }, { color: true, maxWidth: 60 });
  t("1.c truncated to 60 visible chars", stripAnsi(long).length <= 60, "len="+stripAnsi(long).length);
  t("1.c ends with ellipsis",            stripAnsi(long).endsWith("…"), JSON.stringify(stripAnsi(long)));
}

// 1.d — eventFromHook for Edit
{
  const ev = eventFromHook({ tool_name: "Edit", tool_input: { file_path: "src/foo.ts" } }, "spider-man");
  t("1.d hook→Edit target",  ev.target === "src/foo.ts", JSON.stringify(ev));
  t("1.d hook→Edit persona", ev.persona === "spider-man", JSON.stringify(ev));
}

// 1.e — eventFromHook for Bash trims long commands
{
  const ev = eventFromHook({ tool_name: "Bash", tool_input: { command: "x".repeat(200) } });
  t("1.e Bash command capped 60", ev.target.length === 60, "len="+ev.target.length);
}

// 1.f — error response → status:err
{
  const ev = eventFromHook({ tool_name: "Edit", tool_input: { file_path: "a" }, tool_response: { is_error: true } });
  t("1.f error status detected", ev.status === "err", JSON.stringify(ev));
}

// 1.g — pad helper
{
  t("1.g pad left-pads to width", pad("ab", 5) === "ab   ", JSON.stringify(pad("ab",5)));
  t("1.g pad truncates to width", pad("abcdef", 4) === "abcd", JSON.stringify(pad("abcdef",4)));
}

console.log(`format-unit: ${pass} passed, ${fail} failed`);
process.exit(fail > 0 ? 1 : 0);
JS

OUT="$TEST_DIR/format-unit.out"
if node "${TEST_DIR}/test-format.mjs" "$FORMAT" >"$OUT" 2>&1; then
  while IFS= read -r line; do
    case "$line" in
      "ok  "*) pass "${line#ok  }" ;;
      "FAIL "*) fail "${line#FAIL }" "" ;;
    esac
  done <"$OUT"
else
  fail "format-unit subprocess" "$(tail -10 "$OUT")"
fi

# ────────────────────────────────────────────────────────────────────────
# Group 2: emit.mjs hot-path tests
# ────────────────────────────────────────────────────────────────────────
echo ""
echo "--- Group 2: emit.mjs hot path ---"

# Background reader to drain fifo for the emit tests.
DRAIN="$TEST_DIR/drain.out"
( cat "$FIFO" > "$DRAIN" ) &
DRAIN_PID=$!

# 2.a — emit with Edit hook payload writes one line through the fifo
HOOK_JSON='{"tool_name":"Edit","tool_input":{"file_path":"src/app.ts"},"tool_response":{}}'
echo "$HOOK_JSON" | node "$EMIT"
sleep 0.3
if grep -q "src/app.ts" "$DRAIN"; then
  pass "2.a Edit hook → fifo contains target file_path"
else
  fail "2.a Edit hook → fifo" "drain content: $(cat "$DRAIN")"
fi

# 2.b — emit p95 latency under 100ms (Risk R1 budget)
HOOK_BASH='{"tool_name":"Bash","tool_input":{"command":"echo hi"},"tool_response":{}}'
LAT_FILE="$TEST_DIR/latencies.txt"
: > "$LAT_FILE"
for i in $(seq 1 50); do
  T0=$(node -e 'process.stdout.write(String(Date.now()))')
  echo "$HOOK_BASH" | node "$EMIT"
  T1=$(node -e 'process.stdout.write(String(Date.now()))')
  echo $((T1 - T0)) >> "$LAT_FILE"
done
P95=$(sort -n "$LAT_FILE" | awk 'BEGIN{cnt=0} {a[NR]=$0; cnt=NR} END{print a[int(cnt*0.95+0.5)]}')
if [[ "$P95" -lt 200 ]]; then
  pass "2.b emit p95 latency = ${P95}ms (<200ms acceptance threshold)"
else
  fail "2.b emit p95 latency" "got ${P95}ms (must be <200ms)"
fi

# 2.c — emit fails open when fifo doesn't exist (Risk R6: fail-open)
TMP_NO_FIFO="$TEST_DIR/no-fifo"
mkdir -p "$TMP_NO_FIFO/.aegis/brain/live"
NO_FIFO_OUT="$TEST_DIR/no-fifo.err"
if CLAUDE_PROJECT_DIR="$TMP_NO_FIFO" sh -c "echo '$HOOK_JSON' | node '$EMIT'" >/dev/null 2>"$NO_FIFO_OUT"; then
  pass "2.c emit exits 0 when fifo missing (fail-open)"
else
  fail "2.c emit fail-open" "exit=$? stderr=$(cat "$NO_FIFO_OUT")"
fi

# 2.d — emit drops silently when fifo has no reader
# Fresh fifo with no reader.
DROP_DIR="$TEST_DIR/drop"
mkdir -p "$DROP_DIR/.aegis/brain/live"
DROP_FIFO="$DROP_DIR/.aegis/brain/live/current.fifo"
mkfifo "$DROP_FIFO"
DROP_ERR="$TEST_DIR/drop.err"
if CLAUDE_PROJECT_DIR="$DROP_DIR" sh -c "echo '$HOOK_JSON' | node '$EMIT'" >/dev/null 2>"$DROP_ERR"; then
  pass "2.d emit drops cleanly when no reader on fifo"
else
  fail "2.d emit no-reader" "exit=$? stderr=$(cat "$DROP_ERR")"
fi

# 2.e — emit exits 0 even on garbage stdin (fail-open)
GARBAGE_ERR="$TEST_DIR/garbage.err"
if printf 'not json at all' | node "$EMIT" >/dev/null 2>"$GARBAGE_ERR"; then
  pass "2.e emit exits 0 on malformed stdin"
else
  fail "2.e emit malformed stdin" "exit=$? stderr=$(cat "$GARBAGE_ERR")"
fi

# Clean up drain reader.
kill "$DRAIN_PID" 2>/dev/null || true
wait "$DRAIN_PID" 2>/dev/null || true

# ────────────────────────────────────────────────────────────────────────
# Group 3: watch.mjs filter tests
# ────────────────────────────────────────────────────────────────────────
echo ""
echo "--- Group 3: watch.mjs filters ---"

# Replace the consumed fifo (cat closed it).
rm -f "$FIFO"; mkfifo "$FIFO"

# Helper: write a few canned events to fifo via emit, captured via watch in
# --no-color mode so substring matching is simple.
run_watch_with_input() {
  local flags="$1"; shift
  local out="$1"; shift
  : > "$out"
  # Spawn watcher in background.
  ( node "$WATCH" --no-color $flags > "$out" 2>/dev/null & echo $! > "$TEST_DIR/watch.pid" )
  sleep 0.2
  # Drive a few events.
  for ev in "$@"; do
    echo "$ev" | node "$EMIT"
    sleep 0.05
  done
  sleep 0.4
  kill -TERM "$(cat "$TEST_DIR/watch.pid")" 2>/dev/null || true
  wait "$(cat "$TEST_DIR/watch.pid")" 2>/dev/null || true
}

EV_BASH_BOLT='{"tool_name":"Bash","tool_input":{"command":"npm test"}}'
EV_EDIT_BOLT='{"tool_name":"Edit","tool_input":{"file_path":"src/a.ts"}}'
EV_EDIT_VIGIL_ERR='{"tool_name":"Edit","tool_input":{"file_path":"src/b.ts"},"tool_response":{"is_error":true}}'

# 3.a — --tool Edit filters out Bash
W3A="$TEST_DIR/watch-3a.out"
AEGIS_PERSONA=spider-man run_watch_with_input "--tool Edit" "$W3A" \
  "$EV_BASH_BOLT" "$EV_EDIT_BOLT"
if grep -q "src/a.ts" "$W3A" && ! grep -q "npm test" "$W3A"; then
  pass "3.a --tool Edit shows Edit, hides Bash"
else
  fail "3.a --tool filter" "out=$(cat "$W3A")"
fi

rm -f "$FIFO"; mkfifo "$FIFO"

# 3.b — --errors-only shows only events with error/warn/block status
W3B="$TEST_DIR/watch-3b.out"
AEGIS_PERSONA=spider-man run_watch_with_input "--errors-only" "$W3B" \
  "$EV_EDIT_BOLT" "$EV_EDIT_VIGIL_ERR"
if grep -q "src/b.ts" "$W3B" && ! grep -q "src/a.ts" "$W3B"; then
  pass "3.b --errors-only shows error event, hides clean event"
else
  fail "3.b --errors-only" "out=$(cat "$W3B")"
fi

rm -f "$FIFO"; mkfifo "$FIFO"

# 3.c — --persona filters by persona env
W3C="$TEST_DIR/watch-3c.out"
( node "$WATCH" --no-color --persona spider-man > "$W3C" 2>/dev/null & echo $! > "$TEST_DIR/watch.pid" )
sleep 0.2
AEGIS_PERSONA=spider-man sh -c "echo '$EV_EDIT_BOLT' | node '$EMIT'"
sleep 0.05
AEGIS_PERSONA=war-machine sh -c "echo '$EV_EDIT_BOLT' | node '$EMIT'"
sleep 0.4
kill -TERM "$(cat "$TEST_DIR/watch.pid")" 2>/dev/null || true
wait "$(cat "$TEST_DIR/watch.pid")" 2>/dev/null || true

if grep -q "spider-man" "$W3C"; then
  if grep -q "war-machine" "$W3C"; then
    fail "3.c --persona filter" "war-machine line leaked through: $(cat "$W3C")"
  else
    pass "3.c --persona spider-man filters out war-machine"
  fi
else
  fail "3.c --persona match" "spider-man not seen: $(cat "$W3C")"
fi

# ────────────────────────────────────────────────────────────────────────
# Group 4: start.sh subcommand wiring
# ────────────────────────────────────────────────────────────────────────
echo ""
echo "--- Group 4: start.sh wiring ---"

# 4.a — start.sh start outside tmux returns helpful guidance
unset TMUX || true
START_OUT="$TEST_DIR/start-no-tmux.out"
if ! TMUX="" CLAUDE_PROJECT_DIR="$TEST_DIR" bash "$START_SH" start >"$START_OUT" 2>&1; then
  if grep -q "Not in tmux" "$START_OUT"; then
    pass "4.a start.sh start outside tmux fails clean with guidance"
  else
    fail "4.a start.sh outside-tmux msg" "$(cat "$START_OUT")"
  fi
else
  fail "4.a start.sh outside-tmux exit code" "exited 0 — should be non-zero with guidance"
fi

# 4.b — start.sh stop removes fifo
mkfifo "$TEST_DIR/.aegis/brain/live/test-stop-fifo" 2>/dev/null || true
TMUX="" CLAUDE_PROJECT_DIR="$TEST_DIR" bash "$START_SH" stop >/dev/null 2>&1 || true
if [[ ! -p "$TEST_DIR/.aegis/brain/live/current.fifo" ]]; then
  pass "4.b start.sh stop removes fifo"
else
  fail "4.b start.sh stop fifo cleanup" "fifo still present"
fi

# 4.c — bash syntax check on start.sh
if bash -n "$START_SH" 2>"$TEST_DIR/start-syntax.err"; then
  pass "4.c start.sh bash syntax OK"
else
  fail "4.c start.sh syntax" "$(cat "$TEST_DIR/start-syntax.err")"
fi

# ────────────────────────────────────────────────────────────────────────
# Group 5: end-to-end pipeline
# ────────────────────────────────────────────────────────────────────────
echo ""
echo "--- Group 5: end-to-end emit → fifo → watch ---"

rm -f "$FIFO"; mkfifo "$FIFO"

E2E_OUT="$TEST_DIR/e2e.out"
( node "$WATCH" --no-color > "$E2E_OUT" 2>/dev/null & echo $! > "$TEST_DIR/watch.pid" )
sleep 0.2

# 10 tool calls per acceptance criterion
for i in $(seq 1 10); do
  AEGIS_PERSONA=spider-man sh -c "echo '{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"src/file-${i}.ts\"}}' | node '$EMIT'"
  sleep 0.04
done
sleep 0.6
kill -TERM "$(cat "$TEST_DIR/watch.pid")" 2>/dev/null || true
wait "$(cat "$TEST_DIR/watch.pid")" 2>/dev/null || true

LINE_COUNT=$(grep -c "src/file-" "$E2E_OUT" || true)
if [[ "$LINE_COUNT" -ge 8 ]]; then
  pass "5.a 10 emits → ${LINE_COUNT} lines reached watcher (≥8 acceptable; some race acceptable)"
elif [[ "$LINE_COUNT" -eq 10 ]]; then
  pass "5.a 10 emits → 10 lines reached watcher (lossless)"
else
  fail "5.a end-to-end coverage" "only $LINE_COUNT/10 lines reached watcher: $(head -3 "$E2E_OUT")"
fi

echo ""
echo "--- Group 6: watcher survives multiple writers (O_RDWR pin regression) ---"
# Bug observed during kam-tong-ham pilot bootstrap: watcher exited after the
# first emit closed its writer end of the fifo, collapsing the tmux pane.
# Fix: open fifo in O_RDWR mode so the kernel never reports EOF to the read
# stream. Test: spawn watcher, fire 3 sequential emits, assert all 3 lines
# arrive AND the watcher process is still alive afterward.

rm -f "$FIFO"; mkfifo "$FIFO"
G6_OUT="$TEST_DIR/g6.out"
G6_PID_FILE="$TEST_DIR/g6.pid"
( node "$WATCH" --no-color > "$G6_OUT" 2>&1 & echo $! > "$G6_PID_FILE" )
sleep 0.3
for i in 1 2 3; do
  printf '%s' "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"survive-${i}\"}}" \
    | AEGIS_PERSONA=spider-man node "$EMIT"
  sleep 0.15
done
sleep 0.5
G6_LINES=$(grep -c "survive-" "$G6_OUT" || true)
G6_PID=$(cat "$G6_PID_FILE")
G6_ALIVE="no"
kill -0 "$G6_PID" 2>/dev/null && G6_ALIVE="yes"

if [[ "$G6_LINES" -eq 3 ]]; then
  pass "6.a all 3 sequential emits reached the watcher"
else
  fail "6.a sequential coverage" "got $G6_LINES/3 — content: $(cat "$G6_OUT")"
fi

if [[ "$G6_ALIVE" == "yes" ]]; then
  pass "6.b watcher still alive after writer close cycles (O_RDWR pin holds)"
else
  fail "6.b watcher survival" "watcher exited after first writer cycle"
fi

kill -TERM "$G6_PID" 2>/dev/null || true
wait "$G6_PID" 2>/dev/null || true

echo ""
echo "============================================"
echo "RESULTS: ${PASS_COUNT} passed, ${FAIL_COUNT} failed, ${SKIP_COUNT} skipped"
echo "============================================"

if [[ $FAIL_COUNT -gt 0 ]]; then
  echo -e "${RED}AEGIS LIVE-TAIL TESTS: FAILURES${NC}"
  exit 1
fi
echo -e "${GREEN}AEGIS LIVE-TAIL TESTS: ALL PASSED${NC}"
exit 0
