#!/usr/bin/env bash
# =============================================================================
# aegis-migrate-consolidate.sh
# AEGIS v9 POC: Consolidate _aegis-brain/ -> .aegis/brain/
# =============================================================================
# Usage:
#   ./tools/aegis-migrate-consolidate.sh                          # dry-run
#   ./tools/aegis-migrate-consolidate.sh --apply                  # migrate
#   ./tools/aegis-migrate-consolidate.sh --rollback               # reverse
#   ./tools/aegis-migrate-consolidate.sh --apply --gitignore-mode private
#   ./tools/aegis-migrate-consolidate.sh --apply --yes            # skip confirm
#   ./tools/aegis-migrate-consolidate.sh --apply --force          # skip git-clean check
#   ./tools/aegis-migrate-consolidate.sh --help
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Resolve absolute project root (works regardless of CWD)
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ---------------------------------------------------------------------------
# Colours (degrade gracefully if terminal doesn't support them)
# ---------------------------------------------------------------------------
if [ -t 1 ]; then
  C_RESET='\033[0m'
  C_GREEN='\033[0;32m'
  C_YELLOW='\033[1;33m'
  C_RED='\033[0;31m'
  C_CYAN='\033[0;36m'
  C_BOLD='\033[1m'
else
  C_RESET='' C_GREEN='' C_YELLOW='' C_RED='' C_CYAN='' C_BOLD=''
fi

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
MODE="dry-run"         # dry-run | apply | rollback
GITIGNORE_MODE="shared"  # shared | private | paranoid
SKIP_CONFIRM=false
FORCE_GIT=false
FORCE_OVERWRITE=false

# ---------------------------------------------------------------------------
# Source / destination paths
# ---------------------------------------------------------------------------
SRC="${PROJECT_ROOT}/_aegis-brain"
DST_ROOT="${PROJECT_ROOT}/.aegis"
DST="${DST_ROOT}/brain"
MANIFEST="${DST_ROOT}/.migration-manifest.json"
BACKUP_ROOT="${PROJECT_ROOT}/.aegis-backup"
LOG_DIR="${DST_ROOT}/logs"

GITIGNORE="${PROJECT_ROOT}/.gitignore"
SENTINEL_START="# <<< AEGIS-V9-START >>>"
SENTINEL_END="# <<< AEGIS-V9-END >>>"

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --apply)
        MODE="apply"
        shift
        ;;
      --rollback)
        MODE="rollback"
        shift
        ;;
      --dry-run)
        MODE="dry-run"
        shift
        ;;
      --gitignore-mode)
        if [ -z "${2:-}" ]; then
          die "--gitignore-mode requires a value: shared|private|paranoid"
        fi
        case "$2" in
          shared|private|paranoid) GITIGNORE_MODE="$2" ;;
          *) die "Unknown gitignore mode '$2'. Must be: shared, private, paranoid" ;;
        esac
        shift 2
        ;;
      --yes|-y)
        SKIP_CONFIRM=true
        shift
        ;;
      --force)
        FORCE_GIT=true
        shift
        ;;
      --force-overwrite)
        FORCE_OVERWRITE=true
        shift
        ;;
      --help|-h)
        show_help
        exit 0
        ;;
      *)
        die "Unknown option: $1  (run with --help)"
        ;;
    esac
  done
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
log_info()    { printf "${C_GREEN}[INFO]${C_RESET}  %s\n" "$*"; }
log_warn()    { printf "${C_YELLOW}[WARN]${C_RESET}  %s\n" "$*"; }
log_error()   { printf "${C_RED}[ERROR]${C_RESET} %s\n" "$*" >&2; }
log_dry()     { printf "${C_CYAN}[DRY]${C_RESET}   %s\n" "$*"; }
log_section() { printf "\n${C_BOLD}%s${C_RESET}\n" "=== $* ==="; }

die() {
  log_error "$*"
  exit 1
}

write_log() {
  local log_file="$1"; shift
  printf "[%s] %s\n" "$(date '+%Y-%m-%dT%H:%M:%S')" "$*" >> "${log_file}"
}

# ISO 8601 timestamp (bash 3.2 compatible — no printf %T)
timestamp_iso() {
  date -u '+%Y-%m-%dT%H:%M:%SZ'
}

# Count files under a directory
count_files() {
  local dir="$1"
  if [ -d "${dir}" ]; then
    find "${dir}" -type f | wc -l | tr -d ' '
  else
    echo 0
  fi
}

show_help() {
  cat <<'EOF'
aegis-migrate-consolidate.sh — AEGIS v9 POC migration tool
===========================================================

USAGE
  ./tools/aegis-migrate-consolidate.sh [OPTIONS]

OPTIONS
  (no flags)                  Dry-run: show what would change (default)
  --apply                     Perform the actual migration
  --rollback                  Reverse migration (reads .aegis/.migration-manifest.json)
  --dry-run                   Explicit dry-run (same as no flags)
  --gitignore-mode MODE       shared (default) | private | paranoid
  --yes, -y                   Skip confirmation prompt on --apply
  --force                     Bypass uncommitted-git-changes check
  --force-overwrite           Bypass .aegis/ already-exists check
  --help, -h                  Show this help

GITIGNORE MODES
  shared    Track instincts/resonance/sprints/config; ignore cache/logs/tmp/metrics
  private   Ignore entire .aegis/
  paranoid  Ignore .aegis/ AND .claude/

EXAMPLES
  ./tools/aegis-migrate-consolidate.sh
  ./tools/aegis-migrate-consolidate.sh --apply
  ./tools/aegis-migrate-consolidate.sh --apply --gitignore-mode private --yes
  ./tools/aegis-migrate-consolidate.sh --rollback

EOF
}

# ---------------------------------------------------------------------------
# Safety: git clean check
# ---------------------------------------------------------------------------
check_git_clean() {
  if [ "${FORCE_GIT}" = true ]; then
    log_warn "Skipping git-clean check (--force)"
    return 0
  fi
  local git_dir="${PROJECT_ROOT}/.git"
  if [ ! -d "${git_dir}" ]; then
    log_warn "Not a git repository — skipping git-clean check"
    return 0
  fi
  local dirty
  dirty=$(cd "${PROJECT_ROOT}" && git status --porcelain 2>/dev/null || true)
  if [ -n "${dirty}" ]; then
    log_error "Uncommitted changes detected. Commit or stash first, or pass --force."
    printf "${C_YELLOW}Dirty files:${C_RESET}\n%s\n" "${dirty}"
    exit 1
  fi
}

# ---------------------------------------------------------------------------
# Safety: .aegis/ already exists
# ---------------------------------------------------------------------------
check_dst_clean() {
  if [ "${FORCE_OVERWRITE}" = true ]; then
    log_warn "Skipping .aegis/ existence check (--force-overwrite)"
    return 0
  fi
  if [ -d "${DST_ROOT}" ] && [ "$(ls -A "${DST_ROOT}" 2>/dev/null)" ]; then
    log_error ".aegis/ already exists and is not empty."
    log_error "Use --force-overwrite to proceed (will merge, NOT wipe)."
    exit 1
  fi
}

# ---------------------------------------------------------------------------
# Build the gitignore block for the chosen mode
# ---------------------------------------------------------------------------
build_gitignore_block() {
  local mode="$1"
  local ts
  ts="$(timestamp_iso)"
  cat <<EOF
${SENTINEL_START}
# Auto-managed by aegis-migrate-consolidate.sh (mode: ${mode}) — ${ts}
# Edit between these markers at your own risk; --apply will replace this block.

EOF
  case "${mode}" in
    shared)
      cat <<'EOF'
# --- .aegis/brain: track knowledge, ignore runtime noise ---

# Track (committed knowledge)
!.aegis/
!.aegis/brain/
!.aegis/brain/instincts/
!.aegis/brain/instincts/**
!.aegis/brain/resonance/
!.aegis/brain/resonance/**
!.aegis/brain/sprints/
!.aegis/brain/sprints/**
!.aegis/brain/retrospectives/
!.aegis/brain/retrospectives/**
!.aegis/brain/handoffs/
!.aegis/brain/handoffs/**
!.aegis/brain/index.md
!.aegis/brain/counters.json
!.aegis/config/
!.aegis/config/**

# Ignore runtime noise
.aegis/brain/logs/
.aegis/brain/metrics/raw/
.aegis/brain/skill-cache/
.aegis/brain/learnings/raw/
.aegis/logs/
.aegis/brain/tasks/*/history.md
EOF
      ;;
    private)
      cat <<'EOF'
# Ignore entire .aegis/ (private mode — nothing committed)
.aegis/
EOF
      ;;
    paranoid)
      cat <<'EOF'
# Ignore .aegis/ AND .claude/ (paranoid mode)
.aegis/
.claude/
EOF
      ;;
  esac
  printf "\n%s\n" "${SENTINEL_END}"
}

# ---------------------------------------------------------------------------
# Idempotent gitignore update: replace or append the sentinel block
# ---------------------------------------------------------------------------
update_gitignore() {
  local mode="$1"
  local dry="${2:-false}"
  local new_block
  new_block="$(build_gitignore_block "${mode}")"

  if [ ! -f "${GITIGNORE}" ]; then
    if [ "${dry}" = "true" ]; then
      log_dry "Would create .gitignore with AEGIS-V9 block (mode: ${mode})"
      return 0
    fi
    printf "%s\n" "${new_block}" > "${GITIGNORE}"
    log_info "Created .gitignore with AEGIS-V9 block (mode: ${mode})"
    return 0
  fi

  # Check if sentinel block already exists
  if grep -qF "${SENTINEL_START}" "${GITIGNORE}" 2>/dev/null; then
    if [ "${dry}" = "true" ]; then
      log_dry "Would REPLACE existing AEGIS-V9 gitignore block (mode: ${mode})"
      return 0
    fi
    # Replace the block between sentinels (bash 3.2 compatible, no sed -i.bak with multi-line)
    local tmpfile
    tmpfile="$(mktemp /tmp/aegis-gitignore.XXXXXX)"
    local in_block=false
    local block_written=false
    while IFS= read -r line || [ -n "${line}" ]; do
      if [ "${line}" = "${SENTINEL_START}" ]; then
        in_block=true
        if [ "${block_written}" = false ]; then
          printf "%s\n" "${new_block}"
          block_written=true
        fi
        continue
      fi
      if [ "${line}" = "${SENTINEL_END}" ]; then
        in_block=false
        continue
      fi
      if [ "${in_block}" = false ]; then
        printf "%s\n" "${line}"
      fi
    done < "${GITIGNORE}" > "${tmpfile}"
    mv "${tmpfile}" "${GITIGNORE}"
    log_info "Replaced AEGIS-V9 gitignore block (mode: ${mode})"
  else
    if [ "${dry}" = "true" ]; then
      log_dry "Would APPEND AEGIS-V9 gitignore block to .gitignore (mode: ${mode})"
      return 0
    fi
    printf "\n%s\n" "${new_block}" >> "${GITIGNORE}"
    log_info "Appended AEGIS-V9 gitignore block to .gitignore (mode: ${mode})"
  fi
}

# ---------------------------------------------------------------------------
# Remove the sentinel block from .gitignore
# ---------------------------------------------------------------------------
remove_gitignore_block() {
  local dry="${1:-false}"
  if [ ! -f "${GITIGNORE}" ]; then
    log_warn ".gitignore not found — nothing to remove"
    return 0
  fi
  if ! grep -qF "${SENTINEL_START}" "${GITIGNORE}" 2>/dev/null; then
    log_warn "AEGIS-V9 sentinel block not found in .gitignore — nothing to remove"
    return 0
  fi
  if [ "${dry}" = "true" ]; then
    log_dry "Would remove AEGIS-V9 sentinel block from .gitignore"
    return 0
  fi
  local tmpfile
  tmpfile="$(mktemp /tmp/aegis-gitignore.XXXXXX)"
  local in_block=false
  while IFS= read -r line || [ -n "${line}" ]; do
    if [ "${line}" = "${SENTINEL_START}" ]; then
      in_block=true
      continue
    fi
    if [ "${line}" = "${SENTINEL_END}" ]; then
      in_block=false
      continue
    fi
    if [ "${in_block}" = false ]; then
      printf "%s\n" "${line}"
    fi
  done < "${GITIGNORE}" > "${tmpfile}"
  mv "${tmpfile}" "${GITIGNORE}"
  log_info "Removed AEGIS-V9 sentinel block from .gitignore"
}

# ---------------------------------------------------------------------------
# Write migration manifest
# ---------------------------------------------------------------------------
write_manifest() {
  local gitignore_mode="$1"
  local block_added="$2"   # true|false
  mkdir -p "${DST_ROOT}"
  cat > "${MANIFEST}" <<EOF
{
  "from_version": "8.4",
  "to_version": "9.0-poc",
  "migration_date": "$(timestamp_iso)",
  "moved_paths": [
    {"from": "_aegis-brain/", "to": ".aegis/brain/"}
  ],
  "gitignore_mode": "${gitignore_mode}",
  "gitignore_block_added": ${block_added},
  "rollback_available": true,
  "backup_path": "${BACKUP_ROOT}/_aegis-brain"
}
EOF
  log_info "Migration manifest written: .aegis/.migration-manifest.json"
}

# ---------------------------------------------------------------------------
# DRY-RUN: show plan without touching anything
# ---------------------------------------------------------------------------
cmd_dry_run() {
  log_section "AEGIS v9 Migration — DRY-RUN (no changes will be made)"
  printf "  Project root : %s\n" "${PROJECT_ROOT}"
  printf "  Source       : _aegis-brain/\n"
  printf "  Destination  : .aegis/brain/\n"
  printf "  Gitignore    : %s\n" "${GITIGNORE_MODE}"
  printf "\n"

  # Source check
  if [ ! -d "${SRC}" ]; then
    log_warn "_aegis-brain/ not found — nothing to migrate"
    return 0
  fi

  local file_count dir_count
  file_count=$(count_files "${SRC}")
  dir_count=$(find "${SRC}" -type d | wc -l | tr -d ' ')

  log_section "Files that would be moved"
  find "${SRC}" -type f | sort | while IFS= read -r f; do
    local rel="${f#${PROJECT_ROOT}/}"
    local dst_rel=".aegis/brain/${rel#_aegis-brain/}"
    log_dry "  ${rel}  -->  ${dst_rel}"
  done

  printf "\n"
  log_section "Summary"
  printf "  Directories  : %s\n" "${dir_count}"
  printf "  Files        : %s\n" "${file_count}"
  printf "\n"

  log_section ".gitignore changes (mode: ${GITIGNORE_MODE})"
  update_gitignore "${GITIGNORE_MODE}" "true"

  log_section "New files that would be created"
  log_dry "  .aegis/.migration-manifest.json  (migration record)"
  log_dry "  .aegis/logs/migration-<timestamp>.log  (action log)"

  log_section "Backup"
  log_dry "  _aegis-brain/ would be copied to .aegis-backup/_aegis-brain/ before move"

  log_section "Post-migration state"
  printf "  .aegis/\n"
  printf "  .aegis/brain/     <- contents of _aegis-brain/\n"
  printf "  .aegis/logs/\n"
  printf "  .aegis/.migration-manifest.json\n"
  printf "  _aegis-brain/     <- REMOVED after successful move\n"

  printf "\n"
  log_info "Dry-run complete. Run with --apply to perform migration."
}

# ---------------------------------------------------------------------------
# APPLY: perform the actual migration
# ---------------------------------------------------------------------------
cmd_apply() {
  log_section "AEGIS v9 Migration — APPLY"
  printf "  Project root : %s\n" "${PROJECT_ROOT}"
  printf "  Gitignore    : %s\n" "${GITIGNORE_MODE}"
  printf "\n"

  check_git_clean
  check_dst_clean

  # Source must exist
  if [ ! -d "${SRC}" ]; then
    die "_aegis-brain/ not found at ${SRC}. Nothing to migrate."
  fi

  # Confirmation
  if [ "${SKIP_CONFIRM}" = false ]; then
    local file_count
    file_count=$(count_files "${SRC}")
    printf "${C_YELLOW}About to migrate %s files from _aegis-brain/ to .aegis/brain/${C_RESET}\n" "${file_count}"
    printf "Gitignore mode: %s\n" "${GITIGNORE_MODE}"
    printf "Continue? [y/N] "
    read -r answer
    case "${answer}" in
      [yY][eE][sS]|[yY]) ;;
      *) log_info "Aborted."; exit 0 ;;
    esac
  fi

  # Create directory structure
  mkdir -p "${DST_ROOT}"
  mkdir -p "${LOG_DIR}"
  local log_file="${LOG_DIR}/migration-$(date '+%Y%m%d-%H%M%S').log"
  touch "${log_file}"

  write_log "${log_file}" "=== AEGIS v9 Migration START ==="
  write_log "${log_file}" "Source: ${SRC}"
  write_log "${log_file}" "Dest:   ${DST}"
  write_log "${log_file}" "Gitignore mode: ${GITIGNORE_MODE}"

  # Step 1: Backup (copy before move — rollback works even if manifest is lost)
  log_info "Step 1/4: Backing up _aegis-brain/ to .aegis-backup/_aegis-brain/"
  mkdir -p "${BACKUP_ROOT}"
  if [ -d "${BACKUP_ROOT}/_aegis-brain" ]; then
    log_warn "Backup already exists — overwriting"
    rm -rf "${BACKUP_ROOT}/_aegis-brain"
  fi
  cp -R "${SRC}" "${BACKUP_ROOT}/_aegis-brain"
  write_log "${log_file}" "Backup created: ${BACKUP_ROOT}/_aegis-brain"
  log_info "Backup complete"

  # Step 2: Move _aegis-brain -> .aegis/brain
  log_info "Step 2/4: Moving _aegis-brain/ -> .aegis/brain/"
  mkdir -p "$(dirname "${DST}")"
  # If .aegis/brain already partially exists (force-overwrite), merge
  if [ -d "${DST}" ]; then
    log_warn ".aegis/brain/ already exists — merging (files will not be overwritten)"
    # Copy files that don't exist in destination
    find "${SRC}" -type d | while IFS= read -r d; do
      local rel="${d#${SRC}}"
      mkdir -p "${DST}${rel}"
    done
    find "${SRC}" -type f | while IFS= read -r f; do
      local rel="${f#${SRC}}"
      local dst_f="${DST}${rel}"
      if [ ! -f "${dst_f}" ]; then
        cp "${f}" "${dst_f}"
        write_log "${log_file}" "COPIED: ${f} -> ${dst_f}"
      else
        write_log "${log_file}" "SKIP (exists): ${dst_f}"
        log_warn "  Skipped (exists): .aegis/brain${rel}"
      fi
    done
    rm -rf "${SRC}"
  else
    mv "${SRC}" "${DST}"
  fi
  write_log "${log_file}" "Move complete: ${SRC} -> ${DST}"
  log_info "Move complete"

  # Step 3: gitignore
  log_info "Step 3/4: Updating .gitignore (mode: ${GITIGNORE_MODE})"
  update_gitignore "${GITIGNORE_MODE}" "false"
  write_log "${log_file}" "gitignore updated: mode=${GITIGNORE_MODE}"

  # Step 4: Manifest
  log_info "Step 4/4: Writing migration manifest"
  write_manifest "${GITIGNORE_MODE}" "true"
  write_log "${log_file}" "Manifest written: ${MANIFEST}"
  write_log "${log_file}" "=== AEGIS v9 Migration COMPLETE ==="

  printf "\n"
  log_section "Migration complete"
  local moved_count
  moved_count=$(count_files "${DST}")
  printf "  Files migrated : %s\n" "${moved_count}"
  printf "  Destination    : .aegis/brain/\n"
  printf "  Manifest       : .aegis/.migration-manifest.json\n"
  printf "  Log            : %s\n" "${log_file#${PROJECT_ROOT}/}"
  printf "  Backup         : .aegis-backup/_aegis-brain/\n"
  printf "\n"
  log_info "Run with --rollback to reverse if anything looks wrong."
}

# ---------------------------------------------------------------------------
# ROLLBACK: reverse migration using manifest
# ---------------------------------------------------------------------------
cmd_rollback() {
  log_section "AEGIS v9 Migration — ROLLBACK"

  # Check backup first (most reliable path, no manifest needed)
  local has_backup=false
  if [ -d "${BACKUP_ROOT}/_aegis-brain" ]; then
    has_backup=true
  fi

  local has_manifest=false
  if [ -f "${MANIFEST}" ]; then
    has_manifest=true
  fi

  if [ "${has_backup}" = false ] && [ "${has_manifest}" = false ]; then
    die "No backup found at ${BACKUP_ROOT}/_aegis-brain and no manifest at ${MANIFEST}. Cannot rollback."
  fi

  # Confirm
  if [ "${SKIP_CONFIRM}" = false ]; then
    printf "${C_YELLOW}This will move .aegis/brain/ back to _aegis-brain/ and remove the .aegis directory structure.${C_RESET}\n"
    printf "Continue? [y/N] "
    read -r answer
    case "${answer}" in
      [yY][eE][sS]|[yY]) ;;
      *) log_info "Aborted."; exit 0 ;;
    esac
  fi

  # Step 1: Restore from backup (preferred — binary-safe, no manifest dependency)
  if [ "${has_backup}" = true ]; then
    log_info "Step 1/3: Restoring from backup (.aegis-backup/_aegis-brain/)"
    if [ -d "${SRC}" ]; then
      log_warn "_aegis-brain/ already exists — removing before restore"
      rm -rf "${SRC}"
    fi
    cp -R "${BACKUP_ROOT}/_aegis-brain" "${SRC}"
    log_info "Restored _aegis-brain/ from backup"
  else
    # Fallback: manifest-guided reverse
    log_warn "No backup found — attempting manifest-guided rollback"
    log_info "Step 1/3: Moving .aegis/brain/ back to _aegis-brain/"
    if [ ! -d "${DST}" ]; then
      die ".aegis/brain/ not found. Cannot rollback."
    fi
    mv "${DST}" "${SRC}"
    log_info "Moved .aegis/brain/ -> _aegis-brain/"
  fi

  # Step 2: Remove gitignore block
  log_info "Step 2/3: Removing AEGIS-V9 gitignore block"
  remove_gitignore_block "false"

  # Step 3: Clean up .aegis/ (remove if now empty, else leave with warning)
  log_info "Step 3/3: Cleaning up .aegis/ directory"
  if [ -d "${DST}" ]; then
    rm -rf "${DST}"
  fi
  if [ -f "${MANIFEST}" ]; then
    rm -f "${MANIFEST}"
  fi
  # Remove .aegis/ only if empty (may have other content)
  if [ -d "${DST_ROOT}" ]; then
    local remaining
    remaining=$(find "${DST_ROOT}" -not -name ".migration-manifest.json" -type f 2>/dev/null | wc -l | tr -d ' ')
    if [ "${remaining}" -eq 0 ]; then
      rm -rf "${DST_ROOT}"
      log_info "Removed empty .aegis/ directory"
    else
      log_warn ".aegis/ still has ${remaining} files (logs kept) — not removing"
    fi
  fi

  printf "\n"
  log_section "Rollback complete"
  printf "  _aegis-brain/ : restored\n"
  printf "  .aegis/brain/ : removed\n"
  printf "  .gitignore    : AEGIS-V9 block removed\n"
  printf "\n"
  log_info "Project is back to v8.4 state."
}

# ---------------------------------------------------------------------------
# Idempotency: detect current state and report
# ---------------------------------------------------------------------------
report_current_state() {
  log_section "Current state"
  if [ -d "${SRC}" ]; then
    printf "  _aegis-brain/         EXISTS  (%s files)\n" "$(count_files "${SRC}")"
  else
    printf "  _aegis-brain/         NOT FOUND\n"
  fi
  if [ -d "${DST}" ]; then
    printf "  .aegis/brain/         EXISTS  (%s files)\n" "$(count_files "${DST}")"
  else
    printf "  .aegis/brain/         NOT FOUND\n"
  fi
  if [ -f "${MANIFEST}" ]; then
    printf "  .aegis/.migration-manifest.json  EXISTS\n"
  else
    printf "  .aegis/.migration-manifest.json  NOT FOUND\n"
  fi
  if [ -d "${BACKUP_ROOT}/_aegis-brain" ]; then
    printf "  .aegis-backup/_aegis-brain/   EXISTS  (%s files)\n" "$(count_files "${BACKUP_ROOT}/_aegis-brain")"
  else
    printf "  .aegis-backup/        NOT FOUND\n"
  fi
  if grep -qF "${SENTINEL_START}" "${GITIGNORE}" 2>/dev/null; then
    printf "  .gitignore            AEGIS-V9 block present\n"
  else
    printf "  .gitignore            no AEGIS-V9 block\n"
  fi
  printf "\n"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  parse_args "$@"

  printf "\n"
  printf "${C_BOLD}AEGIS v9 Migration Tool — POC (S2-07)${C_RESET}\n"
  printf "Project root: %s\n" "${PROJECT_ROOT}"
  printf "Mode: %s | Gitignore: %s\n\n" "${MODE}" "${GITIGNORE_MODE}"

  report_current_state

  case "${MODE}" in
    dry-run)  cmd_dry_run ;;
    apply)    cmd_apply ;;
    rollback) cmd_rollback ;;
  esac
}

main "$@"
