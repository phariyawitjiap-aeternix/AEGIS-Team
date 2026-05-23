# Sprint v15-25 — Confident Lean (Actual Deletion)

> User challenge 2026-05-23: "ลุยได้ แต่มั่นใจ ผลลัพทธ์ aegis จะดีขึ้นด้วย"
> v15-24 was the decision sprint (positioning doc + deprecation tags). v15-25
> is the execution sprint — delete deprecated code, archive superseded tools.
> Confident == only cut what's PROVABLY redundant with native CC.

## Sprint metadata

- **ID**: sprint-v15-25-confident-lean
- **Points**: 3
- **Status**: SELECTED
- **Branch**: `claude/sprint-v15-25-confident-lean`

## Decision principle

For each candidate, the verdict must answer YES to all three:

1. **Native equivalent exists and is documented** (in `docs/AEGIS_VS_NATIVE_CC.md`)
2. **Removal makes AEGIS clearer** (fewer concepts to learn, fewer drift surfaces)
3. **No live workflow depends on the candidate** (greps confirm — only historical brain artifacts reference it)

If any answer is NO → KEEP. We don't lean for the sake of leaner.

## Stories

| Story | Pts | Description |
|---|---|---|
| **A — Remove `mt cwd` + `mt run` (deprecated v15-24)** | 1 | Native `claude --cwd "$(mt where <name>)" <args>` replaces both. Removed `cmdCwd` + `cmdRun` from mt.mjs (~70 LOC). Switch dispatcher returns exit 2 with migration hint for back-compat scripts. Help text + test Group 6 collapsed (8 cases → 2 migration-hint cases). |
| **B — Archive v9-era worktree tools (superseded by native `isolation: "worktree"`)** | 1 | Moved `tools/aegis-worktree-gc.sh` (150 LOC) + `tools/aegis-merge-worktree.sh` (314 LOC) → `tools/_archived/`. Total 464 LOC archived. Updated 4 referrers (thor.md, README.md, install-remote.sh, v9-follow-ups.md). Native CC Agent tool's `isolation: "worktree"` flag handles worktree lifecycle now. |
| **C — Audit + KEEP confirmations** | 1 | Audited 8 candidates, kept 6: `aegis-resume/` (unique crash-detection at SessionStart, not duplicate of `claude --resume`); `aegis-status-brief.sh` (terminal-side dashboard, parallel to `/aegis-status` slash command); `aegis-dump.sh` (shareable redacted setup summary, v14-03 Hermes parity); `aegis-pin.sh` (instinct/skill 2-axis pinning, v14-03 Hermes parity); `aegis-contrast-check.sh` (wired into wasp tests); `aegis-router.sh` (would need fuller audit). Updated `docs/AEGIS_VS_NATIVE_CC.md` to reflect the keep verdicts. |

**Total: 3 pt**

## Measurement (the "AEGIS gets better" assertion)

| Surface | Before | After | Delta |
|---|---|---|---|
| `tools/aegis-*.sh` count | 55 | 52 | **−3** |
| `tools/` total size (KB) | 1068 | 1064 | −4 |
| LOC removed from mt.mjs | — | — | −70 |
| LOC moved to `_archived/` | — | — | −464 (from active) |
| Test cases (Group 6 in mt-test) | 8 | 2 | **−6** |
| Concepts users must learn | `mt cwd` / `mt run` / `mt where` (3 paths to same thing) | just `mt where` (one canonical path) | **−2 redundant concepts** |
| Help text length (mt help) | ~16 lines | ~13 lines | clearer |

The qualitative win is bigger than the LOC delta: users now learn ONE recipe (`claude --cwd "$(mt where <name>)"`) instead of three (`mt cwd`, `mt run`, plus the native `claude --cwd`).

## Acceptance criteria

- [ ] `mt cwd` invocation → exit 2 with hint "use `mt where`"
- [ ] `mt run` invocation → exit 2 with hint
- [ ] `mt help` no longer lists removed subcommands; CC 2.1.141 section shows the new recipe
- [ ] `tools/aegis-worktree-gc.sh` + `tools/aegis-merge-worktree.sh` moved to `tools/_archived/`
- [ ] 4 referrers updated (thor.md, README.md, install-remote.sh, v9-follow-ups.md)
- [ ] `aegis-trace-audit.sh` shows 0 orphan references
- [ ] Multi-tenant test suite green
- [ ] Full suite green

## What this does NOT do

- Touch `aegis-resume/` — confirmed unique value (SessionStart crash-detection ≠ `claude --resume`)
- Touch `aegis-status-brief.sh` — terminal-side dashboard, parallel to slash command
- Touch any persona, skill, or hook (these are core content)
- Touch any brain artifact (historical records)

## Closes / impact

- v15-24 deprecation tags graduate to actual removal
- AEGIS's "Cwd integration" surface area: 3 paths → 1 canonical path
- v9-era worktree pattern: removed from active tools (still in `_archived/` for reference)
