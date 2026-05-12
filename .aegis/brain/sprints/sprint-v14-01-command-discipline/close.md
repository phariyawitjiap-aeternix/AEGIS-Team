<!-- version: 1.0.0 -->
<!-- Last updated: 2026-05-12 -->

# Sprint v14-01 Close — Command Discipline + Governance Polish

**Status**: CLOSED 2026-05-12 (100%)
**Outcome**: 13/13 points delivered + 1 bug fix (aegis-upgrade.md frontmatter)
**Test results**: **60/60 GREEN** across 3 new test suites
**Series**: [v14-series-plan.md](../v14-series-plan.md)

## What shipped

### S14-01-01 — CommandDef central registry (5pt) ✅
- [tools/aegis-commands/registry.mjs](../../../../tools/aegis-commands/registry.mjs) — `COMMAND_REGISTRY` with all 14 commands, frozen dataclass-style entries with `name`, `description`, `category`, `aliases`, `triggers_en`, `triggers_th`, `args_hint`, `subcommands`, `cli_only`, `gateway_only`
- [tools/aegis-commands/render-help.mjs](../../../../tools/aegis-commands/render-help.mjs) — `validate` / `list` / `help [--json]` subcommands
- [tests/aegis-commands-registry-test.sh](../../../../tests/aegis-commands-registry-test.sh) — **9/9 passing**
- **Bug found + fixed**: [.claude/commands/aegis-upgrade.md](../../../../.claude/commands/aegis-upgrade.md) was missing YAML frontmatter — added during inventory pass
- Categories adopted: Setup / Workflow / Inspection / Lifecycle (mirroring Hermes Session/Configuration/Tools&Skills/Info/Exit)

### S14-01-02 — Brain content threat scanner (3pt) ✅
- [tools/aegis-brain-threat-patterns.yaml](../../../../tools/aegis-brain-threat-patterns.yaml) — 12 ERE patterns + 10 invisible-char codepoints documented
- [tools/aegis-brain-write.sh](../../../../tools/aegis-brain-write.sh) — `_aegis_threat_scan()` runs before every `brain_write` and `brain_append` (skipped for `logs/*`); supports `# scan-exempt: <reason>` opt-out and `AEGIS_BRAIN_SCAN_DISABLED=1` CI escape hatch
- [tests/aegis-brain-threat-scan-test.sh](../../../../tests/aegis-brain-threat-scan-test.sh) — **32/32 passing** (12 patterns + 10 invisible chars + 5 benign + 2 narrow-pattern guards + 1 scan-exempt + 1 escape-hatch + 1 regression check on existing brain content)
- Pattern adapted from Hermes verbatim except `aegis_env` (narrowed to `.env` files only after regression check found benign refs to `~/.aegis-plus/projects.yaml`)

### S14-01-03 — Narrow supply-chain CI workflow (5pt) ✅
- [tools/aegis-supply-chain-scan.sh](../../../../tools/aegis-supply-chain-scan.sh) — 6 narrow checks: postinstall scripts, `.pth` files, `eval()`/`new Function()`, raw-IP outbound, `.npmrc` mods, `node_modules/` commits
- [.github/workflows/supply-chain-audit.yml](../../../../.github/workflows/supply-chain-audit.yml) — runs scan on PR, posts findings as PR comment, blocks merge on findings
- [tests/aegis-supply-chain-ci-test.sh](../../../../tests/aegis-supply-chain-ci-test.sh) — **19/19 passing** (9 bad fixtures + 10 benign control)
- Comment-line skip added to eval-check after TC15 false-positive on legitimate "// avoid eval()" docstring
- Pinned action SHAs adopted (no `@v4` floating refs)

## Decisions logged

| ID | Topic | Source | Reasoner |
|----|-------|--------|----------|
| D-001 | v14 series plan adoption | framework | Nick Fury |
| D-002 | sprint-v14-01 open | framework | Nick Fury |
| D-003 (this) | sprint-v14-01 close — 100% delivered | framework | Nick Fury |

(Worktree-local decision counter; will renumber on merge into main if collision.)

## Test summary

```
sprint-v14-01 test totals:
  S14-01-01 CommandDef registry:      9/9   GREEN
  S14-01-02 Brain threat scanner:    32/32  GREEN
  S14-01-03 Supply-chain audit CI:   19/19  GREEN
  ────────────────────────────────────────────────
  TOTAL:                             60/60  GREEN
```

## Files delta

```
NEW (6 files):
  tools/aegis-commands/registry.mjs                 (12,308 bytes)
  tools/aegis-commands/render-help.mjs              ( 9,633 bytes, +x)
  tools/aegis-brain-threat-patterns.yaml            ( 4,380 bytes)
  tools/aegis-supply-chain-scan.sh                  ( 7,684 bytes, +x)
  .github/workflows/supply-chain-audit.yml          ( 3,815 bytes)
  tests/aegis-commands-registry-test.sh             ( 6,720 bytes, +x)
  tests/aegis-brain-threat-scan-test.sh             ( 8,778 bytes, +x)
  tests/aegis-supply-chain-ci-test.sh               ( 7,210 bytes, +x)

EDIT (2 files):
  tools/aegis-brain-write.sh                        (added _aegis_threat_scan + 2 call sites)
  .claude/commands/aegis-upgrade.md                 (added YAML frontmatter — bug fix)
```

## What worked

1. **AST-free registry pattern** — `Object.freeze()` + module exports gave us a clean dataclass-equivalent without needing a class hierarchy or external schema validator. The 14-command list reads top-to-bottom like a config file.

2. **Test-first feedback caught real bugs**:
   - TC30 regression check found 3 legitimate brain files tripping the over-broad `aegis_env` pattern → narrowed pattern + added 2 regression guards (TC12a/TC12b)
   - TC15 caught the eval-check tripping on doc comments → added comment-line skip
   - Both bugs would have shipped silently without the regression fixtures

3. **Hermes-verbatim adoption with intentional deviations**:
   - 12/12 prompt-injection patterns adopted unchanged
   - 10/10 invisible-char codepoints adopted unchanged
   - `aegis_env` narrowed (Hermes target was `.hermes/.env` specifically; ours generalizes correctly)
   - `ssh_access` narrowed to require trailing `/` (avoids matching mid-word like "ssh_access" in code)

4. **No-noise CI discipline** — 6 narrow checks, no warning-tier patterns. Comment in workflow YAML cites Hermes commit dd0923b for posterity.

## What surprised

1. **`aegis-upgrade.md` had no frontmatter** — the registry inventory surfaced this immediately. Without the registry, this would have been silent rot. **Validation IS the value.**

2. **Hermes pattern adoption is more nuanced than copy-paste** — pattern `aegis_env` directly translated tripped 3 existing brain files. Need to think about WHAT each Hermes pattern is targeting (Hermes `.hermes/.env` = secret access; `.aegis/` paths in our docs are usually benign references), not just port the regex.

3. **Bash regex escaping is treacherous** — needed `\\\$` (4 chars in source = `\$` in string) to match a literal dollar sign in `grep -E`. Several iterations on fixture content before patterns matched correctly.

4. **`brain_write`'s pre-existing structure was clean** — adding `_aegis_threat_scan` as Step 0 was a 4-line edit. Modular shell architecture pays off here vs Hermes's mega-file approach (where adding similar logic would require touching `tools/memory_tool.py` AND its 200+ callers).

## Lessons (added to brain)

- `learnings/v14-01-hermes-pattern-adaptation.md` (added next session-end via aegis-retro)
- `learnings/v14-01-test-first-caught-real-bugs.md` (TC30 regression fixture pattern)

## DoD bars (per DoD.md §1-9)

| Bar | Status | Evidence |
|-----|--------|----------|
| §1 Functional | ✅ | All 3 stories deliver tooling that runs on `node`/`bash` |
| §2 Tests | ✅ | 3 new test files, 60/60 green |
| §3 Safety | ✅ | No new escalation paths; threat scanner adds defense, doesn't remove |
| §4 Documentation | ⚠️ | AGENTS.md + ARCHITECTURE.md updates queued for next sprint (out of v14-01 scope) |
| §5 CI green | ✅ | All scripts pass shellcheck-equivalent; workflow YAML lints clean |
| §6 Decision audit | ✅ | D-001/002/003 logged via aegis-log-decision.sh |
| §7 Roadmap | ✅ | roadmap.md updated with v14-01 row |
| §8 Retro | ✅ | This close.md is the retro |
| §9 Brain update | ⚠️ | Lessons entries deferred to /aegis-retro |

**Notable**: §4 and §9 are partial — those touch CLAUDE_lessons.md / AGENTS.md / ARCHITECTURE.md which are framework-level docs that need careful update via `/aegis-retro` to avoid double-edits. Marked as carry-forward.

## Carry-forward to v14-02

- Update `ARCHITECTURE.md` Concern→File map with new rows for `tools/aegis-commands/`, `tools/aegis-brain-threat-patterns.yaml`, `tools/aegis-supply-chain-scan.sh`
- Update `AGENTS.md` (root) to reference `tools/aegis-commands/registry.mjs` as command source-of-truth
- Add `learnings/v14-01-*` entries via `/aegis-retro`
- Consider extracting threat-scan helper into `tools/aegis-brain-threat-scan.sh` for reuse outside `aegis-brain-write.sh` (deferred — YAGNI for now)

## Roadmap math impact

```
Pre-sprint:   v14 selected = 0   /  v14 done = 0   (not yet in roadmap)
Post-sprint:  v14-01       = 13  /  v14-01 done = 13  (100%)
Series total: v14 selected = 47  /  v14 done = 13   (28% of v14 series)
```

Next sprint candidate: **sprint-v14-02-brain-safety-nets** (13pt — shadow-git checkpoints + decision search) per [v14-series-plan.md](../v14-series-plan.md).
