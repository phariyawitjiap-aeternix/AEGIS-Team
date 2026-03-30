---
name: aegis-doctor
description: "Post-install verification — checks all AEGIS components are present and healthy"
triggers:
  en: doctor, health check, verify install, diagnose
  th: ตรวจสุขภาพ, เช็คระบบ, วินิจฉัย
---

# /aegis-doctor

## Quick Reference
Run 14 diagnostic checks to verify AEGIS installation is complete and healthy.
Reports PASS/WARN/FAIL for each check with remediation hints.
Use after install, upgrade, or when something seems broken.

## Full Instructions

Run ALL checks below. Display results as a table. Do NOT stop on first failure.

### Check 1: Core Files
Verify these files exist:
```
CLAUDE.md, CLAUDE_agents.md, CLAUDE_skills.md, CLAUDE_safety.md, CLAUDE_lessons.md
```
PASS: All 5 exist | FAIL: List missing files

### Check 2: Agent Files (13)
Verify `.claude/agents/` contains exactly 13 .md files:
```
mother-brain, navi, sage, bolt, vigil, havoc, forge, pixel, muse, sentinel, probe, scribe, ops
```
PASS: 13/13 | WARN: <13 | FAIL: directory missing

### Check 3: Command Files (24)
Count `.claude/commands/*.md` files.
PASS: >= 23 | WARN: 20-22 | FAIL: < 20

### Check 4: Skill Files (25)
Count `skills/*.md` files.
PASS: >= 25 | WARN: 20-24 | FAIL: < 20

### Check 5: Reference Files (11)
Count `.claude/references/*.md` files.
PASS: >= 11 | WARN: 8-10 | FAIL: < 8

### Check 6: Team Files (6)
Count `.claude/teams/*.md` files.
PASS: >= 6 | WARN: 4-5 | FAIL: < 4

### Check 7: Brain Directory Structure
Verify these directories exist:
```
_aegis-brain/tasks, _aegis-brain/sprints, _aegis-brain/resonance,
_aegis-brain/learnings, _aegis-brain/logs, _aegis-brain/metrics,
_aegis-brain/skill-cache, _aegis-brain/handoffs, _aegis-brain/backlog
```
PASS: All 9 exist | WARN: 7-8 | FAIL: < 7

### Check 8: Counters File
Verify `_aegis-brain/counters.json` exists and has valid JSON with `project_key` and `counters` fields.
PASS: Valid JSON with correct schema | WARN: Exists but malformed | FAIL: Missing

### Check 9: Output Directory Structure
Verify these directories exist:
```
_aegis-output/specs, _aegis-output/breakdown, _aegis-output/qa,
_aegis-output/iso-docs, _aegis-output/reviews, _aegis-output/sessions
```
PASS: All 6 exist | WARN: 4-5 | FAIL: < 4

### Check 10: Settings File
Verify `.claude/settings.json` exists and contains `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` env var.
PASS: Exists with agent teams enabled | WARN: Exists without agent teams | FAIL: Missing

### Check 11: Git Status
Check: `git status --short`
PASS: Clean working tree | WARN: Uncommitted changes | INFO: Not a git repo

### Check 12: ISO Document Templates
Verify `_aegis-output/iso-docs/` has at least PM-01 and SI-01 directories.
PASS: >= 6 ISO doc directories | WARN: 1-5 | FAIL: 0 or missing

### Check 13: Version Consistency
Read version from CLAUDE.md header, compare with:
- README.md badge
- project-identity.md
- update-protocol.md CURRENT VERSION
PASS: All match | WARN: 1 mismatch | FAIL: 2+ mismatches

### Check 14: Dashboard (optional)
Check if `dashboard/` directory exists with `package.json`.
PASS: Dashboard installed | SKIP: Not installed (optional component)

### Output Format

```
🏥 AEGIS Doctor — Installation Diagnostic
═══════════════════════════════════════════

  #   Check                    Status    Detail
  ──  ───────────────────────  ────────  ──────────────────
   1  Core Files               ✅ PASS   5/5 files present
   2  Agent Files              ✅ PASS   13/13 agents
   3  Command Files            ✅ PASS   24/23 commands
   4  Skill Files              ✅ PASS   25/25 skills
   5  Reference Files          ✅ PASS   11/11 references
   6  Team Files               ✅ PASS   6/6 teams
   7  Brain Directories        ✅ PASS   9/9 directories
   8  Counters File            ✅ PASS   Valid schema
   9  Output Directories       ✅ PASS   6/6 directories
  10  Settings File            ✅ PASS   Agent teams enabled
  11  Git Status               ⚠️ WARN   3 uncommitted files
  12  ISO Documents            ✅ PASS   11/6 doc directories
  13  Version Consistency      ✅ PASS   v8.3 everywhere
  14  Dashboard                ✅ PASS   Installed at dashboard/

═══════════════════════════════════════════
  Result: 13 PASS | 1 WARN | 0 FAIL
  Status: ✅ HEALTHY
═══════════════════════════════════════════
```

If any FAIL:
```
  ❌ UNHEALTHY — Run these to fix:
  • Missing agents: bash install.sh --upgrade
  • Missing brain dirs: mkdir -p _aegis-brain/{tasks,sprints,resonance,...}
  • Missing counters: /aegis-start will auto-create
```
