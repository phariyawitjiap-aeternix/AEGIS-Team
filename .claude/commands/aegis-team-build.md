---
name: aegis-team-build
description: "Spawn build team — Sage specs, Bolt implements, Vigil reviews"
triggers:
  en: team build, build team, spawn builders
  th: ทีมสร้าง, สร้างแบบทีม
---

# /aegis-team-build

Spawn a build team using Claude Code's **built-in Agent tool**.

## Instructions

When this command is triggered:

### Step 1: Determine the task

Look at the user's message for what they want built:
- "ทีมสร้าง — implement auth system" → task is "implement auth system"
- "/aegis-team-build add user CRUD" → task is "add user CRUD"
- Just "/aegis-team-build" with no task → ask: "What should the build team work on?"

### Step 2: Spawn agents using the Agent tool

Launch agents in sequence — each phase feeds the next:

**Phase 1: Architecture (📐 Sage)**

Use the Agent tool:
```
subagent_type: use the agent defined in .claude/agents/sage.md
prompt: |
  You are Sage, the system architect.
  Task: [TASK]

  Write a technical spec covering:
  1. Architecture overview and patterns
  2. Data model / schema
  3. File structure with all files to create
  4. Key implementation decisions

  Write output to: _aegis-output/specs/
  When done, summarize what you designed.
```

Wait for Sage to complete before proceeding.

**Phase 2: Implementation (⚡ Bolt)**

Use the Agent tool:
```
subagent_type: use the agent defined in .claude/agents/bolt.md
prompt: |
  You are Bolt, the implementer.
  Task: [TASK]

  Read the spec that Sage wrote in _aegis-output/specs/.
  Implement ALL files described in the spec.
  Write production-quality code with proper error handling.
  Run builds/tests if applicable.

  When done, list all files you created.
```

Wait for Bolt to complete before proceeding.

**Phase 3: Review (🛡️ Vigil)**

Use the Agent tool:
```
subagent_type: use the agent defined in .claude/agents/vigil.md
prompt: |
  You are Vigil, the code reviewer.
  Task: Review all files created by Bolt for [TASK].

  Run 4-pass review:
  1. Correctness — logic errors, edge cases
  2. Security — vulnerabilities, input validation
  3. Performance — bottlenecks, resource usage
  4. Maintainability — code quality, patterns

  Issue a quality gate: PASS, CONDITIONAL, or FAIL.
  Write review to: _aegis-output/reviews/
```

### Step 3: Report results

After all 3 agents complete, show the user:

```
🛡️ Build Team Complete!

📐 Sage: [summary of spec]
⚡ Bolt: [summary of implementation, file count]
🛡️ Vigil: [quality gate result, findings count]

Output:
  _aegis-output/specs/      ← architecture spec
  _aegis-output/reviews/    ← review report
  [project files]           ← implementation
```

## Pipeline

```
Sage (spec) → GATE → Bolt (implement) → GATE → Vigil (review)
                                                    ↓
                                              APPROVE → done
                                              CHANGES → Bolt fixes → Vigil re-reviews
```
