# BRD -- AEGIS Web Dashboard + Pixel Office

> Document: BRD-DASH-001 | Version: 1.0 | Author: Sage | Date: 2026-03-30
> Status: DRAFT -- Pending Vigil/Havoc review

---

## 1. Executive Summary

AEGIS v8.3 is an AI agent team framework where 13 agents collaborate through
file-based state in `_aegis-brain/`. Today, the only way to observe agent
activity is by reading raw Markdown and JSON files or tailing log output in
a terminal. This proposal introduces a web-based dashboard with an integrated
Pixel Office -- a real-time, animated visualization of the agent team working
in a virtual office environment.

The dashboard provides operational observability. The Pixel Office provides
intuitive engagement. Together they make AEGIS legible to developers who do
not want to parse raw files, and memorable to anyone evaluating the framework.

---

## 2. Business Objectives

| ID | Objective | Measure |
|----|-----------|---------|
| BO-1 | Observability | Users can assess full sprint/agent status within 10 seconds of opening the dashboard |
| BO-2 | Engagement | The Pixel Office creates a shareable, visually distinctive identity for AEGIS |
| BO-3 | Adoption | Lower the barrier to understanding AEGIS by replacing file-reading with a GUI |
| BO-4 | Trust | Real-time heartbeat display proves Mother Brain is alive and working |
| BO-5 | Compliance Visibility | ISO 29110 document status is surfaced without navigating the filesystem |

---

## 3. Stakeholders

| Stakeholder | Interest | Impact |
|-------------|----------|--------|
| AEGIS End Users | Monitor agent team progress without terminal access | Primary |
| Team Leads / PMs | Sprint burndown, velocity, gate status at a glance | Primary |
| Developers | Debug agent behavior, review specs and architecture docs | Primary |
| Framework Evaluators | Understand AEGIS capabilities quickly via Pixel Office demo | Secondary |
| Open Source Contributors | Onboard faster with visual project state | Secondary |

---

## 4. Scope

### 4.1 In Scope

- Real-time dashboard reading `_aegis-brain/` via Next.js API routes
- Pixel Office with 13 animated agent sprites on HTML5 Canvas
- Sprint kanban view, burndown chart, activity timeline
- Agent detail panels with task assignment and gate status
- Mother Brain heartbeat indicator (2-second polling)
- Spec viewer for `_aegis-output/specs/`
- ISO compliance document viewer for `_aegis-output/iso-docs/`
- Context budget estimation display
- Dark and light theme support
- Deployment via localhost, Docker, and Vercel

### 4.2 Out of Scope

- Write operations (the dashboard is strictly read-only)
- User authentication or multi-user access control
- Database layer (all data comes from filesystem)
- Mobile-native application
- Real-time WebSocket (polling is sufficient for v1)
- Agent command execution from the dashboard
- Chat interface with agents
- Historical data beyond current sprint (v1 only shows active sprint)

---

## 5. Success Criteria

| ID | Criterion | Threshold |
|----|-----------|-----------|
| SC-1 | Time to first meaningful paint | Less than 2 seconds on localhost |
| SC-2 | Heartbeat freshness | Dashboard reflects Mother Brain state within 4 seconds of change |
| SC-3 | Pixel Office frame rate | Stable 30+ FPS with 13 sprites on a 2020-era laptop |
| SC-4 | Zero write side effects | Dashboard never creates, modifies, or deletes any file in _aegis-brain/ |
| SC-5 | One-command startup | `npm run dev` or `docker compose up` with zero configuration |
| SC-6 | Data accuracy | Dashboard state matches raw file content with no stale data older than 5 seconds |

---

## 6. Assumptions and Constraints

### Assumptions
- `_aegis-brain/` directory exists and follows the documented schema
- Mother Brain writes `heartbeat.log` at regular intervals when active
- The host machine has Node.js 20+ available for local development
- File sizes in `_aegis-brain/` remain small (under 1MB per file)

### Constraints
- Read-only access: no mutations to the AEGIS state
- Must not require any database installation
- Must work as a standalone Next.js app inside the AEGIS project directory
- Pixel art sprites must be original (no copyrighted assets)
- Total bundle size target: under 500KB gzipped (excluding sprite sheets)

---

## 7. Dependencies

| Dependency | Type | Risk |
|------------|------|------|
| _aegis-brain/ file schema stability | Data | Medium -- schema may evolve |
| heartbeat.log format | Data | Low -- simple timestamp format |
| Next.js 15 App Router | Technology | Low -- stable release |
| HTML5 Canvas API | Technology | Low -- universal browser support |
| Sprite sheet creation | Asset | Medium -- requires Pixel agent or manual creation |

---

## 8. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Schema changes break dashboard | Medium | High | Version the data models; add fallback defaults |
| Large log files cause slow reads | Low | Medium | Read only last N lines of activity.log |
| Sprite animation impacts performance | Low | Medium | Use sprite sheets, limit canvas redraws |
| CORS issues in remote deployment | Medium | Low | API routes are same-origin in Next.js |
