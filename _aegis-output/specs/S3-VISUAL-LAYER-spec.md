# S3 MEGA-SPEC: Visual Design Layer Integration

AEGIS becomes design-literate. Today, Iron Man specs borrow VoltAgent's
format discipline -- soul paragraphs, matrix tables, do's/don'ts, Agent Prompt
Guide -- but when Spider-Man touches a `.tsx` or `.css` file, he has no design
contract to build against. No DESIGN.md exists. No fetch tool exists. No gate
verifies visual consistency. This epic closes the gap: it seeds a curated
reference library, gives the team tooling to init and lint DESIGN.md files,
wires a BLOCK 0F check so UI tasks without a design contract are stopped before
work begins, and installs a PreToolUse hook so Spider-Man cannot edit UI code
without one. The experience should feel like adding a type system for
aesthetics -- invisible when present, impossible to ignore when absent.

---

## Table of Contents

1. [Epic Overview](#1-epic-overview)
2. [Story Breakdown](#2-story-breakdown)
3. [S3-01: Seed Design Library + Fetch Tool](#3-s3-01-seed-design-library--fetch-tool)
4. [S3-02: aegis-design-init Wizard + Linter](#4-s3-02-aegis-design-init-wizard--linter)
5. [S3-03: BLOCK 0F Integration](#5-s3-03-block-0f-integration)
6. [S3-04: Spider-Man Pre-UI-Edit Hook](#6-s3-04-spider-man-pre-ui-edit-hook)
7. [Architecture Decision Records](#7-architecture-decision-records)
8. [Non-Functional Requirements](#8-non-functional-requirements)
9. [Trust Zones and Data Access](#9-trust-zones-and-data-access)
10. [Severity and Escalation](#10-severity-and-escalation)
11. [Do's and Don'ts](#11-dos-and-donts)
12. [Stretch Stories (Appendix)](#12-stretch-stories-appendix)
13. [Agent Prompt Guide](#13-agent-prompt-guide)

---

## 1. Epic Overview

| Field | Value |
|-------|-------|
| Epic ID | S3-VISUAL-LAYER |
| Total Points | 11 (core) + stretch deferred |
| Sprint | S3 |
| Owner | Iron Man (spec), Spider-Man (build) |
| Reviewers | Loki (plan gate), Black Panther (code review) |
| Dependencies | S2-03/04 BLOCK 0 lite-mode (SHIPPED) |
| Upstream Source | [VoltAgent/awesome-design-md](https://github.com/VoltAgent/awesome-design-md) |

### Story / Points / Deliverables / Dependencies

| Story | Points | Deliverables | Dependencies |
|-------|--------|--------------|--------------|
| S3-01 Seed library + fetch tool | 3 | `.aegis/brain/design-library/` (10 files), `tools/aegis-design-fetch.sh`, library README | None (standalone) |
| S3-02 Init wizard + linter | 3 | `tools/aegis-design-init.sh`, `tools/aegis-design-lint.sh`, `tools/aegis-design-lint-test.sh` (8+ cases) | S3-01 (library must exist for vibe matching) |
| S3-03 BLOCK 0F integration | 3 | Nick Fury BLOCK_0_PROCEDURE update, Coulson mode table extension, Loki criterion, Black Panther sub-check, `tools/aegis-block0f-gate-test.sh` | S2-03 (BLOCK 0 shipped), S3-02 (lint tool for validation) |
| S3-04 Pre-UI-edit hook | 2 | `.claude/hooks/guard-ui-edit.sh`, profiles.json update, settings.json update, `tools/aegis-guard-ui-edit-test.sh` (6+ cases) | S3-03 (gate must be wired before hook enforces) |

---

## 2. Story Breakdown

### Execution Order

```
S3-01 (library + fetch)
  |
  v
S3-02 (init + lint)
  |
  v
S3-03 (BLOCK 0F gate)
  |
  v
S3-04 (PreToolUse hook)
```

Each story has a clear handoff artifact. No story may begin implementation
until its predecessor's test script passes green.

---

## 3. S3-01: Seed Design Library + Fetch Tool

### 3.1 Soul

A curated shelf of design systems, fetched once and cached locally. When an
agent needs to know "what does Stripe look like?", the answer is one file read
away -- no network, no guessing, no hallucination.

### 3.2 Deliverables

#### 3.2.1 Design Library Directory

**Path**: `.aegis/brain/design-library/`

**Structure**:
```
.aegis/brain/design-library/
  README.md                  # provenance, license, curation rationale
  claude/DESIGN.md           # AI/LLM -- warm terracotta, editorial
  vercel/DESIGN.md           # Dev tools -- black/white precision, Geist
  linear/DESIGN.md           # SaaS -- ultra-minimal, purple accent
  raycast/DESIGN.md          # Dev tools -- dark chrome, gradient accents
  stripe/DESIGN.md           # SaaS -- signature purple, weight-300
  cursor/DESIGN.md           # Dev tools -- dark IDE aesthetic
  replicate/DESIGN.md        # AI/LLM -- ML-native, documentation-heavy
  cohere/DESIGN.md           # AI/LLM -- enterprise AI, clean
  xai/DESIGN.md              # AI/LLM -- terminal monochrome, bold
  warp/DESIGN.md             # Terminal -- neon accents, dark canvas
```

**Curation Rationale** (10 files covering 5 aesthetic axes):

| Slug | Category | Aesthetic Axis | Why Included |
|------|----------|----------------|-------------|
| claude | AI/LLM | Warm + editorial | AEGIS's own model provider; reference anchor |
| vercel | Dev tools | Monochrome precision | Industry standard for dev-tool minimalism |
| linear | SaaS | Ultra-minimal | Best-in-class product design |
| raycast | Dev tools | Dark chrome + gradients | Power-user density without clutter |
| stripe | SaaS | Purple + elegant | Gold standard for developer-facing SaaS |
| cursor | Dev tools | IDE-native dark | Closest analogy to AEGIS's own UX context |
| replicate | AI/LLM | Documentation-first | ML tooling with heavy API surface |
| cohere | AI/LLM | Enterprise clean | Enterprise-grade AI product design |
| xai | AI/LLM | Bold monochrome | Terminal-forward, high-contrast |
| warp | Terminal | Neon + dark canvas | Modern terminal reimagined |

**Library README** (`README.md` in library root):
- State provenance: "Sourced from VoltAgent/awesome-design-md (MIT license)"
- Link to upstream: `https://github.com/VoltAgent/awesome-design-md`
- Explain curation criteria: cover AI/LLM, dev tools, SaaS, terminal, and
  a range from minimal to bold
- Note that files are snapshots; use `aegis-design-fetch.sh` for updates

#### 3.2.2 Fetch Tool

**Path**: `tools/aegis-design-fetch.sh`

**Interface**:
```bash
# Fetch a single DESIGN.md from upstream
tools/aegis-design-fetch.sh --project <slug>

# Fetch and save to custom location
tools/aegis-design-fetch.sh --project <slug> --output <path>

# List available projects in local library
tools/aegis-design-fetch.sh --list

# Validate a slug exists upstream before fetching
tools/aegis-design-fetch.sh --check <slug>

# Verify all 10 seeded library slugs are reachable upstream
tools/aegis-design-fetch.sh --verify-library
```

**Behavior**:
- Upstream URL pattern: `https://raw.githubusercontent.com/VoltAgent/awesome-design-md/main/design-md/<slug>/DESIGN.md`
- Default save location: `.aegis/brain/design-library/<slug>/DESIGN.md`
- On network failure: exit 1 with message "Fetch failed for <slug> -- check network or slug validity"
- On 404: exit 1 with message "DESIGN.md not found for <slug> -- verify slug at https://github.com/VoltAgent/awesome-design-md/tree/main/design-md"
- On success: exit 0, print path to saved file
- `--list` mode: reads local `.aegis/brain/design-library/` subdirs, prints slugs
- `--check` mode: HEAD request to upstream URL, exit 0 if 200, exit 1 if not
- `--verify-library` mode: iterates all 10 seeded slugs from the library
  directory, HEAD-checks each upstream URL, prints per-slug OK/STALE status
  to stdout, exits 0 if all OK, exits 1 if any stale (with actionable
  message: "STALE: <slug> -- upstream URL returned <HTTP code>. Re-fetch
  with --project <slug> or verify upstream repo structure.")

**Implementation constraints**:
- Use `curl -fsSL` for fetching (available on macOS + Linux)
- No external dependencies beyond curl
- Create parent directories with `mkdir -p`
- Set file permissions to 644

### 3.3 Test Script

**Path**: `tools/aegis-design-fetch-test.sh`

| # | Test Case | Input | Expected |
|---|-----------|-------|----------|
| 1 | List with seeded library | `--list` | Exit 0, output contains "claude", "stripe", at least 10 slugs |
| 2 | Check valid slug | `--check claude` | Exit 0 |
| 3 | Check invalid slug | `--check nonexistent-xyz-fake` | Exit 1 |
| 4 | Fetch to default location | `--project claude` (pre-clean target) | Exit 0, file exists at expected path, file size > 100 bytes |
| 5 | Fetch to custom output | `--project stripe --output /tmp/test-design.md` | Exit 0, file exists at /tmp/test-design.md |
| 6 | Fetch invalid slug | `--project nonexistent-xyz-fake` | Exit 1, stderr contains "not found" |
| 7 | Verify-library with stale slug | `--verify-library` (inject malformed slug "zzz-bad-slug" into library dir) | Exit 1, stdout contains "STALE" and actionable re-fetch message |

### 3.4 Acceptance Criteria

- [ ] `.aegis/brain/design-library/` contains exactly 10 subdirectories
- [ ] Each subdirectory contains a `DESIGN.md` file with >100 bytes
- [ ] `README.md` in library root mentions MIT license and VoltAgent provenance
- [ ] `tools/aegis-design-fetch.sh` passes all 7 test cases
- [ ] `tools/aegis-design-fetch.sh --list` outputs all 10 seeded slugs
- [ ] `tools/aegis-design-fetch.sh --verify-library` reports OK for all 10 seeded slugs

---

## 4. S3-02: aegis-design-init Wizard + Linter

### 4.1 Soul

Starting a UI task without DESIGN.md should feel like starting a TypeScript
project without tsconfig.json -- a conscious choice, not an accident. The init
wizard lowers the barrier to zero, and the linter ensures every DESIGN.md is
structurally sound before any agent trusts it.

### 4.2 Deliverables

#### 4.2.1 Init Wizard

**Path**: `tools/aegis-design-init.sh`

**Interface**:
```bash
# Init from library vibe keyword
tools/aegis-design-init.sh --vibe minimal       # matches: linear, vercel
tools/aegis-design-init.sh --vibe bold           # matches: xai, warp
tools/aegis-design-init.sh --vibe warm           # matches: claude, cohere
tools/aegis-design-init.sh --vibe dark           # matches: cursor, raycast, warp
tools/aegis-design-init.sh --vibe elegant        # matches: stripe, linear

# Init from specific library entry
tools/aegis-design-init.sh --from <slug>

# Init with blank template (9-section skeleton)
tools/aegis-design-init.sh --blank

# Output to non-default location
tools/aegis-design-init.sh --vibe minimal --output <path>
```

**Vibe-to-Library Mapping**:

| Vibe Keyword | Matched Slugs (priority order) | Selection Rule |
|--------------|-------------------------------|----------------|
| minimal | linear, vercel | First match (linear) |
| bold | xai, warp | First match (xai) |
| warm | claude, cohere | First match (claude) |
| dark | cursor, raycast, warp | First match (cursor) |
| elegant | stripe, linear | First match (stripe) |
| terminal | warp, xai | First match (warp) |
| enterprise | cohere, stripe | First match (cohere) |
| ai | claude, replicate, cohere | First match (claude) |

**Behavior**:
- Default output: `DESIGN.md` at project root (cwd)
- If DESIGN.md already exists at target: exit 1 with "DESIGN.md already exists -- use --output to write elsewhere or remove existing file"
- `--from <slug>`: copy `.aegis/brain/design-library/<slug>/DESIGN.md` to output
- `--vibe <keyword>`: resolve keyword via mapping table, then behave as `--from`
- `--blank`: emit the 9-section skeleton template (all sections present with TODO placeholders)
- On success: run `tools/aegis-design-lint.sh` against the output; if lint fails, warn but still exit 0 (library files should always pass; blank template intentionally has TODOs)
- Print "DESIGN.md created at <path> -- customize sections before building"
- The init wizard is NON-INTERACTIVE. All choices are determined by CLI
  flags (`--vibe`, `--from`, `--blank`). When invoked programmatically by
  Nick Fury without flags, Nick Fury selects the vibe based on project
  context (keywords in `project-identity.md`, `README.md`, or
  `package.json` "description" field) or defaults to `--blank` (empty
  9-section skeleton). No interactive prompts, no menus, no stdin reads.

**9-Section Skeleton** (for `--blank` mode):

```markdown
# DESIGN.md

## 1. Theme
<!-- TODO: Describe the overall visual atmosphere -->

## 2. Colors
<!-- TODO: Define color palette with semantic names -->

## 3. Typography
<!-- TODO: Define font families, sizes, weights -->

## 4. Components
<!-- TODO: Define component styles and states -->

## 5. Layout
<!-- TODO: Define spacing, grid, alignment -->

## 6. Depth
<!-- TODO: Define shadows, elevation, layering -->

## 7. Do's and Don'ts
<!-- TODO: Visual guardrails -->

## 8. Responsive
<!-- TODO: Breakpoints and adaptive behavior -->

## 9. Agent Prompt Guide
<!-- TODO: Copy-paste prompts for coding agents -->
```

#### 4.2.2 Linter

**Path**: `tools/aegis-design-lint.sh`

**Interface**:
```bash
# Lint DESIGN.md at project root
tools/aegis-design-lint.sh

# Lint specific file
tools/aegis-design-lint.sh --file <path>

# Lint with verbose output (show matched/missing sections)
tools/aegis-design-lint.sh --verbose

# Lint in strict mode (content-required -- each section must have
# at least 1 non-comment, non-empty content line after the ## header)
tools/aegis-design-lint.sh --strict
tools/aegis-design-lint.sh --strict --file <path>
```

**Lint Modes**:

| Mode | Flag | Section Check | Content Check | Use Case |
|------|------|--------------|---------------|----------|
| Default | (none) | 9 headers present + ordered | No | Init wizard blank template validation |
| Strict | `--strict` | 9 headers present + ordered | Each section has >=1 non-comment, non-empty line after header | BLOCK 0F gate, guard-ui-edit validation |

**9-Section Validation** (required sections, in order):

| # | Section Name | Required Header Pattern (case-insensitive) |
|---|-------------|-------------------------------------------|
| 1 | Theme | `## *Theme` or `## 1. Theme` or `## 1: Theme` |
| 2 | Colors | `## *Color` |
| 3 | Typography | `## *Typo` |
| 4 | Components | `## *Compon` |
| 5 | Layout | `## *Layout` |
| 6 | Depth | `## *Depth` |
| 7 | Do's and Don'ts | `## *Do` |
| 8 | Responsive | `## *Respon` |
| 9 | Agent Prompt Guide | `## *Agent` |

**Behavior**:
- Exit 0 on pass (all 9 sections present and in order)
- Exit 1 on fail, with specific diagnostic:
  - Missing section: `FAIL: Missing section "Typography" -- expected after "Colors"`
  - Out-of-order: `FAIL: Section "Layout" (line 45) appears before "Components" (line 62) -- sections must follow canonical order`
  - Empty file: `FAIL: DESIGN.md is empty`
  - File not found: `FAIL: DESIGN.md not found at <path>`
- Report line numbers for each detected section header
- `--verbose`: list all 9 sections with status (FOUND at line N / MISSING)
- `--strict`: after validating structure, scan each section's body (lines
  between its header and the next `## ` header or EOF). A content line is
  any line that is not blank and does not start with `<!--`. If any section
  has zero content lines: exit 1 with
  `FAIL (strict): Section "Theme" has no content -- only comments/blanks`

**Implementation constraints**:
- Pure bash + grep/awk -- no external linting frameworks
- Case-insensitive matching on section headers
- Detect sections by scanning for `^## ` lines and matching against patterns
- Track last-seen section index to validate order

### 4.3 Test Script

**Path**: `tools/aegis-design-lint-test.sh`

| # | Test Case | Setup | Expected |
|---|-----------|-------|----------|
| 1 | Happy path -- all 9 sections in order | Valid DESIGN.md from library | Exit 0 |
| 2 | Missing Theme section | DESIGN.md without Theme header | Exit 1, output contains "Missing section" and "Theme" |
| 3 | Missing Colors section | DESIGN.md without Colors header | Exit 1, output contains "Missing section" and "Color" |
| 4 | Missing Typography section | DESIGN.md without Typography | Exit 1, output contains "Missing section" and "Typo" |
| 5 | Missing Components section | DESIGN.md without Components | Exit 1, output contains "Missing section" and "Compon" |
| 6 | Missing Responsive section | DESIGN.md without Responsive | Exit 1, output contains "Missing section" and "Respon" |
| 7 | Missing Agent Prompt Guide | DESIGN.md without Agent section | Exit 1, output contains "Missing section" and "Agent" |
| 8 | Out-of-order sections | Layout before Components | Exit 1, output contains "appears before" |
| 9 | Empty file | 0-byte DESIGN.md | Exit 1, output contains "empty" |
| 10 | File not found | No DESIGN.md at given path | Exit 1, output contains "not found" |
| 11 | Blank template passes | Output from `--blank` init | Exit 0 (TODOs are allowed; structure matters) |
| 12 | Case-insensitive match | Headers like "## THEME", "## colors" | Exit 0 |

### 4.4 Acceptance Criteria

- [ ] `tools/aegis-design-init.sh --blank` emits a file with all 9 sections
- [ ] `tools/aegis-design-init.sh --vibe minimal` produces a valid DESIGN.md (lint passes)
- [ ] `tools/aegis-design-init.sh --from stripe` copies Stripe's DESIGN.md to project root
- [ ] `tools/aegis-design-lint.sh` passes on all 10 seeded library files
- [ ] `tools/aegis-design-lint-test.sh` has 12 test cases, all green
- [ ] Init refuses to overwrite existing DESIGN.md (exit 1)

---

## 5. S3-03: BLOCK 0F Integration

### 5.1 Soul

When a task touches UI code, the system must pause and ask: "do you have a
design contract?" Not as a nagging popup, but as an architectural gate -- the
same way BLOCK 0B demands a requirements spec. If DESIGN.md is missing, the
task cannot proceed. If present, every downstream agent knows exactly what
visual language to speak.

### 5.2 BLOCK 0 Mode Table (Extended with 0F)

This extends the existing BLOCK 0 mode table from S2-03. Check 0F is
conditional: it only activates when a task's file paths intersect UI patterns.

**BLOCK 0 Check / Mode: Full / Standard / Lite**

| Check | Artifact | Full | Standard | Lite |
|-------|----------|------|----------|------|
| 0A | PM.01 Project Plan | require | require | skip |
| 0B | SI.01 Requirements Spec | require | require | skip |
| 0C | Epic/Task/Sub-task hierarchy | require | require | require |
| 0D | Kanban board with tickets | require | require | require |
| 0E | SI.02 Traceability Matrix | require | skip | skip |
| **0F** | **DESIGN.md at project root** | **conditional** | **conditional** | **conditional** |

**0F Condition**: activated when task touches UI paths AND task is P3 or higher.

**UI Path Detection Patterns**:

| Pattern | Type | Match | Rule |
|---------|------|-------|------|
| `src/components/**` | Directory | `src/components/Button.tsx` | INCLUDE |
| `src/pages/**` | Directory | `src/pages/Dashboard.vue` | INCLUDE |
| `*.tsx` | Extension | `app/layout.tsx` | INCLUDE |
| `*.jsx` | Extension | `components/Card.jsx` | INCLUDE |
| `*.css` | Extension | `styles/global.css` | INCLUDE |
| `*.scss` | Extension | `styles/theme.scss` | INCLUDE |
| `*.vue` | Extension | `views/Home.vue` | INCLUDE |
| `*.svelte` | Extension | `routes/+page.svelte` | INCLUDE |
| `src/styles/**` | Directory | `src/styles/tokens.css` | INCLUDE |
| `src/ui/**` | Directory | `src/ui/primitives/Box.tsx` | INCLUDE |
| `*.test.{tsx,jsx,css,scss}` | Extension | `Button.test.tsx` | EXCLUDE |
| `*.spec.{tsx,jsx}` | Extension | `Card.spec.jsx` | EXCLUDE |
| `*.stories.{tsx,jsx}` | Extension | `Button.stories.tsx` | EXCLUDE |
| `*.config.{tsx,js,ts}` | Extension | `tailwind.config.ts` | EXCLUDE |
| `**/__tests__/**` | Directory | `__tests__/Button.tsx` | EXCLUDE |
| `**/__mocks__/**` | Directory | `__mocks__/style.css` | EXCLUDE |
| `**/setupTests.*` | File | `setupTests.ts` | EXCLUDE |

**Evaluation order**: EXCLUDE patterns are checked FIRST. If any EXCLUDE
pattern matches, the file is classified as non-UI regardless of INCLUDE
matches. This is fail-safe: test/story/config files never trigger the gate.

**0F Decision Procedure** (added to Nick Fury's BLOCK_0_PROCEDURE):

```
BLOCK_0F_CHECK(task):
  1. Collect task file paths from:
     - PR changed-file list (if PR exists)
     - Task description file mentions
     - meta.json "files" field (if present)

  2. For each file path, check EXCLUDE patterns first:
     IF path matches any EXCLUDE pattern (*.test.*, *.spec.*, *.stories.*,
       *.config.*, __tests__/**, __mocks__/**, setupTests.*): remove from list
     Match remaining paths against INCLUDE UI_PATH_PATTERNS
     IF no matches: 0F = NOT_APPLICABLE, skip
     IF matches found AND task priority < P3: 0F = NOT_APPLICABLE, skip

  3. Check for DESIGN.md:
     IF file exists at project root (DESIGN.md):
       Run tools/aegis-design-lint.sh --strict
       IF lint passes: 0F = PASS
       IF lint fails: 0F = FAIL, reason = "DESIGN.md exists but fails strict lint"
     ELSE:
       0F = FAIL, reason = "DESIGN.md required for UI task -- run tools/aegis-design-init.sh"

  4. Log result:
     Append to activity.log:
       "[HOOK:block0] task=<ID> check=0F result=<PASS|FAIL|NOT_APPLICABLE> files=<matched-count>"
```

### 5.3 Agent Integration Points

#### 5.3.1 Nick Fury -- BLOCK_0_PROCEDURE Extension

Add check 0F after existing checks 0A-0E in the BLOCK_0_PROCEDURE. The check
is conditional (unlike 0A-0E which are mode-determined), so it runs in all
modes but only activates when UI paths are detected.

**Location**: `.claude/agents/nick-fury.md`, BLOCK 0 section, after check 0E

**Addition**: the 0F decision procedure above, plus a skip-log for non-UI tasks

#### 5.3.2 Coulson -- Mode-Aware Table Extension

Add 0F row to Coulson's existing mode table (coulson.md, BLOCK 0 section).

**Existing table** (checks 0A-0E):

| Check | Document | Full | Standard | Lite |
|-------|----------|------|----------|------|
| 0A | PM.01 | yes | yes | skip |
| 0B | SI.01 | yes | yes | skip |
| 0C | tasks | yes | yes | yes |
| 0D | kanban | yes | yes | yes |
| 0E | SI.02 | yes | skip | skip |

**Extended with 0F**:

| Check | Document | Full | Standard | Lite |
|-------|----------|------|----------|------|
| 0F | DESIGN.md | conditional | conditional | conditional |

Coulson does NOT generate DESIGN.md (unlike other checks where Coulson
generates missing docs). Coulson only verifies presence and lint status.
If 0F fails, Coulson reports to Nick Fury who surfaces the init tool.

#### 5.3.3 Loki -- Review Criterion

Add to Loki's review checklist (loki.md):

> "Any spec claiming UI work (stories that modify `*.tsx`, `*.jsx`, `*.css`,
> `*.scss`, `*.vue`, `*.svelte`, or paths under `src/components/`,
> `src/pages/`, `src/styles/`, `src/ui/`) MUST cite specific DESIGN.md
> sections by name (e.g., 'per DESIGN.md section 2 Colors, use `--primary`
> token'). A spec that mentions UI work without citing DESIGN.md sections
> receives an automatic finding: 'S-DESIGN: UI spec without design contract
> reference.'"

#### 5.3.4 Black Panther -- Visual Conformance Sub-Check

Add "Visual Conformance" as a sub-check in Black Panther's 5-pass review
(black-panther.md):

**Pass 6 (new): Visual Conformance** (conditional -- only runs if DESIGN.md
exists and task touches UI paths):

```
VISUAL_CONFORMANCE_CHECK:
  1. Read DESIGN.md sections: Colors, Typography, Components, Layout
  2. For each changed UI file in the PR:
     a. Verify color values reference DESIGN.md tokens (not hardcoded hex)
     b. Verify font-family/size/weight match Typography section
     c. Verify component structure matches Components section patterns
     d. Verify spacing/grid usage matches Layout section
  3. Report findings:
     - CONFORMANT: "Component uses design tokens correctly"
     - DEVIATION: "Button uses #3b82f6 instead of DESIGN.md --primary token"
     - UNLISTED: "Component <X> not defined in DESIGN.md -- add or justify"
```

### 5.4 Test Script

**Path**: `tools/aegis-block0f-gate-test.sh`

| # | Test Case | Setup | Expected |
|---|-----------|-------|----------|
| 1 | UI task without DESIGN.md | meta.json with `files: ["src/components/Button.tsx"]`, no DESIGN.md | 0F = FAIL |
| 2 | UI task with valid DESIGN.md | meta.json with UI files, valid DESIGN.md at root | 0F = PASS |
| 3 | UI task with malformed DESIGN.md | meta.json with UI files, DESIGN.md missing sections | 0F = FAIL |
| 4 | Non-UI task | meta.json with `files: ["src/utils/math.ts"]` | 0F = NOT_APPLICABLE |
| 5 | Mixed files (UI + non-UI) | meta.json with `files: ["src/utils/math.ts", "src/components/Card.tsx"]` | 0F triggers (any UI file activates) |
| 6 | Low-priority UI task (P4+) | meta.json with UI files, priority P4 | 0F = NOT_APPLICABLE (below P3 threshold) |
| 7 | P3 UI task with DESIGN.md | meta.json with UI files, priority P3, valid DESIGN.md | 0F = PASS |
| 8 | CSS-only change | meta.json with `files: ["styles/theme.css"]` | 0F triggers |

### 5.5 Acceptance Criteria

- [ ] Nick Fury BLOCK_0_PROCEDURE includes 0F check after 0E
- [ ] Coulson mode table has 0F row with "conditional" in all three modes
- [ ] Loki review criterion documented for UI-spec-without-DESIGN.md finding
- [ ] Black Panther Visual Conformance pass documented
- [ ] `tools/aegis-block0f-gate-test.sh` has 8 test cases, all green
- [ ] Non-UI tasks are never blocked by 0F (regression test: case 4)
- [ ] Activity log receives 0F check results

---

## 6. S3-04: Spider-Man Pre-UI-Edit Hook

### 6.1 Soul

The last line of defense. Even if BLOCK 0F was somehow bypassed (lite mode,
manual override, agent bug), Spider-Man's hands are physically stopped from
editing UI files without DESIGN.md present. Like a compiler error, not a
warning -- the edit does not proceed.

### 6.2 Deliverables

#### 6.2.1 Guard Hook

**Path**: `.claude/hooks/guard-ui-edit.sh`

**Hook Type**: PreToolUse

**Matcher**: `Edit|Write|MultiEdit`

**Input Schema** (JSON on stdin):
```json
{
  "tool_name": "Edit",
  "tool_input": {
    "file_path": "src/components/Button.tsx",
    "old_string": "...",
    "new_string": "..."
  }
}
```

**Decision Logic**:

```
guard-ui-edit(input):
  1. Parse tool_name and file_path from stdin JSON

  2. IF tool_name not in [Edit, Write, MultiEdit]: exit 0 (allow)

  3. Check EXCLUDE patterns first (fail-safe -- if exclusion matches, skip gate):
     EXCLUDE (regex, any match = exit 0 immediately):
       \.(test|spec|stories)\.(tsx|jsx|css|scss)$
       \.config\.(tsx|js|ts)$
       (^|/)__tests__/
       (^|/)__mocks__/
       (^|/)setupTests\.

     IF file_path does not match INCLUDE UI patterns: exit 0 (allow)
     INCLUDE UI patterns (regex):
       \.(tsx|jsx|css|scss|vue|svelte)$
       (^|/)src/components/
       (^|/)src/pages/
       (^|/)src/styles/
       (^|/)src/ui/

  4. IF DESIGN.md exists at project root: exit 0 (allow)

  5. BLOCK:
     Output: {"decision":"block","reason":"DESIGN.md required before UI code -- run tools/aegis-design-init.sh first"}
     Exit 2
```

**Implementation constraints**:
- Follow `guard-write.sh` pattern exactly (stdin JSON parsing via python3)
- Exit 0 = allow (hook passes through)
- Exit 2 = block (with JSON reason on stdout)
- No side effects (no file writes, no logging -- that is post-tool-use's job)
- Must work when called via `run-with-flags.sh` wrapper

#### 6.2.2 Profile Registration

**File**: `.claude/hooks/profiles.json`

Add `guard-ui-edit` to `standard` and `strict` profiles:

| Profile | guard-ui-edit Included |
|---------|----------------------|
| minimal | no |
| standard | yes |
| strict | yes |

Updated profiles.json entries:

```json
{
  "standard": [
    "guard-bash",
    "guard-write",
    "guard-ui-edit",
    "guard-ask-user",
    "post-tool-use",
    "post-edit-accumulate",
    "on-stop"
  ],
  "strict": [
    "guard-bash",
    "guard-write",
    "guard-ui-edit",
    "guard-ask-user",
    "post-tool-use",
    "post-edit-accumulate",
    "on-stop",
    "tinman-heartbeat"
  ]
}
```

#### 6.2.3 Settings.json Registration

Add a new PreToolUse entry to `.claude/settings.json`:

```json
{
  "matcher": "Edit|Write|MultiEdit",
  "hooks": [
    {
      "type": "command",
      "command": "bash .claude/hooks/run-with-flags.sh guard-ui-edit .claude/hooks/guard-ui-edit.sh"
    }
  ]
}
```

**Ordering note**: this entry must appear AFTER the existing `guard-write`
matcher for `Edit|Write|MultiEdit`. Both hooks fire on the same matcher;
`guard-write` protects config files, `guard-ui-edit` protects UI files.
They are independent checks -- if either blocks, the edit is blocked.

### 6.3 Test Script

**Path**: `tools/aegis-guard-ui-edit-test.sh`

**Hook / Trigger Pattern / Block Reason / Escape Hatch**

| Hook | Trigger Pattern | Block Reason | Escape Hatch |
|------|----------------|--------------|--------------|
| guard-ui-edit | Edit on `*.tsx` without DESIGN.md | "DESIGN.md required before UI code" | Create DESIGN.md via `aegis-design-init.sh` |
| guard-ui-edit | Write on `*.css` without DESIGN.md | "DESIGN.md required before UI code" | Create DESIGN.md via `aegis-design-init.sh` |
| guard-ui-edit | Edit on `*.tsx` WITH DESIGN.md | (not blocked) | N/A |
| guard-ui-edit | Edit on `*.ts` (non-UI) | (not blocked) | N/A |
| guard-write | Edit on `.eslintrc` | "Protected config file" | AEGIS_MAINTAINER_MODE |
| guard-ui-edit | Edit on `src/components/X.tsx` without DESIGN.md | "DESIGN.md required before UI code" | Create DESIGN.md |

Test cases:

| # | Test Case | Input JSON | DESIGN.md Present | Expected |
|---|-----------|-----------|-------------------|----------|
| 1 | Block .tsx edit without DESIGN.md | `{"tool_name":"Edit","tool_input":{"file_path":"src/components/Button.tsx"}}` | no | Exit 2, output contains "DESIGN.md required" |
| 2 | Block .css write without DESIGN.md | `{"tool_name":"Write","tool_input":{"file_path":"styles/main.css"}}` | no | Exit 2 |
| 3 | Block .vue edit without DESIGN.md | `{"tool_name":"Edit","tool_input":{"file_path":"views/Home.vue"}}` | no | Exit 2 |
| 4 | Allow .tsx edit with DESIGN.md | `{"tool_name":"Edit","tool_input":{"file_path":"src/components/Button.tsx"}}` | yes | Exit 0 |
| 5 | Allow .ts edit (non-UI) | `{"tool_name":"Edit","tool_input":{"file_path":"src/utils/math.ts"}}` | no | Exit 0 |
| 6 | Allow .json edit (non-UI) | `{"tool_name":"Edit","tool_input":{"file_path":"config/settings.json"}}` | no | Exit 0 |
| 7 | Block .svelte edit without DESIGN.md | `{"tool_name":"Edit","tool_input":{"file_path":"routes/+page.svelte"}}` | no | Exit 2 |
| 8 | Allow Bash tool (non-write) | `{"tool_name":"Bash","tool_input":{"command":"ls"}}` | no | Exit 0 |

### 6.4 Acceptance Criteria

- [ ] `.claude/hooks/guard-ui-edit.sh` exists and is executable
- [ ] Hook blocks UI file edits when DESIGN.md is absent (exit 2 + JSON reason)
- [ ] Hook allows UI file edits when DESIGN.md is present (exit 0)
- [ ] Hook allows non-UI file edits regardless of DESIGN.md (exit 0)
- [ ] Hook registered in profiles.json under standard + strict
- [ ] Hook registered in settings.json with `run-with-flags.sh` wrapper
- [ ] `tools/aegis-guard-ui-edit-test.sh` has 8 test cases, all green
- [ ] Hook does not interfere with guard-write (both can fire on same matcher)

---

## 7. Architecture Decision Records

### ADR-S3-01: Library Size -- 10 Files, Not All 55+

**Status**: Accepted

**Context**: VoltAgent/awesome-design-md contains 55+ DESIGN.md files. Seeding
all of them into the local library would add bulk without proportional value.

**Decision**: Seed 10 curated files covering 5 aesthetic axes.

**Rationale**:
- 10 files = enough diversity for vibe matching without noise
- Each axis (AI, dev tools, SaaS, terminal, bold) has 2+ representatives
- The fetch tool provides on-demand access to all 55+ when needed
- Library README documents the curation criteria for future additions

**Consequences**: Users who want Figma, Notion, or Spotify must use the fetch
tool. This is intentional -- the library is a curated starting point.

### ADR-S3-02: 0F as Conditional Check, Not Mode-Gated

**Status**: Accepted

**Context**: Existing BLOCK 0 checks (0A-0E) are mode-gated (some skip in
lite/standard). Should 0F follow the same pattern?

**Decision**: 0F is conditional on UI path detection, not on mode.

**Rationale**:
- A 1pt task tagged `chore` that touches `Button.tsx` still needs design
  guidance -- skipping 0F in lite mode would be a security-class bypass
- Conversely, a 5pt feature that only touches backend code should never
  trigger 0F regardless of mode
- Condition = "task touches UI paths AND priority >= P3" is more precise
  than mode gating
- Aligns with S2-04's principle: detect what the task actually does, not
  just what it claims to be

**Consequences**: 0F may fire even in lite mode if UI paths are touched.
This is stricter than 0A-0E but correctly reflects the risk.

### ADR-S3-03: Hook Placement -- New Hook vs Extending guard-write

**Status**: Accepted

**Context**: The UI edit guard could be added as a new case inside the existing
`guard-write.sh` or as a separate hook script.

**Decision**: Separate hook (`guard-ui-edit.sh`).

**Rationale**:
- Separation of concerns: guard-write protects config files from weakening;
  guard-ui-edit enforces design contract presence
- Independent enable/disable via profiles.json (a project without UI never
  needs guard-ui-edit)
- guard-write already has 100+ lines with maintainer-mode logic; adding
  UI pattern matching would exceed single-responsibility
- Both hooks fire on the same matcher -- Claude Code hooks pipeline
  supports multiple hooks per matcher

**Consequences**: Two hooks fire on `Edit|Write|MultiEdit`. Both must pass
for the edit to proceed. Marginal latency increase (~10ms per edit) is
acceptable.

---

## 8. Non-Functional Requirements

### Performance
- Library seeding: one-time operation, <30s total for 10 curl fetches
- Lint tool: <500ms for a 500-line DESIGN.md (pure bash text scanning)
- Guard hook: <50ms per invocation (single file-existence check)
- Init wizard: <2s including lint validation pass

### Security
- Fetch tool uses HTTPS only (no HTTP fallback)
- Library files are immutable references, enforced by `guard-write.sh`:
  `.aegis/brain/design-library/` is added to AEGIS_PATTERNS protected paths.
  Any agent Edit/Write to a library file is BLOCKED (exit 2). Maintainer-mode
  override (ADR-004) still works for legitimate library updates by the human.
- Hook does not log file contents, only paths and decisions
- No secrets or credentials involved in any S3 tool

**guard-write.sh change** (Category 5 AEGIS_PATTERNS extension):
```bash
AEGIS_PATTERNS=(
    ".claude/settings.json"
    ".claude/settings.local.json"
    ".aegis/brain/design-library/"    # S3: library immutability
)
```

**Test case** (in `tools/aegis-guard-write-test.sh`, create if missing):

| # | Test Case | Input | Expected |
|---|-----------|-------|----------|
| N+1 | Block library file edit | `{"tool_name":"Edit","tool_input":{"file_path":".aegis/brain/design-library/stripe/DESIGN.md"}}` | Exit 2, output contains "AEGIS Self-Protection" |
| N+2 | Allow library file edit in maintainer mode | Same input, `AEGIS_MAINTAINER_MODE=1` | Exit 0 (per ADR-004) |

### Accessibility
- All tool output is plain text, compatible with screen readers
- Error messages include actionable next steps (not just "failed")
- Lint output includes line numbers for editor navigation

### Portability
- All tools use POSIX-compatible bash (tested on macOS zsh + Linux bash)
- Only external dependency: `curl` (for fetch tool network operations)
- Python3 used only for JSON parsing in hooks (matches existing AEGIS pattern)

---

## 9. Trust Zones and Data Access

| Zone | Auth | Data Access | S3 Relevance |
|------|------|-------------|-------------|
| public | none | read-only upstream repo | `aegis-design-fetch.sh` reads from GitHub |
| project | filesystem | read/write `.aegis/brain/design-library/` | Library seeding + fetch tool writes |
| project | filesystem | read-only `DESIGN.md` at root | Lint tool + guard hook reads |
| agent | prompt-level | read agent prompt references | Nick Fury, Coulson, Loki, Black Panther read 0F spec |
| hook | PreToolUse | read stdin JSON + check file existence | guard-ui-edit decision logic |

---

## 10. Severity and Escalation

| Severity | Trigger | Handler | Escalation |
|----------|---------|---------|------------|
| P0 | guard-ui-edit crashes (non-zero non-2 exit) | Thor -- investigate hook failure | Nick Fury within 5 min |
| P1 | 0F gate produces false negatives (UI task proceeds without DESIGN.md) | Black Panther catches in review | Nick Fury logs bug, Spider-Man patches |
| P2 | Lint tool rejects valid DESIGN.md (false positive) | Spider-Man fixes lint regex | Sprint retro |
| P3 | Fetch tool 404 on valid upstream slug (URL structure changed) | Beast investigates upstream | Spider-Man updates URL pattern |
| P4 | Library file outdated vs upstream | Manual re-fetch when noticed | No escalation needed |

---

## 11. Do's and Don'ts

### Do's

1. DO seed library files as exact copies from upstream -- no modifications to
   content (preserve provenance)
2. DO run `aegis-design-lint.sh` on every DESIGN.md before trusting it in a
   spec or review (agents and humans alike)
3. DO cite specific DESIGN.md section names in specs that touch UI (e.g.,
   "per section 2 Colors, use `--primary` token")
4. DO treat guard-ui-edit as a hard gate -- if it blocks, create DESIGN.md
   first, then retry the edit
5. DO use `--vibe` keywords for quick init when starting a new UI project --
   refine the DESIGN.md afterward
6. DO log all 0F check results to activity.log, including NOT_APPLICABLE
   (auditability over brevity)
7. DO test every library DESIGN.md against the linter after seeding (catch
   upstream format drift early)
8. DO keep the fetch tool's URL pattern in a single variable at the top of
   the script (easy to update if upstream restructures)
9. DO register guard-ui-edit in profiles.json before settings.json (profile
   membership is checked first by run-with-flags.sh)
10. DO treat the blank template's TODO comments as valid lint targets -- the
    linter checks structure, not content completeness

### Don'ts

1. DON'T modify library DESIGN.md files in place -- copy to project root and
   customize there (library = reference shelf, not working copy)
2. DON'T skip 0F for lite-mode tasks that touch UI paths -- the condition is
   path-based, not mode-based (per ADR-S3-02)
3. DON'T add guard-ui-edit to the `minimal` profile -- minimal is for
   emergency debugging where all non-security hooks are stripped
4. DON'T hardcode the upstream URL in multiple places -- single source of
   truth in `aegis-design-fetch.sh`, other tools reference the library
5. DON'T let Coulson generate DESIGN.md -- unlike SI.01/PM.01, design systems
   require human or Iron Man authorship, not boilerplate generation
6. DON'T block non-write tools (Bash, Read, Grep) on UI file patterns --
   guard-ui-edit only fires on Edit/Write/MultiEdit
7. DON'T treat lint warnings as lint failures -- the linter has exactly two
   outcomes: pass (exit 0) or fail (exit 1), no warning tier
8. DON'T assume all upstream DESIGN.md files follow the 9-section structure --
   the linter validates this; some upstream files may fail lint and that
   is acceptable (they are still useful as references)
9. DON'T bypass guard-ui-edit via AEGIS_MAINTAINER_MODE -- that escape hatch
   is for guard-write config protection only; DESIGN.md creation is fast
10. DON'T add DESIGN.md to .gitignore -- it is a project artifact that belongs
    in version control alongside code
11. DON'T ask the user interactively for vibe preference via AskUserQuestion
    or option menus -- Nick Fury selects based on project context (keywords
    in project-identity.md, README, or package.json "description" field) or
    defaults to `--blank` (empty 9-section skeleton). The `--vibe` CLI flag
    is ONLY for explicit human override via terminal.

---

## 12. Stretch Stories (Appendix)

These stories are explicitly OUT of the S3 sprint. They are documented here
for backlog continuity and to prevent scope creep during implementation.

### S3-05: Wasp Revival as DESIGN.md Owner (Deferred)

**Rationale for deferral**: Wasp was retired in v9-06 because UX tasks were
~5% of AEGIS workload. Reviving Wasp requires a persistent UX workload to
justify the agent slot. If AEGIS-HQ or a downstream project generates
sustained UI work, revisit.

**When to activate**: 3+ consecutive sprints with >20% UI tasks.

**Scope sketch**: Un-archive wasp.md, assign DESIGN.md ownership, add Wasp to
BLOCK 0F as the generator (replacing the "Coulson does not generate" rule),
update agent table to 11 agents.

### S3-06: DESIGN.md to Tailwind Tokens Pipeline (Deferred)

**Rationale for deferral**: Requires a real Tailwind project to test against.
AEGIS meta-repo has no UI code.

**Scope sketch**: `tools/aegis-design-to-tokens.sh` reads DESIGN.md Colors +
Typography sections, emits `tailwind.config.ts` theme extensions. Spider-Man
uses generated config instead of manual token mapping.

### S3-07: AEGIS-HQ DESIGN.md Submitted Upstream (Deferred)

**Rationale for deferral**: AEGIS-HQ does not yet have a DESIGN.md. Creating
one is a prerequisite. Submitting upstream is a PR to VoltAgent/awesome-design-md.

**Scope sketch**: Create AEGIS-HQ DESIGN.md (dark terminal aesthetic, emerald
accent, monospace-first), submit PR to upstream repo, add to local library.

---

## 13. Agent Prompt Guide

Copy-paste prompts for downstream agents. Each prompt is self-contained and
includes the context needed to execute without re-reading this spec.

### 13.1 Iron Man -- Per-Story Spec Refinement

```
You are Iron Man. Refine the implementation spec for S3-01 (Seed Design
Library + Fetch Tool).

Context: S3-VISUAL-LAYER-spec.md section 3 defines the deliverables. Your
job is to produce the implementation-level detail Spider-Man needs:
- Exact curl command with error handling for aegis-design-fetch.sh
- Library README template with provenance text
- Directory structure with mkdir commands
- Test script skeleton for aegis-design-fetch-test.sh

Constraints: bash only, no npm/pip dependencies, follow existing tool
patterns in tools/aegis-*.sh. File must be executable (chmod +x).

Output: refined implementation notes saved to
_aegis-output/specs/S3-01-impl-notes.md
```

### 13.2 Spider-Man -- Seed Library + Build Tools

```
You are Spider-Man. Implement S3-01 and S3-02 from the Visual Design Layer
epic.

Read: _aegis-output/specs/S3-VISUAL-LAYER-spec.md sections 3 and 4.

S3-01 deliverables:
1. Seed .aegis/brain/design-library/ with 10 DESIGN.md files from upstream
   URL: https://raw.githubusercontent.com/VoltAgent/awesome-design-md/main/design-md/<slug>/DESIGN.md
   Slugs: claude, vercel, linear, raycast, stripe, cursor, replicate, cohere, xai, warp
2. Create library README.md with MIT license provenance
3. Build tools/aegis-design-fetch.sh (--project, --list, --check, --output)
4. Build tools/aegis-design-fetch-test.sh (6 test cases)

S3-02 deliverables:
1. Build tools/aegis-design-init.sh (--vibe, --from, --blank, --output)
2. Build tools/aegis-design-lint.sh (9-section validation, exit codes)
3. Build tools/aegis-design-lint-test.sh (12 test cases)

Pattern to follow: tools/aegis-block0-mode.sh for tool structure,
tools/aegis-block0-mode-test.sh for test harness pattern.

Run all test scripts after building. Commit only if green.
```

### 13.3 Spider-Man -- Pre-UI-Edit Hook

```
You are Spider-Man. Implement S3-04 from the Visual Design Layer epic.

Read: _aegis-output/specs/S3-VISUAL-LAYER-spec.md section 6.

Deliverables:
1. Create .claude/hooks/guard-ui-edit.sh (PreToolUse hook)
   - Pattern: follow .claude/hooks/guard-write.sh structure exactly
   - Match: Edit|Write|MultiEdit on UI file extensions (.tsx, .jsx, .css,
     .scss, .vue, .svelte) and UI directories (src/components/, src/pages/,
     src/styles/, src/ui/)
   - EXCLUDE before INCLUDE: skip gate for *.test.*, *.spec.*, *.stories.*,
     *.config.*, __tests__/**, __mocks__/**, setupTests.*
   - Block (exit 2 + JSON) if DESIGN.md missing at project root
   - Allow (exit 0) if DESIGN.md present or file is non-UI
   - When validating DESIGN.md presence, use `aegis-design-lint.sh --strict`
     to ensure sections have real content (not just comment placeholders)

2. Register in .claude/hooks/profiles.json: add "guard-ui-edit" to
   standard and strict arrays

3. Register in .claude/settings.json: add PreToolUse entry with
   run-with-flags.sh wrapper, AFTER existing guard-write entry

4. Build tools/aegis-guard-ui-edit-test.sh (8 test cases per spec)

Run test script after building. Commit only if green.
```

### 13.4 Coulson -- BLOCK 0F Table Update

```
You are Coulson. Update the BLOCK 0 mode-aware generation table to include
check 0F (DESIGN.md).

Read: _aegis-output/specs/S3-VISUAL-LAYER-spec.md section 5.3.2.

Changes to .claude/agents/coulson.md:
1. Add row to the BLOCK 0 mode table:
   | 0F | DESIGN.md | conditional | conditional | conditional |
2. Add note: "0F is conditional -- only activated when task file paths
   match UI patterns (*.tsx, *.jsx, *.css, *.scss, *.vue, *.svelte,
   src/components/, src/pages/). Coulson does NOT generate DESIGN.md;
   only verifies presence and lint status via tools/aegis-design-lint.sh."
3. Add 0F to the COULSON_BLOCK0 procedure after 0E:
   - IF UI paths detected AND DESIGN.md missing: report FAIL to Nick Fury
   - IF UI paths detected AND DESIGN.md present: run lint, report result
   - IF no UI paths: log NOT_APPLICABLE, skip

No changes to document generation logic -- 0F is verification-only.
```

### 13.5 Black Panther -- Visual Conformance Pass

```
You are Black Panther. Add a Visual Conformance sub-check to your review
process.

Read: _aegis-output/specs/S3-VISUAL-LAYER-spec.md section 5.3.4.

Add to .claude/agents/black-panther.md review procedure:

Pass 6: Visual Conformance (conditional)
- Trigger: DESIGN.md exists at project root AND PR touches UI files
- Skip if: no DESIGN.md or no UI files in diff

Check procedure:
1. Read DESIGN.md sections: Colors (2), Typography (3), Components (4),
   Layout (5)
2. For each changed UI file:
   a. Color values: verify tokens, not hardcoded hex
   b. Font properties: verify match against Typography section
   c. Component patterns: verify structural match against Components
   d. Spacing/grid: verify match against Layout section
3. Finding categories:
   - CONFORMANT: code matches design tokens
   - DEVIATION: code uses values not in DESIGN.md (cite specific line)
   - UNLISTED: component not defined in DESIGN.md

This pass produces findings, not blocks. Spider-Man addresses deviations
in the fix loop. Unlisted components may be intentional (document why).
```

---

*Spec produced by Iron Man. Awaiting Loki Plan-Approval Gate review.*
*Save path: `_aegis-output/specs/S3-VISUAL-LAYER-spec.md`*
*Stories: 4 core (11pt) + 3 stretch (deferred)*
*Test scripts specified: 4 (fetch 7 cases + lint 12 cases + gate 8 cases + hook 8 cases = 35 total assertions) + 2 guard-write library protection cases*

---
*v1.1 -- Loki D-023 conditions addressed 2026-04-23 by Iron Man cycle 7*
