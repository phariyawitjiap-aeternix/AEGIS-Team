<!-- version: 1.0.0 -->
<!-- Last updated: 2026-05-06 -->

# settings.json Patch — sprint-v12-04 PostToolUse hook

## Why this is a separate file (not auto-applied)

The guard-write hook from `.claude/hooks/guard-write.sh` blocks mid-session edits to `.claude/settings.json` (AEGIS self-protection). This is intentional — modifying hook wiring while a session is running can destabilize the running hook chain.

The patch below must be applied **between sessions**, not from inside Claude Code.

## Apply

In a fresh terminal (no Claude Code session running):

```bash
cd ~/Documents/AEGIS-Team   # or your AEGIS root

# Backup
cp .claude/settings.json .claude/settings.json.pre-v12-04-backup

# Patch — adds the graph-build hook to PostToolUse Edit/Write/MultiEdit
python3 - <<'EOF'
import json, sys
with open('.claude/settings.json') as f:
    s = json.load(f)
post = s['hooks']['PostToolUse']
for entry in post:
    if entry.get('matcher') == 'Edit|Write|MultiEdit':
        cmds = entry['hooks']
        target = 'tools/aegis-brain-graph/hook.sh'
        if not any(target in h.get('command', '') for h in cmds):
            cmds.append({
                'type': 'command',
                'command': 'bash "$CLAUDE_PROJECT_DIR/tools/aegis-brain-graph/hook.sh"'
            })
            print('+ added graph-build hook to PostToolUse Edit|Write|MultiEdit')
        else:
            print('= graph-build hook already present')
        break
else:
    print('! could not find PostToolUse Edit|Write|MultiEdit matcher')
    sys.exit(1)
with open('.claude/settings.json', 'w') as f:
    json.dump(s, f, indent=2)
    f.write('\n')
EOF

# Verify
jq '.hooks.PostToolUse[] | select(.matcher=="Edit|Write|MultiEdit")' .claude/settings.json
```

## Patch as YAML diff (manual reference)

```diff
   "PostToolUse": [
     ...
     {
       "matcher": "Edit|Write|MultiEdit",
       "hooks": [
         {
           "type": "command",
           "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/run-with-flags.sh\" post-edit-accumulate \"$CLAUDE_PROJECT_DIR/.claude/hooks/post-edit-accumulate.sh\""
+        },
+        {
+          "type": "command",
+          "command": "bash \"$CLAUDE_PROJECT_DIR/tools/aegis-brain-graph/hook.sh\""
         }
       ]
     },
     ...
   ]
```

## Rollback

```bash
cp .claude/settings.json.pre-v12-04-backup .claude/settings.json
```

## See also

- `.claude/hooks/guard-write.sh` — the protection that blocked mid-session apply
- `tools/aegis-brain-graph/hook.sh` — the actual hook (debounced, fail-OPEN)
- v11 precedent: `tools/settings-mbp-guard.json` (sprint-v10-04) used the same between-session pattern
