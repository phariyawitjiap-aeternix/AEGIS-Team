# Anti-Patterns (Avoid)
> Patterns that caused gate failures 2+ times.
> Agents are warned when encountering similar tasks.

## A-001: bypassPermissions as Default Mode

**Evidence**:
- v8.x .claude/settings.json `defaultMode: "bypassPermissions"` exposed wide attack surface
- Loki review (Critical #2): allow list had `rm`, `curl`, `docker`, `kubectl`, `terraform` -- any blast radius
- Real risk: Spider-Man could `kubectl delete pod` without prompt

**Anti-pattern**: Setting `defaultMode: "bypassPermissions"` to "make agents work smoothly" while keeping a thin deny list.

**Root cause**: Optimizing for developer convenience over safety. Permission prompts feel annoying, so disable them.

**Cost**: Single bug in agent prompt could destroy repo or production infra.

**Fix**: Use `acceptEdits` (allows Edit/Write only). Bash requires explicit allow per command. Deny list ≥ 20 dangerous patterns.

**Detection**: aegis-doctor checks `defaultMode != "bypassPermissions"`.

---

## A-002: Comment-Regex for Idempotent File Edits

**Evidence**:
- Loki review (Critical #5): `grep -q "AEGIS Framework"` is fragile if user removes comment
- 2+ tools in v8.x used this pattern
- Re-runs caused duplicate gitignore entries

**Anti-pattern**: Using comment text as a marker for auto-managed file blocks (e.g., `# AEGIS managed:` then grep for that string).

**Root cause**: Comments feel natural to humans, but they're optional. Users can remove them while keeping content.

**Cost**: Tool re-runs add duplicate content; idempotency breaks.

**Fix**: Use sentinel markers (`# <<< NAME-START >>>` / `# <<< NAME-END >>>`). See P-001 for the proven pattern.

---

## A-003: Dual-Write Persistence Without Source of Truth

**Evidence**:
- v9 plan v3.0 ADR-002: memory_20250818 + file as peers (Loki Critical #5b)
- Cost: data divergence when one write fails -- which version is correct?
- Pattern: 2+ "syncing" issues in distributed system contexts

**Anti-pattern**: Writing the same data to 2 systems as equal peers, hoping for eventual consistency.

**Root cause**: "Belt and suspenders" thinking without designating authority.

**Cost**: Inconsistency bugs are insidious -- silent data loss, hard to debug.

**Fix**: Designate ONE source of truth. Other writes are best-effort cache. On divergence, truth wins.

**See also**: P-002 (file = truth, memory tool = cache).

---

## A-004: BLOCK 0 Forced on All Tasks Regardless of Size

**Evidence**:
- Loki review (Critical #5a): 1pt typo fix consumes 31,481 tokens through full BLOCK 0
- v8 sprint-1 metrics: 850K tokens for 27 story points
- Pattern: small tasks bypass workflow entirely (anti-pattern feedback loop)

**Anti-pattern**: One-size-fits-all process where 1pt and 21pt tasks follow identical pipeline.

**Root cause**: Treating ISO 29110 compliance as binary (all or nothing) instead of risk-proportional.

**Cost**: Token waste + workflow fatigue + agents skip steps to compensate.

**Fix**: Proportional BLOCK 0 (lite/standard/full modes per task size). See block-0-lite.md.

---

## A-005: Single Point of Failure in Decision Authority (No Fallback)

**Evidence**:
- Loki review (Critical #3): Nick Fury Master Brain has no fallback
- If Nick Fury times out / hits judgment gap, pipeline stalls
- Lvl-8 fallback = "own judgment" = hallucination risk

**Anti-pattern**: Centralized decision authority with no tier-2 fallback.

**Root cause**: Designing for happy path, ignoring failure modes.

**Cost**: System unavailable when authority is unreachable.

**Fix**: Tiered fallback (Nick Fury → Captain America → human). Confidence threshold auto-escalates. See captain-america-fallback.md.

---

## A-006: Empty Brain Files Claimed as "Self-Learning"

**Evidence**:
- Loki review (HIGH #4): evolved-patterns.md, anti-patterns.md, ADRs all empty in v8.4
- Marketed as "smarter every sprint" but knowledge pipeline never triggered
- 3 sprints completed, 1 promoted instinct (seed)

**Anti-pattern**: Building learning infrastructure without seeding initial content or wiring auto-population.

**Root cause**: Assuming patterns will "emerge naturally" from sessions without explicit capture.

**Cost**: Brain is dead weight; agents fall back to judgment (lvl-8) for everything.

**Fix**: Seed brain with proven patterns (S3-01 through S3-03). Wire ScheduleWakeup for periodic distillation (S6-01).

---

## A-007: Marketing-File Naming for Framework Folders

**Evidence**:
- v8.x scattered: `_aegis-brain/`, `_aegis-output/`, etc. (underscore prefix = "internal" feel)
- v9 plan ADR-007: convention is dot-prefix for framework folders (`.git/`, `.claude/`)
- Loki review: "single folder" promise should follow convention

**Anti-pattern**: Using non-standard naming (underscore prefix, MarketingCase) for framework-managed directories.

**Root cause**: Wanting visibility/branding for framework folders.

**Cost**: Breaks convention readers expect; harder to .gitignore; framework feels "polluting".

**Fix**: Hidden dot-prefix folders (`.aegis/` per ADR-007). Use README/docs for discoverability instead.

---

## A-008: Documentation Without Hook Enforcement

**Evidence**:
- v8 CLAUDE_safety.md hard rule "Never push to main" -- but hook only WARNs, doesn't block
- Activity.log shows `git push origin main` ALLOWED multiple times
- Loki review: "safety theater" gap

**Anti-pattern**: Writing safety rules in markdown but not enforcing them in hooks.

**Root cause**: Hooks are harder to write than markdown; rules drift apart.

**Cost**: Rules look enforced but aren't. Trust in documentation degrades.

**Fix**: Every CRITICAL hard rule MUST have a hook. See P-008.

**Detection**: aegis-doctor cross-references CLAUDE_safety.md hard rules vs hook enforcement.

---

## A-009: Plugin/Distribution Lock-In Without Abstraction

**Evidence**:
- v9 plan R2: Plugin API may break in Claude 4.8+
- Initial plan had no abstraction layer task
- Loki review: "S10-01 is just research, not abstraction"

**Anti-pattern**: Building directly against external API surface without adapter layer.

**Root cause**: "We can refactor later" -- but later never comes; breaking change does.

**Cost**: Each external API change requires hunting through codebase to update calls.

**Fix**: Build IPluginAdapter / IMCPAdapter interfaces. AEGIS code calls adapter, not external API. See S10-01b.

---

## A-010: Treating "Single Folder" as Strict (When .claude/ Required)

**Evidence**:
- Loki review (Critical #4 on ADR-007): "Single folder" promise is misleading
- `.claude/` is required at project root by Claude Code (cannot move)
- Marketing message conflicts with reality

**Anti-pattern**: Promising "consolidate to ONE folder" when platform constraints require multiple.

**Root cause**: Aspirational design without validating platform constraints.

**Cost**: Loss of trust when users see 2 folders despite "single folder" claim.

**Fix**: Truthful messaging: "Consolidate to .aegis/, with .claude/ remaining at root per Claude Code requirement". See ADR-007 honest framing.
