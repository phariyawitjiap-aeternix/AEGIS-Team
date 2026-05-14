# Sprint v15-08 — terminalSequence Notifications

> Adopt Claude Code 2.1.141's hook `terminalSequence` JSON output to surface
> AEGIS lifecycle events (session end, sprint-plan gate, Linear sync) as
> desktop attention pings without disturbing existing hook semantics.

## Sprint metadata

- **ID**: sprint-v15-08-terminal-sequence-notifications
- **Points**: 3 (1pt spike + 2pt wiring)
- **Status**: SELECTED
- **Branch**: `claude/sprint-v15-08-terminal-sequence`
- **Driver**: CC 2.1.141 release notes (2026-05-13) flagged terminalSequence
  as the highest user-facing payoff with lowest schema risk.

## Stories

| Story | Points | Description |
|-------|--------|-------------|
| A — Schema spike + helper library | 1 | `tools/aegis-notify.sh`: BEL fallback + opt-in JSON; reentrant guard; standalone smoke path. |
| B — Wire 3 hooks | 1 | `on-stop.sh` (session end), `session-start.sh` (sprint-plan gate), `linear-sync-on-kanban.sh` (sync start). |
| C — Regression net | 1 | `tests/aegis-notify-test.sh` × 8 scenarios — schema, BEL, log, reentrant guard, suppression. |

## Acceptance criteria

1. Helper sources cleanly in bash 3.2+ (macOS default shell).
2. BEL fires to stderr by default — works on EVERY POSIX terminal.
3. JSON `{"terminalSequence": "<ansi>"}` emits to stdout only when
   `AEGIS_HOOK_NOTIFY=1` (opt-in).
4. JSON shape is **strictly additive**: no `continue`, no `decision`. Safe
   to emit from any hook event including Stop (where `continue: true` would
   collide with the block/allow decision semantics).
5. All 3 hooks degrade silently if the helper is missing (downstream
   projects that haven't synced yet).
6. Full test suite passes: 58/58.

## Decisions

- **OSC-9 over OSC-777**: OSC-9 is supported natively by iTerm2, macOS
  Terminal.app, Windows Terminal. OSC-777 (xterm extension) needs a tmux
  passthrough config. Picked the simpler standard.
- **Strictly additive JSON**: Omit `continue` field. CC ignores unknown
  fields, so emitting just `{"terminalSequence": "..."}` is safe across
  hook events. Schema-spike conclusion: don't speculate on `continue`
  semantics for Stop hooks.
- **Opt-in default**: `AEGIS_HOOK_NOTIFY=0` until users explicitly enable.
  BEL always fires (universal, harmless).

## Out of scope

- Wiring into PreToolUse hooks (would add per-tool noise; not the right
  signal for desktop attention).
- Linear-sync-complete notification (sync is async; would require a second
  hook after subshell exit — not worth the complexity for v15-08).
- Per-event customization (e.g., different ANSI for warn vs info) — future
  work if users request it.

## Verification plan

1. `bash tools/aegis-notify.sh test` — standalone smoke.
2. `bash tests/aegis-notify-test.sh` — 8/8 scenarios.
3. `bash tests/run-all.sh --continue` — full suite stays 58/58.
4. Manual inspection of all 3 patched hooks — wired identically, all
   degrade-on-missing.
