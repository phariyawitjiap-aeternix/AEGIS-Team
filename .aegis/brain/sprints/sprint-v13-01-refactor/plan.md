# Sprint v13-01 Plan: Codebase Re-organize + Re-factor (Quality Sweep)

**Status**: SCOPED, NOT YET OPEN — awaiting explicit "open v13-01" go.
**Points**: 24pt across 5 phases (Phase A–E, mostly independent)
**Authored**: 2026-05-07
**Trigger**: User asked for "analyze codebase ของ AEGIS-Team แล้ว ทำแผน re-organize & re-factor เพื่อหา bugs ปิดจุดอ่อน เสริมจุดแข็ง"

This is the **Rule 4 quality-debt sprint** for everything pre-v13. Per SPRINT_RULES Rule 4, "quality is a sprint topic, not a backlog item" — this plan formalizes that.

---

## Audit findings (2026-05-07, this session)

### File counts
| Surface | Count |
|---|---:|
| `tools/*.sh` (root) | 49 |
| `tools/*.mjs` (root + packages) | 36 |
| `skills/*.md` | 39 |
| `tests/*.sh` | 56 |
| `.claude/hooks/*.sh` | 14 |
| `.claude/agents/*.md` (active) | 11 |
| `.claude/commands/*.md` | 13 |

### 🔴 Hard findings (real bugs / dead code)

1. **5 truly-dead tools** (zero references in code, docs, settings, agents):
   - `tools/aegis-apply-mbp-guard.sh` — one-off MBP rollout helper, done
   - `tools/aegis-claude-md-lift.sh` — one-off CLAUDE.md migration helper, done
   - `tools/aegis-nick-fury-loop-harness.sh` — test harness, no callers
   - `tools/aegis-rtk-upstream-check.sh` — one-off readiness check, done
   - `tools/aegis-sdk-readiness-check.sh` — one-off SDK readiness, deferred per v9
2. **1 stale doc reference**: `tools/aegis-status-brief.sh` mentioned in `README.md` only — tool not called anywhere; superseded by `/aegis-status` skill.
3. **No CI/CD configured** — `.github/workflows/` doesn't exist. 56 tests + 0 automated runs. PRs merge without enforcing test pass.
4. **No pre-commit hook** — drift between code and tests can ship silently.

### 🟡 Coverage gaps

5. **~30 root tools (`tools/aegis-*.sh`) lack tests.** Visible-by-name list (sample): `aegis-agent-tools-matrix`, `aegis-brain-benchmark`, `aegis-brain-index`, `aegis-brain-sync`, `aegis-brain-write`, `aegis-distill-reset`, `aegis-fix-hook-paths`, `aegis-instinct-auto-reinforce`, `aegis-log-decision`, `aegis-maintainer-grant`, `aegis-merge-worktree`, `aegis-pending-items`, `aegis-policy-audit`, `aegis-privacy-scrubber`, `aegis-progress`, `aegis-queue-human`, `aegis-queue-resolve`, `aegis-team-chat`, `aegis-test-all`, `aegis-shell-lint`, `aegis-status-brief`. ~70% gap.
6. **8 tests with <10 assertions** (likely surface-only):
   - `aegis-block0-f-gate-test.sh` (2)
   - `aegis-guard-ui-edit-test.sh` (2)
   - `aegis-guard-write-test.sh` (2)
   - `aegis-trace-audit-test.sh` (6)
   - `aegis-version-consistency-test.sh` (6)
   - `aegis-wasp-generate-test.sh` (7)
   - `aegis-func-catalog-test.sh` (8)
   - `aegis-design-fetch-test.sh` (9)
7. **~15 AGENT-INVISIBLE tools** — tools exist but no agent prompt mentions them, so haiku Beast/Black Panther can't invoke them autonomously.

### 🟢 Strong patterns to keep + replicate

- **Top tests by assertion density** (templates worth copying):
  - `aegis-brain-graph-query-test.sh` (60)
  - `aegis-brain-graph-build-test.sh` (52)
  - `aegis-skill-frontmatter-test.sh` (49)
  - `aegis-approval-gate-test.sh` (49)
  - `aegis-multi-tenant-test.sh` (47)
- **Hook chain integrity**: 15 hook commands wired in settings.json — ALL exist on disk ✓
- **Governance lint**: 9 governance docs all version-headed + changelog-tracked ✓
- **Skill schema**: 39/39 skills satisfy frontmatter schema ✓

### 📚 Cosmetic / low-priority

8. **TODO/FIXME inventory** (39 markers across 6 files):
   - `skills/tech-debt-tracker.md` (10)
   - `skills/kanban-board.md` (10)
   - `tools/aegis-design-init.sh` (9)
   - `skills/sprint-tracker.md` (9)
   - `skills/super-spec.md` (1)
   - `skills/aegis-reengineer.md` (1)
9. **Hot files for refactor consideration** (largest LoC):
   - `skills/sprint-tracker.md` (564) — could split into smaller skill + reference doc
   - `tools/aegis-brain-graph/build.mjs` (495) — already modular but parsers could split
   - `tools/aegis-instinct-promote.sh` (469) — review for complexity
   - `skills/iso-29110-docs.md` (469) — long but content-heavy by design
10. **Stale historical doc**: `AEGIS_v9_UPGRADE_PLAN.md` (1042 lines) — kept per CLAUDE.md note as reference, but `AEGIS_v9_PROGRESS_TRACKER.md` (131) is superseded by `roadmap.md` and could archive.

---

## Stories (5 phases · 24pt total)

### Phase A — Dead code removal (3pt)

**Goal:** archive or delete confirmed-unused code. Smaller surface = less to maintain + audit.

| ID | Story | Pt |
|----|-------|----|
| A1 | Move 5 dead tools to `tools/_archived/` w/ ARCHIVE_NOTE.md explaining why each | 1 |
| A2 | Update `README.md` to remove `aegis-status-brief` reference; verify no docs link to archived tools | 1 |
| A3 | Strip TODO/FIXME prose from 6 skills (decide: implement OR remove the marker; not both) | 1 |

**Acceptance:**
- `find tools/aegis-* -type f` no longer lists the 5 archived tools
- `tools/_archived/ARCHIVE_NOTE.md` documents what + why per tool
- Zero TODO/FIXME markers in `tools/`, `skills/`, `.claude/hooks/` after this
- Existing tests still pass

### Phase B — Test coverage (8pt)

**Goal:** raise root-tool test coverage from ~30% to ~85%.

| ID | Story | Pt |
|----|-------|----|
| B1 | Choose 12 highest-leverage untested tools (decision-log, queue-human/resolve, progress, brain-write, instinct-promote, policy-audit, privacy-scrubber, merge-worktree, fix-hook-paths, brain-sync, brain-index, brain-benchmark) — write happy-path tests | 4 |
| B2 | Strengthen the 8 surface-only tests to ≥15 assertions each (use graph-query test as template) | 3 |
| B3 | Build `tests/run-all.sh` — single entry that runs every `tests/aegis-*-test.sh` and exits non-zero on any fail | 1 |

**Acceptance:**
- ≥85% of root `tools/aegis-*.sh` have a matching `tests/aegis-*-test.sh`
- All tests with <10 assertions either upgraded to ≥15 OR archived with rationale in close.md
- `bash tests/run-all.sh` works · prints summary · exits non-zero on any failure
- `tests/run-all.sh` is referenced in DoD §5 cross-reference

### Phase C — Agent visibility (3pt)

**Goal:** make every active tool reachable from at least one agent prompt or skill body — so Beast/Black Panther can find them autonomously.

| ID | Story | Pt |
|----|-------|----|
| C1 | For each AGENT-INVISIBLE tool, decide: archive (if obsolete) OR add a 1-line "available tools" section to the agent that owns it | 2 |
| C2 | Update `tools/aegis-doc-canon/skill-graph-manifest.json` so agent-invisible tools that survive get tracked in the graph | 1 |

**Acceptance:**
- Every surviving root tool is referenced from ≥1 of: `.claude/agents/*.md`, `skills/*.md`, `.claude/commands/*.md`, `.claude/settings.json`
- v12-04 graph re-build picks up the new edges (run `node tools/aegis-brain-graph/build.mjs --full` and `query mentions <tool>` returns ≥1 hit per tool)

### Phase D — CI/CD wiring (5pt)

**Goal:** automated test-run on every PR. No more "merge without enforcement."

| ID | Story | Pt |
|----|-------|----|
| D1 | `.github/workflows/test.yml` — runs `bash tests/run-all.sh` on push + PR; matrix on macOS + Linux | 2 |
| D2 | `.github/workflows/lint.yml` — runs `node tools/aegis-doc-canon/lint.mjs` + `node tools/aegis-doc-canon/skill-frontmatter.mjs --lint` + `bash tools/aegis-policy-audit.sh` (if usable) | 2 |
| D3 | Optional pre-commit (`.husky/` or `.pre-commit-config.yaml`) — runs governance lint locally on every commit | 1 |

**Acceptance:**
- PR can be merged only if test workflow passes
- Lint workflow catches missing version-header / missing schema-key on PR open
- DoD.md §5 references the CI workflow as the canonical "tests run from a top-level entrypoint" answer

### Phase E — Refactor hot files (5pt)

**Goal:** reduce complexity in the top-3 LoC files where it matters.

| ID | Story | Pt |
|----|-------|----|
| E1 | `skills/sprint-tracker.md` (564 → target <300) — split off "long-form examples" into `skills/sprint-tracker-examples.md` reference | 2 |
| E2 | `tools/aegis-instinct-promote.sh` (469) — review for cyclomatic complexity; if >15 in any function, split into module | 2 |
| E3 | Archive `AEGIS_v9_PROGRESS_TRACKER.md` to `_aegis-output/architecture/archive/` per its own "superseded by roadmap.md" note | 1 |

**Acceptance:**
- No single skill or tool exceeds 500 LoC after this phase (except `skills/iso-29110-docs.md` which is content-by-design — explicitly waived)
- `aegis-instinct-promote.sh` cyclomatic complexity ≤15 per function (use `bash -n` + manual inspection)
- `AEGIS_v9_PROGRESS_TRACKER.md` no longer at repo root

---

## Sequencing

Phases mostly independent — can ship in any order. Recommended:

```
1. Phase A (dead code)        ← lightest, highest signal-noise reduction
2. Phase D (CI)               ← unblocks future enforcement
3. Phase B (test coverage)    ← biggest win, but depends on D for value
4. Phase C (agent visibility) ← polish; depends on graph-rebuild from B
5. Phase E (refactor)         ← last; benefits from all earlier cleanup
```

Or open as one mega-sprint if user prefers single-shot.

## Acceptance for the whole sprint

- [ ] All 5 phases complete OR explicitly deferred with rationale
- [ ] DoD §5 + SPRINT_RULES Rule 3 unchanged but newly **enforceable** (CI blocks on red)
- [ ] No truly-dead tools in `tools/` (only `_archived/` may hold them)
- [ ] `bash tests/run-all.sh` runs ≥80 assertions across all suites in <30s
- [ ] Sprint close.md includes before/after metrics: file counts, test count, assertion count, CI runs

## Open questions for kickoff

1. Q: Sprint scoping — open all 5 phases as one v13-01 mega-sprint, OR split into v13-01..05 (one phase per sprint)? Recommend: split, ship Phase A first as 3pt warm-up.
2. Q: Test-runner choice for Phase B — pure bash matrix or migrate to `bats` for nicer output? Recommend: stay pure-bash for parity with existing tests.
3. Q: Pre-commit (D3) — opt-in or default? Recommend: opt-in via `.husky/install.sh` so cloning the repo doesn't auto-install hooks.
4. Q: Archived tools — keep in repo at `tools/_archived/` (audit trail, costs ~2KB) OR delete (clean, but loses provenance)? Recommend: keep, follows ADR-004 pattern.

## References

- This audit: 2026-05-07 session, direct Bash audit (Explore agent rejected prompts; pivoted to direct queries)
- [SPRINT_RULES.md](../../../SPRINT_RULES.md) Rule 4 — "quality-gate failure spawns a follow-up sprint" — this is exactly that
- [DoD.md](../../../DoD.md) §5 — Test coverage (≥1 assertion per AC) is the floor; Phase B + D raise the bar
- [GUARDRAILS.md](../../../GUARDRAILS.md) Sign "Policy without test" — Phase D structurally prevents this from re-emerging via CI
- [`.aegis/brain/sprints/roadmap.md`](../roadmap.md) — sprint-v13-01 row added as SCOPED

## Why SCOPED, not OPEN

Sprint open requires:
1. ✅ Audit data sufficiency — DONE (this plan's "Audit findings" section)
2. ⏳ User explicit "open v13-01" go — NOT YET
3. ⏳ Decision on Open Question 1 (mega vs split) — answer at kickoff

When ready: user types something like "open v13-01" / "ship phase A" / "start refactor sprint" → kickoff.
