# Sprint v15-10 Kanban

## DONE

- [x] **A** — `mt cwd <name>` semantic alias (0.5pt)
  - Output: absolute path only.
  - Stricter than `where`: exits 2 if path no longer exists on disk.
- [x] **B** — `mt run <name> [--dry-run] [-- claude-args]` launcher (1pt)
  - Args after `--` forwarded verbatim to `claude`.
  - `--dry-run` prints the command, doesn't execute.
  - Whitespace in forwarded args is shell-quoted in dry-run output.
  - ENOENT for missing `claude` → exit 127 + helpful stderr.
- [x] **C** — Test coverage + help (0.5pt)
  - Group 6 × 8 scenarios in `aegis-multi-tenant-test.sh` (cwd × 3,
    run --dry-run × 4, run spawn × 1).
  - Module header documents the new subcommands + CC 2.1.141 examples.
  - `help` text advertises both new subcommands + CC integration note.

## Stories table

| Story | Type | Points | Status | Hash |
|-------|------|--------|--------|------|
| A — cwd subcommand | enhancement | 0.5 | DONE | — |
| B — run launcher | enhancement | 1 | DONE | — |
| C — tests + help | testing | 0.5 | DONE | — |

**Total**: 2/2 points done.
