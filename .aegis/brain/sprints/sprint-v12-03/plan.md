# Sprint v12-03 Plan: Skill / tool / sprint frontmatter convergence

**Points**: 5pt · **Branch**: `sprint-v12-03` (stacked on `sprint-v12-02`)

## Goal

Establish a uniform frontmatter schema across all 39 skills (and high-value tool packages) so the v12-04 graph builder can parse them with a single shape. Backfill via a deterministic tool (no by-hand edits per skill). Lint enforces presence.

Closes Knowledge-Layer Mega Plan v1.1 §6 v12-03.

## Schema (additive — never removes existing keys)

Skill frontmatter today: `name`, `description`, `profile`, `triggers`. Plan adds 5 graph-keys (all optional values, but **keys must be present**, even with empty arrays):

```yaml
---
name: <unchanged>
description: <unchanged>
profile: minimal | standard | full
triggers:
  en: [...]
  th: [...]

# v12-03 graph keys (all required to be PRESENT; values may be []):
reads: []          # brain paths this skill READS from (e.g. ".aegis/brain/activity/")
writes: []         # brain paths this skill WRITES to (e.g. ".aegis/brain/issues/*.yaml")
wires: []          # hook chains this skill ties into (e.g. "PostToolUse:.*:tools/.../emit.mjs")
tests: []          # test files that cover this skill (e.g. "tests/aegis-activity-logger-test.sh")
supersedes: []     # older skill or tool names this replaces (for graph SUPERSEDES edges)
---
```

Why "present even if empty": a missing key is ambiguous (unknown vs deliberately none). An empty array is unambiguous. The graph builder treats `reads: []` as "this skill reads no brain paths" and skips creating edges; the lint catches the actual mistake (key omitted).

## Stories

| ID | Story | Pt |
|----|-------|----|
| A | Document the schema in `ARCHITECTURE.md` (new §) and a fresh top-level reference at `tools/aegis-doc-canon/skill-schema.md` | 1 |
| B | Build `tools/aegis-doc-canon/skill-frontmatter.mjs` — `--lint` (assert presence) and `--backfill` (idempotent fill of missing keys with `[]`) | 2 |
| C | Backfill: run `--backfill` across all 39 `skills/*.md`. Manually populate values for the 12 tool-backed skills via a JSON manifest (`tools/aegis-doc-canon/skill-graph-manifest.json`) | 1 |
| D | Tests: ≥ 8 assertions covering lint pass/fail, backfill idempotency, manifest application, schema enforcement | 1 |

## Tool design — `skill-frontmatter.mjs`

```text
$ node tools/aegis-doc-canon/skill-frontmatter.mjs --lint
✓ skills/aegis-activity-logger.md  — 5/5 graph keys present
✓ ... (37 more)
all 39 skills satisfy schema.
exit 0

$ node tools/aegis-doc-canon/skill-frontmatter.mjs --backfill [--dry-run]
+ skills/foo.md: added reads, writes, wires, tests, supersedes (5 keys)
+ skills/bar.md: already complete, no change
…

$ node tools/aegis-doc-canon/skill-frontmatter.mjs --apply-manifest tools/aegis-doc-canon/skill-graph-manifest.json
+ skills/aegis-activity-logger.md: writes ← [".aegis/brain/activity/YYYY-MM-DD.jsonl"]
+ skills/aegis-activity-logger.md: wires  ← ["PostToolUse:.*:tools/aegis-activity-logger/log.mjs"]
…
```

## Manifest shape

`tools/aegis-doc-canon/skill-graph-manifest.json`:

```jsonc
{
  "skills": {
    "aegis-activity-logger": {
      "reads": [],
      "writes": [".aegis/brain/activity/YYYY-MM-DD.jsonl"],
      "wires": ["PostToolUse:.*:tools/aegis-activity-logger/log.mjs"],
      "tests": ["tests/aegis-activity-logger-test.sh"],
      "supersedes": []
    },
    "aegis-live-tail": { ... },
    ...
  }
}
```

This decouples the per-skill graph metadata from the skill's prose body, so future schema additions or value tweaks happen by editing JSON, not 12 markdown files.

## Acceptance criteria

- [ ] Schema documented in `ARCHITECTURE.md` (new §) + standalone `tools/aegis-doc-canon/skill-schema.md`
- [ ] `tools/aegis-doc-canon/skill-frontmatter.mjs` exists with `--lint`, `--backfill`, `--apply-manifest`, `--dry-run`, `--json`
- [ ] All 39 skills have the 5 graph keys present (post-backfill)
- [ ] Manifest covers ≥ 12 tool-backed skills with non-empty values
- [ ] Lint exits 0 on the live tree post-backfill
- [ ] Lint exits 1 on a fixture with a missing key
- [ ] Backfill is idempotent: second `--backfill` run produces zero diff
- [ ] Tests: ≥ 8 assertions
- [ ] Sprint roadmap row flips to CLOSED 5/5

## Out of scope

- Tool-package frontmatter convergence (tools don't have unified frontmatter; v12-04 graph builder uses code-level regex/import scan instead)
- Auto-deriving `wires` values by parsing `.claude/settings.json` (graph builder does this in v12-04; this sprint just declares them)
- New schema fields beyond the 5 in the plan

## References

- Knowledge-Layer Mega Plan v1.1 §6 v12-03
- ARCHITECTURE.md §6 (Skill Resolution) — extended in this sprint
- Predecessor: sprint-v12-02 (PR #119)
