---
name: aegis-doctor
description: "Post-install health check — validates all 10 active agents (+ _archived/), teams, references, and brain structure"
triggers:
  en: doctor, health check, verify install, check agents, validate aegis
  th: ตรวจสุขภาพ, เช็คติดตั้ง, ตรวจ agent
---

# /aegis-doctor

## Quick Reference
Validates AEGIS installation: checks all agent model IDs, required fields, tool lists,
cross-references, team files, and brain directory structure. Read-only — never modifies files.
Reads `VERSION` file to discover the installed framework version.

## Full Instructions

### Step 1: Print Header
```
🩺 AEGIS DOCTOR — Health Check
Timestamp: [current UTC]
AEGIS Version: [read from ./VERSION]
```
If `VERSION` file is missing, report `unknown` and flag as 🟡 Warning (installer
was supposed to place it -- see install-remote.sh).

### Step 2: Validate Agent Files

For each file in `.claude/agents/*.md` (NOT `.claude/agents/_archived/*.md` --
those are retired and shouldn't count against the active roster):

1. Read frontmatter (`name`, `model`, `tools`, `disallowedTools`, `description`)
2. Check `name` matches filename (without `.md`) → 🔴 if mismatch
3. Check `model` is one of:
   - `claude-opus-4-6`, `claude-opus-4-7`
   - `claude-sonnet-4-6`
   - `claude-haiku-4-5-20251001`
   → 🔴 Critical if invalid
4. Check `tools` is non-empty array → 🟡 Warning if missing
5. Check no tool appears in both `tools` AND `disallowedTools` → 🔴 if conflict
6. Check `## Constraints` section exists → 🔴 if missing
7. Check `## Output Location` section exists → 🟡 if missing
8. Collect result: `✅ PASS` / `🟡 WARN` / `🔴 FAIL`

**Expected count (v9 model)**: 10 active agents — beast, black-panther,
captain-america, coulson, iron-man, loki, nick-fury, spider-man, thor,
war-machine. Report the active-vs-archived split:
```
ACTIVE AGENTS (N/10):  [list]
ARCHIVED AGENTS (M):   [list from _archived/ — Vision, Wasp, Songbird expected
                        in a v8-to-v9 upgrade]
```

If active count != 10, flag 🟡 Warning ("unexpected roster size; may be an
in-flight consolidation or drift").

### Step 3: Validate Team Files

For each file in `.claude/teams/`:

1. Extract all `subagent_type:` values
2. For each value: check matching file exists in `.claude/agents/`
3. 🔴 Critical if any subagent_type has no matching agent file

### Step 4: Validate Reference Files

Check these files exist in `.claude/references/`:
- quality-protocol.md
- context-rules.md
- adaptive-thinking-guide.md
- context-editing-protocol.md
- autonomy-levels.md
- message-types.md

→ 🟡 Warning for each missing file

### Step 5: Validate Brain Structure (v9 layout)

Check these paths exist:
- `.aegis/brain/` (root dir — 🔴 Critical if missing; v8 repos need manual
  `mv _aegis-brain .aegis/brain` or `--upgrade` which auto-migrates)
- `.aegis/brain/resonance/` (🔴 if missing)
- `.aegis/brain/tasks/` (🟡 if empty; empty is OK for new projects with no
  work yet)
- `.aegis/brain/sprints/current/kanban.md` (🟡 if missing; ditto)
- `_aegis-output/iso-docs/PM-01-project-plan/` (🟡 if missing)
- `_aegis-output/iso-docs/SI-01-requirements-spec/` (🟡 if missing)
- `_aegis-output/iso-docs/SI-02-traceability-matrix/` (🟡 if missing)

**Note**: `.aegis/brain/logs/activity.log` is **gitignored in v9** and will be
created lazily by the session-start hook. Don't flag its absence as
critical — treat as 🟡 only if `.aegis/brain/logs/` the directory is also
missing. A missing file inside an existing logs/ dir is normal between
sessions.

**v8 compatibility probe**: if the v9 layout doesn't exist, check for the
legacy `_aegis-brain/` path. If found, report 🔴 with message "v8 layout
detected; run `--upgrade` to migrate" instead of the generic critical.

→ 🔴 Critical for `.aegis/brain/` root or `.aegis/brain/resonance/` missing
→ 🔴 Critical for v8 `_aegis-brain/` present without v9 `.aegis/brain/`
→ 🟡 Warning for empty tasks/sprints/kanban (project may be brand new)
→ 🟡 Warning for missing iso-docs paths

### Step 6: Print Summary

```
ACTIVE AGENTS (N/10 checked)
  ✅/🟡/🔴 [name]  [model]  tools=N  constraints=N
ARCHIVED AGENTS (M)
  [names from _archived/ -- Vision/Wasp/Songbird expected post-v9]

TEAMS ([N] files checked)
  ✅/🔴 [team-name]

REFERENCES ([N]/6 present)
  ✅/🟡 [filename]

BRAIN STRUCTURE (v9 layout)
  ✅/🟡/🔴 [path]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
OVERALL: [✅ PASS | 🟡 WARN | 🔴 FAIL]
  Critical: N  |  Warnings: N  |  Checks: N
```

### Step 7: Write Report

Write full report to: `_aegis-output/research/YYYY-MM-DD_aegis-doctor.md`

### Step 8: If Any Critical Failures

Print:
```
🔴 ACTION REQUIRED:
  Run: bash <(curl -sL .../install-remote.sh) --upgrade
  Or fix manually — see report at _aegis-output/research/YYYY-MM-DD_aegis-doctor.md
```

### Gate Logic

| Verdict | Condition |
|---------|-----------|
| ✅ PASS | 0 critical, 0 warnings |
| 🟡 WARN | 0 critical, 1+ warnings |
| 🔴 FAIL | 1+ critical findings |
