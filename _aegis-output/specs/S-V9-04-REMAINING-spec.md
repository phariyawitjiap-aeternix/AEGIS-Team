# Sprint v9-04 Remaining Stories -- Closing the Gaps

These four stories exist because the AEGIS framework has sharp edges where
knowledge lives in more than one place, where paths can lie, where approved
work vanishes from git, and where instincts have no formal way to grow up.
Each story removes a class of silent drift: S3-05 collapses four copies of
the same truth into one file, S3-09 canonicalizes paths so a hook cannot be
tricked, S2-06 makes specs permanent in version control, and S2-05 gives
instincts the lifecycle tooling they were designed to have but never received.
Together they close the gap between what the framework promises and what it
actually enforces.

---

## Table of Contents

1. [Sprint Overview](#1-sprint-overview)
2. [S3-05: EXCLUDE/INCLUDE Pattern SSOT](#2-s3-05-excludeinclude-pattern-ssot)
3. [S3-09: realpath Normalization in guard-ui-edit](#3-s3-09-realpath-normalization-in-guard-ui-edit)
4. [S2-06: Track Approved Specs in Git](#4-s2-06-track-approved-specs-in-git)
5. [S2-05: Promote Resonance to Instinct Lifecycle](#5-s2-05-promote-resonance-to-instinct-lifecycle)
6. [Cross-Story Dependencies](#6-cross-story-dependencies)
7. [Acceptance Test Matrix](#7-acceptance-test-matrix)
8. [Architecture Decision Records](#8-architecture-decision-records)
9. [Non-Functional Requirements](#9-non-functional-requirements)
10. [Trust Zones and Data Access](#10-trust-zones-and-data-access)
11. [Do's and Don'ts](#11-dos-and-donts)
12. [Agent Prompt Guide](#12-agent-prompt-guide)

---

## 1. Sprint Overview

| Story | Title | Points | Origin | Owner |
|-------|-------|--------|--------|-------|
| S3-05 | EXCLUDE/INCLUDE pattern SSOT | 3 | BP F-03 (v9-03 retro) | Spider-Man |
| S3-09 | realpath normalization in guard-ui-edit | 1 | BP F-02 (v9-03 retro) | Spider-Man |
| S2-06 | Track approved specs in git | 2 | v9-02 retro action | Spider-Man |
| S2-05 | Promote resonance to instinct lifecycle | 3 | v9-02 retro action | Spider-Man |
| **Total** | | **9** | | |

### Deliverable Summary

| # | Deliverable | Story | Files |
|---|-------------|-------|-------|
| 1 | `tools/aegis-ui-patterns.sh` (canonical SSOT) | S3-05 | new |
| 2 | Refactor `guard-ui-edit.sh` to source SSOT | S3-05 | modify |
| 3 | Refactor `aegis-block0-f-gate-test.sh` to source SSOT | S3-05 | modify |
| 4 | Refactor `aegis-guard-ui-edit-test.sh` to source SSOT | S3-05 | modify |
| 5 | Update `nick-fury.md` BLOCK 0F prose to cite SSOT | S3-05 | modify |
| 6 | Update `coulson.md` 0F section to cite SSOT | S3-05 | modify |
| 7 | `tools/aegis-ui-patterns-test.sh` (7 TC) | S3-05 | new |
| 8 | `realpath` normalization in `guard-ui-edit.sh` | S3-09 | modify |
| 9 | Path-traversal TC in `aegis-guard-ui-edit-test.sh` | S3-09 | modify |
| 10 | `.gitignore` carve-out for `_aegis-output/specs/` | S2-06 | modify |
| 11 | `_aegis-output/.gitignore` override file | S2-06 | new |
| 12 | `tools/aegis-spec-tracking-test.sh` (4 TC) | S2-06 | new |
| 13 | `tools/aegis-instinct-promote.sh` (lifecycle tool) | S2-05 | new |
| 14 | `tools/aegis-instinct-promote-test.sh` (9 TC) | S2-05 | new |

---

## 2. S3-05: EXCLUDE/INCLUDE Pattern SSOT

### 2.1 Problem

UI file patterns are duplicated verbatim across four files:

| Location | Type | Current Pattern Source |
|----------|------|----------------------|
| `.claude/hooks/guard-ui-edit.sh` | Runtime hook | Inline bash regex |
| `tools/aegis-block0-f-gate-test.sh` | Test | Inline bash regex (copy) |
| `tools/aegis-guard-ui-edit-test.sh` | Test | Implicit (via hook invocation) |
| `.claude/agents/nick-fury.md` BLOCK_0F | Prose pseudocode | Hardcoded pattern list |
| `.claude/agents/coulson.md` 0F section | Prose reference | Hardcoded pattern list |

Adding a new UI extension (e.g., `.astro`, `.mdx`) requires updating 4+ files
with no mechanism to detect drift.

### 2.2 Design: `tools/aegis-ui-patterns.sh`

**Purpose**: Single canonical file that defines both INCLUDE and EXCLUDE
pattern arrays. Consumers source this file to get the arrays.

**Interface contract**:

```bash
#!/usr/bin/env bash
# tools/aegis-ui-patterns.sh -- SSOT for UI file patterns (S3-05)
#
# Source this file; it sets two bash arrays:
#   UI_INCLUDE_PATTERNS -- file extensions + directory prefixes matching UI files
#   UI_EXCLUDE_PATTERNS -- test/spec/config files excluded from UI gating
#
# It also provides two functions:
#   is_ui_file <path>       -- returns 0 if path matches INCLUDE patterns
#   is_excluded_file <path> -- returns 0 if path matches EXCLUDE patterns
#
# Usage:
#   source "$(dirname "$0")/aegis-ui-patterns.sh"
#   # or from hooks:
#   source "$(git rev-parse --show-toplevel)/tools/aegis-ui-patterns.sh"

# --- set -u compatibility: declare arrays unconditionally before populating ---
UI_INCLUDE_EXTENSIONS=()
UI_INCLUDE_DIRS=()
UI_EXCLUDE_SUFFIXES=()
UI_EXCLUDE_CONFIG_EXTENSIONS=()
UI_EXCLUDE_DIRS=()
UI_EXCLUDE_PREFIXES=()

# --- INCLUDE patterns: file extensions ---
UI_INCLUDE_EXTENSIONS=("tsx" "jsx" "css" "scss" "vue" "svelte")

# --- INCLUDE patterns: directory prefixes ---
UI_INCLUDE_DIRS=("src/components/" "src/pages/" "src/styles/" "src/ui/" "app/components/")

# --- EXCLUDE patterns: test/spec/config suffixes ---
UI_EXCLUDE_SUFFIXES=("test" "spec" "stories")

# --- EXCLUDE patterns: config extensions ---
UI_EXCLUDE_CONFIG_EXTENSIONS=("tsx" "jsx" "js" "ts" "mjs" "cjs")

# --- EXCLUDE patterns: directory markers ---
UI_EXCLUDE_DIRS=("__tests__" "__mocks__")

# --- EXCLUDE patterns: file prefixes ---
UI_EXCLUDE_PREFIXES=("setupTests")
```

**Functions exported by the file**:

```bash
is_excluded_file() {
    local path="$1"
    # Match *.{test,spec,stories}.{tsx,jsx,...}
    # Match *.config.{tsx,js,...}
    # Match **/__tests__/** and **/__mocks__/**
    # Match **/setupTests.*
    # Returns 0 (excluded) or 1 (not excluded)
}

is_ui_file() {
    local path="$1"
    # Match file extensions from UI_INCLUDE_EXTENSIONS
    # Match directory prefixes from UI_INCLUDE_DIRS
    # Returns 0 (UI file) or 1 (not UI file)
}
```

**Behavioral contract**: The functions MUST produce identical true/false
results as the current inline implementations in `guard-ui-edit.sh` lines
51-64 and 74-85. Zero behavioral change.

### 2.3 Consumer Integration

**Layer / Consumer / Integration Method / Migration Risk**

| Layer | Consumer | Integration Method | Migration Risk |
|-------|----------|-------------------|----------------|
| Hook | `guard-ui-edit.sh` | `source "$REPO_ROOT/tools/aegis-ui-patterns.sh"` at top; replace inline `is_excluded`/`is_ui_file` with sourced versions | Low -- function signatures identical |
| Test | `aegis-block0-f-gate-test.sh` | `source "$(dirname "$0")/aegis-ui-patterns.sh"` in setup; replace inline `is_excluded`/`is_ui_file` | Low -- same functions |
| Test | `aegis-guard-ui-edit-test.sh` | No direct change needed (tests the hook, which now sources SSOT) | None |
| Prose | `nick-fury.md` BLOCK_0F_CHECK | Replace hardcoded pattern list with: `-- Patterns per tools/aegis-ui-patterns.sh (canonical SSOT)` | None -- prose only |
| Prose | `coulson.md` 0F section | Replace hardcoded pattern list with: `Patterns per tools/aegis-ui-patterns.sh (canonical SSOT).` | None -- prose only |

### 2.4 Test: `tools/aegis-ui-patterns-test.sh` -- 6 Cases

| TC | Description | Assertion |
|----|-------------|-----------|
| 1 | Source file sets `UI_INCLUDE_EXTENSIONS` array | Array length >= 6 |
| 2 | Source file sets `UI_INCLUDE_DIRS` array | Array length >= 5 |
| 3 | Source file sets `UI_EXCLUDE_SUFFIXES` array | Array length >= 3 |
| 4 | `is_ui_file` returns 0 for `src/components/Foo.tsx` | Exit code 0 |
| 5 | `is_excluded_file` returns 0 for `Button.test.tsx` | Exit code 0 |
| 6 | Source works from `/tmp` cwd (not repo root) | Arrays populated, functions callable |
| 7 | Source under `set -u` (nounset) causes no unset-variable error | `bash -c 'set -u; source ...; echo ok'` exits 0 |

---

## 3. S3-09: realpath Normalization in guard-ui-edit

### 3.1 Problem

`guard-ui-edit.sh` receives `file_path` from JSON input and matches it
directly against regex patterns. A path like
`src/components/../../../etc/passwd.tsx` matches `\.tsx$` and would be
evaluated as a UI file, when in reality the resolved path is entirely
outside the repository.

### 3.2 Design

Insert path canonicalization immediately after `FILE` extraction (line 24)
and before any pattern matching.

**Resolution strategy (with fallback chain)**:

```
Priority 1: realpath -m "$FILE"     (GNU coreutils, available on Linux)
Priority 2: greadlink -m "$FILE"    (Homebrew coreutils on macOS)
Priority 3: python3 -c "import os; print(os.path.realpath('$FILE'))"
Priority 4: Use $FILE as-is + log warning to activity.log
```

**Additional guard**: After resolution, verify the canonical path starts with
`$REPO_ROOT`. If it does not, exit 0 with a log entry (the file is outside
the repo; not our concern).

**Implementation location**: Between current line 32 (`[[ -z "$FILE" ]] && exit 0`)
and the logging helper on line 35. Approximately 15 lines of new code.

### 3.3 Pseudocode

```bash
# ── STEP 0: Canonicalize path ───────────────────────────────────────────
REPO_ROOT="${AEGIS_REPO_ROOT:-$(pwd)}"

canonicalize() {
    local p="$1"
    if command -v realpath >/dev/null 2>&1; then
        realpath -m "$p" 2>/dev/null && return
    fi
    if command -v greadlink >/dev/null 2>&1; then
        greadlink -m "$p" 2>/dev/null && return
    fi
    python3 -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$p" 2>/dev/null && return
    echo "$p"  # fallback: use as-is
}

# Make path absolute relative to REPO_ROOT if not already absolute
if [[ "$FILE" != /* ]]; then
    FILE="${REPO_ROOT}/${FILE}"
fi
FILE=$(canonicalize "$FILE")

# Guard: if resolved path is outside repo root, allow (not our concern)
if [[ "$FILE" != "${REPO_ROOT}"* ]]; then
    log_decision "ALLOW" "resolved path outside repo root (${FILE})"
    exit 0
fi

# Strip REPO_ROOT prefix for pattern matching (keep relative path form)
FILE="${FILE#${REPO_ROOT}/}"
```

### 3.4 Test Addition to `aegis-guard-ui-edit-test.sh`

| TC | Description | Input | Expected |
|----|-------------|-------|----------|
| PT-1 | Path traversal `src/components/../../../etc/passwd.tsx` | Edit tool, no DESIGN.md | exit 0 (resolved path outside repo, allowed) |

Add as TC-9 (or TC-PT1) after existing TC-8 in `aegis-guard-ui-edit-test.sh`.

---

## 4. S2-06: Track Approved Specs in Git

### 4.1 Problem

`.gitignore` line 2 contains `_aegis-output/` which blanket-ignores all
session artifacts. This is correct for deployments, research, and runtime
output. But approved specs (Iron Man output, Loki-reviewed) are historical
records that should survive `git clean` and be available in PR diffs.

### 4.2 Design

**Change 1: Root `.gitignore`**

Replace:
```
_aegis-output/
```

With:
```
# AEGIS Runtime Output (session artifacts -- research, deployments, qa, etc.)
_aegis-output/*
!_aegis-output/specs/
```

The `/*` glob with `!specs/` negation tracks the `specs/` subdirectory while
ignoring everything else.

**Change 2: `_aegis-output/.gitignore` override**

Create new file:
```gitignore
# Track approved specs (Iron Man output, Loki-reviewed)
# Everything else in _aegis-output/ remains gitignored via root .gitignore
!specs/
!specs/**
```

**Change 3: Ensure `_aegis-output/specs/` directory exists in git**

Add a `.gitkeep` file at `_aegis-output/specs/.gitkeep` if the directory
is empty (unlikely given existing specs, but defensive).

### 4.3 Retroactive Note

The following specs exist locally and will become git-trackable after this
change:

| Spec | Status |
|------|--------|
| S2-03-spec.md | Exists locally |
| S2-04-spec.md | Exists locally |
| S3-VISUAL-LAYER-spec.md | Exists locally |
| S3-06-spec.md | Exists locally |
| PROJ-T-* specs (8 files) | Exists locally |
| dashboard/* (4 files) | Exists locally |

Spider-Man should `git add _aegis-output/specs/` after implementing the
`.gitignore` change to capture all existing specs in the next commit.

### 4.4 Test: `tools/aegis-spec-tracking-test.sh` -- 4 Cases

| TC | Description | Command | Assertion |
|----|-------------|---------|-----------|
| 1 | `_aegis-output/specs/` NOT gitignored | `git check-ignore -q _aegis-output/specs/test.md` | exit != 0 (not ignored) |
| 2 | `_aegis-output/deployments/` IS gitignored | `git check-ignore -q _aegis-output/deployments/foo.txt` | exit 0 (ignored) |
| 3 | `_aegis-output/research/` IS gitignored | `git check-ignore -q _aegis-output/research/bar.md` | exit 0 (ignored) |
| 4 | `_aegis-output/specs/nested/deep.md` NOT gitignored | `git check-ignore -q _aegis-output/specs/nested/deep.md` | exit != 0 (not ignored) |

**Test prerequisite**: Tests must create temp files at those paths to make
`git check-ignore` work correctly (it checks against .gitignore rules for
real paths). Cleanup via `trap`.

---

## 5. S2-05: Promote Resonance to Instinct Lifecycle

### 5.1 Problem

The instinct system has four tiers (`pending/`, `active/`, `promoted/`,
`retired/`) with documented promotion rules in
`.aegis/brain/instincts/README.md`, but no tooling exists to:
- Create a pending instinct from a resonance observation
- Promote through tiers with threshold validation
- List instincts by tier with confidence scores

Currently there are 4 pending instincts, 1 promoted instinct, 0 active
instincts, and 0 retired instincts -- all created manually.

### 5.2 Design: `tools/aegis-instinct-promote.sh`

**CLI interface**:

```
Usage: aegis-instinct-promote.sh <command> [options]

Commands:
  create    --from <resonance-file> [--id <kebab-id>] [--cluster <name>]
  activate  --id <instinct-id>
  promote   --id <instinct-id> [--adr <adr-file>]
  reinforce --id <instinct-id>
  retire    --id <instinct-id>
  list      [--tier pending|active|promoted|retired|all]
```

### 5.3 Instinct YAML Schema

Per existing convention (`.aegis/brain/instincts/README.md`):

```yaml
id: <kebab-case-id>
status: pending | active | promoted | retired
confidence: 0.0-1.0
observations: <integer>
first_seen: <ISO8601 date>
last_reinforced: <ISO8601 date>
cluster: <category-name>
pattern: |
  <multi-line description of the pattern>
rationale: |
  <multi-line rationale for why this pattern matters>
adr_refs: []          # list of ADR file paths (optional enrichment)
retired_reason: ""    # populated only on retire
retired_date: ""      # populated only on retire
```

### 5.4 Promotion Criteria Matrix

| Transition | Confidence | Observations | ADR Required | Human Required |
|------------|-----------|--------------|--------------|----------------|
| resonance -> pending | n/a (set to 0.3) | n/a (set to 1) | No | No |
| pending -> active | > 0.5 | >= 2 | No | No |
| active -> promoted | > 0.8 | n/a | No | No |
| any -> retired | n/a | n/a | No | No |

### 5.5 Command Details

**`create --from <resonance-file>`**

1. Read the resonance file (Markdown in `.aegis/brain/resonance/`)
2. Extract a pattern summary (first non-heading paragraph or `## Pattern` section)
3. Generate kebab-case ID from filename or `--id` flag
4. Create YAML at `.aegis/brain/instincts/pending/<id>.yaml`
5. Set `confidence: 0.3`, `observations: 1`, `first_seen: <now>`, `status: pending`
6. Print confirmation to stdout

**`activate --id <instinct-id>`**

1. Find `pending/<id>.yaml`
2. Validate: `confidence > 0.5` AND `observations >= 2`
3. If validation fails: print rejection reason, exit 1
4. Move file to `active/<id>.yaml`
5. Update `status: active` in YAML
6. Log to `.aegis/brain/logs/activity.log`

**`reinforce --id <instinct-id>`**

1. Find instinct in any tier (pending, active, or promoted)
2. Increment `observations` by 1
3. Set `last_reinforced` to current ISO 8601 timestamp
4. Confidence unchanged (manual adjustment via future tooling)
5. Log to `.aegis/brain/logs/activity.log`

**`promote --id <instinct-id>`**

1. Find `active/<id>.yaml`
2. Validate: `confidence > 0.8`
3. If `--adr <file>` provided: append to `adr_refs` list (optional enrichment, not required)
4. If validation fails: print rejection reason, exit 1
5. Move file to `promoted/<id>.yaml`
6. Update `status: promoted` in YAML
7. Log to `.aegis/brain/logs/activity.log`

**`retire --id <instinct-id>`**

1. Find instinct in any tier (pending, active, or promoted)
2. Move to `retired/<id>.yaml`
3. Update `status: retired`, set `retired_date: <now>`, `retired_reason` from `--reason` flag
4. Log to `.aegis/brain/logs/activity.log` with audit marker
5. If previously promoted: also log to `tools/aegis-log-decision.sh` (autonomous demotion is a decision worth auditing)

**`list [--tier <tier>]`**

1. If `--tier all` or no flag: scan all four directories
2. For each YAML file: extract `id`, `status`, `confidence`, `observations`, `cluster`
3. Print table sorted by confidence descending
4. Format: `<id>  <status>  <confidence>  <observations>  <cluster>`

### 5.6 YAML Parsing Strategy

Use `grep`/`sed` for field extraction (no `yq` dependency). The instinct
YAML schema is simple enough that line-oriented parsing is reliable.

**Field extraction pattern**:
```bash
get_yaml_field() {
    local file="$1" field="$2"
    grep "^${field}:" "$file" | sed "s/^${field}: *//" | tr -d '"' | tr -d "'"
}
```

**Multi-line fields** (`pattern:`, `rationale:`): not parsed by the tool.
Only single-line scalar fields are needed for promotion logic.

### 5.7 Test: `tools/aegis-instinct-promote-test.sh` -- 8 Cases

| TC | Description | Assertion |
|----|-------------|-----------|
| 1 | `create --from` produces valid YAML in `pending/` | File exists, status=pending, confidence=0.3 |
| 2 | `activate` with sufficient confidence+observations | File moves to `active/`, status=active |
| 3 | `activate` rejected: confidence <= 0.5 | Exit 1, file stays in `pending/` |
| 4 | `activate` rejected: observations < 2 | Exit 1, file stays in `pending/` |
| 5 | `promote` with confidence > 0.8 | File moves to `promoted/`, status=promoted |
| 6 | `promote` rejected: confidence <= 0.8 | Exit 1, file stays in `active/` |
| 7 | `retire` moves from any tier to `retired/` | File in `retired/`, retired_date set |
| 8 | `list --tier pending` shows only pending instincts | Output contains pending IDs, not active/promoted |
| 9 | `reinforce` increments observations and updates last_reinforced | observations +1, last_reinforced = today, confidence unchanged |

**Test setup**: Create temp instinct directory tree under `$TMPDIR`. Set
`AEGIS_INSTINCT_ROOT` env var to redirect tool to temp location. Cleanup
via `trap`.

---

## 6. Cross-Story Dependencies

```
S3-05 (SSOT) ──> S3-09 (realpath) uses the sourced functions from SSOT
                  (build S3-05 first, then S3-09 patches the hook)

S2-06 (git tracking) ──> independent, can build in parallel

S2-05 (instinct lifecycle) ──> independent, can build in parallel
```

**Build order recommendation**: S3-05 -> S3-09 -> (S2-06 || S2-05)

S3-09 depends on S3-05 because after S3-05 ships, `guard-ui-edit.sh` will
source `aegis-ui-patterns.sh`. The `realpath` patch (S3-09) modifies the
same file, so S3-05 must land first to avoid merge conflicts.

---

## 7. Acceptance Test Matrix

| Story | Test Script | TC Count | Covers |
|-------|------------|----------|--------|
| S3-05 | `tools/aegis-ui-patterns-test.sh` | 7 | Pattern arrays, functions, cross-cwd sourcing, set -u compat |
| S3-05 | `tools/aegis-block0-f-gate-test.sh` (existing, refactored) | 11 | BLOCK 0F gate logic via SSOT |
| S3-05 | `tools/aegis-guard-ui-edit-test.sh` (existing, unchanged) | 12 | Hook behavior unchanged after SSOT swap |
| S3-09 | `tools/aegis-guard-ui-edit-test.sh` (extended +1 TC) | 13 | Path traversal rejection |
| S2-06 | `tools/aegis-spec-tracking-test.sh` | 4 | gitignore carve-out correctness |
| S2-05 | `tools/aegis-instinct-promote-test.sh` | 9 | Full lifecycle: create/activate/reinforce/promote/retire/list |
| **Total** | | **20 new + 23 existing** | |

**Regression guard**: All existing tests (11 block0-f + 12 guard-ui-edit)
must continue to pass after S3-05 refactor. The SSOT swap is a refactor,
not a behavior change.

### bash -n Syntax Check Requirement

All new scripts MUST pass `bash -n <script>` (syntax check without execution):

| Script | Check |
|--------|-------|
| `tools/aegis-ui-patterns.sh` | `bash -n tools/aegis-ui-patterns.sh` |
| `tools/aegis-ui-patterns-test.sh` | `bash -n tools/aegis-ui-patterns-test.sh` |
| `tools/aegis-spec-tracking-test.sh` | `bash -n tools/aegis-spec-tracking-test.sh` |
| `tools/aegis-instinct-promote.sh` | `bash -n tools/aegis-instinct-promote.sh` |
| `tools/aegis-instinct-promote-test.sh` | `bash -n tools/aegis-instinct-promote-test.sh` |

---

## 8. Architecture Decision Records

### ADR-S3-05: SSOT via Source-able Bash Arrays

**Context**: UI patterns duplicated across 4+ files. Alternatives considered:

| Option | Mechanism | Pros | Cons |
|--------|-----------|------|------|
| A) Source-able bash file (chosen) | `source tools/aegis-ui-patterns.sh` | Zero-dependency, native bash, no new format | Functions must match existing regex exactly |
| B) JSON config + jq parser | JSON file + `jq` extraction | Structured, easy to extend | Adds jq dependency; hooks parse JSON already via python3 |
| C) Shared environment variable | `AEGIS_UI_PATTERNS` env var | Simple export | Arrays don't survive env var serialization cleanly |

**Decision**: Option A. Bash source is the native integration pattern for
the hook system. No new dependencies. The SSOT file lives in `tools/` alongside
the consumers that source it.

### ADR-S3-09: realpath Fallback Chain

**Context**: macOS ships without GNU `realpath`. Alternatives:

| Option | Availability | Handles `-m` (missing path) |
|--------|-------------|---------------------------|
| `realpath -m` | Linux, Homebrew | Yes |
| `greadlink -m` | Homebrew `coreutils` | Yes |
| `python3 os.path.realpath` | macOS + Linux | Yes (always resolves) |
| No-op (use as-is) | Universal | No resolution |

**Decision**: Try all three in order, fall back to no-op with warning log.
The python3 fallback is always available in Claude Code environments.

### ADR-S2-06: gitignore Negation Pattern

**Context**: Git negation requires the parent directory to use a wildcard
(`_aegis-output/*` not `_aegis-output/`). Using the bare directory name
without wildcard makes negation impossible.

**Decision**: Change `_aegis-output/` to `_aegis-output/*` plus `!_aegis-output/specs/`.
Add `_aegis-output/.gitignore` for clarity. This is the standard git
negation pattern documented in `gitignore(5)`.

---

## 9. Non-Functional Requirements

| Category | Requirement | Story |
|----------|-------------|-------|
| Performance | `aegis-ui-patterns.sh` source time < 10ms (no subshell, no I/O) | S3-05 |
| Performance | `realpath` resolution adds < 5ms per hook invocation | S3-09 |
| Security | Path traversal outside repo root is silently allowed (not our file) | S3-09 |
| Security | Instinct retire requires explicit `--reason` flag (audit trail) | S2-05 |
| Compatibility | All scripts work on macOS (zsh default) and Linux (bash 4+) | All |
| Compatibility | No new binary dependencies (python3 is the only allowed fallback) | All |
| Backward Compat | Zero behavioral change for existing callers after S3-05 SSOT swap | S3-05 |
| Idempotency | `aegis-instinct-promote.sh create` is idempotent (re-run = no-op if exists) | S2-05 |

---

## 10. Trust Zones and Data Access

| Zone | Auth | Data Access | Stories |
|------|------|-------------|---------|
| Hook runtime | None (PreToolUse) | Read: JSON stdin, FS pattern check | S3-05, S3-09 |
| Test runtime | None (bash scripts) | Read/write: temp dirs only | All |
| Brain filesystem | Agent-level (in-process) | Read/write: `.aegis/brain/instincts/` | S2-05 |
| Git config | Agent-level | Read/write: `.gitignore` | S2-06 |
| Activity log | Append-only | `.aegis/brain/logs/activity.log` | S3-09, S2-05 |

### Severity and Escalation

| Severity | Trigger | Handler | Escalation |
|----------|---------|---------|------------|
| P0 | Hook crash on every invocation | Thor: rollback hook change | Human 5 min |
| P1 | SSOT source failure (arrays empty) | Spider-Man: fix source path | Human 1 hr |
| P2 | realpath fallback to no-op | Log warning, continue | Sprint retro |
| P3 | Instinct promote threshold off-by-one | Fix in next sprint | Backlog |

---

## 11. Do's and Don'ts

### Do's

- DO source `aegis-ui-patterns.sh` using `$(git rev-parse --show-toplevel)` or `$AEGIS_REPO_ROOT` to resolve path from any cwd
- DO keep `is_excluded_file` and `is_ui_file` function signatures identical to the current inline versions (same argument, same return code semantics)
- DO run all 23 existing tests after S3-05 refactor to confirm zero behavioral change
- DO use `realpath -m` (the `-m` flag handles non-existent path components, which is the traversal case)
- DO strip the `$REPO_ROOT/` prefix after canonicalization so pattern matching operates on relative paths
- DO use `git check-ignore -q` (quiet mode) in spec-tracking tests for clean exit-code assertions
- DO create instinct YAML via `cat << EOF` heredoc to avoid quoting issues with multi-line fields
- DO log every instinct tier transition to `activity.log` with ISO 8601 timestamp
- DO validate `bash -n` on every new script before committing

### Don'ts

- DON'T add `yq` or `jq` as dependencies -- use grep/sed for YAML field extraction
- DON'T change the pattern lists themselves in S3-05 -- this story is a refactor, not a feature change
- DON'T use `readlink -f` on macOS (it does not support `-f`; use `greadlink` from Homebrew or python3 fallback)
- DON'T remove the `_aegis-output/*` gitignore entry entirely -- only carve out `specs/`
- DON'T allow `instinct-promote.sh retire` without `--reason` flag -- audit trail is mandatory
- DON'T create `active/` directory instincts with confidence < 0.5 even if manually edited
- DON'T assume `AEGIS_REPO_ROOT` is set -- always provide `$(pwd)` fallback

---

## 12. Agent Prompt Guide

### Prompt 1: S3-05 -- Pattern SSOT (Spider-Man)

```
Build tools/aegis-ui-patterns.sh per S-V9-04-REMAINING-spec.md section 2.
Extract the EXACT regex patterns from guard-ui-edit.sh lines 51-64 (is_excluded)
and lines 74-85 (is_ui_file) into the new file. Provide is_excluded_file and
is_ui_file functions with identical behavior. Then refactor guard-ui-edit.sh to
source the new file (remove inline functions, add source line). Refactor
aegis-block0-f-gate-test.sh similarly. Update nick-fury.md BLOCK_0F_CHECK and
coulson.md 0F section prose to reference the SSOT. Create
aegis-ui-patterns-test.sh with 6 TCs. Run ALL existing tests to confirm zero
regression. bash -n all new files.
```

### Prompt 2: S3-09 -- realpath Normalization (Spider-Man)

```
Patch guard-ui-edit.sh per S-V9-04-REMAINING-spec.md section 3. Add the
canonicalize function with realpath/greadlink/python3 fallback chain. Insert
path resolution between FILE extraction and EXCLUDE check. Add repo-root
boundary guard. Add TC-PT1 to aegis-guard-ui-edit-test.sh testing
src/components/../../../etc/passwd.tsx path traversal. Run full test suite.
```

### Prompt 3: S2-06 -- Spec Git Tracking (Spider-Man)

```
Implement S2-06 per S-V9-04-REMAINING-spec.md section 4. Change root .gitignore
line 2 from "_aegis-output/" to "_aegis-output/*" plus "!_aegis-output/specs/".
Create _aegis-output/.gitignore with "!specs/" and "!specs/**". Run
git check-ignore on test paths to verify. Create
tools/aegis-spec-tracking-test.sh with 4 TCs. git add _aegis-output/specs/ to
capture existing approved specs.
```

### Prompt 4: S2-05 -- Instinct Lifecycle (Spider-Man)

```
Build tools/aegis-instinct-promote.sh per S-V9-04-REMAINING-spec.md section 5.
Implement create/activate/reinforce/promote/retire/list commands. Use grep/sed for YAML
parsing (no yq). Support AEGIS_INSTINCT_ROOT env override for testing. Create
tools/aegis-instinct-promote-test.sh with 8 TCs using temp directory. Validate
promotion thresholds match README.md (pending->active: conf>0.5, obs>=2;
active->promoted: conf>0.8, no ADR required). bash -n both files.
```

---

*Spec v1.1 -- Loki D-044 conditions addressed 2026-04-23 by Iron Man cycle 10.*
*Sprint: v9-04 | Total: 9pt | Stories: 4 | New tests: 20 TC | Existing tests: 23 TC (regression guard)*
