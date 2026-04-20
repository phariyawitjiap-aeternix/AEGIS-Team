# Sprint v9-01 Kanban

> Updated: 2026-04-20 | Source of truth: this file (sprint-level summary)

## DONE (7 tasks, 13 pts)
- [x] S1-01 VERSION file (1pt) — Spider-Man
- [x] S1-02 install.sh + install-remote.sh read VERSION (1pt) — Spider-Man
- [x] S1-03 aegis-version-check.sh hook (3pt) — Spider-Man (tested, zero drift)
- [x] S1-04 settings.json hardening DESIGN (3pt) — Iron Man (in tools/v9-proposed-settings.json)
- [x] S1-05 Deny list expansion (1pt) — Black Panther (combined into S1-04)
- [x] S1-06 Permission migration guide (3pt) — Coulson
- [x] S1-07 Version drift consolidation (1pt) — Spider-Man

## IN PROGRESS (0)

## TODO (0)

## Sprint Velocity
13 pts / 1 session = 13 pts/session

## Notes
- S1-04 enforcement = framework self-protection working as designed
- guard-write.sh blocked the very edit it should block
- Manual apply needed via: cp tools/v9-proposed-settings.json .claude/settings.json
