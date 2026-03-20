---
name: aegis-context
description: "Check context window budget — usage breakdown and optimization suggestions"
triggers:
  en: context check, context budget, how much context left
  th: เช็ค context, context เหลือเท่าไหร่
---

# /aegis-context

## Quick Reference
Context budget monitoring tool. Estimates current context usage as a percentage,
shows breakdown (loaded files, agent prompts, conversation history), displays a
traffic light indicator (green <40%, yellow 40-70%, red >70%), suggests optimization
actions when high, and shows cost estimates for common pipeline operations.

## Full Instructions

### Step 1: Estimate Current Context Usage
- Approximate the current context window consumption.
- Factors to estimate:
  - System prompt and CLAUDE.md content
  - Loaded slash command definitions
  - Conversation history (messages so far)
  - Any files currently "in context" from recent reads
  - Agent/team prompts if any are active
- Express as a percentage of the model's context limit.
- Note: This is an approximation — exact token counts are not available.

### Step 2: Show Usage Breakdown
- Display a detailed breakdown:
  ```
  ┌─ Context Budget ─────────────────────────────┐
  │                                               │
  │  Total Estimated Usage: [X]%                  │
  │  ████████░░░░░░░░░░░░ [visual bar]           │
  │                                               │
  │  Breakdown:                                   │
  │  ├─ System prompt & config:  ~[X]%            │
  │  ├─ Conversation history:    ~[X]%            │
  │  ├─ Loaded files:            ~[X]%            │
  │  │  ├─ [file1.ts]            ~[N] tokens      │
  │  │  ├─ [file2.ts]            ~[N] tokens      │
  │  │  └─ [file3.ts]            ~[N] tokens      │
  │  ├─ Agent prompts:           ~[X]%            │
  │  └─ Tool definitions:       ~[X]%            │
  │                                               │
  └───────────────────────────────────────────────┘
  ```

### Step 3: Traffic Light Status
- Display the appropriate traffic light:
  - 🟢 **GREEN** (<40%): "Plenty of context remaining. Operate freely."
  - 🟡 **YELLOW** (40-70%): "Context getting warm. Be mindful of large file reads."
  - 🔴 **RED** (>70%): "Context critically high. Take action now."
- For each level, provide context-appropriate guidance.

### Step 4: Suggest Actions (if Yellow or Red)
- **Yellow (40-70%)**:
  ```
  Suggestions:
  • Avoid loading large files — use targeted reads with line ranges
  • Consider running /compact to summarize conversation history
  • Reduce active agent count if using teams
  • Summarize long outputs instead of displaying raw data
  ```
- **Red (>70%)**:
  ```
  ⚠️ URGENT — Context budget critical!
  Recommended actions:
  1. Run /compact immediately to reclaim space
  2. If running a pipeline, pause and save state
  3. Consider running /aegis-handoff and starting a fresh session
  4. Disable any agents that aren't actively needed
  5. Avoid reading new files — work from memory
  ```

### Step 5: Pipeline Cost Estimates
- Show estimated context cost for common operations:
  ```
  ┌─ Operation Cost Estimates ──────────────────┐
  │                                              │
  │  /aegis-pipeline (full)     ~25-35%          │
  │  /aegis-team-review         ~15-20%          │
  │  /aegis-team-build          ~15-20%          │
  │  /aegis-team-debate         ~20-25%          │
  │  /aegis-verify              ~5-10%           │
  │  Reading a large file       ~2-5% per file   │
  │  Spawning a subagent        ~5-8% each       │
  │                                              │
  │  Available budget: ~[remaining]%             │
  │  Can fit: [list feasible operations]         │
  └──────────────────────────────────────────────┘
  ```
- Based on remaining budget, note which operations are feasible and which would risk overflow.
