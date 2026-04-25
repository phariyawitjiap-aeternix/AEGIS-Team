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

---

## A-011: Prose-Only Integration Points in Specs

**Evidence**:
- Sprint v9-05: F1-05 Loki integration described in prose but NOT in Tool Deliverables Matrix
- Spider-Man self-check used matrix as checklist, shipped without touching loki.md
- BP round-1 caught it as MEDIUM-01 only via spec-to-file cross-check
- Feature would have shipped non-functional without BP review

**Anti-pattern**: Describing integration points ("integrate with X", "add to Y", "call from Z") in prose paragraphs instead of structured tables/matrices in specs.

**Root cause**: Prose feels natural for describing relationships, but prose hides actionable work inside sentences that implementers skim.

**Cost**: Deliverables ship "complete" but non-functional -- the tool exists but no agent invokes it. Silent omission.

**Fix**: Every spec claiming integration with existing files MUST include a "Cross-Cutting Touchpoints" section with structured table: Deliverable | Integration Target | Required Change. Prose alone is a known hiding place.

---

## A-012: Relative Paths in Hook Configurations

**Evidence**:
- Recurring Stop hook error across all AEGIS projects: "bash: .claude/hooks/run-with-flags.sh: No such file or directory"
- Root cause: hook commands in .claude/settings.json used RELATIVE paths
- Sub-agents and background processes fire hooks from arbitrary cwd, not repo root
- Fixed across 5 projects (PRs #67, #68) by anchoring to $CLAUDE_PROJECT_DIR
- Same class as cross-project namespace isolation (P-012)

**Anti-pattern**: Using relative paths in hook command configurations, assuming hooks always execute from the repo root.

**Root cause**: Hook commands work during manual testing (developer is in repo root). Fails silently when sub-agents or background processes have different cwd.

**Cost**: Hooks silently fail, degrading retro logging, false-ready detection, and session-end safety checks.

**Fix**: Anchor ALL hook commands to `$CLAUDE_PROJECT_DIR` or absolute paths. Auto-applied during `/aegis-upgrade`. Detection: grep for relative paths in settings.json hooks.

---

## A-013: Stale Heartbeat During Main-Agent-as-Router

**Evidence**:
- Sprint v9-05: Nick Fury heartbeat stale for 7 hours while main agent routed decisions
- Sprint v10-02 session 2: heartbeat never refreshed across 7 PRs
- TinMan health checks would report brain as unhealthy, creating false alerts
- Pattern repeats whenever main-agent-as-router substitutes for Nick Fury process

**Anti-pattern**: Running the main-agent-as-router pattern (Captain America substituting for Nick Fury) without refreshing the heartbeat signal.

**Root cause**: Heartbeat is tied to Nick Fury's process loop, not to the decision-routing function. When the function moves to a different agent, the signal goes stale.

**Cost**: False health alerts from TinMan; observability gap; session-end hooks may trigger stale-brain warnings.

**Fix**: If main-agent-as-router exceeds 3 PRs or 30 minutes, manually refresh heartbeat. Future: decouple heartbeat from agent identity, tie it to decision-routing activity.
