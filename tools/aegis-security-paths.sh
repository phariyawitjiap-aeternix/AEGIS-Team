#!/usr/bin/env bash
# AEGIS Security-Sensitive Path Registry (Sprint v9-02 S2-04)
#
# Emits the canonical list of security-sensitive path regexes, one per line.
# Single source of truth referenced by:
#   - tools/aegis-s204-override.sh (runtime override logic)
#   - tools/aegis-s204-override-test.sh (test harness)
#
# Usage:
#   source tools/aegis-security-paths.sh   # not recommended — use via pipe
#   bash tools/aegis-security-paths.sh     # emits patterns to stdout
#
# Each line is a regex suitable for use with grep -E.
# Patterns are anchored to prevent substring false-positives.
# See spec S2-04 §3 Path Pattern table for category mapping.

cat <<'EOF'
(^|/)auth/
(^|/)credentials/
(^|/)\.env
(^|/)secrets/
(^|/)\.ssh/
(^|/)tokens/
(^|/)\.claude/agents/
(^|/)password
(^|/)secret($|[^s])
(^|/)api-key
EOF
