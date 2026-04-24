#!/usr/bin/env bash
# aegis-policy-audit.sh (S2-10) -- Policy-without-test scanner.
#
# Scans AEGIS documentation for enforcement claims (MUST, enforces,
# auto-REJECTs, BLOCK, guard-*, hook) and cross-references against
# actual enforcement code (hooks, test harnesses, guard scripts).
#
# Exit codes:
#   0  All policy claims have matching enforcement
#   1  Unmatched claims found (printed to stdout as report)
#   2  Usage error
#
# Usage:
#   bash tools/aegis-policy-audit.sh [--json] [--verbose]
#
# Sprint: sprint-v9-06 / S2-10
# ADR: ADR-005 (Hook Governance -- Rule 4 requires test harnesses)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
JSON_MODE=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --json)    JSON_MODE=true;  shift ;;
        --verbose) VERBOSE=true;    shift ;;
        -h|--help)
            echo "Usage: aegis-policy-audit.sh [--json] [--verbose]"
            echo ""
            echo "Scans AEGIS docs for enforcement claims (MUST, enforces,"
            echo "auto-REJECTs, BLOCK, guard-*) and verifies each has"
            echo "matching enforcement code (hooks, tests, guard scripts)."
            exit 0 ;;
        *) echo "ERROR: Unknown arg: $1" >&2; exit 2 ;;
    esac
done

# ── Phase 1: Collect policy claims from documentation ─────────────────────

# Files to scan for claims
CLAIM_SOURCES=(
    "$REPO_ROOT/CLAUDE.md"
    "$REPO_ROOT/CLAUDE_safety.md"
    "$REPO_ROOT/CLAUDE_agents.md"
)
# Add agent files
while IFS= read -r f; do
    CLAIM_SOURCES+=("$f")
done < <(find "$REPO_ROOT/.claude/agents" -name "*.md" -not -path "*/_archived/*" 2>/dev/null)
# Add reference files
while IFS= read -r f; do
    CLAIM_SOURCES+=("$f")
done < <(find "$REPO_ROOT/.claude/references" -name "*.md" 2>/dev/null)

# Patterns that indicate enforcement claims
# Each pattern extracts: the claim keyword, the file, the line number, and the full line
CLAIM_PATTERNS=(
    'MUST\b'
    'MUST NOT\b'
    '\bauto-REJECT'
    '\bauto-reject'
    '\benforces?\b'
    '\bBLOCK[S ]'
    '\bguard-[a-z]+'
    '\bhook\b.*\b(block|reject|deny|prevent)'
    '\b(block|reject|deny|prevent).*\bhook\b'
)

# Build combined regex
COMBINED_PATTERN=""
for p in "${CLAIM_PATTERNS[@]}"; do
    if [[ -z "$COMBINED_PATTERN" ]]; then
        COMBINED_PATTERN="$p"
    else
        COMBINED_PATTERN="${COMBINED_PATTERN}|${p}"
    fi
done

# Collect claims
declare -a CLAIM_FILES=()
declare -a CLAIM_LINES=()
declare -a CLAIM_TEXTS=()
declare -a CLAIM_KEYWORDS=()
CLAIM_COUNT=0

for src in "${CLAIM_SOURCES[@]}"; do
    [[ -f "$src" ]] || continue
    while IFS=: read -r lineno text; do
        # Skip markdown comments, code fence markers, table headers
        stripped=$(echo "$text" | sed 's/^[[:space:]]*//')
        [[ "$stripped" == "---"* ]] && continue
        [[ "$stripped" == '```'* ]] && continue
        [[ "$stripped" == "|---"* ]] && continue
        # Skip lines that are just describing the pattern (meta-documentation)
        [[ "$stripped" == *"CLAIM_PATTERNS"* ]] && continue

        # Extract the primary keyword
        keyword=""
        if echo "$text" | grep -qE 'MUST NOT\b'; then
            keyword="MUST NOT"
        elif echo "$text" | grep -qE '\bMUST\b'; then
            keyword="MUST"
        elif echo "$text" | grep -qiE 'auto-reject'; then
            keyword="auto-REJECT"
        elif echo "$text" | grep -qiE '\benforces?\b'; then
            keyword="enforces"
        elif echo "$text" | grep -qE '\bBLOCK'; then
            keyword="BLOCK"
        elif echo "$text" | grep -qE '\bguard-[a-z]+'; then
            keyword="guard-*"
        else
            keyword="hook-enforcement"
        fi

        CLAIM_FILES+=("$src")
        CLAIM_LINES+=("$lineno")
        CLAIM_TEXTS+=("$text")
        CLAIM_KEYWORDS+=("$keyword")
        CLAIM_COUNT=$(( CLAIM_COUNT + 1 ))
    done < <(grep -nE "$COMBINED_PATTERN" "$src" 2>/dev/null || true)
done

# ── Phase 2: Collect enforcement evidence ─────────────────────────────────

# Enforcement sources: hooks, test harnesses, guard scripts
ENFORCEMENT_FILES=()
while IFS= read -r f; do
    ENFORCEMENT_FILES+=("$f")
done < <(find "$REPO_ROOT/.claude/hooks" -name "*.sh" 2>/dev/null)
while IFS= read -r f; do
    ENFORCEMENT_FILES+=("$f")
done < <(find "$REPO_ROOT/tools" -name "*test*.sh" -o -name "guard-*.sh" -o -name "aegis-*lint*.sh" 2>/dev/null)

# Build a set of "enforcement tokens" -- things that enforcement code does
# We extract function names, variable names, file references from enforcement code
ENFORCEMENT_TOKENS=""
for ef in "${ENFORCEMENT_FILES[@]}"; do
    [[ -f "$ef" ]] || continue
    ENFORCEMENT_TOKENS+=$(cat "$ef" 2>/dev/null)
    ENFORCEMENT_TOKENS+=$'\n'
done

# ── Phase 3: Cross-reference claims against enforcement ───────────────────

UNMATCHED_COUNT=0
MATCHED_COUNT=0
SKIPPED_COUNT=0

declare -a UNMATCHED_FILES=()
declare -a UNMATCHED_LINES=()
declare -a UNMATCHED_TEXTS=()
declare -a UNMATCHED_KEYWORDS=()

for (( i=0; i<CLAIM_COUNT; i++ )); do
    file="${CLAIM_FILES[$i]}"
    line="${CLAIM_LINES[$i]}"
    text="${CLAIM_TEXTS[$i]}"
    keyword="${CLAIM_KEYWORDS[$i]}"

    # Heuristic: extract the "subject" of the claim
    # Look for specific enforceable tokens in the claim text
    matched=false

    # Check 1: Does the claim reference a specific guard/hook by name?
    if echo "$text" | grep -qoE 'guard-[a-z-]+\.sh'; then
        hook_name=$(echo "$text" | grep -oE 'guard-[a-z-]+\.sh' | head -1)
        if [[ -f "$REPO_ROOT/.claude/hooks/$hook_name" ]]; then
            matched=true
        fi
    fi

    # Check 2: Does the claim reference a specific tool by name?
    if [[ "$matched" == false ]]; then
        if echo "$text" | grep -qoE 'aegis-[a-z-]+\.sh'; then
            tool_name=$(echo "$text" | grep -oE 'aegis-[a-z-]+\.sh' | head -1)
            if [[ -f "$REPO_ROOT/tools/$tool_name" ]]; then
                matched=true
            fi
        fi
    fi

    # Check 3: Does the claim reference a hook event type that has a handler?
    if [[ "$matched" == false ]]; then
        if echo "$text" | grep -qiE 'PreToolUse|PostToolUse|SessionStart|Stop'; then
            # These are wired in settings.json
            matched=true
        fi
    fi

    # Check 4: Does enforcement code contain keywords from the claim?
    if [[ "$matched" == false ]]; then
        # Extract significant words from the claim (3+ chars, not common words)
        claim_tokens=$(echo "$text" | tr '[:upper:]' '[:lower:]' | \
            grep -oE '[a-z_-]{4,}' | \
            grep -vE '^(must|that|this|with|from|when|will|should|have|been|does|their|they|them|than|then|each|only|also|into|such|more|other|which|what|were|would|could|make|like|after|before|every|never|always)$' | \
            sort -u | head -5)

        for token in $claim_tokens; do
            if echo "$ENFORCEMENT_TOKENS" | grep -qi "$token" 2>/dev/null; then
                matched=true
                break
            fi
        done
    fi

    # Check 5: Is this a documentation-only claim (describes behavior, not enforcement)?
    # Claims in retrospectives, learnings, or that describe past events are skipped
    if echo "$file" | grep -qE '(retrospective|learning|handoff|resonance)'; then
        SKIPPED_COUNT=$(( SKIPPED_COUNT + 1 ))
        continue
    fi

    if [[ "$matched" == true ]]; then
        MATCHED_COUNT=$(( MATCHED_COUNT + 1 ))
    else
        UNMATCHED_COUNT=$(( UNMATCHED_COUNT + 1 ))
        UNMATCHED_FILES+=("$file")
        UNMATCHED_LINES+=("$line")
        UNMATCHED_TEXTS+=("$text")
        UNMATCHED_KEYWORDS+=("$keyword")
    fi
done

# ── Phase 4: Output report ────────────────────────────────────────────────

if [[ "$JSON_MODE" == true ]]; then
    python3 - "$CLAIM_COUNT" "$MATCHED_COUNT" "$UNMATCHED_COUNT" "$SKIPPED_COUNT" <<'PYEOF'
import json, sys, os
total, matched, unmatched, skipped = [int(x) for x in sys.argv[1:5]]
report = {
    "total_claims": total,
    "matched": matched,
    "unmatched": unmatched,
    "skipped_non_enforcement": skipped,
    "coverage_pct": round(matched / max(matched + unmatched, 1) * 100, 1),
}
print(json.dumps(report, indent=2))
PYEOF
else
    echo "=== AEGIS Policy-Without-Test Audit ==="
    echo ""
    echo "Claims scanned:     $CLAIM_COUNT"
    echo "  Matched:          $MATCHED_COUNT"
    echo "  Unmatched:        $UNMATCHED_COUNT"
    echo "  Skipped (non-enf): $SKIPPED_COUNT"
    COVERAGE=$(python3 -c "print(round($MATCHED_COUNT / max($MATCHED_COUNT + $UNMATCHED_COUNT, 1) * 100, 1))")
    echo "  Coverage:         ${COVERAGE}%"
    echo ""

    if [[ "$VERBOSE" == true && $UNMATCHED_COUNT -gt 0 ]]; then
        echo "--- Unmatched Claims (no enforcement code found) ---"
        echo ""
        for (( i=0; i<UNMATCHED_COUNT; i++ )); do
            rel_file="${UNMATCHED_FILES[$i]#$REPO_ROOT/}"
            echo "  [$((i+1))] ${rel_file}:${UNMATCHED_LINES[$i]}"
            echo "      Keyword: ${UNMATCHED_KEYWORDS[$i]}"
            # Truncate long lines
            claim_text="${UNMATCHED_TEXTS[$i]}"
            if [[ ${#claim_text} -gt 120 ]]; then
                claim_text="${claim_text:0:117}..."
            fi
            echo "      Text: $claim_text"
            echo ""
        done
    fi
fi

if [[ $UNMATCHED_COUNT -gt 0 ]]; then
    exit 1
else
    echo "All policy claims have matching enforcement evidence."
    exit 0
fi
