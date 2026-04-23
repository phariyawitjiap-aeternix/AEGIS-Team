#!/usr/bin/env bash
# aegis-shell-lint.sh (F1-05) — Shell-command pre-flight linter for spec files.
#
# Scans a markdown spec file for shell command references and validates them
# against a curated allowlist and PATH availability. Advisory exit codes:
#   Exit 0: all commands known (allowlisted or available)
#   Exit 1: unknown command references found (possible typo)
#
# Usage:
#   tools/aegis-shell-lint.sh --file <spec.md>
#
# Bash 3.2 compatible.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Allowlist ─────────────────────────────────────────────────────────────────
# Curated set of known-good commands. If a spec references something here it's OK.
KNOWN_GOOD=(
    # coreutils / POSIX
    basename cat chmod cp cut date dirname echo env false head ln ls
    mkdir mktemp mv printf pwd readlink realpath rm rmdir sed sleep sort
    tail tee touch tr true uniq wc xargs
    # common tools
    awk bash curl flock git grep greadlink jq python3 tar tput yq
    # macOS extras (always present on supported platforms)
    open pbcopy pbpaste sw_vers
    # CI / build
    make npm npx node
    # AEGIS custom (auto-discovered below)
)

# Auto-append tools/ directory scripts (both with and without .sh extension)
if [[ -d "$SCRIPT_DIR" ]]; then
    for f in "${SCRIPT_DIR}"/*.sh; do
        [[ -f "$f" ]] || continue
        KNOWN_GOOD+=("$(basename "$f" .sh)" "$(basename "$f")")
    done
fi

# ── Args ──────────────────────────────────────────────────────────────────────
FILE=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --file) FILE="$2"; shift 2 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

if [[ -z "$FILE" ]]; then
    echo "Usage: $0 --file <spec.md>" >&2
    exit 1
fi

if [[ ! -f "$FILE" ]]; then
    echo "ERROR: file not found: $FILE" >&2
    exit 1
fi

# ── Helpers ───────────────────────────────────────────────────────────────────
in_allowlist() {
    local cmd="$1"
    local item
    for item in "${KNOWN_GOOD[@]}"; do
        if [[ "$item" == "$cmd" ]]; then
            return 0
        fi
    done
    return 1
}

is_available() {
    command -v "$1" >/dev/null 2>&1
}

# Check if a command appears near a fallback indicator in the spec
has_fallback_nearby() {
    local cmd="$1"
    # Search for fallback/alternative/if unavailable/|| within 3 lines of the command
    python3 - "$FILE" "$cmd" <<'PYEOF' 2>/dev/null
import sys, re
path, cmd = sys.argv[1], sys.argv[2]
try:
    with open(path) as f:
        lines = f.readlines()
except Exception:
    sys.exit(1)
fallback_words = ['fallback', 'alternative', 'if unavailable', '||', 'or install', 'brew install']
for i, line in enumerate(lines):
    if cmd in line:
        # Check a window of 3 lines before/after
        window_start = max(0, i - 3)
        window_end = min(len(lines), i + 4)
        window = ''.join(lines[window_start:window_end])
        if any(w in window.lower() for w in fallback_words):
            sys.exit(0)  # fallback detected
sys.exit(1)  # no fallback found
PYEOF
}

# ── Extract candidate command tokens from spec ───────────────────────────────
# Extracts backtick-quoted tokens and fenced code block first-word-per-line
extract_commands() {
    python3 - "$FILE" <<'PYEOF' 2>/dev/null
import sys, re

try:
    with open(sys.argv[1]) as f:
        content = f.read()
except Exception:
    sys.exit(0)

candidates = set()

# Backtick tokens: `word` and `word args`
for m in re.finditer(r'`([^`]+)`', content):
    tokens = m.group(1).split()
    if tokens:
        # First word is the command; filter to look like a command name
        cmd = tokens[0]
        candidates.add(cmd)

# Fenced code blocks: first word on each line
in_block = False
for line in content.split('\n'):
    if line.strip().startswith('```'):
        in_block = not in_block
        continue
    if in_block and line.strip():
        tokens = line.strip().split()
        if tokens:
            candidates.add(tokens[0])

# Filter: keep only tokens that look like command names
# (alphanumeric + hyphens, not starting with $, /, ., #, -, quotes)
result = set()
cmd_re = re.compile(r'^[a-zA-Z][a-zA-Z0-9_-]*$')
for c in candidates:
    # Skip variables, paths, flags
    if c.startswith(('$', '/', '.', '#', '-', '"', "'")):
        continue
    # Skip common non-command words (markdown, language keywords, etc.)
    skip_words = {
        'if', 'then', 'else', 'fi', 'for', 'do', 'done', 'while',
        'true', 'false', 'local', 'export', 'return', 'echo', 'exit',
        'source', 'set', 'unset', 'shift', 'case', 'esac', 'in',
        'import', 'print', 'sys', 'json', 'os', 'python', 'and', 'or',
        'not', 'with', 'as', 'from', 'class', 'def', 'pass', 'break',
        'continue', 'try', 'except', 'finally', 'raise', 'None', 'True',
        'False', 'Yes', 'No', 'OK', 'WARN', 'INFO', 'ERROR', 'DEBUG',
        'Step', 'Note', 'See', 'The', 'If', 'When', 'Run', 'Use',
        'After', 'Before', 'This', 'That', 'Each', 'All', 'Any',
        'bash', 'sh', 'zsh', 'fish',
    }
    if c in skip_words:
        continue
    if cmd_re.match(c) and len(c) >= 2:
        result.add(c)

for cmd in sorted(result):
    print(cmd)
PYEOF
}

# ── Main validation ───────────────────────────────────────────────────────────
UNKNOWN=()
WARNED=()

# Read all candidate commands
while IFS= read -r cmd; do
    [[ -z "$cmd" ]] && continue

    # Already in allowlist?
    if in_allowlist "$cmd"; then
        continue
    fi

    # Available on PATH?
    if is_available "$cmd"; then
        continue
    fi

    # Has a fallback indicator nearby?
    if has_fallback_nearby "$cmd"; then
        WARNED+=("$cmd (has fallback)")
        continue
    fi

    # Check if it looks like a known typo pattern (e.g., greadpath vs greadlink)
    # Heuristic: if it starts with 'g' and is not in allowlist, it might be a typo
    UNKNOWN+=("$cmd")

done < <(extract_commands)

# ── Report ────────────────────────────────────────────────────────────────────
echo "aegis-shell-lint: ${FILE}"
echo ""

if [[ ${#WARNED[@]} -gt 0 ]]; then
    echo "ADVISORY (fallback detected):"
    for w in "${WARNED[@]}"; do
        echo "  WARN: $w"
    done
    echo ""
fi

if [[ ${#UNKNOWN[@]} -eq 0 ]]; then
    echo "OK: all command references validated"
    exit 0
else
    echo "UNKNOWN commands (not in allowlist, not on PATH, no fallback):"
    for u in "${UNKNOWN[@]}"; do
        echo "  UNKNOWN: $u  -- add to allowlist or include a fallback"
    done
    echo ""
    echo "Exit 1: ${#UNKNOWN[@]} unknown command(s) found"
    exit 1
fi
