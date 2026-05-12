#!/usr/bin/env bash
# tools/aegis-dump.sh
# ────────────────────────────────────────────────────────────────────────────
# Shareable redacted setup summary. Adapted from Hermes `hermes dump`.
#
# Sprint:  v14-03 (S14-03-01)
#
# Usage:
#   aegis-dump.sh                # default — redacted
#   aegis-dump.sh --show-keys    # show last-4 of API keys (still redacted)
#   aegis-dump.sh --json         # machine-readable
#
# Output is paste-safe to Discord/Slack/GitHub issues for support.
# ────────────────────────────────────────────────────────────────────────────

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

SHOW_KEYS=0
JSON_OUT=0

for arg in "$@"; do
    case "$arg" in
        --show-keys) SHOW_KEYS=1 ;;
        --json)      JSON_OUT=1 ;;
        --help|-h)
            cat <<EOF
Usage: aegis-dump.sh [--show-keys] [--json]

Prints a shareable redacted summary of this AEGIS install:
  - framework version, worktree state
  - hooks profile, agents/commands/skills counts
  - brain stats (sprints, decisions, index)
  - external keys (set/not-set; --show-keys shows last 4 chars)
  - recent activity (last 5 JSONL entries)

Default output excludes all secrets. Paste-safe for support requests.
EOF
            exit 0
            ;;
    esac
done

# ─── Collect facts ───────────────────────────────────────────────────────────
VERSION="$(cat VERSION 2>/dev/null || echo unknown)"
OS="$(uname -srm 2>/dev/null || echo unknown)"
SHELL_NAME="$(basename "${SHELL:-unknown}")"

# Git state
GIT_BRANCH="$(git branch --show-current 2>/dev/null || echo '(no-git)')"
GIT_STATUS="clean"
if [[ -d .git ]] || git rev-parse --git-dir >/dev/null 2>&1; then
    DIRTY=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$DIRTY" -gt 0 ]]; then GIT_STATUS="dirty (${DIRTY} files)"; fi
fi

# Worktree
WORKTREE_PATH="$(pwd)"
WORKTREE_NAME="$(basename "$WORKTREE_PATH")"
IS_WORKTREE="no"
if [[ "$WORKTREE_PATH" == *".claude/worktrees/"* ]]; then IS_WORKTREE="yes"; fi

# Hooks profile
HOOK_PROFILE="$(node -e "
try {
  const j = JSON.parse(require('fs').readFileSync('.claude/settings.json','utf-8'));
  console.log(j.env?.AEGIS_HOOK_PROFILE || 'standard');
} catch(e) { console.log('(no settings.json)'); }
" 2>/dev/null || echo unknown)"

# Counts
AGENT_COUNT=$(ls .claude/agents/*.md 2>/dev/null | wc -l | tr -d ' ')
TEAM_COUNT=$(ls .claude/teams/*.md 2>/dev/null | wc -l | tr -d ' ')
CMD_COUNT=$(ls .claude/commands/*.md 2>/dev/null | wc -l | tr -d ' ')
SKILL_COUNT=$(ls skills/*.md 2>/dev/null | wc -l | tr -d ' ')
HOOK_COUNT=$(ls .claude/hooks/*.sh 2>/dev/null | wc -l | tr -d ' ')
TOOL_COUNT=$(find tools -maxdepth 1 -type f -name "*.sh" 2>/dev/null | wc -l | tr -d ' ')

# Brain stats
BRAIN_SPRINT_COUNT=$(ls -d .aegis/brain/sprints/sprint-* 2>/dev/null | wc -l | tr -d ' ')
DECISION_COUNT=$(wc -l < .aegis/brain/logs/decision-audit.log 2>/dev/null | tr -d ' ' || echo 0)
LEARNING_COUNT=$(find .aegis/brain/learnings -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
HANDOFF_COUNT=$(find .aegis/brain/handoffs -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')

# Brain index
INDEX_TS="(no-index)"
INDEX_SIZE="0"
if [[ -f .aegis/brain/index.db ]]; then
    if command -v stat >/dev/null 2>&1; then
        # macOS / BSD stat first, then GNU stat fallback
        INDEX_TS=$(stat -f '%Sm' -t '%Y-%m-%dT%H:%M:%SZ' .aegis/brain/index.db 2>/dev/null \
                   || stat -c '%y' .aegis/brain/index.db 2>/dev/null \
                   | head -c 19 \
                   || echo '?')
    fi
    INDEX_SIZE=$(du -h .aegis/brain/index.db 2>/dev/null | cut -f1 || echo '?')
fi

# Human queue (single integer — grep -c always prints a number)
HUMAN_QUEUE_PENDING=0
if [[ -f .aegis/brain/human-queue.md ]]; then
    HUMAN_QUEUE_PENDING=$(awk '/<!-- PENDING_START -->/,/<!-- PENDING_END -->/' .aegis/brain/human-queue.md 2>/dev/null \
                        | grep -cE '^- \[' | head -1)
    HUMAN_QUEUE_PENDING="${HUMAN_QUEUE_PENDING:-0}"
fi

# Checkpoint store
CKPT_COMMITS=0
CKPT_SIZE="0"
if [[ -d .aegis/.brain-checkpoints/store/.git ]]; then
    CKPT_COMMITS=$(cd .aegis/.brain-checkpoints/store && git rev-list --count HEAD 2>/dev/null || echo 0)
    CKPT_SIZE=$(du -sh .aegis/.brain-checkpoints 2>/dev/null | cut -f1 || echo '?')
fi

# External keys — redacted check
key_status() {
    local var_name="$1"
    local val="${!var_name:-}"
    if [[ -z "$val" ]]; then
        echo "not-set"
    elif [[ "$SHOW_KEYS" = "1" ]]; then
        local last4="${val: -4}"
        echo "set (...${last4})"
    else
        echo "set (redacted)"
    fi
}

LINEAR_KEY=$(key_status LINEAR_API_KEY)
GH_TOKEN=$(key_status GITHUB_TOKEN)
ANTHROPIC_KEY=$(key_status ANTHROPIC_API_KEY)

# Recent activity
RECENT_ACTIVITY=""
if [[ -f .aegis/brain/logs/activity.log ]]; then
    RECENT_ACTIVITY=$(tail -5 .aegis/brain/logs/activity.log 2>/dev/null | head -5)
fi

# ─── Output ──────────────────────────────────────────────────────────────────
if [[ "$JSON_OUT" = "1" ]]; then
    # JSON output
    cat <<JSON
{
  "version": "$VERSION",
  "os": "$OS",
  "shell": "$SHELL_NAME",
  "worktree": {
    "name": "$WORKTREE_NAME",
    "path": "$WORKTREE_PATH",
    "is_worktree": "$IS_WORKTREE"
  },
  "git": {
    "branch": "$GIT_BRANCH",
    "status": "$GIT_STATUS"
  },
  "hooks": {"profile": "$HOOK_PROFILE", "count": $HOOK_COUNT},
  "counts": {
    "agents": $AGENT_COUNT,
    "teams": $TEAM_COUNT,
    "commands": $CMD_COUNT,
    "skills": $SKILL_COUNT,
    "tools": $TOOL_COUNT
  },
  "brain": {
    "sprints": $BRAIN_SPRINT_COUNT,
    "decisions": $DECISION_COUNT,
    "learnings": $LEARNING_COUNT,
    "handoffs": $HANDOFF_COUNT,
    "index_size": "$INDEX_SIZE",
    "index_last_modified": "$INDEX_TS",
    "human_queue_pending": $HUMAN_QUEUE_PENDING,
    "checkpoint_commits": $CKPT_COMMITS,
    "checkpoint_size": "$CKPT_SIZE"
  },
  "keys": {
    "LINEAR_API_KEY": "$LINEAR_KEY",
    "GITHUB_TOKEN": "$GH_TOKEN",
    "ANTHROPIC_API_KEY": "$ANTHROPIC_KEY"
  }
}
JSON
else
    # Plain text output (paste-safe)
    cat <<EOF
--- aegis dump ---
version:        $VERSION
os:             $OS
shell:          $SHELL_NAME
worktree:       $WORKTREE_NAME ($WORKTREE_PATH)
                is_worktree=$IS_WORKTREE
git:            branch=$GIT_BRANCH  status=$GIT_STATUS
hooks:          profile=$HOOK_PROFILE  count=$HOOK_COUNT
counts:         agents=$AGENT_COUNT  teams=$TEAM_COUNT  commands=$CMD_COUNT  skills=$SKILL_COUNT  tools=$TOOL_COUNT
brain:          sprints=$BRAIN_SPRINT_COUNT  decisions=$DECISION_COUNT  learnings=$LEARNING_COUNT  handoffs=$HANDOFF_COUNT
brain_index:    size=$INDEX_SIZE  last_modified=$INDEX_TS
human_queue:    pending=$HUMAN_QUEUE_PENDING
checkpoints:    commits=$CKPT_COMMITS  size=$CKPT_SIZE
keys:           LINEAR_API_KEY=$LINEAR_KEY
                GITHUB_TOKEN=$GH_TOKEN
                ANTHROPIC_API_KEY=$ANTHROPIC_KEY
recent_activity:
$(printf '%s' "$RECENT_ACTIVITY" | sed 's/^/  /')
--- end dump ---
EOF
fi
