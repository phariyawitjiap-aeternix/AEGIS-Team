---
name: aegis-breakdown
description: "Decompose a user story into journeys, epics, tasks, and subtasks using Sage sub-agent"
triggers:
  en: breakdown, decompose
  th: แตกงาน, แยกย่อย
---

# /aegis-breakdown

## Quick Reference
Break down a user story or feature description into a structured work hierarchy using the
Sage sub-agent. Produces ready-to-plan task lists that feed into sprint planning and the kanban board.

- **Skill**: `work-breakdown` (see `skills/work-breakdown.md` for full hierarchy rules)
- **Agent**: Sage (opus) — decomposition lead
- **Output**: `_aegis-output/breakdown/<US-NNN>/`

**Usage**:
```
/aegis-breakdown "As a user, I want to reset my password so that I can regain access"
/aegis-breakdown "Add dark mode support"
```

## Full Instructions

### Step 1: Parse Input

Accept the user story text from the command argument.

- If in full "As a... I want... So that..." format, use as-is.
- If in short format (just a feature description), Sage will infer and write the full user story format.
- If no argument provided, prompt: `Please provide a user story or feature description to break down.`

### Step 2: Assign Story ID

- Scan `_aegis-output/breakdown/` for existing `US-NNN` directories.
- Assign the next available `US-NNN` ID (zero-padded to 3 digits).

### Step 3: Spawn Sage for Decomposition

Delegate to the Sage sub-agent with the `work-breakdown` skill loaded:

```
Sage, decompose this user story using the work-breakdown skill:

Story: <full user story text>
ID: US-NNN

Follow the 5-step decomposition process:
1. Parse the user story
2. Identify user journeys (J-NNN)
3. Break journeys into epics (E-NNN)
4. Break epics into tasks (T-NNN) with types and point estimates
5. Optionally break tasks >= 5pts into subtasks (ST-NNN)

Write all output to: _aegis-output/breakdown/US-NNN/
Validate against all rules before finalizing.
```

### Step 4: Validate Output

After Sage completes, verify:

1. Directory `_aegis-output/breakdown/US-NNN/` exists with required files:
   - `summary.md` — overview with stats and hierarchy tree
   - `journeys/J-NNN.md` — one file per journey
   - `epics/E-NNN.md` — one file per epic
   - `tasks.md` — flat task list ready for backlog import
   - `tree.md` — visual hierarchy tree
2. No task exceeds 13 story points.
3. No epic exceeds 40 story points total.
4. All IDs are unique and properly formatted.
5. Dependencies are acyclic.

If validation fails, report the issues and ask Sage to fix them.

### Step 5: Display Summary

Show the breakdown summary to the human:

```
BREAKDOWN COMPLETE — US-NNN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Story: As a <persona>, I want <action> so that <benefit>

Journeys:  <N>
Epics:     <N>
Tasks:     <N>
Subtasks:  <N>
Total pts: <sum>
Est sprints: <pts / avg_velocity>

Tree:
US-NNN: <story>
├── J-001: <journey>
│   ├── E-001: <epic> [<pts>pts]
│   │   ├── T-001: <task> [<pts>pts] @<type>
│   │   └── T-002: <task> [<pts>pts] @<type>
│   └── E-002: <epic> [<pts>pts]
│       └── T-003: <task> [<pts>pts] @<type>
└── J-002: <journey>
    └── E-003: <epic> [<pts>pts]
        └── T-004: <task> [<pts>pts] @<type>

Output: _aegis-output/breakdown/US-NNN/
Tasks ready for backlog: _aegis-output/breakdown/US-NNN/tasks.md

Next: Run sprint planning to pull tasks into backlog,
      or use /aegis-kanban add to add individual tasks.
```

### Step 6: Log

Append to `_aegis-brain/logs/activity.log`:
```
[YYYY-MM-DD HH:MM] BREAKDOWN | story=US-NNN | journeys=<N> | epics=<N> | tasks=<N> | subtasks=<N> | total_pts=<pts>
```

### Error Handling

- **Empty input**: Prompt for a user story or feature description.
- **Sage unavailable**: Fall back to Navi performing the decomposition directly using the `work-breakdown` skill.
- **Output directory conflict**: If `US-NNN` already exists, increment to the next available ID.
- **Validation failure**: Report specific issues, retry decomposition with corrections.
- **Very large story (> 100 estimated points)**: Suggest splitting into multiple user stories before breakdown.
