# Sprint v15-26 Kanban

## DONE

- [x] **A** — Sweep block in `install.sh` (1pt)
  - ~50 LOC inserted before post-install doctor check
  - Walks 6 managed surfaces: tools/aegis-*.sh, skills/*.md, .claude/{agents,commands,references}/*.md, .claude/hooks/*.sh|*.mjs
  - Moves stale files to `${BACKUP_DIR}/swept/<rel-path>` (backup-preserved)
  - Silent if 0 stale files (no false-positive noise)
  - Skips on fresh install (no `--upgrade`)
- [x] **B** — `tests/aegis-install-upgrade-sweep-test.sh` × 13 (1pt)
  - T1+T1b: stale tool swept + preserved in backup
  - T2: stale skill swept
  - T3a-T3d: stale agent / command / reference / hook all swept
  - T4a+T4b: user brain + _aegis-output preserved
  - T5: tool package subdir not touched
  - T6: _archived/ subdir not touched
  - T7: fresh install → no backup dir created
  - T8: clean upgrade (no stale) → silent no-op
  - **13/13 green standalone**

- [x] **Real-world dogfood** — ran upgrade against Auto-Affi → swept 9 genuine stale items (1 fake-planted + 4 accumulated skills + 4 archived references). 8 of those had been accumulating silently across v15-18..25 lean passes.

## Stories table

| Story | Type | Points | Status |
|-------|------|--------|--------|
| A — sweep block | install.sh enhancement | 1 | DONE |
| B — tests × 13 | testing | 1 | DONE |

**Total**: 2/2 done.

## Closes

- Bug class: `install.sh --upgrade` is additive-only (now closed structurally)
- v15-19+ memory item: "should sweep source-removed skills" — 4 stale skills observed in Auto-Affi/DriveWiki/RizzLab
- v15-25 manual cleanup gap: 12 files I removed by hand → next time it's automatic

## Strategic outcome

Future lean passes (v15-25 style) now propagate cleanly to downstream. The
expensive memory item "additive-only --upgrade leads to accumulating stale
files" is fixed by code, not by belief. Closes [[policy-without-test]] for
this surface.

## Carry to v15-27+

- Sweep tool packages (`tools/aegis-foo/` subdirs) if accumulation becomes visible
- `--no-sweep` opt-out flag — only if users actually complain (right now sweep is conservative)
- `aegis-doctor.sh` could surface "would be swept on next upgrade" preview info
