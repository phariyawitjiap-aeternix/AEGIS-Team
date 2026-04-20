# Sprint v9-04 Integration Guide

> Apply these changes between sessions (guard-write.sh protects hook files mid-session).

## Step 1: Install Session Start Hook

```bash
# From repo root:
cp tools/v9-session-start-hook.sh .claude/hooks/session-start.sh
chmod +x .claude/hooks/session-start.sh
```

## Step 2: Update settings.json SessionStart

Replace the current SessionStart hook entry in `.claude/settings.json`:

```json
"SessionStart": [
  {
    "hooks": [
      {
        "type": "command",
        "command": "bash .claude/hooks/session-start.sh"
      }
    ]
  }
]
```

This replaces the standalone `aegis-version-check.sh` call with the combined
session-start hook that runs both version check AND brain sync.

## Step 3: Verify

After restarting Claude Code:

```bash
# Should pass validation
./tools/aegis-brain-sync.sh --validate

# Should show fresh MEMORY.md
cat .aegis/brain/MEMORY.md

# Should show session-start log entry
tail -3 .aegis/brain/logs/activity.log
```

## What This Enables

After installation, every Claude Code session will:
1. Check version consistency across files (S1-03)
2. Validate brain directory structure
3. Regenerate MEMORY.md index (fresh for memory_20250818 cache layer)
4. Log session start with brain statistics

## New Tools Available

| Tool | Usage | Purpose |
|------|-------|---------|
| `tools/aegis-brain-sync.sh` | `./tools/aegis-brain-sync.sh` | Regenerate MEMORY.md from brain state |
| `tools/aegis-brain-sync.sh --validate` | Validate brain structure | Check all required dirs/files exist |
| `tools/aegis-brain-sync.sh --dry-run` | Preview MEMORY.md | Show what would be generated |
| `tools/aegis-brain-write.sh <path> <content>` | Write to brain | Write file + regenerate MEMORY.md + log |
| `source tools/aegis-brain-write.sh` | Library mode | Provides brain_write() and brain_append() functions |

## Still Deferred (S4-02)

The `memory_20250818` cache layer integration requires Claude Code SDK access.
When available, the brain_write() function in aegis-brain-write.sh has a clearly
marked Step 4 placeholder for adding the cache write call.
