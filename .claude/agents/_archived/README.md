# Archived Agents (Retired in v9)

These agents were retired in AEGIS v9 per Sprint v9-06 (S6-03/04/05).

## Why Archived

| Agent | Reason | Routing Replacement |
|-------|--------|---------------------|
| **vision.md** | Merged into War Machine | War Machine handles both QA strategy AND test execution |
| **wasp.md** | UX tasks too rare in v8.x (~5%) | Spider-Man + reference docs (ui-style-guide.md TBD) |
| **songbird.md** | Content/marketing rarely needed by AEGIS | Coulson handles docs + changelogs |

## Files Preserved For

1. **Reference**: existing patterns may be useful when designing replacement workflows
2. **Rollback**: if v9 plan changes mind, restore via `git mv ../_archived/AGENT.md ..`
3. **History**: shows AEGIS evolution from 13 → 10 agents

## DO NOT Spawn These Agents

The Agent tool will not find them in `.claude/agents/_archived/`. Spawn requests for `vision`, `wasp`, or `songbird` will fail.

For tasks they previously handled:

```typescript
// OLD: Agent({ subagent_type: "vision", ... })
// NEW: Agent({ subagent_type: "war-machine", ... })

// OLD: Agent({ subagent_type: "wasp", ... })
// NEW: Agent({ subagent_type: "spider-man", prompt: "Build UI component for X. Reference .claude/references/ui-style-guide.md for tokens." })

// OLD: Agent({ subagent_type: "songbird", ... })
// NEW: Agent({ subagent_type: "coulson", prompt: "Write changelog for X." })
```

## Active Agents (10)

After consolidation:
1. 🧬 Nick Fury (controller)
2. 🧭 Captain America (lead + fallback brain)
3. 📐 Iron Man (architect)
4. ⚡ Spider-Man (implementer)
5. 🛡️ Black Panther (reviewer)
6. 🔴 Loki (devil's advocate)
7. 🔧 Beast (scanner)
8. 🎯 War Machine (QA lead + executor, absorbed Vision)
9. 🚀 Thor (devops)
10. 📜 Coulson (compliance + docs, absorbed Songbird's content role)
