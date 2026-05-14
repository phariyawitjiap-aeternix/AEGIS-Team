# Sprint v15-10 Close — aegis-multi-tenant `--cwd` Integration

**Status**: CLOSED (100%)
**Date**: 2026-05-14
**Tests**: 57/57 (multi-tenant suite 22 → 30 with Group 6)
**Branch**: `claude/sprint-v15-10-multi-tenant-cwd`

## What shipped

- `tools/aegis-multi-tenant/mt.mjs`:
  - New subcommand `cwd <name>` — semantic alias for `where`, stricter
    (exits 2 on deleted-on-disk projects).
  - New subcommand `run <name> [--dry-run] [-- claude-args]` — wraps
    `claude --cwd <project> args`. ENOENT-on-spawn exits 127.
  - `parseFlags` now respects `--` as the forwarded-args separator, with
    everything after `--` captured in `out.__` for `cmdRun`.
  - Help text + module header document both subcommands and the CC
    2.1.141 integration pattern.
- `tests/aegis-multi-tenant-test.sh` Group 6 × 8 scenarios.

## Schema notes

CC 2.1.141 added `--cwd` for the top-level `claude` command (and any
subcommand it invokes). AEGIS does NOT hardcode which subcommand to
launch — args after `--` are forwarded verbatim. Examples:

```bash
# Interactive session in a registered project:
node tools/aegis-multi-tenant/mt.mjs run alpha

# Run `claude agents list` in alpha's tree:
node tools/aegis-multi-tenant/mt.mjs run alpha -- agents list

# Preview without executing:
node tools/aegis-multi-tenant/mt.mjs run alpha --dry-run -- agents list
# prints:  claude --cwd /Users/.../alpha agents list
```

## Design decisions

- **`cwd` is stricter than `where`**: `where` echoes the registered path
  even if it's been deleted; `cwd` refuses (exit 2). Reason: `cwd` is
  designed to feed `claude --cwd`, and a non-existent path would fail
  the spawn with a confusing error. Better to refuse early.
- **No CC version detection**: trusting `claude` to handle its own
  flag versions. Worst case: CC < 2.1.141 prints "unknown flag --cwd"
  and exits non-zero — propagated through.
- **`--` separator is conventional**: matches `git`, `npm`, `cargo`,
  `kubectl`. Args after `--` belong to the child process.

## Verification

```
$ bash tests/aegis-multi-tenant-test.sh
RESULTS: 30 passed, 0 failed
ALL PASSED

$ bash tests/run-all.sh --continue
ALL TESTS PASS — 57/57

$ node tools/aegis-multi-tenant/mt.mjs cwd AEGIS-Team
/Users/phariyawit.jiap/Documents/AEGIS-Team

$ node tools/aegis-multi-tenant/mt.mjs run AEGIS-Team --dry-run -- agents list
claude --cwd /Users/phariyawit.jiap/Documents/AEGIS-Team agents list
```

## Follow-ups

- Document `mt run` in the user-facing multi-tenant skill page (covered
  by general AEGIS docs sync; no separate task).
- If CC adds a structured discovery flag for capabilities (e.g.
  `claude --query-flags`), we could conditionally fall back when `--cwd`
  isn't supported. Deferred until that flag exists.

## Roadmap impact

v15 net deliverable: 25pt → 27pt.
