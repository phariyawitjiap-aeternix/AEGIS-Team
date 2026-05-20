<!-- version: 1.0.0 -->
<!-- Last updated: 2026-05-06 -->

Last reviewed: 2026-05-06

# AEGIS Agents — Quick Reference (v9 Model: 10 agents)

## Changelog

| Date | Version | Change |
|------|---------|--------|
| 2026-05-06 | 1.0.0 | Version header pattern introduced (sprint-v12-01). |

## Active Agents

| # | Agent | Model | Role |
|:-:|-------|:-----:|------|
| 🧬 | Nick Fury | opus | Autonomous Controller (Master Brain) |
| 🧭 | Captain America | opus | Navigator/Lead + Fallback Brain (S2-01) |
| 📐 | Iron Man | opus | Architect |
| ⚡ | Spider-Man | sonnet | Implementer (worktree-default per S5-02) |
| 🛡️ | Black Panther | sonnet | Reviewer (read-only worktree per S5-03) |
| 🔴 | Loki | opus | Devil's Advocate |
| 🔧 | Beast | haiku | Scanner/Research |
| 🎯 | War Machine | sonnet | QA Lead + Executor (absorbed Vision in v9) |
| 🚀 | Thor | sonnet | DevOps |
| 📜 | Coulson | haiku | Compliance + Docs (absorbed Songbird's content role) |

Model routing: opus=strategy, sonnet=implementation, haiku=scanning

## Return Format (v15-20)

Every sub-agent return MUST tag non-trivial claims (counts, status booleans,
closures, DONE/SHIPPED) as either **`[VERIFIED: <command>]`** (backed by an
executed command — cite it) or **`[PRODUCED: unverified]`** (artifact exists
but was not run against ground truth). See [`skills/aegis-return-format.md`](skills/aegis-return-format.md)
for the rule + examples. Driver: Contra-Thai post-mortem F-C — sub-agent
returns conflated `produced` and `verified`; main agent inherited paper claims
as ground truth. Validator: `tools/aegis-return-validator.sh check <file-or-stdin>`
(soft gate, exits 0; high untagged ratio = re-prompt the sub-agent).

## Retired in v9 (Sprint v9-06)

| # | Agent | Reason | Replacement |
|:-:|-------|--------|-------------|
| 🔬 | Vision | Merged into War Machine | War Machine handles strategy + execution |
| 🖌️ | Wasp | UX tasks too rare (~5%) | Spider-Man + ui-style-guide.md reference |
| 🎨 | Songbird | Marketing rarely needed | Coulson handles docs + changelogs |

Archived files: `.claude/agents/_archived/` (with README explaining routing)

## Full Persona Details

`.claude/agents/<name>.md`

## v9 Protocol References

Each agent should reference (per role):

- All agents → `.claude/references/captain-america-fallback.md` (S2-01)
- Nick Fury → `.claude/references/decision-audit-protocol.md` (S2-02)
- Coulson → `.claude/references/block-0-lite.md` (S2-03)
- Spider-Man, Black Panther → `.claude/references/worktree-isolation.md` (Sprint v9-05)
- Nick Fury → `.claude/references/memory-tool-integration.md` (Sprint v9-04)
- Iron Man → `.claude/references/brain-tier-architecture.md` (Sprints v9-07-09)
