# AEGIS Team Commands Upgrade Plan v6.1

**Author**: Sage (Architect)
**Date**: 2026-03-23
**Status**: DRAFT -- Requires peer review from Vigil or Havoc
**Scope**: Upgrade team command files (build, review, debate) by selectively adopting patterns from the reference quick-dev-team implementation.

---

## 1. Comparative Analysis

### 1.1 AEGIS Current Strengths (KEEP)

| Strength | Why It Matters |
|----------|---------------|
| Project-agnostic prompts | Works with any language, any repo. No Go-specific or domain-specific assumptions baked in. |
| Simple command structure | Each team command is a single self-contained file under 50 lines. A new user reads it once and understands the full flow. |
| Clear agent persona separation | Each agent reads its own `.claude/agents/<name>.md` file at runtime, keeping the command file lean. |
| Message-based coordination | Agents use SendMessage to hand off work, creating a natural dependency chain without explicit phase machinery. |
| Immediate parallel spawn | All agents spawn at once; those that depend on others simply wait via SendMessage, avoiding orchestration overhead. |
| Team lifecycle (TeamCreate / TeamDelete) | Clean setup and teardown already in place. |

### 1.2 Reference Implementation Strengths (ADOPT selectively)

| Pattern | What It Does Well | Adoption Verdict |
|---------|-------------------|-----------------|
| **Threshold check (solo vs team)** | Avoids spawning 3-4 agents for a trivial one-file fix. Saves cost and complexity. | **ADOPT** |
| **Baseline commit capture** | Records `git rev-parse HEAD` before work begins. Enables rollback, diff-based review, and prevents "what changed?" confusion. | **ADOPT** |
| **Success metrics per step** | Each phase defines what "done" looks like. Prevents agents from declaring victory prematurely. | **ADOPT** (simplified) |
| **Failure modes per step** | Documents what can go wrong and what to do about it. Makes the system self-healing. | **ADOPT** (simplified) |
| **Integration step with merge authority** | A team-lead agent merges parallel outputs and resolves conflicts before declaring done. | **ADOPT** (AEGIS already has this implicitly via Vigil/Navi -- make it explicit) |
| **State variables across steps** | Persisting `{baseline_commit}`, `{execution_mode}`, etc. across the workflow. | **ADOPT** (minimal set only) |

### 1.3 Reference Implementation Weaknesses (SKIP)

| Pattern | Why It Should Be Skipped |
|---------|------------------------|
| **Separate workflow.md files** | Adds indirection. The command file loads another file which loads agent personas. Three hops to understand one team. AEGIS's single-file approach is clearer. |
| **5-phase sequential/parallel orchestration** | Over-engineered for a general framework. The rigid phase structure (Sequential -> Parallel -> Sequential -> Parallel -> Sequential) assumes a specific workflow shape. AEGIS's message-based coordination is more flexible. |
| **Hyper-detailed agent prompts with exact file paths** | Embeds project knowledge (specific file paths, type contracts, module names) into the team command. This breaks the moment the project structure changes. Agent personas should carry domain knowledge, not team commands. |
| **Explicit prohibitions per agent per step** | The reference lists "DO NOT touch X, Y, Z" for each agent in each phase. AEGIS already handles this via blast radius definitions in `CLAUDE_agents.md`. Duplicating it creates maintenance burden and drift. |
| **Language-specific checks** | The reference includes Go-specific linting, type checking, and build commands. AEGIS must remain language-agnostic. |
| **Complex state variable threading** | Passing 6+ variables between phases adds cognitive overhead. A minimal set (baseline_commit, execution_mode) is sufficient. |

---

## 2. Implementation Plan

### 2.1 Change: Add Threshold Check to All Team Commands

**Rationale**: Spawning a full team for a one-line typo fix is wasteful. A quick size check routes small tasks to solo mode.

**Design**: Add a Step 1.5 between "Get the task" and "Create team" in each command file.

```
## Step 2: Threshold Check

Evaluate the task scope:
- If the task touches 1-2 files AND is a simple fix/change: run in SOLO mode
  (execute with a single agent, skip team creation)
- If the task touches 3+ files OR involves design decisions OR has unclear scope:
  run in TEAM mode (proceed to Step 3)

Report which mode was selected.
```

**Files changed**:
- `.claude/commands/aegis-team-build.md`
- `.claude/commands/aegis-team-review.md`
- `.claude/commands/aegis-team-debate.md`

**Priority**: P1 (high impact, low effort)

---

### 2.2 Change: Capture Baseline Commit

**Rationale**: Without a baseline, review agents cannot produce meaningful diffs, and rollback is guesswork.

**Design**: Add to the beginning of the build and review team commands.

```
## Step 1: Capture Baseline

Record the current state:
- {baseline_commit} = output of `git rev-parse HEAD`
- {current_branch} = output of `git branch --show-current`
- {dirty_files} = output of `git status --porcelain`

If {dirty_files} is non-empty, warn the user before proceeding.
```

**Files changed**:
- `.claude/commands/aegis-team-build.md`
- `.claude/commands/aegis-team-review.md`

**Priority**: P1 (critical for review quality)

---

### 2.3 Change: Add Success Metrics to Agent Prompts

**Rationale**: Agents currently receive open-ended tasks. Adding explicit completion criteria reduces false-ready signals.

**Design**: Append a SUCCESS_CRITERIA block to each agent's prompt within the team commands. Keep it generic, not project-specific.

For the build team, the prompts would gain:

- **Sage**: "SUCCESS: Spec file exists in _aegis-output/specs/, contains at least: problem statement, proposed solution, file list, and acceptance criteria."
- **Bolt**: "SUCCESS: All files listed in spec are created/modified, tests pass (`run test command`), no lint errors."
- **Vigil**: "SUCCESS: Review file exists in _aegis-output/reviews/, contains PASS/CONDITIONAL/FAIL verdict with specific file:line references for any issues."

**Files changed**:
- `.claude/commands/aegis-team-build.md`
- `.claude/commands/aegis-team-review.md`
- `.claude/commands/aegis-team-debate.md`

**Priority**: P2 (improves reliability)

---

### 2.4 Change: Add Failure Handling Instructions

**Rationale**: Currently, if an agent fails or gets stuck, the team lead has no instructions for recovery. The reference implementation's failure modes are valuable but can be simplified.

**Design**: Add a single "Failure Handling" section at the end of each team command.

```
## Failure Handling

If any agent fails to send its completion message within a reasonable time:
1. Check agent status via the team tools
2. If agent is stuck: send it a nudge message with simplified instructions
3. If agent has errored: report the error to the user and proceed with available results
4. If multiple agents fail: abort the team, report partial results, suggest retry

Never wait indefinitely. If an agent has not responded after completing its logical predecessor's work, investigate.
```

**Files changed**:
- `.claude/commands/aegis-team-build.md`
- `.claude/commands/aegis-team-review.md`
- `.claude/commands/aegis-team-debate.md`

**Priority**: P2 (prevents silent hangs)

---

### 2.5 Change: Explicit Integration Step

**Rationale**: AEGIS currently says "summarize results" in Step 5 but does not define what integration means. The reference implementation's merge authority pattern is worth adopting in simplified form.

**Design**: Replace the current vague "summarize" instruction with a concrete integration checklist.

For the build team:
```
## Step 5: Integration

After all agents report completion:
1. Read Vigil's review verdict from _aegis-output/reviews/
2. If PASS: summarize what was built, commit with descriptive message
3. If CONDITIONAL: list the conditions, ask user whether to proceed or fix
4. If FAIL: list critical issues, do NOT commit, suggest re-running with fixes
5. Compare current state against {baseline_commit} using `git diff {baseline_commit}`
6. Report the diff summary to the user
7. Clean up: send shutdown_request to each agent, then TeamDelete
```

**Files changed**:
- `.claude/commands/aegis-team-build.md`
- `.claude/commands/aegis-team-review.md`
- `.claude/commands/aegis-team-debate.md`

**Priority**: P1 (prevents premature "done" declarations)

---

## 3. What NOT to Change

| Current Behavior | Reason to Keep |
|-----------------|---------------|
| Single-file command structure | Simplicity. No indirection through workflow files. |
| Agent persona files in `.claude/agents/` | Separation of concerns. Persona logic stays out of team commands. |
| Message-based coordination (SendMessage) | More flexible than rigid phase sequencing. Agents naturally wait for predecessors. |
| Parallel spawn of all agents | Simple and effective. Agents that need to wait, wait. No phase orchestrator needed. |
| Project-agnostic prompts | AEGIS must work with any codebase. Never embed specific file paths or language-specific commands in team commands. |
| Blast radius enforcement via CLAUDE_agents.md | Single source of truth for permissions. Do not duplicate in team commands. |

---

## 4. Priority Execution Order

| Order | Change | Effort | Impact | Risk |
|-------|--------|--------|--------|------|
| 1 | Baseline commit capture (2.2) | Low | High | None |
| 2 | Threshold check (2.1) | Low | High | Low -- must test solo fallback |
| 3 | Explicit integration step (2.5) | Medium | High | Low |
| 4 | Success metrics (2.3) | Low | Medium | None |
| 5 | Failure handling (2.4) | Low | Medium | None |

Estimated total effort: One focused implementation session for all five changes across three files.

---

## 5. Validation Criteria

The upgrade is successful when:

1. A trivial task (e.g., "fix typo in README") triggers solo mode, not a full team
2. Every build team run captures a baseline commit and uses it in the final diff
3. No agent declares completion without meeting its success criteria
4. A simulated agent failure (e.g., Bolt times out) triggers the failure handling path instead of silent hang
5. The integration step produces a clear PASS/CONDITIONAL/FAIL decision visible to the user
6. A new user can still read any team command file and understand the full flow in under 5 minutes

---

## 6. Open Questions for Peer Review

1. Should the threshold check be a shared snippet included by all three team commands, or duplicated in each? Duplication is simpler but creates maintenance drift.
2. Should baseline commit capture also snapshot the dependency lockfile hash for reproducibility?
3. Should failure handling include an automatic retry (with simplified prompt) or always escalate to the user?

---

*This plan requires review from Vigil (for process rigor) or Havoc (for adversarial challenge) before implementation proceeds.*
