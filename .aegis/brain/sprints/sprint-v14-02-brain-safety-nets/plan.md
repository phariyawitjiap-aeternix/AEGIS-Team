<!-- version: 1.0.0 -->
<!-- Last updated: 2026-05-12 -->

# Sprint v14-02 Plan — Brain Safety Nets

**Goal**: Add reversibility to `.aegis/brain/` mutations + dedicated search over the decision-audit log.

**Capacity**: 13pt (2 stories)
**Status**: ACTIVE (opened 2026-05-12)
**Series**: [v14-series-plan.md](../v14-series-plan.md)

## Stories

| ID | Title | Points | Hermes source |
|----|-------|--------|---------------|
| S14-02-01 | Shadow-git checkpoints for brain | 8 | `tools/checkpoint_manager.py` |
| S14-02-02 | `aegis-decision-search` wrapper | 5 | `aegis-brain-search.sh --type decisions` already exists; ship dedicated UX |

## Acceptance criteria

### S14-02-01 — Shadow-git checkpoints
- [ ] `tools/aegis-brain-checkpoint/store.sh` — init real git repo at `.aegis/.brain-checkpoints/store/`
- [ ] `tools/aegis-brain-checkpoint/snapshot.sh` — rsync brain → store, commit if changed
- [ ] `tools/aegis-brain-checkpoint/rollback.sh` — `list | restore <N> | diff <N>`
- [ ] `.gitignore` adds `.aegis/.brain-checkpoints/`
- [ ] Test: snapshot creates commit; restore reverts; diff shows changes
- [ ] **Pre-decided caps** (Hermes verbatim per D-114): 20 checkpoints shown in `list`, no enforced max-size cap in v1 (git pack handles dedup naturally)
- [ ] No automatic hook wiring in this sprint — opt-in via manual call OR explicit later sprint after burn-in

### S14-02-02 — Decision search wrapper
- [ ] `tools/aegis-decision-search.sh` — pre-filters to `--type decisions`, adds reasoner/outcome filters
- [ ] `.claude/commands/aegis-decisions.md` slash command
- [ ] Test: search finds known decision; filters work

## Findings during audit

- `aegis-brain-search.sh` already supports `--type decisions` (v10-06 work shipped this) — S14-02-02 simplifies to a UX wrapper
- `aegis-brain-index.sh` already indexes `decision-audit.log` as `source_type=decisions`
- No reasoner-level filter exists today → add as wrapper-only enhancement
