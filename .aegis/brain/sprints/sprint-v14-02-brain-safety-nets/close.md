<!-- version: 1.0.0 -->
<!-- Last updated: 2026-05-12 -->

# Sprint v14-02 Close — Brain Safety Nets

**Status**: CLOSED 2026-05-12 (100%)
**Outcome**: 13/13 points delivered
**Test results**: **21/21 GREEN** (S14-02-01 11/11 + S14-02-02 10/10)
**Series**: [v14-series-plan.md](../v14-series-plan.md)

## What shipped

### S14-02-01 — Shadow-git brain checkpoints (8pt) ✅
- [tools/aegis-brain-checkpoint/store.sh](../../../../tools/aegis-brain-checkpoint/store.sh) — `init` + `info` + shared lib (lock + manifest helpers)
- [tools/aegis-brain-checkpoint/snapshot.sh](../../../../tools/aegis-brain-checkpoint/snapshot.sh) — rsync + git commit; idempotent on no-change
- [tools/aegis-brain-checkpoint/rollback.sh](../../../../tools/aegis-brain-checkpoint/rollback.sh) — `list` (top 20) / `diff <N>` / `restore <N>` / `restore <N> <file>`
- [tests/aegis-brain-checkpoint-test.sh](../../../../tests/aegis-brain-checkpoint-test.sh) — **11/11 passing** (init, no-op, change, list, diff, single-file restore, full restore, pre-rollback snapshot, info)
- Storage at `.aegis/.brain-checkpoints/store/` (real git repo, content-addressable, naturally deduplicated)
- Defaults adopted from Hermes (per D-114 pre-decision): top-20 in `list`, no enforced size cap in v1, `gc.reflogExpire 30d`
- **Hook wiring deferred** — opt-in via manual call OR explicit later sprint after burn-in (avoids surprising hot-loop on existing brain mutations)

### S14-02-02 — Decision-audit search wrapper (5pt) ✅
- [tools/aegis-decision-search.sh](../../../../tools/aegis-decision-search.sh) — wraps `aegis-brain-search.sh --type decisions` + post-filters by `--source`
- [.claude/commands/aegis-decisions.md](../../../../.claude/commands/aegis-decisions.md) — slash command spec
- [tests/aegis-decision-search-test.sh](../../../../tests/aegis-decision-search-test.sh) — **10/10 passing**
- Added `aegis-decisions` to [registry.mjs](../../../../tools/aegis-commands/registry.mjs) (15 commands now — was 14)
- Registry test updated to expect 15 — verified GREEN

## Carry-forward bonus

- Rebuilt brain index incrementally (152 files indexed) — D-001..D-005 now searchable via `aegis-brain-search.sh --type decisions "v14"`
- Discovered: v10-06 brain-search already had `--type decisions`; the v14-02 wrapper is a UX layer over existing infrastructure (5pt → mostly UX + testing + registry sync, not from-scratch search)

## Decisions logged

| ID | Topic | Source | Reasoner |
|----|-------|--------|----------|
| D-004 | sprint-v14-02 open | framework | Nick Fury |
| D-005 (this) | sprint-v14-02 close | framework | Nick Fury (logged on close) |

## What worked

1. **Git-as-CAS for checkpoints** — git's native content-addressable storage means duplicate files across snapshots cost zero. Restored Hermes pattern wholesale; works first try.

2. **Pre-rollback snapshot before restore** — every `restore <N>` first snapshots current state. Makes rollback itself undoable (Hermes pattern). Tested via TC10.

3. **rsync `--delete --exclude='.brain-checkpoints'`** — single command syncs brain → store working tree without recursive copy of the checkpoint store inside itself. Prevents storage explosion.

4. **Registry expansion pattern proved** — adding `aegis-decisions` to registry.mjs was 11 lines. Test failure (TC8) caught the missing registration immediately. The CommandDef SSOT pattern paid off the same sprint it shipped.

## What surprised

1. **`aegis-brain-search.sh` already had `--type decisions`** — discovered during sprint planning. Cut S14-02-02 effort by ~3pt vs original estimate (was sized for from-scratch search; ended up as UX wrapper). Honest accounting: 5pt budget delivered 5pt of UX work (wrapper + slash command + tests + registry expansion + index rebuild).

2. **Brain index was stale** — `decision-audit.log` mentioned in `aegis-brain-index.sh` config but the index file didn't exist locally. Running `--incremental` rebuilt cleanly (152 files, 30s). Suggests we should consider running incremental on `SessionStart` hook (carry-forward).

3. **Test TC8 caught registry desync** — exactly the failure mode the CommandDef pattern was designed to prevent. Without TC8, aegis-decisions could have shipped with the .md present but no registry entry. **Self-validating registry pays off.**

## DoD bars

| Bar | Status | Evidence |
|-----|--------|----------|
| §1 Functional | ✅ | snapshot/restore work; search wraps cleanly |
| §2 Tests | ✅ | 21/21 |
| §3 Safety | ✅ | Checkpoint adds undo safety net; search read-only |
| §4 Documentation | ⚠️ | Slash command .md written; ARCHITECTURE.md update queued |
| §5 CI green | ✅ | Tests pass; supply-chain CI from v14-01 covers new .mjs/.sh (no findings) |
| §6 Decision audit | ✅ | D-004 + D-005 logged |
| §7 Roadmap | ✅ | roadmap.md updated |
| §8 Retro | ✅ | This close.md |
| §9 Brain update | ⚠️ | Lessons → next /aegis-retro |

## Files delta

```
NEW (4 files):
  tools/aegis-brain-checkpoint/store.sh          ( 3,815 bytes, +x)
  tools/aegis-brain-checkpoint/snapshot.sh       ( 2,560 bytes, +x)
  tools/aegis-brain-checkpoint/rollback.sh       ( 4,829 bytes, +x)
  tools/aegis-decision-search.sh                 ( 5,742 bytes, +x)
  .claude/commands/aegis-decisions.md            ( 2,400 bytes)
  tests/aegis-brain-checkpoint-test.sh           ( 5,107 bytes, +x)
  tests/aegis-decision-search-test.sh            ( 4,331 bytes, +x)

EDIT (2 files):
  tools/aegis-commands/registry.mjs              (+1 CommandDef → 15 entries)
  tests/aegis-commands-registry-test.sh          (14 → 15 expected count)
```

## Roadmap math impact

```
v14 series:  47 selected / 26 done = 55% (2/4 sprints CLOSED)
            v14-01 (13) + v14-02 (13) = 26 / 47 — on track
```

Next: **sprint-v14-03-operations-hardening** (11pt — aegis-dump + first-run defer retrofit + pin 2-axis).
