#!/usr/bin/env bash
# AEGIS Maintainer Grant (ADR-004 Phase 2)
# Generates a time-bound, one-shot grant token for guard-write.sh.
#
# The human runs this from THEIR terminal -- never from inside a Claude Code
# session. The helper emits an `export` line for the caller to eval; the
# resulting env is inherited by the Claude Code process launched afterward.
#
# Usage:
#   eval "$(./tools/aegis-maintainer-grant.sh <path>)"
#   # Then launch (or resume) Claude Code in the same terminal.
#
# The grant is consumed on the first matching write and auto-expires after
# 60 seconds. One grant = one edit. Re-run this helper for each subsequent
# authorized write.
#
# Path argument: a single file path relative to the repo root. Wildcards are
# rejected -- ADR-004 bans wildcard scopes.
#
# Exit codes:
#   0 = grant emitted on stdout
#   2 = usage error / invalid path

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

TTL_SECONDS=60

usage() {
    cat >&2 <<'EOF'
Usage: aegis-maintainer-grant.sh <path>

<path> must be:
  - A single file path (no wildcards, no globs, no directories)
  - Relative to the repo root (e.g. .claude/settings.json)

Example:
  eval "$(./tools/aegis-maintainer-grant.sh .claude/settings.json)"
EOF
    exit 2
}

[[ $# -eq 1 ]] || usage

TARGET_PATH="$1"

# --- Validate path ---
# Reject wildcards: * ? [ ]
case "$TARGET_PATH" in
    *\**|*\?*|*\[*|*\]*) echo "ERROR: wildcards not allowed in grant path" >&2; exit 2 ;;
esac

# Reject absolute paths -- grant must be repo-relative
case "$TARGET_PATH" in
    /*) echo "ERROR: path must be repo-relative, not absolute" >&2; exit 2 ;;
esac

# Reject directory references (trailing slash or existing directory)
case "$TARGET_PATH" in
    */) echo "ERROR: path must be a file, not a directory" >&2; exit 2 ;;
esac
if [[ -d "${REPO_ROOT}/${TARGET_PATH}" ]]; then
    echo "ERROR: path resolves to a directory, not a file" >&2
    exit 2
fi

# Reject parent-dir traversal
case "$TARGET_PATH" in
    *..*) echo "ERROR: path must not contain '..'" >&2; exit 2 ;;
esac

# --- Generate nonce (16 hex chars from /dev/urandom) ---
NONCE=$(head -c 8 /dev/urandom | od -An -tx1 | tr -d ' \n')

# --- Compute expiry epoch ---
NOW=$(date -u +%s)
EXPIRY=$((NOW + TTL_SECONDS))

# --- Emit grant ---
# Format: <path>|<nonce>|<expiry-epoch>
# The caller evals this output; the resulting env is inherited by Claude Code.
echo "export AEGIS_MAINTAINER_MODE='${TARGET_PATH}|${NONCE}|${EXPIRY}'"

# --- Emit human-readable preview on stderr ---
cat >&2 <<EOF
AEGIS Maintainer Grant:
  path:    ${TARGET_PATH}
  nonce:   ${NONCE:0:8}... (one-shot)
  expires: $(date -u -r "${EXPIRY}" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d "@${EXPIRY}" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "in ${TTL_SECONDS}s")
  ttl:     ${TTL_SECONDS}s

Next step: eval this command in your terminal, then launch Claude Code:
  eval "\$(./tools/aegis-maintainer-grant.sh ${TARGET_PATH})"
EOF
