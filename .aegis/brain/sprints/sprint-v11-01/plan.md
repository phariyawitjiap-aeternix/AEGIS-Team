# Sprint v11-01 Plan: aegis-live-tail (always-on terminal visibility)

**Sprint Goal**: Ship `aegis-live-tail` — the highest-leverage v1.1 build from the AEGIS-Plus Mega Plan. Always-on terminal pane that displays the live conversation/activity stream during every Claude Code session, with zero servers and zero browsers.

**Points**: 5pt
**Duration**: 1–2 sessions (per plan §13 estimate: 5 hrs)
**Branch**: `feat/v11-01-aegis-live-tail`
**Pilot project**: `~/Documents/kam-tong-ham/`

## Strategic Context

`aegis-live-tail` closes Goal G1 from the Mega Plan: *Always-visible live conversation/activity stream*. Without it, the operator has no real-time view of agent activity — every Edit/Write/Bash/Skill call is invisible until it scrolls past in the Claude Code conversation. With it, a tmux pane shows the in-flight stream and survives session restart.

This is the **first AEGIS-Plus skill** and establishes:
- The `.aegis/brain/live/` storage convention (fifo + format.yaml)
- The PostToolUse `emit.mjs` hook pattern that other skills (activity-logger, parallel-dispatch) will reuse
- The tmux integration pattern for terminal-only mandate

## Stories

| ID | Story | Pt | Type |
|----|-------|----|------|
| A | Skill scaffolding + SKILL.md (bilingual triggers, format.yaml schema) | 1 | NEW |
| B | `emit.mjs` PostToolUse hook (write one event line to fifo, p95 <100ms) | 1 | NEW |
| C | `watch.mjs` foreground tailer (ANSI render, filter flags, <20MB) | 2 | NEW |
| D | `start-tmux.sh` bootstrap + `format.mjs` render util | 1 | NEW |

### Story A — Skill scaffolding (1pt)

- Create `.claude/skills/aegis-live-tail/SKILL.md` with bilingual triggers per plan §6.1
- Create `.aegis/brain/live/format.yaml` template with display config (width, timestamps, persona, tool, truncate, highlight colors)
- Create `.aegis/brain/live/.gitignore` to exclude `current.fifo` (transient)
- Document `aegis-live-tail start | watch | stop` CLI surface in SKILL.md

### Story B — `emit.mjs` PostToolUse hook (1pt)

- Read tool name + args from hook env vars (CLAUDE_TOOL, CLAUDE_TOOL_ARGS)
- Format one timestamped line per plan §6.1 spec: `HH:MM:SS [Persona  ] Tool   target (delta/result)`
- Non-blocking write to `.aegis/brain/live/current.fifo` (drop if pipe full)
- Performance budget: p95 <100ms (R1 mitigation), enforced by inline timing log
- Wire into `.claude/settings.json` PostToolUse with matcher `.*`
- Test: 100-call benchmark, assert p95 latency

### Story C — `watch.mjs` foreground tailer (2pt)

- `tail -f`-style readline loop on the fifo
- ANSI escape codes for color highlighting per format.yaml
- Filter flags: `--persona <name>`, `--tool <name>`, `--errors-only`, `--since <duration>`
- Memory cap: <20MB (use simple readline, no buffering)
- 24-hour auto-recycle to prevent leak (R2 mitigation)
- Standalone mode (no tmux required) — works in any terminal

### Story D — `start-tmux.sh` + `format.mjs` (1pt)

- `start-tmux.sh`: split current tmux window 70/30, spawn `watch.mjs` in bottom pane, focus top pane
- `format.mjs`: shared render utility used by both `emit.mjs` and `watch.mjs`
- Fallback: if tmux not detected, print instructions for second-terminal mode

## Acceptance Criteria (from plan §6.1)

- [ ] `aegis-live-tail start` opens tmux split with live pane
- [ ] Every Edit/Write/Bash/Skill emits one line within 200ms (p95)
- [ ] Pane survives Claude Code session restart (fifo persists)
- [ ] Filter flags work: `--persona`, `--tool`, `--errors-only`, `--since`
- [ ] Test: trigger 10 tool calls, all 10 appear in pane
- [ ] Test: kill watcher, restart, see new events appear (not old)
- [ ] Memory footprint <20MB for watcher process
- [ ] Hook latency p95 <100ms (benchmarked)
- [ ] Existing AEGIS skills still work after install (regression check)

## Risks (from plan §11, applicable subset)

| # | Risk | Mitigation in this sprint |
|---|---|---|
| R1 | Hooks slow down every tool call | Hard performance budget + 100-call benchmark in Story B |
| R2 | Watcher leaks memory | 24h auto-recycle in Story C |
| R3 | fifo fills up if no reader | Non-blocking writes from `emit.mjs` (drop oldest) in Story B |
| R6 | Hook script crashes block all tool calls | `emit.mjs` exits 0 on internal error (fail-open) |
| R11 | Tmux setup fails on non-tmux env | Standalone `watch.mjs` per Story C |

## Out of Scope (deferred to later v11 sprints)

- Activity log JSONL format (→ v11-02 `aegis-activity-logger`)
- Issue thread YAML (→ v11-03 `aegis-issue-thread`)
- Parallel dispatch wrapper (→ v11-04 `aegis-parallel-dispatch`)
- Approval gate / router / run-logger / trace-export (→ v11-05+ Phase 2)

## Dependencies

- ✅ tmux 3.6a installed
- ✅ node v25.8.2 installed (≥20 required by plan §13)
- ✅ Claude Code with hook support (existing meta uses hooks already)
- ✅ Pilot project `~/Documents/kam-tong-ham/` exists on disk

## Decision Log (per Mega Plan §14)

- **D1 Install scope**: global at `~/.claude/skills/` (share across kam-tong-ham + future projects)
- **D2 Phase 1 order**: sequential, `aegis-live-tail` first
- **D3 Live-tail transport**: named pipe (fifo) — atomic line writes, macOS+Linux supported
- **D5 Tmux auto-spawn**: yes, via `start-tmux.sh`

## Success Metrics (Phase 1 acceptance, plan §12)

- Live-tail uptime >95% during pilot week
- Live-tail latency <500ms event-to-display p95
- Hook latency p95 <100ms
- Zero regressions in existing AEGIS skill set

## References

- `~/Documents/AEGIS-PLUS-MEGA-PLAN.md` — full plan v1.1 (989 lines)
- Plan §6.1 — `aegis-live-tail` spec
- Plan §11 — Risks
- Plan §15 D — Tmux quick-start
