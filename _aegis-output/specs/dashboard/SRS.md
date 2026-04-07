# SRS -- AEGIS Web Dashboard + Pixel Office

> Document: SRS-DASH-001 | Version: 1.0 | Author: Sage | Date: 2026-03-30
> Status: DRAFT -- Pending Vigil/Havoc review

---

## 1. System Overview

The AEGIS Dashboard is a Next.js 15 web application that reads the file-based
state of an AEGIS agent team and presents it through two complementary views:
a structured Dashboard for operational data, and a Pixel Office for animated
visualization of agent activity.

### 1.1 Architecture Diagram

```
+------------------------------------------------------------------+
|                        BROWSER (React 19)                        |
|                                                                  |
|  +---------------------------+  +-----------------------------+  |
|  |      Dashboard Views      |  |      Pixel Office View      |  |
|  |  +-----+ +-----+ +-----+ |  |  +------------------------+ |  |
|  |  |Home | |Kanbn| |Burn | |  |  |   HTML5 Canvas Engine   | |  |
|  |  +-----+ +-----+ +-----+ |  |  |  13 Agent Sprites       | |  |
|  |  +-----+ +-----+ +-----+ |  |  |  Office Environment     | |  |
|  |  |Time | |Agent| |Gates| |  |  |  Click Interaction       | |  |
|  |  +-----+ +-----+ +-----+ |  |  +------------------------+ |  |
|  |  +-----+ +-----+ +-----+ |  |                             |  |
|  |  |Specs| | ISO | | Ctx | |  |                             |  |
|  |  +-----+ +-----+ +-----+ |  |                             |  |
|  +---------------------------+  +-----------------------------+  |
|                          |                                       |
|                    React Hooks (SWR)                             |
|                    Polling: 2s heartbeat, 5s data                |
+------------------------------------------------------------------+
                           |
                    HTTP (same-origin)
                           |
+------------------------------------------------------------------+
|                   NEXT.JS 15 SERVER (App Router)                 |
|                                                                  |
|  /api/heartbeat    GET  -> reads heartbeat.log (last line)       |
|  /api/agents       GET  -> reads tasks/*/meta.json, aggregates   |
|  /api/kanban       GET  -> reads sprints/current/kanban.md       |
|  /api/metrics      GET  -> reads sprints/current/metrics.json    |
|  /api/activity     GET  -> reads logs/activity.log (tail 100)    |
|  /api/tasks/[id]   GET  -> reads tasks/[id]/meta.json + history  |
|  /api/gates        GET  -> aggregates gate_results from all tasks|
|  /api/specs        GET  -> lists _aegis-output/specs/**          |
|  /api/specs/[...f] GET  -> reads specific spec file              |
|  /api/iso          GET  -> reads _aegis-output/iso-docs/**       |
|  /api/context      GET  -> estimates context budget from metrics  |
|  /api/resonance    GET  -> reads resonance/*.md files            |
|  /api/counters     GET  -> reads counters.json                   |
+------------------------------------------------------------------+
                           |
                    fs.readFile (Node.js)
                           |
+------------------------------------------------------------------+
|                    FILESYSTEM (read-only)                         |
|                                                                  |
|  _aegis-brain/                                                   |
|    +-- counters.json                                             |
|    +-- logs/activity.log                                         |
|    +-- sprints/sprint-N/kanban.md                                |
|    +-- sprints/sprint-N/metrics.json                             |
|    +-- tasks/PROJ-*/meta.json                                    |
|    +-- tasks/PROJ-*/history.md                                   |
|    +-- metrics/benchmarks.json                                   |
|    +-- metrics/token-usage.json                                  |
|    +-- resonance/*.md                                            |
|    +-- skill-cache/stats.json                                    |
|                                                                  |
|  _aegis-output/                                                  |
|    +-- specs/**                                                  |
|    +-- iso-docs/**                                               |
|    +-- architecture/**                                           |
+------------------------------------------------------------------+
```

### 1.2 Technology Stack

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| Framework | Next.js 15 (App Router) | File-based routing, API routes, SSR capability, Vercel-native |
| UI Library | React 19 | Latest concurrent features, use() hook for data |
| Styling | Tailwind CSS v4 | Utility-first, rapid prototyping, dark mode built-in |
| Canvas | HTML5 Canvas API | No dependency needed; full control over pixel rendering |
| Data Fetching | SWR | Stale-while-revalidate polling with configurable intervals |
| Markdown Parsing | remark + rehype | Parse kanban.md and spec files for display |
| Charts | Lightweight custom SVG | Avoid heavy charting library; burndown is a simple line chart |
| Deployment | Docker + Vercel | Docker for self-hosted; Vercel for zero-config cloud |

Trade-off notes:
- SWR over TanStack Query: SWR is lighter, polling is the primary pattern, no mutations needed.
- Custom SVG over Chart.js/Recharts: The only chart is a burndown line; a 50KB library is not justified.
- Canvas over DOM sprites: 13 animated sprites with smooth movement is more performant on Canvas than on absolutely positioned DOM elements.

---

## 2. Functional Requirements

### FR-001: Dashboard Home

**Description:** Landing page showing system health at a glance.

**Elements:**
- Mother Brain heartbeat indicator (pulsing dot: green=alive, yellow=stale >10s, red=dead >60s)
- Last heartbeat timestamp
- Sprint summary card (name, goal, dates, progress bar)
- Agent grid: 13 cards showing name, emoji, model tier, current status
- Quick stats: tasks done/total, points burned/committed, velocity

**Data Sources:** `/api/heartbeat`, `/api/metrics`, `/api/agents`

---

### FR-002: Agent Cards

**Description:** Each agent is represented by a card on the home page.

**Fields per card:**
- Emoji + Name (e.g., "Sage")
- Model tier badge (opus/sonnet/haiku)
- Current status: idle | working | reviewing | blocked
- Active task ID and title (if any)
- Last action timestamp

**Interaction:** Click card to navigate to Agent Detail (FR-006).

**Data Source:** `/api/agents` (aggregated from task meta.json files)

---

### FR-003: Kanban Board View

**Description:** Visual kanban board reflecting `sprints/sprint-N/kanban.md`.

**Columns:** TODO | IN_PROGRESS | IN_REVIEW | QA | DONE | BLOCKED

**Card fields:** Task ID, title, points badge, assignee avatar (emoji), priority indicator.

**Behavior:**
- Cards are read-only (no drag-and-drop in v1)
- Column headers show task count and point sum
- Color-coded priority: critical=red, high=orange, medium=blue, low=gray

**Data Source:** `/api/kanban`

---

### FR-004: Burndown Chart

**Description:** Line chart showing sprint burndown over time.

**Axes:**
- X: Sprint days (day 1 through planned end)
- Y: Remaining story points

**Lines:**
- Ideal burndown (straight diagonal from committed_pts to 0)
- Actual burndown (from daily_burndown array in metrics.json)

**Annotations:** Today marker, capacity line.

**Data Source:** `/api/metrics`

---

### FR-005: Activity Timeline

**Description:** Scrollable feed of recent AEGIS activity.

**Entry format:** Timestamp | Agent emoji | Event type badge | Message

**Event types and colors:**
- SESSION_START (blue), TASK_DONE (green), GATE_PASS (emerald),
  GATE_FAIL (red), DECISION (purple), PROGRESS (gray),
  SPEC_WRITTEN (cyan), TASK_WIP (yellow), BREAKDOWN (indigo)

**Behavior:**
- Shows last 100 entries (configurable)
- Auto-scrolls to newest entry
- Click entry to filter by agent

**Data Source:** `/api/activity`

---

### FR-006: Agent Detail View

**Description:** Detailed view for a single agent.

**Sections:**
- Header: emoji, name, role description, model tier
- Assigned Tasks: table of tasks where assignee matches this agent
- Task History: timeline of status changes for assigned tasks
- Gate Results: pass/fail badges for each gate on each task
- Performance: points completed, tasks done count

**Data Sources:** `/api/agents`, `/api/tasks/[id]`

---

### FR-007: Five-Gate Quality Display

**Description:** Visual display of the 5-gate quality pipeline.

**Gates:**
1. Code Review (gate1_code_review)
2. Test Pass (gate2_test)
3. Integration (gate3_integration)
4. Security Scan (gate4_security)
5. Acceptance (gate5_acceptance)

**Per-task display:** Row of 5 circles -- green (PASS), red (FAIL), gray (PENDING).

**Aggregate display:** Summary bar showing how many tasks have passed each gate.

**Data Source:** `/api/gates`

---

### FR-008: Pixel Office

**Description:** Animated pixel-art office viewed through HTML5 Canvas.

**Office layout (top-down isometric):**
```
+-------------------------------------------------------+
|  [Kanban Board on Wall]        [Clock]    [AEGIS Logo] |
|                                                         |
|  +------+  +------+  +------+  +------+  +------+     |
|  |Navi  |  |Sage  |  |Bolt  |  |Vigil |  |Havoc |     |
|  | desk |  | desk |  | desk |  | desk |  | desk |     |
|  +------+  +------+  +------+  +------+  +------+     |
|                                                         |
|  +------+  +------+  +------+  +------+  +------+     |
|  |Forge |  |Pixel |  |Muse  |  |Sntnel|  |Probe |     |
|  | desk |  | desk |  | desk |  | desk |  | desk |     |
|  +------+  +------+  +------+  +------+  +------+     |
|                                                         |
|  +------+  +------+         +------------------+       |
|  |Scribe|  | Ops  |        |  Meeting Room     |       |
|  | desk |  | desk |        |  (Mother Brain    |       |
|  +------+  +------+        |   Central Orb)    |       |
|                              +------------------+       |
+-------------------------------------------------------+
```

**Agent sprites:** 16x16 pixel base, rendered at 3x scale (48x48 display).

**Animation states:**
- idle: sitting at desk, slight breathing animation (2-frame loop)
- working: sitting at desk, hands moving on keyboard (4-frame loop)
- waiting: standing beside desk (2-frame loop)
- done: brief celebration animation, then returns to idle (6-frame, plays once)

**Mother Brain:** Central pulsing orb in the meeting room. Pulse rate matches
heartbeat frequency. Color: green=alive, red=dead. Radiating particle effect.

**Interactions:**
- Hover agent sprite: name tooltip appears
- Click agent sprite: popup card with current task, status, last action
- Click Mother Brain orb: show heartbeat details and sprint summary

**Rendering:** RequestAnimationFrame loop at 30 FPS target. Sprite sheet
atlas loaded once, frames selected by state and timer.

**Data Source:** Same `/api/agents` and `/api/heartbeat` endpoints, polled
and mapped to animation states via a state machine:
- Agent has task with status IN_PROGRESS -> "working"
- Agent has task with status TODO -> "waiting"
- Agent has no active tasks -> "idle"
- Agent's task just moved to DONE (within last 30s) -> "done"

---

### FR-009: Spec Viewer

**Description:** Browse and read spec files from `_aegis-output/specs/`.

**Behavior:**
- File tree sidebar listing all specs
- Click file to render Markdown in a reading pane
- Syntax highlighting for code blocks within specs

**Data Source:** `/api/specs`, `/api/specs/[...filepath]`

---

### FR-010: Context Budget Display

**Description:** Show estimated context window usage.

**Elements:**
- Circular progress indicator (used / total)
- Breakdown by category: skills loaded, brain files, conversation
- Warning threshold indicators (yellow at 60%, red at 80%)

**Data Source:** `/api/context` (derived from `metrics/token-usage.json` and
`skill-cache/stats.json`)

---

### FR-011: ISO Compliance Viewer

**Description:** Display ISO 29110 compliance documents.

**Elements:**
- Document list grouped by category (PM-01 through PM-04, SI-01 through SI-07)
- Status badge per document (current version number)
- Click to read full document content
- Changelog tab per document

**Data Source:** `/api/iso`

---

### FR-012: Theme Toggle

**Description:** Switch between dark and light themes.

**Behavior:**
- Default: dark theme (matches terminal-centric developer audience)
- Toggle persisted to localStorage
- Tailwind dark mode class strategy

---

### FR-013: Navigation

**Description:** Primary navigation structure.

**Layout:**
- Sidebar on desktop (collapsible)
- Bottom tab bar on tablet
- Nav items: Home, Kanban, Burndown, Timeline, Agents, Gates, Pixel Office, Specs, ISO, Context

---

### FR-014: Sprint Selector

**Description:** Select which sprint to view.

**Behavior:**
- Dropdown showing available sprints (derived from `sprints/` subdirectories)
- Defaults to latest sprint
- Changing sprint reloads all sprint-scoped data

**Data Source:** Filesystem scan of `_aegis-brain/sprints/`

---

### FR-015: Responsive Layout

**Description:** Adaptive layout for different screen sizes.

**Breakpoints:**
- Desktop (1280px+): full sidebar + main content + optional Pixel Office panel
- Tablet (768px-1279px): collapsed sidebar + main content
- Below 768px: not a priority target but must not break

---

## 3. Non-Functional Requirements

### NFR-001: Performance
- First Contentful Paint: under 1.5 seconds on localhost
- Heartbeat polling: 2-second interval, response under 100ms
- Data polling: 5-second interval for non-heartbeat data
- Pixel Office: stable 30 FPS with all 13 sprites animating
- API route response time: under 200ms for any single endpoint

### NFR-002: Security
- All data access is read-only; no fs.writeFile, fs.unlink, or fs.mkdir calls
- API routes must validate and sanitize path parameters to prevent directory traversal
- Path parameters must be restricted to `_aegis-brain/` and `_aegis-output/` only
- No user authentication required (single-user local tool)
- Content-Security-Policy headers to prevent XSS

### NFR-003: Reliability
- Graceful degradation when `_aegis-brain/` is missing or empty
- Each widget shows a clear "no data" state rather than crashing
- Heartbeat indicator must show "unknown" if heartbeat.log does not exist
- API routes return structured error responses with appropriate HTTP codes

### NFR-004: Accessibility
- Semantic HTML for all dashboard views
- ARIA labels on interactive canvas elements (Pixel Office)
- Keyboard navigation for all dashboard views
- Sufficient color contrast in both themes (WCAG 2.1 AA)
- Screen reader alternative text for the Pixel Office (agent status table)

### NFR-005: Maintainability
- Component-per-feature directory structure
- TypeScript strict mode throughout
- Data models defined as shared TypeScript interfaces
- API response shapes validated with Zod schemas

---

## 4. Data Models

### 4.1 TaskMeta (from tasks/PROJ-*/meta.json)

```typescript
interface TaskMeta {
  id: string;                    // "PROJ-T-001"
  title: string;
  type: "task" | "epic" | "story" | "journey";
  task_type?: "impl" | "review" | "spec" | "test";
  parent?: string;               // parent task ID
  children: string[];
  status: "TODO" | "IN_PROGRESS" | "IN_REVIEW" | "QA" | "DONE" | "BLOCKED";
  assignee: string;              // agent name lowercase
  points: number;
  priority: "critical" | "high" | "medium" | "low";
  labels: string[];
  dependencies: {
    blocks: string[];
    blocked_by: string[];
  };
  created: string;               // ISO 8601
  updated: string;               // ISO 8601
  sprint: string;
  time_tracking: {
    estimated_hours: number;
    logged_hours: number;
  };
  gate_results: {
    gate1_code_review?: "PASS" | "FAIL";
    gate1_date?: string;
    gate2_test?: "PASS" | "FAIL";
    gate2_date?: string;
    gate3_integration?: "PASS" | "FAIL";
    gate3_date?: string;
    gate4_security?: "PASS" | "FAIL";
    gate4_date?: string;
    gate5_acceptance?: "PASS" | "FAIL";
    gate5_date?: string;
  };
}
```

### 4.2 SprintMetrics (from sprints/sprint-N/metrics.json)

```typescript
interface SprintMetrics {
  sprint: string;
  started: string;               // "2026-03-24"
  planned_end: string;
  actual_end: string | null;
  goal: string;
  capacity_pts: number;
  committed_pts: number;
  completed_pts: number;
  daily_burndown: Array<{
    date: string;
    day: number;
    remaining: number;
    completed: number;
  }>;
  velocity_history: Array<{
    sprint: string;
    velocity: number;
  }>;
  tasks: {
    TODO: number;
    IN_PROGRESS: number;
    IN_REVIEW: number;
    QA: number;
    DONE: number;
    BLOCKED: number;
  };
  carry_over: {
    count: number;
    points: number;
    task_ids: string[];
  };
}
```

### 4.3 Counters (from counters.json)

```typescript
interface Counters {
  project_key: string;
  counters: Record<string, number>;
  last_updated: string;
}
```

### 4.4 ActivityLogEntry (parsed from logs/activity.log)

```typescript
interface ActivityLogEntry {
  timestamp: string;
  agent_emoji?: string;
  event_type: string;            // SESSION_START, TASK_DONE, etc.
  message: string;
  raw: string;                   // original log line
}
```

### 4.5 AgentState (derived, not stored)

```typescript
interface AgentState {
  name: string;
  emoji: string;
  model: "opus" | "sonnet" | "haiku";
  role: string;
  status: "idle" | "working" | "waiting" | "done" | "blocked";
  active_task?: {
    id: string;
    title: string;
    status: string;
  };
  tasks_completed: number;
  points_completed: number;
  last_action?: string;          // ISO 8601
}
```

### 4.6 HeartbeatStatus (derived from heartbeat.log)

```typescript
interface HeartbeatStatus {
  alive: boolean;
  last_beat: string | null;      // ISO 8601
  age_seconds: number;
  health: "healthy" | "stale" | "dead" | "unknown";
}
```

### 4.7 SkillCacheStats (from skill-cache/stats.json)

```typescript
interface SkillCacheStats {
  total_patterns: number;
  high_confidence: number;
  medium_confidence: number;
  low_confidence: number;
  cache_hits: number;
  cache_misses: number;
  last_updated: string;
}
```

---

## 5. API Specifications

All routes are under `/api/`. All responses follow this envelope:

```typescript
interface ApiResponse<T> {
  ok: boolean;
  data: T;
  error?: string;
  timestamp: string;             // server time of response
}
```

### 5.1 Route Table

| Method | Path | Response Type | Poll Interval | Description |
|--------|------|--------------|---------------|-------------|
| GET | /api/heartbeat | HeartbeatStatus | 2s | Mother Brain heartbeat |
| GET | /api/agents | AgentState[] | 5s | All 13 agents with derived status |
| GET | /api/agents/[name] | AgentState | 5s | Single agent detail |
| GET | /api/kanban | KanbanBoard | 5s | Parsed kanban.md as structured data |
| GET | /api/metrics | SprintMetrics | 10s | Sprint metrics and burndown |
| GET | /api/activity | ActivityLogEntry[] | 5s | Last 100 activity log lines |
| GET | /api/activity?agent=bolt | ActivityLogEntry[] | 5s | Filtered by agent |
| GET | /api/tasks/[id] | TaskDetail | 5s | Full task with meta + history + comments |
| GET | /api/gates | GateSummary | 10s | Aggregated gate status across all tasks |
| GET | /api/specs | FileTree | 30s | Directory listing of specs |
| GET | /api/specs/[...filepath] | FileContent | on-demand | Single spec file content |
| GET | /api/iso | IsoDocList | 30s | ISO document listing with versions |
| GET | /api/iso/[docId] | FileContent | on-demand | Single ISO document content |
| GET | /api/context | ContextBudget | 10s | Estimated context usage |
| GET | /api/counters | Counters | 30s | Project counters |
| GET | /api/sprints | SprintList | 30s | Available sprints |
| GET | /api/resonance | ResonanceData | 30s | Team patterns and conventions |

### 5.2 Path Security

Every API route that accepts a path parameter MUST:
1. Resolve the path to an absolute path
2. Verify the resolved path starts with the project root
3. Verify the resolved path is within `_aegis-brain/` or `_aegis-output/`
4. Reject paths containing `..` segments
5. Return 403 for any path outside the allowed directories

### 5.3 Error Responses

| HTTP Code | Condition |
|-----------|-----------|
| 200 | Success |
| 404 | File or resource not found |
| 403 | Path traversal attempt or access outside allowed dirs |
| 500 | Filesystem read error |

---

## 6. Project Structure

```
aegis-dashboard/
  +-- package.json
  +-- next.config.ts
  +-- tailwind.config.ts
  +-- tsconfig.json
  +-- Dockerfile
  +-- docker-compose.yml
  +-- public/
  |   +-- sprites/
  |       +-- spritesheet.png      (all agents, all frames)
  |       +-- spritesheet.json     (frame coordinates)
  |       +-- office-tiles.png     (desk, floor, wall tiles)
  +-- src/
      +-- app/
      |   +-- layout.tsx           (root layout with sidebar nav)
      |   +-- page.tsx             (dashboard home)
      |   +-- kanban/page.tsx
      |   +-- burndown/page.tsx
      |   +-- timeline/page.tsx
      |   +-- agents/page.tsx
      |   +-- agents/[name]/page.tsx
      |   +-- gates/page.tsx
      |   +-- pixel-office/page.tsx
      |   +-- specs/page.tsx
      |   +-- specs/[...filepath]/page.tsx
      |   +-- iso/page.tsx
      |   +-- context/page.tsx
      |   +-- api/                 (all API routes)
      +-- components/
      |   +-- layout/
      |   |   +-- Sidebar.tsx
      |   |   +-- ThemeToggle.tsx
      |   |   +-- Header.tsx
      |   +-- dashboard/
      |   |   +-- HeartbeatIndicator.tsx
      |   |   +-- SprintSummaryCard.tsx
      |   |   +-- AgentCard.tsx
      |   |   +-- AgentGrid.tsx
      |   |   +-- QuickStats.tsx
      |   +-- kanban/
      |   |   +-- KanbanBoard.tsx
      |   |   +-- KanbanColumn.tsx
      |   |   +-- KanbanCard.tsx
      |   +-- charts/
      |   |   +-- BurndownChart.tsx
      |   +-- timeline/
      |   |   +-- ActivityFeed.tsx
      |   |   +-- ActivityEntry.tsx
      |   +-- gates/
      |   |   +-- GatePipeline.tsx
      |   |   +-- GateCircle.tsx
      |   +-- pixel-office/
      |   |   +-- PixelOfficeCanvas.tsx
      |   |   +-- SpriteEngine.ts
      |   |   +-- OfficeLayout.ts
      |   |   +-- AgentSprite.ts
      |   |   +-- MotherBrainOrb.ts
      |   |   +-- SpriteSheet.ts
      |   |   +-- AnimationStateMachine.ts
      |   +-- specs/
      |   |   +-- FileTree.tsx
      |   |   +-- MarkdownRenderer.tsx
      |   +-- iso/
      |   |   +-- IsoDocList.tsx
      |   +-- context/
      |       +-- ContextGauge.tsx
      +-- hooks/
      |   +-- useHeartbeat.ts      (SWR, 2s interval)
      |   +-- useAgents.ts         (SWR, 5s interval)
      |   +-- useMetrics.ts        (SWR, 10s interval)
      |   +-- useActivity.ts       (SWR, 5s interval)
      |   +-- useTheme.ts
      +-- lib/
      |   +-- api-client.ts        (fetch wrappers)
      |   +-- parsers.ts           (log line parser, kanban parser)
      |   +-- constants.ts         (agent registry, colors, paths)
      |   +-- schemas.ts           (Zod validation schemas)
      |   +-- path-guard.ts        (security: path validation)
      +-- types/
          +-- index.ts             (all TypeScript interfaces)
```

---

## 7. Deployment

### 7.1 Local Development

```bash
cd aegis-dashboard
npm install
npm run dev
# Dashboard available at http://localhost:3000
```

Environment variable: `AEGIS_ROOT` points to the AEGIS project root
(defaults to `..` relative to the dashboard directory).

### 7.2 Docker

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --production
COPY . .
RUN npm run build
EXPOSE 3000
CMD ["npm", "start"]
```

```yaml
# docker-compose.yml
services:
  dashboard:
    build: .
    ports:
      - "3000:3000"
    volumes:
      - ../_aegis-brain:/data/_aegis-brain:ro
      - ../_aegis-output:/data/_aegis-output:ro
    environment:
      - AEGIS_ROOT=/data
```

Note: The `:ro` flag ensures the container cannot write to AEGIS state files.

### 7.3 Vercel

For remote deployment, the dashboard requires a snapshot mechanism since
Vercel functions cannot read the local filesystem. Options:
- (a) Git-committed `_aegis-brain/` data (works for demo/public instances)
- (b) External API proxy that serves `_aegis-brain/` files from a host machine
- Vercel deployment is best suited for demo purposes; production use targets
  localhost or Docker.
