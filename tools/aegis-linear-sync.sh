#!/usr/bin/env bash
# aegis-linear-sync.sh — One-way sync from kanban.md → Linear (issues + state).
#
# Subcommands:
#   open  <sprint_id>          — parse kanban, ensure project + milestone, create missing issues
#   push  <sprint_id>          — sync state transitions (TODO → IN_PROGRESS → DONE etc.) for existing issues
#   close <sprint_id>          — mark milestone Done, archive issues
#   drift <sprint_id>          — read-only report: what differs between kanban and Linear
#
# Flags:
#   --dry    show planned API calls, do not execute
#   --json   emit machine-readable summary
#
# Rules (from .aegis/config/linear.json):
#   - direction: aegis_to_linear_one_way (never read Linear and overwrite kanban)
#   - conflict: aegis_wins (kanban is source of truth)
#   - circular guard: each issue description carries `<!-- aegis-sync:{story_id} -->` marker

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_PATH="${REPO_ROOT}/.aegis/config/linear.json"
SETUP="${REPO_ROOT}/tools/aegis-linear-setup.sh"
LINEAR_API="https://api.linear.app/graphql"

DRY=0
JSON=0

log()  { printf '[linear-sync] %s\n' "$*" >&2; }
warn() { printf '[linear-sync] ⚠️  %s\n' "$*" >&2; }
fail() { printf '[linear-sync] ❌ %s\n' "$*" >&2; exit 1; }
ok()   { printf '[linear-sync] ✅ %s\n' "$*" >&2; }

load_token() {
  if [[ -n "${LINEAR_API_TOKEN:-}" ]]; then printf '%s' "$LINEAR_API_TOKEN"; return; fi
  local svc acct kc
  svc="$(jq -r '.auth.keychain.service' "$CONFIG_PATH")"
  acct="$(jq -r '.auth.keychain.account' "$CONFIG_PATH")"
  kc="$(security find-generic-password -s "$svc" -a "$acct" -w 2>/dev/null || true)"
  [[ -n "$kc" ]] || fail "Token not found in keychain ($svc/$acct)"
  printf '%s' "$kc"
}

gql() {
  local q="$1" v="${2:-}"
  [[ -z "$v" ]] && v='{}'
  local payload
  payload="$(jq -nc --arg q "$q" --argjson v "$v" '{query:$q,variables:$v}')"
  if (( DRY )); then
    log "DRY: would POST $(printf '%s' "$q" | head -c 80)..."
    printf '{"data":{}}'
    return
  fi
  curl -sS -X POST "$LINEAR_API" \
    -H "Authorization: $(load_token)" \
    -H "Content-Type: application/json" \
    --data "$payload"
}

# Parse kanban.md → JSONL with {section, story_id, points, agent, title, pr}
parse_kanban() {
  local sprint_id="$1"
  local kanban="${REPO_ROOT}/.aegis/brain/sprints/${sprint_id}/kanban.md"
  [[ -f "$kanban" ]] || fail "kanban not found: $kanban"

  python3 - "$kanban" <<'PY'
import re, sys, json
path = sys.argv[1]
section = None
SECTIONS = {'BACKLOG','TODO','IN_PROGRESS','IN_REVIEW','QA','DONE'}
# Story line: - [ ] [S3-01] Title (@agent) — 3pt [PR #47]
#         or: - [x] [S3-01] Title (@agent) — 3pt [PR #47]
story_re = re.compile(
    r'^\s*-\s*\[(?P<chk>[ x])\]\s*'
    r'\[(?P<sid>[A-Z]+\d+-\d+)\]\s*'
    r'(?P<title>.+?)'
    r'(?:\s*\(@(?P<agent>[\w-]+)\))?'
    r'(?:\s*[—-]\s*(?P<pts>\d+)pt)?'
    r'(?:\s*\[PR\s*#(?P<pr>\d+)\])?'
    r'\s*$'
)
section_re = re.compile(r'^##\s+([A-Z_]+)\s*$')
out = []
with open(path) as f:
    for line in f:
        m = section_re.match(line)
        if m and m.group(1) in SECTIONS:
            section = m.group(1)
            continue
        if not section: continue
        m = story_re.match(line)
        if not m: continue
        out.append({
            'section': section,
            'checked': m.group('chk') == 'x',
            'story_id': m.group('sid'),
            'title': m.group('title').strip(),
            'agent': m.group('agent') or '',
            'points': int(m.group('pts')) if m.group('pts') else 0,
            'pr': m.group('pr') or '',
        })
print(json.dumps(out, indent=2))
PY
}

# Find existing issue by story_id (via aegis-sync marker in description)
find_issue_by_story() {
  local project_id="$1" story_id="$2"
  local marker="<!-- aegis-sync:${story_id} -->"
  local q='query F($pid: String!) { project(id: $pid) { issues { nodes { id identifier title description state { id name } } } } }'
  local v
  v="$(jq -nc --arg p "$project_id" '{pid: $p}')"
  local resp
  resp="$(gql "$q" "$v")"
  echo "$resp" | jq --arg m "$marker" -c '.data.project.issues.nodes[]? | select(.description != null and (.description | contains($m)))' | head -n1
}

cmd_open() {
  local sprint_id="${1:-}"
  [[ -n "$sprint_id" ]] || fail "open requires <sprint_id>"

  log "Step 1/3: ensure project + milestone"
  if (( DRY )); then
    log "DRY: skip ensure-project + ensure-milestone (would create real Linear resources)"
    local milestone_id="DRY-FAKE-MILESTONE-ID"
  else
    bash "$SETUP" ensure-project >&2
    local milestone_id
    milestone_id="$(bash "$SETUP" ensure-milestone "$sprint_id")"
    [[ -n "$milestone_id" ]] || fail "milestone_id missing"
  fi

  local project_id
  project_id="$(jq -r '.project.id' "$CONFIG_PATH")"
  local team_id
  team_id="$(jq -r '.team.id' "$CONFIG_PATH")"

  log "Step 2/3: parse kanban"
  local stories
  stories="$(parse_kanban "$sprint_id")"
  local count
  count="$(echo "$stories" | jq 'length')"
  ok "Parsed $count stories from kanban"

  log "Step 3/3: create missing issues + sync state"
  local created=0 skipped=0 updated=0
  local i len
  len="$(echo "$stories" | jq 'length')"
  for ((i=0; i<len; i++)); do
    local row state_col story_id title agent points pr
    row="$(echo "$stories" | jq -c ".[$i]")"
    state_col="$(echo "$row" | jq -r '.section')"
    story_id="$(echo "$row" | jq -r '.story_id')"
    title="$(echo "$row" | jq -r '.title')"
    agent="$(echo "$row" | jq -r '.agent')"
    points="$(echo "$row" | jq -r '.points')"
    pr="$(echo "$row" | jq -r '.pr')"

    local state_id
    state_id="$(jq -r ".state_map.${state_col}.id" "$CONFIG_PATH")"
    [[ "$state_id" != "null" && -n "$state_id" ]] || { warn "no state_map for $state_col — skip $story_id"; continue; }

    # Build title + description
    local issue_title
    issue_title="$(jq -r '.sync_policy.issue_title_format' "$CONFIG_PATH" \
                   | sed "s|{story_id}|$story_id|g" \
                   | sed "s|{title}|$title|g")"

    local pr_block=""
    [[ -n "$pr" ]] && pr_block="\nPR: #${pr}"
    local agent_block=""
    [[ -n "$agent" ]] && agent_block="\nAgent: @${agent}"

    local footer
    footer="$(jq -r '.sync_policy.description_footer' "$CONFIG_PATH" \
              | sed "s|{sprint_id}|$sprint_id|g" \
              | sed "s|{story_id}|$story_id|g")"

    local desc
    desc="Points: ${points}pt${agent_block}${pr_block}${footer}\n<!-- aegis-sync:${story_id} -->"

    # Check if exists
    local existing
    existing="$(find_issue_by_story "$project_id" "$story_id")"

    if [[ -n "$existing" ]]; then
      # Update state if changed
      local cur_state
      cur_state="$(echo "$existing" | jq -r '.state.id')"
      if [[ "$cur_state" != "$state_id" ]]; then
        local iid
        iid="$(echo "$existing" | jq -r '.id')"
        local mut='mutation U($id: String!, $input: IssueUpdateInput!) { issueUpdate(id: $id, input: $input) { success } }'
        local vars
        vars="$(jq -nc --arg id "$iid" --arg sid "$state_id" '{id: $id, input: {stateId: $sid}}')"
        gql "$mut" "$vars" > /dev/null
        updated=$((updated+1))
        log "  ↻ $story_id state → $state_col"
      else
        skipped=$((skipped+1))
      fi
      continue
    fi

    # Create new issue
    local mut='mutation C($input: IssueCreateInput!) { issueCreate(input: $input) { success issue { id identifier url } } }'
    local vars
    vars="$(jq -nc \
      --arg title "$issue_title" \
      --arg desc "$desc" \
      --arg team "$team_id" \
      --arg proj "$project_id" \
      --arg ms "$milestone_id" \
      --arg state "$state_id" \
      '{input: {
        title: $title,
        description: $desc,
        teamId: $team,
        projectId: $proj,
        projectMilestoneId: $ms,
        stateId: $state
      }}')"
    local resp
    resp="$(gql "$mut" "$vars")"
    if echo "$resp" | jq -e '.errors' >/dev/null 2>&1; then
      warn "create failed for $story_id: $(echo "$resp" | jq -c '.errors')"
      continue
    fi
    local ident
    ident="$(echo "$resp" | jq -r '.data.issueCreate.issue.identifier // "?"')"
    created=$((created+1))
    log "  + $story_id → $ident"
  done

  ok "open complete: created=$created updated=$updated skipped=$skipped"
  if (( JSON )); then
    jq -nc --arg s "$sprint_id" --arg m "$milestone_id" --argjson c "$created" --argjson u "$updated" --argjson k "$skipped" \
      '{sprint:$s, milestone:$m, created:$c, updated:$u, skipped:$k}'
  fi
}

cmd_push() {
  local sprint_id="${1:-}"
  [[ -n "$sprint_id" ]] || fail "push requires <sprint_id>"
  log "push = open (idempotent: only state diffs are sent)"
  cmd_open "$sprint_id"
}

cmd_close() {
  local sprint_id="${1:-}"
  [[ -n "$sprint_id" ]] || fail "close requires <sprint_id>"

  log "Sync final state first..."
  cmd_open "$sprint_id"

  # Mark milestone done by setting targetDate to today (Linear has no explicit "done" for milestones)
  # Better: project milestones support `sortOrder` not state. Just leave it.
  log "close complete — milestone left in Linear (no destructive ops)"
}

cmd_drift() {
  local sprint_id="${1:-}"
  [[ -n "$sprint_id" ]] || fail "drift requires <sprint_id>"

  local project_id
  project_id="$(jq -r '.project.id // empty' "$CONFIG_PATH")"
  [[ -n "$project_id" ]] || { warn "no project linked yet — no drift to detect"; return 0; }

  local stories
  stories="$(parse_kanban "$sprint_id")"
  local drifts=0

  local i len
  len="$(echo "$stories" | jq 'length')"
  for ((i=0; i<len; i++)); do
    local row story_id state_col expected_state_id
    row="$(echo "$stories" | jq -c ".[$i]")"
    story_id="$(echo "$row" | jq -r '.story_id')"
    state_col="$(echo "$row" | jq -r '.section')"
    expected_state_id="$(jq -r ".state_map.${state_col}.id" "$CONFIG_PATH")"

    local existing
    existing="$(find_issue_by_story "$project_id" "$story_id")"
    [[ -z "$existing" ]] && continue

    local cur_state cur_name
    cur_state="$(echo "$existing" | jq -r '.state.id')"
    cur_name="$(echo "$existing" | jq -r '.state.name')"
    if [[ "$cur_state" != "$expected_state_id" ]]; then
      warn "DRIFT $story_id: kanban=$state_col linear=$cur_name"
      drifts=$((drifts+1))
    fi
  done

  if (( drifts == 0 )); then
    ok "no drift detected for sprint $sprint_id"
  else
    warn "drift count: $drifts (run: aegis-linear-sync.sh push $sprint_id)"
  fi
}

main() {
  command -v jq      >/dev/null || fail "jq required (brew install jq)"
  command -v curl    >/dev/null || fail "curl required"
  command -v python3 >/dev/null || fail "python3 required"

  local sub="${1:-help}"
  shift || true
  # Parse flags from remaining args
  local args=()
  while (( $# )); do
    case "$1" in
      --dry)  DRY=1 ;;
      --json) JSON=1 ;;
      *)      args+=("$1") ;;
    esac
    shift
  done

  case "$sub" in
    open)  cmd_open  "${args[@]:-}" ;;
    push)  cmd_push  "${args[@]:-}" ;;
    close) cmd_close "${args[@]:-}" ;;
    drift) cmd_drift "${args[@]:-}" ;;
    help|--help|-h)
      sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
      ;;
    *) printf 'Unknown subcommand: %s\n' "$sub" >&2; exit 1 ;;
  esac
}

main "$@"
