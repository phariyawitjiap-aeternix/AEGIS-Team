#!/usr/bin/env bash
# aegis-credential-scan.sh — Discover required credentials at intake.
#
# Implements the "credential upfront" rule: at first /aegis-start, scan the
# project for every credential/key/token it needs, check what's already set,
# and report what's MISSING in one batch — so the team asks the human once,
# never mid-work.
#
# Sources scanned (in priority order):
#   .env.example / .env.sample / .env.template   (the canonical key list)
#   docker-compose*.yml  environment: refs
#   *.tf  variable "..." {}  (terraform, best-effort)
#
# Existing values checked in: .env, process env, .aegis/brain/state/credentials.json
#
# bash 3.2 compatible (macOS default) — NO associative arrays.
#
# Usage:
#   aegis-credential-scan.sh scan [--project-dir <path>]    List all required keys
#   aegis-credential-scan.sh check [--project-dir <path>]   Report missing vs set
#   aegis-credential-scan.sh check --json                   Machine-readable

set -uo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'
info() { printf "${BLUE}[INFO]${NC} %s\n" "$*" >&2; }

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
JSON=false
cmd="${1:-check}"; shift || true
while [[ $# -gt 0 ]]; do
    case "$1" in
        --project-dir) PROJECT_DIR="$2"; shift 2 ;;
        --json) JSON=true; shift ;;
        *) shift ;;
    esac
done
PROJECT_DIR="$(cd "$PROJECT_DIR" 2>/dev/null && pwd || echo "$PROJECT_DIR")"

# ── Collect required keys (newline-delimited, deduped) ────────────────────────
collect_keys() {
    {
        # .env.example family — lines like KEY= or KEY=value
        for ef in .env.example .env.sample .env.template; do
            local f="$PROJECT_DIR/$ef"
            [[ -f "$f" ]] && grep -oE '^[A-Za-z_][A-Za-z0-9_]*=' "$f" 2>/dev/null | sed 's/=$//'
        done
        # docker-compose environment refs: - KEY=... or ${KEY}
        for cf in docker-compose.yml docker-compose.yaml; do
            local f="$PROJECT_DIR/$cf"
            if [[ -f "$f" ]]; then
                grep -oE '\$\{[A-Za-z_][A-Za-z0-9_]*' "$f" 2>/dev/null | sed 's/^${//'
            fi
        done
    } | sort -u | grep -vE '^(LOG_LEVEL|NODE_ENV|PORT|HOST|PATH|PWD|HOME)$' || true
}

# ── Is a key already satisfied? (env, .env file, credentials.json) ────────────
key_is_set() {
    local key="$1"
    # 1. process env
    if [[ -n "${!key:-}" ]]; then return 0; fi
    # 2. .env file (non-empty value)
    local envf="$PROJECT_DIR/.env"
    if [[ -f "$envf" ]]; then
        local val
        val=$(grep -E "^${key}=" "$envf" 2>/dev/null | head -1 | sed "s/^${key}=//")
        # strip quotes/whitespace
        val=$(printf '%s' "$val" | sed 's/^["'"'"' ]*//; s/["'"'"' ]*$//')
        [[ -n "$val" ]] && return 0
    fi
    # 3. credentials.json
    local credf="$PROJECT_DIR/.aegis/brain/state/credentials.json"
    if [[ -f "$credf" ]] && command -v jq &>/dev/null; then
        local cval
        cval=$(jq -r --arg k "$key" '.[$k] // empty' "$credf" 2>/dev/null)
        [[ -n "$cval" ]] && return 0
    fi
    return 1
}

KEYS="$(collect_keys)"

case "$cmd" in
    scan)
        if [[ "$JSON" == "true" ]]; then
            printf '%s' "$KEYS" | jq -R . 2>/dev/null | jq -s . 2>/dev/null || printf '[]'
        else
            if [[ -z "$KEYS" ]]; then
                info "No credential sources found (.env.example / docker-compose / *.tf)"
            else
                printf "${BOLD}Required credentials (%s):${NC}\n" "$(printf '%s' "$KEYS" | grep -c .)"
                printf '%s\n' "$KEYS" | sed 's/^/  · /'
            fi
        fi
        ;;
    check)
        local_missing=""; local_set=""
        while IFS= read -r key; do
            [[ -z "$key" ]] && continue
            if key_is_set "$key"; then
                local_set="${local_set}${key}\n"
            else
                local_missing="${local_missing}${key}\n"
            fi
        done <<< "$KEYS"

        miss_count=$(printf '%b' "$local_missing" | grep -c . || true)
        set_count=$(printf '%b' "$local_set" | grep -c . || true)

        if [[ "$JSON" == "true" ]]; then
            jq -n \
                --argjson missing "$(printf '%b' "$local_missing" | grep . | jq -R . | jq -s . 2>/dev/null || echo '[]')" \
                --argjson set "$(printf '%b' "$local_set" | grep . | jq -R . | jq -s . 2>/dev/null || echo '[]')" \
                '{missing: $missing, set: $set, missing_count: ($missing|length), set_count: ($set|length)}'
        else
            printf "${BOLD}── Credential Check ──${NC}\n"
            printf "  Set:     ${GREEN}%s${NC}\n" "$set_count"
            printf "  Missing: ${RED}%s${NC}\n" "$miss_count"
            if [[ "$miss_count" -gt 0 ]]; then
                printf "\n${YELLOW}⚠️  Missing credentials — ask the human ONCE for all of these:${NC}\n"
                printf '%b' "$local_missing" | grep . | sed 's/^/  ❌ /'
                printf "\n  Store in: %s/.env  (or .aegis/brain/state/credentials.json)\n" "$PROJECT_DIR"
            else
                printf "\n${GREEN}✅ All required credentials are set.${NC}\n"
            fi
        fi
        # exit 1 if anything missing (lets /aegis-start gate on it)
        [[ "$miss_count" -gt 0 ]] && exit 1 || exit 0
        ;;
    -h|--help)
        echo "Usage: aegis-credential-scan.sh scan|check [--project-dir <path>] [--json]"
        ;;
    *)
        info "Unknown command: $cmd (use scan|check)"
        exit 1
        ;;
esac
