# Sprint v15-05 — Close (VERIFIED CLEAN)

**Status**: CLOSED 2026-05-13
**Velocity**: 3/3 pt
**Outcome**: No changes needed — hooks already compatible

## What "no terminal access" actually means

CC 2.1.139 release note: "Hooks ตอนนี้รันโดยไม่มี terminal access → กัน hook เขียน output ทับ interactive prompt บนจอ"

This blocks:
- Direct tty writes (`> /dev/tty`)
- Interactive prompts (`read -p`)
- `stty` calls
- ANSI escapes that assume a tty (e.g., raw cursor positioning)

This does NOT block:
- `echo` / `printf` to stdout — captured by CC, shown to user normally
- Redirects to `>&2` — captured by CC as hook stderr
- ANSI color codes inside stdout — CC's UI renders them

## AEGIS hook audit

Scanned `.claude/hooks/*.sh` + `.claude/hooks/lib/*.sh`:

| Pattern searched | Matches |
|---|---|
| `> /dev/tty` | 0 |
| `read -p`, `read -s` from non-stdin | 0 |
| `stty` invocation | 0 |
| `/dev/tty` reference | 0 |
| Interactive prompt loop | 0 |

All output flows through stdout/stderr → CC captures → displays to user. The "no terminal" change is invisible to AEGIS hooks.

## When to revisit

- IF a future AEGIS feature adds an interactive hook prompt (don't do this — use the human-queue.md pattern instead)
- IF CC 2.1.139+ changes the spec further (e.g., stripping ANSI colors from hook stdout)

Neither condition holds today.
