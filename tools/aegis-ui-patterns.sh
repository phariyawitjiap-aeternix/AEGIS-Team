#!/usr/bin/env bash
# tools/aegis-ui-patterns.sh — SSOT for UI file patterns (S3-05)
#
# Single canonical source of truth for UI INCLUDE and EXCLUDE patterns.
# Used by guard-ui-edit.sh (hook), aegis-block0-f-gate-test.sh, and any
# future consumers.
#
# !! DO NOT EDIT patterns without updating all consumers !!
# !! Consumers: .claude/hooks/guard-ui-edit.sh             !!
# !!            tools/aegis-block0-f-gate-test.sh          !!
# !!            .claude/agents/nick-fury.md (prose ref)    !!
# !!            .claude/agents/coulson.md (prose ref)      !!
#
# Source this file; it sets two sets of arrays AND exports two functions:
#   is_ui_file <path>       — returns 0 if path matches INCLUDE patterns
#   is_excluded_file <path> — returns 0 if path matches EXCLUDE patterns
#
# Usage (from same directory):
#   source "$(dirname "$0")/aegis-ui-patterns.sh"
# Usage (from hooks, absolute):
#   source "$(git rev-parse --show-toplevel)/tools/aegis-ui-patterns.sh"
# Usage (via env override):
#   source "${AEGIS_REPO_ROOT:-$(pwd)}/tools/aegis-ui-patterns.sh"
#
# set -u compatibility: all arrays declared unconditionally before populate.

# --- INCLUDE: file extensions (declare empty first for set -u compat) ---
UI_INCLUDE_EXTENSIONS=()
UI_INCLUDE_EXTENSIONS=("tsx" "jsx" "css" "scss" "vue" "svelte")

# --- INCLUDE: directory prefixes ---
UI_INCLUDE_DIRS=()
UI_INCLUDE_DIRS=("src/components/" "src/pages/" "src/styles/" "src/ui/" "app/components/")

# --- EXCLUDE: test/spec/stories suffixes ---
UI_EXCLUDE_SUFFIXES=()
UI_EXCLUDE_SUFFIXES=("test" "spec" "stories")

# --- EXCLUDE: config file extensions (paired with .config. middle segment) ---
UI_EXCLUDE_CONFIG_EXTENSIONS=()
UI_EXCLUDE_CONFIG_EXTENSIONS=("tsx" "jsx" "js" "ts" "mjs" "cjs")

# --- EXCLUDE: directory markers ---
UI_EXCLUDE_DIRS=()
UI_EXCLUDE_DIRS=("__tests__" "__mocks__")

# --- EXCLUDE: file name prefixes ---
UI_EXCLUDE_PREFIXES=()
UI_EXCLUDE_PREFIXES=("setupTests")

# --- Combined convenience arrays (for consumers that iterate a flat list) ---
UI_INCLUDE_PATTERNS=()
UI_EXCLUDE_PATTERNS=()

for _ext in "${UI_INCLUDE_EXTENSIONS[@]}"; do
    UI_INCLUDE_PATTERNS+=("*.${_ext}")
done
for _dir in "${UI_INCLUDE_DIRS[@]}"; do
    UI_INCLUDE_PATTERNS+=("${_dir}**")
done

for _suf in "${UI_EXCLUDE_SUFFIXES[@]}"; do
    UI_EXCLUDE_PATTERNS+=("*.${_suf}.*")
done
UI_EXCLUDE_PATTERNS+=("*.config.*")
for _dir in "${UI_EXCLUDE_DIRS[@]}"; do
    UI_EXCLUDE_PATTERNS+=("**/${_dir}/**")
done
UI_EXCLUDE_PATTERNS+=("**/setupTests.*")
unset _ext _dir _suf

# ── Functions ──────────────────────────────────────────────────────────────
# Behavioral contract: identical true/false results as the inline
# implementations formerly in guard-ui-edit.sh lines 51-64 and 74-85.

is_excluded_file() {
    local path="$1"
    # *.test.{tsx,jsx,css,scss,js,ts}  *.spec.*  *.stories.*
    [[ "$path" =~ \.(test|spec|stories)\.(tsx|jsx|css|scss|js|ts)$ ]] && return 0
    # *.config.{tsx,jsx,js,ts,mjs,cjs}
    [[ "$path" =~ \.config\.(tsx|jsx|js|ts|mjs|cjs)$ ]] && return 0
    # **/__tests__/**
    [[ "$path" =~ (^|/)'__tests__'/ ]] && return 0
    # **/__mocks__/**
    [[ "$path" =~ (^|/)'__mocks__'/ ]] && return 0
    # **/setupTests.*
    [[ "$path" =~ (^|/)setupTests\. ]] && return 0
    return 1
}

is_ui_file() {
    local path="$1"
    # UI file extensions
    [[ "$path" =~ \.(tsx|jsx|css|scss|vue|svelte)$ ]] && return 0
    # UI source directories
    [[ "$path" =~ (^|/)src/components/ ]] && return 0
    [[ "$path" =~ (^|/)src/pages/ ]] && return 0
    [[ "$path" =~ (^|/)src/styles/ ]] && return 0
    [[ "$path" =~ (^|/)src/ui/ ]] && return 0
    [[ "$path" =~ (^|/)app/components/ ]] && return 0
    return 1
}
