# Review Checklist — Multi-Pass Review Methodology

> Used by Vigil (primary) and any agent conducting review-type tasks.

## The 5-Pass Review

Every review MUST execute all 5 passes in order. No pass may be skipped.

### Pass 1: Correctness
- Does the code do what the spec says it should?
- Are all edge cases handled?
- Are return types and error states correct?
- Do loops terminate? Are off-by-one errors present?
- Are null/undefined states handled properly?

### Pass 2: Security
- Input validation: are all external inputs sanitized?
- Authentication: are auth checks present where required?
- Authorization: are permission checks correctly scoped?
- Data exposure: are sensitive fields excluded from responses?
- Dependencies: are known vulnerabilities present?
- Injection: SQL, XSS, command injection vectors?

### Pass 3: Performance
- Are there N+1 query patterns?
- Are expensive operations cached appropriately?
- Are large datasets paginated?
- Are there unnecessary re-renders or recomputations?
- Are async operations handled efficiently?
- Are there memory leaks (unclosed connections, listeners)?

### Pass 4: Maintainability
- Is the code readable without excessive comments?
- Are functions and variables named clearly?
- Is the code DRY (Don't Repeat Yourself)?
- Are modules appropriately sized and focused?
- Is the dependency graph clean (no circular dependencies)?
- Are magic numbers and strings extracted to constants?

### Pass 5: SDD Compliance
- Does the implementation match the approved specification?
- Are all specified interfaces implemented?
- Are deviations from spec documented and justified?
- Do file locations match the project structure conventions?
- Are all required tests present?

## Finding Format

Each finding from any pass must include:

```
[SEVERITY] [PASS_NAME] — [Description]
Location: [file]:[line_range]
Evidence: [code snippet or reference]
Recommendation: [what to change]
```

**Example:**
```
🔴 SECURITY — SQL injection vector in user search
Location: src/api/users.ts:45-48
Evidence: Raw user input concatenated into SQL query string
Recommendation: Use parameterized queries via the ORM query builder
```

## Gate Criteria

After all 5 passes are complete, apply the quality gate:

| Condition | Result | Action |
|-----------|--------|--------|
| 0 critical findings | ✅ PASS | Approved for merge/deploy |
| 0 critical + warnings present | 🟡 CONDITIONAL | Approved with required follow-up |
| 1+ critical findings | 🔴 FAIL | Blocked until critical issues resolved |

## Consensus Requirement

- A deliverable requires **at least 2 agents** to agree on PASS for final approval
- Typical consensus pairs: Vigil + Havoc, Vigil + Sage, Vigil + Navi
- If agents disagree, Navi arbitrates and documents the decision rationale
- Human override is always available and supersedes agent consensus

## Review Report Template

```markdown
# [EMOJI] Review: [Subject]
Timestamp: YYYY-MM-DD HH:MM UTC
Reviewer: [Agent Name]
Verdict: [PASS | CONDITIONAL | FAIL]

## Summary
[2-3 sentences with overall assessment]

## Pass Results
| Pass | Findings | Critical | Warnings |
|------|----------|----------|----------|
| Correctness | N | N | N |
| Security | N | N | N |
| Performance | N | N | N |
| Maintainability | N | N | N |
| SDD Compliance | N | N | N |

## Critical Findings
[List all critical findings]

## Warnings
[List all warnings]

## Suggestions
[List suggestions, if space permits]
```
