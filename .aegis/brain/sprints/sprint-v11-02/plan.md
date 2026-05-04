# Sprint v11-02 Plan: aegis-activity-logger (JSONL audit)

**Sprint Goal**: Ship `aegis-activity-logger` — append-only JSONL audit of every mutation, one file per UTC day. Closes G2 from the AEGIS-Plus Mega Plan and provides historical replay for `aegis-live-tail`.

**Points**: 5pt
**Branch**: `feat/v11-02-aegis-activity-logger`

## Stories

| ID | Story | Pt |
|----|-------|----|
| A | `log.mjs` PostToolUse hook (one JSONL line per Edit/Write/Bash, ≤100ms p95) | 2 |
| B | `view.mjs` CLI (`--today`, `--since`, `--persona`, `--tool`, `--watch`) | 1 |
| C | `stats.mjs` CLI (counts by day/persona/tool over a window) | 1 |
| D | Skill scaffolding + SKILL.md + tests | 1 |

## Storage

- `.aegis/brain/activity/YYYY-MM-DD.jsonl` — one JSON per line, never modify past entries
- Schema: `{"ts":"<ISO>","tool":"<Edit|Write|Bash|...>","target":"<file|cmd>","extra":"<diff|exit>","persona":"<name>","status":"<ok|err|warn|block>","session":"<id>"}`
- Reuses `format.mjs::eventFromHook()` from v11-01 to keep event shape canonical.

## Acceptance criteria (from plan §6.2)

- [ ] Every Edit/Write/Bash produces one JSONL line
- [ ] `view --today` prints today's entries
- [ ] `view --watch` tails today's file (text fallback to live-tail)
- [ ] `stats --week` shows tool counts by day
- [ ] Test: write a file, confirm activity entry exists with correct path
- [ ] Hook latency p95 <100ms
- [ ] Daily file rotation (no per-line overwrite of past entries)
