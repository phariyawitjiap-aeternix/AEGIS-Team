# Sprint v11-07 Plan: aegis-run-logger

**Points**: 8pt · **Branch**: `feat/v11-07-aegis-run-logger`

## Goal

On Stop hook, archive the complete Claude Code session transcript + meta to `.aegis/brain/runs/<date>-<session>/`. Closes part of G7.

## Stories

| ID | Story | Pt |
|----|-------|----|
| A | archive.mjs Stop hook — copy transcript_path file + write meta.json | 3 |
| B | replay.mjs CLI — render transcript prettily in terminal | 2 |
| C | list.mjs CLI — summarize archived runs (date / session / msg-count / persona) | 1 |
| D | SKILL.md + 16-assertion regression test | 2 |

## Storage

- `.aegis/brain/runs/<YYYY-MM-DD>-<session-id>/`
  - `meta.json` — `{ session_id, started_at, ended_at, persona, transcript_lines, source_path }`
  - `transcript.ndjson` — copy of Claude Code's transcript file (JSONL)

(`costUsd` field intentionally dropped per Mega Plan v1.1 — no cost tracking.)

## Hook wiring

`.claude/settings.json` Stop hook: chain `node tools/aegis-run-logger/archive.mjs` alongside the existing `on-stop.sh`. Stop hooks can be additive — both run.

## Acceptance criteria (Mega Plan §7.3)

- [ ] Every session produces one archive directory
- [ ] meta.json populated with required fields (no costUsd)
- [ ] transcript.ndjson is a verbatim copy of Claude Code's session file
- [ ] `replay <run-id>` shows pretty transcript (no Web UI)
- [ ] `list` summarizes archives across days
- [ ] Archive script never blocks Stop (fail-OPEN per Risk R6)
