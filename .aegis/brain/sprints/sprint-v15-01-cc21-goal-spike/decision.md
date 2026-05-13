<!-- version: 1.0.0 -->
<!-- Last updated: 2026-05-13 -->

# Decision — CC 2.1.139 `/goal` adoption for AEGIS

## TL;DR

**Recommendation: HYBRID.** Use CC `/goal` as the autonomous-loop primitive; keep Nick Fury's brain (Decision Matrix + BLOCK 0 + agent-dispatch logic + MBP) layered *inside* the loop. Migrate the heartbeat-mechanics (SendMessage polling, idle/timeout nudges, context-budget watchdog) to `/goal`'s native primitives. Estimated 13pt of follow-up work, gated on a successful 2pt prototype.

**Re-evaluate**: when `/goal` adds either (a) typed goal-state schemas, or (b) sub-goal nesting. Either would unlock more delegation.

## Why hybrid, not replace

`/goal`'s 1-line spec ("ทำต่อข้าม turn จนถึงเงื่อนไขที่ตั้งไว้") covers the **mechanism**, not the **policy**. AEGIS's Nick Fury isn't valuable because she loops — it's because she encodes:

- A 10-priority **Decision Matrix** (P0 hotfix → P10 empty-project bootstrap)
- **BLOCK 0** gates (PM.01 / SI.01 / kanban / SI.02) that pause work until docs catch up
- **Agent routing** by task type (build → spider-man, test → war-machine, docs → coulson, etc.)
- **MBP escalation** — only 4 categories ever reach the human
- **ISO 29110 compliance** enforcement at sprint open/close

`/goal` provides none of these. It provides the loop primitive that today is hand-rolled across:
- `nick-fury.md` § "Decision Cycle (per session)"
- Subagent spawn with `run_in_background=true`
- Manual SendMessage polling + 120s/300s nudge/respawn windows
- Context-budget watchdog (stop at ≥80%)

So the migration is **loop substrate → CC**, not **brain → CC**.

## Capability matrix

| Dimension | Nick Fury (current) | CC `/goal` 2.1.139 | Verdict |
|---|---|---|---|
| Cross-turn continuation | Manual: subagent + SendMessage polling | Native command primitive | `/goal` wins |
| Cost transparency | Manual context-budget check at each cycle | Native overlay panel (elapsed/turns/tokens) | `/goal` wins, much better UX |
| Decision Matrix (P0–P10) | Encoded in nick-fury.md, ~80 lines of policy | None (user defines goal text only) | Nick Fury essential |
| BLOCK 0 gates | Hard-stop logic in nick-fury.md §HARD BLOCKS | None (would need to be in goal text or pre-check) | Nick Fury essential |
| Agent routing by task type | Captain America + persona dispatch | None | Nick Fury essential |
| MBP / 4-category escalation | Hook + guard-ask-user + nick-fury policy | None | Nick Fury essential |
| Idle-agent nudge / timeout-respawn | Manual: 120s/300s thresholds | Unknown — release notes don't say. Probably similar primitives exist | TBD; prototype |
| Sub-goal nesting (recursive loops) | Subagent spawning subagents (works) | Single `/goal` per session per release notes | Nick Fury wins; release-note limitation |
| Cancellation / interrupt | Ctrl+C interrupts; aegis-mode --autonomy L1 downgrades | Native — `/goal` has overlay panel + presumably an abort | `/goal` cleaner UX, but parity functionally |
| Auditability | activity.log + decision-audit.log + retro | OTEL spans now carry `agent_id`/`parent_agent_id` | Both — combinable |

**Net**: 2 wins for `/goal` (loop substrate + cost UX), 4 wins for Nick Fury (policy layer), 1 TBD (nudge/respawn). The two systems are not substitutes — they're complementary layers.

## Proposed hybrid architecture

```
┌──────────────────────────────────────────────────────────────────┐
│  /goal "complete sprint v15-XX OR escalate per MBP"              │
│  (CC native loop, overlay panel, agent_id propagation)           │
│       │                                                           │
│       ▼ each turn:                                                │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  Nick Fury cycle (existing policy layer)                   │  │
│  │   1. scan state (git/tests/sprint/kanban/specs/deps/debt)  │  │
│  │   2. Decision Matrix (P0..P10)                             │  │
│  │   3. BLOCK 0 gate check                                    │  │
│  │   4. dispatch sub-agents (Agent tool, bg=true)             │  │
│  │   5. log decision (activity.log + decision-audit.log)      │  │
│  └────────────────────────────────────────────────────────────┘  │
│       │                                                           │
│       ▼ loop until goal met OR MBP escalation                     │
└──────────────────────────────────────────────────────────────────┘
```

The mechanical bits (SendMessage polling, manual idle-nudge, context-budget watchdog, "exit when >= 80%") get replaced by `/goal`'s native flow. The brain stays.

## What this means for the AEGIS codebase

| Concern | Action |
|---|---|
| `.claude/agents/nick-fury.md` | Keep, but cut the §HEARTBEAT LOOP and §Context Window sections that duplicate `/goal` |
| `tools/aegis-parallel-dispatch/` | Likely still useful for multi-agent fan-out within a `/goal` turn |
| `/aegis-start` Step 4 | Replace "spawn nick-fury subagent run_in_background=true" with "open `/goal '... per Decision Matrix ...'` then Nick Fury persona runs inside each turn" |
| `aegis-resume` (v11 skill) | Keep — `/goal` doesn't replace cross-session continuity |
| Activity log + decision-audit log | Keep — `/goal` overlay is ephemeral; AEGIS needs durable audit |
| OTEL spans | New `agent_id`/`parent_agent_id` headers — wire into aegis-trace-export |

Estimated downstream sprint sequence (rough order):

- **v15-01** (this sprint): decision doc — DONE
- **v15-02** (3pt): wire `/goal` into `/aegis-start` Step 4; deprecate manual subagent dispatch loop; keep nick-fury.md persona but trim duplicate loop policy
- **v15-03** (5pt): migrate approval-gate to `continueOnBlock: true` (separate from /goal but same release)
- **v15-04** (2pt): wildcard-permission cleanup `Skill(aegis-*)`
- **v15-05** (3pt): hooks "no terminal" compatibility check + queue-banner refactor if needed

## Re-evaluate when

- CC `/goal` adds nested sub-goals → could absorb Captain America's role
- CC adds typed goal-state schemas → could absorb Decision Matrix
- CC adds policy hooks at goal-boundary level → could absorb MBP escalation
- AEGIS metrics show Nick Fury policy is being routed around (drift signal)

Any one of those = revisit. Today's call holds for at least 1 quarter.

## Risks

1. **`/goal` is a one-shot command** — release notes don't describe nesting. If true, AEGIS multi-sprint runs may still need Nick Fury's outer orchestration even after migration. Mitigation: run a 2pt prototype before committing v15-02.
2. **CC overlay panel may not surface in headless/remote contexts** — release mentions `-p` and Remote Control support but the live UI is interactive-first. Mitigation: keep activity.log emission unchanged.
3. **Token cost might shift** — `/goal` "ป้องกัน runaway cost" is the marketing claim. Verify via OTEL spans on a real run before declaring win.

## Provenance

- 2026-05-13 — User shared CC 2.1.139 release notes (`/goal` + 30+ other changes)
- 2026-05-13 — Capability matrix built from release-note features vs `.claude/agents/nick-fury.md` content
- 2026-05-13 — Decision: HYBRID. This doc, plan.md, kanban.md committed under sprint v15-01-cc21-goal-spike.
