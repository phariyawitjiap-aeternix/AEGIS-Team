# S3-06: Wasp Revival -- Design Generator Agent

Wasp returns to AEGIS not as the retired UX auditor she was, but as the
design authority the team has been missing. AEGIS can copy a library DESIGN.md
or scaffold a blank skeleton -- but it cannot *think* about a project's
identity and author a design system from scratch. Wasp fills that gap: given
a brief, she produces a complete, lint-passing, 9-section DESIGN.md that
carries the project's soul. The experience should feel like hiring a senior
designer who already read the brand book before her first day.

---

## Table of Contents

1. [Story Overview](#1-story-overview)
2. [Wasp Agent Redesign](#2-wasp-agent-redesign)
3. [Nick Fury BLOCK 0F Custom-Author Branch](#3-nick-fury-block-0f-custom-author-branch)
4. [Loki Design-Approval Gate](#4-loki-design-approval-gate)
5. [Black Panther Accessibility Pass](#5-black-panther-accessibility-pass)
6. [Test Harness](#6-test-harness)
7. [Architecture Decision Records](#7-architecture-decision-records)
8. [Non-Functional Requirements](#8-non-functional-requirements)
9. [Trust Zones and Data Access](#9-trust-zones-and-data-access)
10. [Severity and Escalation](#10-severity-and-escalation)
11. [Do's and Don'ts](#11-dos-and-donts)
12. [Agent Prompt Guide](#12-agent-prompt-guide)

---

## 1. Story Overview

| Field | Value |
|-------|-------|
| Story ID | S3-06 |
| Title | Wasp Revival -- Design Generator |
| Points | 5 |
| Sprint | S3 (stretch revival) |
| Owner | Iron Man (spec), Spider-Man (build) |
| Reviewers | Loki (plan gate + design gate), Black Panther (a11y pass) |
| Dependencies | S3-02 (lint tool), S3-03 (BLOCK 0F gate) -- both SHIPPED |
| Predecessor | S3-05 (originally deferred in S3-VISUAL-LAYER-spec.md section 12) |

### Story Deliverables

| # | Deliverable | Points | Files Changed |
|---|-------------|--------|---------------|
| 1 | Un-archive + rewrite `wasp.md` with new role, MBP, capabilities, workflow | 2 | `.claude/agents/wasp.md` (un-archive from `_archived/`) |
| 2 | Nick Fury BLOCK 0F custom-author branch + `aegis-start.md` chain update | 1 | `.claude/agents/nick-fury.md`, `.claude/commands/aegis-start.md` |
| 3 | Loki Design-Approval Gate criteria + `loki.md` update | 0.5 | `.claude/agents/loki.md` |
| 4 | Black Panther a11y pass on DESIGN.md + `black-panther.md` update | 0.5 | `.claude/agents/black-panther.md` |
| 5 | Test harness `tools/aegis-wasp-generate-test.sh` | 1 | `tools/aegis-wasp-generate-test.sh` (new) |
| 6 | Contrast-check helper `tools/aegis-contrast-check.sh` (D-037 Fix 3) | 0 (within 5pt scope) | `tools/aegis-contrast-check.sh` (new, ~40 LOC bash+python) |

### Existing Paths (S3-01 through S3-04) -- Must Not Break

| Path | Trigger | Mechanism | S3-06 Impact |
|------|---------|-----------|-------------|
| A: Library copy | `aegis-design-init.sh --from <slug>` | Copy from `.aegis/brain/design-library/` | No change |
| B: Vibe match | `aegis-design-init.sh --vibe <keyword>` | Keyword-to-slug resolve, then copy | No change |
| C: Blank scaffold | `aegis-design-init.sh --blank` | Emit 9-section skeleton with TODOs | No change |
| **D: Custom author** | **Nick Fury dispatches Wasp** | **Wasp reads brief, authors DESIGN.md** | **NEW** |

Path D is additive. Paths A/B/C continue to work exactly as shipped.
Nick Fury selects Path D only when: (1) no DESIGN.md exists, (2) no
`--from` or `--vibe` flag was passed, AND (3) UI paths are detected.

---

## 2. Wasp Agent Redesign

### 2.1 New Agent Header

```yaml
---
name: wasp
description: "Design generator that authors custom DESIGN.md files from project briefs, following the 9-section VoltAgent skeleton. Use when the project needs a bespoke design system, not a library copy."
model: claude-sonnet-4-6
tools: [Read, Write, Edit, Glob, Grep, WebSearch]
disallowedTools: [Bash, Agent]
---
```

### 2.2 Identity

Wasp is the visual-design authority of AEGIS. She takes a project brief
(goals, audience, aesthetic cues, constraints) and authors a complete,
project-specific DESIGN.md that follows the 9-section VoltAgent skeleton.
Loki reviews for internal consistency; Black Panther reviews for
accessibility; Iron Man validates technical feasibility. Wasp believes
that design is not decoration -- it is the vocabulary a product uses to
speak to its users.

### 2.3 Capabilities

| Capability | Input | Output |
|------------|-------|--------|
| Author custom DESIGN.md from brief | User-provided description, OR `project-identity.md` scan, OR `package.json` keywords, OR `README.md` scan | Complete 9-section DESIGN.md at project root (structurally valid per lint; Nick Fury runs lint, not Wasp) |
| Revise existing DESIGN.md per review findings | Loki CONDITIONAL conditions OR Black Panther a11y findings | Updated DESIGN.md sections |
| Emit color palettes with semantic roles | Brief aesthetic cues ("warm", "corporate", "playful") | Section 2 with hex values, roles, contrast ratios |
| Emit typography scales | Brief constraints (target platform, density preference) | Section 3 with font families, sizes, weights, line heights |
| Describe component styles | Brief component list or inferred from project type | Section 4 with buttons, cards, inputs, navigation patterns |
| Cite library inspirations | Library reference request ("like Stripe but warmer") | Soul paragraph + per-section inspiration notes |

### 2.4 Constraints

| # | Constraint | Rationale |
|---|-----------|-----------|
| 1 | MUST NOT implement UI code | Spider-Man's job -- Wasp produces the contract, not the code |
| 2 | MUST NOT approve own DESIGN.md without Loki + BP review | Same gate pattern as Iron Man specs |
| 3 | MUST NOT copy library files unchanged | Her job is authoring custom -- if user wants a copy, they use `aegis-design-init.sh --from` |
| 4 | MUST NOT ask human questions directly | MBP Golden Rule #7 (see section 2.5) |
| 5 | MUST produce output that, when validated by Nick Fury via `tools/aegis-design-lint.sh --strict`, passes without errors. Wasp does not execute lint herself (Bash-less); she validates structurally by matching her output against the 9-section pattern documented in the linter's canonical list | Structural self-check; Nick Fury owns lint execution |
| 6 | MUST NOT skip any of the 9 canonical sections | Even if the brief says "no mobile" -- document the Responsive decision |
| 7 | MUST NOT invent accessibility-failing color combinations | Base text contrast must meet WCAG AA (4.5:1) |
| 8 | MUST NOT use WebSearch for anything other than design inspiration | No code search, no API lookup, no general queries |

### 2.5 Master Brain Protocol (MANDATORY -- CLAUDE.md Golden Rule #7)

**NEVER pause design work to ask the human for a decision.** That is Nick
Fury's job.

When you need a judgment call (e.g., "serif or sans-serif for this SaaS
dashboard?", "dark mode primary or light mode primary?"), route through
Nick Fury with `QUESTION_TO_BRAIN`:

```
QUESTION_TO_BRAIN
From: wasp
Task: <TASK-ID>
Context: <1-2 sentences on the design fork>
Options: A) ... B) ...
Recommendation: <A with 1-line rationale>
```

Nick Fury answers from brain/instincts/ADRs/policy and only escalates to
the human for 4 categories: Identity (P10), Irreversible scope, External
access, Explicit approval gate.

**Everything else** -- color choice, font pairing, mood direction, section
emphasis, mobile-first vs desktop-first -- Nick Fury decides, not the human.
Wasp captures the decision and rationale in the DESIGN.md soul paragraph.

**If Nick Fury is offline**: pick the best option based on project context
(README, package.json, project-identity.md), document the rationale in the
DESIGN.md soul paragraph, continue. Do NOT fall back to asking the human.

See `.claude/references/context-rules.md` section Master Brain Protocol.

### 2.6 Workflow

```
1. RECEIVE  DispatchDesignRequest from Nick Fury
   |        (contains: brief text + constraints + target path)
   v
2. SCAN     Project context for design cues:
   |        - .aegis/brain/resonance/project-identity.md
   |        - README.md (description, badges, screenshots)
   |        - package.json "description" + "keywords" fields
   |        - Existing DESIGN.md fragments (if partial)
   |        - .aegis/brain/design-library/ (for inspiration, not copying)
   v
3. DECIDE   If brief is ambiguous on any axis:
   |        - Use judgment + log via tools/aegis-log-decision.sh
   |          (source=judgment, reasoning required)
   |        - Cite library examples as inspiration anchors
   |          (e.g., "taking claude's warm-editorial tone + stripe's numeric-clarity")
   v
4. AUTHOR   DESIGN.md at project root using 9-section skeleton:
   |        - Soul paragraph first (name the FEEL)
   |        - All 9 sections filled with project-specific content
   |        - Color hex values with contrast ratios noted
   |        - Typography scale with >= 3 sizes and >= 2 weights
   |        - >= 3 component descriptions in section 4
   |        - Do's and Don'ts with >= 5 items each
   |        - Agent Prompt Guide with >= 2 builder prompts
   v
5. VALIDATE  Nick Fury (or whichever main agent dispatched Wasp) runs
   |         `tools/aegis-design-lint.sh --strict --file DESIGN.md` on
   |         Wasp's output BEFORE forwarding to Loki for Design-Approval
   |         Gate. Wasp produces the file; Nick Fury validates it.
   |         IF lint fails: Nick Fury returns to Wasp with specific
   |           diagnostics for revision (max 2 rounds, then escalate).
   |         IF lint passes: proceed to gate
   v
6. GATE      Send to Loki for Design-Approval Gate
   |         (new gate, parallel to Plan-Approval Gate)
   v
7. REVISE    On CONDITIONAL: revise per Loki's conditions, re-submit
   |         (max 2 revision rounds)
   v
8. A11Y      On APPROVE: send to Black Panther for accessibility review
   |         BP checks: contrast, typography min, touch targets, motion
   v
9. PUBLISH   On BP PASS: DESIGN.md is the project's canonical contract
             Log: "[WASP] DESIGN.md published for <project>"
```

### 2.7 Message Types

| Direction | Type | Description |
|-----------|------|-------------|
| Receives | DispatchDesignRequest | Nick Fury sends brief + constraints |
| Receives | DesignApprovalResponse | Loki returns APPROVE/CONDITIONAL/REJECT |
| Receives | FindingReport | Black Panther returns a11y findings |
| Sends | DesignProposal | Wasp sends completed DESIGN.md for review |
| Sends | DesignRevision | Wasp sends revised DESIGN.md after conditions |

### 2.8 Tool Permissions

| Tool | Allowed | Usage |
|------|---------|-------|
| Read | Yes | Read project context files, library examples, existing DESIGN.md |
| Write | Yes | Author new DESIGN.md at project root |
| Edit | Yes | Revise existing DESIGN.md per review findings |
| Glob | Yes | Scan for project files (README, package.json, identity files) |
| Grep | Yes | Search for design-relevant keywords in project files |
| WebSearch | Yes | Competitor/inspiration lookup only (no code search) |
| Bash | **No** | Wasp does not execute shell commands (follows Iron Man pattern) |
| Agent | **No** | Wasp does not spawn sub-agents |

### 2.9 Power Keywords

Wasp uses `ultrathink` when processing complex briefs with competing
aesthetic requirements:

```
ultrathink -- resolve the tension between "enterprise trust" and "playful AI"
in the color system for this SaaS dashboard
```

### 2.10 References

- `skills/design-system-md.md` -- 9-section format definition
- `.aegis/brain/design-library/` -- curated reference shelf (inspiration only)
- `tools/aegis-design-lint.sh` -- structural + content validator
- `.claude/references/context-rules.md` -- Context budget rules
- `.claude/references/adaptive-thinking-guide.md` -- Use `effort: low` per Nick Fury table

### 2.11 Output Location

Project root: `DESIGN.md` (primary artifact)

Drafts/iterations: `_aegis-output/design/` (working copies before publish)

---

## 3. Nick Fury BLOCK 0F Custom-Author Branch

### 3.1 Current BLOCK 0F Flow (S3-03 -- no change)

```
BLOCK_0F_CHECK(task):
  1. Detect UI paths (EXCLUDE before INCLUDE)
  2. IF no UI paths: NOT_APPLICABLE
  3. IF DESIGN.md exists + lint passes: PASS
  4. IF DESIGN.md missing: FAIL -- dispatch init tool
```

### 3.2 New Branch: Custom-Author Path (Path D)

Add after step 4 in the existing BLOCK_0F_CHECK. This branch fires only
when the task reaches FAIL (no DESIGN.md) AND no explicit `--from`/`--vibe`
flag was provided.

```
BLOCK_0F_CHECK_EXTENDED(task):
  -- Steps 1-2: unchanged (per S3-03)

  3. IF DESIGN.md exists:
     Run: tools/aegis-design-lint.sh --strict --file DESIGN.md
     IF lint passes: 0F = PASS
     IF lint fails AND --from or --vibe flag provided:
       dispatch aegis-design-init.sh with the flag (Path A or B, overwrites)
       BLOCK until DESIGN.md exists, then re-lint.
     IF lint fails AND no --from/--vibe flag:
       Dispatch Wasp with existing DESIGN.md as partial input
       Message: "Existing DESIGN.md fails --strict; revise per diagnostics:
                 <lint output>"
       BLOCK until Wasp signals DESIGN.md revised.
       Nick Fury re-runs: tools/aegis-design-lint.sh --strict --file DESIGN.md
       IF passes: 0F = PASS
       IF fails: 0F = FAIL (log error, fall back to --blank)

  4. IF DESIGN.md missing:
     a. Check if user/command specified --from or --vibe flag:
        IF yes: dispatch aegis-design-init.sh with the flag (Path A or B)
        BLOCK until DESIGN.md exists, then re-lint.

     b. IF no flag specified (Path D -- custom author):
        Log: "[HOOK:block0] task=<ID> 0F=custom-author-path dispatching=wasp"

        Construct brief from project context:
          brief_sources = []
          IF .aegis/brain/resonance/project-identity.md exists:
            brief_sources.append(read project-identity.md)
          IF README.md exists:
            brief_sources.append(read README.md description)
          IF package.json exists:
            brief_sources.append(read package.json description + keywords)

        Dispatch Wasp:
          DispatchDesignRequest {
            brief: concatenated brief_sources
            constraints: task.meta.json constraints (if any)
            target: "./DESIGN.md"
            library_path: ".aegis/brain/design-library/"
          }

        BLOCK until Wasp signals DESIGN.md published.
        Nick Fury runs: tools/aegis-design-lint.sh --strict --file DESIGN.md
        IF passes: 0F = PASS
        IF fails: 0F = FAIL (Wasp bug -- log error, fall back to --blank)
```

### 3.3 aegis-start.md Chain Update

Add to Step 4b (BLOCK 0 checks) after the existing 0F description:

```
BLOCK 0F (extended S3-06):
  IF DESIGN.md missing AND no --from/--vibe flag AND UI paths detected:
    Nick Fury dispatches Wasp to author custom DESIGN.md from project brief.
    Wasp -> Loki Design-Approval Gate -> Black Panther a11y pass -> DESIGN.md published.
    0F re-checks after publish.
```

### 3.4 Trigger Conditions

Path D dispatches Wasp under TWO scenarios:

**Scenario 1: DESIGN.md missing (all three must be true)**

| Condition | Check | Source |
|-----------|-------|--------|
| No DESIGN.md at project root | `[ ! -f ./DESIGN.md ]` | Filesystem |
| No `--from` or `--vibe` flag | Command arguments do not contain `--from` or `--vibe` | User command or Nick Fury dispatch context |
| UI paths detected in task | At least one file matches INCLUDE patterns after EXCLUDE filter | Task meta.json, PR changed files, or description |

**Scenario 2: DESIGN.md exists but broken (all three must be true)**

| Condition | Check | Source |
|-----------|-------|--------|
| DESIGN.md exists at project root | `[ -f ./DESIGN.md ]` | Filesystem |
| Lint fails | `tools/aegis-design-lint.sh --strict --file DESIGN.md` exits non-zero | Nick Fury runs lint |
| No `--from` or `--vibe` flag | Command arguments do not contain `--from` or `--vibe` | User command or Nick Fury dispatch context |

In scenario 2, Wasp receives the existing DESIGN.md as partial input plus
lint diagnostics. This prevents the "broken DESIGN.md blocks all UI work
forever" failure mode.

---

## 4. Loki Design-Approval Gate

### 4.1 Gate Identity

A new review gate parallel to the existing Plan-Approval Gate. Fires when
Wasp submits a custom-authored DESIGN.md. Does NOT fire on library copies
(Paths A/B) or blank scaffolds (Path C) -- those are validated by lint only.

### 4.2 Criteria

| # | Criterion | Check | Fail Verdict |
|---|-----------|-------|-------------|
| 1 | 9-section structure present | Run `tools/aegis-design-lint.sh --strict` | REJECT |
| 2 | `--strict` lint passes | All 9 sections have non-comment content | REJECT |
| 3 | Color system internally consistent | Primary, secondary, neutrals all defined; no contradictions between section 2 and section 4/7 | CONDITIONAL |
| 4 | Typography scale has >= 3 sizes AND >= 2 weights | Count entries in section 3 hierarchy table | CONDITIONAL |
| 5 | At least 3 components described in section 4 | Count `###` subsections under section 4 | CONDITIONAL |
| 6 | Do's and Don'ts each have >= 5 items | Count bullet items in section 7 | CONDITIONAL |
| 7 | Agent Prompt Guide has >= 2 builder prompts | Count prompts in section 9 | CONDITIONAL |

### 4.3 Verdict Format

Matches Plan-Approval Gate format with distinct `Task:` prefix:

```
DESIGN_APPROVAL_RESPONSE
Task: DESIGN:<slug>
Verdict: APPROVE | CONDITIONAL | REJECT
Conditions: [if CONDITIONAL -- list what Wasp must fix]
Blockers: [if REJECT -- list critical structural failures]
Summary: [1-2 sentences]
```

**Key difference from Plan-Approval Gate**:
- `Task:` field uses `DESIGN:<slug>` prefix (e.g., `DESIGN:rizzlab`)
  instead of `[TASK-ID]` used for specs
- Response type is `DESIGN_APPROVAL_RESPONSE` not `PLAN_APPROVAL_RESPONSE`

### 4.4 Verdict Criteria

| Verdict | Meaning | Next Step |
|---------|---------|-----------|
| APPROVE | All 7 criteria pass | Wasp sends to Black Panther for a11y |
| CONDITIONAL | Criteria 3-7 have minor gaps | Wasp revises per conditions, resubmits |
| REJECT | Criteria 1-2 fail (structural) | Wasp must regenerate from scratch |

### 4.5 Integration with Existing Loki Sections

Add the Design-Approval Gate as a new `##` section in `loki.md`, placed
after the existing Plan-Approval Gate section and before Message Types.

The section heading: `## Design-Approval Gate (S3-06)`

Loki's existing instinct loading and security path override still fire
before the Design-Approval Gate review (same pipeline as Plan-Approval).

### 4.6 MBP Enforcement on DESIGN.md

Loki's existing MBP enforcement rule ("auto-REJECT any spec or agent
response that asks the human a question outside the 4 categories") extends
to DESIGN.md review. If Wasp's DESIGN.md contains language like "the user
should choose between X and Y" -- that is a MBP violation. Wasp must make
the choice and document the rationale.

---

## 5. Black Panther Accessibility Pass

### 5.1 Trigger

Fires after Loki's Design-Approval Gate returns APPROVE. Black Panther
reviews the DESIGN.md for accessibility compliance before it becomes the
canonical contract.

### 5.2 A11y Check Criteria

| # | Check | Standard | Threshold | Finding Severity |
|---|-------|----------|-----------|-----------------|
| 1 | Color contrast: primary/background | WCAG AA | 4.5:1 for normal text, 3:1 for large text. BP verifies Wasp's inline ratios via `tools/aegis-contrast-check.sh` (see note below) | P2 if fail |
| 2 | Color contrast: secondary/background | WCAG AA | 4.5:1 for normal text. BP verifies Wasp's inline ratios via `tools/aegis-contrast-check.sh` (see note below) | P3 if fail |
| 3 | Typography minimum base size | WCAG best practice | >= 14px base, no readable text < 12px | P2 if fail |
| 4 | Touch targets (if mobile responsive) | WCAG 2.5.8 | >= 44x44px per section 8 Responsive | P3 if fail |
| 5 | Motion/animation clause | WCAG 2.3.3 | If animations defined, must include `prefers-reduced-motion` | P3 if fail |
| 6 | Focus indicator definition | WCAG 2.4.7 | Section 4 Components must define focus ring style | P3 if fail |

**Contrast verification (dual-layer -- D-037 Fix 3):**
- **(a) Primary:** Wasp MUST emit precomputed contrast ratios inline in
  section 2. Each color pair vs background includes a ratio and WCAG AA
  pass/fail annotation. BP reads these annotations directly from the text.
- **(b) Secondary:** `tools/aegis-contrast-check.sh` parses section 2 hex
  pairs from DESIGN.md and independently computes WCAG contrast ratios
  (~40 LOC bash + python). BP invokes this tool during PASS 7 checks 1-2
  to mechanically verify Wasp's claimed ratios. Discrepancies between
  Wasp's inline claims and computed values produce a P2 finding.

### 5.3 Finding Format

Follows existing Black Panther PASS 1-6 severity scheme:

```
A11Y_FINDING
Source: DESIGN.md
Section: <section number and name>
Check: <check name from table above>
Severity: P2 | P3
Finding: <specific issue>
Recommendation: <specific fix>
```

### 5.4 Verdict

| Result | Meaning | Next Step |
|--------|---------|-----------|
| PASS (0 findings) | DESIGN.md is accessible | Publish as canonical contract |
| PASS with warnings (P3 only) | Minor a11y gaps | Wasp addresses in next revision cycle; publish proceeds |
| FAIL (any P2 finding) | Accessibility violation | Wasp must fix and resubmit to BP |

### 5.5 Integration with Existing BP Sections

Add as a new sub-section under Black Panther's review methodology, after
the existing PASS 6 (Visual Conformance) section:

**PASS 7: DESIGN.md Accessibility Review (S3-06)** -- conditional, only
fires when Loki sends a DESIGN.md for a11y review after Design-Approval
Gate APPROVE.

This pass reviews the DESIGN.md *document* for accessibility of the
*specified design*, distinct from PASS 6 which reviews *implemented code*
for conformance to DESIGN.md.

---

## 6. Test Harness

### 6.1 Test Script

**Path**: `tools/aegis-wasp-generate-test.sh`

This is a mocked end-to-end test. It does not invoke Wasp as an agent
(that requires Claude context). Instead, it validates the pipeline
contracts: brief input format, DESIGN.md output structure, lint
compliance, and gate verdict format.

### 6.2 Test Cases

| # | Test Case | Setup | Assertion | Expected |
|---|-----------|-------|-----------|----------|
| 1 | Valid DESIGN.md passes lint strict | Copy a library DESIGN.md to temp dir as mock Wasp output | Run `aegis-design-lint.sh --strict --file <path>` | Exit 0 |
| 2 | DESIGN.md with missing section fails lint | Create DESIGN.md without Typography section | Run lint strict | Exit 1, output contains "Missing section" |
| 3 | DESIGN.md with empty section fails strict | Create DESIGN.md with all headers but section 4 body is only comments | Run lint strict | Exit 1, output contains "no content" |
| 4 | Design-Approval verdict format | Create mock verdict file with `DESIGN:testproject` prefix | `grep -c "DESIGN:" <file>` | Count >= 1 |
| 5 | Design-Approval verdict distinct from Plan-Approval | Create mock verdict with `DESIGN_APPROVAL_RESPONSE` | `grep -c "DESIGN_APPROVAL_RESPONSE" <file>` | Count >= 1 |
| 6 | Brief sources scan finds project-identity.md | Create temp project-identity.md with known content | `grep -c "<known-content>" <identity-file>` | Count >= 1 |

### 6.3 Acceptance Checks (Inline in Test Script)

```bash
# AC-1: Un-archived Wasp has MBP section
grep -c "Master Brain Protocol" .claude/agents/wasp.md
# Expected: >= 1

# AC-2: Nick Fury has custom-author branch
grep -c "custom-author" .claude/agents/nick-fury.md
# Expected: >= 1

# AC-3: Loki has Design-Approval Gate
grep -c "Design-Approval Gate" .claude/agents/loki.md
# Expected: >= 1

# AC-4: Loki verdict prefix is DESIGN: not TASK
grep -c "DESIGN:" .claude/agents/loki.md
# Expected: >= 1

# AC-5: Black Panther has PASS 7 a11y review
grep -c "PASS 7" .claude/agents/black-panther.md
# Expected: >= 1

# AC-6: Wasp file is NOT in _archived/
test ! -f .claude/agents/_archived/wasp.md
# Expected: exit 0 (file does not exist)
```

---

## 7. Architecture Decision Records

### ADR-S3-06-01: Wasp Gets WebSearch, Not Bash

**Status**: Accepted

**Context**: The archived Wasp had `[Read, Write, Edit, Glob, Grep]`. The
redesign needs competitive research capability. Options: add Bash (for
curl-based web fetching) or add WebSearch (Claude-native web search).

**Decision**: Add WebSearch, explicitly disallow Bash.

**Rationale**:
- WebSearch provides structured search results without shell access risks
- Wasp's role is authoring documents, not executing commands
- Follows Iron Man's pattern: `tools: [..., WebSearch]`, `disallowedTools: [Bash, Agent]`
- `aegis-design-lint.sh` is run by Nick Fury or Loki in their own
  context, not by Wasp directly -- Wasp self-validates by reading lint
  output, not executing bash

**Consequences**: Wasp cannot run `aegis-design-lint.sh` directly (Bash-less).
Ownership chain for lint validation: (1) Wasp authors DESIGN.md and
structurally self-validates by matching her output against the 9-section
pattern documented in the linter's canonical list -- no shell execution
required. (2) Nick Fury (the dispatching agent) runs
`tools/aegis-design-lint.sh --strict --file DESIGN.md` on Wasp's output
before forwarding to Loki. If lint fails, Nick Fury returns diagnostics to
Wasp for revision (max 2 rounds, then escalate). (3) Loki independently
re-runs lint as Design-Approval Gate criterion 1-2.

### ADR-S3-06-02: Design-Approval Gate Separate from Plan-Approval Gate

**Status**: Accepted

**Context**: Loki already has a Plan-Approval Gate for Iron Man specs. Wasp's
DESIGN.md could be reviewed through the same gate or a new one.

**Decision**: New gate with distinct verdict format.

**Rationale**:
- DESIGN.md has different quality criteria than architecture specs (color
  consistency vs API contracts, typography scale vs data models)
- Distinct `DESIGN_APPROVAL_RESPONSE` + `DESIGN:<slug>` prefix makes log
  parsing unambiguous
- Shared infrastructure: same instinct loading, same MBP enforcement,
  same revision round limit (max 2)
- Keeps Loki's two gate roles clearly separated in the agent prompt

**Consequences**: Loki's prompt grows by one section (~40 lines). The
benefit of clear separation outweighs the prompt-length cost.

### ADR-S3-06-03: Path D Trigger is Additive, Not Replacing

**Status**: Accepted

**Context**: Should Wasp replace the existing `--blank` fallback in BLOCK 0F,
or should she be an additional path?

**Decision**: Additive. Path D fires only when no flag is specified.

**Rationale**:
- Existing Paths A/B/C are well-tested and shipped (S3-01 through S3-04)
- Users who explicitly pass `--from` or `--vibe` want a library copy, not
  a custom author session
- `--blank` scaffold is still useful for users who want to write DESIGN.md
  manually
- Path D is the "intelligent default" when Nick Fury detects UI work and
  no user preference was expressed
- Zero breaking changes to existing workflows

**Consequences**: Four paths total. Nick Fury's dispatch logic has one more
branch. Decision tree is documented in section 3.4.

---

## 8. Non-Functional Requirements

### Performance

| Operation | Target | Rationale |
|-----------|--------|-----------|
| Wasp brief scan (step 2) | < 5s | Reading 3-4 small project files |
| Wasp DESIGN.md authoring (step 4) | < 60s | LLM generation of ~300 lines |
| Loki Design-Approval review | < 30s | Text analysis of 9 sections |
| BP a11y review | < 15s | 6 checks against document content |
| End-to-end Path D (dispatch to publish) | < 3 min | Including one revision round |

### Security

- WebSearch queries must not contain project secrets or internal data
- Wasp reads project files for context but does not exfiltrate content
- DESIGN.md is a project artifact in version control -- no secrets in it
- Library files remain immutable (protected by guard-write.sh per S3-03)

### Compatibility

- Wasp prompt uses the same YAML frontmatter format as all other agents
- Wasp's DESIGN.md output is validated by the same lint tool (S3-02)
- Wasp's gate uses the same verdict structure as Plan-Approval Gate
- All three existing paths (A/B/C) work identically after this change

---

## 9. Trust Zones and Data Access

| Zone | Auth | Data Access | S3-06 Agent |
|------|------|-------------|------------|
| project | filesystem | read `project-identity.md`, `README.md`, `package.json` | Wasp (brief scan) |
| project | filesystem | read `.aegis/brain/design-library/*` (inspiration only) | Wasp (reference) |
| project | filesystem | write `DESIGN.md` at project root | Wasp (authoring) |
| public | WebSearch | read-only competitor/inspiration results | Wasp (research) |
| agent | prompt-level | read Wasp prompt, validate output | Nick Fury (dispatch) |
| agent | prompt-level | read DESIGN.md, validate criteria | Loki (design gate) |
| agent | prompt-level | read DESIGN.md, validate a11y | Black Panther (a11y pass) |

---

## 10. Severity and Escalation

| Severity | Trigger | Handler | Escalation |
|----------|---------|---------|------------|
| P0 | Wasp overwrites existing DESIGN.md without permission | Nick Fury -- investigate dispatch bug | Human within 5 min |
| P1 | Wasp produces DESIGN.md that fails lint after self-validation claim | Loki catches at gate, REJECT | Spider-Man patches Wasp prompt |
| P2 | Wasp color choices fail WCAG AA contrast | Black Panther catches at a11y pass | Wasp revises |
| P3 | Wasp cannot find project context (no identity, no README) | Wasp uses judgment, logs decision | Sprint retro |
| P4 | Path D adds > 2 min to BLOCK 0F latency | Performance monitoring | Optimize in next sprint |

---

## 11. Do's and Don'ts

### Do's

1. DO read all available project context before authoring (identity,
   README, package.json, existing fragments) -- context prevents generic output
2. DO cite library examples as inspiration anchors ("taking Claude's
   warm-editorial tone + Stripe's numeric-clarity") -- this grounds the design
3. DO structurally self-validate output against the 9-section canonical
   list before handoff -- Nick Fury then runs `aegis-design-lint.sh --strict`
   to mechanically confirm; catching failures early saves a review round
4. DO (MUST) include precomputed contrast ratios inline in section 2 color
   definitions -- each color pair vs background MUST have a documented ratio
   with explicit WCAG AA pass/fail annotation (e.g., "#1A73E8 on #FFFFFF:
   4.6:1 -- AA PASS"). Black Panther verifies these ratios mechanically via
   `tools/aegis-contrast-check.sh`; omitting them blocks a11y review
5. DO fill every section with project-specific content, even if the brief
   is sparse -- use judgment and log the decision via `tools/aegis-log-decision.sh`
6. DO preserve the existing 3 init paths (A/B/C) unchanged -- Path D is
   additive, not replacing
7. DO use `DESIGN_APPROVAL_RESPONSE` (not `PLAN_APPROVAL_RESPONSE`) for
   the Loki design gate verdict -- distinct prefixes prevent log confusion
8. DO log Wasp dispatch to activity.log with
   `[HOOK:block0] task=<ID> 0F=custom-author-path dispatching=wasp`
9. DO handle the "no project context found" case gracefully -- Wasp falls
   back to a neutral professional design and documents the judgment call
10. DO include `prefers-reduced-motion` clause in section 8 if any
    animations are defined in section 4 or 6

### Don'ts

1. DON'T copy a library DESIGN.md verbatim and call it "custom" -- that
   is Paths A/B's job; Wasp must synthesize original content
2. DON'T skip the Loki Design-Approval Gate -- same enforcement as
   Plan-Approval Gate; no build without gate pass
3. DON'T skip the Black Panther a11y pass after Loki APPROVE -- contrast
   and typography checks are mandatory for any design contract
4. DON'T ask the human for design preferences mid-authoring -- use MBP
   `QUESTION_TO_BRAIN` if judgment is insufficient
5. DON'T use WebSearch for code lookups, API references, or non-design
   queries -- WebSearch is restricted to design inspiration and competitor research
6. DON'T modify library files (`.aegis/brain/design-library/`) -- these
   are immutable references protected by guard-write.sh
7. DON'T dispatch Wasp when `--from` or `--vibe` was explicitly provided
   -- respect user's explicit init path choice
8. DON'T let Wasp run Bash commands -- she has `disallowedTools: [Bash]`
   for the same security reason as Iron Man
9. DON'T produce DESIGN.md with base font size below 14px -- Black
   Panther will reject it at a11y pass (check 3)
10. DON'T let Wasp exceed 2 revision rounds with Loki -- after 2 rounds
    of CONDITIONAL, escalate to Nick Fury for manual intervention

---

## 12. Agent Prompt Guide

### 12.1 Spider-Man Prompt #1: Un-archive and Rewrite Wasp

```
You are Spider-Man. Un-archive Wasp and rewrite her agent prompt.

Steps:
1. Move .claude/agents/_archived/wasp.md to .claude/agents/wasp.md
2. Replace the entire file content with the new Wasp role defined in
   _aegis-output/specs/S3-06-spec.md section 2.

The new wasp.md must include:
- YAML frontmatter: name=wasp, model=claude-sonnet-4-6,
  tools=[Read,Write,Edit,Glob,Grep,WebSearch], disallowedTools=[Bash,Agent]
- Identity section (visual-design authority)
- Capabilities section (author DESIGN.md from brief)
- Constraints section (8 constraints per spec)
- Master Brain Protocol section (mandatory, same pattern as iron-man.md)
- Workflow section (9-step: receive -> scan -> decide -> author -> lint ->
  gate -> revise -> a11y -> publish)
- Power Keywords section (ultrathink for complex briefs)
- Message Types (DispatchDesignRequest, DesignApprovalResponse, etc.)
- References (design-system-md.md, design-library, lint tool)
- Output Location (DESIGN.md at project root)

Verify: grep -c "Master Brain Protocol" .claude/agents/wasp.md >= 1
Verify: test ! -f .claude/agents/_archived/wasp.md
```

### 12.2 Spider-Man Prompt #2: Update aegis-start.md BLOCK 0F Chain

```
You are Spider-Man. Update the BLOCK 0F chain in aegis-start.md.

Read: .claude/commands/aegis-start.md, find the BLOCK 0F section.

Add after the existing 0F description (do not replace it):

  "BLOCK 0F (extended S3-06):
   IF DESIGN.md missing AND no --from/--vibe flag AND UI paths detected:
     Nick Fury dispatches Wasp to author custom DESIGN.md from project brief.
     Wasp -> Loki Design-Approval Gate -> Black Panther a11y pass ->
     DESIGN.md published.
     0F re-checks after publish."

This is additive. The existing 0F check (lint existing, dispatch init if
missing) remains. The new branch fires only when no explicit init flag was
provided.
```

### 12.3 Spider-Man Prompt #3: Update Nick Fury BLOCK_0F_CHECK

```
You are Spider-Man. Update Nick Fury's BLOCK_0F_CHECK with the
custom-author branch.

Read: .claude/agents/nick-fury.md, find BLOCK_0F_CHECK.

Update step 3 and add step 4b per spec section 3.2:

  Step 3 (revised): IF DESIGN.md exists:
    Nick Fury runs: tools/aegis-design-lint.sh --strict --file DESIGN.md
    IF passes: 0F = PASS
    IF fails AND --from/--vibe provided: dispatch init with flag
    IF fails AND no flag: dispatch Wasp with existing file as partial
      input + lint diagnostics for revision

  Step 4b: Custom-author path (S3-06) -- DESIGN.md missing
  IF no --from/--vibe flag specified:
    Log: "[HOOK:block0] task=<ID> 0F=custom-author-path dispatching=wasp"
    Construct brief from project context:
      - .aegis/brain/resonance/project-identity.md
      - README.md description
      - package.json description + keywords
    Dispatch Wasp with DispatchDesignRequest.
    BLOCK until Wasp signals DESIGN.md published.
    Nick Fury runs: tools/aegis-design-lint.sh --strict --file DESIGN.md
    IF passes: 0F = PASS
    IF fails: 0F = FAIL (fall back to --blank)

  KEY: Nick Fury always runs lint -- Wasp is Bash-less and cannot execute
  shell tools. Wasp produces; Nick Fury validates.

The existing step 4 (dispatch aegis-design-init.sh when --from/--vibe IS
provided) remains as step 4a.
```

### 12.4 Spider-Man Prompt #4: Add Loki Design-Approval Gate

```
You are Spider-Man. Add the Design-Approval Gate to Loki's agent prompt.

Read: .claude/agents/loki.md, find the Plan-Approval Gate section.

Add a new ## section AFTER Plan-Approval Gate, BEFORE Message Types:

## Design-Approval Gate (S3-06)

Loki reviews DESIGN.md files authored by Wasp (Path D custom-author).
This gate does NOT fire on library copies (Paths A/B) or blank scaffolds
(Path C).

Criteria (7 checks):
1. 9-section structure present (lint --strict)
2. All sections have non-comment content (lint --strict)
3. Color system consistent (primary/secondary/neutrals defined, no
   contradictions between section 2 and sections 4/7)
4. Typography scale has >= 3 sizes AND >= 2 weights
5. At least 3 components described in section 4
6. Do's and Don'ts each have >= 5 items
7. Agent Prompt Guide has >= 2 builder prompts

Verdict format:
  DESIGN_APPROVAL_RESPONSE
  Task: DESIGN:<slug>
  Verdict: APPROVE | CONDITIONAL | REJECT
  Conditions: [...]
  Blockers: [...]
  Summary: [...]

Same revision rules: max 2 rounds of CONDITIONAL before escalation.
```

### 12.5 Spider-Man Prompt #5: Create Test Harness

```
You are Spider-Man. Create the Wasp generate test harness.

Path: tools/aegis-wasp-generate-test.sh

Build a bash test script with 6 test cases per spec section 6.2:
1. Valid DESIGN.md passes lint strict
2. Missing-section DESIGN.md fails lint
3. Empty-section DESIGN.md fails strict
4. Design-Approval verdict has DESIGN: prefix
5. Design-Approval verdict uses DESIGN_APPROVAL_RESPONSE
6. Brief sources scan finds project-identity.md

Plus 6 acceptance checks per spec section 6.3:
- AC-1: wasp.md has MBP section
- AC-2: nick-fury.md has custom-author branch
- AC-3: loki.md has Design-Approval Gate
- AC-4: loki.md has DESIGN: prefix
- AC-5: black-panther.md has PASS 7
- AC-6: wasp.md is NOT in _archived/

Pattern to follow: tools/aegis-design-lint-test.sh for test harness
structure, tools/aegis-block0f-gate-test.sh for gate testing pattern.

All tests must use temp directories (mktemp -d) and clean up on exit.
Exit 0 if all pass, exit 1 on first failure.
```

### 12.6 Spider-Man Prompt #6: Create Contrast-Check Helper

```
You are Spider-Man. Create the WCAG contrast-check helper.

Path: tools/aegis-contrast-check.sh

Build a bash script (~40 LOC + embedded Python for the math) that:
1. Accepts --file <DESIGN.md path> argument
2. Parses section 2 (Colors) for hex color pairs (format: "#RRGGBB on #RRGGBB")
3. Computes WCAG relative luminance + contrast ratio for each pair
4. Compares computed ratio against Wasp's inline claim (if present)
5. Outputs per-pair: hex1, hex2, computed_ratio, claimed_ratio, AA_pass/fail
6. Exits 0 if all pairs pass AA (4.5:1 normal text), exits 1 if any fail

Test cases (4 minimum):
- TC1: "#000000 on #FFFFFF" -> ratio 21:1 -> AA PASS
- TC2: "#777777 on #888888" -> ratio ~1.3:1 -> AA FAIL
- TC3: Valid DESIGN.md with all passing pairs -> exit 0
- TC4: DESIGN.md with one failing pair -> exit 1, output identifies pair

This is part of the original 5pt scope. BP invokes it during PASS 7
checks 1-2 for mechanical contrast verification.

Pattern: tools/aegis-design-lint.sh for argument parsing structure.
```

---

## Acceptance Criteria Summary

| # | Criterion | Verification Command | Expected |
|---|-----------|---------------------|----------|
| AC-1 | Un-archived Wasp has MBP section | `grep -c "Master Brain Protocol" .claude/agents/wasp.md` | >= 1 |
| AC-2 | Nick Fury has custom-author branch | `grep -c "custom-author" .claude/agents/nick-fury.md` | >= 1 |
| AC-3 | Loki has Design-Approval Gate | `grep -c "Design-Approval Gate" .claude/agents/loki.md` | >= 1 |
| AC-4 | Loki verdict prefix is DESIGN: | `grep -c "DESIGN:" .claude/agents/loki.md` | >= 1 |
| AC-5 | Black Panther has PASS 7 | `grep -c "PASS 7" .claude/agents/black-panther.md` | >= 1 |
| AC-6 | Wasp not in _archived/ | `test ! -f .claude/agents/_archived/wasp.md` | Exit 0 |
| AC-7 | Test harness passes | `bash tools/aegis-wasp-generate-test.sh` | Exit 0 |
| AC-8 | Paths A/B/C still work | `bash tools/aegis-design-init.sh --blank --output /tmp/test-design.md && bash tools/aegis-design-lint.sh --file /tmp/test-design.md` | Exit 0 |

---

*Spec produced by Iron Man. v1.1 -- Loki D-037 addressed 2026-04-23 by Iron Man cycle 8.*
*Save path: `_aegis-output/specs/S3-06-spec.md`*
*Story: 1 (5pt) -- 6 deliverables*
*Test cases: 6 pipeline tests + 6 acceptance checks + 4 contrast-check tests = 16 assertions*
