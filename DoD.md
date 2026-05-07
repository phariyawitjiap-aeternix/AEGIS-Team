<!-- version: 1.0.0 -->
<!-- Last updated: 2026-05-06 -->

Last reviewed: 2026-05-06

# AEGIS Definition of Done

> Repo-wide stable completion bar. Sprint-level acceptance criteria are **additive** on top of this — never weaken these bars. If a sprint's acceptance criteria fail to cover one of these, the bar still applies.
>
> Adapted from GitNexus's `DoD.md` 9-bar pattern. Source: AEGIS Knowledge-Layer Mega Plan v1.1 (sprint-v12-01).

## Changelog

| Date | Version | Change |
|------|---------|--------|
| 2026-05-06 | 1.0.0 | Initial DoD authored as part of sprint-v12-01 (Knowledge-Layer Mega Plan Phase A). 9 sub-bars adapted from GitNexus to AEGIS specifics. |

---

## How to use this document

- A sprint's `plan.md` lists **sprint-specific** acceptance criteria.
- This file lists **repo-wide** completion bars that apply to every sprint regardless.
- Before opening a sprint-close PR: walk every applicable bar below. Any unchecked bar that *should* apply is a blocker.
- Bars marked **(applicable when …)** only gate sprints that touch the named area.

---

## 1. Brain integrity

**Bar.** Every write to `.aegis/brain/` is atomic (temp + rename) and the FTS5 index can be rebuilt deterministically from sources.

- [ ] Any new tool that writes to `.aegis/brain/` uses `tools/aegis-brain-write.sh` (or its node equivalent) — never a plain `fs.writeFile` to a tracked path.
- [ ] If the sprint adds new brain content kinds, the indexer (`tools/aegis-brain-index.sh`) handles them on `--full` rebuild.
- [ ] No write to a brain path leaves a half-written file on a kill -9 mid-write.

**Why.** Half-written brain files corrupt search and break next-session bootstrap. Atomic discipline is non-negotiable.

---

## 2. Hook fail-OPEN

**Bar.** Every hook script (`PreToolUse`, `PostToolUse`, `Stop`, `SessionStart`) exits 0 on **internal error** — meaning a bug in the hook itself never blocks legitimate tool calls.

- [ ] New hook scripts wrap their body in a top-level try/catch (or `set +e` with explicit error trap) that emits a one-line warning to stderr and exits 0.
- [ ] Approval gates (`aegis-approval-gate`) are the **one allowed exception**: they fail-CLOSED on bug-or-block. This must be explicit in the script comment.
- [ ] Hook latency budget: p95 < 100ms (see Mega Plan §11 R1). New hooks include a benchmark.

**Why.** A hook crash that fails-CLOSED locks the user out of their own tool. Risk R6 in Mega Plan v1.1.

---

## 3. MBP compliance (Master Brain Protocol)

**Bar.** No agent response ends with a "Options: A/B/C — what do you want?" menu. No `AskUserQuestion` call from any caller other than Nick Fury escalating one of the 4 allowed categories (Identity / Irreversible scope / External access / Explicit approval gate).

- [ ] Every command's exit chain is documented in `.claude/references/command-chain.md`. No "what next?" prompts.
- [ ] If a non-Fury caller invokes `AskUserQuestion`, `.claude/hooks/guard-ask-user.sh` blocks it; this gate must remain wired in `.claude/settings.json`.
- [ ] If Nick Fury is offline, fallback is **judgment + log** (via `tools/aegis-log-decision.sh --source judgment`), never "ask the human."

**Why.** Golden Rule #7. The single most-violated AEGIS rule; tightening compliance is core to v9–v11 hardening and stays mandatory through v12+.

---

## 4. Sprint close.md present

**Bar.** Every sprint that opens has a `plan.md`; every sprint that closes has a `close.md` adjacent to it.

- [ ] `.aegis/brain/sprints/sprint-<id>/plan.md` exists at sprint open.
- [ ] `.aegis/brain/sprints/sprint-<id>/close.md` exists at sprint close, with: stories shipped table, acceptance evidence, lessons, links to PRs.
- [ ] No silent closures. A sprint moved to "CLOSED" in `roadmap.md` without a `close.md` is a violation.

**Why.** The grand-total tracker depends on close.md as the source of truth for what shipped. Close.md is also the seed for v12-04 graph IMPLEMENTS edges.

---

## 5. Test coverage (≥1 assertion per AC)

**Bar.** Every sprint Acceptance Criterion has ≥1 corresponding assertion in a regression test that runs in CI.

- [ ] Each AC bullet maps to one (or more) test assertions; the mapping is referenced in `close.md`.
- [ ] Tests live in `tests/sprint-<id>/` (preferred) or in the tool package's own `tests/` dir.
- [ ] Tests run from a top-level entrypoint (`bash tests/run-all.sh` or equivalent) and exit non-zero on any failure.
- [ ] **(applicable when adding hooks)** New hook scripts have a fixture that simulates a tool call and asserts the hook's exit code + output.

**Why.** Sprint v9-06 surfaced a recurring "policy-without-test" bug class — rules claiming "MUST/enforces/auto-REJECTs" without matching hook/test/assertion code. This bar makes that class structurally impossible to ship.

**See also:** [`SPRINT_RULES.md`](SPRINT_RULES.md) Rule 3 — "Deep test, not surface assertion." DoD §5 is the floor; SPRINT_RULES Rule 3 raises the bar to integration + adversarial + determinism + real-tree smoke for the close gate.

---

## 6. Roadmap update

**Bar.** Every sprint-close PR touches `.aegis/brain/sprints/roadmap.md`.

- [ ] Sprint row's status flips to `CLOSED (NN%)`.
- [ ] Points-Done column reflects actual delivery (including stretch).
- [ ] If scope changed mid-sprint: rationale captured in close.md AND roadmap "Why delivered > denominator" section gets a new row if applicable.
- [ ] If new sprints are queued: they appear in the roadmap as `planned` rows (not silently in `human-queue.md` only).

**Why.** Grand-total math is the single number that says "are we shipping?" Drift here means drift everywhere.

---

## 7. Version headers (v12+)

**Bar.** Every governance doc at the repo root carries a `<!-- version: X.Y.Z -->` header, a `<!-- Last updated: YYYY-MM-DD -->` line, and a Changelog table with ≥1 row.

- [ ] Applies to: `CLAUDE.md`, every `CLAUDE_*.md`, `DoD.md`, `ARCHITECTURE.md`, `GUARDRAILS.md` (when v12-02 ships), `README.md`, `PROJECT_INDEX.md`.
- [ ] Version follows semver (D1 from Knowledge-Layer Mega Plan).
- [ ] `tools/aegis-doc-canon/lint.mjs` passes on the full set.
- [ ] When a doc changes substantively, its version bumps and Changelog gets a new row in the same PR.

**Why.** Readers (humans + agents) need to know whether their mental model is current. Without versioning, doc drift is invisible.

---

## 8. Activity captured

**Bar.** Every tool invocation that mutates project state is captured in `.aegis/brain/activity/<date>.jsonl` (the v11-02 activity logger output).

- [ ] PostToolUse hook for `Bash` / `Edit` / `Write` / `MultiEdit` continues to fire `tools/aegis-activity-logger/log.mjs`.
- [ ] **(applicable when adding new tools)** If the new tool needs custom event emission beyond the default PostToolUse log, it writes a JSONL record to today's activity file.
- [ ] No tool silently mutates state without leaving an activity trace.

**Why.** Sprint v11 introduced 10 new moving parts. The activity log is the audit trail that lets a future operator (or a v12-05 graph query) reconstruct who-did-what.

---

## 9. Reversibility

**Bar.** Destructive operations (`rm -rf`, `git push --force`, `git reset --hard`, `DROP TABLE`) are gated by `tools/aegis-approval-gate` (sprint v11-05). No undocumented bypass paths.

- [ ] Gate rules in `.aegis/brain/gate-rules.yaml` cover the operation if it's destructive.
- [ ] Emergency bypass (`AEGIS_BYPASS=1`) is documented in `CLAUDE_safety.md`; usage is logged.
- [ ] **(applicable when adding new external-system writes)** Any new tool that mutates an external system (third-party API, downstream project, cloud resource) raises an entry in `.aegis/brain/human-queue.md` if it requires explicit human go.

**Why.** Risk R5 in Mega Plan v1.1. The cost of an unwanted destructive action vastly exceeds the cost of a gate. Reversibility is the last line of defense.

---

## How to add a new bar

1. The bar must be **repo-wide** (not sprint-specific) — if it only applies once, it belongs in a sprint plan.
2. State the bar in one sentence (what's true when this bar is satisfied).
3. List the checkbox sub-items that constitute evidence.
4. State the **Why** — what failure mode is this bar preventing? Reference the incident, sprint, or risk that surfaced it.
5. Bump the file version, add a Changelog row.

## See also

- `ARCHITECTURE.md` — the structural map that grounds the "where to change what" half of the DoD.
- `GUARDRAILS.md` (v12-02) — Sign-shaped catalog of recurring failure modes that this DoD prevents.
- `CLAUDE_lessons.md` — long-form patterns and anti-patterns; DoD bars are the executable summary.
- `.aegis/brain/sprints/roadmap.md` — sprint-by-sprint adherence to bar 6.
