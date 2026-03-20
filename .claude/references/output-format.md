# Output Format — Standardized Report Structure

> All AEGIS agents MUST use this format for reports and deliverables.

## Report Header

Every report begins with:

```
[AGENT_EMOJI] [AGENT_NAME] — [REPORT_TITLE]
Timestamp: YYYY-MM-DD HH:MM UTC
Task ID: [reference to originating TaskAssignment]
```

**Example:**
```
🛡️ Vigil — Code Review: Authentication Module
Timestamp: 2026-03-20 14:30 UTC
Task ID: TASK-2026-0320-001
```

## Report Sections

Every report MUST include these sections in order:

### 1. Summary
- 2-3 sentences maximum
- State the conclusion first, then supporting context
- Include overall verdict if applicable (PASS / FAIL / CONDITIONAL)

### 2. Findings
- Bulleted list, ordered by severity (critical first)
- Each finding includes: severity tag, description, location (file:line if applicable)
- Group by category when there are more than 5 findings

### 3. Recommendations
- Actionable items, ordered by priority
- Each recommendation specifies: what to do, who should do it, estimated effort

### 4. Next Steps
- What happens after this report is delivered
- Who needs to act on it
- Any deadlines or dependencies

## Severity Tags

| Tag | Emoji | Meaning | Action Required |
|-----|-------|---------|-----------------|
| Critical | 🔴 | Blocks release, security risk, data loss | Must fix before proceeding |
| Warning | 🟡 | Should fix, potential issues | Fix before next review cycle |
| Suggestion | 🔵 | Nice to have, improvement opportunity | Consider for future iteration |
| Info | ⚪ | Informational, no action needed | For awareness only |

## Constraints

- **Max length**: 2000 tokens per report
- If a report exceeds 2000 tokens, split into numbered parts: `[slug]-part1.md`, `[slug]-part2.md`
- Each part must be self-contained with its own header and summary

## File Naming Convention

```
YYYY-MM-DD_HH-MM_[slug].md
```

**Examples:**
```
2026-03-20_14-30_auth-module-review.md
2026-03-20_15-00_api-design-spec.md
2026-03-20_16-45_dependency-scan-report.md
```

## Output Locations

Reports are saved to `_aegis-output/[category]/` where category matches the agent's designated output folder:

| Agent | Category | Path |
|-------|----------|------|
| Navi | sessions | `_aegis-output/sessions/` |
| Sage | architecture | `_aegis-output/architecture/` |
| Bolt | implementation | `_aegis-output/implementation/` |
| Vigil | reviews | `_aegis-output/reviews/` |
| Havoc | adversarial | `_aegis-output/adversarial/` |
| Forge | research | `_aegis-output/research/` |
| Pixel | ux | `_aegis-output/ux/` |
| Muse | content | `_aegis-output/content/` |
