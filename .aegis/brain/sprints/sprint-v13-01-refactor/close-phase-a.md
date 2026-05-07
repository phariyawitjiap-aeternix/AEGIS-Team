# Sprint v13-01 Phase A Close: Dead Code Removal

**Status**: CLOSED · 3/3pt · 100% · single-session delivery
**Date**: 2026-05-07
**Branch**: `sprint-v13-01-phase-a`
**Phase A of 5 in the v13-01 refactor sprint** — see [plan.md](plan.md) for full sprint context.

## Stories shipped

| ID | Story | Pt | Status |
|----|-------|----|--------|
| A1 | Move 5 dead tools to `tools/_archived/` w/ `ARCHIVE_NOTE.md` | 1 | DONE |
| A2 | Update README.md / install-remote.sh / func-catalog.json — remove stale refs | 1 | DONE |
| A3 | Strip TODO/FIXME prose from 6 skills | 1 | **DONE (no-op confirmed)** |

## A1 — Archive 5 dead tools ✓

`git mv` preserved history (`git log --follow tools/_archived/<name>.sh` works for all 5):

- `tools/_archived/aegis-apply-mbp-guard.sh` — one-off MBP rollout helper, completed
- `tools/_archived/aegis-claude-md-lift.sh` — v8→v9 CLAUDE.md migration helper, completed
- `tools/_archived/aegis-nick-fury-loop-harness.sh` — superseded by ADR-008 persona-overlay model
- `tools/_archived/aegis-rtk-upstream-check.sh` — RTK adoption DEFERRED in sprint-v10-03
- `tools/_archived/aegis-sdk-readiness-check.sh` — v9-07..15 SDK items DEFERRED indefinitely
- Plus: `tools/_archived/ARCHIVE_NOTE.md` documenting why each was archived + revival recipe

Bonus archive (transitively orphaned by A1):

- `scripts/_archived/aegis-migrate-v9.sh` — depended on archived `aegis-claude-md-lift.sh`; v8→v9 migration completed, no live consumer
- `scripts/_archived/ARCHIVE_NOTE.md`

## A2 — Living-code refs cleaned ✓

| File | Edit |
|---|---|
| `README.md` line 106 | `aegis-status-brief.sh` → `/aegis-status` skill (its successor); noted as archived in v13-01 Phase A |
| `install-remote.sh` line 312 | Removed `aegis-status-brief` from the "helper tools installed" success message |
| `install-remote.sh` line 558 | Removed `aegis-status-brief` from the "New ops tools" upgrade summary |
| `.aegis/brain/func-catalog.json` | Regenerated via `bash tools/aegis-func-catalog.sh` — went from listing 4 archived tools to 0 |

Verification: `grep -rln <archived-tool-name>` across living code (excluding `_archived/`, `.git/`, sprint history docs, human-queue.md, roadmap.md) returns ZERO matches for any of the 5 archived tools.

Sprint history docs (`.aegis/brain/sprints/sprint-v10-{02,03}/{plan,close}.md`, `roadmap.md`, `human-queue.md`, `sprint-v13-01-refactor/plan.md`) intentionally retain references — those are immutable historical records, not living code.

## A3 — TODO/FIXME audit was naïve · zero actual debt

The plan.md audit reported "39 TODO/FIXME markers across 6 files." Rule 3 deep-test discipline applied: looked at the actual content of each marker. **All 39 are false positives** — `grep TODO` matched legitimate non-debt usage:

| File | Markers | What they actually are |
|---|---:|---|
| `skills/tech-debt-tracker.md` | 10 | Meta-references in the skill that **scans for** TODO/FIXME (it's the tech-debt scanner — its description naturally references TODO/FIXME) |
| `skills/kanban-board.md` | 10 | `TODO` is a **kanban column name** in `BACKLOG → TODO → IN_PROGRESS → IN_REVIEW → QA → DONE` — not a debt marker |
| `skills/sprint-tracker.md` | 9 | Same kanban column-state usage in sprint task tables |
| `tools/aegis-design-init.sh` | 9 | TODOs are inside a HEREDOC **template** that gets installed into user projects as starter `DESIGN.md` placeholders for the user to fill in (intentional) |
| `skills/super-spec.md` | 1 | One self-referential check: "no TODOs or placeholders in spec body" — meta-check, not debt |
| `skills/aegis-reengineer.md` | 1 | Description: "TODO/FIXME count and locations" — describing what the re-engineer skill scans for |

**Actual debt count: 0.** A3 lands as a no-op confirming the audit was surface-only. The plan.md audit is **not retrofit-corrected** — keeping the original number preserves the "we audited, then deeply checked, then found false positives" trail. Phase B (which adds real assertions) will use stricter scanning.

This is itself a **demonstration of SPRINT_RULES Rule 3**: "DoD §5 floor (≥1 assertion per AC) is NOT the bar." Surface counts (`grep -c`) deceive; deep test = look at each match in context.

## Acceptance evidence

- [x] `find tools/aegis-* -type f` no longer lists the 5 archived tools (verified: only `tools/_archived/aegis-*.sh` listed)
- [x] `tools/_archived/ARCHIVE_NOTE.md` exists with what + why per tool + revival recipe
- [x] No TODO/FIXME debt markers (audit corrected — 0 actual debt, 39 false positives)
- [x] Existing tests still pass:
  - 9 governance docs lint clean
  - 39 skills satisfy schema
  - aegis-mbp-scan-thai-test.sh — 24 pass / 0 fail
  - aegis-doc-canon-lint-test.sh — 18 pass / 0 fail
- [x] `func-catalog.json` regenerated cleanly (289 entries, 0 archived refs)
- [x] `git log --follow tools/_archived/<name>.sh` works for each archived tool (history preserved)

## Net file changes

```
git mv        tools/aegis-apply-mbp-guard.sh        tools/_archived/
git mv        tools/aegis-claude-md-lift.sh         tools/_archived/
git mv        tools/aegis-nick-fury-loop-harness.sh tools/_archived/
git mv        tools/aegis-rtk-upstream-check.sh     tools/_archived/
git mv        tools/aegis-sdk-readiness-check.sh    tools/_archived/
git mv        scripts/aegis-migrate-v9.sh           scripts/_archived/
new           tools/_archived/ARCHIVE_NOTE.md
new           scripts/_archived/ARCHIVE_NOTE.md
modified      README.md                              (1 line)
modified      install-remote.sh                      (2 lines)
modified      .aegis/brain/func-catalog.json         (regenerated)
```

## v13-01 sprint progress after Phase A

```
v13-01 refactor:    3 / 24 pt  =  12.5%
  ✅ Phase A — dead code removal      3 / 3
  ⏳ Phase B — test coverage           0 / 8
  ⏳ Phase C — agent visibility        0 / 3
  ⏳ Phase D — CI/CD                   0 / 5
  ⏳ Phase E — refactor hot files     0 / 5
```

Phase A was the lightest phase by design (warm-up). Phase D (CI) is recommended next per plan §"Sequencing" — unblocks Phase B's value (tests aren't valuable if they never run).

## Lessons (worth retaining for retro mining)

1. **Surface grep audits lie.** The "39 TODOs" finding was wrong because `grep TODO` matched kanban column names + skill meta-descriptions + intentional template placeholders. Future audits should grep for the EXACT comment-marker pattern (e.g. `^\s*(#|//)\s*(TODO|FIXME)`) and review each match in context. Same lesson applied to MBP scan in PR #135 — patterns matter, not surface counts.

2. **Transitive archives surface naturally.** `aegis-migrate-v9.sh` would have stayed broken in `scripts/` if I hadn't grep'd for refs to the archived tools post-archive. Always re-scan after every archive batch.

3. **`git mv` over `rm` + `git add`.** Preserves `git log --follow` history. No information loss. Matches the ADR-004 "audit trail preserved" pattern.

## Next phase

**Phase D (CI/CD)** recommended next per plan §"Sequencing." Phase B (test coverage) depends on D for value.

To open: user types `open phase d` / `ship CI` / `start phase D`.

## References

- Plan: [plan.md](plan.md)
- Phase A branch: `sprint-v13-01-phase-a`
- ARCHIVE_NOTE: [tools/_archived/ARCHIVE_NOTE.md](../../../tools/_archived/ARCHIVE_NOTE.md)
- SPRINT_RULES Rule 3 (deep test) — demonstrated in A3 audit correction
