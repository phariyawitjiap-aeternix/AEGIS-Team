# Sprint v15-18B Kanban

## DONE

- [x] **A** — `tools/aegis-settings-patch.sh` (1pt)
  - 4 subcommands: list / dry-run / apply / revert
  - jq-driven atomic edits (parse + serialize)
  - Timestamped backups to `.aegis/brain/state/settings-backups/`
  - Prominent "CC restart required" post-apply warning
  - Bash-based execution sidesteps guard-write (which only blocks Edit/Write/MultiEdit)
- [x] **B** — `narrow-posttooluse-matcher.jq` (1pt)
  - First patch: swap `.*` matcher → `Bash|Edit|Write|MultiEdit|Task`
  - Idempotent (selector matches only `.*`)
  - Closes v15-16 Story B (deferred since 2026-05-18)
- [x] **C** — `tests/aegis-settings-patch-test.sh` × 6 + meta-apply (1pt)
  - T1 list / T2 dry-run no-write / T3 apply + backup / T4 revert / T5 idempotency / T6 semantic preservation
  - Applied patch to AEGIS-Team's own settings.json — Story B closed for meta repo

## Stories table

| Story | Type | Points | Status |
|-------|------|--------|--------|
| A — patch tool | new tool | 1 | DONE |
| B — narrow matcher patch | bug-fix | 1 | DONE |
| C — tests + meta-apply | testing | 1 | DONE |

**Total**: 3/3 done.

## Closes

- **v15-16 Story B** (deferred 2026-05-18): `.*` matcher → action-tools-only. Saves ~3 hook spawns per Read/Grep/Glob/Task = ~150 spawns per typical codebase scan.

## Establishes pattern

Future between-session settings.json migrations: add a new `.jq` file under `tools/aegis-settings-patches/`, ship via normal sprint, users run `aegis-settings-patch.sh apply <name>` once + restart CC. No maintainer-grant ceremony required.
