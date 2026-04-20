# ScheduleWakeup + ToolSearch + Agent Consolidation (Sprint v9-06)

> **Purpose**: Self-paced loops, lazy-load tools, reduce 13 agents → 10.

## Part 1: ScheduleWakeup for Brain Maintenance (S6-01)

Auto-trigger pattern extraction without manual `/aegis-distill` calls.

### Trigger Conditions

```python
# Hook: post-task-complete
if tasks_completed_since_last_distill >= 3:
    ScheduleWakeup({
        delaySeconds: 1800,    # 30 min
        prompt: "/aegis-distill",
        reason: "auto-distill: 3 tasks completed since last run"
    })
```

### Schedule Strategy

- After 3 tasks complete → schedule distill in 30 min (let dust settle)
- Daily at 22:00 → run `/aegis-evolve` (cluster duplicates)
- Weekly Sunday 23:00 → run `/aegis-lint` (brain health check)

### Why ScheduleWakeup vs CronCreate

- ScheduleWakeup = self-paced (cache stays warm if < 5 min)
- CronCreate = wall-clock cron (always cold start)
- Brain maintenance is "do soon" not "do at exact time" → ScheduleWakeup wins

## Part 2: ToolSearch / Deferred Tools (S6-02)

Currently AEGIS preloads ALL agent schemas at session start = context bloat.

### New Approach

```json
// .claude/settings.json
{
  "tools": {
    "deferred": [
      "aegis-deploy", "aegis-compliance", "aegis-launch",
      "aegis-pipeline", "aegis-evolve", "aegis-distill",
      "aegis-ingest", "aegis-lint", "aegis-flow"
    ],
    "always_load": [
      "aegis-start", "aegis-retro", "aegis-status", "aegis-mode",
      "aegis-team-build", "aegis-team-review", "aegis-context"
    ]
  }
}
```

Always-load = 7 commands (essential for every session)
Deferred = 9 commands (load via ToolSearch when triggered)

### How Deferred Loading Works

1. Session starts → only 7 always-load commands visible
2. User says "let me deploy" → Claude calls ToolSearch with query "deploy"
3. ToolSearch returns aegis-deploy schema
4. Claude can now invoke aegis-deploy
5. Schema stays loaded for rest of session

### Token Savings Estimate

- Before: 31 commands × ~200 tokens each = 6,200 tokens preloaded
- After: 7 commands × ~200 tokens = 1,400 tokens preloaded
- Saving: ~4,800 tokens per session start
- Trade-off: 1 extra ToolSearch call when deferred tool needed (~500 tokens)
- Net: significant savings if user only uses 2-3 commands per session

## Part 3: Agent Consolidation (S6-03 to S6-07)

### Current 13 Agents → Target 10 Agents

| Action | From | To | Reason |
|--------|------|----|----|
| KEEP | Nick Fury | Nick Fury | Master controller (irreplaceable) |
| KEEP | Captain America | Captain America | Fallback brain (added per ADR-001) |
| KEEP | Iron Man | Iron Man | Architect (specs + ADRs) |
| KEEP | Spider-Man | Spider-Man | Implementer |
| KEEP | Black Panther | Black Panther | Reviewer / quality gate |
| KEEP | Loki | Loki | Adversarial review (proven valuable) |
| KEEP | Beast | Beast | Scanner (haiku, fast) |
| KEEP | Thor | Thor | DevOps |
| KEEP | Coulson | Coulson | Compliance + docs |
| **MERGE** | Vision | → War Machine | Test execution merges into QA Lead |
| **RETIRE** | Wasp | (route to Spider-Man) | UX tasks rare; route to Spider-Man + style guide |
| **RETIRE** | Songbird | (route to Coulson) | Content tasks merge with compliance docs |

### Merger: Vision → War Machine (S6-03)

War Machine becomes both QA strategist + executor.

Updated [.claude/agents/war-machine.md](../.claude/agents/war-machine.md):
- Plans test strategy (existing role)
- Executes test cases (Vision's role)
- Reports test results
- Gates releases

Vision archived to `.claude/agents/_archived/vision.md`

### Retirement: Wasp (S6-04)

Wasp UX tasks were rare in v8.x (~5% of total tasks).

Routing change:
- "Design UI component" → Spider-Man + reference [.claude/references/ui-style-guide.md](../.claude/references/ui-style-guide.md)
- "Accessibility review" → Black Panther (a11y is a quality concern)

Wasp archived. Reference doc updated.

### Retirement: Songbird (S6-05)

Songbird was content/marketing-focused. AEGIS rarely needs marketing content.

Routing change:
- "Write README" → Coulson (docs)
- "Draft changelog" → Coulson
- "Marketing copy" → out of scope (use external tool)

Songbird archived.

### Command Consolidation (S6-06)

31 commands → 12 core commands

| Keep (12) | Reason |
|-----------|--------|
| /aegis-start | Required entry point |
| /aegis-retro | Required exit point |
| /aegis-status | Daily check-in |
| /aegis-mode | Profile/autonomy switch |
| /aegis-team-build | Build pipeline |
| /aegis-team-review | Review pipeline |
| /aegis-team-debate | Multi-perspective decision |
| /aegis-sprint | Sprint management |
| /aegis-kanban | Kanban view |
| /aegis-memory | Brain query |
| /aegis-doctor | Health check |
| /aegis-context | Context budget |

Deferred (load via ToolSearch when needed):
- /aegis-pipeline, /aegis-deploy, /aegis-compliance, /aegis-launch
- /aegis-flow, /aegis-evolve, /aegis-distill, /aegis-lint, /aegis-ingest
- /aegis-instinct, /aegis-adr, /aegis-handoff, /aegis-breakdown
- /aegis-dashboard, /aegis-qa, /aegis-verify
- /aegis-team-build/review/debate (alternative direct calls)
- /aegis-reengineer

### Documentation Update (S6-07)

Update files to reflect 10-agent + 12-command model:
- CLAUDE.md (Quick Commands table)
- CLAUDE_agents.md (agent table)
- CLAUDE_skills.md (deprecated skills tagged)
- README.md (overview)

## Acceptance Criteria

- [x] ScheduleWakeup design + trigger conditions
- [x] ToolSearch / deferred tools config
- [x] Agent consolidation map (13→10)
- [x] Merge: Vision → War Machine specified
- [x] Retire: Wasp, Songbird specified
- [x] Command consolidation (31→12 core + 19 deferred)
- [ ] Implementation: actual file changes (deferred -- requires careful testing of each agent removal)
- [ ] CLAUDE.md/agents/skills updates (deferred to incremental refactor)

**Sprint 6 Status**: Design complete. Agent removals deferred to staged execution (one agent per session, with regression testing) to avoid breaking workflows mid-Sprint.
