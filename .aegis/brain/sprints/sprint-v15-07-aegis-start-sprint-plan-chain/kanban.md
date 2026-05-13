# Sprint Kanban — sprint-v15-07-aegis-start-sprint-plan-chain

**Goal**: Tight chain from /aegis-start → /aegis-sprint plan with no shortcut
**Capacity**: 3pt
**Status**: CLOSED 2026-05-14

## DONE

- [x] [SC-1] Add slash-command chaining protocol section to aegis-start.md Step 4b-ENFORCE (@iron-man) — 1pt
      Explicit 5-step protocol: Read .claude/commands/aegis-<cmd>.md → locate subcommand → execute verbatim → persist artifacts → return.
      Anti-pattern documented: "I'll create kanban.md inline" is BANNED.
- [x] [SC-2] Add session-start.sh banner when no sprint dir exists (@thor) — 1pt
      Bordered banner with concrete instructions for Nick Fury. Logs to activity.log.
- [x] [SC-3] Smoke test both cases (banner fires / banner suppressed) (@war-machine) — 1pt
      Verified: banner emits when sprints/ has no sprint-* subdirs; banner suppressed when at least one exists.
