# UX Blueprint -- AEGIS Web Dashboard + Pixel Office

> Document: UX-DASH-001 | Version: 1.0 | Author: Sage | Date: 2026-03-30
> Status: DRAFT -- Pending Vigil/Havoc review

---

## 1. User Personas

### Persona A: "The Operator"
- **Who:** Developer actively running AEGIS on a project
- **Goal:** See what agents are doing right now without reading raw files
- **Context:** Has terminal open, switches to browser tab to check dashboard
- **Key screens:** Home, Kanban, Timeline, Agent Detail
- **Pain point:** Parsing log files and JSON to understand agent status

### Persona B: "The Lead"
- **Who:** Technical lead overseeing an AEGIS-powered team
- **Goal:** Track sprint progress, quality gates, and velocity
- **Context:** Checks dashboard at standup cadence (daily or more)
- **Key screens:** Home, Burndown, Gates, ISO
- **Pain point:** No aggregated view of quality and progress metrics

### Persona C: "The Evaluator"
- **Who:** Developer or manager evaluating AEGIS for adoption
- **Goal:** Quickly understand what AEGIS does and how agents collaborate
- **Context:** First-time visitor, needs to be impressed in 30 seconds
- **Key screens:** Pixel Office, Home
- **Pain point:** AEGIS is abstract; file-based state is not demonstrable

---

## 2. User Flows

### Flow 1: Morning Check-in (Operator)

```
[Open Dashboard] --> [Home Page]
       |
       v
[Scan heartbeat indicator] -- green? --> [Scan agent grid]
       |                                        |
       v (red/yellow)                          v
[Check Timeline for errors]           [Click busy agent card]
                                              |
                                              v
                                     [Agent Detail: see task + gates]
                                              |
                                              v
                                     [Back to Home or Kanban]
```

### Flow 2: Sprint Review (Lead)

```
[Open Dashboard] --> [Navigate to Burndown]
       |
       v
[Review burndown trajectory] --> [Navigate to Gates]
       |                                |
       v                                v
[Note velocity]                [Check gate pass rates]
       |                                |
       v                                v
[Navigate to Kanban]           [Navigate to ISO Docs]
       |                                |
       v                                v
[Review DONE column]           [Verify doc currency]
```

### Flow 3: First Impression (Evaluator)

```
[Open Dashboard] --> [Home Page (10 sec scan)]
       |
       v
[Navigate to Pixel Office]
       |
       v
[Watch agents work in animated office]
       |
       v
[Click agent sprites to learn roles]
       |
       v
[Click Mother Brain orb to see sprint health]
       |
       v
[Navigate to Kanban to see real project data]
```

---

## 3. Screen Inventory

### 3.1 Home Page

```
+------------------------------------------------------------------+
| [=] AEGIS Dashboard           [Sprint 1 v] [Theme] [Pixel Office]|
+--------+---------------------------------------------------------+
|        |                                                          |
| Home * | +--[Heartbeat]--+ +--------[Sprint Summary]----------+  |
| Kanban | | (O) ALIVE     | | Sprint 1: Fix the Foundation     |  |
| Burn   | | 2s ago        | | Mar 24 - Apr 04    70% [=======  ]|  |
| Time   | +---------------+ | 19/27 pts | 6/8 tasks done       |  |
| Agents |                    +-------------------------------------+  |
| Gates  |                                                          |
| Pixel  | +--[Quick Stats]------------------------------------+   |
| Specs  | | Tasks: 6 done / 8 total  | Velocity: -- (first)  |   |
| ISO    | | Points: 19 / 27          | Blocked: 0             |   |
| Ctx    | +-------------------------------------------------------+   |
|        |                                                          |
|        | +--[Agent Grid]-------------------------------------+   |
|        | | +----------+ +----------+ +----------+            |   |
|        | | |Mother    | |Navi      | |Sage      |            |   |
|        | | |Brain     | |  opus    | |  opus    |            |   |
|        | | |  ALIVE   | |  idle    | |  idle    |            |   |
|        | | +----------+ +----------+ +----------+            |   |
|        | | +----------+ +----------+ +----------+            |   |
|        | | |Bolt      | |Vigil     | |Havoc     |            |   |
|        | | |  sonnet  | |  sonnet  | |  opus    |            |   |
|        | | |  working | |  idle    | |  idle    |            |   |
|        | | |  T-011   | |          | |          |            |   |
|        | | +----------+ +----------+ +----------+            |   |
|        | | +----------+ +----------+ +----------+            |   |
|        | | |Forge     | |Pixel     | |Muse      |            |   |
|        | | |  haiku   | |  sonnet  | |  haiku   |            |   |
|        | | |  idle    | |  idle    | |  idle    |            |   |
|        | | +----------+ +----------+ +----------+            |   |
|        | | +----------+ +----------+ +----------+ +--------+ |   |
|        | | |Sentinel  | |Probe     | |Scribe    | |Ops     | |   |
|        | | |  sonnet  | |  haiku   | |  haiku   | | sonnet | |   |
|        | | |  idle    | |  idle    | |  idle    | | idle   | |   |
|        | | +----------+ +----------+ +----------+ +--------+ |   |
|        | +-------------------------------------------------------+   |
+--------+---------------------------------------------------------+
```

### 3.2 Kanban Board

```
+------------------------------------------------------------------+
| [=] AEGIS Dashboard > Kanban Board          [Sprint 1 v] [Theme] |
+--------+---------------------------------------------------------+
|        |                                                          |
| Nav    | TODO (1, 5p) | IN_PROG (1, 3p) | REVIEW (0) | DONE (6, 19p)|
|        | +---------+  | +----------+     |            | +----------+ |
|        | |T-003    |  | |T-011     |     |            | |T-001     | |
|        | |aegis-   |  | |append-   |     |            | |install   | |
|        | |doctor   |  | |only hist |     |            | |files fix | |
|        | |5p @bolt |  | |3p @bolt  |     |            | |3p @bolt  | |
|        | |HIGH     |  | |HIGH      |     |            | |CRITICAL  | |
|        | +---------+  | +----------+     |            | +----------+ |
|        |              |                  |            | |T-002     | |
|        |              |                  |            | |dirs fix  | |
|        |              |                  |            | |2p @bolt  | |
|        |              |                  |            | +----------+ |
|        |              |                  |            | |...4 more | |
+--------+---------------------------------------------------------+
```

### 3.3 Burndown Chart

```
+------------------------------------------------------------------+
| [=] AEGIS Dashboard > Burndown              [Sprint 1 v] [Theme] |
+--------+---------------------------------------------------------+
|        |                                                          |
| Nav    |  Points                                                  |
|        |  27 +--*                                                 |
|        |     |   \  Ideal                                        |
|        |  20 +    \ . . . . . . . . . .                          |
|        |     |     \                    .                         |
|        |  15 +      \                    .                        |
|        |     |       *--- Actual          .                       |
|        |  10 +        \    (8 remaining)   .                      |
|        |     |   TODAY |                    .                     |
|        |   5 +         v                     .                    |
|        |     |                                .                   |
|        |   0 +----+----+----+----+----+----+---*                 |
|        |     D1   D2   D3   D4   D5   D6   D7  D11              |
|        |                                                          |
|        |  Committed: 27 pts | Completed: 19 pts | Remaining: 8  |
+--------+---------------------------------------------------------+
```

### 3.4 Activity Timeline

```
+------------------------------------------------------------------+
| [=] AEGIS Dashboard > Timeline              [Filter: All v]      |
+--------+---------------------------------------------------------+
|        |                                                          |
| Nav    | 12:45 | PROGRESS | sprint-1 day 7 | 6 DONE (19pts/27pts|
|        |       |          | = 70%) | 1 IP (3pts) | 1 TODO (5pts)|
|        | ------+----------+--------------------------------------|
|        | 12:40 | TASK_DONE | PROJ-T-004 | Mother Brain planning- |
|        |       |           | before-build verified working       |
|        | ------+-----------+-------------------------------------|
|        | 12:30 | PROGRESS  | sprint-1 day 7 | 5 DONE (14pts)    |
|        | ------+-----------+-------------------------------------|
|        | 12:25 | TASK_WIP  | PROJ-T-011 | Needs write access    |
|        | ------+-----------+-------------------------------------|
|        | 12:20 | TASK_DONE | PROJ-T-013 | velocity computation  |
|        | ------+-----------+-------------------------------------|
|        | 12:20 | TASK_DONE | PROJ-T-007 | gate enforcement OK   |
|        | ------+-----------+-------------------------------------|
|        |              [ Load More ]                               |
+--------+---------------------------------------------------------+
```

### 3.5 Agent Detail

```
+------------------------------------------------------------------+
| [=] AEGIS Dashboard > Agents > Bolt                              |
+--------+---------------------------------------------------------+
|        |                                                          |
| Nav    | +--[Header]-------------------------------------------+ |
|        | | [Bolt sprite]  Bolt -- Implementer                  | |
|        | |                Model: sonnet | Status: working      | |
|        | |                Active: PROJ-T-011                   | |
|        | +-----------------------------------------------------+ |
|        |                                                          |
|        | +--[Assigned Tasks]-----------------------------------+ |
|        | | ID       | Title                     | Pts | Status | |
|        | |----------+---------------------------+-----+--------| |
|        | | T-001    | install.sh copies all     | 3   | DONE   | |
|        | | T-002    | install.sh creates dirs   | 2   | DONE   | |
|        | | T-003    | aegis-doctor              | 5   | TODO   | |
|        | | T-010    | Sequential IDs            | 3   | DONE   | |
|        | | T-011    | Append-only history       | 3   | IN_PROG| |
|        | +-----------------------------------------------------+ |
|        |                                                          |
|        | +--[Gate Results]-------------------------------------+ |
|        | | T-001: [G1 OK] [G2 --] [G3 --] [G4 --] [G5 --]    | |
|        | | T-002: [G1 OK] [G2 --] [G3 --] [G4 --] [G5 --]    | |
|        | | T-010: [G1 --] [G2 --] [G3 --] [G4 --] [G5 --]    | |
|        | +-----------------------------------------------------+ |
|        |                                                          |
|        | +--[Stats]-----------+                                  |
|        | | Tasks Done: 3      |                                  |
|        | | Points Done: 8     |                                  |
|        | +--------------------+                                  |
+--------+---------------------------------------------------------+
```

### 3.6 Five-Gate Quality Display

```
+------------------------------------------------------------------+
| [=] AEGIS Dashboard > Quality Gates                              |
+--------+---------------------------------------------------------+
|        |                                                          |
| Nav    | +--[Gate Pipeline Overview]---------------------------+ |
|        | |                                                      | |
|        | | Gate 1       Gate 2      Gate 3     Gate 4    Gate 5 | |
|        | | Code Rev     Tests       Integr    Security   Accept | |
|        | | [### 2/8]   [### 0/8]   [### 0/8] [### 0/8] [### 0/8]| |
|        | |                                                      | |
|        | +------------------------------------------------------+ |
|        |                                                          |
|        | +--[Per-Task Gate Status]------------------------------+ |
|        | | Task    | G1  | G2  | G3  | G4  | G5  | Status      | |
|        | |---------+-----+-----+-----+-----+-----+-------------| |
|        | | T-001   | (o) | ( ) | ( ) | ( ) | ( ) | DONE        | |
|        | | T-002   | (o) | ( ) | ( ) | ( ) | ( ) | DONE        | |
|        | | T-003   | ( ) | ( ) | ( ) | ( ) | ( ) | TODO        | |
|        | | T-007   | ( ) | ( ) | ( ) | ( ) | ( ) | DONE        | |
|        | | ...     |     |     |     |     |     |             | |
|        | +------------------------------------------------------+ |
|        |                                                          |
|        | Legend: (o) = PASS  (x) = FAIL  ( ) = PENDING           |
+--------+---------------------------------------------------------+
```

---

## 4. Pixel Office Design

### 4.1 Office Layout (Detail)

The Pixel Office is a top-down view of a virtual office rendered on an
HTML5 Canvas element. The canvas is 960x640 pixels (displayed at native
resolution on desktop, scaled down proportionally on smaller screens).

**Tile grid:** 60x40 tiles at 16x16 pixels each.

**Zones:**
```
+===============================================================+
||                    WALL (dark gray tiles)                    ||
||  +--[Kanban Board]--+  +--[Clock]--+  +--[AEGIS Shield]--+ ||
||  | TODO|WIP|DONE    |  | 12:45     |  |    /\             | ||
||  | ... |...|...     |  |           |  |   /  \            | ||
||  +------------------+  +-----------+  |  / A  \           | ||
||                                        +------------------+ ||
||=============================================================||
||                     FLOOR (warm wood tiles)                  ||
||                                                              ||
||  ROW 1: Strategy Team                                        ||
||  +------+  +------+  +------+  +------+  +------+          ||
||  |[Navi]|  |[Sage]|  |[Bolt]|  |[Vigl]|  |[Havc]|          ||
||  | desk |  | desk |  | desk |  | desk |  | desk |          ||
||  |chair |  |chair |  |chair |  |chair |  |chair |          ||
||  +------+  +------+  +------+  +------+  +------+          ||
||                                                              ||
||  ROW 2: Specialist Team                                      ||
||  +------+  +------+  +------+  +------+  +------+          ||
||  |[Forg]|  |[Pixl]|  |[Muse]|  |[Sent]|  |[Prob]|          ||
||  | desk |  | desk |  | desk |  | desk |  | desk |          ||
||  |chair |  |chair |  |chair |  |chair |  |chair |          ||
||  +------+  +------+  +------+  +------+  +------+          ||
||                                                              ||
||  ROW 3: Support + Command                                    ||
||  +------+  +------+        +========================+       ||
||  |[Scrb]|  |[Ops ]|        ||    MEETING ROOM       ||       ||
||  | desk |  | desk |        ||                       ||       ||
||  |chair |  |chair |        ||   +==============+    ||       ||
||  +------+  +------+        ||   ||MOTHER BRAIN||    ||       ||
||                             ||   ||  ( (O) )   ||    ||       ||
||  [Water Cooler] [Plant]     ||   ||  Pulsing   ||    ||       ||
||                             ||   ||   Orb      ||    ||       ||
||                             ||   +==============+    ||       ||
||                             ||                       ||       ||
||                             +========================+       ||
+===============================================================+
```

### 4.2 Agent Sprite Specifications

Each agent is a 16x16 pixel sprite with 4 animation states.
All sprites share a humanoid base but are distinguished by color and accessory.

| Agent | Primary Color | Accessory | Desk Item |
|-------|--------------|-----------|-----------|
| Mother Brain | Magenta (#FF00FF) | N/A (orb, not humanoid) | Central pedestal |
| Navi | Teal (#00CED1) | Compass pendant | Map on desk |
| Sage | Indigo (#4B0082) | Protractor/ruler | Blueprint scroll |
| Bolt | Electric Yellow (#FFD700) | Lightning bolt hair | Dual monitors |
| Vigil | Steel Blue (#4682B4) | Shield emblem on chest | Checklist clipboard |
| Havoc | Crimson (#DC143C) | Horns headband | Red pen collection |
| Forge | Copper (#B87333) | Wrench in hand | Toolbox |
| Pixel | Lavender (#E6E6FA) | Paint brush behind ear | Drawing tablet |
| Muse | Rose Gold (#B76E79) | Beret | Notebook stack |
| Sentinel | Hunter Green (#355E3B) | Crosshair monocle | Test dashboard |
| Probe | Amber (#FFBF00) | Magnifying glass | Microscope |
| Scribe | Parchment (#F5DEB3) | Quill pen | Scroll pile |
| Ops | Gunmetal (#2C3539) | Rocket pin | Server rack model |

### 4.3 Animation Frames

**Sprite sheet layout:** 13 agents x 4 states x max 6 frames = 312 cells.
Sheet dimensions: 16 columns x 20 rows at 16x16 = 256x320 pixel atlas.

| State | Frames | Speed | Loop |
|-------|--------|-------|------|
| idle | 2 | 500ms/frame | infinite |
| working | 4 | 200ms/frame | infinite |
| waiting | 2 | 800ms/frame | infinite |
| done | 6 | 150ms/frame | play once, then idle |

**Idle animation:** Slight up-down bob (1px shift on frame 2).
**Working animation:** Arms alternate position, screen flickers.
**Waiting animation:** Weight shift side to side.
**Done animation:** Jump up 3px, arms raise, sparkle particles (frames 3-6).

### 4.4 Mother Brain Orb

The Mother Brain is not a humanoid sprite but a floating orb in the
meeting room center.

**Visual:**
- Base: 32x32 pixel circle (rendered at 3x = 96x96 display)
- Color gradient: dark magenta core to bright magenta edge
- Pulse animation: scale oscillates between 0.95x and 1.05x
- Pulse rate: matches heartbeat (every 2 seconds when healthy)
- Particle ring: 8 small dots orbiting the orb

**Health states:**
- Healthy: bright magenta, smooth pulse, full particle ring
- Stale (>10s): dim yellow, slow pulse, 4 particles
- Dead (>60s): dark red, no pulse, no particles, static
- Unknown: gray, no animation

### 4.5 Office Furniture and Props

All rendered as 16x16 tile sprites:

| Prop | Tiles | Description |
|------|-------|-------------|
| Desk | 2x1 | Wood colored, monitor on left half |
| Chair | 1x1 | Swivel chair, matches agent color hint |
| Kanban Board | 3x2 | Wall-mounted, shows miniature cards (colored dots) |
| Clock | 1x1 | Shows current hour (updates every minute) |
| AEGIS Shield | 2x2 | Logo on wall, subtle glow animation |
| Water Cooler | 1x1 | Bubble animation (every 5 seconds) |
| Plant | 1x1 | Gentle sway (2-frame, 1s interval) |
| Server Rack | 1x2 | Blinking LED lights near Ops desk |
| Meeting Table | 3x2 | In meeting room around Mother Brain |

### 4.6 Pixel Office Interactions

**Hover (desktop only):**
- Hovering over an agent sprite shows a floating name tag above the sprite
- Name tag: dark background, white text, agent emoji prefix

**Click:**
- Clicking an agent sprite opens a popup card anchored to the sprite position
- Card contents: name, role, current task (if any), status badge
- Card has a "View Details" link to the Agent Detail page
- Clicking elsewhere dismisses the card

**Click Mother Brain Orb:**
- Opens a larger popup with heartbeat status, sprint name, and progress bar
- "View Dashboard" link to Home page

**Ambient animations (not tied to agent state):**
- Kanban board cards shift occasionally (every 30s, random card moves column)
- Clock updates on the minute
- Water cooler bubbles every 5 seconds
- Plants sway continuously

---

## 5. Responsive Strategy

### 5.1 Breakpoints

| Breakpoint | Layout | Pixel Office |
|------------|--------|--------------|
| >= 1280px (Desktop) | Sidebar (240px) + Main Content | Full 960x640 canvas |
| 768-1279px (Tablet) | Collapsed sidebar (icons) + Main Content | Scaled canvas (fit width) |
| < 768px (Mobile) | Bottom tab bar + Full-width content | Pixel Office hidden; link to full-screen overlay |

### 5.2 Pixel Office Scaling

The canvas is always 960x640 logical pixels. On smaller screens:
- CSS scales the canvas element to fit container width
- `image-rendering: pixelated` preserves crisp pixel art
- Interaction hit areas scale proportionally

### 5.3 Dashboard Widgets

On tablet, dashboard home switches from 3-column grid to 2-column.
Agent grid switches from 4-per-row to 3-per-row.
Kanban columns scroll horizontally on tablet.

---

## 6. Theme Design

### 6.1 Dark Theme (Default)

| Token | Value | Usage |
|-------|-------|-------|
| bg-primary | #0F1117 | Page background |
| bg-surface | #1A1D27 | Card background |
| bg-elevated | #252833 | Sidebar, modals |
| text-primary | #E8E9ED | Body text |
| text-secondary | #8B8FA3 | Muted text |
| accent | #6C5CE7 | Active nav, links |
| success | #00D68F | Heartbeat alive, gates passed |
| warning | #FFAA00 | Stale heartbeat, medium priority |
| danger | #FF3D71 | Dead heartbeat, critical, gate fail |
| border | #2E3140 | Dividers |

### 6.2 Light Theme

| Token | Value | Usage |
|-------|-------|-------|
| bg-primary | #F7F8FA | Page background |
| bg-surface | #FFFFFF | Card background |
| bg-elevated | #F0F1F5 | Sidebar, modals |
| text-primary | #1A1D27 | Body text |
| text-secondary | #6B7085 | Muted text |
| accent | #6C5CE7 | Active nav, links |
| success | #00B87C | Heartbeat alive |
| warning | #E59400 | Stale heartbeat |
| danger | #E53E3E | Dead heartbeat |
| border | #E2E4EA | Dividers |

### 6.3 Pixel Office Theme

The Pixel Office canvas does not switch themes. It uses its own retro palette
inspired by classic SNES/GBA color limitations:
- Floor: warm browns (#8B6914, #A0792C)
- Walls: cool grays (#4A4A5A, #6A6A7A)
- Furniture: wood tones (#6B4226, #8B5E3C)
- Ambient light: warm yellow tint overlay on working agents

---

## 7. Accessibility

### 7.1 Canvas Accessibility

The Pixel Office canvas is purely visual. To ensure accessibility:
- A hidden `<table>` element mirrors the canvas content with agent names,
  statuses, and current tasks for screen readers
- The table is visually hidden but accessible via `aria-label`
- Keyboard users can Tab through agents in the hidden table; pressing
  Enter opens the same popup card as clicking the sprite

### 7.2 Dashboard Accessibility

- All interactive elements are focusable and keyboard-navigable
- Color is never the sole indicator (icons/text accompany status colors)
- Heartbeat status has text label alongside the colored dot
- Gate circles have aria-label: "Gate 1 Code Review: PASS"
- Timeline entries have semantic time elements
- Chart has a data table alternative (toggle button)

---

## 8. Implementation Phases

This section is a recommendation for Bolt's implementation order.

| Phase | Scope | Estimated Effort |
|-------|-------|-----------------|
| Phase 1 | Project scaffold, API routes, data models, path security | 1 session |
| Phase 2 | Dashboard Home, Agent Grid, Heartbeat, Sprint Summary | 1 session |
| Phase 3 | Kanban Board, Burndown Chart, Activity Timeline | 1 session |
| Phase 4 | Agent Detail, Gates Display, Sprint Selector | 1 session |
| Phase 5 | Pixel Office canvas engine, sprite rendering, state machine | 2 sessions |
| Phase 6 | Spec Viewer, ISO Viewer, Context Budget | 1 session |
| Phase 7 | Theme toggle, responsive layout, accessibility | 1 session |
| Phase 8 | Docker + Vercel deployment configs, testing | 1 session |

Total estimated: 9 sessions (each session is approximately 1 hour of
concentrated Bolt implementation time).
