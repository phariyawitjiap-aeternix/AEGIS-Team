# BREAKDOWN COMPLETE -- PROJ-US-001

## Story
As a developer, I want AEGIS to be production-ready with all documented features
actually working, so I can use it on real projects without hitting broken promises.

## Stats

| Metric | Count |
|--------|------:|
| Journeys | 4 |
| Epics | 4 |
| Tasks | 13 |
| Subtasks | 0 |
| Total Points | 55 |
| Est. Sprints | 3 (at ~20pts/sprint capacity) |

## Hierarchy Tree

```
PROJ-US-001: Production-ready AEGIS v8.0
├── PROJ-J-001: First-time user onboarding
│   └── PROJ-E-001: Installer works perfectly [10pts]
│       ├── PROJ-T-001: install.sh copies ALL v7.1 files including PM state files [3pts] @impl
│       ├── PROJ-T-002: install.sh creates ALL directories including tasks/ [2pts] @impl
│       └── PROJ-T-003: Post-install verification command (/aegis-doctor) [5pts] @impl
├── PROJ-J-002: Autonomous development workflow
│   └── PROJ-E-002: Nick Fury delivers on promises [18pts]
│       ├── PROJ-T-004: Nick Fury follows planning-before-build in practice [5pts] @impl
│       ├── PROJ-T-005: Multi-cycle within session (context budget aware) [8pts] @impl
│       └── PROJ-T-006: Cross-session continuity via handoff [5pts] @impl
├── PROJ-J-003: Quality assurance pipeline
│   └── PROJ-E-003: 3-Gate system works end-to-end [13pts]
│       ├── PROJ-T-007: Gate enforcement blocks kanban transitions [3pts] @impl
│       ├── PROJ-T-008: War Machine+Vision QA pipeline produces real reports [5pts] @test
│       └── PROJ-T-009: Coulson generates versioned ISO docs automatically [5pts] @doc
└── PROJ-J-004: Project management
    └── PROJ-E-004: PM state system is reliable [14pts]
        ├── PROJ-T-010: Sequential IDs work across all commands [3pts] @impl
        ├── PROJ-T-011: Task history is append-only and consistent [3pts] @impl
        ├── PROJ-T-012: Dashboard shows real computed metrics [5pts] @impl
        └── PROJ-T-013: Sprint close computes velocity correctly [3pts] @impl
```

## Loki Review Cross-Reference

This breakdown directly addresses findings from the adversarial review:

| Task | Loki Finding | Severity |
|------|--------------|----------|
| T-001 | H-001: install.sh missing v7.0 skills | CRITICAL |
| T-002 | H-002: install.sh missing output directories | CRITICAL |
| T-003 | H-020: No pre-flight diagnostic | HIGH |
| T-004 | H-005: Nick Fury cannot actually loop | HIGH |
| T-005 | H-005, H-011: Context window overflow | HIGH |
| T-006 | H-012: Multi-session continuity theoretical | HIGH |
| T-007 | H-006: 3-Gate system has no enforcement | HIGH |
| T-008 | H-006: QA pipeline advisory not mandatory | HIGH |
| T-009 | H-006: ISO docs not auto-generated | HIGH |
| T-010 | H-023: Task ID conflict breakdown vs kanban | MEDIUM |
| T-011 | H-023: History consistency | MEDIUM |
| T-012 | - : Dashboard rendering | MEDIUM |
| T-013 | - : Velocity computation | HIGH |

## Output Paths
- Task directories: `_aegis-brain/tasks/PROJ-{TYPE}-NNN/`
- Breakdown output: `_aegis-output/breakdown/PROJ-US-001/`
- Tasks ready for backlog: see meta.json files with status=BACKLOG

## Next Steps
Run `/aegis-sprint plan` to pull tasks into Sprint-1.
