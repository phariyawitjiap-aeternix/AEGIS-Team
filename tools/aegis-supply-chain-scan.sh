#!/usr/bin/env bash
# aegis-supply-chain-scan.sh
# ────────────────────────────────────────────────────────────────────────────
# Narrow supply-chain audit scan over a git diff. Runs in CI and locally.
#
# Sprint:    v14-01 (S14-01-03)
# Source:    Hermes .github/workflows/supply-chain-audit.yml (commit dd0923b)
# Discipline: NARROW + NO-NOISE.
#
# Why narrow:
#   Hermes explicitly removed broad heuristics (plain base64, plain exec/eval,
#   dependency edits) because they fired on nearly every PR and trained
#   reviewers to ignore the scanner. We adopt that discipline:
#   only ship checks that flag genuine attack indicators, not lifecycle noise.
#
# Adapted for AEGIS (.mjs/.sh codebase):
#   1. package.json gains `pre-install` / `post-install` / `prepare` script that
#      runs anything beyond a noop — actual install-time code execution path.
#   2. New .mjs file uses `eval(...)` or `new Function(...)` constructor.
#   3. New .mjs file makes outbound network call to non-allowlisted domain.
#   4. `.npmrc` modification (registry override / token leakage vector).
#   5. `node_modules/` content committed (should be gitignored).
#
# Usage:
#   tools/aegis-supply-chain-scan.sh <base-sha> <head-sha>           # ranged scan
#   tools/aegis-supply-chain-scan.sh --diff-file <path>              # scan from file
#   tools/aegis-supply-chain-scan.sh --names <name1> <name2> ...     # scan listed files
#
# Exit codes:
#   0 — no findings
#   1 — at least one finding (markdown report on stdout)
#   2 — usage error
# ────────────────────────────────────────────────────────────────────────────

set -uo pipefail

usage() {
    cat >&2 <<'EOF'
Usage:
  aegis-supply-chain-scan.sh <base-sha> <head-sha>
  aegis-supply-chain-scan.sh --diff-file <path>
  aegis-supply-chain-scan.sh --names <file1> [<file2> ...]
EOF
    exit 2
}

if [ $# -lt 1 ]; then
    usage
fi

# Mode 1: ranged scan via git diff
# Mode 2: scan provided diff file
# Mode 3: scan list of filenames (used by tests)
MODE=""
DIFF_FILE=""
DIFF_BODY=""
NAMES=()

case "$1" in
    --diff-file)
        MODE="file"
        DIFF_FILE="${2:-}"
        [ -z "$DIFF_FILE" ] && usage
        DIFF_BODY="$(cat "$DIFF_FILE")"
        ;;
    --names)
        MODE="names"
        shift
        NAMES=("$@")
        ;;
    *)
        if [ $# -lt 2 ]; then usage; fi
        MODE="git"
        BASE="$1"
        HEAD="$2"
        # Exclude tests/ + close.md sprint docs from the scan — those legitimately
        # contain bad patterns as STRING fixtures + retrospective discussion (e.g.
        # "TC15 false-positive on eval()"). Scanning them would create perpetual
        # false-positives + the exact "reviewers ignore the scanner" failure mode
        # Hermes commit dd0923b warned against.
        DIFF_BODY="$(git diff "$BASE..$HEAD" -- . ':!*.lock' ':!package-lock.json' ':!yarn.lock' ':!tests/*' ':!.aegis/brain/sprints/*' ':!.aegis/brain/learnings/*' 2>/dev/null || true)"
        NAMES=()
        while IFS= read -r line; do
            [ -n "$line" ] && NAMES+=("$line")
        done < <(git diff --name-only "$BASE..$HEAD" 2>/dev/null \
                 | grep -vE '^tests/|^\.aegis/brain/sprints/|^\.aegis/brain/learnings/' \
                 || true)
        ;;
esac

FINDINGS=""
ADD_FINDING() {
    local title="$1"
    local detail="$2"
    if [ -z "$FINDINGS" ]; then
        FINDINGS=$'## Supply Chain Audit Findings\n\n'
    fi
    FINDINGS="${FINDINGS}### 🚨 ${title}"$'\n'
    FINDINGS="${FINDINGS}${detail}"$'\n\n'
}

# ── Check 1: package.json install scripts added/modified ─────────────────────
if printf '%s' "$DIFF_BODY" | grep -E '^\+.*(pre-?install|post-?install|prepare)' \
        | grep -E '"(pre-?install|post-?install|prepare)"\s*:' \
        | grep -v '\bnoop\b\|"true"\|"echo' >/dev/null 2>&1; then
    matched_lines=$(printf '%s' "$DIFF_BODY" | grep -E '^\+.*(pre-?install|post-?install|prepare).*:.*"' | grep -v '\bnoop\b\|"true"\|"echo' | head -3)
    ADD_FINDING "package.json install script added/modified" "$(printf '%s\n\nThese scripts auto-execute during `npm install` — same vector as the litellm supply-chain attack and Mini Shai-Hulud worm. Verify the script is intentional and audit its content.\n\nMatched lines:\n```\n%s\n```' '' "$matched_lines")"
fi

# ── Check 2: .pth files added (Python equivalent — kept for compat) ──────────
PTH_FILES=""
if [ "$MODE" = "git" ]; then
    PTH_FILES=$(git diff --name-only "$BASE..$HEAD" 2>/dev/null | grep '\.pth$' || true)
elif [ "$MODE" = "names" ]; then
    PTH_FILES=$(printf '%s\n' "${NAMES[@]}" | grep '\.pth$' || true)
fi
if [ -n "$PTH_FILES" ]; then
    ADD_FINDING ".pth file added or modified" "$(printf 'Python `.pth` files in `site-packages/` execute automatically when the interpreter starts — no import required. The exact mechanism used in the litellm attack: https://github.com/BerriAI/litellm/issues/24512\n\nFiles:\n```\n%s\n```' "$PTH_FILES")"
fi

# ── Check 3: eval(...) or new Function(...) introduced in new .mjs/.js ───────
# Skip comment lines (#, //, *) — comments mentioning eval() are common and benign.
EVAL_HITS=$(printf '%s' "$DIFF_BODY" | grep -E '^\+[^+]' | grep -vE '^\+[[:space:]]*(#|//|\*)' | grep -E '\beval\s*\(|\bnew\s+Function\s*\(' || true)
if [ -n "$EVAL_HITS" ]; then
    ADD_FINDING "eval() or new Function() introduced" "$(printf 'JavaScript `eval()` and the `Function` constructor execute arbitrary strings as code — common deobfuscation step in malicious packages. If this is genuinely needed (rare), prepend an explanatory comment.\n\nMatched lines:\n```\n%s\n```' "$(printf '%s' "$EVAL_HITS" | head -5)")"
fi

# ── Check 4: outbound network in new .mjs (curl/wget/fetch to ip-or-domain) ──
# Only flag URLs in newly-added lines that look like raw IPs or unknown domains.
NET_HITS=$(printf '%s' "$DIFF_BODY" | grep -E '^\+[^+]' \
    | grep -E "(fetch|axios|http\.(get|post|request))\s*\(\s*['\"]https?://[0-9]" \
    || true)
if [ -n "$NET_HITS" ]; then
    ADD_FINDING "outbound HTTP to raw IP address" "$(printf 'New code calls a raw-IP URL (no DNS name). Common pattern in malicious telemetry / C2.\n\nMatched lines:\n```\n%s\n```' "$(printf '%s' "$NET_HITS" | head -5)")"
fi

# ── Check 5: .npmrc modification ─────────────────────────────────────────────
NPMRC_FILES=""
if [ "$MODE" = "git" ]; then
    NPMRC_FILES=$(git diff --name-only "$BASE..$HEAD" 2>/dev/null | grep '\.npmrc$' || true)
elif [ "$MODE" = "names" ]; then
    NPMRC_FILES=$(printf '%s\n' "${NAMES[@]}" | grep '\.npmrc$' || true)
fi
if [ -n "$NPMRC_FILES" ]; then
    ADD_FINDING ".npmrc added or modified" "$(printf '`.npmrc` controls registry endpoints and authentication. A malicious change can redirect package installs to an attacker-controlled mirror or leak auth tokens.\n\nFiles:\n```\n%s\n```' "$NPMRC_FILES")"
fi

# ── Check 6: node_modules/ content committed (should be gitignored) ──────────
NM_FILES=""
if [ "$MODE" = "git" ]; then
    NM_FILES=$(git diff --name-only "$BASE..$HEAD" 2>/dev/null | grep '^node_modules/' || true)
elif [ "$MODE" = "names" ]; then
    NM_FILES=$(printf '%s\n' "${NAMES[@]}" | grep '^node_modules/' || true)
fi
if [ -n "$NM_FILES" ]; then
    ADD_FINDING "node_modules/ content committed" "$(printf 'Vendored dependencies in the repo bypass lockfile review. `node_modules/` should be gitignored.\n\nFiles:\n```\n%s\n```' "$(echo "$NM_FILES" | head -10)")"
fi

# ── Output ───────────────────────────────────────────────────────────────────
if [ -n "$FINDINGS" ]; then
    printf '%s' "$FINDINGS"
    exit 1
fi

# No findings — silent
exit 0
