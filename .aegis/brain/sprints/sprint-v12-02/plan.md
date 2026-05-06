# Sprint v12-02 Plan: GUARDRAILS.md (Sign migration)

**Points**: 5pt · **Branch**: `sprint-v12-02` (stacked on `sprint-v12-01`)

## Goal

Migrate prose lessons from `CLAUDE_lessons.md` + key auto-memory entries + recent v11 PR fix-classes into structured **Sign form** (Trigger / Do / Why). Build `add-sign.mjs` interactive helper. Extend `aegis-doc-canon/lint.mjs` to cover `GUARDRAILS.md`.

Closes Knowledge-Layer Mega Plan v1.1 §6 v12-02.

## Sign shape (canonical)

```markdown
### <Sign title>

- **Trigger:** <observable cue — what tells you this sign applies>
- **Do:** <the action that resolves it>
- **Why:** <what failure mode is being prevented; ideally with a concrete past incident>
```

## Stories

| ID | Story | Pt |
|----|-------|----|
| A | Author `GUARDRAILS.md` skeleton (Scope · Non-negotiables · Signs sections) with v1.0.0 version header | 1 |
| B | Migrate ≥ 10 Signs from existing material (CLAUDE_lessons.md A001–A007, auto-memory feedback, recent v11 PR fix-classes) | 2 |
| C | `tools/aegis-doc-canon/add-sign.mjs` — interactive append helper (validates Trigger/Do/Why fields; non-interactive mode via flags for testability) | 1 |
| D | Extend `aegis-doc-canon/lint.mjs` to include GUARDRAILS.md + tests for add-sign.mjs | 1 |

## Sign sources (planning the catalog)

10 minimum, drawn from these well-known recurring failure classes:

1. **"Wired but not shipped"** — install.sh delivery bug class (surfaced 4× in v11 PRs #105/108/114)
2. **"set -e + empty-array"** — fixed 3× in v11 (PR #107 set-u guard)
3. **"grep -c double-print"** — fixed 2× in v11 pilot scripts (PR #108)
4. **"node fifo O_RDONLY EOF"** — fixed in PR #105
5. **"Doc/reality skew"** — fixed 3× in v11 (e.g. mega-plan still says "Status: Proposed" after delivery)
6. **`git commit --amend` in multi-agent** — Golden Rule #3
7. **`AskUserQuestion` option-menu** — MBP rule #7 violation pattern
8. **Hook fail-CLOSED bug locks user out** — DoD §2 / Mega Plan R6
9. **Policy without test** — auto-memory feedback (rules claiming "MUST/enforces" without enforcement code)
10. **Doc-version vs framework-version conflation** — surfaced in sprint-v12-01 close
11. **Lint missing empty-table case** — surfaced in sprint-v12-01 close
12. **Ask-after-explicit-go** — auto-memory feedback (treating "approve"/"เอาให้ครบ" as needing clarification)

## Acceptance criteria

- [ ] `GUARDRAILS.md` exists at repo root with: version header, Changelog row, Scope section, Non-negotiables section, Signs section
- [ ] ≥ 10 Signs captured in canonical Trigger/Do/Why shape
- [ ] `tools/aegis-doc-canon/add-sign.mjs` exists; supports interactive AND `--title/--trigger/--do/--why/--non-interactive` flags
- [ ] add-sign.mjs validates that all 3 fields are present and non-empty
- [ ] add-sign.mjs writes to the correct section (under `## Signs`) without disturbing earlier content
- [ ] `aegis-doc-canon/lint.mjs` includes GUARDRAILS.md in DEFAULT_DOCS list and passes on the live tree
- [ ] `CLAUDE_lessons.md` gets a "see also: GUARDRAILS.md" pointer (light cross-ref, not a duplication)
- [ ] Tests: ≥ 8 assertions covering add-sign happy path, missing-field rejection, lint passes with GUARDRAILS, lint fails without GUARDRAILS
- [ ] Sprint roadmap row flips to CLOSED 5/5

## Out of scope

- Auto-extracting Signs from `decision-audit.log` (deferred to v10-07 / Hermes L2)
- Per-Sign metadata (severity, owner, last-fired-at) — keep schema minimal until v12-04 graph queries can use it
- HTML / web view of Signs

## References

- Knowledge-Layer Mega Plan v1.1 §2.4 + §6 v12-02
- GitNexus `GUARDRAILS.md` Sign pattern
- `CLAUDE_lessons.md` A001–A007 (anti-patterns to convert)
- `~/.claude/projects/-Users-phariyawit-jiap-Documents-AEGIS-Team/memory/MEMORY.md` (auto-memory feedback Signs)
- sprint-v12-01 close.md (2 new Signs surfaced during v12-01)
