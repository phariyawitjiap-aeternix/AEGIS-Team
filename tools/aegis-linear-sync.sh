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

# ─── Label management (idempotent) ─────────────────────────────────────────
# Linear team labels are global per team. We cache id→name in a tmp file
# per script run to avoid 1 query per issue.
_LABEL_CACHE="/tmp/aegis-linear-labels.$$.json"

# Subtype color hex map for auto-created labels
_subtype_color() {
  case "$1" in
    build)        printf '#10b981' ;;   # emerald
    design|ui)    printf '#bb87fc' ;;   # purple
    test)         printf '#f59e0b' ;;   # amber
    docs)         printf '#0ea5e9' ;;   # sky
    devops)       printf '#06b6d4' ;;   # cyan
    review)       printf '#ec4899' ;;   # pink
    research)     printf '#a855f7' ;;   # violet
    orchestrate)  printf '#5e6ad2' ;;   # linear-purple
    data)         printf '#84cc16' ;;   # lime
    content)      printf '#f472b6' ;;   # rose
    refactor)     printf '#fb923c' ;;   # orange
    scout)        printf '#94a3b8' ;;   # slate
    *)            printf '#94a3b8' ;;
  esac
}

# Ensure a label exists in the team; return its id
ensure_label() {
  local name="$1" color="$2"
  local team_id
  team_id="$(jq -r '.team.id' "$CONFIG_PATH")"

  # Refresh cache once per run
  if [[ ! -f "$_LABEL_CACHE" ]]; then
    local resp
    resp="$(gql "{ team(id: \"$team_id\") { labels { nodes { id name } } } }")"
    echo "$resp" | jq -c '[.data.team.labels.nodes[]? | {(.name): .id}] | add // {}' > "$_LABEL_CACHE"
  fi

  local cached
  cached="$(jq -r --arg n "$name" '.[$n] // empty' "$_LABEL_CACHE")"
  if [[ -n "$cached" ]]; then
    printf '%s' "$cached"
    return 0
  fi

  # Create
  local mut='mutation L($input: IssueLabelCreateInput!) { issueLabelCreate(input: $input) { success issueLabel { id name } } }'
  local vars
  vars="$(jq -nc --arg n "$name" --arg t "$team_id" --arg c "$color" '{input: {name:$n, teamId:$t, color:$c}}')"
  local resp
  resp="$(gql "$mut" "$vars")"
  if echo "$resp" | jq -e '.errors' >/dev/null 2>&1; then
    warn "label create failed for '$name': $(echo "$resp" | jq -c '.errors')"
    printf ''
    return 1
  fi
  local lid
  lid="$(echo "$resp" | jq -r '.data.issueLabelCreate.issueLabel.id')"
  # Update cache
  local tmp
  tmp="$(mktemp)"
  jq --arg n "$name" --arg id "$lid" '. + {($n): $id}' "$_LABEL_CACHE" > "$tmp" && mv "$tmp" "$_LABEL_CACHE"
  log "  + label created: $name"
  printf '%s' "$lid"
}

# Get label IDs for an issue (aegis + subtype label)
get_issue_label_ids() {
  local subtype="$1"
  local aegis_id subtype_id
  aegis_id="$(ensure_label "aegis" "#5e6ad2")"
  local ids=()
  [[ -n "$aegis_id" ]] && ids+=("$aegis_id")
  if [[ -n "$subtype" && "$subtype" != "general" ]]; then
    subtype_id="$(ensure_label "subtype:$subtype" "$(_subtype_color "$subtype")")"
    [[ -n "$subtype_id" ]] && ids+=("$subtype_id")
  fi
  # Output as JSON array
  printf '%s\n' "${ids[@]:-}" | jq -R . | jq -sc '[ .[] | select(. != "") ]'
}

# Parse kanban.md + plan.md → rich JSON with sprint goal + per-story descriptions + subtype
# Returns: { goal, source, stories: [{section, story_id, title, agent, subtype, points, pr, description}] }
parse_sprint() {
  local sprint_id="$1"
  local sprint_dir="${REPO_ROOT}/.aegis/brain/sprints/${sprint_id}"
  local kanban="${sprint_dir}/kanban.md"
  local plan="${sprint_dir}/plan.md"
  # Must have at least kanban.md OR plan.md. Older sprints (1-3) use table-kanban,
  # v13-* skip kanban entirely and live in plan.md Stories table.
  if [[ ! -f "$kanban" && ! -f "$plan" ]]; then
    warn "sprint has neither kanban.md nor plan.md: $sprint_dir"
    echo '{"sprint_id":"'"$sprint_id"'","stories":[],"goal":"","plan_exists":false,"_error":"no source files"}'
    return
  fi

  python3 - "$sprint_id" "$sprint_dir" <<'PY'
import re, sys, json, pathlib
sprint_id = sys.argv[1]
sprint_dir = pathlib.Path(sys.argv[2])
kanban_path = sprint_dir / 'kanban.md'
plan_path   = sprint_dir / 'plan.md'
close_path  = sprint_dir / 'close.md'

# AEGIS agent → work subtype (for stakeholder filtering in Linear)
AGENT_SUBTYPE = {
    'iron-man':        'design',
    'spider-man':      'build',
    'war-machine':     'test',
    'vision':          'test',
    'coulson':         'docs',
    'thor':            'devops',
    'captain-america': 'orchestrate',
    'captain':         'orchestrate',
    'nick-fury':       'orchestrate',
    'wasp':            'ui',
    'songbird':        'content',
    'black-panther':   'review',
    'loki':            'research',
    'beast':           'data',
    'hulk':            'refactor',
    'hawkeye':         'scout',
}

# ── Pull Sprint Goal + Source from plan.md (fallback: kanban frontmatter) ──
sprint_goal = ''
sprint_source = ''
sprint_status = ''

def read_field(text, field):
    m = re.search(rf'^\*\*{re.escape(field)}\*\*:\s*(.+?)$', text, re.MULTILINE)
    return m.group(1).strip() if m else ''

if plan_path.exists():
    plan_text = plan_path.read_text(errors='ignore')
    sprint_goal   = read_field(plan_text, 'Goal')
    sprint_source = read_field(plan_text, 'Source')
    sprint_status = read_field(plan_text, 'Status')

kanban_text = kanban_path.read_text(errors='ignore') if kanban_path.exists() else ''
plan_text   = plan_path.read_text(errors='ignore')   if plan_path.exists()   else ''
if not sprint_goal:
    sprint_goal = read_field(kanban_text, 'Goal')

# ── PARSER 1: bullet-list kanban (sprint-v9-*, v10-*, v11-*, v12-*) ──
SECTIONS = {'BACKLOG','TODO','IN_PROGRESS','IN_REVIEW','QA','DONE'}
section_re = re.compile(r'^##\s+([A-Z_]+)\s*$')
bullet_re = re.compile(
    r'^\s*-\s*\[(?P<chk>[ x])\]\s*'
    r'\[(?P<sid>[A-Z]+\d*-?\d+)\]\s*'
    r'(?P<title>.+?)'
    r'(?:\s*\(@(?P<agent>[\w-]+)\))?'
    r'(?:\s*[—-]\s*(?P<pts>\d+)pt)?'
    r'(?:\s*\[PR\s*#(?P<pr>\d+)\])?'
    r'\s*$'
)

def parse_bullet_kanban(text):
    out = []; section = None; cur = None
    def push():
        if cur is not None:
            cur['description'] = '\n'.join(cur['_desc_lines']).strip()
            del cur['_desc_lines']
            out.append(cur)
    for line in text.splitlines():
        sm = section_re.match(line)
        if sm and sm.group(1) in SECTIONS:
            push(); cur = None; section = sm.group(1); continue
        if not section: continue
        m = bullet_re.match(line)
        if m:
            push()
            agent = m.group('agent') or ''
            cur = {'section': section, 'checked': m.group('chk') == 'x',
                   'story_id': m.group('sid'), 'title': m.group('title').strip(),
                   'agent': agent, 'subtype': AGENT_SUBTYPE.get(agent, 'general' if agent else ''),
                   'points': int(m.group('pts')) if m.group('pts') else 0,
                   'pr': m.group('pr') or '', '_desc_lines': []}
            continue
        if cur is not None and line.strip() and (line.startswith('      ') or line.startswith('\t')):
            cur['_desc_lines'].append(line.strip())
    push()
    return out

# ── PARSER 2: table kanban (sprint-1, 2, 3) — section header + rows ──
# Row: | PROJ-T-001 | Title | 3 | @spider-man | critical |
table_row_re = re.compile(
    r'^\s*\|\s*'
    r'(?P<sid>[A-Z][A-Z0-9-]+(?:-T)?-?\d+)'    # PROJ-T-001 or AI-3
    r'\s*\|\s*(?P<title>[^|]+?)'
    r'\s*\|\s*(?P<pts>\d+)?'
    r'\s*\|\s*@?(?P<agent>[\w-]+)?'
    r'\s*\|\s*(?P<extra>[^|]*?)'
    r'\s*\|\s*$'
)

def parse_table_kanban(text):
    # Section detection — looser: "## TODO (7 tasks, 22 pts)" should match
    section_loose_re = re.compile(r'^##\s+([A-Z_]+)\b')
    out = []; section = None
    for line in text.splitlines():
        sm = section_loose_re.match(line)
        if sm:
            sec_name = sm.group(1)
            section = sec_name if sec_name in SECTIONS else None
            continue
        if not section: continue
        m = table_row_re.match(line)
        if not m: continue
        # Skip header row "| ID | Title | ..." and separator "|---|---|"
        sid = m.group('sid').strip()
        if sid in ('ID', '---'): continue
        agent = (m.group('agent') or '').strip()
        out.append({'section': section, 'checked': section == 'DONE',
                    'story_id': sid, 'title': m.group('title').strip(),
                    'agent': agent, 'subtype': AGENT_SUBTYPE.get(agent, 'general' if agent else ''),
                    'points': int(m.group('pts')) if m.group('pts') else 0,
                    'pr': '', 'description': ''})
    return out

# ── PARSER 3: plan.md "## Stories" table (v13-*, v11-*) ──
# Row formats:
#   | **AI-1** | Title text | 1 | Owner | PR |
#   | A | Title text | 1 |
plan_row_re = re.compile(
    r'^\s*\|\s*\*{0,2}(?P<sid>[A-Z][A-Z0-9-]*-?\d*|[A-Z])\*{0,2}'
    r'\s*\|\s*(?P<title>[^|]+?)'
    r'\s*\|\s*(?P<pts>\d+)?'
    r'(?:\s*\|\s*(?P<owner>[^|]*?))?'
    r'(?:\s*\|\s*(?P<pr>[^|]*?))?'
    r'\s*\|\s*$'
)

def parse_plan_stories(text):
    """Find `## Stories` or `## Tasks` section in plan.md, parse rows."""
    out = []
    # Match Stories/Tasks heading until the next ## heading
    m = re.search(r'^##\s+(?:Stories|Tasks)\b.*?$(?P<body>.*?)(?=^##\s|\Z)',
                  text, re.MULTILINE | re.DOTALL)
    if not m: return out
    body = m.group('body')
    # Detect status from plan-level (default to TODO since plans are forward-looking)
    # We'll set DONE if the sprint status field says CLOSED
    default_section = 'DONE' if 'CLOSED' in sprint_status.upper() else 'TODO'
    for line in body.splitlines():
        # Skip table header + separator
        if re.match(r'^\s*\|\s*ID\s*\|', line): continue
        if re.match(r'^\s*\|[\s\-\:]+\|', line):  continue
        rm = plan_row_re.match(line)
        if not rm: continue
        sid = rm.group('sid').strip()
        if not sid or sid in ('ID',): continue
        title = rm.group('title').strip()
        # Skip rows where title is empty or only whitespace
        if not title or title.startswith('-'): continue
        owner = (rm.group('owner') or '').strip()
        # Owner might be a real name "Captain America" — keep as-is
        # Map to agent key for subtype: lowercase + dashes
        agent_key = re.sub(r'\s+', '-', owner.lower()) if owner else ''
        # Strip role suffixes like "(reviewer)" or trailing "+"
        agent_key = re.sub(r'\(.*?\)|[+,].*$', '', agent_key).strip().strip('-')
        pr_text = (rm.group('pr') or '').strip()
        pr = ''
        prm = re.search(r'#?(\d+)', pr_text)
        if prm: pr = prm.group(1)
        out.append({'section': default_section, 'checked': default_section == 'DONE',
                    'story_id': sid, 'title': title,
                    'agent': agent_key,
                    'subtype': AGENT_SUBTYPE.get(agent_key, 'general' if agent_key else ''),
                    'points': int(rm.group('pts')) if rm.group('pts') else 0,
                    'pr': pr, 'description': ''})
    return out

# ── Try parsers in order: bullet (most data) → table (older) → plan (no kanban) ──
stories = []
parser_used = ''
if kanban_text:
    stories = parse_bullet_kanban(kanban_text)
    if stories: parser_used = 'kanban-bullet'
if not stories and kanban_text:
    stories = parse_table_kanban(kanban_text)
    if stories: parser_used = 'kanban-table'
if not stories and plan_text:
    stories = parse_plan_stories(plan_text)
    if stories: parser_used = 'plan-stories'

out = {
    'sprint_id': sprint_id,
    'goal': sprint_goal,
    'source': sprint_source,
    'status': sprint_status,
    'plan_exists': plan_path.exists(),
    'kanban_exists': kanban_path.exists(),
    'close_exists': close_path.exists(),
    'parser_used': parser_used,
    'stories': stories,
}
print(json.dumps(out, indent=2, ensure_ascii=False))
PY
}

# Build rich Linear issue description from sprint+story JSON
# Embeds a content hash in the marker so we can detect real changes despite
# Linear's markdown normalization (blank lines, table-syntax tweaks).
build_issue_description() {
  local sprint_id="$1" goal="$2" story_json="$3"
  python3 - "$sprint_id" "$goal" "$story_json" <<'PY'
import sys, json, hashlib
sprint_id, goal, story_json = sys.argv[1], sys.argv[2], sys.argv[3]
s = json.loads(story_json)

# Content hash — only changes when SOURCE content changes, not when Linear
# re-renders markdown. Use this for idempotency-safe diff detection.
canonical = json.dumps({
    'goal':        goal or '',
    'description': s.get('description', ''),
    'agent':       s.get('agent', ''),
    'subtype':     s.get('subtype', ''),
    'points':      s.get('points', 0),
    'pr':          s.get('pr', ''),
    'title':       s.get('title', ''),
    'sprint':      sprint_id,
    'story':      s.get('story_id', ''),
}, sort_keys=True, ensure_ascii=False)
chash = hashlib.sha1(canonical.encode('utf-8')).hexdigest()[:10]

agent_line   = f"@{s['agent']}" if s['agent'] else "_(unassigned)_"
points_line  = f"{s['points']}pt" if s['points'] else "_(not estimated)_"
pr_line      = f"#{s['pr']}" if s['pr'] else "_(none yet)_"
subtype_line = f"`{s['subtype']}`" if s['subtype'] else "_(not classified)_"
desc_section = s['description'] or '_(no description in kanban — story line only)_'
goal_section = goal or '_(not declared in plan.md)_'

md = f"""## 🎯 Sprint Goal
{goal_section}

## 📋 Task
{desc_section}

## 📦 Metadata

| | |
|---|---|
| **Story ID** | `{s['story_id']}` |
| **Sprint** | `{sprint_id}` |
| **Owner** | {agent_line} |
| **Subtype** | {subtype_line} |
| **Points** | {points_line} |
| **PR** | {pr_line} |

---
🤖 Synced from AEGIS · sprint `{sprint_id}` · story `{s['story_id']}` · do not edit manually
<!-- aegis-sync:{sprint_id}/{s['story_id']} v={chash} -->"""
print(md)
PY
}

# Extract content hash from an existing Linear description (returns "" if not present)
# Marker format: `aegis-sync:SPRINT_ID/STORY_ID v=hash` (sprint+story prefix prevents
# cross-sprint collision when short IDs like A/B/AI-1 are reused across sprints).
extract_content_hash() {
  local desc="$1"
  printf '%s' "$desc" | grep -oE 'aegis-sync:[A-Za-z0-9_/-]+ v=[a-f0-9]+' | head -n1 | sed 's/.*v=//'
}

# Compute the hash that a fresh description WOULD have, given the source data
compute_content_hash() {
  local sprint_id="$1" goal="$2" story_json="$3"
  python3 - "$sprint_id" "$goal" "$story_json" <<'PY'
import sys, json, hashlib
sprint_id, goal, story_json = sys.argv[1], sys.argv[2], sys.argv[3]
s = json.loads(story_json)
canonical = json.dumps({
    'goal':        goal or '',
    'description': s.get('description', ''),
    'agent':       s.get('agent', ''),
    'subtype':     s.get('subtype', ''),
    'points':      s.get('points', 0),
    'pr':          s.get('pr', ''),
    'title':       s.get('title', ''),
    'sprint':      sprint_id,
    'story':      s.get('story_id', ''),
}, sort_keys=True, ensure_ascii=False)
print(hashlib.sha1(canonical.encode('utf-8')).hexdigest()[:10])
PY
}

# Find existing issue by (sprint_id, story_id) — looking up the unique aegis-sync
# marker in the description. The marker carries sprint+story to avoid cross-sprint
# collision when short IDs (A, B, AI-1, AI-2, etc.) repeat across sprints.
#
# Marker schema history:
#   v1: <!-- aegis-sync:STORY_ID -->                  (original — collision risk)
#   v2: <!-- aegis-sync:STORY_ID v=HASH -->           (added content hash)
#   v3: <!-- aegis-sync:SPRINT_ID/STORY_ID v=HASH --> (CURRENT — sprint-scoped)
find_issue_by_story() {
  local project_id="$1" story_id="$2" sprint_id="${3:-}"
  local q='query F($pid: String!) { project(id: $pid) { issues { nodes { id identifier title description state { id name } projectMilestone { id name } } } } }'
  local v
  v="$(jq -nc --arg p "$project_id" '{pid: $p}')"
  local resp
  resp="$(gql "$q" "$v")"
  # Build a regex anchor that requires BOTH sprint and story in the marker
  # (v3 format). Fall back to story-only for v1/v2 backward compat (rare path).
  local marker="aegis-sync:${sprint_id}/${story_id}[ -]"
  local fallback="aegis-sync:${story_id}[ -]"
  echo "$resp" | jq --arg new "$marker" --arg old "$fallback" -c '
    [.data.project.issues.nodes[]?
      | select(.description != null and (.description | test($new)))]
    | sort_by(.identifier | capture("(?<n>[0-9]+)$") | .n | tonumber)
    | .[0] // empty
  '
}

# Same as find_issue_by_story but includes labels in the result.
find_issue_by_story_with_labels() {
  local project_id="$1" story_id="$2" sprint_id="${3:-}"
  local q='query F($pid: String!) { project(id: $pid) { issues { nodes { id identifier title description state { id name } projectMilestone { id name } labels { nodes { id name } } } } } }'
  local v
  v="$(jq -nc --arg p "$project_id" '{pid: $p}')"
  local resp
  resp="$(gql "$q" "$v")"
  local marker="aegis-sync:${sprint_id}/${story_id}[ -]"
  echo "$resp" | jq --arg new "$marker" -c '
    [.data.project.issues.nodes[]?
      | select(.description != null and (.description | test($new)))]
    | sort_by(.identifier | capture("(?<n>[0-9]+)$") | .n | tonumber)
    | .[0] // empty
  '
}

cmd_open() {
  local sprint_id="${1:-}"
  [[ -n "$sprint_id" ]] || fail "open requires <sprint_id>"

  log "Step 1/4: ensure project + milestone"
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

  log "Step 2/4: parse sprint (plan.md + kanban.md)"
  local sprint_data
  sprint_data="$(parse_sprint "$sprint_id")"
  local goal
  goal="$(echo "$sprint_data" | jq -r '.goal')"
  local count
  count="$(echo "$sprint_data" | jq '.stories | length')"
  local plan_found
  plan_found="$(echo "$sprint_data" | jq -r '.plan_exists')"
  ok "Parsed $count stories · goal=$([ -n "$goal" ] && printf '✓' || printf '✗') · plan.md=$plan_found"

  log "Step 3/4: build rich descriptions + sync state + content"
  local created=0 skipped=0 updated_state=0 updated_desc=0
  local i len
  len="$(echo "$sprint_data" | jq '.stories | length')"
  for ((i=0; i<len; i++)); do
    local row state_col story_id title
    row="$(echo "$sprint_data" | jq -c ".stories[$i]")"
    state_col="$(echo "$row" | jq -r '.section')"
    story_id="$(echo "$row" | jq -r '.story_id')"
    title="$(echo "$row" | jq -r '.title')"

    local state_id
    state_id="$(jq -r ".state_map.${state_col}.id" "$CONFIG_PATH")"
    [[ "$state_id" != "null" && -n "$state_id" ]] || { warn "no state_map for $state_col — skip $story_id"; continue; }

    # Build title
    local issue_title
    issue_title="$(jq -r '.sync_policy.issue_title_format' "$CONFIG_PATH" \
                   | sed "s|{story_id}|$story_id|g" \
                   | sed "s|{title}|$title|g")"

    # Build rich description (with sprint goal + multi-line task + metadata table)
    local desc
    desc="$(build_issue_description "$sprint_id" "$goal" "$row")"

    # Build label IDs (aegis + subtype:<value>)
    local subtype
    subtype="$(echo "$row" | jq -r '.subtype // ""')"
    local label_ids
    label_ids="$(get_issue_label_ids "$subtype")"

    # Check if exists (with labels for diff detection) — pass sprint_id to scope marker
    local existing
    existing="$(find_issue_by_story_with_labels "$project_id" "$story_id" "$sprint_id")"

    if [[ -n "$existing" ]]; then
      local iid cur_state cur_desc cur_hash new_hash cur_label_ids cur_ms_id
      iid="$(echo "$existing" | jq -r '.id')"
      cur_state="$(echo "$existing" | jq -r '.state.id')"
      cur_desc="$(echo "$existing" | jq -r '.description // ""')"
      cur_hash="$(extract_content_hash "$cur_desc")"
      new_hash="$(compute_content_hash "$sprint_id" "$goal" "$row")"
      cur_label_ids="$(echo "$existing" | jq -c '[.labels.nodes[].id] | sort')"
      cur_ms_id="$(echo "$existing" | jq -r '.projectMilestone.id // ""')"
      # UNION: preserve user-added labels; ensure aegis + subtype are present
      local expected_label_ids
      expected_label_ids="$(jq -nc --argjson cur "$cur_label_ids" --argjson new "$label_ids" '($cur + $new) | unique | sort')"

      local need_state=false need_desc=false need_labels=false need_ms=false
      [[ "$cur_state" != "$state_id" ]] && need_state=true
      [[ "$cur_hash" != "$new_hash" ]] && need_desc=true
      [[ "$cur_label_ids" != "$expected_label_ids" ]] && need_labels=true
      # If milestone is wrong or missing, fix it (catches orphans + mis-linked dupes)
      [[ "$cur_ms_id" != "$milestone_id" ]] && need_ms=true

      if $need_state || $need_desc || $need_labels || $need_ms; then
        # Build update fields — include only what needs changing (Linear labelIds is a SET op)
        local fields="{}"
        if $need_state; then
          fields="$(echo "$fields" | jq --arg s "$state_id" '. + {stateId:$s}')"
        fi
        if $need_desc; then
          fields="$(echo "$fields" | jq --arg d "$desc" --arg t "$issue_title" '. + {description:$d, title:$t}')"
        fi
        if $need_labels; then
          fields="$(echo "$fields" | jq --argjson lids "$expected_label_ids" '. + {labelIds:$lids}')"
        fi
        if $need_ms; then
          fields="$(echo "$fields" | jq --arg ms "$milestone_id" '. + {projectMilestoneId:$ms}')"
        fi
        local mut='mutation U($id: String!, $input: IssueUpdateInput!) { issueUpdate(id: $id, input: $input) { success } }'
        local vars
        vars="$(jq -nc --arg id "$iid" --argjson f "$fields" '{id:$id, input:$f}')"
        local resp
        resp="$(gql "$mut" "$vars")"
        if echo "$resp" | jq -e '.errors' >/dev/null 2>&1; then
          warn "update failed for $story_id: $(echo "$resp" | jq -c '.errors')"
          continue
        fi
        $need_state && { updated_state=$((updated_state+1)); log "  ↻ $story_id state → $state_col"; }
        $need_desc  && { updated_desc=$((updated_desc+1));   log "  ✎ $story_id description refreshed"; }
        $need_labels && { log "  🏷️  $story_id labels updated"; }
        $need_ms    && { log "  🎯 $story_id milestone → $sprint_id"; }
      else
        skipped=$((skipped+1))
      fi
      continue
    fi

    # Create new issue (with labels)
    local mut='mutation C($input: IssueCreateInput!) { issueCreate(input: $input) { success issue { id identifier url } } }'
    local vars
    vars="$(jq -nc \
      --arg title "$issue_title" \
      --arg desc "$desc" \
      --arg team "$team_id" \
      --arg proj "$project_id" \
      --arg ms "$milestone_id" \
      --arg state "$state_id" \
      --argjson lids "$label_ids" \
      '{input: {
        title: $title,
        description: $desc,
        teamId: $team,
        projectId: $proj,
        projectMilestoneId: $ms,
        stateId: $state,
        labelIds: $lids
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

  log "Step 4/4: summary"
  ok "open complete: created=$created · state-updated=$updated_state · desc-updated=$updated_desc · skipped=$skipped"
  if (( JSON )); then
    jq -nc --arg s "$sprint_id" --arg m "$milestone_id" \
      --argjson c "$created" --argjson us "$updated_state" --argjson ud "$updated_desc" --argjson k "$skipped" \
      '{sprint:$s, milestone:$m, created:$c, updated_state:$us, updated_desc:$ud, skipped:$k}'
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

  local sprint_data
  sprint_data="$(parse_sprint "$sprint_id")"
  local drifts=0

  local i len
  len="$(echo "$sprint_data" | jq '.stories | length')"
  for ((i=0; i<len; i++)); do
    local row story_id state_col expected_state_id
    row="$(echo "$sprint_data" | jq -c ".stories[$i]")"
    story_id="$(echo "$row" | jq -r '.story_id')"
    state_col="$(echo "$row" | jq -r '.section')"
    expected_state_id="$(jq -r ".state_map.${state_col}.id" "$CONFIG_PATH")"

    local existing
    existing="$(find_issue_by_story "$project_id" "$story_id" "$sprint_id")"
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
