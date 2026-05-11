#!/usr/bin/env bash
# aegis-linear-bootstrap.sh — Initialize Linear integration in a FRESH repo.
#
# Use case: you just ran `git init` in a new project and want AEGIS to mirror
# its kanban to Linear. This script:
#
#   1. Verifies token exists in keychain (or env var)
#   2. Auto-discovers workspace + team + state map via Linear API
#   3. Writes .aegis/config/linear.json into target repo (project.id = null)
#   4. Adds .aegis/config/ to git tracking (whitelisted in .gitignore)
#   5. Prints next steps
#
# Project itself is auto-created on first /aegis-sprint plan (via ensure-project).
#
# Usage:
#   aegis-linear-bootstrap.sh                          # current repo
#   aegis-linear-bootstrap.sh /path/to/new-repo        # explicit target
#   aegis-linear-bootstrap.sh --throwaway              # mark as throwaway (skip Linear)
#   aegis-linear-bootstrap.sh --shared-with "Project"  # use existing umbrella project
#
# Exit codes:
#   0 = success
#   1 = fatal (no token, no team, network down)
#   2 = config already present (re-run with --force to overwrite)

set -uo pipefail

LINEAR_API="https://api.linear.app/graphql"
TARGET=""
THROWAWAY=false
SHARED_WITH=""
FORCE=false

while (( $# )); do
  case "$1" in
    --throwaway)   THROWAWAY=true ;;
    --shared-with) shift; SHARED_WITH="${1:-}" ;;
    --force)       FORCE=true ;;
    --help|-h)
      sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    -*)
      printf 'Unknown flag: %s\n' "$1" >&2
      exit 1
      ;;
    *)
      TARGET="$1"
      ;;
  esac
  shift
done

TARGET="${TARGET:-$PWD}"
[[ -d "$TARGET" ]] || { printf 'Target directory does not exist: %s\n' "$TARGET" >&2; exit 1; }
TARGET="$(cd "$TARGET" && pwd)"  # resolve to absolute

log()  { printf '[bootstrap] %s\n' "$*" >&2; }
ok()   { printf '[bootstrap] ✅ %s\n' "$*" >&2; }
warn() { printf '[bootstrap] ⚠️  %s\n' "$*" >&2; }
fail() { printf '[bootstrap] ❌ %s\n' "$*" >&2; exit 1; }

# ── deps ─────────────────────────────────────────────────────────────────────
command -v jq      >/dev/null || fail "jq required (brew install jq)"
command -v curl    >/dev/null || fail "curl required"
command -v python3 >/dev/null || fail "python3 required"

# ── token ────────────────────────────────────────────────────────────────────
TOKEN=""
if [[ -n "${LINEAR_API_TOKEN:-}" ]]; then
  TOKEN="$LINEAR_API_TOKEN"
  log "Token source: env var"
else
  TOKEN="$(security find-generic-password -s aegis-linear-token -a phariyawit -w 2>/dev/null || true)"
  [[ -n "$TOKEN" ]] && log "Token source: keychain (aegis-linear-token/phariyawit)"
fi
[[ -n "$TOKEN" ]] || fail "No Linear token found. Setup keychain first: security add-generic-password -s aegis-linear-token -a phariyawit -w <TOKEN>"

# ── target config path ───────────────────────────────────────────────────────
CONFIG_DIR="${TARGET}/.aegis/config"
CONFIG_FILE="${CONFIG_DIR}/linear.json"

if [[ -f "$CONFIG_FILE" && "$FORCE" != "true" ]]; then
  warn "Config already exists: $CONFIG_FILE"
  warn "Re-run with --force to overwrite (will reset project.id to null)"
  exit 2
fi

# ── GraphQL helper ───────────────────────────────────────────────────────────
gql() {
  local q="$1" v="${2:-{}}"
  curl -sS -X POST "$LINEAR_API" \
    -H "Authorization: $TOKEN" \
    -H "Content-Type: application/json" \
    --data "$(jq -nc --arg q "$q" --argjson v "$v" '{query:$q, variables:$v}')"
}

# ── 1. validate token + get viewer/org ───────────────────────────────────────
log "1/4  Validating token..."
viewer_resp="$(gql '{ viewer { id email displayName admin } organization { id name urlKey userCount } }')"
if echo "$viewer_resp" | jq -e '.errors' >/dev/null 2>&1; then
  fail "Token invalid or API down: $(echo "$viewer_resp" | jq -c '.errors')"
fi
viewer_id="$(echo "$viewer_resp" | jq -r '.data.viewer.id')"
viewer_email="$(echo "$viewer_resp" | jq -r '.data.viewer.email')"
viewer_name="$(echo "$viewer_resp" | jq -r '.data.viewer.displayName')"
viewer_admin="$(echo "$viewer_resp" | jq -r '.data.viewer.admin')"
org_id="$(echo "$viewer_resp" | jq -r '.data.organization.id')"
org_name="$(echo "$viewer_resp" | jq -r '.data.organization.name')"
org_key="$(echo "$viewer_resp" | jq -r '.data.organization.urlKey')"
org_users="$(echo "$viewer_resp" | jq -r '.data.organization.userCount')"
ok "Authenticated: $viewer_email @ $org_name ($org_users users)"

# ── 2. pick team (first one if only one exists) ──────────────────────────────
log "2/4  Discovering teams..."
teams_resp="$(gql '{ teams { nodes { id key name timezone } } }')"
team_count="$(echo "$teams_resp" | jq -r '.data.teams.nodes | length')"
[[ "$team_count" -gt 0 ]] || fail "No teams found in workspace"

if [[ "$team_count" -gt 1 ]]; then
  warn "Multiple teams found:"
  echo "$teams_resp" | jq -r '.data.teams.nodes[] | "  · \(.key) — \(.name)"' >&2
  warn "Using first team. To pick a different one, edit .aegis/config/linear.json manually after bootstrap."
fi

team_id="$(echo "$teams_resp" | jq -r '.data.teams.nodes[0].id')"
team_key="$(echo "$teams_resp" | jq -r '.data.teams.nodes[0].key')"
team_name="$(echo "$teams_resp" | jq -r '.data.teams.nodes[0].name')"
team_tz="$(echo "$teams_resp" | jq -r '.data.teams.nodes[0].timezone')"
ok "Team: $team_key / $team_name ($team_tz)"

# ── 3. fetch states + labels for this team ───────────────────────────────────
log "3/4  Fetching workflow states + labels..."
states_resp="$(gql "{ team(id: \"$team_id\") { states { nodes { id name type } } } }")"
labels_resp="$(gql "{ team(id: \"$team_id\") { labels { nodes { id name } } } }")"

# Helper: resolve state by type+name preference
state_id() {
  local prefer_name="$1" prefer_type="$2"
  echo "$states_resp" | jq -r \
    --arg n "$prefer_name" --arg t "$prefer_type" \
    '(.data.team.states.nodes[] | select(.name == $n) | .id) //
     (.data.team.states.nodes[] | select(.type == $t) | .id) //
     empty' | head -n1
}

s_backlog="$(state_id 'Backlog' 'backlog')"
s_todo="$(state_id 'Todo' 'unstarted')"
s_in_progress="$(state_id 'In Progress' 'started')"
s_in_review="$(state_id 'In Review' 'started')"
s_done="$(state_id 'Done' 'completed')"

ok "State map: BACKLOG / TODO / IN_PROGRESS / IN_REVIEW / DONE all resolved"

# Existing labels for reference
labels_json="$(echo "$labels_resp" | jq -c '[.data.team.labels.nodes[] | {(.name): .id}] | add // {}')"

# ── 4. write config ──────────────────────────────────────────────────────────
log "4/4  Writing config to $CONFIG_FILE..."
mkdir -p "$CONFIG_DIR"

today="$(date +'%Y-%m-%d')"
project_name=""
shared_field="null"

if [[ -n "$SHARED_WITH" ]]; then
  shared_field="$(jq -nc --arg s "$SHARED_WITH" '$s')"
  log "Mode: shared_with → $SHARED_WITH (no project will be auto-created)"
fi

throwaway_field="$THROWAWAY"
if [[ "$THROWAWAY" == "true" ]]; then
  log "Mode: throwaway → Linear sync DISABLED for this repo"
fi

cat > "$CONFIG_FILE" <<EOF
{
  "\$schema": "https://aegis-team.dev/schemas/linear-config-v1.json",
  "version": "1.1.0",
  "generated_at": "$today",
  "generated_by": "aegis-linear-bootstrap (fresh-repo init)",
  "_target_repo": "$TARGET",

  "auth": {
    "method": "api_key",
    "source_preferred": "keychain",
    "keychain": { "service": "aegis-linear-token", "account": "phariyawit" },
    "dotfile_fallback": "~/.aegis/secrets/linear.env",
    "env_var": "LINEAR_API_TOKEN"
  },

  "workspace": {
    "id": "$org_id",
    "url_key": "$org_key",
    "name": "$org_name",
    "url": "https://linear.app/$org_key"
  },

  "viewer": {
    "id": "$viewer_id",
    "email": "$viewer_email",
    "display_name": "$viewer_name",
    "admin": $viewer_admin
  },

  "team": {
    "id": "$team_id",
    "key": "$team_key",
    "name": "$team_name",
    "timezone": "$team_tz"
  },

  "project": {
    "id": null,
    "name": null,
    "name_from": "git_remote_slug",
    "auto_create_on_first_sync": true,
    "description_template": "Auto-synced from AEGIS framework kanban.md\\n\\nRepo: {git_remote_url}\\nDo not edit manually — AEGIS is single writer.",
    "throwaway": $throwaway_field,
    "shared_with": $shared_field
  },

  "sprint_mapping": {
    "strategy": "project_milestone",
    "milestone_name_format": "{sprint_id}",
    "milestone_description_template": "AEGIS Sprint {sprint_id}\\nGoal: {goal}\\nCapacity: {capacity}pt\\nKanban: {kanban_url}"
  },

  "state_map": {
    "BACKLOG":     { "id": "$s_backlog",     "name": "Backlog",     "type": "backlog" },
    "TODO":        { "id": "$s_todo",        "name": "Todo",        "type": "unstarted" },
    "IN_PROGRESS": { "id": "$s_in_progress", "name": "In Progress", "type": "started" },
    "IN_REVIEW":   { "id": "$s_in_review",   "name": "In Review",   "type": "started" },
    "QA":          { "id": "$s_in_review",   "name": "In Review",   "type": "started", "_alias_note": "aliased to In Review + qa label" },
    "DONE":        { "id": "$s_done",        "name": "Done",        "type": "completed" }
  },

  "labels": {
    "existing": $labels_json,
    "to_create": [
      { "name": "aegis", "color": "#5e6ad2", "purpose": "marks all AEGIS-synced issues" },
      { "name": "qa",    "color": "#f2c94c", "purpose": "QA-pending; pairs with In Review state" }
    ]
  },

  "sync_policy": {
    "direction": "aegis_to_linear_one_way",
    "source_of_truth": "kanban.md",
    "conflict_strategy": "aegis_wins",
    "circular_sync_guard": "<!-- aegis-sync:{story_id} -->",
    "issue_title_format": "[{story_id}] {title}",
    "description_footer": "\\n\\n---\\n🤖 Synced from AEGIS · sprint \`{sprint_id}\` · story \`{story_id}\` · do not edit manually",
    "drift_detection": { "enabled": true, "surfaces_in": "/aegis-status", "auto_merge": false }
  },

  "rate_limit": { "max_requests_per_minute": 20, "backoff_strategy": "exponential" },

  "health_check": {
    "run_on": ["aegis-start", "manual"]
  }
}
EOF

# Validate the JSON we just wrote
if ! jq empty "$CONFIG_FILE" 2>/dev/null; then
  fail "Wrote invalid JSON to $CONFIG_FILE — please report this bug"
fi
ok "Config written: $CONFIG_FILE ($(wc -c < "$CONFIG_FILE" | tr -d ' ') bytes)"

# ── Next steps ───────────────────────────────────────────────────────────────
echo "" >&2
echo "════════════════════════════════════════════════════════════════════" >&2
echo "  Bootstrap complete. Next steps:" >&2
echo "════════════════════════════════════════════════════════════════════" >&2
echo "" >&2
echo "  cd \"$TARGET\"" >&2

if [[ "$THROWAWAY" == "true" ]]; then
  echo "  # Throwaway flag set — no Linear sync will run." >&2
elif [[ -n "$SHARED_WITH" ]]; then
  echo "  # Will use existing project: $SHARED_WITH" >&2
  echo "  bash tools/aegis-linear-setup.sh health    # verify shared project exists" >&2
else
  echo "  bash tools/aegis-linear-setup.sh health    # should report YELLOW (project not yet created)" >&2
  echo "  # On first /aegis-sprint plan, project will auto-create with name = git remote slug." >&2
  echo "  # To customize name, edit .aegis/config/linear.json → project.name (before first sync)." >&2
fi

echo "" >&2
echo "  Workspace: https://linear.app/$org_key" >&2
echo "" >&2
