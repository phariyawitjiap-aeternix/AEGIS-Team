<!-- version: 1.0.0 -->
<!-- Last updated: 2026-05-06 -->

Last reviewed: 2026-05-06

# AEGIS Skill Frontmatter Schema (v12-03)

> Authoritative reference for the YAML frontmatter shape that every `skills/<name>.md` file must satisfy. Validated by `tools/aegis-doc-canon/skill-frontmatter.mjs --lint`. Required by the v12-04 knowledge-graph builder.

## Changelog

| Date | Version | Change |
|------|---------|--------|
| 2026-05-06 | 1.0.0 | Initial schema authored as part of sprint-v12-03 (Knowledge-Layer Mega Plan Phase A). Adds 5 graph keys (reads, writes, wires, tests, supersedes) to the existing 4 (name, description, profile, triggers). |

---

## Required keys (must be PRESENT — values may be empty)

```yaml
---
name: <kebab-case-skill-name>             # MUST equal the filename without .md
description: <one-paragraph description>
profile: minimal | standard | full
triggers:
  en: [<list of EN trigger phrases>]      # may be empty array []
  th: [<list of TH trigger phrases>]      # may be empty array []

# Graph keys (added in v12-03; required PRESENT, values often [])
reads: []
writes: []
wires: []
tests: []
supersedes: []
---
```

### `name`

Must match the filename minus `.md` extension. The graph builder uses this as the canonical identifier.

### `description`

Free-text. The Skill router scans this for trigger phrases. No format constraint beyond "single paragraph."

### `profile`

One of `minimal` / `standard` / `full`. Determines which contexts auto-load this skill.

### `triggers`

Two lists: `en` (English trigger phrases) and `th` (Thai trigger phrases). Either may be empty. Scanned for matches when the user types or speaks something resembling a phrase.

### `reads` *(graph)*

List of brain paths this skill READS from. Examples: `".aegis/brain/activity/"`, `".aegis/brain/issues/*.yaml"`. Empty array = does not read any brain path.

The graph builder creates `READS` edges from the skill node to each path's destination node.

### `writes` *(graph)*

List of brain paths this skill WRITES to. Same shape as `reads`. Empty array = read-only-or-no-brain-mutation skill.

The graph builder creates `WRITES` edges.

### `wires` *(graph)*

List of hook chain anchors this skill ties into. Format: `"<event>:<matcher>:<command-tail>"`.

Examples:

- `"PostToolUse:.*:tools/aegis-activity-logger/log.mjs"`
- `"PreToolUse:Bash:tools/aegis-approval-gate/check.mjs"`
- `"SessionStart:startup:tools/aegis-resume/session-start.mjs"`

Empty array = pure command-style skill (no hook integration).

The graph builder creates `WIRES` edges from the hook node to the skill / tool node.

### `tests` *(graph)*

List of test file paths that cover this skill. Used by `aegis-brain-graph query impact <name>` to find which tests need re-running.

Empty array = skill has no dedicated test (allowed but discouraged for tool-backed skills).

The graph builder creates `TESTS` edges.

### `supersedes` *(graph)*

List of older skill or tool names this skill replaces. Used by `aegis-brain-graph query mentions <skill>` to surface migration history.

Examples:

- For an `aegis-resume` skill that replaced an older `session-recovery`: `supersedes: ["session-recovery"]`

Empty array = no supersession (the common case).

The graph builder creates `SUPERSEDES` edges (skill → predecessor).

---

## Tooling

### Lint (assert presence)

```bash
node tools/aegis-doc-canon/skill-frontmatter.mjs --lint
```

Exits 0 if every skill has all 9 required keys (4 base + 5 graph). Exit 1 lists which keys are missing on which skills.

### Backfill (idempotent)

```bash
node tools/aegis-doc-canon/skill-frontmatter.mjs --backfill [--dry-run]
```

For each skill missing one or more graph keys, inserts the missing keys with empty array values. Idempotent — running twice produces zero diff.

### Apply manifest

```bash
node tools/aegis-doc-canon/skill-frontmatter.mjs \
  --apply-manifest tools/aegis-doc-canon/skill-graph-manifest.json
```

Reads the manifest, sets the named values for each skill (overwriting existing values for those keys). The manifest is the single source of truth for non-empty graph values; the YAML in each skill is a generated reflection.

---

## Manifest format

`tools/aegis-doc-canon/skill-graph-manifest.json`:

```jsonc
{
  "$schema": "skill-schema.md v1.0.0",
  "skills": {
    "<skill-name>": {
      "reads":      [".aegis/brain/some/path"],
      "writes":     [".aegis/brain/other/path"],
      "wires":      ["PostToolUse:.*:tools/<name>/<entry>.mjs"],
      "tests":      ["tests/<name>-test.sh"],
      "supersedes": []
    }
  }
}
```

Skills not in the manifest are left untouched by `--apply-manifest`. Use `--backfill` after `--apply-manifest` to fill any keys still missing.

---

## See also

- `ARCHITECTURE.md` — high-level skill resolution flow
- `CLAUDE_skills.md` — human-facing skill catalog by profile
- `~/Documents/AEGIS-KNOWLEDGE-MEGA-PLAN.md` v1.1 §6 v12-03 — the plan spec
- v12-04 — graph builder that consumes this schema
