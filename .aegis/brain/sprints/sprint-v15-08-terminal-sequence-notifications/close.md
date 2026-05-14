# Sprint v15-08 Close — terminalSequence Notifications

**Status**: CLOSED (100%)
**Date**: 2026-05-14
**Tests**: 58/58 PASS (added `aegis-notify-test.sh` × 8 scenarios)
**Branch**: `claude/sprint-v15-08-terminal-sequence`

## What shipped

- `tools/aegis-notify.sh` — central helper for hook-driven desktop pings.
  Strictly additive JSON shape `{"terminalSequence": "..."}`. BEL fallback
  to stderr. Opt-in via `AEGIS_HOOK_NOTIFY=1`. Reentrant-source guarded.
- 3 hooks wired: `on-stop.sh` (session end), `session-start.sh` (sprint
  gate), `linear-sync-on-kanban.sh` (sync start).
- 8-scenario regression test.

## Schema spike result

CC 2.1.141 release notes documented `terminalSequence` as a hook JSON
output field. We confirmed the SAFE schema empirically:

- **Use**: `{"terminalSequence": "<ansi-escape-string>"}` only.
- **Avoid**: emitting `continue` alongside — for Stop hooks, `continue`
  has block/allow semantics that collide with our pure-notification intent.
- **Format**: OSC-9 (`ESC ] 9 ; <text> BEL`) is the most portable
  attention sequence. iTerm2, macOS Terminal.app (≥ Big Sur), Windows
  Terminal render it as a native banner. Everything else falls back to
  BEL ping.

## Implementation notes

- **Reentrant guard** uses `declare -f aegis_notify >/dev/null` as the
  sentinel — the first source defines the function, subsequent sources
  see the symbol and early-return.
- **Python3 JSON escaping** is the canonical path; if python3 is missing,
  the raw sequence is emitted with documented risk. AEGIS already requires
  python3 elsewhere, so this is a soft fallback only.
- **Stop hook safety**: by omitting `continue` we sidestep the entire
  question of "does emitting `continue: true` from Stop interfere with
  decision-based block semantics?" Strictly additive JSON wins.

## Verification

```
$ bash tools/aegis-notify.sh test session_end "smoke"
{"terminalSequence":"]9;AEGIS: smoke"}
[aegis-notify] sent event=session_end message=smoke

$ bash tests/aegis-notify-test.sh
Results: 8 passed, 0 failed

$ bash tests/run-all.sh --continue
ALL TESTS PASS — 58/58 in 88s
```

## Follow-ups

- Document `AEGIS_HOOK_NOTIFY=1` opt-in path in user-facing setup notes
  (deferred to v15-10 multi-tenant docs pass).
- Linear-sync-complete notification — would need a second hook after the
  subshell exits. Not worth the complexity yet; user can read the log if
  they care about completion vs start.

## Roadmap impact

v15 net deliverable count: 20pt → 23pt. Bumps to v15 series:
`20 selected / 20 done` → `23 selected / 23 done`.
