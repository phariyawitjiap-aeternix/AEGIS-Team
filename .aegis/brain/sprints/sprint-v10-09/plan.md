# Sprint v10-09 Plan: Per-Agent Allow Lists (v9 Marvel personas)

**Sprint Goal**: Implement per-agent least-privilege Bash allow/deny lists for all v9 Marvel personas. Re-implementation of stale PR #87 (AEG-88) which targeted pre-v9 agent names.
**Points**: 3pt total (1+1+1)
**Duration**: 1 session (2026-05-02)
**Branch**: `feat/v10-09-per-agent-allow-lists`

## Strategic Context

Closed PR #87 (`fix/AEG-88-per-agent-allow-lists`) was based on a branch from before the v9 agent rename (sprint-v9-04 → sprint-v9-06). Files at old paths (`bolt.md`, `vigil.md`, `sentinel.md`, etc.) no longer exist in main — current Marvel personas use different filenames.

The **security intent** of PR #87 remains valid:
- Implementer agents (writes code) should be denied destructive ops (rm, curl-pipe-shell, force push)
- Researcher/reviewer agents (read-only by role) should have tight allow lists with explicit deny
- Designer/architect agents should be denied Bash entirely (already enforced via tools list omission in v9)

Defense in depth: project-level deny list (already in main from PR #88) blocks at one layer; per-agent allow/deny adds a second layer that's role-aware.

## Mapping: PR #87 (old) → v10-09 (current v9 Marvel)

| Old (PR #87) | Current (v9) | Pattern | Apply v10-09? |
|--------------|--------------|---------|---------------|
| bolt | spider-man | DENY-only (implementer) | ✅ |
| forge | beast | ALLOW+DENY tight (read-only researcher) | ✅ |
| mother-brain | nick-fury | DENY (autonomous controller) | ✅ |
| navi | captain-america | DENY (orchestrator) | ✅ |
| ops | thor | DENY (DevOps) | ✅ |
| pixel | wasp | (already no Bash via tools list) | ⏸️ skip |
| probe / sentinel | war-machine | ALLOW+DENY tight (QA Lead) | ✅ |
| sage | iron-man | (already no Bash via tools list) | ⏸️ skip |
| vigil | black-panther | ALLOW+DENY tight (code reviewer) | ✅ |
| (new in v9) | loki | (already no Bash via tools list) | ⏸️ skip |
| (new in v9) | coulson | (already no Bash via tools list) | ⏸️ skip |

**7 agents need permissions blocks**: spider-man, beast, nick-fury, captain-america, thor, war-machine, black-panther.

## Stories

| ID | Story | Pt | Type |
|----|-------|----|------|
| A | Implementer/orchestrator deny patterns (4 agents) | 1 | NEW |
| B | Researcher/reviewer/QA allow+deny patterns (3 agents) | 1 | NEW |
| C | Update CLAUDE_safety.md "Per-Agent Permissions" section | 1 | DOC |

### Story A — DENY-only pattern (4 agents)

Agents that legitimately need broad Bash access for their role, but must be blocked from destructive operations:

- **spider-man** (implementer) — needs: build, test, install, edit-via-shell. Deny: rm/curl-pipe/wget-pipe/chmod/sudo/force push/reset hard/amend/clean -f
- **nick-fury** (autonomous controller) — needs: orchestration, state inspection. Deny: same as spider-man + rm-of-critical-paths (src, .git, _aegis-brain)
- **captain-america** (orchestrator) — same deny set as nick-fury
- **thor** (DevOps) — needs: deployment, monitoring. Deny: same baseline (no sudo even though DevOps)

### Story B — ALLOW+DENY tight pattern (3 agents)

Agents whose role is read-only or limited-write — need an explicit allow list to enforce least privilege:

- **beast** (scanner/researcher) — allow: git read-only, file inspection, jq/grep/wc. Deny: rm/mv/cp/curl/wget/install/git push|commit|reset|rebase|checkout|clean
- **war-machine** (QA Lead) — allow: test runners (jest/vitest/pytest/go test/cargo test), git read-only, file inspection. Deny: rm/mv/install/git push|commit|reset|checkout
- **black-panther** (code reviewer) — allow: git read-only, file inspection, diff utilities. Deny: rm/mv/cp/install/all git write ops/sed/awk/source/export

### Story C — CLAUDE_safety.md update

Add new section "Per-Agent Permissions" documenting:
- The two patterns (DENY-only vs ALLOW+DENY tight)
- Which agents use which pattern + rationale
- Defense-in-depth model: project deny list + per-agent permissions = 2 layers
- How to extend to new agents (decision tree)

## Out of scope

- **Settings.json changes** — project-level deny+allow already hardened in PR #88 (#86 deny-list, v10-05/06 allow tweaks). Per-agent layer doesn't touch global config.
- **Skipped agents** (wasp, iron-man, loki, coulson) — already lack Bash tool, so per-agent block is redundant. If Bash is added later for any of these, revisit.
- **Tool registry refactor** — out of scope; this sprint adds permissions to existing frontmatter only.
- **Runtime enforcement testing** — Claude Code's frontmatter `permissions:` is enforced by the harness; we trust the documented contract. No runtime test scaffold added.

## Success Criteria

- [ ] 7 agent files have `permissions:` block in YAML frontmatter
- [ ] All YAML still valid (no parse errors)
- [ ] `CLAUDE_safety.md` has new "Per-Agent Permissions" section explaining the model
- [ ] Sprint added to roadmap.md
- [ ] PR opened with explicit reference to closed PR #87 + AEG-88 ticket
