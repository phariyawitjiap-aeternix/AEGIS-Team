<!-- version: 1.0.0 -->
<!-- Last updated: 2026-05-06 -->

Last reviewed: 2026-05-06

# AEGIS Guardrails

> **Sign-shaped catalog of recurring failure modes.** Each Sign is a 3-field record (Trigger / Do / Why) so it is actionable on first scan. Append-only as the same mistake repeats.
>
> Adapted from GitNexus's `GUARDRAILS.md` pattern. Source: AEGIS Knowledge-Layer Mega Plan v1.1 (sprint-v12-02).
>
> See `CLAUDE_lessons.md` for long-form patterns / anti-patterns / decision history; this file is the **quick-reference** surface.

## Changelog

| Date | Version | Change |
|------|---------|--------|
| 2026-05-06 | 1.0.0 | Initial GUARDRAILS authored as part of sprint-v12-02 (Knowledge-Layer Mega Plan Phase A). Migrated 12 Signs from CLAUDE_lessons / auto-memory / recent v11 PR fix-classes. |

---

## Scope

GUARDRAILS.md captures **recurring** failure modes that have surfaced ≥ 2 times. A one-off bug does not deserve a Sign — fix it in code and move on. A class of bug that keeps re-emerging deserves a structural recognition pattern, which is what a Sign is.

**Least-privilege principle.** Each Sign tells *just* what's needed: when to recognize it, what to do, and why. No more.

## Non-negotiables

These come **before** the Signs catalog because they apply universally:

- 🚫 **Never use `--force` flags on git** — Golden Rule #1.
- 🚫 **Never push to `main` / `master`** — branch + PR always. Golden Rule #2.
- 🚫 **Never `git commit --amend` in multi-agent workflows** — Golden Rule #3 (also a Sign below; the Sign explains the *why*).
- 🚫 **Never end a turn before agents finish** — false-ready guard. Golden Rule #4.
- 🚫 **Never present an option-menu to the human mid-task** — MBP rule. Golden Rule #7 (also a Sign below).
- 🚫 **Never skip hooks** with `--no-verify` or `--no-gpg-sign` unless the user explicitly says so.
- 🚫 **Never exfiltrate secrets** — see `CLAUDE_safety.md` §6 for the full list.

If a Sign below appears to override a non-negotiable, the non-negotiable wins.

---

## Signs

### Wired but not shipped

- **Trigger:** A new tool, hook, or skill is referenced from `.claude/settings.json`, an agent persona, or a SKILL.md, but the file at the referenced path doesn't exist or doesn't actually do the thing.
- **Do:** Run `node tools/aegis-doc-canon/lint.mjs` (or future `aegis-brain-graph query wiring <name>`) before declaring the work done. Verify every `command:` path in `settings.json` resolves to an existing executable file. Verify install scripts that *advertise* a delivery actually `cp`/`ln`/`mkdir` it.
- **Why:** Surfaced 4× in v11 (PR #105 / #108 / #114 / others). The bug class is a hook entry being added to settings.json but the script being absent — the user gets a silent no-op or a permission-prompt loop. Tighten the loop with a graph query that fails build if any wired path is missing.

### `set -e` + empty-array trap

- **Trigger:** A bash script with `set -euo pipefail` iterates over an array that may be empty (`for x in "${arr[@]}"`).
- **Do:** Guard with `[[ ${#arr[@]} -gt 0 ]] || continue` before iterating, OR set `set +u` for the iteration block, OR pre-declare the array with `arr=()`.
- **Why:** `set -u` plus `${arr[@]}` on an unset array exits the script with "unbound variable." Surfaced 3× in v11 pilot scripts (PR #107 made the empty-notes guard explicit). Prefer the `${#arr[@]}` length-check — it survives later refactors.

### `grep -c` double-print

- **Trigger:** A bash script does `count=$(grep -c PATTERN file)` then echoes `$count` somewhere.
- **Do:** Use `count=$(grep -c PATTERN file 2>/dev/null || true)` — the `|| true` keeps the count at 0 when grep returns non-zero (no matches), and prevents bash word-splitting from double-emitting the value.
- **Why:** Fixed 2× in v11 pilot signal-3 scripts. The bug is `grep -c` exits 1 when no match → `set -e` kills the script → the rescue path emits the count twice. Add the `|| true` to prevent both classes simultaneously.

### Node FIFO O_RDONLY EOF loop

- **Trigger:** A node script opens a named pipe (FIFO) with `fs.createReadStream(path)` and immediately gets EOF on a fresh process.
- **Do:** Open with `O_RDWR` (or open a writer first to keep the pipe alive) when reading from a FIFO that may not have a current writer. For aegis-live-tail's case: use `fs.openSync(path, fs.constants.O_RDONLY | fs.constants.O_NONBLOCK)`.
- **Why:** Fixed in PR #105 (live-tail watcher). A FIFO with no writer returns EOF immediately on read; the readline loop terminates and the watcher thinks the session ended. Persistent reader via O_NONBLOCK + a `.on("close", reopen)` recovers cleanly.

### Doc/reality skew

- **Trigger:** A document says "Status: Proposed" / "TODO" / "DEFERRED" / "Awaiting approval" but the work is already shipped (or rejected, or scope-changed).
- **Do:** Bump the doc's version header + Changelog row in the same PR that ships the work. If the doc lives outside the repo (e.g. `~/Documents/AEGIS-PLUS-MEGA-PLAN.md`), add a closing-note line with the sprint ID that delivered it.
- **Why:** Fixed 3× in v11. The mega plan's "Status: Proposed — pending Phase 1 kickoff" stayed there long after Phase 1 shipped. Readers (humans + agents) trust the doc; stale doc → wrong mental model → wasted re-discovery time.

### `git commit --amend` in multi-agent workflows

- **Trigger:** You're tempted to amend a commit because of a typo, a forgotten file, or a pre-commit hook that just failed.
- **Do:** Create a NEW commit instead. If a hook failed, fix the underlying issue, re-stage, commit fresh — the failed attempt did NOT actually create a commit, so `--amend` would mutate the *previous* commit (potentially destroying earlier work).
- **Why:** Golden Rule #3. In multi-agent workflows, Agent B may already hold a reference to commit hash X — Agent A's amend invalidates that reference and breaks the pipeline. CLAUDE_lessons A004 has the long-form rationale.

### `AskUserQuestion` option-menu (MBP violation)

- **Trigger:** You're about to end a response with "Options: A / B / C — what do you want?" or "Should I run X next? Y? Z?" or any tool call to `AskUserQuestion` from a non-Nick-Fury caller.
- **Do:** STOP. (1) If a decision is needed, send `QUESTION_TO_BRAIN` to Nick Fury per `.claude/references/context-rules.md`. (2) If Nick Fury is offline, make the best call from brain/instincts/ADRs and log via `tools/aegis-log-decision.sh --source judgment` with `--reasoning`. (3) Apply the chain in `.claude/references/command-chain.md`. Never "ask the human" as a fallback for the chain.
- **Why:** Golden Rule #7 — the most-violated AEGIS rule. Surfaced repeatedly in pre-v9 sessions; `guard-ask-user.sh` blocks tool-level violations now, but the *response-text* violation pattern still slips through. The right loop is: agent → judgment → log → continue, NOT agent → menu → human.

### Hook fail-CLOSED bug locks user out

- **Trigger:** Adding a new PostToolUse / PreToolUse / Stop / SessionStart hook that does any non-trivial work (parse, write, network, jq).
- **Do:** Wrap the body in a top-level try/catch (or `set +e` + explicit error trap). On any internal error: emit a one-line warning to stderr and `exit 0`. The ONE allowed exception is `aegis-approval-gate` (fail-CLOSED is its job — and that must be explicit in the script comment).
- **Why:** Mega Plan R6 + DoD §2. A hook crash that fails-CLOSED locks the user out of their own tool — they can't `Edit`, `Bash`, or `Stop` until they manually disable the hook. Cost of fail-OPEN: a missed event in the audit log. Cost of fail-CLOSED: workflow halt. The asymmetry is decisive.

### Policy without test

- **Trigger:** A CLAUDE_*.md / spec / SKILL.md says "MUST", "enforces", "auto-REJECTs", "blocks", or "rejects" something, but no hook / lint / test asserts the behavior.
- **Do:** Either (a) add the corresponding hook + assertion, OR (b) downgrade the prose to "should" / "convention" so the doc's strength matches its enforcement. Tightening the doc is cheap; tightening enforcement is the structural fix.
- **Why:** Auto-memory feedback (`feedback_policy_without_test.md`). The dominant bug class in pre-v9 AEGIS was rules that *claimed* enforcement without code to back it up. Sprint v9-06 introduced the `aegis-policy-audit.sh` scanner. DoD §5 makes the bar repo-wide.

### Doc-version vs framework-version conflation

- **Trigger:** A governance doc title contains a framework-version tag (e.g. `# AEGIS v11.0 -- Safety Rules`), and you're about to bump that tag because you edited the doc.
- **Do:** Treat the *title-version* as the **framework** version (changes when the framework version changes — rarely). Bump the doc's *own* version header (`<!-- version: 1.0.0 -->`) instead. The two evolve at different cadences.
- **Why:** Surfaced in sprint-v12-01. Conflating them either forces a framework version bump on every doc edit, or hides doc drift behind framework stability. Keeping them independent makes both legible.

### Lint missing empty-table case

- **Trigger:** Adding a new structural lint rule that checks for the *presence* of a section (e.g. `## Changelog`).
- **Do:** Cover the empty-table case explicitly. A markdown table with `| Date | Version | Change |` and a `|---|---|---|` separator but **no data rows** passes a naive `grep "## Changelog"` check while being functionally empty.
- **Why:** Surfaced in sprint-v12-01. The first draft of `aegis-doc-canon/lint.mjs` only checked the heading; the bug was caught in code review (self-) before it shipped, and the test suite picked it up at T6. Make this explicit so the next structural lint doesn't repeat the omission.

### Ask-after-explicit-go

- **Trigger:** The user said "approve" / "เอาให้ครบ" / "do it all" / "ship it" and you're considering asking a clarification before proceeding.
- **Do:** Don't. The "go" was the explicit decision; pausing IS the violation. If the request is genuinely ambiguous (e.g. multiple gates open simultaneously), pick the one most-recently discussed and act on it; surface the other(s) at the end of the response as separate items, NOT as questions.
- **Why:** Auto-memory feedback (`feedback_no_pause_after_go.md`). Asking after a go is the same MBP failure mode as the option-menu, just dressed up as helpfulness. The cost of guessing wrong is one redo; the cost of pausing is repeated friction the user has explicitly told you to stop creating.

---

## How to add a Sign

A new Sign should land when **the same class of bug repeats**. One-off bugs go in commit messages; classes go here.

**Interactive (preferred):**

```bash
node tools/aegis-doc-canon/add-sign.mjs
```

Prompts for: `title`, `trigger`, `do`, `why`. Validates all four are non-empty. Appends a section under `## Signs` and bumps the file's `<!-- version: -->` patch number + Changelog row.

**Non-interactive (for tests / scripts):**

```bash
node tools/aegis-doc-canon/add-sign.mjs \
  --non-interactive \
  --title "<short title>" \
  --trigger "<observable cue>" \
  --do "<the action>" \
  --why "<failure mode + incident>"
```

**Rules of thumb:**

- 1 Sign per class. If you find yourself adding a Sign that mostly overlaps an existing one, edit the existing one instead.
- Reference the incident in the **Why** field (PR #, sprint, date). Future readers need to know whether the lesson is fresh or ancient.
- Keep each field to 1–2 sentences. If you need a paragraph, you're writing a `CLAUDE_lessons.md` entry, not a Sign.

## See also

- `DoD.md` — repo-wide completion bars (Signs are the bug-class catalog; DoD bars are the repo-wide criteria they support).
- `ARCHITECTURE.md` — structural map of the codebase.
- `CLAUDE_lessons.md` — long-form patterns and anti-patterns. Signs are the executable summary.
- `CLAUDE_safety.md` — hard safety rules and incident-response procedures.
- `~/.claude/projects/-Users-phariyawit-jiap-Documents-AEGIS-Team/memory/MEMORY.md` — auto-memory feedback (often the seed for new Signs).
