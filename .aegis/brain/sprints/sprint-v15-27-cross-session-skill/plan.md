# Sprint v15-27 — Cross-Session Awareness Skill

> User question 2026-05-25: "AEGIS เรียก `claude agents` ตอนไหน? ผ่าน skill มั้ย? skill อะไร?"
> Honest answer (then): NO skill — only command-level integration via
> `/aegis-start` Step 2.7 + `/aegis-status` Step 5.5.
>
> User follow-up: "ถ้าวิเคราะห์ว่าควรมี ก็ทำเลย"
> Analysis verdict: YES, marginally — the BEHAVIORAL rule of "consult
> cross-session state before parallel dispatch / brain writes" lives only
> in command files today. Personas don't see it in their toolkit.

## Why the skill is justified

v15-22 wired `claude agents --json` as a TOOL (`aegis-claude-agents.sh` +
`mt sessions`). v15-22 also wired it as a COMMAND (`/aegis-start` + `/aegis-status`).
What it didn't wire: the DECISION layer — "Nick Fury, before you dispatch
two parallel Task agents on the same project, check if another CC session
is already there."

That decision rule was implicit. A skill makes it discoverable:
1. Persona docs can `[[link]]` to the skill from their tool sections
2. FTS5 brain search surfaces it on queries like "race risk", "before dispatch"
3. Frontmatter graph wires it into `aegis-claude-agents.sh` + `mt sessions`
   so v12 knowledge graph queries answer "what uses the cross-session
   wrapper?" with the skill in the dependency list
4. `install.sh` glob-discovery ships it automatically (v15-18A pattern)

## Sprint metadata

- **ID**: sprint-v15-27-cross-session-skill
- **Points**: 1
- **Status**: SELECTED
- **Branch**: `claude/sprint-v15-27-cross-session-skill`

## Stories

| Story | Pts | Description |
|---|---|---|
| **A — `skills/aegis-cross-session-awareness.md`** | 0.5 | New skill doc. Frontmatter `profile: standard\|full` (ships at standard tier and above). Wires to `tools/aegis-claude-agents.sh` + `tools/aegis-multi-tenant/mt.mjs`. Tests pointer to `aegis-claude-agents-test.sh` + `aegis-mt-sessions-test.sh`. Body documents 4 decision rules + when to consult + how to invoke. Triggers en/th to surface on persona queries. |
| **B — Persona doc updates** | 0.5 | Add cross-session check to tool sections of: Nick Fury (Decision Brain — most important), Spider-Man (brain writes), Beast (research dispatch). Each gains a 1-line invocation + `[[aegis-cross-session-awareness]]` link. Skill count bumped 39 → 40 in tests/README/docs. |

**Total: 1 pt**

## Acceptance criteria

- [ ] `skills/aegis-cross-session-awareness.md` exists with full frontmatter (name, description, profile, triggers, reads, writes, wires, tests, supersedes)
- [ ] Nick Fury, Spider-Man, Beast persona docs each reference the skill in their "Tools You Can Reach For" sections
- [ ] Skill count bumped: 39 → 40 in `tests/aegis-skill-frontmatter-test.sh`, `README.md` badge + tagline, `docs/AEGIS_USER_JOURNEY.md`
- [ ] Full suite green (72/72 → 72/72; no test count change — this skill has no dedicated test, it points at the existing v15-22 tests)
- [ ] Skill frontmatter schema test passes ("40 skills satisfy schema")
- [ ] FUNC catalog regen catches the new skill

## What this skill does NOT do (deferred to v15-28+ when active dispatch lands)

- Spawn a background `claude agents` session (active dispatch)
- Send a message to another live session (inter-session messaging)
- Auto-handoff stale idle sessions
- Hard-lock brain writes on race detection (currently soft warning only)

## Linked memory

- [[aegis-coverage-contract]] — same family (cross-cutting awareness skills)
- v15-22 sprint plan/kanban — origin of the wrapper + mt-sessions wiring
- `docs/AEGIS_VS_NATIVE_CC.md` — strategic doc putting cross-session awareness on AEGIS's keep-and-invest list
