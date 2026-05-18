# Sprint v15-14 Kanban

## DONE

- [x] **A** — Ship `.claude/hooks/lib/` (1pt) — 4 modules sourced by on-stop.sh
- [x] **B** — Glob-discover tool packages (2pt) — `for pkg_dir in tools/*/; do cp -R …`. Skips `_archived`. Also ships `tools/*.yaml` (threat-patterns config).
- [x] **C** — Doctor fail-loud (1pt) — captures doctor output, prints diagnostic + recovery hint, exits 1 on orphans
- [x] **D** — Regression test (1pt) — `tests/aegis-install-manifest-test.sh` × 4 (install / doctor PASS / 13 critical files / injected-orphan detection)

## Stories table

| Story | Type | Points | Status |
|-------|------|--------|--------|
| A — hooks/lib ship | bug-fix | 1 | DONE |
| B — tool packages glob | bug-fix | 2 | DONE |
| C — doctor fail-loud | enhancement | 1 | DONE |
| D — regression test | testing | 1 | DONE |

**Total**: 5/5 points done.

## Closes

- [Issue #182](https://github.com/phariyawitjiap-aeternix/AEGIS-Team/issues/182) — install-remote.sh ships incomplete manifest
