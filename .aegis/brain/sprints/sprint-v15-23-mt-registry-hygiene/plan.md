# Sprint v15-23 — Multi-Tenant Registry Hygiene

> Tiny sprint to fix a UX gap surfaced 2026-05-22 while cleaning up
> the Contra-Thai aftermath: `mt.mjs` has `register` but no `unregister`,
> and no way to bulk-remove stale entries whose `path` no longer exists
> on disk. Until now the only fix was hand-editing `~/.aegis-plus/projects.yaml`.

## Sprint metadata

- **ID**: sprint-v15-23-mt-registry-hygiene
- **Points**: 2
- **Status**: SELECTED
- **Branch**: `claude/sprint-v15-23-mt-registry-hygiene`

## Stories

| Story | Pts | Description |
|---|---|---|
| **A — `mt unregister <name>`** | 1 | Remove a project from the registry by name. Errors with exit 2 if name not found. |
| **B — `mt prune` + tests** | 1 | Auto-remove all entries whose `path` no longer exists on disk. `--dry-run` previews. Reports row-by-row what was removed. `tests/aegis-mt-hygiene-test.sh` × 6: T1 unregister works, T2 unknown name errors, T3 dry-run no-write, T4 prune removes stale, T5 no-op on clean, T6 empty registry graceful. |

## Acceptance criteria

- [ ] `mt help` lists `unregister` + `prune`
- [ ] `mt unregister <name>` removes the entry; reports `unregistered: <name> → <path>`
- [ ] `mt unregister <unknown>` exits 2 with `no such project` message
- [ ] `mt prune --dry-run` reports stale rows; does NOT modify registry
- [ ] `mt prune` removes stale rows; reports before → after count
- [ ] `mt prune` on a clean registry says `(no stale entries — registry clean)`
- [ ] 6/6 tests green standalone
- [ ] Full suite green
- [ ] No new dependencies

## What this does NOT do (deferred)

- **Confirmation prompt** before destructive removal — explicit subcommand + name is already two-step; adding a prompt would break scripting
- **Backup before destructive op** — registry is a 4-line YAML; user can `git diff` or revert manually; auto-backup feels over-engineered
- **`mt rename <old> <new>`** — separate sprint candidate; not asked for

## Closes

- UX gap surfaced 2026-05-22 — "registry has no removal path other than hand-editing YAML"
- Cleanup workflow for stale multi-tenant entries (was just demonstrated against `gen-google-form` which had `exists=no` for weeks)

## Recursive validation

After this sprint lands, the user can rerun `mt prune` periodically to keep
the registry clean without remembering YAML structure.
