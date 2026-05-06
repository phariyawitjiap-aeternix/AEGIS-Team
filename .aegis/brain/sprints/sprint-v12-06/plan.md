# Sprint v12-06 Plan: Auto-wiki + Staleness Signal

**Points**: 5pt · **Branch**: `sprint-v12-06` (stacked on `sprint-v12-05`)
**Final v12 sprint** — closes Phase B and v12 at 39/39pt.

## Goal

Generate `PROJECT_INDEX.md` + `_aegis-output/wiki/<topic>.md` per skill/sprint from the v12-04 NDJSON graph. Surface graph staleness at SessionStart. Close v12.

Closes Knowledge-Layer Mega Plan v1.1 §6 v12-06.

## Stories

| ID | Story | Pt |
|----|-------|----|
| A | `wiki.mjs` — read nodes+edges, write PROJECT_INDEX.md (auto-overwritten) + per-skill / per-sprint pages under `_aegis-output/wiki/` | 2 |
| B | Wiki determinism — byte-equal-skip if existing content matches | 1 |
| C | `staleness.mjs` — compare `meta.json.built_at` to `git log -1 --format=%cI HEAD`; emit one-line warning if HEAD is newer by ≥ 1 hour AND ≥ 1 source changed; SessionStart-friendly output | 1 |
| D | Tests + settings-patch update for SessionStart hook wiring | 1 |

## Output shapes

### `PROJECT_INDEX.md` (master TOC, auto-generated)

```markdown
<!-- version: auto -->
<!-- Last updated: <built_at> -->
<!-- Auto-generated from .aegis/brain/graph/ — DO NOT EDIT BY HAND -->

# AEGIS Project Index

> Auto-generated from the knowledge graph (`.aegis/brain/graph/`). Edit
> `_aegis-output/wiki/<topic>.md` for per-topic content; this file is
> regenerated on every PostToolUse Edit/Write/MultiEdit.

## Skills (NN)
- [skill-name](_aegis-output/wiki/skill-<name>.md) — description excerpt
- ...

## Sprints (NN)
- [v12-04](_aegis-output/wiki/sprint-v12-04.md) — CLOSED 8/8 pt
- ...

## Tools (NN packages)
- aegis-brain-graph (4 files)
- ...

## Hooks (NN)
- PostToolUse:.* (3 commands)
- ...

## Open issues (NN)
- ...
```

### `_aegis-output/wiki/skill-<name>.md`

```markdown
<!-- Auto-generated from graph — edit manifest at tools/aegis-doc-canon/skill-graph-manifest.json -->

# Skill: <name>

> <description from frontmatter>

## Profile
<profile>

## Triggers
- EN: ...
- TH: ...

## Wires (hooks that fire this)
- PostToolUse:.*:tools/.../emit.mjs

## Implemented in
- sprint-v11-01

## Tests
- tests/aegis-live-tail-test.sh

## Reads
- .aegis/brain/live/current.fifo

## Writes
- .aegis/brain/live/current.fifo

## See also
- Source: skills/<name>.md
```

### `_aegis-output/wiki/sprint-<id>.md`

```markdown
# Sprint <id>

**Status**: CLOSED · NN/NN pt
**Source**: .aegis/brain/sprints/sprint-<id>/close.md

## Implements
- tool:tools/aegis-live-tail/emit.mjs
- skill:aegis-live-tail
```

## CLI shape

```
$ node tools/aegis-brain-graph/wiki.mjs --root <path> [--out <dir>] [--quiet] [--check]
✓ wiki: 51 files written, 14 unchanged (skipped)
exit 0
```

`--check` exits 1 if any wiki page is out-of-date with the current graph (no writes).

### staleness.mjs

```
$ node tools/aegis-brain-graph/staleness.mjs --root <path>
🕒 brain graph N hours behind HEAD — run: bash tools/aegis-brain-graph/build.mjs --full

# Or silent on fresh graph:
$ node tools/aegis-brain-graph/staleness.mjs --root <path>
$ # (no output, exit 0)
```

## Acceptance criteria

- [ ] `PROJECT_INDEX.md` is auto-overwritten by `wiki.mjs --root <repo>`; sections for skills / sprints / tools / hooks
- [ ] `_aegis-output/wiki/skill-<name>.md` exists per skill (≥ 39); each has WIRES + IMPLEMENTS + TESTS + READS + WRITES sections (where applicable)
- [ ] `_aegis-output/wiki/sprint-<id>.md` exists per sprint with IMPLEMENTS list
- [ ] Wiki determinism: re-run produces zero-byte diff (byte-equal-skip)
- [ ] `staleness.mjs` exits 0 always; output empty when graph is fresh; banner when HEAD is newer by ≥ 1 hour AND graph predates the latest source mtime
- [ ] SessionStart hook wiring documented in `settings-patch.md` (between-session apply, same as v12-04)
- [ ] Tests: ≥ 10 assertions covering wiki determinism, content correctness, staleness fresh/stale scenarios, fail-OPEN
- [ ] v12-06 row CLOSED 5/5 in roadmap.md
- [ ] v12 grand total = 39/39 pt (100%)

## Out of scope

- HTML / browser viewer for the wiki — terminal-only mandate
- Auto-generated tool pages — only skills + sprints + master index in v12-06
- Auto-archive of pre-v12 manual PROJECT_INDEX.md content (skipped — current PROJECT_INDEX.md is already a structured wiki)

## References

- Knowledge-Layer Mega Plan v1.1 §2.6, §2.7, §5.3, §6 v12-06
- v12-04 (PR #121) — graph storage
- v12-05 (PR #122) — graph queries (some logic shared with wiki link generation)
