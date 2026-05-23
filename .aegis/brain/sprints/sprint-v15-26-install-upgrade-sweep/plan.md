# Sprint v15-26 — Install Upgrade-Sweep (Kill Stale-File Accumulation)

> Bug class surfaced in v15-25 dogfood: `install.sh --upgrade` is purely
> additive — it copies new framework files but never removes files that
> source has deleted. After v15-25's lean pass, 8 downstream projects
> still had `aegis-worktree-gc.sh` + `aegis-merge-worktree.sh` sitting in
> their `tools/` directory. Manual cleanup got us through, but the same
> bug will recur on every future deletion.
>
> Driver: also closes the memory item from v15-19 series ("install --upgrade
> should sweep source-removed skills — observed 4 stale skills in
> Auto-Affi/DriveWiki/RizzLab").

## Sprint metadata

- **ID**: sprint-v15-26-install-upgrade-sweep
- **Points**: 2
- **Status**: SELECTED
- **Branch**: `claude/sprint-v15-26-install-upgrade-sweep`

## Design

Add an upgrade-sweep step to `install.sh` that runs AFTER all copy steps complete (so newly-introduced files are present in target before we diff).

### What gets swept

Only the surfaces AEGIS explicitly manages:

| Pattern | Why these |
|---|---|
| `tools/aegis-*.sh` (top-level) | Helper scripts shipped via `runtime_helpers` |
| `skills/*.md` | Skill definitions shipped via frontmatter-glob discovery |
| `.claude/agents/*.md` | Persona prompts |
| `.claude/commands/*.md` | Slash commands |
| `.claude/references/*.md` (top-level) | Protocol docs |
| `.claude/hooks/*.sh` + `*.mjs` (top-level) | Hook scripts |

### What is NEVER swept

- User content: `.aegis/brain/` (resonance, learnings, retros, sprints, instincts, state, logs)
- Pipeline outputs: `_aegis-output/`
- Tool subdirectories: `tools/aegis-*/` (these are tool packages, deletion-by-glob is wrong)
- Library subdirs: `.claude/hooks/lib/` (only top-level hook files)
- Intentional archives: `tools/_archived/`, `.claude/references/_archived/`

### Safety design

- Swept files MOVE to `${BACKUP_DIR}/swept/<original-path>/` (not deleted)
- Backup dir is already created by upgrade-init step
- Only fires when `--upgrade` flag set; fresh install path skips sweep entirely
- If 0 stale files found, sweep is silent (no false-positive noise)

## Stories

| Story | Pts | Description |
|---|---|---|
| **A — Sweep block in `install.sh`** | 1 | ~50 LOC inserted right before the post-install doctor check. Walks the 6 managed surfaces, moves any file in target without source equivalent to `${BACKUP_DIR}/swept/<rel-path>`. Reports count via `success()`. |
| **B — `tests/aegis-install-upgrade-sweep-test.sh` × 13** | 1 | Build fixture target with stale files + user files + tool subdirs + `_archived/`; run upgrade; verify (T1-T6) stale removed + (T4) user untouched + (T5-T6) subdirs untouched + (T7) fresh install no backup + (T8) clean upgrade silent. |

**Total: 2 pt**

## Acceptance criteria

- [ ] Stale framework files (tools/.sh, skills/.md, hooks/, agents/, commands/, references/) removed during `--upgrade`
- [ ] Removed files preserved in `_aegis-backup-<ts>/swept/<path>` (rollback path)
- [ ] User brain content untouched
- [ ] `_aegis-output/` untouched
- [ ] Tool package subdirs (`tools/aegis-foo/`) untouched (only top-level `*.sh`)
- [ ] `_archived/` subdirs untouched (intentional archives)
- [ ] Fresh install (no `--upgrade`) does NOT create backup dir or sweep
- [ ] Clean upgrade (no stale files) is silent — no false positives
- [ ] 13/13 tests green standalone
- [ ] Full suite green
- [ ] Real-world dogfood: run on Auto-Affi → sweep catches 8 genuine stale items (4 skills + 4 references that accumulated across v15-18..25)

## Real-world dogfood result (preview)

When v15-26 ran against Auto-Affi:

```
swept: tools/aegis-fake-stale-from-v15-26.sh   # (test file I planted)
swept: skills/aegis-doctor.md                   # accumulated stale skill
swept: skills/aegis-observe.md                  # accumulated stale skill
swept: skills/aegis-plus-pilot.md               # accumulated stale skill
swept: skills/sprint-manager.md                 # accumulated stale skill
swept: .claude/references/mcp-server-architecture.md    # archived in v15-24
swept: .claude/references/migration-ga-strategy.md      # archived in v15-24
swept: .claude/references/plugin-architecture.md        # archived in v15-24
swept: .claude/references/schedule-toolsearch-consolidation.md  # archived in v15-24
[OK] Swept 9 stale framework file(s) → _aegis-backup-20260523-155400/swept
```

8 of those 9 had been silently accumulating across multiple lean passes. v15-26 cleans them in one shot + prevents future accumulation.

## Closes

- Bug class: `install.sh --upgrade` is additive-only
- v15-19+ memory item: "should sweep source-removed skills (4 stale observed)"
- v15-25 manual-cleanup gap: 12 files removed by hand → automated going forward

## What this does NOT do (deferred)

- Sweep tool packages (`tools/aegis-foo/` subdirs) — needs separate logic since packages are dir-level not file-level; v15-27+ if accumulation becomes visible
- Sweep `.claude/references/_archived/` if file removed from `_archived/` — out of scope (archive is the destination, not a sweep target)
- Configurable opt-out (`--no-sweep`) — current sweep is conservative enough not to need an opt-out

## Strategic outcome

AEGIS lean passes are now permanently sustainable. Future deletion sprints
(v15-25 style) will automatically propagate to downstream without manual
cleanup. The "additive-only --upgrade" bug class is closed structurally.
