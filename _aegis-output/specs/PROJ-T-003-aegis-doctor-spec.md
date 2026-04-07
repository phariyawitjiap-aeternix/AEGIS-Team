# 🔧 Iron Man — Architecture Spec: /aegis-doctor
Timestamp: 2026-04-07 09:02 UTC
Task ID: PROJ-T-003 | Story Points: 5

---

## Summary

`/aegis-doctor` is a post-install verification command that checks all 13 AEGIS agents are correctly configured. It validates model IDs, required frontmatter fields, tool allow/deny lists, output locations, and cross-references between agents and teams. Output is a pass/warn/fail report written to `_aegis-output/research/`.

---

## Problem Statement

After install or upgrade, there is no automated way to confirm the AEGIS configuration is valid. Users may run `/aegis-start` with silently broken agents (wrong model ID, missing tools, stale cross-references). `/aegis-doctor` surfaces these issues before any work begins.

---

## Scope

### In Scope
- Validate all 13 agent `.md` files in `.claude/agents/`
- Validate all team files in `.claude/teams/`
- Validate all command files in `.claude/commands/`
- Validate all reference files in `.claude/references/`
- Check `_aegis-brain/` directory structure
- Output a structured health report

### Out of Scope
- Auto-fixing broken configurations (read-only diagnostic)
- Validating skill content (separate concern)
- Network checks (offline-first)

---

## Agent File Validation Rules

For each `.claude/agents/*.md`:

| Field | Rule | Severity |
|-------|------|----------|
| `name` | Must match filename (without .md) | 🔴 Critical |
| `model` | Must be one of: `claude-opus-4-6`, `claude-sonnet-4-6`, `claude-haiku-4-5-20251001` | 🔴 Critical |
| `tools` | Must be a non-empty array | 🟡 Warning |
| `disallowedTools` | Must not contain tools in `tools` list | 🔴 Critical |
| `description` | Must be present and non-empty | 🟡 Warning |
| `## Identity` section | Must exist | 🟡 Warning |
| `## Constraints` section | Must exist | 🔴 Critical |
| `## Output Location` section | Must exist | 🟡 Warning |
| Cross-references | Any `@agent/` references must point to existing agents | 🔴 Critical |

---

## Team File Validation Rules

For each `.claude/teams/*.md`:

| Rule | Severity |
|------|----------|
| Each listed agent name must match an existing agent file | 🔴 Critical |
| `subagent_type` values must match actual agent names | 🔴 Critical |

---

## Output Format

```
🩺 AEGIS DOCTOR — Health Check Report
Timestamp: YYYY-MM-DD HH:MM UTC
AEGIS Version: 8.3

AGENTS (13/13 checked)
  ✅ nick-fury      opus-4-6        tools=10  constraints=15
  ✅ captain-america opus-4-6       tools=8   constraints=12
  ✅ iron-man        opus-4-6       tools=7   constraints=10
  ✅ spider-man      sonnet-4-6     tools=7   constraints=11
  ✅ black-panther   sonnet-4-6     tools=6   constraints=9
  ✅ loki            opus-4-6       tools=7   constraints=8
  ✅ beast           haiku-4-5      tools=7   constraints=5
  ✅ wasp            sonnet-4-6     tools=5   constraints=6
  ✅ songbird        haiku-4-5      tools=5   constraints=5
  ✅ war-machine     sonnet-4-6     tools=4   constraints=6
  ✅ vision          haiku-4-5      tools=4   constraints=7
  ✅ coulson         haiku-4-5      tools=5   constraints=8
  ✅ thor            sonnet-4-6     tools=6   constraints=9

REFERENCES (13 files checked)
  ✅ quality-protocol.md
  ✅ context-rules.md
  ✅ adaptive-thinking-guide.md
  ✅ context-editing-protocol.md
  ... (9 more)

BRAIN STRUCTURE
  ✅ _aegis-brain/tasks/
  ✅ _aegis-brain/sprints/current/kanban.md
  ✅ _aegis-brain/logs/activity.log
  ✅ _aegis-brain/resonance/

OVERALL: ✅ PASS — 0 critical, 0 warnings, 0 failures
```

---

## Implementation Notes

- Implemented as a skill file: `skills/aegis-doctor.md`
- Command entry: `.claude/commands/aegis-doctor.md`
- Invoked via Claude Code slash command: `/aegis-doctor`
- Reads files with Read/Glob/Grep — no Write, no Bash
- Report written to `_aegis-output/research/YYYY-MM-DD_aegis-doctor.md`

---

## Acceptance Criteria

1. `/aegis-doctor` runs without error on a clean install
2. Detects a wrong model ID (e.g., `claude-haiku-3-5`) and flags it 🔴 Critical
3. Detects a missing `## Constraints` section and flags it 🔴 Critical
4. Detects a missing agent cross-reference and flags it 🔴 Critical
5. Report is written to `_aegis-output/research/`
6. Output summary shows PASS / WARN / FAIL verdict

---

*Iron Man — Architecture complete. Handoff to Spider-Man.*
