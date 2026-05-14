# Sprint v15-10 — aegis-multi-tenant `--cwd` Integration

> Wrap CC 2.1.141's `claude --cwd <path>` flag in the multi-tenant
> registry so switching between AEGIS projects is a single command —
> instead of `cd /path && claude` (which loses parent shell state) or a
> hand-rolled wrapper.

## Sprint metadata

- **ID**: sprint-v15-10-multi-tenant-cwd
- **Points**: 2
- **Status**: SELECTED
- **Branch**: `claude/sprint-v15-10-multi-tenant-cwd`
- **Driver**: CC 2.1.141 release notes flagged `--cwd` as the
  multi-project ergonomics improvement.

## Stories

| Story | Points | Description |
|-------|--------|-------------|
| A — `mt cwd <name>` semantic alias | 0.5 | Same output as `where` but documented for `--cwd` integration; exit 2 on deleted-on-disk projects (stricter than `where`, which would still echo the stale path). |
| B — `mt run <name> [-- args]` launcher | 1 | Wraps `claude --cwd <project> args`. `--dry-run` flag prints the command. Bare `--` separates args. ENOENT for missing `claude` exits 127 with clear stderr. |
| C — Regression coverage + help | 0.5 | 8 new scenarios in `aegis-multi-tenant-test.sh` Group 6; help text + module header updated. |

## Acceptance criteria

1. `mt cwd alpha` outputs only the absolute path.
2. `mt cwd <unknown>` → exit 2.
3. `mt cwd <deleted-on-disk>` → exit 2 (extra check vs `where`).
4. `mt run alpha --dry-run -- agents list` prints
   `claude --cwd <path> agents list` to stdout.
5. `mt run alpha --dry-run` (no `--` block) prints `claude --cwd <path>`.
6. `mt run <unknown>` → exit 2.
7. Forwarded args containing whitespace are shell-quoted in dry-run.
8. `mt run alpha -- xyz` without `--dry-run` spawns `claude` with the
   right args. Missing `claude` binary → exit 127.
9. Full test suite stays GREEN.
10. `mt help` advertises the new subcommands + CC 2.1.141 integration.

## Out of scope

- Auto-detecting `claude agents` vs `claude` subcommand structure — we
  pass args verbatim and let the user (or downstream tooling) specify
  the right invocation.
- Multi-project parallel launching (one `mt run` per project at a time;
  shell can `&` them if desired).
- Reading the registered project's CLAUDE.md before launch — separate
  concern.
- CC version detection — `--cwd` exists on CC 2.1.141+; if user is on an
  older CC, `claude` will reject the flag and the user sees a clean
  error from claude itself.

## Risks

- **R1**: CC < 2.1.141 may not recognize `--cwd`. Mitigation: error
  propagates from the child claude process; non-zero exit + helpful
  stderr.
- **R2**: User invokes `mt run alpha` without `--` and the args get
  consumed as `mt` flags. Mitigation: documented in help; `mt run` only
  accepts `--dry-run` as a known flag before `--`; everything else after
  `--` is forwarded.

## Verification plan

1. `bash tests/aegis-multi-tenant-test.sh` → 30/30 (was 22, +8 Group 6).
2. `bash tests/run-all.sh --continue` → 57/57 stays GREEN.
3. Manual: `node tools/aegis-multi-tenant/mt.mjs cwd AEGIS-Team` →
   prints `/Users/.../AEGIS-Team`.
4. Manual: `node tools/aegis-multi-tenant/mt.mjs run AEGIS-Team --dry-run -- agents list`
   → prints `claude --cwd /Users/.../AEGIS-Team agents list`.
