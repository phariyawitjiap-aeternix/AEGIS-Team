<!-- version: 1.1.0 -->
<!-- Last updated: 2026-05-07 -->

Last reviewed: 2026-05-07

# AEGIS Sprint Operating Rules

> **The 6 rules that govern how a sprint runs.** Written down because they kept regressing as implicit conventions. Loki auto-rejects any sprint plan or close.md that violates these. `mbp-scan.sh` (on-stop hook) blocks responses that ask the human to fill the team's role.
>
> Mental model: **human = Board** (governance — Identity / Irreversible / External access / Explicit approval gate). **Nick Fury = CEO** (operational decisions). **The team = the org.** The Board does not pick stories from the backlog; the Board does not vote on tactics; the Board approves the four governance categories and otherwise delegates.

## Changelog

| Date | Version | Change |
|------|---------|--------|
| 2026-05-07 | 1.0.0 | Initial SPRINT_RULES authored after user feedback (2026-05-07) that the team kept stopping mid-sprint to ask the human for operational input. Codifies 5 rules + voting protocol that were previously implicit. Cross-referenced from DoD.md §3, ARCHITECTURE.md §7, CLAUDE.md Golden Rules. |
| 2026-05-07 | 1.1.0 | Added **Rule 6** — Graduate-by-running, not graduate-by-reading. Codified after sprint-v13-01 retro found audit verdicts were wrong about half the time across the sprint, but each wrongness revealed a real bug. Action item AI-1 from v13-01 close retro. |

---

## Rule 1 — Team self-knows what to do

**Bar.** At sprint open the team has a `plan.md` with stories, points, and acceptance criteria. From that point until close, the team does not ask the human "what should I do next?" The plan IS the answer.

- ✅ The team READS the plan.md, picks the next story per Rule 2, and acts.
- ✅ If the plan is unclear, Iron Man writes a tighter spec — the team does not escalate.
- ✅ If a story turns out to be wrong, the team writes a Change Request (PM.2) into the close.md and continues with the next story.
- ❌ The team does NOT end a turn with "what would you like me to work on next?" / "ต่อไปจะทำอะไร?" — these are reverse-delegation. The plan answers it.

**Exception (the only one):** if the next action requires Identity, Irreversible scope, External access, or an Explicit approval gate (the four MBP escalation categories), the team appends to `.aegis/brain/human-queue.md` via `tools/aegis-queue-human.sh` and CONTINUES with everything else they can do. They do NOT pause-and-wait.

**Enforcement:** `on-stop.sh` mbp-scan blocks responses that end with "what next" / "ต้องการอะไรต่อ" / "pick by name" / etc. (PR #135 — 21 fixtures pinned).

## Rule 2 — Team self-prioritizes the backlog

**Bar.** The team picks the next story by this deterministic order — no human input required:

1. **Blockers first** — anything tagged `blocker` in the close.md or surfaced by Loki review.
2. **Highest-impact-per-point** — biggest story (DoD-bar lift) divided by point estimate.
3. **Dependency order** — if Story B requires Story A, do A first regardless of impact.
4. **Lowest risk to ship** — among ties, pick the one whose acceptance criteria are most testable.
5. **Tiebreak: lexicographic story ID** — A before B before C, just to be deterministic.

If any human input is genuinely required to choose between two equally-ranked stories, the team **picks one and acts**, then logs the alternative in close.md as "deferred — re-rank if not delivered."

**Enforcement:** Captain America (or Nick Fury when active) reviews the next-story choice during dispatch. Loki auto-rejects sprint plans whose story order violates the deterministic rules above without a logged rationale.

## Rule 3 — Deep test, not surface assertion

**Bar.** DoD §5's "≥1 assertion per AC" is the floor, not the bar. A sprint close gate requires:

- **Unit-level assertions** — one per acceptance criterion bullet (DoD §5 minimum).
- **Integration test** — at least one fixture that exercises the story end-to-end with real (or realistic-fixture) inputs, not just mocks.
- **Adversarial test** — at least one Loki-style fixture that tries the wrong inputs, malformed data, or pathological-but-plausible misuse.
- **Determinism check** (when applicable) — if the story produces output that should be byte-equal across runs (parsers, builders, miners), assert that explicitly.
- **Real-tree smoke test** — for tools/scripts: at least one assertion that runs against the live meta or a representative fixture, not just a synthetic fixture.

**Why this matters:** the team has historically shipped sprints with only happy-path tests, then spent the next sprint fixing bugs that should have been caught in the original. Deep-test in-sprint is cheaper than fix-sprint after.

**Enforcement:** Black Panther reviews every sprint close.md and rejects PASS if the test inventory is happy-path-only. Loki challenges the test fixtures for missing edge cases. The team is allowed one round of fix-loop before the sprint counts as "shipped with quality debt."

## Rule 4 — Quality-gate failure spawns a follow-up sprint

**Bar.** A sprint can close in one of three states:

1. **CLOSED clean** — all DoD bars hit, all tests green, no quality debt logged. → next sprint per backlog.
2. **CLOSED with quality debt** — shipped functionally but Black Panther / Loki / human flagged ≥1 of: missing tests, code smell, unrefactored area, performance regression, doc gap.
3. **NOT closed — hold for next sprint** — story didn't actually ship. → re-plan, do not declare CLOSED.

**For state 2 — quality debt closure:** before the next backlog sprint, the team automatically opens a **bug-fix / quality sprint** (`sprint-<ID>-fixup` or named explicitly) that contains:

- Every flagged bug as a story
- "Ultimate test" pass — full integration + adversarial test sweep against the area touched in the prior sprint
- Code review pass (Black Panther primary, Loki secondary)
- Refactor pass for any code smell flagged
- Continues until the team is satisfied (Black Panther + Loki both PASS, OR human explicitly says "ship it" gate-override)

The team does NOT skip a fix-sprint to start new feature work just because the user hasn't asked for one. **Quality is a sprint topic, not a backlog item.**

**Enforcement:** sprint close.md template includes a "Quality debt" section. Roadmap.md gets a `sprint-<ID>-fixup` row added automatically when state 2 fires. Captain America logs the auto-opened fixup sprint to decision-audit. The fixup sprint is not optional once flagged.

**Examples:**
- v11-09 multi-tenant shipped with 4 follow-up fixes (PR #114 / #115) — those should have been one fixup sprint, not 4 separate emergency PRs
- v12-01 doc canon shipped clean — no fixup needed
- v12-04 graph build shipped clean — but discovered the F1/F3 friction in pilot use, which spawned the kam-tong-ham + meta fixes (PR #126 / #133 / #134) — that was effectively a fixup sprint, just not formally named

## Rule 5 — Voting / debate / decision protocol

**There is no majority-vote system.** Decisions in AEGIS work by **CEO call + audit log**, not by tally. Specifically:

| Decision class | Who decides | How | Logged to |
|---|---|---|---|
| Operational / tactical (which story · which approach · ship vs split) | **Nick Fury** (CEO) — Captain America when Nick is offline | Decision Matrix → instinct → judgment fallback | `decision-audit.log` |
| Two-agent consensus required (critical-severity code review findings) | **Black Panther + Loki** must both PASS | If they disagree, escalate to Nick | `decision-audit.log` + close.md |
| Adversarial design debate (`/aegis-team debate`) | Iron Man proposes A, Loki argues B, **Nick Fury decides** | Captain America synthesizes; Nick picks | `decision-audit.log` |
| Architecture decisions of lasting impact | **Iron Man** drafts ADR · Nick approves · all agents bound thereafter | ADR-NNN in `.aegis/brain/resonance/` | ADR file + `decision-audit.log` |
| MBP escalation (Identity / Irreversible / External access / Explicit approval gate) | **Human** (= Board) | Item appended to `human-queue.md`; team continues with everything else | `human-queue.md` PENDING block |

**Why no majority vote?**

Tested in early v6 — produced ties that needed a tiebreaker, which became Nick anyway. Cleaner to make Nick the decider explicitly. The dissent voices (Loki, Black Panther) are still heard via debate / review and can flip Nick's decision via reasoned argument — but they don't "outvote" him.

**The closest thing to "veto":** if Loki rejects an Iron Man spec on adversarial review, Nick can override but the override goes into the audit log for retro mining. Repeated overrides on the same axis surface as a pattern in v10-07 mining.

## Rule 6 — Graduate-by-running, not graduate-by-reading

**Bar.** When opening graduation work for a known-failure (`tests/_known-failures.txt` entry) OR starting a refactor flagged in a sprint plan §"Audit findings" section, the FIRST move is to **run the test or read the code end-to-end** — not to trust the audit verdict written in the plan.

- ✅ Step 1: `bash tests/<name>.sh` standalone (or `cat tools/<name>.sh` for a refactor target).
- ✅ Step 2: Compare actual failure mode / actual code structure to what the audit claimed.
- ✅ Step 3: If they diverge, trust reality and document the divergence in the close.md.
- ❌ The team does NOT skip Step 1 because the audit verdict "sounds plausible". Audit verdicts are inputs, not decisions.

**Why this matters.** Sprint v13-01 ran 5 phases / 7 PRs / 24 points. The plan §6 audit's verdicts were wrong about **half the time**, but each wrong verdict revealed a real bug nearby:

| Phase | Audit said | Reality |
|-------|-----------|---------|
| A audit error | aegis-test-all is dead | Actually load-bearing — false-positive caught by Rule 3 |
| B/c1 | block0-f-gate "surface-only" | `$(dirname "$0")` misuse |
| B/c2 | instinct-promote "fixture-dependent" | `set -e` + `&&` short-circuit silent exit |
| B/c2 | trace-audit "needs more assertions" | Real ghost-ref drift in SI.02 |
| B/c3 | install-v11 "v11-specific outdated" | Real "wired but not shipped" bug for v12 brain-graph |
| C | "23 orphan tools" | 5 surviving are *correctly* architecturally invisible |
| E | sprint-tracker "needs split" | Splitting harms cohesion; TOC suffices |
| E | instinct-promote "needs refactor" | Already well-factored at avg 33 LOC/function |

The other half of the time the audit was directionally correct but the fix was **smaller than the audit suggested** (e.g. "needs split" → TOC was enough; "complexity review" → no refactor needed).

**Pattern**: an audit verdict is a hypothesis, not a verdict. The test or the code is the verdict.

**Enforcement:**
- Sprint close.md template includes an "Audit verdict vs reality" subsection when graduation work is part of the sprint. If the audit was wrong, the close.md must record what the actual bug was.
- Loki challenges any close.md that graduates a known-failure without showing the diff between audit claim and reality.
- Captain America logs the divergence to decision-audit when it surfaces a recurring pattern (e.g. "two of last three audits called things 'fixture-dependent' when they were actually `set -e` footguns" → flag for next-sprint sweep).

**Examples:**
- v13-01 close.md mining produced the 9 audit-vs-reality rows above; this is the canonical example.
- Future sprint that graduates a known-failure should follow the same audit-vs-reality table format in its close.md.

---

## How these rules interlock

```
                Backlog (plan.md per sprint)
                          │
                          ▼
                    Rule 1 — team knows
                          │
                          ▼
                    Rule 2 — team picks
                          │
                          ▼
                Execute (Spider-Man builds,
                Iron Man specs, Black Panther
                reviews, Loki adversarial)
                          │
                          ▼
                    Rule 3 — deep test
                          │
                          ▼
                Sprint close gate
                  /        |        \
                 /         |         \
        CLEAN    QUALITY DEBT     NOT CLOSED
        (1)        (2)              (3)
         │          │                │
         ▼          ▼                ▼
    backlog     Rule 4 —         re-plan
    next        spawn fixup      same sprint
                sprint
                  │
                  ▼
              fix-bugs +
              ultimate-test +
              code-review +
              refactor
                  │
                  ▼
              Rule 4 satisfied →
              backlog next
```

Decisions all along the way: **Rule 5** — Nick / Captain / Black Panther+Loki / human-queue per category. Never a free-form "what should I do?" loop with the human.

## Cross-references

- [DoD.md](DoD.md) §5 (Test coverage) — the floor that Rule 3 sits on top of
- [ARCHITECTURE.md](ARCHITECTURE.md) §7 (Persona Routing) — defines the agent roles cited in Rule 5
- [GUARDRAILS.md](GUARDRAILS.md) — Sign "AskUserQuestion option-menu" enforces Rule 1
- [CLAUDE.md](CLAUDE.md) Golden Rule #7 — the Master Brain Protocol that Rules 1–5 implement
- `.claude/references/command-chain.md` — what each `/aegis-*` command does after it finishes (the chain that prevents Rule 1 violations)
- `.claude/references/decision-audit-protocol.md` — the JSONL contract used by Rule 5
- `.claude/hooks/lib/mbp-scan.sh` — the regex enforcement that pins Rule 1 (PR #135)
- `tests/aegis-mbp-scan-thai-test.sh` — the 21-fixture pinning test for Rule 1's enforcement

## When to update this file

- A rule regresses and the user has to flag it manually → strengthen the existing rule's "Enforcement" section AND add the corresponding test fixture.
- A new decision class emerges that doesn't fit Rule 5 → add a row to the Rule 5 table.
- A human-queue category is added or removed → update Rule 1's exception list.
- A new sprint shape is needed (e.g. spike sprints, research sprints) → add Rule 7+, do NOT silently bend Rule 4.

The version-header pattern requires a Changelog row on every substantive edit.
