# Sprint v15-22 — Claude Agents CLI Integration (Cross-Session Awareness)

> Bring AEGIS up to speed with Claude Code 2.1.148's `claude agents` CLI.
> Currently AEGIS uses `.claude/agents/*.md` (persona files dispatched via
> `Task` tool) but doesn't touch the `claude agents` *process-management*
> facility — the CLI that lists live CC sessions across all projects, lets
> you dispatch background sessions with per-task config overrides, and
> exposes everything as JSON for scripting.
>
> Driver: user observation 2026-05-22 — "AEGIS ใช้ความสามารถของ claude agents ได้มั้ย?"
> Honest answer: partially. AEGIS has 11 persona subagents but is blind to
> cross-project session state. Two open CC sessions exist right now
> (AEGIS-Team busy, GenGoogleForm idle) and AEGIS has no awareness of either.

## Scope: observability layer first

This sprint focuses on **observability** — making AEGIS aware of cross-session
state. The next sprint (v15-23) tackles **active dispatch** — letting AEGIS spawn
background `claude agents` sessions for long-running work (Beast research,
Spider-Man big builds). Split because dispatch needs the observability layer
to be solid first.

## Architecture (one diagram)

```mermaid
flowchart TB
    classDef new fill:#dbeafe,stroke:#2563eb,color:#000
    classDef ext fill:#dcfce7,stroke:#16a34a,color:#000

    CCC[claude agents --json<br/>CC 2.1.148 CLI]
    CCC --> WRAP[tools/aegis-claude-agents.sh<br/>thin wrapper + cwd filter + caching]:::new

    REG[(.aegis/brain/multi-tenant/<br/>registry.yaml)]
    WRAP --> MT[tools/aegis-multi-tenant/mt.mjs<br/>NEW: sessions subcommand]:::ext
    REG --> MT
    MT --> MAP[Merged view:<br/>registered project × live session]

    MAP --> S1[/aegis-start<br/>Step 2.4 NEW: cross-session warning/]:::ext
    MAP --> S2[/aegis-status<br/>NEW: cross-project session map/]:::ext
    MAP --> S3[/aegis-handoff<br/>NEW: warn on race risk/]:::ext

    classDef warn fill:#fef3c7,stroke:#d97706
    S1 --> W[Output: "⚠️ คุณมี idle CC session ที่<br/>DriveWiki-MCP 3 ชม. แล้ว — ลืม /aegis-handoff?"]:::warn
    S2 --> W
```

## Stories

| Story | Pts | Description |
|---|---|---|
| **A — `tools/aegis-claude-agents.sh`** | 1 | Thin bash wrapper around `claude agents --json`. Subcommands: `list` (all sessions, human-readable), `list --json` (raw), `where <project-name>` (path of a registered project's live session if any), `filter --cwd <path>` (sessions under that path). 1-second cache to avoid spamming the CLI in tight loops. Soft-fails to empty array if `claude` not on PATH (CI env compat). |
| **B — `mt.mjs sessions` subcommand** | 1 | Extend the multi-tenant CLI: `node tools/aegis-multi-tenant/mt.mjs sessions` merges the registry with `claude agents --json` output and prints a table — project name, path, version, session status (busy/idle/none), session age. `--json` flag for scripting. |
| **C — `/aegis-start` cross-session warning** | 1 | New Step 2.4 in `.claude/commands/aegis-start.md`: query other live sessions (excluding self via `CLAUDE_SESSION_ID`). Warn if: (a) another session on same cwd exists (race risk on brain writes), (b) idle session > 1h exists at any registered project (forgotten /aegis-handoff). Soft warning, not block. |
| **D — `/aegis-status` cross-project map** | 1 | Extend `.claude/commands/aegis-status.md` to print a "Cross-project sessions" section using `mt sessions`. Shows what else is running where, so the user gets a global view from any project. |
| **E — Tests** | 1 | `tests/aegis-claude-agents-test.sh` × 6: wrapper subcommands, JSON schema, cwd filter, caching, fallback when `claude` missing, soft fail. Plus `tests/aegis-mt-sessions-test.sh` × 4: registry merge correctness, session attribution to right project, JSON output schema, no-session case. |

**Total: 5 pt**

## Acceptance criteria

- [ ] `bash tools/aegis-claude-agents.sh list` shows live sessions in human-readable form
- [ ] `bash tools/aegis-claude-agents.sh list --json` returns the raw `claude agents --json` array (or `[]` if `claude` missing)
- [ ] `node tools/aegis-multi-tenant/mt.mjs sessions` shows a merged table of registered projects + their session state
- [ ] `/aegis-start` warns about other live sessions when relevant (race risk + idle handoff candidates)
- [ ] `/aegis-status` shows cross-project session map as a new section
- [ ] All 10 new tests green standalone
- [ ] Full suite green
- [ ] `claude` not on PATH → all subcommands fall back gracefully (CI env compat)
- [ ] Self-session excluded from warnings (uses `CLAUDE_SESSION_ID` env)

## Why split observability from dispatch (v15-22 vs v15-23)

| Aspect | v15-22 (this sprint) | v15-23 (next sprint candidate) |
|---|---|---|
| Surface | read-only (`claude agents --json`) | dispatch (`claude agents [opts]` spawn) |
| Risk | low — observe only | medium — spawning external processes, needs PID tracking, cleanup, error capture |
| User-visible payoff | "AEGIS knows what's happening" | "AEGIS can offload heavy work without blocking conversation" |
| Persona impact | Nick Fury gains awareness | Beast / Spider-Man gain background dispatch |
| Test burden | mock `claude agents --json` output | mock full process spawn + capture lifecycle |

The observability layer is the dependency for sane dispatch — you can't safely
spawn background sessions if you don't know what's already running. So
v15-22 first.

## Soft-gate philosophy (consistent with v15-19/20/21)

All warnings are soft. `/aegis-start` warns but proceeds. `/aegis-handoff` warns
on race risk but doesn't block. Reasoning: the user is the only one who can
decide whether two parallel sessions are intentional (e.g., A/B comparison)
or a mistake.

## What this does NOT do (deferred)

- **Background dispatch** (v15-23+) — actually spawning a `claude agents`
  session for long-running work
- **Inter-session messaging** — sessions sharing state mid-flight
  (relies on dispatch first)
- **Auto-handoff of stale sessions** — auto-`/aegis-handoff` on idle > N hours
  (could be heavy-handed; deferred until soft warning proves insufficient)
- **MCP / plugin per-session profiles** — the `--mcp-config` / `--plugin-dir`
  flags of `claude agents` (out of scope; useful but no immediate AEGIS pain)

## Closes / follow-ups

- Opens: cross-session awareness gap surfaced by 2026-05-22 user question
- Closes: nothing direct (this is feature work, not bug-fix)
- Carries to v15-23: background dispatch helper for personas

## Test plan summary

```text
tests/aegis-claude-agents-test.sh           — 6 cases (wrapper)
tests/aegis-mt-sessions-test.sh             — 4 cases (multi-tenant extension)
                                            10 total new cases
Full suite expected: 68 → 78 tests
```

## Recursive validation

After this sprint lands, AEGIS-Team's own `/aegis-start` will start surfacing
the existing GenGoogleForm idle session as the first real "cross-session
warning" — that's the smoke-test of the observability layer working.
