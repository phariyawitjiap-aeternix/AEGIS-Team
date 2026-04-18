# aegis-migrate-consolidate.sh

AEGIS v9 POC migration tool — consolidates `_aegis-brain/` into `.aegis/brain/`
per ADR-007.

## Purpose

AEGIS v8.4 stores its runtime brain in `_aegis-brain/` at the project root.
v9 consolidates all AEGIS-managed directories under `.aegis/` (a single
dotdir). This script performs that migration safely with dry-run, apply,
and rollback modes.

This is a **POC for S2-07**. It covers `_aegis-brain/` only.
See Limitations section for what is out of scope.

## Usage

```bash
# Dry-run (default) — show what would change, touch nothing
./tools/aegis-migrate-consolidate.sh

# Apply migration with default gitignore mode (shared)
./tools/aegis-migrate-consolidate.sh --apply

# Apply with private gitignore (nothing in .aegis/ gets committed)
./tools/aegis-migrate-consolidate.sh --apply --gitignore-mode private

# Apply in paranoid mode (.aegis/ AND .claude/ ignored)
./tools/aegis-migrate-consolidate.sh --apply --gitignore-mode paranoid

# Apply, skip confirmation prompt
./tools/aegis-migrate-consolidate.sh --apply --yes

# Rollback — restore _aegis-brain/, remove .aegis/brain/, clean .gitignore
./tools/aegis-migrate-consolidate.sh --rollback

# Show help
./tools/aegis-migrate-consolidate.sh --help
```

## Gitignore modes

| Mode      | What gets committed                          | What gets ignored                            |
|-----------|----------------------------------------------|----------------------------------------------|
| `shared`  | instincts/, resonance/, sprints/, config/    | logs/, metrics/raw/, skill-cache/, learnings/raw/ |
| `private` | nothing inside .aegis/                       | entire .aegis/                               |
| `paranoid`| nothing inside .aegis/ or .claude/           | .aegis/ AND .claude/                         |

The gitignore block is wrapped in sentinel markers:

```
# <<< AEGIS-V9-START >>>
...
# <<< AEGIS-V9-END >>>
```

Running the script multiple times will **replace** the block, not append a
duplicate. If you manually edit inside the markers, the next `--apply` run
will replace your edits. Edit outside the markers if you need persistent
custom rules.

## Safety

- **Dry-run is the default.** You must pass `--apply` explicitly.
- Script refuses to run if uncommitted git changes exist (bypass with `--force`).
- Script refuses to run if `.aegis/` already has content (bypass with `--force-overwrite`).
- A full backup of `_aegis-brain/` is written to `.aegis-backup/_aegis-brain/`
  before any move. Rollback works even if the manifest is deleted.
- All actions are logged to `.aegis/logs/migration-<timestamp>.log`.
- A migration manifest is written to `.aegis/.migration-manifest.json`.

## Rollback

```bash
./tools/aegis-migrate-consolidate.sh --rollback
```

Rollback:
1. Restores `_aegis-brain/` from `.aegis-backup/`
2. Removes the AEGIS-V9 sentinel block from `.gitignore`
3. Removes `.aegis/brain/` and the manifest
4. Removes `.aegis/` if it becomes empty (logs are kept)

## Idempotency

Running the script multiple times in the same mode is safe:

- Dry-run: always safe, reads nothing
- Apply twice: second run hits the `--force-overwrite` guard; pass it to
  merge (skips files that already exist at destination)
- Rollback twice: second run will find `_aegis-brain/` already present and
  nothing left to move; exits cleanly with warnings

## Limitations (POC scope)

This script deliberately does NOT:

- Relocate `skills/` or `dashboard/` (Phase 1 full migration)
- Move `.claude/` (Claude Code requires it at root — permanent exception)
- Update agent/command file references that point to `_aegis-brain/`
- Perform CLAUDE.md lift (Phase 4)
- Handle memory tool migration
- Handle plugin distribution

After running `--apply`, existing agent and command files that reference
`_aegis-brain/` paths will be stale. Update those references as a
separate task before activating v9 agents.

## Requirements

- bash 3.2+ (macOS default — no GNU-only flags used)
- git (optional — used only for dirty-tree check)
- Standard POSIX utilities: cp, mv, rm, find, mkdir, date, mktemp
