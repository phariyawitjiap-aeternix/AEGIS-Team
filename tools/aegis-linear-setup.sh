#!/usr/bin/env bash
# aegis-linear-setup.sh — Bootstrap and verify the AEGIS ↔ Linear connection.
#
# Subcommands:
#   init                         — one-time setup wizard (validates token, discovers IDs, writes config)
#   health                       — read-only health check (called by /aegis-start; exit 0=ok, 2=warn, 3=action)
#   ensure-project               — idempotent: create Linear project if missing, write id back to config
#   ensure-milestone <sprint_id> — idempotent: create milestone for sprint, write id to sprint metadata
#   test                         — dry-run end-to-end test (no writes to Linear)
#
# Exit codes:
#   0 = success / healthy
#   1 = fatal error (token missing, network down, etc.)
#   2 = warning (degraded but functional)
#   3 = action required from user (e.g. project needs creation but auto-create disabled)
#
# Design refs:
#   - .aegis/config/linear.json — source of truth for IDs and policy
#   - sync_policy.direction = aegis_to_linear_one_way (no reverse sync from Linear)
#   - sprint_mapping.strategy = project_milestone (NOT cycles — cross-project leak risk)
#   - auth: keychain first, env var fallback (never logged, never echoed)

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_PATH="${REPO_ROOT}/.aegis/config/linear.json"
LINEAR_API="https://api.linear.app/graphql"

# ──────────────────────────────────────────────────────────────────────────────
# Helpers
# ──────────────────────────────────────────────────────────────────────────────

log()   { printf '[linear-setup] %s\n' "$*" >&2; }
warn()  { printf '[linear-setup] ⚠️  %s\n' "$*" >&2; }
fail()  { printf '[linear-setup] ❌ %s\n' "$*" >&2; exit 1; }
ok()    { printf '[linear-setup] ✅ %s\n' "$*" >&2; }

require_jq()     { command -v jq      >/dev/null || fail "jq not installed (brew install jq)"; }
require_curl()   { command -v curl    >/dev/null || fail "curl not installed"; }
require_python() { command -v python3 >/dev/null || fail "python3 not installed"; }

load_token() {
  # Priority: env var → keychain → dotfile
  if [[ -n "${LINEAR_API_TOKEN:-}" ]]; then
    printf '%s' "$LINEAR_API_TOKEN"
    return
  fi

  local svc acct
  svc="$(jq -r '.auth.keychain.service' "$CONFIG_PATH")"
  acct="$(jq -r '.auth.keychain.account' "$CONFIG_PATH")"
  local kc_token
  kc_token="$(security find-generic-password -s "$svc" -a "$acct" -w 2>/dev/null || true)"
  if [[ -n "$kc_token" ]]; then
    printf '%s' "$kc_token"
    return
  fi

  local dotfile
  dotfile="$(jq -r '.auth.dotfile_fallback' "$CONFIG_PATH")"
  dotfile="${dotfile/#\~/$HOME}"
  if [[ -f "$dotfile" ]]; then
    # shellcheck disable=SC1090
    source "$dotfile" 2>/dev/null
    if [[ -n "${LINEAR_API_TOKEN:-}" ]]; then
      printf '%s' "$LINEAR_API_TOKEN"
      return
    fi
  fi

  fail "Linear token not found (keychain svc=$svc acct=$acct, dotfile=$dotfile, env=LINEAR_API_TOKEN)"
}

# graphql_call <query> [variables_json]
graphql_call() {
  local query="$1"
  local vars="${2:-}"
  [[ -z "$vars" ]] && vars='{}'
  local token
  token="$(load_token)"
  local payload
  payload="$(jq -nc --arg q "$query" --argjson v "$vars" '{query:$q,variables:$v}')"
  curl -sS -X POST "$LINEAR_API" \
    -H "Authorization: $token" \
    -H "Content-Type: application/json" \
    --data "$payload"
}

git_remote_slug() {
  # github.com/x/AEGIS-Team.git → AEGIS-Team
  # falls back to basename of repo root
  local url slug
  url="$(git -C "$REPO_ROOT" config --get remote.origin.url 2>/dev/null || true)"
  if [[ -z "$url" ]]; then
    basename "$REPO_ROOT"
    return
  fi
  slug="${url##*/}"
  slug="${slug%.git}"
  printf '%s' "$slug"
}

# Atomic write to config: jq filter, replace file.
config_update() {
  local filter="$1"
  local tmp
  tmp="$(mktemp)"
  jq "$filter" "$CONFIG_PATH" > "$tmp" && mv "$tmp" "$CONFIG_PATH"
}

# ──────────────────────────────────────────────────────────────────────────────
# Subcommand: health
# ──────────────────────────────────────────────────────────────────────────────

cmd_health() {
  log "Health check starting..."
  local issues=0 warnings=0

  # 1. Config file exists
  if [[ ! -f "$CONFIG_PATH" ]]; then
    warn "Config missing: $CONFIG_PATH (run: aegis-linear-setup init)"
    return 3
  fi
  ok "Config file present"

  # 2. Token resolves
  local token
  if ! token="$(load_token 2>/dev/null)"; then
    warn "Token not resolvable"
    return 1
  fi
  ok "Token resolved (length=${#token})"

  # 3. /viewer query succeeds
  local resp
  resp="$(graphql_call '{ viewer { id email } organization { id name } }')"
  if echo "$resp" | jq -e '.errors' >/dev/null 2>&1; then
    warn "API call failed: $(echo "$resp" | jq -c '.errors')"
    return 1
  fi
  local email org
  email="$(echo "$resp" | jq -r '.data.viewer.email')"
  org="$(echo "$resp" | jq -r '.data.organization.name')"
  ok "Authenticated as $email @ $org"

  # 4. Team reachable
  local team_id
  team_id="$(jq -r '.team.id' "$CONFIG_PATH")"
  resp="$(graphql_call "{ team(id: \"$team_id\") { id key name } }")"
  if echo "$resp" | jq -e '.data.team' >/dev/null 2>&1; then
    ok "Team reachable: $(echo "$resp" | jq -r '.data.team.key') / $(echo "$resp" | jq -r '.data.team.name')"
  else
    warn "Team unreachable (team_id=$team_id)"
    issues=$((issues+1))
  fi

  # 5. Project exists or is creatable
  local project_id
  project_id="$(jq -r '.project.id // empty' "$CONFIG_PATH")"
  if [[ -z "$project_id" ]]; then
    if [[ "$(jq -r '.project.auto_create_on_first_sync' "$CONFIG_PATH")" == "true" ]]; then
      warn "Project not yet created — will auto-create on next /aegis-sprint plan"
      warnings=$((warnings+1))
    else
      warn "Project missing AND auto_create disabled → action required"
      issues=$((issues+1))
    fi
  else
    resp="$(graphql_call "{ project(id: \"$project_id\") { id name state } }")"
    if echo "$resp" | jq -e '.data.project' >/dev/null 2>&1; then
      ok "Project linked: $(echo "$resp" | jq -r '.data.project.name') ($(echo "$resp" | jq -r '.data.project.state'))"
    else
      warn "Configured project_id no longer exists: $project_id"
      issues=$((issues+1))
    fi
  fi

  # 6. Throwaway flag
  if [[ "$(jq -r '.project.throwaway' "$CONFIG_PATH")" == "true" ]]; then
    warn "Repo flagged as throwaway → Linear sync is DISABLED"
    return 2
  fi

  log "Summary: issues=$issues warnings=$warnings"
  if (( issues > 0 )); then return 1; fi
  if (( warnings > 0 )); then return 2; fi
  return 0
}

# ──────────────────────────────────────────────────────────────────────────────
# Subcommand: ensure-project (idempotent auto-create)
# ──────────────────────────────────────────────────────────────────────────────

cmd_ensure_project() {
  local existing_id
  existing_id="$(jq -r '.project.id // empty' "$CONFIG_PATH")"

  # Throwaway short-circuit
  if [[ "$(jq -r '.project.throwaway' "$CONFIG_PATH")" == "true" ]]; then
    log "Throwaway flag set → skipping project creation"
    return 0
  fi

  # Shared project override
  local shared
  shared="$(jq -r '.project.shared_with // empty' "$CONFIG_PATH")"
  if [[ -n "$shared" ]]; then
    log "shared_with=$shared → resolving by name..."
    local team_id
    team_id="$(jq -r '.team.id' "$CONFIG_PATH")"
    local resp
    resp="$(graphql_call "{ team(id: \"$team_id\") { projects(filter: {name: {eq: \"$shared\"}}) { nodes { id name } } } }")"
    local pid
    pid="$(echo "$resp" | jq -r '.data.team.projects.nodes[0].id // empty')"
    if [[ -z "$pid" ]]; then
      fail "shared_with project '$shared' not found in team"
    fi
    config_update ".project.id = \"$pid\" | .project.name = \"$shared\""
    ok "Linked to shared project: $shared ($pid)"
    return 0
  fi

  # Already linked?
  if [[ -n "$existing_id" ]]; then
    log "Project already linked (id=$existing_id) — skip"
    return 0
  fi

  # Auto-create
  local auto
  auto="$(jq -r '.project.auto_create_on_first_sync' "$CONFIG_PATH")"
  if [[ "$auto" != "true" ]]; then
    warn "auto_create_on_first_sync=false and no project linked → run: aegis-linear-setup init"
    return 3
  fi

  local name
  name="$(git_remote_slug)"
  local team_id
  team_id="$(jq -r '.team.id' "$CONFIG_PATH")"
  local remote_url
  remote_url="$(git -C "$REPO_ROOT" config --get remote.origin.url 2>/dev/null || printf '(no remote)')"
  local desc
  desc="$(jq -r '.project.description_template' "$CONFIG_PATH" \
            | sed "s|{git_remote_url}|$remote_url|g")"

  log "Creating Linear project: '$name' in team $team_id"
  local mutation='mutation Create($input: ProjectCreateInput!) { projectCreate(input: $input) { success project { id name url } } }'
  local vars
  vars="$(jq -nc --arg n "$name" --arg t "$team_id" --arg d "$desc" \
            '{input: {name: $n, teamIds: [$t], description: $d}}')"
  local resp
  resp="$(graphql_call "$mutation" "$vars")"
  if echo "$resp" | jq -e '.errors' >/dev/null 2>&1; then
    fail "projectCreate failed: $(echo "$resp" | jq -c '.errors')"
  fi
  local pid purl
  pid="$(echo "$resp" | jq -r '.data.projectCreate.project.id')"
  purl="$(echo "$resp" | jq -r '.data.projectCreate.project.url')"
  config_update ".project.id = \"$pid\" | .project.name = \"$name\""
  ok "Created project: $name"
  ok "URL: $purl"
}

# ──────────────────────────────────────────────────────────────────────────────
# Subcommand: ensure-milestone <sprint_id>
# ──────────────────────────────────────────────────────────────────────────────

cmd_ensure_milestone() {
  local sprint_id="${1:-}"
  [[ -n "$sprint_id" ]] || fail "ensure-milestone requires <sprint_id>"

  cmd_ensure_project  # make sure project exists first

  local project_id
  project_id="$(jq -r '.project.id' "$CONFIG_PATH")"
  [[ "$project_id" != "null" && -n "$project_id" ]] || fail "project.id missing after ensure-project"

  # Check existing milestones
  local resp
  resp="$(graphql_call "{ project(id: \"$project_id\") { projectMilestones { nodes { id name targetDate } } } }")"
  local existing
  existing="$(echo "$resp" | jq -r --arg n "$sprint_id" '.data.project.projectMilestones.nodes[] | select(.name == $n) | .id' | head -n1)"
  if [[ -n "$existing" ]]; then
    log "Milestone '$sprint_id' already exists (id=$existing) — skip"
    printf '%s' "$existing"
    return 0
  fi

  # Read sprint plan/close for goal/capacity/dates
  local sprint_dir="${REPO_ROOT}/.aegis/brain/sprints/${sprint_id}"
  local plan="${sprint_dir}/plan.md"
  local close="${sprint_dir}/close.md"
  local goal="(plan.md missing or no Goal section)"
  local capacity=""
  local target_date=""

  if [[ -f "$plan" ]]; then
    # Goal: first non-blank line under "## Goal" header
    goal="$(awk '/^## Goal/{flag=1; next} flag && NF>0 && !/^##/{print; exit}' "$plan" 2>/dev/null || true)"
    [[ -z "$goal" ]] && goal="(no Goal section in plan.md)"
    # Capacity from "**Total points**: Npt"
    capacity="$(grep -iE '^\*\*Total points\*\*:' "$plan" 2>/dev/null | head -n1 | sed -E 's/.*: *([0-9]+)pt.*/\1/' || true)"
  fi

  # Target date priority: close.md Date closed → plan.md Date target → plan.md Date opened + 7d
  if [[ -f "$close" ]]; then
    target_date="$(grep -iE '^\*\*Date closed\*\*:' "$close" 2>/dev/null | head -n1 | sed -E 's/.*: *([0-9]{4}-[0-9]{2}-[0-9]{2}).*/\1/' || true)"
  fi
  if [[ -z "$target_date" && -f "$plan" ]]; then
    target_date="$(grep -iE '^\*\*Date target\*\*:' "$plan" 2>/dev/null | head -n1 | sed -E 's/.*: *([0-9]{4}-[0-9]{2}-[0-9]{2}).*/\1/' || true)"
    if [[ -z "$target_date" ]]; then
      local opened
      opened="$(grep -iE '^\*\*Date opened\*\*:' "$plan" 2>/dev/null | head -n1 | sed -E 's/.*: *([0-9]{4}-[0-9]{2}-[0-9]{2}).*/\1/' || true)"
      if [[ -n "$opened" ]]; then
        target_date="$(date -j -v+7d -f '%Y-%m-%d' "$opened" '+%Y-%m-%d' 2>/dev/null || echo "$opened")"
      fi
    fi
  fi

  local cap_line
  if [[ -n "$capacity" ]]; then cap_line="Capacity: ${capacity}pt"; else cap_line="Capacity: (not declared)"; fi
  local date_line
  if [[ -n "$target_date" ]]; then date_line="Target date: ${target_date}"; else date_line="Target date: (none)"; fi

  local desc
  desc="AEGIS Sprint ${sprint_id}
Goal: ${goal}
${cap_line}
${date_line}
Kanban: .aegis/brain/sprints/${sprint_id}/kanban.md"

  log "Creating milestone '$sprint_id' in project $project_id (targetDate=${target_date:-none})"
  local mutation='mutation Create($input: ProjectMilestoneCreateInput!) { projectMilestoneCreate(input: $input) { success projectMilestone { id name } } }'
  local vars
  if [[ -n "$target_date" ]]; then
    vars="$(jq -nc --arg n "$sprint_id" --arg p "$project_id" --arg d "$desc" --arg t "$target_date" \
              '{input: {name: $n, projectId: $p, description: $d, targetDate: $t}}')"
  else
    vars="$(jq -nc --arg n "$sprint_id" --arg p "$project_id" --arg d "$desc" \
              '{input: {name: $n, projectId: $p, description: $d}}')"
  fi
  resp="$(graphql_call "$mutation" "$vars")"
  if echo "$resp" | jq -e '.errors' >/dev/null 2>&1; then
    fail "projectMilestoneCreate failed: $(echo "$resp" | jq -c '.errors')"
  fi
  local mid
  mid="$(echo "$resp" | jq -r '.data.projectMilestoneCreate.projectMilestone.id')"
  ok "Created milestone: $sprint_id ($mid)"
  printf '%s' "$mid"
}

# ──────────────────────────────────────────────────────────────────────────────
# Subcommand: test (dry-run, read-only)
# ──────────────────────────────────────────────────────────────────────────────

cmd_test() {
  log "Dry-run test (read-only)..."
  cmd_health
  local h=$?
  case $h in
    0) ok "Health: GREEN" ;;
    2) warn "Health: YELLOW (warnings)" ;;
    *) warn "Health: RED (issues exit=$h)" ;;
  esac

  local slug
  slug="$(git_remote_slug)"
  log "git remote slug: $slug"
  log "If ensure-project ran now, project would be named: $slug"

  log "Existing sprints (most recent 5):"
  ls -1t "${REPO_ROOT}/.aegis/brain/sprints/" 2>/dev/null \
    | grep -E '^sprint-' \
    | head -5 \
    | sed 's/^/  · /'
}

# ──────────────────────────────────────────────────────────────────────────────
# Subcommand: init (interactive — not used in autopilot)
# ──────────────────────────────────────────────────────────────────────────────

cmd_init() {
  log "init: validating token + discovering workspace..."
  if [[ ! -f "$CONFIG_PATH" ]]; then
    fail "Config not present yet — bootstrap workflow has not been run. Re-run /aegis-start in a fresh project."
  fi
  cmd_health
  local h=$?
  if (( h == 0 || h == 2 )); then
    ok "init complete — health passed"
  else
    fail "init failed health check (exit=$h)"
  fi
}

# ──────────────────────────────────────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────────────────────────────────────

main() {
  require_curl
  require_jq
  require_python
  local sub="${1:-help}"
  shift || true
  case "$sub" in
    health)           cmd_health "$@" ;;
    init)             cmd_init "$@" ;;
    ensure-project)   cmd_ensure_project "$@" ;;
    ensure-milestone) cmd_ensure_milestone "$@" ;;
    test)             cmd_test "$@" ;;
    help|--help|-h)
      sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'
      ;;
    *)
      printf 'Unknown subcommand: %s\n' "$sub" >&2
      printf 'Run: %s help\n' "$(basename "$0")" >&2
      exit 1
      ;;
  esac
}

main "$@"
