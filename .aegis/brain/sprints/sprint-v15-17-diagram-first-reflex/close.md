# Sprint v15-17 Close — Diagram-First Reflex

**Status**: CLOSED (100%)
**Date**: 2026-05-19
**Driver**: user request "เพิ่มนิสัยให้ nick และ ทีม คือ ให้หายใจเข้าออก เป็น mermaidchart"
**Branch**: `claude/sprint-v15-17-diagram-first-reflex`

## What shipped

```mermaid
flowchart LR
    Thought([thought]) --> Type{structural?}
    Type -->|yes| Mermaid["```mermaid```<br/>diagram first"]
    Type -->|no: narrative/<br/>retro/apology/<br/>code-review| Prose[prose / list / code]
    classDef yes fill:#dcfce7,stroke:#16a34a
    classDef no fill:#fef3c7,stroke:#d97706
    class Mermaid yes
    class Prose no
```

- **`skills/diagram-first-reflex.md`** — the canonical reflex definition
- **5 personas wired** with in-line examples: `nick-fury`, `captain-america`, `iron-man`, `loki`, `coulson`
- **Other 6 personas** inherit defaults from the skill's per-persona table (Spider-Man / War Machine / Black Panther / Thor / Beast / Wasp)
- **CLAUDE.md** surfaces the habit at top-level for discoverability
- **`tests/aegis-diagram-first-lint-test.sh`** × 6 scenarios → 6/6 PASS

## Why "reflex" not "breathing"

The original request was "หายใจเข้าออก เป็น mermaidchart" (breathe mermaid). I downgraded that to **"reflex"** based on three risks:

| Risk if "always breathe" | Reflex mitigates it |
|---|---|
| Token cost +30-50% per response | Only fires on trigger |
| 1-node graph for "file is at X" | Anti-trigger matrix catches |
| Prose-native content (retro, apology, code review) gets cold | Anti-trigger list explicit |
| Pattern-fit overfit | Trigger requires > 3 steps / > 2 branches / multi-actor / state machine |

## Per-persona defaults

| Persona | Default diagram | Triggered by |
|---|---|---|
| 🧬 Nick Fury | `flowchart TB` with diamonds | Decision Matrix P0-P10, escalation flows |
| 🛡 Captain America | `sequenceDiagram` | Multi-agent dispatch, hand-offs |
| 🦾 Iron Man | `flowchart TB` + `stateDiagram-v2` | Architecture maps, lifecycle states |
| 🪐 Loki | `flowchart TB` with `:::warning` | Attack paths, edge cases |
| 📋 Coulson | `flowchart LR` + tables | Traceability (req → impl → test) |
| 🕷 Spider-Man | prose + code (sequence only when integrating) | API integration flows |
| ⚙ War Machine | `stateDiagram-v2` | Test phases, gate states |
| 🐆 Black Panther | prose + code (flow for review trees) | Review decision trees |
| ⚡ Thor | `flowchart LR` + `gantt` | Deploy pipeline, release timeline |
| 🔬 Beast | `flowchart TB` | Concept maps, synthesis trees |
| 🐝 Wasp | image artifacts via canvas-design (flow for user journey) | User journey maps |

## Verification

```
$ bash tests/aegis-diagram-first-lint-test.sh
PASS T1 skill file present with required sections
PASS T2 all 5 personas wired with mermaid example
PASS T3 CLAUDE.md documents reflex + links to skill
PASS T4 all 11 personas have a default diagram type
PASS T5 both trigger + anti-trigger sections documented
PASS T6 skill confirms Mermaid-in-Markdown compatibility
Results: 6 passed, 0 failed

$ bash tests/run-all.sh --continue
ALL TESTS PASS — 61/61
```

## Integration

- Native render: GitHub, Linear, Notion, IDE preview, brain-graph wiki — all support Mermaid in Markdown fences
- `aegis-brain-graph` indexes the mermaid source as text (no special handling needed)
- `aegis-doc-canon` linter has no quarrel with mermaid (treats as opaque code fence)
- ISO 29110 audit trail unchanged — diagrams are part of the docs, not replacements
- FTS5 brain search indexes mermaid syntax (`flowchart`, `sequenceDiagram` etc. become searchable keywords)

## Out of scope

- Retrofitting old sprint plans / closes with mermaid (historical record stays)
- Auto-render preview server (Markdown viewers handle it)
- Migrating to HTML for "more visual" output (see critique of "HTML is the new Markdown" — Markdown + Mermaid is the superset)

## Roadmap impact

v15 net: 53pt → 56pt.

## Follow-ups

- **v15-18 candidate**: same reflex for the 6 non-wired personas (Spider-Man, War Machine, Black Panther, Thor, Beast, Wasp) IF in practice their output looks too prose-heavy without it. Defer until observed.
