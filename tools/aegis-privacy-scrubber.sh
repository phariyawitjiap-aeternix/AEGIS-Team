#!/usr/bin/env bash
# =============================================================================
# aegis-privacy-scrubber.sh
# Privacy guard for Tier 1 -> Tier 2 brain promotion (S7-05 implementation)
# =============================================================================
# Reads pattern content from stdin or file, removes project-specific data,
# writes scrubbed version to stdout.
#
# Removes:
#   - File paths starting with /Users/<name>/ or /home/<name>/
#   - Email addresses
#   - API keys (sk-, pk_, AKIA, ghp_, github_pat_, etc.)
#   - Project task IDs (PROJ-T-N, ABC-123 patterns)
#   - Commit hashes (40-char hex)
#   - Private repo URLs (github.com/org/private-*, internal.*)
#   - IP addresses
#
# Keeps:
#   - General patterns / best practices
#   - Generic code examples
#   - Workflow descriptions
#
# Usage:
#   ./tools/aegis-privacy-scrubber.sh < input.md > scrubbed.md
#   ./tools/aegis-privacy-scrubber.sh --check < input.md   # exit 1 if found PII
#   echo "leak: ghp_abc123" | ./tools/aegis-privacy-scrubber.sh
# =============================================================================

set -euo pipefail

CHECK_ONLY=false
QUIET=false

while [ $# -gt 0 ]; do
    case "$1" in
        --check) CHECK_ONLY=true; shift ;;
        --quiet) QUIET=true; shift ;;
        --help|-h)
            sed -n '2,30p' "$0"
            exit 0
            ;;
        *) echo "Unknown arg: $1" >&2; exit 2 ;;
    esac
done

INPUT=$(cat)
SCRUBBED="$INPUT"
FOUND_PII=0

# ────────────────────────────────────────────────────────────────────────────
# Patterns
# ────────────────────────────────────────────────────────────────────────────

# 1. User home paths -> replaced with generic
SCRUBBED=$(echo "$SCRUBBED" | sed -E 's|/Users/[a-zA-Z0-9._-]+|/Users/<USER>|g')
SCRUBBED=$(echo "$SCRUBBED" | sed -E 's|/home/[a-zA-Z0-9._-]+|/home/<USER>|g')

if echo "$INPUT" | grep -qE '/(Users|home)/[a-zA-Z0-9._-]+'; then
    FOUND_PII=$((FOUND_PII + 1))
    [ "$QUIET" = false ] && echo "PII: user home paths" >&2
fi

# 2. Email addresses -> redacted
SCRUBBED=$(echo "$SCRUBBED" | sed -E 's|[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}|<REDACTED-EMAIL>|g')

if echo "$INPUT" | grep -qE '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'; then
    FOUND_PII=$((FOUND_PII + 1))
    [ "$QUIET" = false ] && echo "PII: email addresses" >&2
fi

# 3. API keys -> redacted
# OpenAI / Anthropic style
SCRUBBED=$(echo "$SCRUBBED" | sed -E 's|sk-[A-Za-z0-9_-]{20,}|<REDACTED-API-KEY>|g')
SCRUBBED=$(echo "$SCRUBBED" | sed -E 's|pk_live_[A-Za-z0-9]{20,}|<REDACTED-API-KEY>|g')
SCRUBBED=$(echo "$SCRUBBED" | sed -E 's|pk_test_[A-Za-z0-9]{20,}|<REDACTED-API-KEY>|g')
# AWS
SCRUBBED=$(echo "$SCRUBBED" | sed -E 's|AKIA[A-Z0-9]{16}|<REDACTED-AWS-KEY>|g')
# GitHub (token lengths vary)
SCRUBBED=$(echo "$SCRUBBED" | sed -E 's|ghp_[A-Za-z0-9]{20,}|<REDACTED-GH-TOKEN>|g')
SCRUBBED=$(echo "$SCRUBBED" | sed -E 's|github_pat_[A-Za-z0-9_]{20,}|<REDACTED-GH-PAT>|g')

if echo "$INPUT" | grep -qE '(sk-[A-Za-z0-9_-]{20,}|AKIA[A-Z0-9]{16}|ghp_[A-Za-z0-9]{36}|github_pat_)'; then
    FOUND_PII=$((FOUND_PII + 1))
    [ "$QUIET" = false ] && echo "PII: API keys / tokens" >&2
fi

# 4. Project task IDs (PROJ-T-N, ABC-123 patterns)
SCRUBBED=$(echo "$SCRUBBED" | sed -E 's|PROJ-[A-Z]+-[0-9]+|<TASK-ID>|g')
SCRUBBED=$(echo "$SCRUBBED" | sed -E 's|\b[A-Z]{2,5}-[0-9]{2,5}\b|<TASK-ID>|g')

# 5. Commit hashes (40-char hex)
# Match in 3 contexts: middle of line, end of line, start of line
SCRUBBED=$(echo "$SCRUBBED" | sed -E 's|([^a-zA-Z0-9])[0-9a-f]{40}([^a-zA-Z0-9])|\1<COMMIT-HASH>\2|g')
SCRUBBED=$(echo "$SCRUBBED" | sed -E 's|([^a-zA-Z0-9])[0-9a-f]{40}$|\1<COMMIT-HASH>|g')
SCRUBBED=$(echo "$SCRUBBED" | sed -E 's|^[0-9a-f]{40}([^a-zA-Z0-9])|<COMMIT-HASH>\1|g')
# Short hashes (7-12 char hex prefix in commit context)
SCRUBBED=$(echo "$SCRUBBED" | sed -E 's|commit [0-9a-f]{7,12}|commit <SHORT-HASH>|g')

# 6. Private repo URLs (best-effort)
SCRUBBED=$(echo "$SCRUBBED" | sed -E 's|github\.com/[a-zA-Z0-9_-]+/private-[a-zA-Z0-9_-]+|github.com/<ORG>/<PRIVATE-REPO>|g')
SCRUBBED=$(echo "$SCRUBBED" | sed -E 's|internal\.[a-zA-Z0-9_.-]+|<INTERNAL-HOST>|g')

# 7. IP addresses (IPv4; macOS sed -- anchor with non-digit context)
SCRUBBED=$(echo "$SCRUBBED" | sed -E 's|([^0-9.])([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})([^0-9.])|\1<IP>\3|g')
# Edge case: IP at line start
SCRUBBED=$(echo "$SCRUBBED" | sed -E 's|^([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})([^0-9.])|<IP>\2|g')

# ────────────────────────────────────────────────────────────────────────────
# Output
# ────────────────────────────────────────────────────────────────────────────

if [ "$CHECK_ONLY" = true ]; then
    if [ "$FOUND_PII" -gt 0 ]; then
        [ "$QUIET" = false ] && echo "Found ${FOUND_PII} PII categories" >&2
        exit 1
    fi
    exit 0
fi

echo "$SCRUBBED"
