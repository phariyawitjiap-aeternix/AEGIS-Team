#!/usr/bin/env bash
# ============================================================================
# AEGIS — macOS new-machine bootstrap (prerequisites layer)
#
# install.sh / install-remote.sh assume node + git + claude-code already exist
# and only ERROR if they don't. On a fresh Mac (e.g. a new mac-mini) nothing is
# installed yet. This script fills that gap: it installs the prerequisites
# (Xcode CLT, Homebrew, Node.js, Claude Code CLI) idempotently, then hands off
# to install-remote.sh for the actual AEGIS install.
#
# One-command new machine + new project:
#   bash <(curl -sL https://raw.githubusercontent.com/phariyawitjiap-aeternix/AEGIS-Team/main/bootstrap-macos.sh) --new my-project
#
# Prereqs only (then install AEGIS yourself later):
#   bash <(curl -sL https://raw.githubusercontent.com/phariyawitjiap-aeternix/AEGIS-Team/main/bootstrap-macos.sh)
#
# Any flags after the script name are forwarded verbatim to install-remote.sh
# (e.g. --new <slug>, --profile full, --project-name "My App", --upgrade).
#
# Safe to re-run: every step checks before it installs.
# bash 3.2 compatible (macOS default shell) — no `declare -A`, no mapfile.
# ============================================================================
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/phariyawitjiap-aeternix/AEGIS-Team/main"
FORWARD_ARGS=("$@")   # everything after the script name → install-remote.sh

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'
info()  { printf "${BLUE}[bootstrap]${NC} %s\n" "$*"; }
ok()    { printf "${GREEN}[ok]${NC} %s\n" "$*"; }
warn()  { printf "${YELLOW}[warn]${NC} %s\n" "$*"; }
die()   { printf "${RED}[error]${NC} %s\n" "$*" >&2; exit 1; }

# --------------------------------------------------------------------------
# 0. Guard: macOS only
# --------------------------------------------------------------------------
[[ "$(uname -s)" == "Darwin" ]] || die "This bootstrap is macOS-only (uname=$(uname -s)). On Linux install node+git+claude-code manually, then run install-remote.sh."

printf "${BOLD}AEGIS macOS bootstrap${NC} — installing prerequisites (idempotent)\n"

# --------------------------------------------------------------------------
# 1. Xcode Command Line Tools (provides git, cc)
# --------------------------------------------------------------------------
if xcode-select -p >/dev/null 2>&1; then
    ok "Xcode Command Line Tools present"
else
    info "Installing Xcode Command Line Tools (a GUI dialog will pop up — click Install)…"
    xcode-select --install || true
    warn "Finish the Xcode CLT dialog, then re-run this script."
    exit 0
fi

# --------------------------------------------------------------------------
# 2. Homebrew (Apple Silicon → /opt/homebrew, Intel → /usr/local)
# --------------------------------------------------------------------------
if command -v brew >/dev/null 2>&1; then
    ok "Homebrew present: $(brew --version | head -1)"
else
    info "Installing Homebrew (may prompt for your password)…"
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
# Ensure brew is on PATH for THIS shell (both arch locations).
if [[ -x /opt/homebrew/bin/brew ]]; then eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then eval "$(/usr/local/bin/brew shellenv)"; fi
command -v brew >/dev/null 2>&1 || die "Homebrew installed but not on PATH — open a new Terminal and re-run."

# --------------------------------------------------------------------------
# 3. Node.js (+ npm)
# --------------------------------------------------------------------------
if command -v node >/dev/null 2>&1; then
    ok "Node.js present: $(node --version)"
else
    info "Installing Node.js via Homebrew…"
    brew install node
fi
command -v npm >/dev/null 2>&1 || die "npm not found after node install."

# --------------------------------------------------------------------------
# 4. Claude Code CLI
# --------------------------------------------------------------------------
if command -v claude >/dev/null 2>&1; then
    ok "Claude Code CLI present: $(claude --version 2>/dev/null || echo installed)"
else
    info "Installing Claude Code CLI (npm -g @anthropic-ai/claude-code)…"
    npm install -g @anthropic-ai/claude-code
fi

# --------------------------------------------------------------------------
# 5. git (should come from Xcode CLT; belt-and-suspenders)
# --------------------------------------------------------------------------
command -v git >/dev/null 2>&1 || { info "Installing git…"; brew install git; }
ok "git present: $(git --version)"

printf "\n${GREEN}${BOLD}✓ Prerequisites ready.${NC}\n"

# --------------------------------------------------------------------------
# 6. Hand off to install-remote.sh (only if install args were provided)
# --------------------------------------------------------------------------
if [[ ${#FORWARD_ARGS[@]} -gt 0 ]]; then
    info "Running AEGIS installer: install-remote.sh ${FORWARD_ARGS[*]}"
    bash <(curl -sL "${REPO_RAW}/install-remote.sh") "${FORWARD_ARGS[@]}"
    printf "\n${GREEN}${BOLD}✓ Done.${NC} Next: run ${BOLD}claude${NC}, type ${BOLD}/login${NC} (one-time OAuth), then ${BOLD}/aegis-start${NC}.\n"
else
    cat <<NEXT

Next steps (no install args were given, prerequisites only):

  1. Authenticate Claude Code (one-time):
       claude          # then type: /login   (OAuth in your browser), then /exit

  2. Install AEGIS into a NEW project (creates dir + git init + full setup):
       bash <(curl -sL ${REPO_RAW}/install-remote.sh) --new my-project

     …or into an EXISTING project directory:
       cd ~/path/to/project
       bash <(curl -sL ${REPO_RAW}/install-remote.sh) --profile standard

  3. Open the project in Claude Code and run:  /aegis-start

Tip: you could have chained step 2 into this bootstrap, e.g.
     bash <(curl -sL ${REPO_RAW}/bootstrap-macos.sh) --new my-project
NEXT
fi
