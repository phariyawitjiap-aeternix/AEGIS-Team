# Sprint v15-21 Kanban

## DONE

- [x] **A** — `.claude/hooks/research-probe-on-write.sh` (1pt)
  - PostToolUse hook: filters by tool_name + file_path; runs probe tool on match
  - Soft gate (exit 0 always); logs to `/tmp/aegis-probe-hook.log`
  - Gracefully skips when probe tool missing (older AEGIS install compat)
- [x] **B** — `tools/aegis-settings-patches/wire-research-probe-hook.jq` + tests (1pt)
  - jq patch appends hook to PostToolUse `Edit|Write|MultiEdit` block
  - Idempotent (re-apply byte-identical)
  - Reversible via `aegis-settings-patch.sh revert wire-research-probe-hook`
  - Tests × 8 all green
  - Patch applied to AEGIS-Team's own settings.json — sprint meta-self-applied

## Stories table

| Story | Type | Points | Status |
|-------|------|--------|--------|
| A — hook script | new hook | 1 | DONE |
| B — settings patch + tests | settings migration + tests | 1 | DONE |

**Total**: 2/2 done.

## Closes

- v15-20 follow-up: "Auto-fire probe-gate on research-doc commits" ✅

## Recursive validation note

This sprint USED `tools/aegis-settings-patch.sh` (shipped in v15-18B) to apply
its own hook wiring to AEGIS-Team's settings.json. Patch lives at
`tools/aegis-settings-patches/wire-research-probe-hook.jq` and ships to all
downstream projects on next install — they can apply it themselves with:

```
bash tools/aegis-settings-patch.sh apply wire-research-probe-hook
```

Followed by CC restart. This proves the v15-18B safe-migration pattern scales.

## Follow-ups (v15-22+ candidates, carried from v15-20 learning)

- Hook-level enforcement of sub-agent return tagging (F-C hard gate) — needs Task-return hook event
- Playtest result skeleton auto-creation at sprint plan
- `runtime_helpers` array in install.sh → glob-discover (2nd manifest-drift surface)
- Hard ack gate (block sprint until gaps acknowledged) — only if soft proves ignored
