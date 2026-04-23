# S2-04 Spec: BLOCK 0 Lite-Mode Tag-Override Validation (Loki Counter)

> A defense-in-depth safety net. When a task is tagged `chore` or `typo` but
> its diff touches security-sensitive paths, something is wrong -- either the
> tag is stale, or an agent is gaming lite-mode to skip SI.01 enforcement.
> Loki intercepts this during his pre-review instinct load, forces the mode
> to `full`, increments a tamper counter, and emits a finding. The system
> optimizes for paranoia over convenience on auth paths: a false positive
> costs one re-review; a false negative ships unreviewed security code.

## 1. Problem Statement

S2-03 shipped BLOCK 0 lite-mode switching. Black Panther's review accepted
finding S-01: **stale-pin bypass risk**. A task pinned as `block0_mode: lite`
(e.g., tagged `typo`) that later touches `auth/login.ts` would skip SI.01
generation entirely -- no requirements spec, no security review. The existing
helper (`tools/aegis-block0-mode.sh`) trusts a pinned mode unconditionally
(line 74-76: `if pinned: print(__PINNED__<mode>)`).

This spec adds Loki as the counter-party validator. Loki already fires an
"Instinct Loading" pass before every review (loki.md line 83-98). This spec
extends that pass with a security-path scan that overrides lite/standard
pins when the task diff intersects sensitive paths.

SI.01 requirements addressed:
- **REQ-V9-02-05**: Loki MUST auto-override lite-tagged tasks to full-mode
  when they touch security-sensitive paths.
- **REQ-V9-02-06**: Every override MUST increment a counter in
  `.aegis/brain/state/override-counter.json` and log via Loki's adversarial
  report.

## 2. Scope

| In Scope | Out of Scope |
|----------|-------------|
| Loki override logic during pre-review pass | Modifying `aegis-block0-mode.sh` precedence |
| Security-sensitive path pattern registry | New agent prompts or roles |
| Override counter schema + atomic writes | Dashboard or UI for counter stats |
| Override enforcement test script | Behavioral end-to-end harness |
| meta.json rewrite on override | Nick Fury tag-legitimacy audit (separate concern) |

## 3. Architecture

### Layer / Responsibility / Interface

| Layer | Responsibility | Interface |
|-------|----------------|-----------|
| Loki Pre-Review | Detect mode/path mismatch during instinct load | `loki.md` Instinct Loading section (agent prompt) |
| Path Registry | Define security-sensitive path patterns | `tools/aegis-security-paths.sh` (stdout: newline-separated regexes) |
| Override Writer | Rewrite meta.json `block0_mode` to `full` | Inline in Loki's review procedure |
| Counter | Track override frequency and history | `.aegis/brain/state/override-counter.json` |
| Activity Log | Audit trail for overrides | `.aegis/brain/logs/activity.log` |

### Trigger / Detection Mechanism / Override Action

| Trigger | Detection | Override Action |
|---------|-----------|-----------------|
| Task diff touches `auth/` path | Regex match on changed-file list | Force `block0_mode = full` in meta.json |
| Task diff touches `credentials/` path | Regex match on changed-file list | Force `block0_mode = full` in meta.json |
| Task diff touches `.env*` files | Regex match on changed-file list | Force `block0_mode = full` in meta.json |
| Task diff touches `secrets/` path | Regex match on changed-file list | Force `block0_mode = full` in meta.json |
| Task diff touches `.ssh/` path | Regex match on changed-file list | Force `block0_mode = full` in meta.json |
| Task diff touches `tokens/` path | Regex match on changed-file list | Force `block0_mode = full` in meta.json |
| Task diff touches `.claude/agents/` path | Regex match on changed-file list | Force `block0_mode = full` in meta.json |
| Task already `full` mode | No mismatch detected | No action (skip counter) |

### Path Pattern / Regex / Category

| Path Pattern | Regex | Category |
|-------------|-------|----------|
| `auth/` directory | `(^|\/)auth\/` | auth |
| `credentials/` directory | `(^|\/)credentials\/` | credentials |
| `.env` files (all variants) | `(^|\/)\.env` | env |
| `secrets/` directory | `(^|\/)secrets\/` | secrets |
| `.ssh/` directory | `(^|\/)\.ssh\/` | ssh |
| `tokens/` directory | `(^|\/)tokens\/` | tokens |
| `.claude/agents/` directory | `(^|\/)\.claude\/agents\/` | agent-prompts |
| `**/password*` files | `(^|\/)password` | credentials |
| `**/secret*` files | `(^|\/)secret($\|[^s])` | secrets |
| `**/api-key*` files | `(^|\/)api-key` | credentials |

**Negative cases (MUST NOT trigger)**:
| Path | Why NOT sensitive |
|------|-------------------|
| `src/auth-docs.md` | `auth-` prefix, not `auth/` directory |
| `docs/authentication-guide.md` | Documentation, not auth code |
| `src/components/Authorize.tsx` | Component name contains "auth" substring only |
| `tests/auth/` | Triggers -- test files for auth paths ARE sensitive |

### Severity / Loki Action / Counter Behavior

| Severity | Condition | Loki Action | Counter |
|----------|-----------|-------------|---------|
| OVERRIDE | lite/standard task touches sensitive path | Force `full`, emit `[LOKI:override]` finding | Increment `total_overrides`, append to `recent[]` |
| INFO | full-mode task touches sensitive path | Log confirmation, no override needed | No increment |
| CLEAR | Task does NOT touch sensitive paths | No action | No change |

## 4. Implementation Plan

### 4a. Loki Agent Prompt Extension (`loki.md`)

After the existing Instinct Loading section (lines 83-98), add a
**Security Path Override** procedure:

```
SECURITY_PATH_OVERRIDE(task, review_context):
  1. Resolve current mode:
     MODE = task.meta.json.block0_mode (default: "full")
     IF MODE == "full":
       RETURN  # already maximum enforcement, nothing to override

  2. Collect changed files:
     FILES = git diff --name-only for the task's branch/PR
     (or: review_context.changed_files if available from the review payload)

  3. Match against security patterns:
     PATTERNS = [
       "(^|/)auth/",
       "(^|/)credentials/",
       "(^|/)\.env",
       "(^|/)secrets/",
       "(^|/)\.ssh/",
       "(^|/)tokens/",
       "(^|/)\.claude/agents/",
       "(^|/)password",
       "(^|/)secret($|[^s])",
       "(^|/)api-key"
     ]
     MATCHED = []
     FOR each file in FILES:
       FOR each pattern in PATTERNS:
         IF file matches pattern:
           MATCHED.append({file, pattern, category})

  4. If any match found:
     a. Rewrite task meta.json: block0_mode = "full"
     b. Increment override counter (see §4c)
     c. Emit finding in review:
        "[LOKI:override] task=<ID> was=<old_mode> now=full
         triggered_by=<first matched file> category=<cat>
         reason=security-sensitive path detected"
     d. Log to activity.log:
        "[LOKI:override] task=<ID> mode <old>->full paths=[matched list]"

  5. Continue with standard review (now in full-mode context)
```

### 4b. Path Registry (`tools/aegis-security-paths.sh`)

A standalone helper that emits the security-sensitive path regexes, one per
line. This centralizes pattern maintenance -- both the test script and Loki's
runtime reference the same source of truth.

```bash
#!/usr/bin/env bash
# Emit security-sensitive path patterns (one regex per line)
# Used by: Loki override logic, tools/aegis-s204-override-test.sh
cat <<'EOF'
(^|/)auth/
(^|/)credentials/
(^|/)\.env
(^|/)secrets/
(^|/)\.ssh/
(^|/)tokens/
(^|/)\.claude/agents/
(^|/)password
(^|/)secret($|[^s])
(^|/)api-key
EOF
```

### 4c. Override Counter Schema

File: `.aegis/brain/state/override-counter.json`

```json
{
  "total_overrides": 0,
  "last_override_at": null,
  "by_category": {
    "auth": 0,
    "credentials": 0,
    "env": 0,
    "secrets": 0,
    "ssh": 0,
    "tokens": 0,
    "agent-prompts": 0
  },
  "recent": []
}
```

Each `recent` entry:
```json
{
  "ts": "2026-04-22T14:30:00Z",
  "task_id": "S2-04",
  "was_mode": "lite",
  "triggered_by_path": "auth/login.ts",
  "category": "auth"
}
```

`recent` is capped at 10 entries (FIFO eviction). This bounds file size
while preserving enough history for sprint retrospectives.

### 4d. Atomic Counter Update

Counter updates use a lockfile to prevent corruption from concurrent
Loki reviews (unlikely in single-agent mode, but defensive):

```
UPDATE_COUNTER(task_id, was_mode, trigger_path, category):
  1. Read current override-counter.json (create with zeros if missing)
  2. Increment total_overrides
  3. Set last_override_at = ISO-8601 now
  4. Increment by_category[category]
  5. Prepend new entry to recent[]
  6. If len(recent) > 10: trim to 10
  7. Write to mktemp file in same directory
  8. Acquire lock:
     exec 200>"$COUNTER.lock"
     flock -x 200 || { echo "lock timeout" >&2; exit 1; }
  9. Read current counter (re-read under lock), increment, write to
     tmp, mv tmp to final (now safe under exclusive lock)
  10. Release lock: flock -u 200 (or let fd close on exit)
```

**macOS compatibility note:** `flock` is available on macOS 10.14+ (via
Homebrew or system). On older macOS where `flock` is unavailable, gracefully
degrade to last-writer-wins + log a warning to stderr -- acceptable for v1
since override events are rare and the counter is advisory, not transactional.

### 4e. Meta.json Rewrite

When Loki overrides, it rewrites the task's meta.json:

```json
{
  "block0_mode": "full",
  "block0_override": {
    "original_mode": "lite",
    "overridden_by": "loki",
    "overridden_at": "2026-04-22T14:30:00Z",
    "reason": "security-sensitive path: auth/login.ts"
  }
}
```

The `block0_override` object provides audit trail. Nick Fury's subsequent
BLOCK 0 check reads `block0_mode: full` and enforces all five checks.

## 5. Enforcement Test

File: `tools/aegis-s204-override-test.sh`

Test cases:

| TC | Setup | Assert |
|----|-------|--------|
| TC-01 | meta `block0_mode: lite`, diff contains `auth/login.ts` | meta rewritten to `full`, counter incremented, `[LOKI:override]` in log |
| TC-02 | meta `block0_mode: lite`, diff contains `src/credentials/store.ts` | meta rewritten to `full`, category=credentials |
| TC-03 | meta `block0_mode: lite`, diff contains `.env.production` | meta rewritten to `full`, category=env |
| TC-04 | meta `block0_mode: lite`, diff contains `secrets/api.json` | meta rewritten to `full`, category=secrets |
| TC-05 | meta `block0_mode: standard`, diff contains `auth/middleware.ts` | meta rewritten to `full` (standard also overridden) |
| TC-06 | meta `block0_mode: full`, diff contains `auth/login.ts` | NO override (already full), counter NOT incremented |
| TC-07 | meta `block0_mode: lite`, diff contains `src/auth-docs.md` | NO override (negative case: `auth-` != `auth/`) |
| TC-08 | meta `block0_mode: lite`, diff contains `docs/authentication-guide.md` | NO override (negative case: substring match) |
| TC-09 | meta `block0_mode: lite`, diff contains `src/components/Authorize.tsx` | NO override (negative case: component name) |
| TC-10 | meta `block0_mode: lite`, diff contains `.claude/agents/loki.md` | meta rewritten to `full`, category=agent-prompts |
| TC-11 | Counter starts at 0, TC-01 runs, then TC-02 runs | `total_overrides == 2`, `by_category.auth == 1`, `by_category.credentials == 1` |
| TC-12 | 12 consecutive overrides | `recent[]` length == 10 (FIFO cap) |
| TC-13 | meta `block0_mode: lite`, diff contains `.ssh/id_rsa` | meta rewritten to `full`, category=ssh |
| TC-14 | meta `block0_mode: lite`, diff contains `tokens/api.json` | meta rewritten to `full`, category=tokens |

Each test case:
1. Creates temp directory with mock meta.json and mock diff file list
2. Invokes the override logic (a testable function extracted to
   `tools/aegis-s204-override-check.sh`)
3. Asserts meta.json content, counter state, and log output

## 6. Acceptance Criteria

- [ ] Loki's pre-review pass includes security-path scan before any spec review
- [ ] Path patterns match `auth/`, `credentials/`, `.env*`, `secrets/`, `.ssh/`,
      `tokens/`, `.claude/agents/`, `password*`, `secret*` (not `secrets/`),
      `api-key*`
- [ ] Override rewrites `block0_mode` to `full` in task meta.json
- [ ] Override adds `block0_override` audit object to meta.json
- [ ] Override increments `.aegis/brain/state/override-counter.json`
- [ ] Override emits `[LOKI:override]` line in activity.log
- [ ] Override emits a finding in Loki's review output
- [ ] Already-full-mode tasks do NOT trigger override or counter increment
- [ ] Negative cases (`src/auth-docs.md`, `docs/authentication-guide.md`,
      `src/components/Authorize.tsx`) do NOT trigger override -- tested by
      TC-07, TC-08, TC-09
- [ ] Counter `recent[]` is capped at 10 entries
- [ ] `tools/aegis-s204-override-test.sh` passes all 14 test cases
- [ ] `tools/aegis-security-paths.sh` exists and emits the canonical pattern list

## 7. Do's and Don'ts

**Do:**
- Always override to `full` -- never to `standard` (security paths deserve
  maximum enforcement)
- Always preserve the `block0_override` audit trail in meta.json (never
  silently overwrite)
- Always log overrides to both activity.log AND the counter file (dual write
  for auditability)
- Always run the path check BEFORE the substantive review begins (override
  must fire even if Loki would otherwise APPROVE)
- Always include at least one negative-case assertion in the test suite
  (prevents regex over-matching)
- Use `tools/aegis-security-paths.sh` as the single source of truth for
  patterns (both runtime and test reference it)
- Create the counter file with zero-state if missing (no crash on first run)
- Cap `recent[]` at 10 entries to bound file growth

**Don't:**
- Don't modify `tools/aegis-block0-mode.sh` -- the override lives in Loki's
  review layer, not in the mode determiner (separation of concerns)
- Don't treat override as a blocking error -- it is a corrective action, not
  a REJECT (the review continues in full mode)
- Don't skip the override for `standard` mode -- `standard` also skips SI.02,
  which may be needed for security paths
- Don't match path substrings without anchoring -- `auth-docs.md` must NOT
  match the `auth/` pattern (use `(^|/)auth/` not `auth`)
- Don't increment the counter for already-full-mode tasks (that would inflate
  the metric and mask real overrides)
- Don't store unlimited history in `recent[]` -- 10 entries is the cap
- Don't use `>` redirect for counter writes -- use `flock` + `mktemp` + `mv`
  for atomicity (see section 4d)
- Don't add new security patterns without adding a corresponding positive
  AND negative test case

## 8. Agent Prompt Guide (Handoff)

**Spider-Man: Add Security Path Override to loki.md**
```
Read .claude/agents/loki.md lines 83-98 (Instinct Loading section). After
line 98, add a new section "## Security Path Override (S2-04)" containing
the SECURITY_PATH_OVERRIDE procedure from spec section 4a. The procedure
reads task meta.json, collects changed files, matches against patterns from
tools/aegis-security-paths.sh, and on match: rewrites meta.json to full,
increments override-counter.json, emits [LOKI:override] log line.
```

**Spider-Man: Create path registry and override checker**
```
Create two files:
1. tools/aegis-security-paths.sh — emits security-sensitive path regexes
   (one per line). Must be executable. See spec section 4b for content.
2. tools/aegis-s204-override-check.sh — testable function that takes
   a meta.json path and a file-list path, runs the pattern match, and
   performs the override + counter update. This is the unit under test
   for the test script. Use patterns from aegis-security-paths.sh
   (source it, don't hardcode).
```

**Spider-Man: Create override counter seed file**
```
Create .aegis/brain/state/override-counter.json with the zero-state schema
from spec section 4c. Ensure by_category has keys for: auth, credentials,
env, secrets, ssh, tokens, agent-prompts. recent is an empty array.
total_overrides is 0. last_override_at is null.
```

**Thor: Run enforcement test suite**
```
Run tools/aegis-s204-override-test.sh. All 14 test cases must pass.
Pay special attention to:
- TC-07/08/09 (negative cases): these prevent regex over-matching
- TC-11 (cumulative counter): total_overrides must equal sum of runs
- TC-12 (FIFO cap): recent[] must not exceed 10 entries
- TC-13/14 (.ssh/ and tokens/ paths): every security category must have coverage
If any fail, the policy-without-test bug class has recurred.
```

**Thor: Validate no regression on S2-03 gate tests**
```
Run tools/aegis-block0-gate-test.sh. All 22 assertions must still pass.
The S2-04 override logic lives in Loki's layer and must NOT alter the
mode helper's behavior. If any S2-03 test fails, the separation of
concerns between mode-determination and mode-override has been violated.
```

---

*Spec author: Iron Man | Task: S2-04 | Sprint: sprint-v9-02*
*Pairs with: S2-03 (BLOCK 0 lite-mode gate switching, PR #39)*
*Mitigates: Black Panther finding S-01 (stale-pin bypass risk)*
*Requires Loki Plan-Approval Gate review before Spider-Man implementation.*
*v1.1 -- Loki D-011 conditions addressed 2026-04-23 by Iron Man*
