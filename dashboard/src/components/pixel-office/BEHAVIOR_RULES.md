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
| `done` → report | Walk to Nick Fury orb | 2.0 px/frame | Walk cycle (satisfied) | Purple: role-specific Nick Fury report |
| `done` → socialize | Fall through to idle | 0.8 px/frame | Idle behaviors | — |

### Work Transitions (status changes)

| From → To | What Happens |
|-----------|-------------|
| `idle` → `working` | Agent walks home, bubble "On it!", start typing |
| `working` → `done` | Celebrate (120 ticks) → walk to Nick Fury → report → idle |
| `idle` → `done` | Celebrate (80 ticks) → walk to Nick Fury → report → idle |
| any → `blocked` | Walk home, red bubble "Blocked! 🚫" |

### Pipeline Handoff Chain

When an agent finishes and hands off to the next:

```
Iron Man → Spider-Man → Black Panther → War Machine → Vision → Coulson
```

Agent walks to next-in-chain's desk with handoff bubble:
- Iron Man: "Spec ready!", "Here, Spider-Man"
- Spider-Man: "Code done!", "PR ready"
- Black Panther: "PASS!", "Approved ✅"
- War Machine: "QA plan done", "Go Vision!"
- Vision: "All pass!", "Results in"

Receiving agent responds: "Got it!", "Thanks!", "On it!", "Roger!"

### Work Bubbles (role-specific)

| Agent | Work Bubbles (blue) |
|-------|-------------------|
| Captain America | "Planning...", "Routing task", "Sprint check" |
| Iron Man | "Writing spec", "Designing...", "Architecture" |
| Spider-Man | "Coding...", "npm install", "Building...", "git commit" |
| Black Panther | "Reviewing...", "Security?", "LGTM!", "Needs fix" |
| Loki | "What if...?", "Edge case!", "Challenge!" |
| Beast | "Scanning...", "Metrics...", "grep -r" |
| Wasp | "UI wireframe", "Colors...", "Responsive?" |
| Songbird | "Writing docs", "README...", "Changelog" |
| War Machine | "Test plan", "Coverage?", "Risk matrix" |
| Vision | "Running...", "PASS ✅", "Testing..." |
| Coulson | "ISO docs", "SI.03...", "Tracing..." |
| Thor | "Deploying...", "Health OK", "docker build" |

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
| Captain America | "What a day", "Any plans?", "Lunch?" |
| Iron Man | "Read this?", "Cool article", "Interesting..." |
| Spider-Man | "Games later?", "LFG!", "Weekend?", "So tired lol" |
| Black Panther | "Stay sharp", "Good job", "Not bad" |
| Loki | "Haha!", "No way!", "Crazy!", "LOL" |
| Beast | "Did you see", "Numbers!", "Cool stats" |
| Wasp | "Love this!", "Colors!", "So pretty" |
| Songbird | "Great read", "Typo!", "Creative!" |
| War Machine | "All quiet", "No bugs", "Peaceful", "Boring day" |
| Vision | "Tests pass", "Clean!", "Easy day" |
| Coulson | "Filed it", "All good", "Organized" |
| Thor | "Servers up", "All green", "Quiet day" |

### Social Rules

- **Only chat with idle friends** — don't bother working agents
- **Friend responds** with their own personality bubble (40 tick delay)
- **Walk away after chat** — go home or wander
- **Trigger interval** — 500-1000 ticks between social actions (not spam)

---

## 3. Nick Fury Command Orb

| State | Condition | Visual |
|-------|----------|--------|
| **Active** | Any agent is `working` or `blocked` or `done` | Magenta glow, pulse, 12+6 particles orbiting |
| **Sleeping** | All agents are `idle` | Dim purple (#332244), slow breathing, no particles, floating "Zzz", label "sleeping — no work" |
| **Stale** | Heartbeat > 60s old | Yellow, slow pulse, 6 particles |

### Orb Interaction Rules

- Agents visit the orb **ONLY** after completing real work (`done` → `reporting_to_mb`)
- Idle agents that wander near the orb just glance ("🧬") and leave quickly (30-60 ticks)
- **No fake check-ins. No fake reporting.**

### Nick Fury Report Bubbles (purple, only after real work)

| Agent | Report to Nick Fury |
|-------|---------------------|
| Iron Man | "Spec complete", "Design ready", "ADR filed" |
| Spider-Man | "Build done", "Code merged", "Tests pass" |
| Black Panther | "Review done", "Gate 1 pass", "Clean code" |
| War Machine | "QA complete", "Gate 2 pass", "All tested" |
| Coulson | "ISO updated", "Gate 3 pass", "Docs synced" |
| Thor | "Deployed OK", "Health green", "Gate 4 pass" |

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
- **Cards** colored by assignee agent color (Marvel-themed palette in `lib/constants.ts`)
- **WIP cards** pulse border (active work indicator)
- **DONE cards** show ✓ checkmark
- **Progress bar** at top: completed_pts / total_pts
- **Sprint name** + percentage displayed

---

## 6. What We NEVER Do

```
❌ Fake work bubbles when idle
❌ Fake "check in with Nick Fury" when idle
❌ Fake meetings when no team command active
❌ Fake "reporting" when no task was completed
❌ Work speech bubbles ("Coding...", "Reviewing...") when status is idle
❌ Nick Fury orb active/glowing when no work exists
❌ Fast walking when just going for coffee
```

---

## 7. Implementation Files

| File | Responsibility |
|------|---------------|
| `types.ts` | Agent state types, behavior states, speech bubble types |
| `behaviors.ts` | State machine: status → behavior → bubbles + movement targets |
| `pathfinding.ts` | Movement speed (state-aware), walk animation, collision |
| `sprites.ts` | All drawing: agents, Nick Fury orb, office, wall kanban, speech bubbles |
| `PixelOfficeCanvas.tsx` | Main loop: tick → behavior → move → draw. Data from hooks |
