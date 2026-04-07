# Multi-Agent Patterns — Adopted from Global Research

> Proven patterns from the Claude multi-agent community, integrated into AEGIS v8.3+.

---

## Pattern 1: Claude Code Hooks (Enforcement Layer)

**Source**: Anthropic official Claude Code docs
**Status**: ✅ Wired in `.claude/settings.json` + `.claude/hooks/`

Three hooks enforce Golden Rules at the machine level:

| Hook | Script | Enforces |
|------|--------|---------|
| PreToolUse (Bash) | `guard-bash.sh` | Block `--force`, `--amend`, `rm -rf /`, direct push to main |
| PostToolUse (Bash) | `post-tool-use.sh` | Log git commits + test results (Metaswarm validation) |
| Stop | `on-stop.sh` | Remind human to run `/aegis-retro` (Golden Rule 6) |

**How it works**: Hook scripts receive JSON on stdin, exit 2 to block, exit 0 to allow.
**Logs**: All events append to `_aegis-brain/logs/activity.log`.

---

## Pattern 2: Agent `tools` Frontmatter (Blast Radius Enforcement)

**Source**: Claude Code subagent docs
**Status**: ✅ All 13 agents have `tools:` and `disallowedTools:` in frontmatter

Claude Code machine-enforces tool access per agent — not just documentation.

| Agent | Tools Allowed | Tools Blocked |
|-------|--------------|--------------|
| Spider-Man | Read, Write, Edit, Bash, Glob, Grep | Agent (can't spawn sub-agents) |
| Beast | Read, Glob, Grep, Bash, WebFetch, code_execution | Write, Edit, Agent |
| Coulson | Read, Glob, Grep, Write, Edit | Bash, Agent |
| Loki | Read, Write, Glob, Grep | Bash, Agent |
| Vision | Read, Bash, Glob, Grep | Write, Edit, Agent |

---

## Pattern 3: Plan-Approval Gate (Iron Man → Loki → Build)

**Source**: Anthropic multi-agent research + Metaswarm
**Status**: ✅ Added to Iron Man and Loki agent definitions

Prevents premature implementation — every spec gets adversarial review before code is written.

```
Iron Man writes spec
      ↓
Iron Man → Loki: PlanProposal
      ↓
Loki → Iron Man: PlanApprovalResponse (APPROVE / CONDITIONAL / REJECT)
      ↓ (only if APPROVE or CONDITIONAL)
Iron Man → Nick Fury: "spec approved"
      ↓
Nick Fury → Spider-Man: TaskAssignment
```

**Gate bypass**: Only P0/P1 hotfixes skip Loki review.

---

## Pattern 4: CLAUDE_CODE_TASK_LIST_ID (Native Task Coordination)

**Source**: Anthropic internal + claude_code_agent_farm
**Status**: ✅ Set in `.claude/settings.json` env

```json
"CLAUDE_CODE_TASK_LIST_ID": "aegis-shared-tasks"
```

Multiple sub-agents can self-claim tasks from the shared list without Nick Fury polling each one.
Reduces orchestration overhead by ~40% in parallel workloads.

**Agent behavior**: When picking a task, check shared list first, claim it atomically, then execute.

---

## Pattern 5: TinMan Heartbeat (Background Monitor)

**Source**: TinMan project + ELF framework (30s heartbeat)
**Status**: ✅ Script at `.claude/hooks/tinman-heartbeat.sh`

Zero-dependency health monitor runs on cron (every 5 minutes):

**Checks**:
- Git working directory clean?
- Brain directories intact (`resonance/`, `tasks/`, `logs/`, `sprints/current/`)
- Kanban board exists?
- BLOCK 0 docs present (PM.01, SI.01, SI.02)?
- Activity log written in last 24h?

**Install**:
```bash
bash .claude/hooks/tinman-heartbeat.sh --install-cron
```

**Log**: `_aegis-brain/logs/heartbeat.log` (last 500 lines, auto-trimmed)

---

## Anti-Patterns Avoided

Based on research failures:

| Anti-Pattern | Why Avoided |
|-------------|-------------|
| Agent self-reports task as done | Metaswarm: PostToolUse hook independently validates |
| All agents load simultaneously | Progressive disclosure: only active agent prompt loaded |
| Trusting subagent "I'm done" | Nick Fury reads output files directly to verify completion |
| No blast radius limits | Machine-enforced via `tools`/`disallowedTools` frontmatter |
| Planning skipped under pressure | Plan-Approval Gate + BLOCK 0 are non-negotiable |

---

## Related Files

- `.claude/hooks/guard-bash.sh` — PreToolUse blocker
- `.claude/hooks/post-tool-use.sh` — PostToolUse logger
- `.claude/hooks/on-stop.sh` — Stop reminder
- `.claude/hooks/tinman-heartbeat.sh` — Background monitor
- `.claude/settings.json` — Hook wiring + env vars
- `@references/quality-protocol.md` — Gate 0 + 6-gate quality system
- `@references/adaptive-thinking-guide.md` — Effort levels per agent
