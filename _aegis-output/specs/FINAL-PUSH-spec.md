# FINAL-PUSH -- AEGIS Completion Mega-Spec

## Soul

This is the last wave. Every item here exists because it was either deferred
with good reason, newly discovered during dogfood, or marked "pending
user-pain signal" and now has one. The goal is surgical closure: every
tool gets a test, every command earns its place or becomes a shim, and the
three observation pipelines that were half-wired -- realpath warnings,
judgment-counter routing, instinct auto-reinforcement -- finally close their
loops. When this lands, the only remaining AEGIS work is SDK-blocked or
calendar-bound. The roadmap denominator hits zero in-repo.

---

## Scope Matrix

| ID | Title | Points | Part | Source |
|----|-------|--------|------|--------|
| F1-01 | macOS realpath silent-degradation warning | 1 | Part 1 (v9-05) | guard-ui-edit.sh audit |
| F1-02 | Replace python3 -c interpolation with argv in instinct tool | 1 | Part 1 (v9-05) | shell-injection audit |
| F1-03 | Judgment-counter auto-defer observability | 1 | Part 1 (v9-05) | decision-audit gap analysis |
| F1-04 | Test-harness template | 1 | Part 1 (v9-05) | DRY test infrastructure |
| F1-05 | Shell-command pre-flight linter | 1 | Part 2 (v9-05 new) | greadpath-typo post-mortem |
| F2-01 | Command consolidation 29 to 12 | 5 | Part 3 (S6-06) | v9-follow-ups deferred |
| F3-01 | Fix _aegis-output/.gitignore paradox | 1 | Part 4 (non-roadmap) | git hygiene |
| F3-02 | Instinct auto-promotion observability pipeline | 2 | Part 4 (non-roadmap) | instinct lifecycle gap |
| | **Total** | **13** | | |

---

## Part 1: v9-05 Hardening (4pt)

### F1-01 -- macOS realpath silent-degradation warning (1pt)

**Problem.** The `_canonicalize()` function in `.claude/hooks/guard-ui-edit.sh`
(lines 58-68) cascades through `realpath` -> `greadlink` -> `python3` -> literal
echo. When earlier options are unavailable, it falls through silently. On a
machine where `realpath` and `greadlink` are both missing, the hook degrades to
python3 or literal path without any record -- masking potential path-resolution
mismatches.

**Fix.**

1. Inside the `_canonicalize()` function, after the literal-echo fallback
   (line 67), add a sentinel-gated warning:

```bash
# After the literal echo "$p" fallback line:
_SENTINEL="/tmp/.aegis-realpath-warned-${CLAUDE_SESSION_ID:-default}.flag"
if [[ ! -f "$_SENTINEL" ]]; then
    touch "$_SENTINEL"
    local _ts
    _ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "unknown")
    echo "[${_ts}] [HOOK:guard-ui-edit] WARN — realpath/greadlink unavailable, fell through to literal path. Install coreutils for accurate path resolution." \
        >> "${AEGIS_ACTIVITY_LOG:-.aegis/brain/logs/activity.log}" 2>/dev/null || true
fi
```

2. The sentinel is per-session: `/tmp/.aegis-realpath-warned-${CLAUDE_SESSION_ID:-default}.flag`.
   This ensures the warning fires once per working session (matching user
   expectation of "warned while I'm working") rather than once per machine
   reboot. It lives in `/tmp` so stale flags auto-clear on reboot. No
   cleanup logic needed.

3. Restructure `_canonicalize()` so the fallback path is a distinct branch
   that triggers the warning BEFORE echoing the literal. Current structure:
   try realpath (return on success) -> try greadlink (return on success) ->
   try python3 (return on success) -> echo literal. The warning fires only
   on the literal branch.

**Layer / Responsibility / Interface**

| Layer | Responsibility | Interface |
|-------|----------------|-----------|
| Hook | Path canonicalization with fallback | `_canonicalize()` internal function |
| Sentinel | One-per-session dedup | `/tmp/.aegis-realpath-warned-${CLAUDE_SESSION_ID:-default}.flag` |
| Log | Observability | `.aegis/brain/logs/activity.log` |

**Test: `tools/test-f1-01-realpath-warn.sh`**

| TC | Setup | Assert |
|----|-------|--------|
| TC-01 | Remove sentinel, mock PATH without realpath/greadlink/python3 | WARN line appears in activity.log exactly once |
| TC-02 | Sentinel already exists, same mock | No new WARN line (dedup works) |
| TC-03 | realpath available on PATH | No WARN line, no sentinel created |

---

### F1-02 -- Replace python3 -c interpolation with argv (1pt)

**Problem.** `tools/aegis-instinct-promote.sh` has three shell-injection
surfaces where shell variables are interpolated into inline python3:

- Line 234: `python3 -c "... float('${confidence}') ..."`
- Line 279: `python3 -c "... float('${confidence}') ..."`
- Lines 78-84 in `tools/aegis-log-decision.sh`: `float('$CONFIDENCE')`
  and the triple-quoted JSONL builder (lines 101-116) interpolating
  `$QUESTION`, `$ANSWER`, `$SOURCE_ID`, `$REASONING`.

**Fix.** Replace every `python3 -c "... '${var}' ..."` pattern with:

```bash
python3 - "$var" <<'PYEOF'
import sys
val = sys.argv[1]
# ... use val ...
PYEOF
```

The heredoc is single-quoted (`<<'PYEOF'`) so the shell does zero
interpolation inside the python block. All data enters via `sys.argv`.

**Specific replacements in aegis-instinct-promote.sh:**

Location 1 -- `cmd_activate()` threshold check (line 234):
```bash
# BEFORE:
python3 -c "import sys; sys.exit(0 if float('${confidence}') > 0.5 else 1)"
# AFTER:
python3 - "$confidence" <<'PYEOF'
import sys
sys.exit(0 if float(sys.argv[1]) > 0.5 else 1)
PYEOF
```

Location 2 -- `cmd_promote()` threshold check (line 279):
```bash
# BEFORE:
python3 -c "import sys; sys.exit(0 if float('${confidence}') > 0.8 else 1)"
# AFTER:
python3 - "$confidence" <<'PYEOF'
import sys
sys.exit(0 if float(sys.argv[1]) > 0.8 else 1)
PYEOF
```

**Specific replacements in aegis-log-decision.sh:**

Location 3 -- confidence validation (lines 78-84):
```bash
# BEFORE:
python3 -c "
c = float('$CONFIDENCE')
assert 0.0 <= c <= 1.0, ..."
# AFTER:
python3 - "$CONFIDENCE" <<'PYEOF'
import sys
c = float(sys.argv[1])
assert 0.0 <= c <= 1.0, f"confidence must be 0.0-1.0, got {c}"
PYEOF
```

Location 4 -- JSONL entry builder (lines 101-116):
```bash
# BEFORE: python3 -c with triple-quoted shell vars
# AFTER:
ENTRY=$(python3 - "$TS" "$DECISION_ID" "$QUESTION" "$SOURCE" \
    "$CONFIDENCE" "$ANSWER" "$SOURCE_ID" "$REASONING" <<'PYEOF'
import json, sys
ts, did, q, src, conf, ans, sid, reason = sys.argv[1:9]
d = {
    'ts': ts,
    'decision_id': did,
    'question': q,
    'source': src,
    'confidence': float(conf),
    'answer': ans,
}
if sid:
    d['source_id'] = sid
if reason:
    d['reasoning'] = reason
print(json.dumps(d, ensure_ascii=False))
PYEOF
)
```

**Test: `tools/test-f1-02-injection-safety.sh`**

| TC | Input | Assert |
|----|-------|--------|
| TC-01 | `confidence="'); import os; os.system('echo PWNED'); #"` passed to activate | Exit non-zero (ValueError), no PWNED in output |
| TC-02 | `QUESTION="'; DROP TABLE; --"` passed to log-decision | JSONL entry contains the literal string, no shell execution |

#### Remaining python3 -c occurrences -- triage

Loki's codebase grep (D-053 C-1) found additional `python3 -c "...$var..."`
patterns beyond F1-02's scope. Per-row disposition by Iron Man:

| File | Line(s) | Variable(s) | Risk | Disposition | Rationale |
|------|---------|-------------|------|-------------|-----------|
| `tools/aegis-progress.sh` | 91 | `$NUM`, `$DENOM` | NONE | ACCEPTED | Integer values from bash arithmetic (`DENOM=$((...))`), never user-supplied |
| `tools/aegis-progress.sh` | 137 | `$bar_chars`, `$PCT` | NONE | ACCEPTED | Integer and float from prior bash/python arithmetic, never user-supplied |
| `tools/aegis-progress.sh` | 105-112 | `$HUMAN_QUEUE` | LOW | ACCEPTED -- harden opportunistically | File path from hardcoded `QUEUE=".aegis/brain/human-queue.md"` (line 104). Trusted internal path. Spider-Man may convert to argv when touching this file for other reasons. |
| `tools/aegis-progress.sh` | 118-132 | `$TS`, `$DENOM`, `$NUM`, `$REMAINING`, `$PCT`, `$CURRENT_SPRINT`, `$PENDING` | LOW | ACCEPTED | All values are outputs of prior bash arithmetic or date(1). `$CURRENT_SPRINT` is from readlink on a controlled symlink. No user input path. |
| `.claude/hooks/on-stop.sh` | 259 | `$QUEUE` | LOW | ACCEPTED -- harden opportunistically | `$QUEUE` is hardcoded to `".aegis/brain/human-queue.md"` two lines above (257). Trusted PATH variable, not user-controlled. |
| `tools/aegis-block0-mode.sh` | 60 | `$META` | LOW | ACCEPTED | `$META` is constructed from `$SPRINT_DIR/$TASK_ID/meta.json` where both components are internal AEGIS paths. File-open, not eval. A path with quotes could cause a python SyntaxError but not code execution. |
| `tools/aegis-distill-counter-test.sh` | 53 | `$STATE` | NONE | ACCEPTED -- test-only | Test harness reading its own fixture. Not production code. |
| `tools/aegis-s204-override-test.sh` | 399 | (comment only) | NONE | N/A | Comment documenting the pattern -- no actual interpolation |

No rows warrant expanding F1-02 scope. All are internal-path or arithmetic
values with no user-input vector. The opportunistic hardening note means
Spider-Man should convert to argv style if editing these files for other
reasons in the same PR, but it is not a blocker.

---

### F1-03 -- Judgment-counter auto-defer observability (1pt)

**Problem.** `tools/aegis-log-decision.sh` increments the judgment-fallback
counter and prints a warning to stderr (line 154), but nothing consumes
that stderr warning. The calling agent (Nick Fury) invokes the script and
checks only exit code 0/1. The warning evaporates.

**Fix.** Use exit codes as a machine-readable signal:

| Exit Code | Meaning |
|-----------|---------|
| 0 | Logged successfully, counter below threshold |
| 3 | Logged successfully, counter AT or ABOVE threshold -- caller should route next judgment to Captain America |
| 1 | Error (missing args, validation failure) |
| 2 | Reserved (hook block convention) |

Implementation in `aegis-log-decision.sh`:

1. After the python3 counter-update block (line 121-155), capture its
   exit status AND grep the counter file to check threshold:

```bash
THRESHOLD_HIT=0
if [[ "$SOURCE" == "judgment" ]]; then
    # ... existing python3 counter update ...
    
    # Check if threshold was hit
    if python3 - "$COUNTER" <<'PYEOF'
import json, sys
try:
    with open(sys.argv[1]) as f:
        state = json.load(f)
    sys.exit(0 if state.get('judgment_count', 0) >= state.get('threshold', 3) else 1)
except Exception:
    sys.exit(1)
PYEOF
    then
        THRESHOLD_HIT=1
    fi
fi
```

2. At the end of the script, exit with code 3 when threshold hit:

```bash
echo "logged $DECISION_ID ($SOURCE, conf=$CONFIDENCE)"
if [[ "$THRESHOLD_HIT" -eq 1 ]]; then
    echo "THRESHOLD_EXCEEDED — route next judgment to Captain America" >&2
    exit 3
fi
exit 0
```

3. Document the exit-code contract in:
   - `nick-fury.md`: "After calling `aegis-log-decision.sh`, check exit
     code. If exit 3, spawn Captain America for the next judgment call
     instead of deciding directly."
   - `captain-america.md`: "Nick Fury may route judgment decisions when
     the judgment-fallback counter exceeds threshold (exit 3 from
     aegis-log-decision.sh)."

**Trust Zone / Auth / Data Access**

| Zone | Auth | Data Access |
|------|------|-------------|
| Nick Fury (caller) | session scope | reads exit code, routes accordingly |
| aegis-log-decision.sh | filesystem | writes decision-audit.log, counter JSON |
| Captain America (routed) | session scope | receives judgment question via Nick Fury |

**Test: `tools/test-f1-03-judgment-counter.sh`**

| TC | Setup | Assert |
|----|-------|--------|
| TC-01 | Log 2 judgment decisions | Exit 0 both times, counter = 2 |
| TC-02 | Log 3rd judgment decision (threshold = 3) | Exit 3, stderr contains THRESHOLD_EXCEEDED |
| TC-03 | Log non-judgment decision after threshold | Exit 0 (only judgment triggers threshold) |
| TC-04 | New session ID resets counter | Exit 0 after reset, counter = 1 |

---

### F1-04 -- Test-harness template (1pt)

**Problem.** Existing test harnesses (`aegis-block0-gate-test.sh`,
`aegis-block0-mode-test.sh`, `aegis-s204-override-test.sh`) each redefine
`pass()`, `fail()`, `assert_*()`, tmpdir setup, and cleanup traps. Copy-paste
drift is inevitable.

**Fix.** Create `tools/aegis-test-harness-template.sh` -- a sourceable file
that exports the common primitives.

**Exported API:**

```bash
source tools/aegis-test-harness-template.sh

# Available after sourcing:
#   $TEST_TMPDIR   — mktemp -d result, auto-cleaned on exit
#   PASS "label"   — increment pass counter, print green
#   FAIL "label"   — increment fail counter, print red, continue
#   FAIL_FAST "l"  — increment fail counter, print red, exit immediately
#   assert_eq   actual expected "label"
#   assert_neq  actual expected "label"
#   assert_exit expected_code "label" command [args...]
#   assert_file_exists  path "label"
#   assert_file_absent  path "label"
#   assert_file_contains  path pattern "label"
#   assert_file_not_contains  path pattern "label"
#   assert_stdout_contains  pattern "label" command [args...]
#   assert_stderr_contains  pattern "label" command [args...]
#   test_results  — print summary, exit 0 if all pass, exit 1 if any fail
```

**Template internals:**

```bash
#!/usr/bin/env bash
# aegis-test-harness-template.sh — Source this, do not execute directly.
# Usage: source tools/aegis-test-harness-template.sh

set -euo pipefail

_AEGIS_TEST_PASS=0
_AEGIS_TEST_FAIL=0
TEST_TMPDIR=$(mktemp -d "${TMPDIR:-/tmp}/aegis-test-XXXXXX")

_cleanup() {
    rm -rf "$TEST_TMPDIR" 2>/dev/null || true
}
trap '_cleanup' EXIT INT TERM

PASS() {
    _AEGIS_TEST_PASS=$(( _AEGIS_TEST_PASS + 1 ))
    printf "  PASS: %s\n" "$1"
}

FAIL() {
    _AEGIS_TEST_FAIL=$(( _AEGIS_TEST_FAIL + 1 ))
    printf "  FAIL: %s\n" "$1" >&2
}

FAIL_FAST() {
    FAIL "$1"
    test_results
    exit 1
}

assert_eq() {
    if [[ "$1" == "$2" ]]; then PASS "$3"; else FAIL "$3 | expected='$2' got='$1'"; fi
}

assert_neq() {
    if [[ "$1" != "$2" ]]; then PASS "$3"; else FAIL "$3 | expected not '$2' but got it"; fi
}

assert_exit() {
    local expected="$1" label="$2"; shift 2
    local actual=0
    "$@" >/dev/null 2>&1 || actual=$?
    assert_eq "$actual" "$expected" "$label"
}

assert_file_exists() {
    if [[ -f "$1" ]]; then PASS "$2"; else FAIL "$2 | file missing: $1"; fi
}

assert_file_absent() {
    if [[ ! -f "$1" ]]; then PASS "$2"; else FAIL "$2 | file should not exist: $1"; fi
}

assert_file_contains() {
    if grep -qF "$2" "$1" 2>/dev/null; then PASS "$3"; else FAIL "$3 | pattern '$2' not found in $1"; fi
}

assert_file_not_contains() {
    if grep -qF "$2" "$1" 2>/dev/null; then FAIL "$3 | unexpected pattern '$2' found in $1"; else PASS "$3"; fi
}

assert_stdout_contains() {
    local pattern="$1" label="$2"; shift 2
    local out
    out=$("$@" 2>/dev/null) || true
    if echo "$out" | grep -qF "$pattern"; then PASS "$label"; else FAIL "$label | stdout missing '$pattern'"; fi
}

assert_stderr_contains() {
    local pattern="$1" label="$2"; shift 2
    local err
    err=$("$@" 2>&1 1>/dev/null) || true
    if echo "$err" | grep -qF "$pattern"; then PASS "$label"; else FAIL "$label | stderr missing '$pattern'"; fi
}

test_results() {
    echo ""
    echo "═══════════════════════════════════════"
    echo "  Results: ${_AEGIS_TEST_PASS} passed, ${_AEGIS_TEST_FAIL} failed"
    echo "═══════════════════════════════════════"
    if [[ $_AEGIS_TEST_FAIL -gt 0 ]]; then
        return 1
    fi
    return 0
}
```

**Proof harness** -- `tools/test-f1-04-harness-self-test.sh` uses the
template to test itself:

| TC | Assert |
|----|--------|
| TC-01 | `assert_eq "a" "a" "trivial eq"` passes |
| TC-02 | `assert_eq "a" "b" "expected fail"` increments fail counter |
| TC-03 | `TEST_TMPDIR` exists and is a directory |
| TC-04 | After `test_results`, exit code is 0 when all pass |
| TC-05 | After `test_results`, exit code is 1 when any fail |

---

## Part 2: v9-05 New Story (1pt)

### F1-05 -- Shell-command pre-flight linter (1pt)

**Problem.** The `greadpath` typo incident (spec referenced a non-existent
command) revealed that spec-time validation of shell commands is missing.
Loki reviews specs for logical and structural issues but cannot catch
references to tools that do not exist.

**Fix.** Create `tools/aegis-shell-lint.sh` that scans a markdown spec
file for shell command references and validates them.

**Algorithm:**

1. Extract all backtick-quoted tokens and fenced code block commands
   from the input markdown file.
2. Filter to tokens that look like command invocations (alphanumeric +
   hyphens, not variable names, not file paths).
3. Compare each against:
   - **Allowlist**: curated set of known-good commands (coreutils, git,
     python3, bash, jq, sed, awk, grep, etc. + AEGIS tools in `tools/`).
   - **PATH check**: `command -v <cmd>` on the current machine.
   - **Fallback note check**: if the command appears near text containing
     "fallback", "alternative", "if unavailable", or a `||` chain, it
     is assumed handled.
4. Report any command that fails all three checks.

**Allowlist structure** (embedded in the script):

```bash
KNOWN_GOOD=(
    # coreutils
    cat chmod cp cut date dirname echo env head ln ls mkdir mktemp
    mv printf pwd readlink realpath rm rmdir sed sleep sort tail
    tee touch tr uniq wc xargs
    # common tools
    awk bash curl git grep greadlink jq python3 tar tput
    # AEGIS tools (auto-discovered from tools/ dir)
)
# Auto-append tools/ directory contents
for f in "${SCRIPT_DIR}"/*.sh; do
    KNOWN_GOOD+=("$(basename "$f" .sh)")
    KNOWN_GOOD+=("$(basename "$f")")
done
```

**Usage:**

```bash
tools/aegis-shell-lint.sh --file _aegis-output/specs/SOME-spec.md
# Exit 0: all commands validated
# Exit 1: unknown commands found (listed to stdout)
```

**Integration.** Loki invokes this during format validation (Plan-Approval
Gate). Add to loki.md agent prompt: "Before structural review, run
`tools/aegis-shell-lint.sh --file <spec>` and include findings in the
review report."

**Test: `tools/test-f1-05-shell-lint.sh`** (uses F1-04 template)

| TC | Input spec content | Assert |
|----|-------------------|--------|
| TC-01 | References `realpath`, `jq`, `git` | Exit 0, no warnings |
| TC-02 | References `greadpath` (typo) | Exit 1, output contains `greadpath` |
| TC-03 | References `customtool` with `|| echo fallback` nearby | Exit 0 (fallback detected) |
| TC-04 | Empty file | Exit 0, no false positives |

---

## Part 3: S6-06 Command Consolidation (5pt)

### F2-01 -- Consolidate 29 commands to 12 (5pt)

**Implementation note (prompt-layer dispatch).** Mode dispatch is
PROMPT-LAYER: the agent reading the consolidated command file (e.g.,
`/aegis-status`) checks for flag patterns in the Modes table and executes
the corresponding instruction block. NO bash flag parsing. NO argparse.
Just markdown + Claude's interpretation. These `.md` command files are
prompt instructions consumed by Claude Code, not executable scripts.

Deprecation shims are 1-line Claude command files that point to the new
canonical form and note the deprecation -- they do NOT need to execute
anything. They exist solely so that old trigger words still resolve and
the user sees a clear redirect message.

**Command Consolidation Map**

| # | Canonical Command | Mode/Subcommand | Absorbs (old name) | Shim action |
|---|-------------------|-----------------|---------------------|-------------|
| 1 | `/aegis-start` | (none) | -- | keep as-is |
| 2 | `/aegis-status` | `--kanban` | `/aegis-kanban` | shim: forward + deprecation note |
| | | `--dashboard` | `/aegis-dashboard` | shim: forward + deprecation note |
| | | `--context` | `/aegis-context` | shim: forward + deprecation note |
| 3 | `/aegis-retro` | (none) | -- | keep as-is |
| 4 | `/aegis-handoff` | (none) | -- | keep as-is |
| 5 | `/aegis-sprint` | plan/standup/close/review/status | -- | keep as-is (already has subcommands) |
| 6 | `/aegis-pipeline` | `--qa` | `/aegis-qa` | shim: forward + deprecation note |
| | | `--flow` | `/aegis-flow` | shim: forward + deprecation note |
| 7 | `/aegis-team` | `build` | `/aegis-team-build` | shim: forward + deprecation note |
| | | `review` | `/aegis-team-review` | shim: forward + deprecation note |
| | | `debate` | `/aegis-team-debate` | shim: forward + deprecation note |
| 8 | `/aegis-breakdown` | (none) | -- | keep as-is |
| 9 | `/aegis-verify` | `--doctor` | `/aegis-doctor` | shim: forward + deprecation note |
| 10 | `/aegis-deploy` | `--launch` | `/aegis-launch` | shim: forward + deprecation note |
| 11 | `/aegis-memory` | `--adr` | `/aegis-adr` | shim: forward + deprecation note |
| | | `--instinct` | `/aegis-instinct` | shim: forward + deprecation note |
| | | `--distill` | `/aegis-distill` | shim: forward + deprecation note |
| | | `--evolve` | `/aegis-evolve` | shim: forward + deprecation note |
| | | `--ingest` | `/aegis-ingest` | shim: forward + deprecation note |
| | | `--lint` | `/aegis-lint` | shim: forward + deprecation note |
| | | `--iso` | `/aegis-compliance` | shim: forward + deprecation note |
| 12 | `/aegis-mode` | (none) | -- | keep as-is |
| -- | (deprecated) | -- | `/aegis-reengineer` | shim: note to use `/aegis-start` on existing codebase |

**Total: 12 canonical + 17 shims + 1 deprecation-only = 30 files (29 old + 1 new `/aegis-team`)**

### Shim Template

Each of the 17 merged commands becomes a 1-line-logic shim file:

```markdown
---
name: aegis-kanban
description: "[DEPRECATED] Use /aegis-status --kanban instead"
triggers:
  en: kanban
  th: คันบัง
---

# /aegis-kanban [DEPRECATED]

> This command has been consolidated into `/aegis-status --kanban`.
> It will be removed in a future sprint.

Run `/aegis-status --kanban` now.
```

The shim retains the old trigger words so existing muscle memory works.
The body is a single instruction to execute the new canonical form.

### Canonical Command Updates

For each of the 7 canonical commands that absorb functionality, add a
"Modes" section at the top of their `.md` file:

**`/aegis-status` additions:**

```markdown
## Modes

| Flag | Behavior | Source |
|------|----------|--------|
| (default) | Team status dashboard | existing |
| `--kanban` | Sprint kanban board | was /aegis-kanban |
| `--dashboard` | Sprint burndown + metrics | was /aegis-dashboard |
| `--context` | Context window budget | was /aegis-context |
```

Similar mode tables for `/aegis-pipeline`, `/aegis-team`, `/aegis-verify`,
`/aegis-deploy`, `/aegis-memory`.

### `/aegis-team` -- New Canonical Command

This is the only net-new command file. It replaces the three separate
team-spawn commands with a single entry point:

```markdown
---
name: aegis-team
description: "Spawn a team — build, review, or debate"
triggers:
  en: team build, team review, team debate, spawn team
  th: ทีม, สปอนทีม
---

# /aegis-team

## Quick Reference
Unified team-spawn command. Replaces /aegis-team-build, /aegis-team-review,
/aegis-team-debate.

| Subcommand | Purpose |
|-----------|---------|
| `/aegis-team build` | Iron Man specs, Spider-Man builds, Black Panther reviews |
| `/aegis-team review` | Multi-agent review (Black Panther + Loki) |
| `/aegis-team debate` | Adversarial debate on design/approach |

## Dispatch
Read the first argument after `/aegis-team`:
- If `build`: execute the full /aegis-team-build flow (Step 1-10)
- If `review`: execute the full /aegis-team-review flow
- If `debate`: execute the full /aegis-team-debate flow
- If missing: default to `build`
```

### Reference Updates

1. **`.claude/references/command-chain.md`** -- Update all command names
   to canonical forms. Replace `/aegis-team-build` with `/aegis-team build`,
   etc. Add deprecation note at bottom listing the 17 shims.

2. **`CLAUDE.md` Quick Commands table** -- Replace with the 12 canonical
   commands only. Add footnote: "17 legacy aliases exist as shims; see
   command-chain.md for the mapping."

3. **`on-stop.sh`** -- No changes needed (it does not reference command
   names by string).

### Severity / Handler / Escalation

| Severity | Scenario | Handler |
|----------|----------|---------|
| P0 | Canonical command broken after merge | Spider-Man hotfix, Thor alert |
| P1 | Shim forwards to wrong canonical | Spider-Man fix in next commit |
| P2 | Old trigger word no longer matches | Update shim triggers, log in retro |

**Test: `tools/test-f2-01-command-shims.sh`** (uses F1-04 template)

| TC | Assert |
|----|--------|
| TC-01 | All 12 canonical command files exist in `.claude/commands/` |
| TC-02 | All 17 shim files exist and contain "DEPRECATED" |
| TC-03 | Each shim references its canonical replacement |
| TC-04 | `/aegis-team.md` exists with build/review/debate subcommands |
| TC-05 | `command-chain.md` contains no references to deprecated command names as primary entries |
| TC-06 | `CLAUDE.md` Quick Commands table has exactly 12 entries |
| TC-07 | No shim file exceeds 20 lines (they are stubs, not logic) |

---

## Part 4: Non-Roadmap Items (3pt)

### F3-01 -- Fix _aegis-output/.gitignore paradox (1pt)

**Problem.** The root `.gitignore` has:
```
_aegis-output/*
!_aegis-output/specs/
```

The inner `_aegis-output/.gitignore` (which provides local clarity with
`!specs/` and `!specs/**`) cannot itself be committed because it matches
the `_aegis-output/*` glob. This is the paradox: the file that explains
the carve-out is itself carved out.

**Fix.** Add one line to the root `.gitignore`:

```
_aegis-output/*
!_aegis-output/specs/
!_aegis-output/.gitignore
```

This is the simpler option. The inner `.gitignore` stays for local
developer clarity (it documents what is tracked and why). The root
negation makes it committable.

Decision rationale: removing the inner `.gitignore` and relying solely
on the root carve-out was considered. Rejected because the inner file
serves as documentation for anyone browsing `_aegis-output/` directly --
they see immediately that specs are tracked and everything else is not.

**Test: `tools/test-f3-01-gitignore-paradox.sh`** (uses F1-04 template)

| TC | Assert |
|----|--------|
| TC-01 | `git check-ignore _aegis-output/.gitignore` returns empty (not ignored) |
| TC-02 | `git check-ignore _aegis-output/random-file.txt` returns the path (still ignored) |
| TC-03 | `git check-ignore _aegis-output/specs/some-spec.md` returns empty (not ignored) |

---

### F3-02 -- Instinct auto-promotion observability pipeline (2pt)

**Problem.** The instinct lifecycle has a gap: `reinforce` exists but
nothing auto-triggers it. Instincts cited in decisions (logged via
`aegis-log-decision.sh` with `--source instinct:<tier>` and
`--source-id <instinct-id>`) should get automatically reinforced, but
the connection is not wired.

**Fix.** Create `tools/aegis-instinct-auto-reinforce.sh`:

**Algorithm:**

1. Read `decision-audit.log` (JSONL).
2. Filter entries where `source` starts with `instinct:` and `source_id`
   is non-empty.
3. Collect unique instinct IDs cited in this session (filter by session
   start time or `$CLAUDE_SESSION_ID` if present in log entries).
4. For each cited instinct ID:
   a. Check session sentinel: `/tmp/.aegis-reinforced-<id>.flag`
   b. If sentinel exists, skip (already reinforced this session).
   c. If not, call `tools/aegis-instinct-promote.sh reinforce --id <id>`.
   d. Touch sentinel.
5. Print summary: "Auto-reinforced N instinct(s): [list]"

**Integration with `on-stop.sh`:**

Add a block after the MBP violation scan and before the human queue
banner (around line 253):

```bash
# -- Instinct auto-reinforce at session end --
if [[ -x "tools/aegis-instinct-auto-reinforce.sh" ]]; then
    echo ""
    echo "Instinct auto-reinforce..."
    bash tools/aegis-instinct-auto-reinforce.sh 2>/dev/null || true
fi
```

**Lifecycle closed-loop diagram (text):**

```
resonance scan → pending instinct (manual create)
       ↓
decision cites instinct (aegis-log-decision --source-id)
       ↓
session end → auto-reinforce (aegis-instinct-auto-reinforce.sh)
       ↓
observations++ → meets activate threshold (confidence>0.5, obs>=2)
       ↓
promote (confidence>0.8) → instinct enters promoted tier
```

**Trust Zone / Auth / Data Access**

| Zone | Auth | Data Access |
|------|------|-------------|
| on-stop hook | session scope | triggers auto-reinforce |
| auto-reinforce script | filesystem | reads decision-audit.log, calls instinct-promote |
| sentinel | /tmp per-session | dedup flag per instinct per boot |

**Test: `tools/test-f3-02-auto-reinforce.sh`** (uses F1-04 template)

| TC | Setup | Assert |
|----|-------|--------|
| TC-01 | Seed decision-audit.log with 2 entries citing instinct `test-inst-a`, create pending instinct YAML | observations incremented by 1 (not 2 -- dedup) |
| TC-02 | Run again in same session (sentinel exists) | No additional increment |
| TC-03 | Seed with entries citing instinct `nonexistent-inst` | Graceful skip, no crash, warning logged |

---

### F3-03 -- Bootstrap instinct-source logging in Nick Fury (0pt, absorbed into F3-02)

**Problem.** F3-02's auto-reinforce pipeline reads `decision-audit.log` for
entries where `source` starts with `instinct:`. But reviewing the actual
log (53 entries as of D-053), zero entries use `source: instinct:*` -- all
are `adr:*`, `judgment`, or `framework`. The pipeline is dead on arrival:
no instinct-sourced decisions exist to trigger reinforcement.

The root cause: Nick Fury's decision-audit protocol documents `instinct:promoted|active|pending`
as valid source values, and `nick-fury.md` even shows an example with
`--source "instinct:promoted"`, but in practice Nick Fury defaults to
`--source judgment` or `--source adr:*` because no explicit instruction
tells her WHEN to use the instinct source.

**Fix.** Two documentation updates (no new tooling -- absorbed into F3-02's 2pt):

1. **Update `.claude/agents/nick-fury.md`** -- in the decision-logging
   section, add explicit instruction:

   > "When making a decision and the source-priority-chain reaches the
   > instincts tier (i.e., the decision is informed by consulting a
   > promoted, active, or pending instinct), log via
   > `tools/aegis-log-decision.sh --source instinct:<tier> --source-id <instinct-id>`.
   > Do NOT default to `--source judgment` when an instinct was consulted.
   > The auto-reinforce pipeline (F3-02) depends on these entries to close
   > the instinct lifecycle loop."

2. **Update `.claude/references/decision-audit-protocol.md`** -- add a
   subsection "Source Attribution Rules":

   > "The `source` field MUST reflect the actual knowledge source consulted,
   > not the decision-making mode. If Nick Fury read instinct
   > `sentinel-markers-over-comment-regex` before deciding, `source` is
   > `instinct:promoted` and `source_id` is
   > `sentinel-markers-over-comment-regex` -- even though the act of
   > deciding is a judgment."

**Acceptance criterion for F3-02 (updated):** In addition to the existing
3 test cases, add:

| TC | Setup | Assert |
|----|-------|--------|
| TC-04 | Nick Fury's `nick-fury.md` contains the string `--source instinct:` in its decision-logging instructions | Grep match found |
| TC-05 | `decision-audit-protocol.md` contains "Source Attribution Rules" section | Grep match found |

These are documentation-level tests ensuring the bootstrap gap is closed
at the prompt layer. The first real `instinct:*` entry will appear when
Nick Fury next consults an instinct during a live session.

---

## Tool Deliverables Matrix

| Tool | Type | Location | Bash 3.2 | Test File |
|------|------|----------|----------|-----------|
| realpath warn patch | Hook edit | `.claude/hooks/guard-ui-edit.sh` | Yes | `tools/test-f1-01-realpath-warn.sh` |
| argv injection fix (instinct) | Tool edit | `tools/aegis-instinct-promote.sh` | Yes | `tools/test-f1-02-injection-safety.sh` |
| argv injection fix (decision) | Tool edit | `tools/aegis-log-decision.sh` | Yes | (same as above) |
| judgment-counter exit code | Tool edit | `tools/aegis-log-decision.sh` | Yes | `tools/test-f1-03-judgment-counter.sh` |
| Test harness template | New tool | `tools/aegis-test-harness-template.sh` | Yes | `tools/test-f1-04-harness-self-test.sh` |
| Shell-command linter | New tool | `tools/aegis-shell-lint.sh` | Yes | `tools/test-f1-05-shell-lint.sh` |
| 12 canonical commands | Command edits | `.claude/commands/aegis-*.md` | N/A | `tools/test-f2-01-command-shims.sh` |
| 17 shim commands | New shims | `.claude/commands/aegis-*.md` | N/A | (same as above) |
| `/aegis-team` command | New command | `.claude/commands/aegis-team.md` | N/A | (same as above) |
| gitignore fix | Config edit | `.gitignore` | N/A | `tools/test-f3-01-gitignore-paradox.sh` |
| Inner gitignore | Config edit | `_aegis-output/.gitignore` | N/A | (same as above) |
| Auto-reinforce pipeline | New tool | `tools/aegis-instinct-auto-reinforce.sh` | Yes | `tools/test-f3-02-auto-reinforce.sh` |
| on-stop.sh integration | Hook edit | `.claude/hooks/on-stop.sh` | Yes | (same as above) |
| Nick Fury instinct-source instruction | Doc edit | `.claude/agents/nick-fury.md` | N/A | `tools/test-f3-02-auto-reinforce.sh` TC-04 |
| Decision-audit source attribution | Doc edit | `.claude/references/decision-audit-protocol.md` | N/A | `tools/test-f3-02-auto-reinforce.sh` TC-05 |

---

## Non-Functional Requirements

### Bash 3.2 Compatibility

All new scripts and edits MUST work on bash 3.2 (macOS default). Specific
constraints:
- No associative arrays (`declare -A`).
- No `mapfile` / `readarray`.
- No `${var,,}` lowercase expansion (use `tr '[:upper:]' '[:lower:]'`).
- No `|&` (use `2>&1 |`).
- No `[[ $x =~ pattern ]]` with stored regex variables (inline only).
- Test on macOS before committing.

### Backward Compatibility

- All 29 original command names remain functional (17 as shims, 12 as
  canonical). Zero breakage for existing muscle memory.
- No sprint-v9-01 through v9-04 test regressions.
- `aegis-log-decision.sh` exit-code change is additive: code 0 still
  means success; only new code 3 is added. No existing caller breaks.

### Security

- F1-02 eliminates all shell-injection surfaces in instinct-promote and
  log-decision tools.
- No new eval/exec patterns introduced anywhere.
- Sentinel files in `/tmp` use predictable names but contain no sensitive
  data (empty flag files only).

---

## Do's and Don'ts

### Do's
1. DO use the test-harness template (F1-04) for all new test scripts in this PR.
2. DO keep shim files under 20 lines -- they are pointers, not logic.
3. DO preserve all existing trigger words in shim files for backward compatibility.
4. DO use `<<'PYEOF'` (single-quoted heredoc) for all inline python to prevent shell expansion.
5. DO test every exit-code contract with explicit `assert_exit` calls.
6. DO update `command-chain.md` atomically with the command consolidation.
7. DO use `/tmp` sentinels for per-session dedup (auto-cleared on reboot, no cleanup burden).
8. DO run the existing `aegis-block0-gate-test.sh` and `aegis-block0-mode-test.sh` after changes to confirm no regressions.

### Don'ts
1. DON'T refactor existing test harnesses to use the new template in this PR -- ship the template, prove it with new tests, migrate later.
2. DON'T delete any of the 17 shim command files in this PR -- deprecation shims are removed in a future sprint.
3. DON'T introduce `declare -A` or any bash 4+ features.
4. DON'T change the JSONL schema of `decision-audit.log` -- only add the exit-code signal layer.
5. DON'T add `AEGIS_MAINTAINER_MODE` or any env-var gates to the new tools -- they are all read/write to `.aegis/` internals, not protected paths.
6. DON'T modify the inner logic of the 12 canonical commands during consolidation -- only add mode-dispatch headers.
7. DON'T put test data in committed directories -- all test fixtures go in `$TEST_TMPDIR`.
8. DON'T use `python3 -c '...${var}...'` where `${var}` could be user-controlled. For integer-only or internal-path values (e.g., bash arithmetic counters, hardcoded AEGIS paths), this is acceptable but harden opportunistically by converting to `sys.argv` style when editing the file for other reasons.
9. DON'T skip the Loki Plan-Approval Gate -- this spec must receive APPROVE or CONDITIONAL before Spider-Man starts.

---

## Agent Prompt Guide (Spider-Man Handoff)

### Prompt 1 -- Part 1: v9-05 Hardening (F1-01 through F1-04)

```
Read _aegis-output/specs/FINAL-PUSH-spec.md Part 1 (sections F1-01
through F1-04).

Implement in this order:
1. F1-04 first (test harness template) — all subsequent tests depend on it.
   Create tools/aegis-test-harness-template.sh + tools/test-f1-04-harness-self-test.sh.
   Run the self-test to confirm.
2. F1-01 (realpath warning) — edit guard-ui-edit.sh _canonicalize(),
   create tools/test-f1-01-realpath-warn.sh using the template, run.
3. F1-02 (argv injection fix) — edit aegis-instinct-promote.sh + aegis-log-decision.sh,
   create tools/test-f1-02-injection-safety.sh using the template, run.
4. F1-03 (judgment counter exit code) — edit aegis-log-decision.sh exit logic,
   update nick-fury.md + captain-america.md, create tools/test-f1-03-judgment-counter.sh
   using the template, run.

Run all existing tests (aegis-block0-gate-test.sh, aegis-block0-mode-test.sh)
to confirm no regressions. Commit: "feat(v9-05): F1-01..F1-04 hardening — realpath warn, argv safety, judgment counter, test template"
```

### Prompt 2 -- Part 2: Shell Linter (F1-05)

```
Read _aegis-output/specs/FINAL-PUSH-spec.md Part 2 (section F1-05).

Create tools/aegis-shell-lint.sh per spec. Create tools/test-f1-05-shell-lint.sh
using the test harness template (source tools/aegis-test-harness-template.sh).
Run tests. Add one line to .claude/agents/loki.md referencing the linter
in the format-validation step. Commit: "feat(v9-05): F1-05 shell-command pre-flight linter"
```

### Prompt 3 -- Part 3: Command Consolidation (F2-01)

```
Read _aegis-output/specs/FINAL-PUSH-spec.md Part 3 (section F2-01).

This is the largest item (5pt). Execute in phases:
Phase A: Create /aegis-team.md (new canonical command).
Phase B: Update the 7 canonical commands that absorb modes (add Modes table).
Phase C: Create all 17 shim files (use the shim template from spec exactly).
Phase D: Update .claude/references/command-chain.md with canonical names.
Phase E: Update CLAUDE.md Quick Commands table to 12 entries.
Phase F: Create tools/test-f2-01-command-shims.sh using test harness template, run.

Commit: "feat(S6-06): command consolidation 29→12 + 17 deprecation shims"
```

### Prompt 4 -- Part 4: Non-Roadmap (F3-01, F3-02)

```
Read _aegis-output/specs/FINAL-PUSH-spec.md Part 4 (sections F3-01, F3-02).

1. F3-01: Add "!_aegis-output/.gitignore" to root .gitignore.
   Create tools/test-f3-01-gitignore-paradox.sh using test harness template, run.
2. F3-02: Create tools/aegis-instinct-auto-reinforce.sh per spec.
   Edit .claude/hooks/on-stop.sh to call it at session end (after MBP scan,
   before human queue banner). Create tools/test-f3-02-auto-reinforce.sh
   using test harness template, run.

3. F3-03 (bootstrap): Update .claude/agents/nick-fury.md decision-logging
   section with instinct-source instruction. Update
   .claude/references/decision-audit-protocol.md with "Source Attribution
   Rules" subsection. Add TC-04 + TC-05 to test-f3-02-auto-reinforce.sh.

Commit: "feat: F3-01 gitignore fix + F3-02 instinct auto-reinforce pipeline + F3-03 bootstrap"
```

---

_v1.1 -- D-053 conditions addressed 2026-04-23 by Iron Man cycle 12._
_Changes: C-1 python3 triage table added to F1-02, Don't #8 refined._
_C-2 F3-03 bootstrap story absorbed into F3-02. C-3 sentinel path_
_per-session via CLAUDE_SESSION_ID. C-4 prompt-layer dispatch note in F2-01._
