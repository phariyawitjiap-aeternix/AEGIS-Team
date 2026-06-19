# AEGIS-Team — Agent Operating Manual

<!-- AEGIS v15.1.0 — AI Agent Team Framework (version banner — governance-enforced by aegis-version-consistency-test) -->

> This README is written for an AI agent (Claude Code) that will **install** or
> **operate** AEGIS. It is optimized for machine comprehension, not human
> marketing. Every fact below is current as of the repo HEAD; if a number here
> disagrees with the code, the code wins — verify with `tools/aegis-doctor.sh`.

## What AEGIS is (and is not)

AEGIS is a **governance + orchestration layer installed as project files** on top
of Claude Code. The Claude Code engine reads these files; AEGIS is not a separate
binary and does **not** make the model smarter.

- **It adds:** hook-enforced guardrails, a persistent brain (cross-session
  memory + decision audit), 11 specialized agent personas, honesty/verification
  contracts, sprint/ISO-29110 structure, and non-stop execution wrappers.
- **It does NOT add:** any new model capability. Same Opus 4.8 underneath.
- **It cannot:** control the OS GUI / mouse / screen, drive the Unity Editor, or
  automate other desktop apps. Browser control is only available if the
  Playwright MCP is separately installed. **Do not claim otherwise.**

---

## INSTALL / UPDATE — copy-paste a prompt into Claude Code

The fastest path: open Claude Code **inside the project you want AEGIS in**, then
paste one of the prompts below. The agent does the rest — no manual shell steps.

### ▶ Copy-paste prompt — NEW INSTALL

```text
Install the AEGIS-Team framework into THIS project. Do it yourself — run the
commands, don't ask me to. Then verify and report honestly.

1. Fetch the framework (public repo, no auth):
   curl -fsSL https://github.com/phariyawitjiap-aeternix/AEGIS-Team/archive/refs/heads/main.tar.gz -o /tmp/aegis.tgz
   mkdir -p /tmp/aegis-installer
   tar -xzf /tmp/aegis.tgz -C /tmp/aegis-installer --strip-components=1
2. If this is not a git repo yet: git init && git commit --allow-empty -m init
3. Install (basename of cwd = project name; profile = standard):
   /tmp/aegis-installer/install.sh --target-dir "$(pwd)" --project-name "$(basename "$(pwd)")" --profile standard
4. Verify — show me the real output; do NOT claim success unless it is green:
   bash tools/aegis-doctor.sh
5. Clean up: rm -rf /tmp/aegis-installer /tmp/aegis.tgz
6. Tell me to restart the Claude Code session, then run /aegis-start.

Profiles if I ask to change: minimal (small/throwaway) · standard (default) ·
full (enterprise SDLC + ISO). Prereq: node + @anthropic-ai/claude-code on PATH.
```

### ▶ Copy-paste prompt — UPDATE / UPGRADE an existing install

```text
Upgrade the AEGIS-Team framework in THIS project to the latest version. Do it
yourself. My .aegis/brain/ and my own project files must NOT be touched.

1. Fetch the latest framework:
   curl -fsSL https://github.com/phariyawitjiap-aeternix/AEGIS-Team/archive/refs/heads/main.tar.gz -o /tmp/aegis.tgz
   mkdir -p /tmp/aegis-installer
   tar -xzf /tmp/aegis.tgz -C /tmp/aegis-installer --strip-components=1
2. Upgrade in place (backs up .aegis/brain/, sweeps stale framework files via
   .aegis/.framework-manifest — never deletes project-owned files):
   /tmp/aegis-installer/install.sh --target-dir "$(pwd)" --upgrade
   (Add --clean for a clean-slate upgrade that also removes renamed/dropped
   framework files, leaving no orphans. brain + my files still untouched.)
3. Verify — show real output, don't claim success unless green:
   bash tools/aegis-doctor.sh
4. Clean up: rm -rf /tmp/aegis-installer /tmp/aegis.tgz
5. Tell me to restart the Claude Code session.
```

### Underlying recipe (what those prompts execute)

```bash
# Fetch + extract (public repo, no auth)
curl -fsSL https://github.com/phariyawitjiap-aeternix/AEGIS-Team/archive/refs/heads/main.tar.gz -o /tmp/aegis.tgz
mkdir -p /tmp/aegis-installer
tar -xzf /tmp/aegis.tgz -C /tmp/aegis-installer --strip-components=1

# NEW install:
/tmp/aegis-installer/install.sh --target-dir "$(pwd)" --project-name "$(basename "$(pwd)")" --profile standard
# OR UPGRADE in place (preserves .aegis/brain/):
/tmp/aegis-installer/install.sh --target-dir "$(pwd)" --upgrade   # add --clean to drop orphaned framework files

bash tools/aegis-doctor.sh              # VERIFY — must be green
rm -rf /tmp/aegis-installer /tmp/aegis.tgz
```

- **Profiles:** `minimal` (small/throwaway) · `standard` (default) · `full` (enterprise SDLC + ISO).
- **Prereqs:** `node` + `@anthropic-ai/claude-code` on PATH; the project should be a git repo (`git init && git commit --allow-empty -m init` if not).
- **What upgrade preserves:** `.aegis/brain/` (cross-session memory) and all project-owned files are **never** touched; only manifest-tracked framework files are swept. `--clean` additionally removes framework files that were renamed/dropped between versions.
- **After install/upgrade:** the hooks in `.claude/settings.json` load at **session start**. Restart the Claude Code session, then run `/aegis-start`.
- **Honesty gate:** if `install.sh` or `aegis-doctor.sh` errors, show the real output. Do **not** claim a working install unless `aegis-doctor.sh` is green.

---

## OPERATE — entry point

```text
/aegis-start
```

This is the only command a human needs. It loads the brain, activates **Nick
Fury** (the autonomous controller), scans project state, and begins executing
per the Decision Matrix (P0–P10) without further human input. End a session with
`/aegis-handoff` (saves a resume brief) or `/aegis-retro`.

---

## RULES YOU MUST FOLLOW (hook-enforced — you WILL be blocked)

These are not suggestions. The Stop and PreToolUse hooks block violations.

1. **MBP (Master Brain Protocol).** Never end a turn by asking the human a
   decision you can make yourself. **No** option menus ("A/B/C — what do you
   want?"). **No** unnecessary confirmations ("commit มั้ย?", "should I push?",
   "want me to build?"). If the next step is obvious (commit / push / build /
   test / deploy), **just do it**. Enforced by `on-stop.sh` → `mbp-scan.sh`
   (5 pattern rounds, EN + Thai).
2. **Honesty — separate PRODUCED from VERIFIED.** PRODUCED = an artifact exists.
   VERIFIED = you ran the command that proves it correct. Never attach ✅ / "done"
   / "complete" to unverified work. State the weaker true claim. (Global rule in
   `~/.claude/CLAUDE.md` + `aegis-return-validator.sh`.)
3. **Git safety.** Never push to `main` (branch + PR always). Never `--force`.
   Never `git commit --amend`. Catastrophic `rm -rf /` `~` `.` `..` are
   hard-denied. Other destructive ops (`git reset --hard`, `git clean -f`,
   `drop table`, `dd of=/dev/*`, `sudo rm`, etc.) require an approval marker via
   `aegis-approval-gate`.
4. **Only 4 things ever reach the human:** Identity · Irreversible-scope ·
   External-access · Explicit-approval-gate. For these, append to
   `.aegis/brain/human-queue.md` (via `tools/aegis-queue-human.sh`) and
   **continue** with everything else. Everything operational is your call —
   route uncertainty through Nick Fury / the Decision Matrix, not the human.

---

## COMMAND SURFACE (16 canonical)

| Command | Purpose |
|---|---|
| `/aegis-start` | Begin session; Nick Fury scans + decides + executes |
| `/aegis-status` | Health snapshot (agents, tasks, progress) |
| `/aegis-mode` | Switch profile / autonomy level |
| `/aegis-handoff` | Save resume brief for the next session |
| `/aegis-upgrade` | Framework upgrade (install.sh --upgrade) |
| `/aegis-sprint` | Sprint lifecycle: plan/standup/review/retro/close |
| `/aegis-breakdown` | Story → epics → tasks → subtasks |
| `/aegis-pipeline` | Full analysis pipeline (--qa, --flow) |
| `/aegis-team` | Spawn a team (build / review / debate) |
| `/aegis-verify` | Verification pipeline (tests, lint, security) |
| `/aegis-deploy` | Deploy pipeline (gated on human approval) |
| `/aegis-retro` | Retrospective + lessons |
| `/aegis-memory` | Brain read/write/recall |
| `/aegis-linear` | One-way kanban → Linear mirror |
| `/aegis-goal` | Set explicit completion condition |
| `/aegis-decisions` | Query the decision-audit log |

---

## NON-STOP EXECUTION (run from a plain terminal, NOT nested in a GUI session)

| Tool | Behavior |
|---|---|
| `tools/aegis-autopilot.sh` | Headless loop: repeats `claude -p` sessions, resumes from handoff, stops on project-complete / stall (git-diff delta) / iteration cap / interrupt. Default: no budget cap (subscription), `--max-iterations N`, `--verbose` for stdout logs. **Terminal-only** — needs the `claude` CLI; not runnable from inside the Claude Desktop GUI. |
| `tools/aegis-daemon.sh` | Opens the Claude Code TUI in a loop, auto-restarts when a session ends. **Terminal-only** — runs the CLI binary; not available inside the Claude Desktop GUI. |
| `tools/aegis-quality-gate.sh` | review + test + spec-compliance → PASS/FAIL verdict before a task is marked DONE (`--parallel`). |
| `tools/aegis-checkpoint.sh` | Structured state snapshot (lossless resume, complements the markdown handoff). |

These long-running loops are tied to the process that launches them — run them in
a standalone terminal so they survive a closed GUI session. Predictions/outputs
are written incrementally; re-running the same command resumes.

---

## CAPABILITIES & LIMITS (do not over-claim)

| Can do | Cannot do |
|---|---|
| Write/edit code, run shell, git, tests | Control OS GUI / mouse / screen |
| Backend / web / API / data / CLI work | Drive the Unity Editor (scene/prefab/play-test) |
| Multi-agent orchestration, planning | Desktop automation of other apps |
| Browser automation **iff** Playwright MCP installed | "Claude for Chrome" (separate product) |

---

## BENCHMARK (verified, with honest scope)

**SWE-bench Verified: 429/500 resolved (85.8%)** — official harness, 10 parallel
x86 jobs, summed from chunk reports. Details + reproducibility:
[`_aegis-output/benchmarks/swe-bench/RESULTS.md`](_aegis-output/benchmarks/swe-bench/RESULTS.md).

**This measures Opus 4.8's raw capability through a thin harness**
(`run_agent.py` = minimal-fix prompt + `claude -p`). It does **not** exercise
AEGIS's personas, quality gate, MBP, or brain. Do **not** cite it as "AEGIS's
solve rate." AEGIS's value is trust/enforcement/audit, which this does not score.

---

## LAYOUT (where things live)

```text
<project>/
├── CLAUDE.md              # hub, loaded every session (golden rules + protocol)
├── CLAUDE_{safety,agents,skills,lessons}.md
├── ARCHITECTURE.md        # concern→file map + hook DAG
├── PROJECT_INDEX.md       # auto-generated knowledge-graph wiki
├── .claude/
│   ├── settings.json      # permissions (defaultMode: acceptEdits) + hook wiring (16 hooks)
│   ├── hooks/             # guard-bash, guard-write, guard-ask-user, on-stop(mbp-scan), session-start, ...
│   ├── agents/            # 11 personas (model pins: opus-4-8 / sonnet-4-6 / haiku-4-5)
│   └── commands/          # 16 canonical slash commands
├── skills/                # 38 skill definitions
├── tools/                 # 60+ helper scripts (aegis-*.sh) + tool packages
└── .aegis/brain/          # persistent memory — NEVER overwritten by upgrade
    ├── resonance/ learnings/ retrospectives/ handoffs/ sprints/ instincts/
    ├── human-queue.md     # the 4 escalation categories
    ├── gate-rules.yaml    # approval-gate destructive patterns
    └── logs/ state/ graph/ (gitignored)
```

## AGENTS (11)

`Nick Fury` (opus-4-8, controller) · `Captain America` (opus-4-8, lead) ·
`Iron Man` (opus-4-8, architect) · `Loki` (opus-4-8, adversarial) ·
`Spider-Man` (sonnet-4-6, implementer) · `Black Panther` (sonnet-4-6, reviewer) ·
`War Machine` (sonnet-4-6, QA) · `Thor` (sonnet-4-6, devops) ·
`Wasp` (sonnet-4-6, UX) · `Beast` (haiku-4-5, scanner) ·
`Coulson` (haiku-4-5, ISO compliance).

## PROFILES

`minimal` · `standard` (default) · `full`. Switch with `/aegis-mode`.

---

## Reference (for deeper context)

- `CLAUDE.md` — golden rules, MBP, decision matrix, protocol (read at session start)
- `ARCHITECTURE.md` — how hooks/brain/skills wire together
- `PROJECT_INDEX.md` — auto-generated graph of every doc/skill/tool/test
- Version history: `git log` + `docs/releases/`. Latest milestone (v15-28):
  SWE-bench benchmark, non-stop execution, quality gate, native-tune.

## License & Credits

MIT (`LICENSE`). Oracle Brain: Nat Weerawan / Soul-Brews-Studio. Agent Teams:
Anthropic.
