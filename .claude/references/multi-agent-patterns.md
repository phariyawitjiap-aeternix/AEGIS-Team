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

## Patterns Adopted from ECC (everything-claude-code, v8.3.1)

After a deep-dive analysis of `affaan-m/everything-claude-code` (145k stars,
Anthropic Hackathon winner), AEGIS adopted four high-leverage patterns:

### Pattern 6: Runtime Hook Profile Switching (from ECC)
**Source**: ECC's `scripts/hooks/run-with-flags.js`
**Status**: ✅ Wired via `.claude/hooks/run-with-flags.sh` + `profiles.json`

Two env vars control hook execution at runtime:
```bash
AEGIS_HOOK_PROFILE=minimal|standard|strict   # profile membership check
AEGIS_DISABLED_HOOKS=id1,id2                 # explicit opt-out
```

Every hook in `settings.json` is wrapped: `run-with-flags.sh <hook-id> <script>`.
The wrapper checks the profile manifest, exits silently if not in profile, otherwise
pipes stdin through to the real hook. Pairs with `/aegis-mode` autonomy L1-L4.

### Pattern 7: Batched Stop-time Format/Typecheck (from ECC)
**Source**: ECC's `post:edit:accumulator` + `stop:format-typecheck` hooks
**Status**: ✅ Wired via `post-edit-accumulate.sh` + updated `on-stop.sh`

Instead of running `tsc` / `biome` after every Edit (expensive), record edited
paths in a session-scoped accumulator file (`/tmp/aegis-edits/<session>.txt`)
and run a single batched check at Stop time. Deduped, scoped per session.

Result: Spider-Man loop speed-up (10 edits = 1 tsc run, not 10).

### Pattern 8: Write-Side Config Protection (from ECC)
**Source**: ECC's `pre:config-protection` hook
**Status**: ✅ Wired via `guard-write.sh` on Edit/Write/MultiEdit

Blocks agents from editing lint/format/typecheck config files
(`.eslintrc*`, `biome.json`, `tsconfig*.json`, `pyproject.toml`, `ruff.toml`,
etc.). Prevents the "silence the linter to ship" anti-pattern where an agent
weakens rules instead of fixing code.

Also protects AEGIS's own `settings.json` from mid-session edits.

### Pattern 9: Instinct Confidence Lifecycle (from ECC)
**Source**: ECC's `continuous-learning-v2` skill
**Status**: ✅ Implemented in `_aegis-brain/instincts/` + `/aegis-instinct` + `/aegis-evolve`

Upgrades freeform `_aegis-brain/learnings/` lessons into confidence-scored
YAML instincts with 4 lifecycle stages: `pending` → `active` → `promoted` → `retired`.

- **Loki** loads `promoted/` as hard rules (auto-REJECT) and `active/` as warnings
- **`/aegis-instinct reinforce <id>`** bumps confidence +0.15, auto-promotes at thresholds
- **`/aegis-evolve`** clusters similar instincts, merges duplicates, retires stale

This is how AEGIS's lesson system becomes a self-enforcing immune system.

---

## Related Files

- `.claude/hooks/guard-bash.sh` — PreToolUse Bash blocker
- `.claude/hooks/guard-write.sh` — PreToolUse Edit/Write blocker (config-protection)
- `.claude/hooks/post-tool-use.sh` — PostToolUse Bash logger
- `.claude/hooks/post-edit-accumulate.sh` — PostToolUse Edit accumulator
- `.claude/hooks/on-stop.sh` — Stop reminder + batched format/typecheck
- `.claude/hooks/run-with-flags.sh` — Profile/disable wrapper for all hooks
- `.claude/hooks/profiles.json` — Hook profile registry (minimal/standard/strict)
- `.claude/hooks/tinman-heartbeat.sh` — Background monitor
- `.claude/settings.json` — Hook wiring + env vars (AEGIS_HOOK_PROFILE)
- `_aegis-brain/instincts/` — Instinct registry (pending/active/promoted/retired)
- `.claude/commands/aegis-instinct.md` — Instinct management command
- `.claude/commands/aegis-evolve.md` — Cluster + merge + promote command
- `@references/quality-protocol.md` — Gate 0 + 6-gate quality system
- `@references/adaptive-thinking-guide.md` — Effort levels per agent
