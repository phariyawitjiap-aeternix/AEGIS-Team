# Sprint v11-06 Plan: aegis-router (model-tier picker)

**Points**: 8pt · **Branch**: `feat/v11-06-aegis-router`

## Goal

Auto-pick subagent model tier based on **quality fit** (not cost — unlimited budget per Mega Plan v1.1). Closes G6.

## Stories

| ID | Story | Pt |
|----|-------|----|
| A | `routing/policy.yaml` schema + default rules + scaffolding | 1 |
| B | `route.mjs` CLI — given (task, persona) input → recommended model + reason + audit log line | 4 |
| C | Skill content with 4 worked examples + Agent-call integration pattern | 2 |
| D | Tests + audit log + manual override + --json | 1 |

## Storage

- `.aegis/brain/routing/policy.yaml` — ordered rules; first match wins
- `.aegis/brain/logs/routing-audit.log` — JSON-per-line: `{ts, task_summary, persona, picked, reason, override}`

## Default tiers (unlimited budget; optimize for quality fit)

| Model | When |
|---|---|
| `opus`   | adversarial review (Loki), architecture (Iron Man), complex design, ambiguous specs |
| `sonnet` | implementation (Spider-Man), standard reviews, refactor, test writing |
| `haiku`  | quick lookups, file enumeration, trivial substitutions, tight latency |

Override always wins — operator can pass `--model opus` and router respects it.

## Acceptance criteria (Mega Plan §7.2)

- [ ] Routing decision logged to `routing-audit.log` with model + reason
- [ ] Manual override: `--model X` returns X regardless of policy
- [ ] Per-persona rules supported (e.g. Loki always opus)
- [ ] Per-task-keyword rules supported
- [ ] First-match-wins ordering
- [ ] `--json` output for tooling
- [ ] At least 4 default rules ship

## Out of scope (deferred to v11-07/08)

- Run archival → v11-07
- Trace export with PII redaction → v11-08
