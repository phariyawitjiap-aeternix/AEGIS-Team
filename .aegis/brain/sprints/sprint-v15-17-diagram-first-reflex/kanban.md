# Sprint v15-17 Kanban

## DONE

- [x] **A** — `skills/diagram-first-reflex.md` (1pt)
  - Trigger matrix (6 cases) + anti-trigger matrix (6 cases)
  - Per-persona defaults for all 11 personas
  - Style rules (labels, named nodes, direction, emoji, colors)
  - Markdown-fence compatibility note
- [x] **B** — Wire 5 most-affected personas (1pt)
  - `nick-fury.md` → flowchart TB with decision diamonds
  - `captain-america.md` → sequenceDiagram (multi-agent dispatch)
  - `iron-man.md` → flowchart TB (architecture) + stateDiagram-v2 (lifecycle)
  - `loki.md` → flowchart TB with `:::warning` class (attack paths)
  - `coulson.md` → flowchart LR (traceability req → impl → test)
- [x] **C** — CLAUDE.md + regression test (1pt)
  - CLAUDE.md gets 3-line "Diagram-First Reflex (v15-17)" section + skill link
  - `tests/aegis-diagram-first-lint-test.sh` × 6 scenarios → 6/6 PASS

## Stories table

| Story | Type | Points | Status |
|-------|------|--------|--------|
| A — skill file | enhancement | 1 | DONE |
| B — persona wiring | enhancement | 1 | DONE |
| C — CLAUDE.md + test | testing | 1 | DONE |

**Total**: 3/3 done.
