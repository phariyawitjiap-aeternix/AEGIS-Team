---
name: aegis-team-build
description: "Spawn build team via tmux — Sage specs, Bolt implements, Vigil reviews"
triggers:
  en: team build, build team, spawn builders
  th: ทีมสร้าง, สร้างแบบทีม
---

# /aegis-team-build

## Quick Reference
Spawns a build team using tmux. Lead: Bolt (speed implementer), Members: Sage (spec writer),
Vigil (reviewer). Pipeline: Sage writes/refines spec, Bolt implements based on spec,
Vigil reviews implementation. Gates between each step. Iterate if Vigil requests changes.
Falls back to sequential if tmux unavailable.

## Full Instructions

### Step 1: Check tmux Availability
- Run `which tmux` to check if tmux is installed.
- If tmux is available:
  ```
  ✅ tmux available — spawning Build Team
  ```
- If NOT available:
  ```
  ⚠️ tmux not available — falling back to sequential mode
  Build pipeline will run steps one at a time.
  ```

### Step 2: Spawn Team
- Create tmux session: `aegis-build-[timestamp]`
- Team structure:
  - **Lead**: Bolt (⚡ Speed) — implements features rapidly
  - **Member**: Sage (📖 Analyst) — writes specs and provides architectural guidance
  - **Member**: Vigil (🛡️ Guardian) — reviews implementation for quality and correctness
- Each agent receives their role and the feature/task description from the user.

### Step 3: Pipeline Execution

#### Stage 1 — Specification (Sage)
**Sage writes/refines the spec:**
- If user provided a spec: Sage reviews and refines it.
- If user provided a description: Sage creates a full spec.
- Spec includes:
  - Feature description and goals
  - Technical approach
  - File structure (new files, modified files)
  - Interface definitions (types, APIs, function signatures)
  - Edge cases and error handling
  - Test requirements
- Output: spec document shared with Bolt.

#### GATE: Spec Review
- Navi (or user if L1 autonomy) reviews the spec.
- Options: approve, request changes, or abort.
- If approved: proceed to implementation.

#### Stage 2 — Implementation (Bolt)
**Bolt implements based on spec:**
- Follow spec exactly for interfaces and structure.
- Implement all specified functionality.
- Write clean, idiomatic code following project conventions.
- Include inline documentation for non-obvious logic.
- Create or update tests as specified.
- Signal completion with list of files created/modified.

#### GATE: Implementation Review
- Pause before review to ensure all files are saved.

#### Stage 3 — Review (Vigil)
**Vigil reviews the implementation:**
- Verify implementation matches spec.
- Check code quality:
  - Error handling complete?
  - Edge cases covered?
  - Tests adequate?
  - No security issues?
  - Code style consistent with project?
- Output review with verdict:
  - ✅ **APPROVE**: Code is good to merge.
  - 🔄 **REQUEST CHANGES**: List specific changes needed.
  - ❌ **REJECT**: Fundamental issues require re-implementation.

#### Iteration Loop
- If Vigil requests changes:
  - Bolt receives the change requests.
  - Bolt makes the changes.
  - Vigil re-reviews.
  - Maximum 3 iterations before escalating to user.
- If Vigil approves:
  - Pipeline complete.
  - Present summary to user.

### Step 4: Final Output
- Display build summary:
  ```
  ╔══════════════════════════════════════════════════╗
  ║  Build Complete                                 ║
  ╠══════════════════════════════════════════════════╣
  ║  Feature: [name]                                ║
  ║  Files created: [N]                             ║
  ║  Files modified: [N]                            ║
  ║  Tests: [N] written, [pass/fail status]         ║
  ║  Review: ✅ Approved by Vigil                   ║
  ║  Iterations: [N]                                ║
  ╚══════════════════════════════════════════════════╝
  ```
- List all created/modified files.
- Suggest: run /aegis-verify for additional validation.
- Clean up tmux session.
