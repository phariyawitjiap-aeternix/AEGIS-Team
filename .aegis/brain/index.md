# AEGIS Brain Index
> Auto-maintained content catalog. Updated by agents on every brain write.
> Pattern: Karpathy's LLM Wiki index.md

Last updated: 2026-04-19

## Resonance

- [anti-patterns.md](resonance/anti-patterns.md) — Patterns that caused gate failures 2+ times; agents are warned on similar tasks
- [architecture-decisions.md](resonance/architecture-decisions.md) — Immutable ADRs accumulated from debate sessions and retrospectives
- [evolved-patterns.md](resonance/evolved-patterns.md) — Proven patterns that appeared 3+ times and are auto-applied
- [project-identity.md](resonance/project-identity.md) — Project name, purpose, and core identity of AEGIS
- [team-conventions.md](resonance/team-conventions.md) — Communication standards and agent workflow conventions

## Instincts

### Pending

- [example-quality-over-speed.yaml](instincts/pending/example-quality-over-speed.yaml) — Seed instinct: always fix the code to pass quality rules rather than suppressing them
- [sentinel-markers-over-comment-regex.yaml](instincts/pending/sentinel-markers-over-comment-regex.yaml) — Use `<<< NAME-START >>>` markers for auto-managed blocks, not comment regex
- [file-as-source-of-truth-over-dual-write.yaml](instincts/pending/file-as-source-of-truth-over-dual-write.yaml) — File system = truth, external services = read-through cache (avoid dual-write peer)
- [dogfood-validates-design.yaml](instincts/pending/dogfood-validates-design.yaml) — Apply infrastructure changes to framework's own repo before shipping to users

### Active

(none yet)

### Promoted

- [route-questions-through-nick-fury.yaml](instincts/promoted/route-questions-through-nick-fury.yaml) — Master Brain Protocol: non-Fury agents route all questions through Nick Fury, never ask the human directly

## Learnings

(none yet)

## Sprints

- [sprints/current/](sprints/current/) — Active sprint (kanban, plan, metrics)
- [sprints/sprint-1/](sprints/sprint-1/) — Sprint 1 archive (kanban, plan, metrics)
- [sprints/sprint-2/](sprints/sprint-2/) — Sprint 2 archive (kanban, plan, metrics)
- [sprints/sprint-3/](sprints/sprint-3/) — Sprint 3 archive (kanban, plan, metrics)

## Retrospectives

(none yet)

## Logs

- [logs/activity.log](logs/activity.log) — Append-only session and agent activity log
