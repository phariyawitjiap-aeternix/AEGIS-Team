# Sprint v11-04 Plan: aegis-parallel-dispatch

**Points**: 3pt · **Branch**: `feat/v11-04-aegis-parallel-dispatch`

This is the **last sprint of v11 Phase-1**. After this lands, v11 Phase-1 (selected scope) hits 100% and Phase-2 gating kicks in.

## Stories
| ID | Story | Pt |
|----|-------|----|
| A | SKILL.md with discipline guidance + 3 worked examples | 1 |
| B | dispatch.mjs helper — manifest → markdown plan with N parallel Agent stubs | 1 |
| C | Tests + examples/parallel-review.md | 1 |

## Acceptance criteria (plan §6.4)
- [ ] Skill description includes 3+ worked examples
- [ ] Helper produces ≥2 parallel Agent stubs from a manifest
- [ ] Aggregation pattern (markdown summary table) documented in SKILL.md
- [ ] Hard cap of 5 concurrent agents enforced (helper rejects manifests with N>5 unless --force)
- [ ] Test: invoke helper with 3-task manifest, verify exactly 3 Agent stubs in output
