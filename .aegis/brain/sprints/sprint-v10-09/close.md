# Sprint v10-09 Close: Per-Agent Allow Lists

**Closed**: 2026-05-02
**Delivered**: 3/3 pt (100%)
**Branch**: `feat/v10-09-per-agent-allow-lists`
**Supersedes**: closed PR #87 (`fix/AEG-88-per-agent-allow-lists`, stale pre-v9-rename)

## Stories Delivered

| ID | Story | Pt | Status |
|----|-------|----|----|
| A | Implementer/orchestrator deny patterns (4 agents) | 1 | ✅ DONE |
| B | Researcher/reviewer/QA allow+deny patterns (3 agents) | 1 | ✅ DONE |
| C | CLAUDE_safety.md "Per-Agent Permissions" section | 1 | ✅ DONE |

## Files Changed

- `.claude/agents/spider-man.md` — DENY (implementer)
- `.claude/agents/nick-fury.md` — DENY (controller, critical-path protect)
- `.claude/agents/captain-america.md` — DENY (orchestrator, critical-path protect)
- `.claude/agents/thor.md` — DENY (DevOps, sudo blocked)
- `.claude/agents/beast.md` — ALLOW + DENY tight (researcher, read-only)
- `.claude/agents/war-machine.md` — ALLOW + DENY tight (QA, test runners only)
- `.claude/agents/black-panther.md` — ALLOW + DENY tight (reviewer, no mutation)
- `CLAUDE_safety.md` — new "Per-Agent Permissions" subsection in §5
- `.aegis/brain/sprints/sprint-v10-09/{plan,close}.md`

## Verification

- All 7 modified agent YAML frontmatters parse cleanly (verified via python yaml.safe_load)
- Pattern A (DENY-only) applied to 4 agents — same baseline destructive ops blocked
- Pattern B (ALLOW + DENY tight) applied to 3 agents — role-specific allow lists, mutation denied
- Decision tree documented for future agents in CLAUDE_safety.md

## Mapping Provenance (PR #87 → v10-09)

| PR #87 (closed) | v10-09 (this sprint) | Pattern |
|-----------------|---------------------|---------|
| bolt | spider-man | DENY |
| forge | beast | ALLOW + DENY tight |
| mother-brain | nick-fury | DENY |
| navi | captain-america | DENY |
| ops | thor | DENY |
| pixel | wasp | (skipped — no Bash in v9) |
| probe + sentinel | war-machine | ALLOW + DENY tight |
| sage | iron-man | (skipped — no Bash in v9) |
| vigil | black-panther | ALLOW + DENY tight |
| (new in v9) | loki | (skipped — no Bash) |
| (new in v9) | coulson | (skipped — no Bash) |

## Defense-in-depth model

1. **Layer 1 — Project deny list** (`.claude/settings.json` `permissions.deny`): blocks dangerous commands at the harness level for ALL agents. Hardened in PR #88 (AEG-86).
2. **Layer 2 — Per-agent permissions** (this sprint): role-aware allow/deny. Catches mistakes where an agent should not even attempt a normally-allowed command.
3. **Layer 3 — Tool-list omission**: agents without Bash in `tools:` cannot run shell commands at all. Used for designer/architect/devil's-advocate roles where Bash would be out-of-character.

## Lessons

1. **Stale PRs accumulate semantic debt** — PR #87 was technically still openable but semantically broken (agent rename made the diff target deprecated paths). Re-implementing on fresh branch was cheaper than rebasing across 6 sprints of evolution.
2. **YAML comments in frontmatter** — used `#` comments inside the `permissions:` block to document the rationale. Survives YAML parse; helps future maintainers understand WHY without grep-spelunking.
3. **Decision tree > exhaustive list** — for new agents, a 4-step decision tree (in CLAUDE_safety.md) scales better than an enumerated mapping table.
4. **Defense in depth, not single layer** — even though project-level deny would catch most cases, per-agent layer adds role-context that helps audit + debugging when something is blocked.

## Carry-forward

- When new agents are added, follow the decision tree in `CLAUDE_safety.md §5 Per-Agent Permissions`
- If a permissions block ever blocks legitimate work, prefer:
  1. Re-evaluating whether the operation matches the agent's role (often the right answer = wrong agent doing it)
  2. Adding a narrow allow rule (with rationale comment)
  3. Last resort: changing the pattern

## No new ADR

This is implementation of existing security policy (CLAUDE_safety.md §5). No architectural choice introduced; just role-aware refinement.
