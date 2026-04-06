# HAVOC ADVERSARIAL REVIEW: AEGIS v7.0 Stress Test

**Date**: 2026-03-24
**Reviewer**: Loki (Devil's Advocate)
**Scope**: Full framework audit -- CLAUDE*.md, agents, skills, commands, installer, orchestrator
**Verdict**: CONDITIONAL -- impressive architecture, significant execution gaps

---

## Executive Summary

AEGIS v7.0 is an ambitious multi-agent orchestration framework layered on top of Claude Code. The design documents are thorough, the concepts are sound, and the vision is coherent. However, there is a stark gap between what the documentation promises and what the implementation can deliver. The framework is heavy on ceremony and specification but has critical installer bugs, relies on experimental APIs that are known-broken, has no runtime error recovery, and conflates "having a markdown template" with "having a working system." A user who follows the Getting Started guide will hit at least 3 showstopping issues before completing their first task.

The framework is NOT smoke and mirrors -- there is real architectural thought here. But it is currently a v0.7, not a v7.0. The gap between documentation and execution is the single biggest risk.

---

## CATEGORY 1: BROKEN PROMISES

### H-001: install.sh Does Not Install v7.0 Skills
- **Severity**: CRITICAL
- **Category**: Broken Promises
- **Finding**: The installer's skill lists are stuck at v6.0. The `standard_skills` array contains `("super-spec" "test-architect" "security-audit" "tech-debt-tracker" "sprint-tracker" "api-docs")` and the `full_skills` array contains `("aegis-distill" "aegis-observe" "adversarial-review" "code-coverage" "retrospective" "course-correction" "skill-marketplace" "aegis-builder")`. The five v7.0 skills -- `kanban-board`, `work-breakdown`, `qa-pipeline`, `iso-29110-docs`, and `sprint-manager` (which supersedes `sprint-tracker`) -- are completely absent from the install script. A user running `install.sh --profile full` will get 21 skills, not the advertised 26.
- **Impact**: The entire v7.0 feature set (kanban, work breakdown, QA pipeline, ISO 29110 compliance, sprint management) will silently fail because the skill files are never copied to the target project. Nick Fury references these skills in its decision flow but they will not exist.
- **Fix Complexity**: LOW
- **Suggested Fix**: Add `"sprint-manager" "kanban-board" "work-breakdown" "qa-pipeline" "iso-29110-docs"` to the appropriate skill arrays. `sprint-manager` and `kanban-board` should be in `standard_skills`. `qa-pipeline` and `iso-29110-docs` should be in `full_skills`. Also update `work-breakdown` to `standard_skills`.

---

### H-002: install.sh Does Not Create Required Output Directories
- **Severity**: CRITICAL
- **Category**: Broken Promises
- **Finding**: The installer creates `_aegis-output/reviews`, `_aegis-output/adversarial`, `_aegis-output/scans`, `_aegis-output/architecture`, `_aegis-output/design`, and `_aegis-output/content`. It does NOT create `_aegis-output/specs/`, `_aegis-output/breakdown/`, `_aegis-output/qa/`, or `_aegis-output/iso-docs/` -- all four of which are assumed to exist by Nick Fury's scan protocol (aegis-start Step 4a/4b), the QA pipeline, the compliance command, and the breakdown command. It also does not create `_aegis-brain/sprints/` or `_aegis-brain/handoffs/`.
- **Impact**: First run of `/aegis-start` will attempt `ls _aegis-output/specs/ 2>/dev/null` and similar commands that will fail. While some commands use `2>/dev/null`, this means the scan results will always show "no spec exists" even if the user later manually creates one in a different location. More critically, `/aegis-breakdown` and `/aegis-sprint plan` will need to mkdir before writing, and if they forget, they will error out.
- **Fix Complexity**: LOW
- **Suggested Fix**: Add the missing directories to the `directories=()` array: `_aegis-output/specs`, `_aegis-output/breakdown`, `_aegis-output/qa`, `_aegis-output/iso-docs`, `_aegis-brain/sprints`, `_aegis-brain/handoffs`.

---

### H-003: TeamCreate / Agent Teams Relies on Experimental API (Known Bug #26479)
- **Severity**: CRITICAL
- **Category**: Broken Promises
- **Finding**: The entire multi-agent system depends on `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`, which the GETTING_STARTED.md itself calls out as having a known bug where "teammates don't inherit project-level settings." The workaround is to set global `~/.claude/settings.json` with `bypassPermissions`. This means the framework's core feature -- agent teams -- is built on an experimental, explicitly-buggy API.
- **Impact**: Users who follow the project-level settings path (the normal path) will get agents that cannot execute tools, rendering the entire team system inoperable. The workaround (global bypassPermissions) works but silently disables ALL permission controls for ALL projects on the machine, which is a significant security regression.
- **Fix Complexity**: IMPOSSIBLE (external dependency)
- **Suggested Fix**: Document this limitation prominently in CLAUDE.md (not just GETTING_STARTED.md). Add a pre-flight check in `/aegis-start` that verifies the env var is set and warns if global settings are not configured. Consider making the in-process Agent tool the default path and treating tmux as the optional fallback, since in-process mode does not have this bug.

---

### H-004: Two Conflicting Team Spawning Mechanisms
- **Severity**: HIGH
- **Category**: Broken Promises
- **Finding**: There are two entirely separate systems for spawning agent teams: (1) `aegis-team.sh` which uses tmux panes with `claude -p` in print mode, and (2) `/aegis-team-build` command which uses the Agent tool with `TeamCreate`/`SendMessage` in in-process mode. These two systems use different coordination protocols (file-polling via `-done.md` files vs. SendMessage), different permission models (CLI `--dangerously-skip-permissions` vs. `mode="bypassPermissions"`), and different agent discovery mechanisms. There is no documentation explaining when to use which.
- **Impact**: Users will be confused about which system to use. Nick Fury's documentation references tmux spawning, but the actual commands use in-process Agent tool. If a user starts with aegis-team.sh and then runs /aegis-team-build, they could have two overlapping sets of agents working on the same files.
- **Fix Complexity**: MEDIUM
- **Suggested Fix**: Pick one as the primary mechanism and deprecate the other. The in-process Agent tool is more reliable (no tmux dependency, no permission inheritance bug). Make aegis-team.sh a legacy/optional tool for users who specifically want the visual tmux experience.

---

### H-005: Nick Fury's "Continuous Loop" Cannot Actually Loop
- **Severity**: HIGH
- **Category**: Broken Promises
- **Finding**: Nick Fury's documentation describes a continuous loop: `SCAN -> ANALYZE -> DECIDE -> PLAN -> EXECUTE -> VERIFY -> LEARN -> REPEAT`. However, Claude Code sessions do not support infinite loops. Each session has a finite context window. Each subagent spawn consumes context. There is no mechanism to restart the loop after context exhaustion. The "REPEAT -> Back to SCAN with updated state" step has no implementation -- the aegis-start command runs once and completes.
- **Impact**: Users who expect Nick Fury to autonomously work through multiple tasks in a sprint will be disappointed. In practice, Nick Fury will scan, pick one task, execute it (maybe), and then the session is over. Multi-task autonomous operation requires multiple sessions with manual re-invocation of `/aegis-start`.
- **Fix Complexity**: HIGH
- **Suggested Fix**: Be honest in documentation: Nick Fury handles one decision cycle per session, not a continuous loop. Add explicit "after task completes, run `/aegis-start` again" guidance. Consider building a wrapper script that re-invokes Claude Code sessions with handoff state.

---

### H-006: 3-Gate Quality System Has No Enforcement Mechanism
- **Severity**: HIGH
- **Category**: Broken Promises
- **Finding**: The 3-gate system (Gate 1: Black Panther code review, Gate 2: War Machine QA, Gate 3: Coulson compliance) is beautifully documented but has no enforcement. There is no code or tooling that prevents a task from being marked DONE without passing all three gates. The kanban board is a markdown file that any agent can edit (despite the "single writer" rule, which is a behavioral instruction to an LLM, not a filesystem permission). There is no lock, no state machine, no webhook -- just a hope that agents will follow the documented protocol.
- **Impact**: In practice, agents will sometimes skip gates, especially under context pressure. A task could be moved to DONE by any agent at any time simply by editing kanban.md. The quality system is advisory, not mandatory.
- **Fix Complexity**: HIGH
- **Suggested Fix**: Implement a gate-check script that validates transitions. Before allowing a task to move to DONE, require the existence of a review file (Gate 1), a QA report with PASS verdict (Gate 2), and updated ISO docs (Gate 3). This script could be invoked by `/aegis-kanban move` before writing the file.

---

### H-007: Blast Radius Rules Are Unenforceable
- **Severity**: HIGH
- **Category**: Broken Promises
- **Finding**: Each agent has a defined blast radius (read/write scope). For example, Spider-Man should not write to `CLAUDE*.md` and Black Panther should not write to `src/`. However, when agents are spawned with `bypassPermissions` (which is required for them to work -- see H-003), they can write anywhere. The blast radius rules are behavioral instructions in markdown files. An LLM that hallucinates or misunderstands its role will cheerfully violate them.
- **Impact**: Agent scope violations will occur in practice. A confused Spider-Man agent could overwrite CLAUDE.md. A Beast agent could accidentally modify source files. There is no runtime guard, file-system permission, or post-hoc validation to catch these violations.
- **Fix Complexity**: MEDIUM
- **Suggested Fix**: Add a post-execution validation step that diffs changes against the agent's allowed write paths and flags violations. Alternatively, use filesystem permissions (read-only mounts) if running in containers.

---

### H-008: aegis-team.sh Uses `claude -p` (Print Mode) Which Is Non-Interactive
- **Severity**: HIGH
- **Category**: Broken Promises
- **Finding**: The tmux orchestrator launches agents with `claude -p --dangerously-skip-permissions < prompt_file`. The `-p` flag puts Claude in "print mode" -- it reads stdin, produces one response, and exits. This means agents spawned via aegis-team.sh cannot have multi-turn interactions, cannot use tools iteratively, and cannot recover from errors. They get one shot to complete their work.
- **Impact**: Complex tasks that require multiple tool calls, iterative debugging, or file-based coordination will fail. The agent gets the prompt, generates one response, and the pane goes idle. The "poll for -done.md file" coordination mechanism also fails because agents are not running persistently.
- **Fix Complexity**: MEDIUM
- **Suggested Fix**: Replace `claude -p` with an interactive Claude Code session that receives the prompt as initial input. Alternatively, use the in-process Agent tool exclusively and deprecate the tmux shell approach.

---

## CATEGORY 2: MISSING CRITICAL FEATURES

### H-009: No Error Recovery When an Agent Crashes Mid-Task
- **Severity**: CRITICAL
- **Category**: Missing Features
- **Finding**: The safety document mentions "Dead agent detection: if an agent's tmux pane exits unexpectedly, log the failure and notify Captain America." But there is no implementation. If Spider-Man crashes halfway through writing three files, the codebase is left in a broken intermediate state. There is no rollback, no checkpoint, no recovery mechanism.
- **Impact**: A crashed agent leaves partial files, broken imports, half-written tests. The only recovery is manual intervention. In an "autonomous" L3/L4 system, this is catastrophic because the user may not be watching.
- **Fix Complexity**: HIGH
- **Suggested Fix**: Implement a checkpoint system: git stash or create a temporary branch before each agent starts work. If the agent fails, automatically revert to the checkpoint. Log the failure state for human review.

---

### H-010: No Token/Cost Tracking
- **Severity**: HIGH
- **Category**: Missing Features
- **Finding**: A full AEGIS pipeline with 12 agents, 4 using opus, 4 using sonnet, and 4 using haiku, could easily consume $50-200 in API credits per session. There is no cost tracking, no token counting, no budget limits, and no cost warnings. The `aegis-observe` skill is listed but there is no evidence it tracks actual API costs.
- **Impact**: Users will be shocked by their API bills. A runaway Nick Fury loop (even one iteration) spawning a full build team + QA team + compliance check could cost $100+ without warning. Enterprise users need cost visibility for budgeting.
- **Fix Complexity**: MEDIUM
- **Suggested Fix**: Integrate with Claude Code's token reporting. Track cumulative tokens per session in `_aegis-brain/logs/`. Display running cost estimate in the dashboard. Add a configurable budget ceiling that pauses execution when reached.

---

### H-011: Context Window Overflow Has No Real Handling
- **Severity**: HIGH
- **Category**: Missing Features
- **Finding**: CLAUDE_safety.md says "If context exceeds 60%, trigger a distillation step" and "If context exceeds 80%, enter emergency mode." But there is no mechanism to measure context usage accurately from within a Claude Code session. The `aegis-distill` skill exists but there is no automatic trigger -- it requires manual invocation. Claude Code does not expose a "current context percentage" API that agents can query.
- **Impact**: Sessions will hit context limits without warning, producing degraded output or truncated responses. The 12-agent system is particularly vulnerable because each spawned subagent consumes context from the parent. A build team alone (3 agents) could consume 50%+ of the parent's context just for the spawn prompts and results.
- **Fix Complexity**: HIGH
- **Suggested Fix**: Use heuristic estimation (count approximate tokens of loaded files + conversation). Add a hard check before spawning agents. Consider /compact as a pre-spawn step.

---

### H-012: Multi-Session Continuity Is Theoretical
- **Severity**: HIGH
- **Category**: Missing Features
- **Finding**: The handoff system relies on `_aegis-brain/resonance/` files and `_aegis-brain/logs/activity.log`. These are markdown files that the next session's `/aegis-start` reads. However, the resonance files are created once by the installer and contain only skeleton data. The actual handoff mechanism (/aegis-handoff is listed as a command but is not in the commands directory) is undefined.
- **Impact**: Starting a new session loses all working context. The resonance files give a vague project identity but none of the task-specific state (which files were being edited, what approach was being taken, what tests were failing). In practice, each session starts nearly from scratch.
- **Fix Complexity**: MEDIUM
- **Suggested Fix**: Implement `/aegis-handoff` as a real command that writes a structured state dump: current task, files touched, approach taken, blockers encountered, next steps. Make `/aegis-retro` actually update the resonance files with session-specific learnings, not just generic patterns.

---

### H-013: No Concurrent User Support
- **Severity**: MEDIUM
- **Category**: Missing Features
- **Finding**: There is no mechanism for two developers to use AEGIS on the same project simultaneously. The kanban board is a single markdown file. The activity log is a single file. The sprint state is a single directory. If Developer A moves TASK-003 to IN_PROGRESS while Developer B moves TASK-004, they will have merge conflicts in kanban.md.
- **Impact**: AEGIS is limited to single-developer use. Teams cannot share the framework state through git because concurrent edits to brain/sprint/kanban files will conflict.
- **Fix Complexity**: HIGH
- **Suggested Fix**: Use per-task files instead of a single kanban.md. Or use a proper database/API. For now, document this as a known limitation.

---

### H-014: No Rollback Mechanism When a Build Breaks
- **Severity**: HIGH
- **Category**: Missing Features
- **Finding**: The aegis-team-build command captures a `baseline_commit` in Step 1 (`git rev-parse HEAD`). Step 7 mentions "If FAIL -> list critical issues, do NOT suggest commit." But there is no automatic rollback. If Spider-Man writes 15 files and Black Panther says FAIL, those 15 broken files remain in the working directory. The user must manually `git checkout .` or `git stash` to recover.
- **Impact**: Failed builds leave the codebase in a dirty state. If the user does not notice the FAIL verdict (possible in autonomous mode), subsequent work builds on a broken foundation.
- **Fix Complexity**: LOW
- **Suggested Fix**: On FAIL verdict, automatically `git checkout -- .` the changed files or `git stash` the changes with a descriptive message. On CONDITIONAL, keep the files but warn prominently.

---

## CATEGORY 3: SECURITY AND SAFETY HOLES

### H-015: `--dangerously-skip-permissions` Is Required for Normal Operation
- **Severity**: CRITICAL
- **Category**: Security
- **Finding**: The GETTING_STARTED.md instructs users to run `claude --dangerously-skip-permissions` as the standard way to start AEGIS. The settings.json ships with `"defaultMode": "bypassPermissions"` and allows `Bash(rm:*)`, `Bash(curl:*)`, `Bash(wget:*)`. The safety document's command blocklist blocks `rm -rf /` but does NOT block `rm -rf src/`, `rm -rf _aegis-brain/`, or any other project-destructive command.
- **Impact**: Any agent can execute `rm -rf src/` and it will be allowed. A hallucinating agent could delete the entire source tree. The deny list only blocks the most catastrophic system-level commands but leaves project-level destruction wide open.
- **Fix Complexity**: MEDIUM
- **Suggested Fix**: Add project-specific deny rules: `Bash(rm -rf src:*)`, `Bash(rm -rf _aegis-brain:*)`. Better yet, implement a whitelist approach where destructive operations on project directories require explicit confirmation even in bypass mode.

---

### H-016: No Rate Limiting on Agent Spawning
- **Severity**: HIGH
- **Category**: Security
- **Finding**: There is no limit on how many agents can be spawned. Nick Fury could theoretically spawn a build team, then a QA team, then another build team, all in one session. Each TeamCreate or Agent call consumes tokens and potentially API rate limits. There is no maximum agent count, no cooldown, and no circuit breaker.
- **Impact**: Runaway agent spawning could exhaust API rate limits, consume massive token budgets, and degrade system performance. Combined with the lack of cost tracking (H-010), this is a recipe for surprise bills.
- **Fix Complexity**: LOW
- **Suggested Fix**: Add a configurable max_agents_per_session (default: 10) and max_concurrent_agents (default: 5) to the settings. Nick Fury should check these limits before spawning.

---

### H-017: Agents Can Execute Arbitrary Shell Commands
- **Severity**: HIGH
- **Category**: Security
- **Finding**: The settings.json allows `Bash(curl:*)` and `Bash(wget:*)`. Combined with `bypassPermissions`, an agent could `curl` arbitrary URLs, download and execute scripts, or exfiltrate project data. The safety document says "Shell command (dangerous: curl pipe sh, eval) | Block" but the actual deny list does not block `curl | sh` or `curl | bash` -- it only blocks a few specific rm patterns.
- **Impact**: A prompt-injected agent (via a malicious dependency or compromised file content) could exfiltrate code or download malware. The gap between the safety documentation and the actual settings.json is itself a security risk.
- **Fix Complexity**: MEDIUM
- **Suggested Fix**: Add deny rules for pipe-to-shell patterns. Restrict curl/wget to specific domains if possible. At minimum, log all network requests.

---

### H-018: No Infinite Loop Detection for Agents
- **Severity**: MEDIUM
- **Category**: Security
- **Finding**: The safety document mentions a 120-second status ping and 300-second escalation timeout. But these are behavioral instructions for Captain America, not system-level enforcement. If a Spider-Man agent enters an infinite compile-fix-compile loop, there is no watchdog to kill it. If Nick Fury re-spawns a failed team repeatedly, there is no circuit breaker.
- **Impact**: Token waste, API rate limit exhaustion, user frustration. A stuck agent will burn tokens until the session context is exhausted.
- **Fix Complexity**: MEDIUM
- **Suggested Fix**: Implement a retry counter. After 2 consecutive failures (as mentioned in Nick Fury's constraints), enforce the L1 downgrade programmatically, not just as a behavioral suggestion.

---

## CATEGORY 4: USER EXPERIENCE GAPS

### H-019: Version Number Mismatch Creates Confusion
- **Severity**: MEDIUM
- **Category**: User Experience
- **Finding**: CLAUDE.md says "AEGIS v6.0." CLAUDE_agents.md says "AEGIS v7.0." CLAUDE_skills.md says "AEGIS v7.0." The installer says `VERSION="6.0.0"`. The README and GETTING_STARTED say "AEGIS v7.0." The git commits reference both v6.0 and v7.0. There is no clear changelog or version boundary.
- **Impact**: Users do not know which version they are running. Documentation references may be wrong. The installer installs v6.0 skill lists but the documentation promises v7.0 features.
- **Fix Complexity**: LOW
- **Suggested Fix**: Unify all version references to v7.0. Update install.sh VERSION. Create a CHANGELOG.md documenting v6.0 -> v7.0 changes.

---

### H-020: First-Time User Experience Is Fragile
- **Severity**: HIGH
- **Category**: User Experience
- **Finding**: A new user must: (1) install Node.js, (2) install Claude Code CLI, (3) install tmux, (4) clone AEGIS-Team repo, (5) run install.sh with correct flags, (6) manually edit `~/.claude/settings.json` to set global bypassPermissions (workaround for bug #26479), (7) set CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS env var, (8) start claude with `--dangerously-skip-permissions`, (9) type `/aegis-start`. If ANY of steps 6-7 are missed, the team features silently fail. The installer does NOT verify step 6.
- **Impact**: High abandonment rate. Most users will fail at step 6 or 7 and get agents that cannot execute tools, with no clear error message explaining why.
- **Fix Complexity**: MEDIUM
- **Suggested Fix**: Add a `/aegis-doctor` command that verifies all prerequisites: env vars, global settings, CLI version, tmux availability. Run it automatically as part of `/aegis-start`.

---

### H-021: Error Messages Are Non-Existent for Command Failures
- **Severity**: MEDIUM
- **Category**: User Experience
- **Finding**: The commands are markdown instruction files, not executable scripts. They rely on the LLM correctly interpreting and executing each step. If Step 3 of `/aegis-sprint plan` fails (no backlog exists), the error handling section says "Create `_aegis-brain/backlog.md` with a header and prompt the user." But this is a behavioral instruction -- there is no try/catch, no error code, no structured error propagation. The LLM might or might not handle it gracefully.
- **Impact**: When things go wrong (and they will), users get vague LLM-generated explanations instead of actionable error messages. Debugging is difficult because the execution is non-deterministic.
- **Fix Complexity**: HIGH (architectural)
- **Suggested Fix**: For critical paths, implement actual shell scripts that validate preconditions before the LLM takes over. The install.sh approach (real bash with error handling) should be the model.

---

### H-022: Non-Technical PMs Cannot Use This
- **Severity**: MEDIUM
- **Category**: User Experience
- **Finding**: The framework requires terminal proficiency: tmux navigation, git concepts, shell environment variables, JSON file editing. The GETTING_STARTED guide assumes familiarity with `brew install`, `npm install -g`, shell rc files, and environment variables. There is no GUI, no web dashboard, no visual kanban board.
- **Impact**: AEGIS is limited to technical users who are comfortable in a terminal. The project management features (sprint, kanban, ISO docs) target PM activities but require developer-level tooling knowledge.
- **Fix Complexity**: HIGH
- **Suggested Fix**: This is a design choice, not a bug. But acknowledge it: AEGIS is for developer-PMs, not non-technical PMs. Consider a future web dashboard that renders `_aegis-brain/sprints/` state visually.

---

### H-023: Task ID Conflict Between Breakdown and Kanban
- **Severity**: MEDIUM
- **Category**: User Experience
- **Finding**: The work-breakdown skill generates task IDs as `T-NNN`. The kanban board uses `TASK-NNN`. The work-breakdown skill itself notes this mismatch: "When importing, map `T-NNN` to `TASK-NNN`." But there is no automatic mapping. If a user runs `/aegis-breakdown` and then `/aegis-sprint plan`, the IDs must be manually reconciled.
- **Impact**: Traceability breaks. The ISO 29110 traceability matrix references `T-NNN` from breakdown but `TASK-NNN` from kanban. A requirement traced to `T-005` cannot be automatically linked to `TASK-005` without a mapping table that does not exist.
- **Fix Complexity**: LOW
- **Suggested Fix**: Standardize on one ID format. Either use `T-NNN` everywhere or `TASK-NNN` everywhere. Update all templates and skills to match.

---

## CATEGORY 5: COMPETITIVE GAPS

### H-024: Overhead vs. Direct Claude Code Usage
- **Severity**: HIGH
- **Category**: Competitive
- **Finding**: For a simple bug fix (1-2 files), AEGIS requires: load CLAUDE.md, load brain resonance, scan project state, check planning artifacts, decide priority level, check if sprint exists, check kanban state. Only then does it start working. Direct Claude Code usage: describe the bug, agent fixes it. AEGIS adds 2-5 minutes of ceremony overhead to every task, regardless of size.
- **Impact**: For small tasks (which are 80% of development work), AEGIS is significantly slower and more expensive than using Claude Code directly. The threshold check in `/aegis-team-build` (solo mode for 1-2 files) is a band-aid that does not address the session startup overhead.
- **Fix Complexity**: MEDIUM
- **Suggested Fix**: Add a "quick mode" that skips all ceremony: `/aegis-quick "fix the auth bug"` that goes straight to Spider-Man without scanning, planning, or gate checks. Nick Fury's P0 (hotfix) path should skip planning artifacts entirely, not just note that they are missing.

---

### H-025: No Real-Time Progress Visibility Compared to Cursor/Windsurf
- **Severity**: MEDIUM
- **Category**: Competitive
- **Finding**: Cursor and Windsurf show real-time code diffs, inline suggestions, and visual progress. AEGIS shows a text dashboard and then says "Watch: tmux attach -t aegis-team." The user's feedback loop is: read markdown files, check tmux panes, parse agent logs. There are no visual diffs, no inline code previews, no progress bars.
- **Impact**: AEGIS feels "blind" compared to modern AI coding tools. The user cannot see what agents are doing until they are done.
- **Fix Complexity**: HIGH
- **Suggested Fix**: This is a fundamental limitation of the terminal-based approach. The in-process mode (Shift+Down to view agents) is better than tmux for visibility but still text-only. Long-term, a VS Code extension or web UI would close this gap.

---

### H-026: No Codebase Understanding Beyond File Scanning
- **Severity**: MEDIUM
- **Category**: Competitive
- **Finding**: Devin and similar tools build semantic models of codebases (call graphs, dependency trees, type hierarchies). AEGIS relies on `find`, `grep`, and `git diff` for codebase understanding. The Beast agent "gathers data" but produces lists of file paths and grep matches, not semantic understanding.
- **Impact**: AEGIS agents make worse architectural decisions because they lack deep codebase comprehension. Iron Man designs architectures based on file listings, not actual code structure.
- **Fix Complexity**: HIGH
- **Suggested Fix**: Integrate with language servers or AST parsers. Have Beast produce structured dependency graphs, not just file lists. This is a significant investment but would dramatically improve agent quality.

---

### H-027: AEGIS Adds Value for Medium-to-Large Tasks Only
- **Severity**: MEDIUM
- **Category**: Competitive
- **Finding**: The sweet spot for AEGIS is tasks that require coordination between architecture, implementation, review, and testing -- roughly 5-13 story points. For anything smaller, it is overhead. For anything larger, the context window limit (H-005, H-011) prevents completion in a single session. The useful operating range is narrow.
- **Impact**: Users must learn to judge task sizes and switch between direct Claude Code and AEGIS depending on complexity. This cognitive overhead reduces adoption.
- **Fix Complexity**: MEDIUM
- **Suggested Fix**: Make the transition seamless. If a user is in a plain Claude Code session and says "this is getting complex," they should be able to invoke `/aegis-team-build` without having run `/aegis-start` first. Remove the ceremony for team spawning.

---

## ADDITIONAL FINDINGS

### H-028: sprint-tracker.md Listed Twice in Skill Catalog
- **Severity**: LOW
- **Category**: Broken Promises
- **Finding**: CLAUDE_skills.md lists `sprint-manager` as skill #12 (standard profile) which "supersedes sprint-tracker." Then lists `sprint-tracker` as skill #26 (full profile, legacy). But install.sh only installs `sprint-tracker` (in standard_skills). The `sprint-manager` skill file does not exist -- the actual file at `skills/sprint-tracker.md` contains the sprint-manager content (based on its frontmatter `name: sprint-manager`). The naming is confused.
- **Impact**: Skill trigger matching may fail. A user asking for "sprint manager" may not load the right skill.
- **Fix Complexity**: LOW
- **Suggested Fix**: Rename the file to match the documented name, or update the documentation to match the filename.

---

### H-029: .gitignore Overwrites User's Existing .gitignore
- **Severity**: MEDIUM
- **Category**: User Experience
- **Finding**: install.sh uses `cat > "${TARGET_DIR}/.gitignore"` (overwrite, not append). Running install.sh on an existing project will destroy the user's custom .gitignore rules.
- **Impact**: User's existing ignore rules are silently deleted. This could cause secrets, build artifacts, or other sensitive files to be accidentally committed.
- **Fix Complexity**: LOW
- **Suggested Fix**: Check if `.gitignore` exists. If it does, append AEGIS-specific rules rather than overwriting. Or at minimum, back it up first.

---

### H-030: SendMessage Protocol Depends on Agent Cooperation
- **Severity**: MEDIUM
- **Category**: Broken Promises
- **Finding**: The build team pipeline (Iron Man -> Spider-Man -> Black Panther) relies on agents sending messages to each other: "When done, send a message to spider-man via SendMessage." This assumes agents will reliably execute SendMessage at the right time. If Iron Man completes but forgets to send the message (LLM non-determinism), Spider-Man waits indefinitely.
- **Impact**: Pipeline stalls with no timeout or fallback. The failure handling in aegis-team-build says "If stuck, send a nudge message" but this nudge depends on the orchestrator noticing the stall.
- **Fix Complexity**: MEDIUM
- **Suggested Fix**: Add a timeout mechanism. If agent B has not received a message from agent A within N seconds of A completing, auto-trigger. Use file-based signaling as a fallback (check for output files).

---

### H-031: The "12 Agents" Claim Is Misleading
- **Severity**: LOW
- **Category**: Competitive
- **Finding**: AEGIS advertises "12 agents" but they are not 12 independent AI instances. They are 12 different system prompts applied to Claude Code sessions. In in-process mode, they all run within the same parent context. In tmux mode, they are separate sessions but share no state except via files. The "agent" framing implies autonomous entities; the reality is prompt templates.
- **Impact**: Users expecting Devin-like autonomous agents will be disappointed. AEGIS agents are closer to "roles" or "modes" than true agents.
- **Fix Complexity**: LOW (documentation)
- **Suggested Fix**: Reframe as "12 specialized roles" or "12 expert personas." Set expectations correctly in marketing materials.

---

## RISK SUMMARY

| Severity | Count |
|----------|:-----:|
| CRITICAL | 4 |
| HIGH | 14 |
| MEDIUM | 11 |
| LOW | 2 |
| **TOTAL** | **31** |

## TOP 5 ACTIONS (Do These First)

1. **Fix install.sh** (H-001, H-002, H-029) -- The installer is broken for v7.0. This blocks ALL new users. Estimated effort: 1 hour.

2. **Unify team spawning** (H-004, H-008) -- Pick in-process Agent tool as default, deprecate tmux approach to experimental status. Estimated effort: 2 hours.

3. **Add /aegis-doctor** (H-020, H-003) -- A pre-flight diagnostic that checks ALL prerequisites before the user wastes time. Estimated effort: 2 hours.

4. **Implement checkpoint/rollback** (H-009, H-014) -- git stash before agent work, auto-revert on failure. Estimated effort: 3 hours.

5. **Unify version numbers** (H-019) -- A 10-minute find-and-replace that eliminates constant confusion.

---

## FINAL VERDICT

AEGIS v7.0 is an impressive architectural vision with significant execution gaps. The documentation is world-class; the implementation is incomplete. The framework will work for technical users who are willing to manually patch the installer, understand the workarounds for experimental APIs, and accept that "autonomous" means "one decision cycle per session."

It is NOT smoke and mirrors. The design thinking is genuine and valuable. But shipping it as "v7.0" when the installer cannot install v7.0 features is a credibility risk.

**Recommendation**: Fix the top 5 items, then do a honest v7.0 release. What exists today is v6.5 at best.

---

*Report generated by Loki (Devil's Advocate) on 2026-03-24*
*Total files reviewed: 35+ across CLAUDE*.md, agents, skills, commands, installer, and orchestrator*
