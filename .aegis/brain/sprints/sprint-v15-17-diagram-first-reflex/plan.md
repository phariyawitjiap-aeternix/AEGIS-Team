# Sprint v15-17 — Diagram-First Reflex

> Add Mermaid-as-reflex to all AEGIS personas. **NOT "breathe mermaid"
> (always)** — that's overfit and noisy. INSTEAD a **trigger-based reflex**:
> when the thought is structural (flow / decision / sequence / state /
> hierarchy), lead with mermaid BEFORE prose. Per-persona defaults make
> the habit consistent + reduces decision fatigue at output time.

## Sprint metadata

- **ID**: sprint-v15-17-diagram-first-reflex
- **Points**: 3
- **Status**: SELECTED
- **Branch**: `claude/sprint-v15-17-diagram-first-reflex`
- **Driver**: user request 2026-05-19 — "เพิ่มนิสัยให้ nick และ ทีม คือ ให้หายใจเข้าออก เป็น mermaidchart"; my critique downgraded "breathing" → "reflex" (always vs. when-triggered) to avoid token bloat and prose-anti-pattern fits.

## Why "reflex" not "breathing"

```mermaid
flowchart LR
    Thought([thought]) --> Type{structural?}
    Type -->|yes: flow/state/seq/tree| Mermaid["```mermaid```"]
    Type -->|no: narrative/apology/<br/>retro/code-review/single-fact| Prose[prose / list / code]
    classDef yes fill:#dcfce7,stroke:#16a34a
    classDef no fill:#fef3c7,stroke:#d97706
    class Mermaid yes
    class Prose no
```

"Breathing" = automatic, ALL the time → +30-50% token cost, single-node-graph noise. "Reflex" = trigger-based → applies where it earns its keep.

## Stories

| Story | Pts | Description |
|---|---|---|
| **A — Skill file `skills/diagram-first-reflex.md`** | 1 | Trigger matrix (6 types) + anti-trigger matrix (6 types) + per-persona defaults (11 personas) + style rules (labeled edges, named nodes, emoji prefixes, color classes) + anti-pattern examples + Markdown-compat note (renders in GitHub/Linear/Notion/brain-graph wiki natively) |
| **B — Wire 5 most-affected personas** | 1 | `nick-fury.md` (decision tree), `captain-america.md` (sequenceDiagram), `iron-man.md` (architecture + state), `loki.md` (attack paths w/ `:::warning`), `coulson.md` (traceability). Each gets a Diagram-First section + an in-line mermaid example. Other 6 personas reference the skill but inherit defaults from the catalog. |
| **C — Surface in CLAUDE.md + regression test** | 1 | CLAUDE.md gets a 3-line "Diagram-First Reflex" section linking to the skill. `tests/aegis-diagram-first-lint-test.sh` × 6 scenarios — skill file present, 5 personas wired, CLAUDE.md surfaces it, 11-persona coverage in the matrix, both trigger + anti-trigger sections present, Markdown-compat note documented. |

## Acceptance criteria

1. `skills/diagram-first-reflex.md` exists with trigger + anti-trigger matrices + per-persona table for all 11 personas
2. 5 personas (nick-fury, captain-america, iron-man, loki, coulson) have a "Diagram-First Reflex" section with at least one in-line mermaid example
3. CLAUDE.md mentions the habit + links to the skill
4. `tests/aegis-diagram-first-lint-test.sh` → 6/6 PASS
5. Full suite stays GREEN (60 → 61 with new test)
6. Habit applies to **structural thought only** — explicit anti-trigger list prevents the "draw mermaid for everything" overfit

## Style enforcement (in-skill rules)

- Render in Markdown fences (` ```mermaid ... ``` `) — works in GitHub, Linear, Notion, IDE preview, brain-graph wiki
- Every edge labeled (`-->|action|`)
- Every node named descriptively (no `A`, `B`, `C` placeholders)
- Direction chosen per content type: `TB` for hierarchies, `LR` for sequences
- Emoji prefixes for persona nodes (🧬 Nick, 🛡 Cap, 🦾 Iron, 🪐 Loki, etc.)
- 5-15 nodes is the sweet spot; > 20 = split

## Out of scope

- Auto-converting old sprint plans to add mermaid — old artifacts stay as-is (historical record)
- Auto-rendering preview server — Mermaid renders natively in GitHub/Linear/Notion/IDE preview
- Replacing `canvas-design` skill — that's for high-fidelity visual UI; mermaid is for structural diagrams in spec/plan docs

## Verification plan

1. `bash tests/aegis-diagram-first-lint-test.sh` → 6/6
2. `bash tests/run-all.sh --continue` → 61/61
3. Manual: read `nick-fury.md` Decision Matrix section — confirm mermaid lead vs prose lead
4. Manual: write next sprint plan, observe whether diagrams appear naturally in flow/state/sequence sections

## Anti-pattern catch (real examples to avoid)

```
❌ Drawing a 1-node "the file is at .claude/agents/nick-fury.md" diagram
❌ Diagramming an apology or retro narrative — those need sentences
❌ Diagramming code-review feedback — use prose + code snippet
❌ Drawing a flowchart for "I'll run the tests now" — that's a 1-step
```

These are caught by the anti-trigger matrix in the skill file.
