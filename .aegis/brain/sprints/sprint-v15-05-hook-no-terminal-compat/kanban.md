# Sprint Kanban — sprint-v15-05-hook-no-terminal-compat

**Goal**: Verify hooks compat with CC 2.1.139 "no terminal access"
**Capacity**: 3pt
**Status**: CLOSED 2026-05-13 (verified clean)

## DONE

- [x] [HT-1] Audit all .claude/hooks/ for terminal-access patterns (@iron-man) — 1pt
      Scanned for: read from tty, stty, /dev/tty, interactive prompts.
      Result: ZERO matches. All hooks use stdout (echo/printf) or stderr (>&2).
- [x] [HT-2] Audit lib/ helper modules same way (@iron-man) — 1pt
      Scanned: false-ready.sh, mbp-scan.sh, quality-check.sh, queue-banner.sh.
      Result: ZERO matches. All output goes through CC's captured stdout/stderr.
- [x] [HT-3] Document why no-op + when to revisit (@coulson) — 1pt
      close.md: hooks were never tty-grabbing. CC's change is invisible to AEGIS.
