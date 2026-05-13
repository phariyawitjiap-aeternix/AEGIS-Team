# Sprint Kanban — sprint-v15-04-skill-wildcard-permissions

**Goal**: Wildcard Skill(aegis-*) permission cleanup
**Capacity**: 2pt
**Status**: CLOSED 2026-05-13 (no-op)

## DONE

- [x] [SW-1] Audit settings.json for Skill(*) enumeration to consolidate (@iron-man) — 1pt
      Result: 31 allow entries, 0 are Skill(*). Tools+tests already use `Bash(./tools/*)` and `Bash(./tests/*)` wildcards. No consolidation possible.
- [x] [SW-2] Document why this is a no-op + when to revisit (@coulson) — 1pt
      Close.md notes: revisit only if Claude Code starts requiring Skill(*) permissions for skill invocation.
