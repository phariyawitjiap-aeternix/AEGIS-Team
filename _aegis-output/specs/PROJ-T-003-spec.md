# Spec: PROJ-T-003 — Post-install Verification Command (/aegis-doctor)

> Author: Sage | Date: 2026-03-30 | Task: PROJ-T-003 (5pts)

## Purpose

Provide a `/aegis-doctor` command that validates an AEGIS installation is complete and
functional. After `install.sh` runs, users need a quick way to verify everything was
installed correctly. This is the "health check" for the framework itself.

## Requirements

1. Check that all required directories exist (as created by install.sh)
2. Check that all required files exist (CLAUDE*.md, settings.json, agents, commands, references, teams)
3. Check that counters.json exists and is valid JSON
4. Check that skills are installed for the current profile
5. Check that ISO 29110 document templates are installed
6. Check external dependencies (git, tmux, claude CLI, CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS)
7. Check brain state health (resonance files, logs directory)
8. Produce a summary report with PASS/WARN/FAIL per check category
9. Give an overall health verdict (HEALTHY / DEGRADED / BROKEN)

## Output Format

```
AEGIS Doctor — Installation Health Check
=========================================

[PASS] Core files (5/5)
[PASS] Directory structure (18/18)
[PASS] Agent definitions (N files)
[PASS] Commands (N files)
[PASS] References (N files)
[PASS] Team configs (N files)
[PASS] Skills installed (N files, profile: full)
[PASS] ISO 29110 templates (11/11 directories)
[PASS] counters.json valid
[PASS] Brain resonance files present
[WARN] tmux not found — team split-pane unavailable
[PASS] git found
[PASS] claude CLI found
[PASS] CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1

Verdict: HEALTHY (13/14 checks passed, 1 warning)

Recommendation: Install tmux for full team experience
  brew install tmux (macOS) | apt install tmux (Linux)
```

## Implementation

- File: `.claude/commands/aegis-doctor.md` (Claude Code command format)
- The command is a prompt-based diagnostic — it reads files and directories, then reports
- No shell script needed; the command instructs Claude to perform the checks inline
- Must match the command format used by other aegis-* commands (YAML frontmatter + markdown body)

## Checks Catalog

| # | Category | What to check | PASS condition | FAIL condition |
|---|----------|---------------|----------------|----------------|
| 1 | Core files | CLAUDE.md, CLAUDE_safety.md, CLAUDE_agents.md, CLAUDE_skills.md, CLAUDE_lessons.md | All 5 exist | Any missing |
| 2 | Directories | All dirs from install.sh directories array | All exist | Any missing |
| 3 | Agent defs | .claude/agents/*.md | At least 1 file | Empty directory |
| 4 | Commands | .claude/commands/*.md | At least 1 file | Empty directory |
| 5 | References | .claude/references/*.md | At least 1 file | Empty directory |
| 6 | Team configs | .claude/teams/*.md | At least 1 file | Empty directory |
| 7 | Skills | skills/*.md | Count matches profile expectation | Missing skills |
| 8 | ISO templates | _aegis-output/iso-docs/*/  | 11 directories | Any missing |
| 9 | counters.json | _aegis-brain/counters.json | Exists + valid JSON | Missing or malformed |
| 10 | Brain resonance | _aegis-brain/resonance/*.md | At least project-state.md | Missing |
| 11 | git | `git --version` | Available | Not found |
| 12 | tmux | `tmux -V` | Available | WARN (not FAIL) |
| 13 | claude CLI | `claude --version` | Available | Not found |
| 14 | Env var | CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS | Set to "1" | Not set (WARN) |

## Verdict Logic

- HEALTHY: All checks PASS (warnings OK)
- DEGRADED: 1-3 checks FAIL (non-critical)
- BROKEN: 4+ checks FAIL, or any critical check fails (Core files, counters.json)

## Acceptance Criteria

- [x] Command file exists at `.claude/commands/aegis-doctor.md`
- [ ] Running `/aegis-doctor` produces the health check report
- [ ] All 14 check categories are verified
- [ ] Verdict is calculated correctly
- [ ] Missing items produce actionable fix suggestions
- [ ] Works on fresh install and upgrade scenarios
