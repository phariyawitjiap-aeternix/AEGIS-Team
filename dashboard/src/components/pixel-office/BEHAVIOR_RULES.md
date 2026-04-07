# Pixel Office — Behavior Rules

> Single source of truth for how agents behave in the Pixel Office.
> All behaviors are DATA-DRIVEN from `/api/agents` and `/api/kanban`.
> **No fake work. No fake meetings. No fake reports.**

---

## Golden Rule

```
API says work  → work
API says idle  → live your life
No exceptions.
```

---

## 1. Work Behaviors (driven by API status)

Only triggered when `/api/agents` returns a non-idle status for this agent.

| API Status | Behavior | Speed | Animation | Bubbles |
|-----------|----------|-------|-----------|---------|
| `working` | Sit at own desk, type | — (stationary) | Typing arms, screen glow | Role-specific blue: "Coding...", "Reviewing...", "Writing spec" |
| `blocked` | Sit at own desk, frustrated | — (stationary) | Still, no typing | Red: "Blocked...", "Blocked! 🚫" |
| `waiting` | Stand near own desk | — (stationary) | Slight sway | Yellow: "Waiting..." (occasional) |
| `done` → celebrate | Bounce at desk | — (stationary) | Jump + sparkles | Green: "Done! 🎉", "Complete! ✅" |
| `done` → report | Walk to Mother Brain orb | 2.0 px/frame | Walk cycle (satisfied) | Purple: role-specific MB report |
| `done` → socialize | Fall through to idle | 0.8 px/frame | Idle behaviors | — |

### Work Transitions (status changes)

| From → To | What Happens |
|-----------|-------------|
| `idle` → `working` | Agent walks home, bubble "On it!", start typing |
| `working` → `done` | Celebrate (120 ticks) → walk to MB → report → idle |
| `idle` → `done` | Celebrate (80 ticks) → walk to MB → report → idle |
| any → `blocked` | Walk home, red bubble "Blocked! 🚫" |

### Pipeline Handoff Chain

When an agent finishes and hands off to the next:

```
Sage → Bolt → Vigil → Sentinel → Probe → Scribe
```

Agent walks to next-in-chain's desk with handoff bubble:
- Sage: "Spec ready!", "Here, Bolt"
- Bolt: "Code done!", "PR ready"
- Vigil: "PASS!", "Approved ✅"
- Sentinel: "QA plan done", "Go Probe!"
- Probe: "All pass!", "Results in"

Receiving agent responds: "Got it!", "Thanks!", "On it!", "Roger!"

### Work Bubbles (role-specific)

| Agent | Work Bubbles (blue) |
|-------|-------------------|
| Navi | "Planning...", "Routing task", "Sprint check" |
| Sage | "Writing spec", "Designing...", "Architecture" |
| Bolt | "Coding...", "npm install", "Building...", "git commit" |
| Vigil | "Reviewing...", "Security?", "LGTM!", "Needs fix" |
| Havoc | "What if...?", "Edge case!", "Challenge!" |
| Forge | "Scanning...", "Metrics...", "grep -r" |
| Pixel | "UI wireframe", "Colors...", "Responsive?" |
| Muse | "Writing docs", "README...", "Changelog" |
| Sentinel | "Test plan", "Coverage?", "Risk matrix" |
| Probe | "Running...", "PASS ✅", "Testing..." |
| Scribe | "ISO docs", "SI.03...", "Tracing..." |
| Ops | "Deploying...", "Health OK", "docker build" |

---

## 2. Idle Behaviors (no work assigned)

Only triggered when `/api/agents` returns `idle` (or `done` after reporting).
**No work-like activities. Just life.**

| Behavior | Probability | Duration | Speed | Bubbles |
|----------|:-----------:|----------|-------|---------|
| Chat with idle friend | 28% | 120-250 ticks | 0.8 px/frame | Casual personality chat |
| Coffee / water break | 17% | 150-300 ticks | 0.8 px/frame | "☕", "Ahh...", "*sip*" |
| Walk around (aimless) | 13% | until arrival | 0.8 px/frame | "🎵", "💭", "..." |
| Hang near friend | 12% | auto return | 0.8 px/frame | — |
| Idle at desk | 30% | 400-800 ticks | — (stationary) | "*stretch*", "*yawn*", "📱", "🎵" |

### Idle Chat (personality-specific, NOT work)

| Agent | Casual Chat |
|-------|------------|
| Navi | "What a day", "Any plans?", "Lunch?" |
| Sage | "Read this?", "Cool article", "Interesting..." |
| Bolt | "Games later?", "LFG!", "Weekend?", "So tired lol" |
| Vigil | "Stay sharp", "Good job", "Not bad" |
| Havoc | "Haha!", "No way!", "Crazy!", "LOL" |
| Forge | "Did you see", "Numbers!", "Cool stats" |
| Pixel | "Love this!", "Colors!", "So pretty" |
| Muse | "Great read", "Typo!", "Creative!" |
| Sentinel | "All quiet", "No bugs", "Peaceful", "Boring day" |
| Probe | "Tests pass", "Clean!", "Easy day" |
| Scribe | "Filed it", "All good", "Organized" |
| Ops | "Servers up", "All green", "Quiet day" |

### Social Rules

- **Only chat with idle friends** — don't bother working agents
- **Friend responds** with their own personality bubble (40 tick delay)
- **Walk away after chat** — go home or wander
- **Trigger interval** — 500-1000 ticks between social actions (not spam)

---

## 3. Mother Brain Orb

| State | Condition | Visual |
|-------|----------|--------|
| **Active** | Any agent is `working` or `blocked` or `done` | Magenta glow, pulse, 12+6 particles orbiting |
| **Sleeping** | All agents are `idle` | Dim purple (#332244), slow breathing, no particles, floating "Zzz", label "sleeping — no work" |
| **Stale** | Heartbeat > 60s old | Yellow, slow pulse, 6 particles |

### MB Interaction Rules

- Agents visit MB orb **ONLY** after completing real work (`done` → `reporting_to_mb`)
- Idle agents that wander near MB just glance ("🧬") and leave quickly (30-60 ticks)
- **No fake check-ins. No fake reporting.**

### MB Report Bubbles (purple, only after real work)

| Agent | Report to MB |
|-------|-------------|
| Sage | "Spec complete", "Design ready", "ADR filed" |
| Bolt | "Build done", "Code merged", "Tests pass" |
| Vigil | "Review done", "Gate 1 pass", "Clean code" |
| Sentinel | "QA complete", "Gate 2 pass", "All tested" |
| Scribe | "ISO updated", "Gate 3 pass", "Docs synced" |
| Ops | "Deployed OK", "Health green", "Gate 4 pass" |

---

## 4. Movement Speed

| Context | Speed | Leg Animation |
|---------|:-----:|:------------:|
| Working (going to desk, collaborating, reporting) | 2.5 px/frame | Every 6 ticks |
| Done (satisfied walk) | 2.0 px/frame | Every 8 ticks |
| Idle (stroll, coffee, chat) | 0.8 px/frame | Every 14 ticks |

---

## 5. Wall Kanban Board

Real-time data from `/api/kanban` (SWR polling every 5s):

- **3 columns**: TODO, WIP (IN_PROGRESS + IN_REVIEW + QA), DONE
- **Cards** colored by assignee agent color
- **WIP cards** pulse border (active work indicator)
- **DONE cards** show ✓ checkmark
- **Progress bar** at top: completed_pts / total_pts
- **Sprint name** + percentage displayed

---

## 6. What We NEVER Do

```
❌ Fake work bubbles when idle
❌ Fake "check in with MB" when idle
❌ Fake meetings when no team command active
❌ Fake "reporting" when no task was completed
❌ Work speech bubbles ("Coding...", "Reviewing...") when status is idle
❌ Mother Brain active/glowing when no work exists
❌ Fast walking when just going for coffee
```

---

## 7. Implementation Files

| File | Responsibility |
|------|---------------|
| `types.ts` | Agent state types, behavior states, speech bubble types |
| `behaviors.ts` | State machine: status → behavior → bubbles + movement targets |
| `pathfinding.ts` | Movement speed (state-aware), walk animation, collision |
| `sprites.ts` | All drawing: agents, MB orb, office, wall kanban, speech bubbles |
| `PixelOfficeCanvas.tsx` | Main loop: tick → behavior → move → draw. Data from hooks |
