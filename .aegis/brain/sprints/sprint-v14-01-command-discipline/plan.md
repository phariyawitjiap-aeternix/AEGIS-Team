<!-- version: 1.0.0 -->
<!-- Last updated: 2026-05-12 -->

# Sprint v14-01 Plan — Command Discipline + Governance Polish

**Goal**: One source of truth for slash commands; harden brain content ingestion; close CI gap. Adopt Hermes patterns ranked P0 in v14-series-plan.md.

**Capacity**: 13pt (3 stories)
**Status**: ACTIVE (opened 2026-05-12)
**Series**: [v14-series-plan.md](../v14-series-plan.md)

## Stories

| ID | Title | Points | Status | Hermes source |
|----|-------|--------|--------|---------------|
| S14-01-01 | CommandDef central registry | 5 | TODO | `hermes_cli/commands.py` (65 entries → 6 consumers) |
| S14-01-02 | Brain content threat scanner | 3 | TODO | `tools/memory_tool.py:_MEMORY_THREAT_PATTERNS` |
| S14-01-03 | Narrow supply-chain CI workflow | 5 | TODO | `.github/workflows/supply-chain-audit.yml` |

## Acceptance criteria

### S14-01-01 — CommandDef registry
- [ ] `tools/aegis-commands/registry.mjs` exports `COMMAND_REGISTRY` with all 14 commands
- [ ] `tools/aegis-commands/render-help.mjs` validates `.claude/commands/*.md` frontmatter ⊆ registry
- [ ] Adding a new command requires 1 edit to registry.mjs (filesystem .md still authored, but metadata-validated)
- [ ] Categories: Setup / Workflow / Inspection / Lifecycle (mirror Hermes Session/Configuration/Tools&Skills/Info/Exit)
- [ ] `tests/aegis-commands-registry-test.sh` passes — registry ⊇ filesystem
- [ ] **Bug found during inventory**: `aegis-upgrade.md` has no frontmatter — fix in this story

### S14-01-02 — Brain threat scanner
- [ ] `tools/aegis-brain-threat-patterns.yaml` with 12 patterns adapted from Hermes
- [ ] `tools/aegis-brain-write.sh` rejects content matching any pattern
- [ ] Invisible-char detection (10 chars: `U+200B U+200C U+200D U+2060 U+FEFF U+202A-U+202E`)
- [ ] `# scan-exempt: <reason>` opt-out comment
- [ ] Existing brain content does NOT match any pattern (pre-flight scan)
- [ ] `tests/aegis-brain-threat-scan-test.sh` — 12 patterns + 10 chars + 5 benign = 27 fixtures

### S14-01-03 — Supply-chain audit CI
- [ ] `.github/workflows/supply-chain-audit.yml` adapted from Hermes
- [ ] Triggers on PR to `**/*.mjs`, `**/*.sh`, `package.json`
- [ ] Checks: install scripts, eval/Function, outbound POST, .npmrc/node_modules
- [ ] Workflow takes <30s on average PR
- [ ] `tests/aegis-supply-chain-ci-test.sh` — 4 bad fixtures + 10 benign control
- [ ] No-noise discipline: comment in workflow citing Hermes commit dd0923b

## Decision Audit Trail (planned)

- D-002 sprint-open (this turn)
- D-XXX (during S14-01-01 impl) — registry shape (raw export vs class-based)
- D-XXX (during S14-01-02 impl) — pattern set verbatim from Hermes vs adapted
- D-XXX sprint-close

## Dependencies

- ✅ `tools/aegis-brain-write.sh` exists
- ✅ Node available (.mjs runs)
- ✅ GitHub Actions available
- ✅ All 14 .claude/commands/*.md present

## Out-of-scope (deferred)

- Auto-regenerating .md bodies from registry (registry validates only, doesn't generate)
- Slack/messaging integration (not applicable — AEGIS lives in Claude Code)
- BotCommand / autocomplete export (Claude Code uses .md directly; no export needed)

## Risks

| Risk | Mitigation |
|------|-----------|
| `aegis-upgrade.md` without frontmatter blocks initial registry test | Fix as part of this sprint (1-line addition) |
| Threat scanner false-positives on `learnings/` describing past attacks | `# scan-exempt: <reason>` comment supported |
| Supply-chain CI false-positives train reviewers to ignore | Adopt Hermes no-noise discipline; remove low-signal at first false alarm |

## Definition of Done

- All 3 stories' acceptance criteria checked
- All new test files pass
- ARCHITECTURE.md updated with `tools/aegis-commands/` row
- AGENTS.md (root) references registry as source-of-truth for commands
- close.md written with retrospective + lessons
- roadmap.md updated with v14-01 row + delivered points
- Decision audit log has D-002 (open) + D-XXX (close) at minimum
