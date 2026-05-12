<!-- version: 1.0.0 -->
<!-- Last updated: 2026-05-12 -->

# v14 Series Retrospective — Hermes Parity + Audit Hardening

> Cross-sprint retro for the 4-sprint Hermes parity series. Individual sprint close.md files have per-sprint detail; this captures patterns + lessons that span the series.

## Series facts

- **Duration**: single session, 2026-05-12 (12+ hours of work distilled into one execution batch)
- **Sprints**: 4 (v14-01 → v14-04)
- **Points delivered**: 47/47 (100%)
- **Tests added**: 132 across 9 new test files, all GREEN
- **Files**: 19 new + 8 edits
- **Bugs caught by tests**: 4 (would have shipped without TC30/TC15/TC3 fixtures)
- **External Access spent**: $0 (heuristic judge only; real LLM gated)

## What worked across all 4 sprints

### 1. Hermes-as-reference, AEGIS-as-target

Reading the Hermes docs + codebase BEFORE proposing v14 produced a much cleaner sprint plan than "let's adopt Hermes patterns" in the abstract. Concrete file paths from Hermes (e.g. `tools/memory_tool.py:_MEMORY_THREAT_PATTERNS`) translated directly to AEGIS targets.

**Lesson**: When porting patterns across frameworks, cite source line+file in the plan. Saves audit time later.

### 2. Test-first regression fixtures caught 4 real bugs

| Bug | Caught by | Without fixture, would have... |
|-----|-----------|--------------------------------|
| `aegis-upgrade.md` missing frontmatter | Registry inventory in S14-01-01 | Silently rotted |
| `aegis_env` regex matching `~/.aegis-plus/` | TC30 regression in S14-01-02 | Blocked legitimate brain edits |
| `eval()` check tripping doc-comments | TC15 in S14-01-03 | False-positive PR comments → reviewers ignore scanner |
| `aegis-dump` JSON malformed by `grep -c || echo 0` | TC3 in S14-03-01 | Downstream JSON parsers would have errored |

**Lesson** (already in `feedback_audit_verdicts_run_test_first` memory entry): graduate-by-running, not by-reading. Even my own newly-written code had bugs that only the tests caught.

### 3. SSOT registry pattern self-validates

The CommandDef registry was tested against the filesystem (TC8 specifically: "registry ⊇ filesystem"). When `aegis-decisions` and `aegis-goal` were added across v14-02/v14-04, the registry test caught BOTH the registry entry omission and the file-count mismatch.

**Lesson**: Self-validating registries (where the test asserts registry-set == filesystem-set) prevent the most common SSOT failure mode: drift between the index and the things it indexes.

### 4. Honest scope splits

v14-04's S14-04-02 measurement methodology was split: 1pt for the doc, 4pt for the actual measurement campaign (deferred). This kept the sprint closing cleanly without violating the External Access gate. The 4pt is documented with explicit go-conditions, not hand-waved.

**Lesson** (extends `feedback_external_access_stays_gated` memory entry): when a sprint mixes in-turn work with External Access work, split the story. Ship the in-turn portion + document the deferred portion's go-conditions.

### 5. Audit-before-retrofit caught 2 surprises

S14-03-02 budget was "first-run defer audit/retrofit for v10-07". The audit step (1pt of the 5pt budget) revealed that `aegis-pattern-mine/mine.mjs` had ZERO defer pattern — full retrofit needed, not optional. If I'd assumed defer was probably there + just touched up, I'd have shipped a no-op.

Similarly, S14-02-02 budget assumed "from-scratch decision search" but the audit found `aegis-brain-search.sh --type decisions` already worked. Story collapsed to "UX wrapper + slash command + registry expansion" — 5pt of real work, just different shape.

**Lesson**: ALWAYS audit before retrofit. Sometimes the work is bigger than expected (v10-07), sometimes smaller (v10-06 search). Both surprises are real, neither is detectable without reading existing code.

## What surprised across the series

### 1. AGENTS.md (root) didn't exist

My "any remaining?" answer to the user claimed AEGIS needed `AGENTS.md (root) reference to registry`. When I went to update it, it didn't exist — AGENTS.md is Hermes's convention, not AEGIS's. Carry-forward item was based on misread of Hermes structure leaking into AEGIS planning.

**Lesson**: When cross-framework gap analysis suggests a carry-forward, verify the gap exists in YOUR framework before scoping it as work.

### 2. Mega-batches with `set -uo pipefail` need careful command grouping

S14-03-01 caught the `grep -c | … || echo 0` race that produced double-zero JSON output. The interaction between `set -uo pipefail` and OR-fallback patterns in shell is subtle. The right idiom turned out to be: capture into a variable, then default with `${VAR:-0}` if empty.

**Lesson**: For numeric extraction from shell pipes, prefer `var=$(pipeline) ; var="${var:-default}"` over `var=$(pipeline || echo default)` — the former is unambiguous about which output wins.

### 3. JSON.stringify default is compact, not pretty

Three tests in S14-03-02 failed because I assumed `JSON.stringify(obj)` produced `{"key": "value"}` (with space after colon). It produces compact `{"key":"value"}`. Three regex fixtures needed updating after the first test run.

**Lesson**: When asserting JSON output content, either: parse the JSON properly, OR use whitespace-tolerant regex (`"key"\s*:`). Don't rely on visual mental model of "what JSON looks like".

### 4. POC honesty cost real time

v14-04's `--mode llm` placeholder + measurement methodology doc took 30+ minutes of design work that produced ZERO running code. But this is the right move — wiring real LLM calls without a measurement plan would have burned $$$ on premature optimization. The methodology doc IS the v14-04 deliverable for the deferred portion.

**Lesson**: For POC sprints with External Access components, the design doc IS load-bearing. Treat it as deliverable, not preamble.

## Patterns to preserve

1. **Test-first regression fixtures** — every threat pattern adopted should have a fixture that proves the existing brain doesn't trigger it. TC30 is the template.
2. **Audit-before-retrofit** — read the existing code before sizing the story. Cite file:line in the plan.
3. **Honest scope splits** — if a story mixes in-turn work + External Access, split it. Ship the in-turn portion + document deferred go-conditions.
4. **SSOT registries with self-validation** — every "single source of truth" should have a test that asserts the SoT covers the consumer set.
5. **No-noise CI discipline** — when adding security CI, ruthlessly remove low-signal heuristics. Cite the Hermes commit (dd0923b) explaining why.

## Anti-patterns to avoid

1. **Don't assume defer-pattern exists** — even after reading the docs that describe it, verify in code.
2. **Don't trust visual JSON assumptions** — parse or use whitespace-tolerant regex.
3. **Don't import "carry-forward" from cross-framework analysis without verifying the gap exists in YOUR framework**.
4. **Don't ship External Access work without a pre-committed budget cap + kill switch + decision tree**.
5. **Don't conflate "go" with "External Access by name"** — broad authorization does NOT cover External Access; that needs by-name approval each time.

## Recurring memory entries to consider promoting to instincts

After the v14 series experience, these patterns feel strong enough to consider for instinct promotion (3+ use-cycles observed within the series):

- "Audit-before-retrofit" — applied successfully in v14-02-02 and v14-03-02
- "Test-first regression fixtures" — caught 4 real bugs across v14-01/v14-03
- "Honest scope splits for External Access" — applied in v14-04

These could be promoted via `tools/aegis-instinct-promote.sh` if the user wants them as durable rules.

## Carry-forward to v15+

- ARCHITECTURE.md and AGENTS.md (root, **if it exists**) cleanup — DOWNGRADED to "AGENTS.md was a Hermes-only file, doesn't apply"; ARCHITECTURE.md DONE in this session
- v15 cleanup sprint for DoD §4 + §9 partials — DOWNGRADED to "this retrospective covers it"
- Real LLM judge integration + measurement campaign for `/aegis-goal` — still deferred, methodology doc has full protocol
- `aegis-pin check` wire-up into `aegis-instinct-auto-reinforce.sh` — primitive shipped, integration deferred
- Auto-snapshot hook wiring — deferred for burn-in

## Series-level decision

The Hermes Agent gap analysis (preceding work in this session) identified 12+ adoption candidates. v14 picked the top 4 (P0/P1) and shipped them. The remaining (multi-platform messaging, voice, browser, RL, profile system, MCP server, agent self-modification) are explicitly OUT of AEGIS scope by design — they would compromise the ISO 29110 audit trail and the methodology-not-runtime posture.

**v14 succeeded at: adopting Hermes operational discipline without compromising AEGIS compliance posture.**

The next sprint after v14 is whatever the user prioritizes. Not "v15" by default — could be operational work, a new project adoption, or unblocking v10-08. v14 closes the explicit Hermes-adoption roadmap.
