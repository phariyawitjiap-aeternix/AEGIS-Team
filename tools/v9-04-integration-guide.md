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

### Supported shells

CLI mode always runs under `bash` via the shebang, regardless of the caller's
shell. Library mode (`source tools/aegis-brain-write.sh`) is tested under both
`bash` and `zsh` — the script detects the host shell and avoids bash-only
constructs (`BASH_SOURCE`) in the zsh path. Regression guard lives in
`tools/aegis-brain-adversarial-test.sh` Scenario G.

Note: sourcing the script also applies `set -euo pipefail` to the caller's
shell as a side effect. For one-shot invocations (`source ... && brain_append ...`)
this is harmless; avoid sourcing it into long-lived interactive shells.

## S4-02 SDK Availability -- Honest Blocker Assessment (2026-04-20)

### What we tried

1. **Agent definition declares it**: `.claude/agents/nick-fury.md` frontmatter lists
   `memory_20250818` in the `tools:` array. This is aspirational -- it tells Claude Code
   "this agent should have memory access" but does not guarantee the runtime surfaces it.

2. **Runtime check**: The top-level agent (Nick Fury running as the human's direct session)
   has access to: Read, Write, Edit, Bash, Glob, Grep, WebFetch, WebSearch, Agent, and
   MCP tools (computer-use). `memory_20250818` is NOT in the available tool set.

3. **No MCP server exists**: `.claude/settings.json` and `.claude/settings.local.json`
   contain no MCP configuration for a memory server. There is no `mcp__memory__*` tool.

4. **Claude's internal memory**: Claude does have a `/memories` directory concept at the
   model level, but this is NOT exposed as a callable tool in Claude Code CLI. The
   `memory_20250818` identifier appears in Anthropic documentation as a model-level
   feature, not a tool-use API that agents can invoke via JSON schema.

### Why it can't be wired right now

`memory_20250818` is a **model-level capability** (Claude's built-in cross-session memory),
not a **tool-use API** that can be called from bash scripts or agent tool invocations.
The brain-write.sh Step 4 placeholder envisions calling it as a tool, but no such tool
endpoint exists in the current Claude Code SDK.

### What would need to change

For S4-02 to complete, ONE of these must happen:

- **Option A**: Anthropic exposes `memory_20250818` as a callable tool in Claude Code's
  agent runtime (not just a model feature). The agent would then call it like any other tool.
- **Option B**: An MCP server wraps the memory system and exposes read/write operations.
  We would add this to settings.json as an MCP endpoint.
- **Option C**: We implement our own file-based memory cache that mimics the memory tool's
  behavior (read-through cache of .aegis/brain/ files at session start). This is what
  MEMORY.md already accomplishes -- the "cache" is just the index file that gets read
  on session start.

### Current state (what works today)

The file-based system already provides 90% of the value:
- MEMORY.md is regenerated on every brain write and session start
- Agents read MEMORY.md to get the brain index
- File system is authoritative (per ADR-002)
- The only missing piece is cross-session in-memory warmth (pre-loading brain into
  Claude's context without explicit file reads). This happens naturally when agents
  read MEMORY.md at session start.

### Recommendation

Mark S4-02 as **BLOCKED (SDK dependency)** with Option C (current MEMORY.md system)
as the de facto implementation. The file-based approach works. The memory_20250818
wiring is a nice-to-have optimization, not a functional gap.

## S4-02 Proxy Pattern (thin implementation, 2026-04-20)

Since `memory_20250818` is unreachable from subagent runtimes, `brain_write` emits a
structured directive on stdout that the main orchestrator (which DOES have the tool)
can parse and action on the subagent's behalf.

### Directive format

Every `brain_write` call emits exactly one line of the form:

```
AEGIS_MEMORY_WRITE: {"path":"<brain-relative>","subtype":"<mapped>","bytes":<n>,"timestamp":"<iso8601>"}
```

The subtype comes from `path_to_subtype()` (e.g., `learning`, `resonance`,
`instinct-promoted`, `handoff`). Unknown paths map to `unknown`.

### Main-agent processing (orchestration pseudocode)

When the main agent spawns a subagent and the subagent uses `brain_write`, the
subagent's final result will contain these directive lines. To replay them into
`memory_20250818`:

```bash
# Extract all directives from a subagent's stdout result
echo "$SUBAGENT_OUTPUT" | grep -oE 'AEGIS_MEMORY_WRITE: \{[^}]*\}' | while read -r line; do
    payload=$(echo "$line" | sed 's|^AEGIS_MEMORY_WRITE: ||')
    path=$(echo "$payload"    | python3 -c 'import sys,json;print(json.loads(sys.stdin.read())["path"])')
    subtype=$(echo "$payload" | python3 -c 'import sys,json;print(json.loads(sys.stdin.read())["subtype"])')
    content=$(cat ".aegis/brain/${path}")
    # Pseudocode for the actual write -- the main agent calls memory_20250818 directly:
    #   memory_20250818.write(content, type='project', subtype=subtype)
done
```

### What this is and isn't

- **Is**: a stable protocol for subagent → main-agent memory propagation, usable today
  without SDK access in subagents. Directives are harmless when ignored (extra stdout
  lines) and actionable when parsed.
- **Isn't**: a full cache implementation. The main agent still has to do the
  `memory_20250818.write` call itself; this pattern just routes the intent.
- **Isn't**: used automatically yet. Nick Fury's dispatch loop would need an opt-in
  "process memory directives" step after each subagent returns. That wiring is a
  future session's work.

### Additive, not replacing the file layer

The file is still authoritative (per ADR-002). The directive is a hint to warm the
cache; losing the hint costs nothing (next `/aegis-start` regenerates MEMORY.md from
the file system).
