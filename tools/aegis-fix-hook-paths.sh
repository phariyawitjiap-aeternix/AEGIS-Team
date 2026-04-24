#!/usr/bin/env bash
# aegis-fix-hook-paths.sh — anchor hook commands to $CLAUDE_PROJECT_DIR
#
# ROOT CAUSE:
#   .claude/settings.json hook commands use RELATIVE paths like:
#     "bash .claude/hooks/run-with-flags.sh guard-bash .claude/hooks/guard-bash.sh"
#   When Claude Code fires a hook (Stop, PostToolUse, etc.) from a sub-agent
#   or background process whose cwd is not the repo root, bash cannot find
#   ".claude/hooks/run-with-flags.sh" and the hook fails with:
#     bash: .claude/hooks/run-with-flags.sh: No such file or directory
#
# FIX:
#   Rewrite every command to anchor paths to ${CLAUDE_PROJECT_DIR}, which
#   Claude Code sets to the absolute project root for every hook invocation.
#   After:
#     "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/run-with-flags.sh\" guard-bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/guard-bash.sh\""
#
# WHEN TO RUN:
#   BETWEEN sessions (guard-write.sh blocks mid-session edits to settings.json
#   per ADR-004). Close Claude Code, run this script, restart Claude Code.
#
# SAFETY:
#   - Creates timestamped backup: .claude/settings.json.pre-hook-path-fix-<ts>
#   - Uses jq for structural edits (won't break JSON)
#   - Validates resulting JSON before overwriting
#   - Idempotent: running twice is a no-op (detects already-anchored paths)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SETTINGS="$REPO_ROOT/.claude/settings.json"
TS=$(date -u +"%Y-%m-%dT%H%M%SZ")
BACKUP="$SETTINGS.pre-hook-path-fix-$TS"

# ---------- Preflight ----------
[[ -f "$SETTINGS" ]] || { echo "ERROR: $SETTINGS not found" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "ERROR: jq required (brew install jq)" >&2; exit 1; }

# Warn if Claude Code is running (best-effort)
if pgrep -f "claude.*code\|claude-code" >/dev/null 2>&1; then
    echo "⚠️  Claude Code appears to be running. Close it first." >&2
    echo "    (Mid-session settings.json edits are blocked by guard-write.sh.)" >&2
    read -rp "    Continue anyway? [y/N] " ans
    [[ "$ans" == "y" || "$ans" == "Y" ]] || exit 1
fi

# ---------- Idempotency check ----------
if grep -q 'CLAUDE_PROJECT_DIR/.claude/hooks' "$SETTINGS"; then
    if ! grep -qE '"command": "bash \.claude/hooks' "$SETTINGS"; then
        echo "✓ Hook paths already anchored to \$CLAUDE_PROJECT_DIR. Nothing to do."
        exit 0
    fi
fi

# ---------- Backup ----------
cp "$SETTINGS" "$BACKUP"
echo "📦 Backup: $BACKUP"

# ---------- Apply fix via jq ----------
# For each hook type and matcher, rewrite .command if it starts with "bash .claude/hooks/..."
python3 - "$SETTINGS" <<'PYEOF'
import json, sys, re

path = sys.argv[1]
with open(path) as f:
    data = json.load(f)

PREFIX_RUN = "bash .claude/hooks/"
ANCHOR = 'bash "$CLAUDE_PROJECT_DIR/.claude/hooks/'

def rewrite(cmd):
    if not isinstance(cmd, str):
        return cmd
    if not cmd.startswith(PREFIX_RUN):
        return cmd
    # Case A: wrapper pattern
    #   bash .claude/hooks/run-with-flags.sh <hook_id> .claude/hooks/<hook>.sh
    # Case B: direct pattern
    #   bash .claude/hooks/<hook>.sh
    # Strategy: replace every ".claude/hooks/<something>.sh" literal with the anchored form.
    def sub(m):
        inner = m.group(0)
        return f'"$CLAUDE_PROJECT_DIR/{inner}"'
    new = re.sub(r'\.claude/hooks/[A-Za-z0-9_.\-]+\.sh', sub, cmd)
    # Also replace the leading "bash " still points at a bare path; normalize to bash "...full..."
    # Current state after sub: `bash "$CLAUDE_PROJECT_DIR/.claude/hooks/run-with-flags.sh" guard-bash "$CLAUDE_PROJECT_DIR/..."`
    # That's what we want. The `bash .claude/...` prefix has been rewritten because the first regex hit matches.
    return new

changed = 0
for event, entries in data.get("hooks", {}).items():
    for entry in entries:
        for h in entry.get("hooks", []):
            old = h.get("command", "")
            new = rewrite(old)
            if new != old:
                h["command"] = new
                changed += 1

with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")

print(f"✏️  Rewrote {changed} hook command(s)")
PYEOF

# ---------- Validate ----------
if ! jq . "$SETTINGS" >/dev/null 2>&1; then
    echo "❌ Validation FAILED — restoring backup" >&2
    cp "$BACKUP" "$SETTINGS"
    exit 2
fi

echo ""
echo "✅ Hook paths anchored to \$CLAUDE_PROJECT_DIR"
echo "   Restart Claude Code to pick up the new settings."
echo ""
echo "   To roll back:"
echo "     cp '$BACKUP' '$SETTINGS'"
