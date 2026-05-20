# Sprint v15-18A Kanban — Skill Auto-Discovery

## DONE

- [x] **A** — `install.sh` auto-discovery (2pt)
  - Replaced 3 hand-coded skill arrays with frontmatter glob-parse
  - `skill_min_rank()` helper handles pipe-separated tier lists
  - tier ordering: minimal=0 < standard=1 < full=2
  - ships if `min_rank <= wanted_rank`
- [x] **B** — `install-remote.sh` same refactor (2pt)
  - Same `skill_min_rank()` + loop semantics, applied to `${TMP_DIR}/skills/*.md`
  - Removed `copy_skills()` helper (no longer needed — direct cp inside loop)
- [x] **C** — Regression test (1pt)
  - `tests/aegis-skill-autodiscover-test.sh` × 6 scenarios
  - T1 frontmatter coverage / T2 tier ordering / T3 full = 37 / T4 install-remote markers / **T5 synthetic-skill proves drift class closed** / T6 hand-arrays removed

## Stories table

| Story | Type | Points | Status |
|-------|------|--------|--------|
| A — install.sh autodiscover | refactor | 2 | DONE |
| B — install-remote.sh autodiscover | refactor | 2 | DONE |
| C — regression + drift-class proof | testing | 1 | DONE |

**Total**: 5/5 done.

## Closes (bug-class level)

The recurring manifest-drift class identified in v15-08..17 series retro:
- v15-14 closed #182 (tool packages drift) via glob-discovery
- v15-17 hotfix surfaced skills drift (diagram-first-reflex missed array)
- v15-18A closes skill drift via same glob+frontmatter pattern

Three of four manifest-source-of-truth surfaces are now drift-proof:
- ✅ tool packages (v15-14)
- ✅ skills (v15-18A — this sprint)
- ✅ hook libs (v15-14)
- ⚠ agents (still explicit — but agent count changes are rare and breakage-loud)
