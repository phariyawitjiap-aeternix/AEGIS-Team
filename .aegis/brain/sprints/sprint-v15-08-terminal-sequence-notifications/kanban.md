# Sprint v15-08 Kanban

## DONE

- [x] **A** — Schema spike + `tools/aegis-notify.sh` helper (1pt)
  - OSC-9 escape sequence (iTerm2/Terminal.app/Windows Terminal native)
  - BEL (0x07) fallback to stderr
  - Strictly additive JSON: `{"terminalSequence": "..."}` only
  - Opt-in via `AEGIS_HOOK_NOTIFY=1`
  - Reentrant guard prevents double-source side effects
  - Suppress BEL via `AEGIS_NOTIFY_BEL=0`
  - Standalone smoke: `bash tools/aegis-notify.sh test`
- [x] **B** — Wire `.claude/hooks/on-stop.sh` (1pt)
  - Sources helper at end-of-hook, after all banners
  - Notifies "AEGIS session ended"
- [x] **B** — Wire `.claude/hooks/session-start.sh` (0pt, bundled with above)
  - Notifies "Sprint plan gate" only when no sprint dir exists
- [x] **B** — Wire `.claude/hooks/linear-sync-on-kanban.sh` (0pt, bundled)
  - Notifies "Linear sync started: <sprint-id>" before async fire
- [x] **C** — `tests/aegis-notify-test.sh` × 8 scenarios (1pt)
  - T1 source + symbol export
  - T2 BEL fires to stderr default
  - T3 JSON emits to stdout with opt-in
  - T4 JSON omits `continue` (Stop-hook safety)
  - T5 notify log written
  - T6 reentrant guard
  - T7 standalone smoke path
  - T8 `AEGIS_NOTIFY_BEL=0` suppresses BEL
  - 8/8 PASS

## Stories table

| Story | Type | Points | Status | Hash |
|-------|------|--------|--------|------|
| A — schema spike + helper | enhancement | 1 | DONE | — |
| B — wire 3 hooks | enhancement | 1 | DONE | — |
| C — regression net | testing | 1 | DONE | — |

**Total**: 3/3 points done.
