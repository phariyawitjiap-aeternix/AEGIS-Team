# Sprint v13-01 Phase B Chunk 1 Close: First graduation + drift detector

**Status**: CLOSED · 2pt of 7pt remaining (28% of Phase B done)
**Date**: 2026-05-07
**Branch**: `sprint-v13-01-phase-b-chunk1`
**Phase B of 5** — see [plan.md](plan.md). A + D already CLOSED in PRs #139 + #140.

## Stories shipped

| ID | Story | Pt | Status |
|----|-------|----|--------|
| **B0** | Fix v12 drift in `.aegis/brain/resonance/project-identity.md` (caught by SessionStart hook on resume) | 0.5 | DONE |
| **B0+** | Extend `aegis-version-consistency-test.sh` to scan brain resonance dir for drift | 0.5 | DONE |
| **B-grad-1** | Graduate `aegis-block0-f-gate-test` from known-failures (the path bug, not "surface assertions") | 1 | DONE |

Total: **2pt** out of Phase B's 7pt remaining. 5pt left.

## What actually broke (and what the audit got wrong)

The plan §6 audit listed `aegis-block0-f-gate-test` as "2 assertions, surface-only." Looking at the test:

- It has **11 test cases** (TC-1 through TC-11), not 2 assertions.
- 9 passed; 2 failed (TC-2 + TC-7 — both "UI task with VALID DESIGN.md → expect PASS").
- Those 2 failed because the test sourced `aegis-design-lint.sh` from `$(dirname "$0")` which resolves to `tests/`. The lint script lives in `tools/`. Silent fall-through to FAIL on every "valid DESIGN.md" branch.
- **Root cause**: misuse of `$(dirname "$0")` as a project-root anchor. The repo convention is `_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)" && ...` then `${_SCRIPT_DIR}/../tools/<name>` for cross-dir refs.

Fix landed in test:

```diff
-    lint_out=$(bash "$(dirname "$0")/aegis-design-lint.sh" --strict --file "${DESIGN_MD_PATH}" 2>&1) || {
+    lint_out=$(bash "${_SCRIPT_DIR}/../tools/aegis-design-lint.sh" --strict --file "${DESIGN_MD_PATH}" 2>&1) || {
```

Result: **11/11 PASS**. Removed from `tests/_known-failures.txt` (kept the entry as graduation provenance per the file's policy).

## v12 drift in project-identity.md

The v12-06 SessionStart staleness hook (PR #123) caught two drifts on session resume:

1. Line 4: `AEGIS v11.0 — AI Agent Team Framework` (should be `v12.0` per PR #127)
2. Line 26: `AEGIS v6.0 — 8 AI Agent Personas` (frozen at v6 era; current is v10 personas after sprint-v9-06 consolidation)

Both fixed.

## Why the audit missed line 26

The `aegis-version-consistency-test.sh` previously checked these surfaces:

- CLAUDE.md / CLAUDE_lessons.md / CLAUDE_safety.md / CLAUDE_skills.md
- PROJECT_INDEX.md (now exempt as auto-gen)
- README.md
- install-remote.sh
- assets/logo/README.md

**`.aegis/brain/resonance/`** wasn't in the list. So drift could land there silently, and only the SessionStart staleness hook caught it on resume. That's a Rule-3 gap (deep-test coverage of source-of-truth-style files).

Extension landed in the test:

```bash
# Brain resonance files often mention the framework version too. Scan
# .aegis/brain/resonance/*.md for any "AEGIS v<N>." mention and confirm
# it matches MAJOR.
RESONANCE_DRIFT=()
if [[ -d "$REPO_ROOT/.aegis/brain/resonance" ]]; then
  while IFS= read -r f; do
    if grep -nE "AEGIS v[0-9]+\\.[0-9]+" "$f" 2>/dev/null \
       | grep -vE "AEGIS v${MAJOR}\\." > /dev/null 2>&1; then
      mismatch=$(grep -nE "AEGIS v[0-9]+\\.[0-9]+" "$f" 2>/dev/null \
                 | grep -vE "AEGIS v${MAJOR}\\." | head -1 || true)
      RESONANCE_DRIFT+=("${f#${REPO_ROOT}/}: $mismatch")
    fi
  done < <(find "$REPO_ROOT/.aegis/brain/resonance" -name '*.md' -type f 2>/dev/null)
fi
if [[ ${#RESONANCE_DRIFT[@]} -eq 0 ]]; then
  pass "brain resonance files all reference v${MAJOR} (or no version at all)"
else
  for d in "${RESONANCE_DRIFT[@]}"; do
    fail "resonance drift" "$d"
  done
fi
```

Verified by synthetic regression test (seed v11, expect FAIL → restore, expect PASS).

## Acceptance evidence

- [x] `.aegis/brain/resonance/project-identity.md` references `v12.0` consistently (lines 4 + 26)
- [x] `aegis-version-consistency-test`: **9/9 pass** (was 8/8 — gained brain resonance scan)
- [x] `aegis-block0-f-gate-test`: **11/11 pass** (was 9/11)
- [x] Full suite: `40 → 41 pass · 4 → 3 known-failure · 0 fail · exit 0 · 72s`
- [x] `tests/_known-failures.txt`: `aegis-block0-f-gate-test` removed (kept as graduation provenance comment per the file's policy)
- [x] No other tests regress
- [x] All 9 governance docs lint clean

## v13-01 sprint progress after Phase B chunk-1

```
v13-01 refactor:    10 / 24 pt  =  41.7%
  ✅ Phase A — dead code removal      3 / 3   PR #139
  ⏳ Phase B — test coverage           3 / 8   2pt this PR + 1pt B3 absorbed in D
  ⏳ Phase C — agent visibility        0 / 3
  ✅ Phase D — CI/CD                   5 / 5   PR #140
  ⏳ Phase E — refactor hot files     0 / 5

Phase B remaining: 5pt
  - 3 known-failures still flagged (aegis-install-v11-delivery, aegis-instinct-promote, aegis-trace-audit)
  - Tests for ~10 high-leverage untested tools (aegis-log-decision, aegis-progress, aegis-queue-{human,resolve}, aegis-policy-audit, aegis-merge-worktree, aegis-fix-hook-paths, aegis-brain-{sync,write,benchmark})
```

## Lessons for retro mining

1. **Audits at file-name-level lie.** "Surface-only test" judged by `grep -c pass\|fail` per file flagged `block0-f-gate-test` because its assertion count was small — but it had 11 cases via a different code path (`PASS=$((PASS+1))` not `pass "$1"`). The real bug was a sourcing path. **Lesson:** before strengthening a "surface" test, RUN it. The reason it's failing might not be "needs more assertions" — might be a real bug.

2. **Drift detectors should scan ALL source-of-truth surfaces.** Today's fix added brain resonance. Tomorrow's might add `.claude/agents/` (frozen v6 personas there?), `_aegis-output/iso-docs/`, etc. Add them as drift surfaces while running v12+ for a few weeks.

3. **SessionStart staleness hook + version-consistency-test are complementary, not redundant.** SessionStart catches at runtime (cheap, fail-OPEN); test catches in CI (gate, fail-CLOSED). Both stay.

## Next chunk per plan §"Sequencing"

**Phase B chunk 2** (next): graduate 1-2 more known-failures and add tests for 4-6 high-leverage untested tools. Probably split into 2-3 PRs of ~2pt each.

To open: `open phase b chunk 2` / `ship more tests` / `continue B`.

## References

- Plan: [plan.md](plan.md)
- Predecessor closes: [close-phase-a.md](close-phase-a.md), [close-phase-d.md](close-phase-d.md)
- Test file: [tests/aegis-block0-f-gate-test.sh](../../../tests/aegis-block0-f-gate-test.sh)
- Drift detector: [tests/aegis-version-consistency-test.sh](../../../tests/aegis-version-consistency-test.sh)
- Updated source: [.aegis/brain/resonance/project-identity.md](../../resonance/project-identity.md)
- Graduation list: [tests/_known-failures.txt](../../../tests/_known-failures.txt)
