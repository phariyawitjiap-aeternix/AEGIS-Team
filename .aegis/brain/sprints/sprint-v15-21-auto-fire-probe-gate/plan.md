# Sprint v15-21 — Auto-Fire Research Probe-Gate

> Close one of the v15-20 open follow-ups: make F-E (research URL probe) fire
> automatically on every write to `_aegis-output/research/*.md`, so Beast (and
> any other agent producing research docs) doesn't have to remember to invoke
> `aegis-research-probe.sh` manually.
>
> Driver: v15-20 shipped the probe tool but left invocation manual — humans
> and agents forget. Hook-level automation removes the discipline requirement.
> This also exercises v15-18B (settings-patch tool) recursively: the wiring
> ships as a `tools/aegis-settings-patches/*.jq` file users apply between
> sessions.

## Sprint metadata

- **ID**: sprint-v15-21-auto-fire-probe-gate
- **Points**: 2
- **Status**: SELECTED
- **Branch**: `claude/sprint-v15-21-auto-fire-probe-gate`
- **Gate style**: soft — hook always exits 0; probe tool itself is annotate-only

## How it works (one diagram)

```mermaid
flowchart LR
    classDef trig fill:#fef3c7,stroke:#d97706
    classDef act  fill:#dcfce7,stroke:#16a34a

    A[Any agent runs Edit/Write/MultiEdit] --> B{PostToolUse hook<br/>matcher Edit|Write|MultiEdit}
    B --> C[research-probe-on-write.sh]:::trig
    C --> D{file_path matches<br/>_aegis-output/research/*.md ?}
    D -->|no| E[exit 0 silently]
    D -->|yes| F[bash tools/aegis-research-probe.sh apply $FILE]:::act
    F --> G[URLs in file get<br/>PROBED ✓ / ✗ / UNPROBED tags]:::act
    G --> H[Beast / downstream agents cannot<br/>cite payload from UNPROBED URLs<br/>per Beast persona rule]
```

## Stories

| Story | Pts | Description |
|---|---|---|
| **A — `.claude/hooks/research-probe-on-write.sh`** | 1 | Hook reads PostToolUse JSON, filters by `tool_name in {Edit, Write, MultiEdit}` AND `file_path` matching `_aegis-output/research/*.md`, then runs `tools/aegis-research-probe.sh apply <file>`. Soft — exit 0 always. Logs to `/tmp/aegis-probe-hook.log` for debugging. Gracefully skips when probe tool missing (older AEGIS installs). |
| **B — `tools/aegis-settings-patches/wire-research-probe-hook.jq` + tests** | 1 | jq filter that appends the new hook command to the existing `Edit\|Write\|MultiEdit` PostToolUse block. Idempotent. Reversible via existing `aegis-settings-patch.sh revert`. `tests/aegis-research-probe-hook-test.sh` × 8: ignore Bash / ignore non-research path / annotate research path / patch idempotent / patch dry-run / soft gate / legacy compat. |

**Total: 2 pt**

## Acceptance criteria

- [ ] Hook fires on `_aegis-output/research/**/*.md` writes and produces probe annotations
- [ ] Hook ignores writes to all other paths (silent exit 0)
- [ ] Hook ignores non-Edit/Write/MultiEdit tool calls (Bash, Read, etc.)
- [ ] jq patch is idempotent (re-applying produces byte-identical output)
- [ ] jq patch reversible via `aegis-settings-patch.sh revert wire-research-probe-hook`
- [ ] AEGIS-Team's own settings.json gets the hook applied as part of this sprint (meta-apply, like v15-18B did)
- [ ] All 8 tests green standalone
- [ ] Full suite green
- [ ] Hook handles missing probe tool gracefully (silent skip — for older AEGIS installs not yet upgraded past v15-20)

## What this does NOT do (deferred)

- Hook-level enforcement of sub-agent return tagging (F-C hard gate) — would need a hook event on Task agent returns, which doesn't exist cleanly; v15-22+ candidate
- Playtest result skeleton auto-creation at sprint plan — v15-22+
- `runtime_helpers` glob-discover in install.sh — v15-22+ (kills the 2nd manifest-drift surface)

## Closes (per v15-20 learning file's follow-ups list)

- Auto-fire probe-gate on research-doc commits ✅

## Recursive validation

This sprint exercises v15-18B by using `aegis-settings-patch.sh apply wire-research-probe-hook`
to wire its own hook into AEGIS-Team's settings.json — same pattern v15-18B established for
v15-16 Story B (narrow `.*` matcher). Demonstrates the "between-session settings migration"
pattern is sustainable and scales.
