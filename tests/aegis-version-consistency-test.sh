#!/usr/bin/env bash
# aegis-version-consistency-test.sh — guard against VERSION/banner drift.
#
# After v11 Phase-1 shipped, the VERSION file lagged at 9.0 (caught during
# kam-tong-ham bootstrap). This test prevents that class of skew by
# asserting the major version in VERSION matches every CLAUDE*.md banner
# and the README.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
PASS=0; FAIL=0
pass() { echo -e "${GREEN}PASS${NC}: $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}FAIL${NC}: $1 -- $2"; FAIL=$((FAIL+1)); }

VERSION=$(cat "$REPO_ROOT/VERSION" | tr -d '[:space:]')
MAJOR=${VERSION%%.*}

echo "============================================"
echo "AEGIS version consistency — VERSION=$VERSION major=v$MAJOR"
echo "============================================"

check_banner() {
  local file="$1" pattern="$2" label="$3"
  if grep -qE "$pattern" "$REPO_ROOT/$file" 2>/dev/null; then
    pass "$label ($file matches v$MAJOR)"
  else
    fail "$label" "$file: expected v$MAJOR.x, head: $(head -1 "$REPO_ROOT/$file" 2>/dev/null)"
  fi
}

# Each banner should reference v<MAJOR>.* (e.g. v11.0).
check_banner "CLAUDE.md"        "AEGIS v${MAJOR}\\.[0-9]+ -- Agent Team Framework"        "CLAUDE.md banner"
check_banner "CLAUDE_lessons.md" "AEGIS v${MAJOR}\\.[0-9]+ -- Lessons Learned"             "CLAUDE_lessons.md banner"
check_banner "CLAUDE_safety.md"  "AEGIS v${MAJOR}\\.[0-9]+ -- Safety Rules"                "CLAUDE_safety.md banner"
check_banner "CLAUDE_skills.md"  "AEGIS Skills Catalog v${MAJOR}\\.[0-9]+"                 "CLAUDE_skills.md banner"
check_banner "PROJECT_INDEX.md"  "AEGIS v${MAJOR}\\.[0-9]+ AI Agent Team Framework"        "PROJECT_INDEX.md banner"
check_banner "README.md"         "AEGIS v${MAJOR}\\.[0-9]+ — AI Agent Team Framework"      "README.md banner"
check_banner "install-remote.sh" "AEGIS v${MAJOR}\\.[0-9]+ — Remote Installer"             "install-remote.sh banner"
check_banner "assets/logo/README.md" "Brand assets for AEGIS v${MAJOR}\\.[0-9]+"           "assets/logo banner"

echo ""
echo "============================================"
echo "RESULTS: ${PASS} passed, ${FAIL} failed"
echo "============================================"
[[ $FAIL -eq 0 ]] && { echo -e "${GREEN}ALL PASSED${NC}"; exit 0; } || { echo -e "${RED}FAILURES${NC}"; exit 1; }
