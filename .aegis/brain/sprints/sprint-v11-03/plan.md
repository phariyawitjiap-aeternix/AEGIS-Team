# Sprint v11-03 Plan: aegis-issue-thread (YAML tickets)

**Points**: 5pt · **Branch**: `feat/v11-03-aegis-issue-thread`

## Stories
| ID | Story | Pt |
|----|-------|----|
| A | `issue.mjs` CLI — create, update, comment, list, link, show subcommands | 3 |
| B | YAML emitter + parser (scoped to issue schema, no external dep) | 1 |
| C | SKILL.md + 12-assertion regression test | 1 |

## Storage
- `.aegis/brain/issues/<KEY>-<N>.yaml` — one file per issue (plan §6.3 schema)
- `.aegis/brain/issues/_index.yaml` — fast lookup table
- `.aegis/brain/issues/_config.yaml` — prefix configuration (default `KTH`)

## Acceptance criteria (plan §6.3)
- [ ] create produces well-formed YAML + updates index
- [ ] comment appends without rewriting whole file (line-append only)
- [ ] list filters by status/assignee
- [ ] link adds typed link (file/pr/url) to issue
- [ ] show prints a single issue cleanly
- [ ] auto-increment N from _index.yaml
- [ ] status enum enforced: todo|in_progress|blocked|review|done|cancelled

## Decision: 1 CLI file vs 5 separate files
Plan §6.3 lists 5 .mjs files. We collapse to one `issue.mjs` with subcommands. Functional equivalence; saves boilerplate and aligns with how Claude Code skills typically dispatch (subcommand string from skill body). Recorded as deviation in close.md.
