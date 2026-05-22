# Sprint v15-23 Kanban

## DONE

- [x] **A** — `mt unregister <name>` (1pt)
  - Removes entry by name; reports path
  - Errors with exit 2 on unknown name
- [x] **B** — `mt prune` + tests × 6 (1pt)
  - Removes all rows where path missing
  - `--dry-run` preview without write
  - No-op detection on clean registry
  - 6/6 tests green standalone

## Stories table

| Story | Type | Points | Status |
|-------|------|--------|--------|
| A — mt unregister | tool extension | 1 | DONE |
| B — mt prune + tests | tool extension + tests | 1 | DONE |

**Total**: 2/2 done.

## Closes

- UX gap surfaced 2026-05-22 after `gen-google-form` stale entry needed manual YAML edit
