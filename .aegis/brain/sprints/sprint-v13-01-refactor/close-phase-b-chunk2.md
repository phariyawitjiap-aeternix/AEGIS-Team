# Sprint v13-01 Phase B Chunk 2 Close: 1 portable graduation + audit fixes + Linux find compat

**Status**: CLOSED · 2pt of 5pt remaining (40% of remaining Phase B done — 1pt graduation + 1pt audit/script fixes)
**Date**: 2026-05-07
**Branch**: `sprint-v13-01-phase-b-chunk2`
**Phase B of 5** — see [plan.md](plan.md). A + D already CLOSED in PRs #139 + #140. B chunk-1 in PR #141.

## Stories shipped

| ID | Story | Pt | Status |
|----|-------|----|--------|
| **B-grad-2** | Graduate `aegis-instinct-promote-test` (silent-exit bug, not "fixture isolation") — passes both platforms | 1 | DONE |
| **B-fix-1** | `tools/aegis-trace-audit.sh` teaches itself `_archived/`+`tests/` fallbacks; SI.02 ghost paths corrected (7 rows + tinman-heartbeat dropped) | 0.5 | DONE |
| **B-fix-2** | `tests/run-all.sh` drops GNU-incompatible `find -perm +111` (caused silent "no tests found" on Ubuntu CI since Phase D) | 0.5 | DONE |

Total: **2pt** out of Phase B's 5pt remaining. 3pt left.

**Partial story** — `aegis-trace-audit-test` graduation **deferred** to chunk-3:
- Test passes on macOS dev + macOS-latest CI (verified: 4/4)
- Fails on ubuntu-latest CI on T1+T2 ("audit exits non-zero on clean state")
- Suspected cross-platform drift in Check 4 FUNC-catalog regen or Check 5 doc-registry — needs Linux repro to root-cause
- Audit-script and SI.02 improvements still ship (real value preserved)

## What actually broke (and what the audit got wrong — again)

Same pattern as B chunk-1: the plan §6 audit's verdict was wrong, but in a productive way — running the tests revealed the *actual* bug class.

### Bug 1: `aegis-instinct-promote-test` — silent-exit, not fixture-state

The audit said "brain-state-dependent; passes in clean fixture, fails when meta repo's real instinct dir has accumulated state."

What was actually happening:

```bash
run_test() {
    local num="$1"; local desc="$2"; local result="$3"
    if [[ "$result" == "pass" ]]; then
        PASS=$((PASS + 1))
        [[ $VERBOSE -eq 1 ]] && echo "  PASS [TC-${num}]: ${desc}"  # ← problem
    else
        FAIL=$((FAIL + 1))
        echo "  FAIL [TC-${num}]: ${desc}"
    fi
}
```

When `VERBOSE=0` (default) and the result was `pass`, the function's last expression was a short-circuit AND that returned **non-zero**. Combined with `set -e` enabled mid-script (lines 114, 130, 165, 204), the script silently exited after `run_test 3`. No "FAIL", no error — just truncated output.

Fix:

```diff
     if [[ "$result" == "pass" ]]; then
         PASS=$((PASS + 1))
         [[ $VERBOSE -eq 1 ]] && echo "  PASS [TC-${num}]: ${desc}"
     else
         FAIL=$((FAIL + 1))
         echo "  FAIL [TC-${num}]: ${desc}"
     fi
+    return 0
 }
```

One line. Test now **10/10 pass** with no fixture changes. The "real instinct dir has accumulated state" hypothesis was a guess that turned out to be a fairy tale — I checked, the real instinct dir was empty.

### Bug 2: `aegis-trace-audit-test` — real drift, not "needs more assertions"

The audit said "surface-only test (6 assertions); strengthen to ≥15 including PII patterns."

The test had 4 cases — all valid. They were failing because `tools/aegis-trace-audit.sh` correctly found **15 ghost references** in `_aegis-output/iso-docs/SI-02-traceability-matrix/current.md`. Categorized:

| Category | Count | Why it's a ghost |
|----------|-------|------------------|
| Path drifts (older sprint moved tools/→tests/) | 8 | `tools/aegis-X-test.sh` → `tests/aegis-X-test.sh` |
| Phase A archive (this sprint, PR #139) | 2 | `tools/aegis-apply-mbp-guard.sh` → `tools/_archived/...` |
| Truly stale (deprecated commands/hooks) | 5 | e.g. `tinman-heartbeat.sh` (Nick Fury became persona overlay per ADR-008, not heartbeat daemon) |

Two-pronged fix:

**(a) Audit teaches itself fallbacks** — `tools/aegis-trace-audit.sh` Check 2 now recognizes:

```bash
# Fallback 1: tools/aegis-X.sh → tools/_archived/aegis-X.sh
archived_path="${PROJECT_ROOT}/${dir}/_archived/${base}"
if [ -e "$archived_path" ]; then
  ARCHIVED_COUNT=$((ARCHIVED_COUNT + 1))
  warn "Archived reference (in _archived/): $ref_path"
  continue
fi

# Fallback 2: tools/aegis-X-test.sh → tests/aegis-X-test.sh
if echo "$base" | grep -qE '\-test\.sh$'; then
  moved_path="${PROJECT_ROOT}/tests/${base}"
  if [ -e "$moved_path" ]; then
    MOVED_COUNT=$((MOVED_COUNT + 1))
    warn "Moved reference (now in tests/): $ref_path → tests/${base}"
    continue
  fi
fi
```

Reduced 15 ghosts → 5 true ghosts + 2 archived (warn) + 8 moved (warn).

**(b) SI.02 paths corrected to disk truth** — five edits:

| Row | Was | Now |
|-----|-----|-----|
| FR-11 | `.claude/commands/aegis-doctor.md` | `skills/aegis-doctor.md` |
| FR-13 | `tools/aegis-block0-{gate,mode}-test.sh` | `tests/aegis-block0-{gate,mode}-test.sh` |
| FR-14 | `tools/aegis-guard-{write,ui-edit}-test.sh` | `tests/aegis-guard-{write,ui-edit}-test.sh` + `.claude/hooks/` prefix on the source files |
| FR-15/16 | `tools/test-f1-03-judgment-counter.sh` | `tests/aegis-distill-counter-test.sh` |
| FR-17 | `tools/aegis-{block0-f-gate,design-lint,design-fetch}-test.sh` | `tests/...` |
| FR-19 | `tools/test-s2-10-policy-audit.sh` | "Manual audit + CI lint workflow (sprint-v13-01-D)" |
| NFR-08 | `tools/aegis-test-harness-template.sh`, `tools/test-f1-04-harness-self-test.sh` | `tests/run-all.sh`, `.github/workflows/test.yml`, `tests/aegis-doc-canon-lint-test.sh` |

Plus removed the deprecated `tinman-heartbeat.sh` row entirely (FR-13's other entries cover the actual implementation).

Result: audit **5/5 pass + 2 archived warns + 0 ghosts** (exit 0). Test **4/4 pass**.

## Lessons that recur (B chunk-1 + B chunk-2 say the same thing)

1. **Audits-by-file-stat lie. RUN the test first.** Both this chunk and chunk-1 had the audit's verdict overridden by reality:
   - Chunk-1: "block0-f-gate is surface-only" → actually had 11 cases, real bug was `$(dirname "$0")` misuse.
   - Chunk-2 bug 1: "instinct-promote is fixture-dependent" → actually a `set -e` + `&&` short-circuit silent exit.
   - Chunk-2 bug 2: "trace-audit needs more assertions" → actually the audit was *working* and finding real drift.

   **The audit's grep-for-pass/fail-count metric is a heuristic, not a verdict.** The actual graduations all reduced to "RUN the test, find the real cause, fix that."

2. **`set -e` + `&&` short-circuit is a recurring footgun in this codebase.** Every function that has a conditional-side-effect tail line is at risk. Worth a sweep — `grep -rn '\&\&' tests/ tools/ | grep -v '#' | wc -l` shows the surface area. Filed as a B chunk-3 candidate.

3. **Ghost-ref drift is a SI.02 governance failure, not a test failure.** The trace-audit script is doing exactly what we need — telling us the doc lies. The right move is fixing the doc + teaching the audit to be lenient about known archive patterns. Both landed.

## Acceptance evidence

- [x] `aegis-instinct-promote-test`: **10/10 pass** on macOS local + cross-platform portable (was silent-exit after 3)
- [x] `aegis-trace-audit-test`: **4/4 pass** on macOS local + macOS-latest CI (Ubuntu CI deferred to chunk-3)
- [x] `tools/aegis-trace-audit.sh` standalone: 5/5 pass + 2 archived warnings + 0 ghosts (exit 0)
- [x] `_aegis-output/iso-docs/SI-02-traceability-matrix/current.md`: 0 path drifts, deprecated tinman-heartbeat row removed
- [x] `tests/run-all.sh`: now finds 44 tests on Linux (was 0 due to GNU-incompatible `-perm +111`)
- [x] Full suite local: **42 pass · 2 known-failure · 0 fail · exit 0 · 92s**
- [x] `tests/_known-failures.txt`: instinct-promote graduated; trace-audit re-pinned with Linux-only annotation
- [x] No other tests regress
- [x] All 9 governance docs lint clean
- [x] CI matrix: macOS-latest 3 fails (brain-search/maintainer/pattern-mine — pre-existing env issues, same as PR #141), Ubuntu 4 fails (above 3 + brain-adversarial — also pre-existing). Net improvement: chunk-2 strictly reduces CI failures vs PR #141 (4→3 on macOS) while shipping 1 portable graduation.

## v13-01 sprint progress after Phase B chunk-2

```
v13-01 refactor:    12 / 24 pt  =  50.0%
  ✅ Phase A — dead code removal      3 / 3   PR #139
  ⏳ Phase B — test coverage           5 / 8   2pt B1 (PR #141) + 2pt B2 (this PR) + 1pt absorbed in D
  ⏳ Phase C — agent visibility        0 / 3
  ✅ Phase D — CI/CD                   5 / 5   PR #140
  ⏳ Phase E — refactor hot files     0 / 5

Phase B remaining: 3pt
  - 1 known-failure still flagged (aegis-install-v11-delivery — needs manifest rewrite)
  - Tests for ~10 high-leverage untested tools — pick 2-3 for chunk 3
```

## Next chunk per plan §"Sequencing"

**Phase B chunk 3** (~3pt, next PR):
1. Root-cause + graduate `aegis-trace-audit-test` on Ubuntu CI (likely `LC_ALL=C` for sort/find ordering OR python3 quirk on Ubuntu runner — needs Docker/Codespace repro)
2. Fix install.sh "wired but not shipped" bug for `tools/aegis-brain-graph/{hook.sh,staleness.mjs}` (settings.json wires them but installer doesn't deliver — exact bug class this test was created to catch)
3. Graduate `aegis-install-v11-delivery-test` once #2 is fixed (B2 story per plan)
4. **Stretch**: add tests for 2-3 high-leverage untested tools — likely `aegis-log-decision`, `aegis-progress`, `aegis-queue-{human,resolve}` (each has clear contract + low setup cost)

After B chunk-3 closes Phase B, move to **Phase C** (agent visibility · 3pt) → **Phase E** (refactor hot files · 5pt) → final v13-01 close.

## References

- Plan: [plan.md](plan.md)
- Predecessor closes: [close-phase-a.md](close-phase-a.md), [close-phase-d.md](close-phase-d.md), [close-phase-b-chunk1.md](close-phase-b-chunk1.md)
- Test files: [tests/aegis-instinct-promote-test.sh](../../../tests/aegis-instinct-promote-test.sh), [tests/aegis-trace-audit-test.sh](../../../tests/aegis-trace-audit-test.sh)
- Audit script (now archive-aware): [tools/aegis-trace-audit.sh](../../../tools/aegis-trace-audit.sh)
- Updated SI.02: [_aegis-output/iso-docs/SI-02-traceability-matrix/current.md](../../../_aegis-output/iso-docs/SI-02-traceability-matrix/current.md)
- Graduation list: [tests/_known-failures.txt](../../../tests/_known-failures.txt)
