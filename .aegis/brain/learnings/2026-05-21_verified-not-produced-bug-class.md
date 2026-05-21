<!-- version: 1.0.0 -->
<!-- Last updated: 2026-05-21 -->

# 2026-05-21 — "Produced ≠ Verified" Bug Class + AEGIS Coverage Contract

> Cross-sprint learning capturing the meta-lesson from v15-18B → v15-19 → v15-20.
> Driver: Contra-Thai post-mortem (`Contra-Thai/_aegis-output/incidents/2026-05-20-research-report-llm-aegis-unity-verification-failure.md`) — 3 sprints of "100% velocity" produced zero playable artifact because the framework conflated `produced` with `verified`.

## The single biggest lesson AEGIS learned this round

**Stop measuring with the word "done". Measure with "verifiable evidence that it works."**

Every gate, every sub-agent return, every sprint close, every research output now must distinguish between:
- **`[PRODUCED]`** — the artifact exists (code written, tests authored, doc saved)
- **`[VERIFIED]`** — backed by an executed command whose output proves it

Before this round, AEGIS treated both as "done". The Contra-Thai session shipped 3,400 LOC + 73 unit tests + 36 commits + "100% velocity" Sprint 3 close.md — and the product never compiled in Unity Editor. That's the failure mode this learning catalogues.

## Origin: 5 framework gaps from the Contra-Thai research report

| ID | Description | Status after v15-19/20 |
|----|-------------|------------------------|
| F-A | Project-class declaration at init (text-runtime vs GUI-runtime) | ✅ v15-19 (`aegis-coverage-screen.sh`) |
| F-B | Playtest-result requirement at sprint close | ✅ v15-20 (`aegis-sprint-close-gate.sh`) |
| F-C | Sub-agent return tagging (`[VERIFIED]`/`[PRODUCED]`) | ✅ v15-20 (`aegis-return-validator.sh` + `skills/aegis-return-format.md`) |
| F-D | Unity asmdef cycle check | ⏭️ skipped (narrow Unity-only audience; F-A + F-B cover transitively) |
| F-E | Research-doc URL probe gate | ✅ v15-20 (`aegis-research-probe.sh`, Beast persona rule) |

**4/5 closed via enforced code** — not just memory rules. Closes [[policy-without-test]] for this surface.

## What changed structurally

### Coverage Contract (v15-19)

AEGIS now classifies every new project on day 1:
- ≥95% coverage (web/CLI/infra) → silent, proceed
- 50-94% (Unity/Xcode/mobile native/Editor-driven) → emit warning block listing every gap
- <50% (closed mobile, hardware-in-the-loop, taste calls) → recommend skip or stack swap

Soft gate (user choice 2026-05-21). Warning re-surfaces at every `/aegis-start` until user types `ack gaps`. Writes `.aegis/brain/state/coverage.json` schema `aegis-coverage-v1`.

### Verified vs Produced (v15-20)

Three gates close the inheritance chain that produced Contra-Thai's failure:

```
Sub-agent return → main agent → close.md → user
```

1. **Sub-agent tag rule (F-C)**: every non-trivial claim (counts, status booleans, closures, DONE/SHIPPED) must carry `[VERIFIED: <command>]` or `[PRODUCED: unverified]`. Untagged = default-treat-as-PRODUCED. Validator surfaces ratio.
2. **Sprint close gate (F-B)**: for coverage<100% projects, `/aegis-sprint close` Step 3.5 reads per-story `_aegis-output/playtests/S<NN>-<NN>.md`. Required keys: `verified_by`, `date`, `pass: true|false`, `notes`. Missing files surface in close.md.
3. **Research probe gate (F-E)**: every URL in a research doc must be probed via HEAD/OPTIONS. Tagged `[PROBED ✓]`, `[PROBED ✗]`, or `[UNPROBED]`. Beast persona forbidden from citing payload/schema from `[UNPROBED]` URLs.

## Why the simpler `verified-stories / committed-stories` metric is not enough

The research report proposed `verified / committed` as the velocity replacement. We implemented something stronger:

- **F-B** writes per-story playtest evidence to disk. The metric is computable as a side effect, but the evidence is the primary artifact. Re-readable in retro. Provenance preserved.
- **F-C** propagates the verified/produced distinction one layer deeper (sub-agent return), where the inheritance starts. A metric at sprint close alone wouldn't catch a sub-agent that returned "tests pass" from a static parse.

The metric IS produced by the gate (`bash tools/aegis-sprint-close-gate.sh report .` emits `verified=N/M coverage=XX%`) but the gate's primary purpose is to FORCE the playtest evidence to exist on disk.

## What this changes about how main agent works

Before today, when Spider-Man returned "Closes S03-02. 28 EditMode tests added. All quality checks pass" — main agent inherited the claim verbatim into close.md. Now:

1. **Validator surfaces the ratio.** A return with 0/3 tags = `UNTAGGED=100%` flags the validator → main re-prompts the sub-agent with the tagging rule reinforced.
2. **Each tag tells main agent what to trust.** `[VERIFIED: bash tests/foo.sh]` = trust the claim at face value (verify the cited command exists). `[PRODUCED: unverified]` = downstream code MUST NOT depend on this passing without separate verification.
3. **The chain doesn't lie anymore.** What appears in close.md is bounded by what was verified, not what was produced.

## What this changes about how AEGIS sells itself

CLAUDE.md's contract is now explicit: **AEGIS = 100% autonomy on (1) implementation + (2) verification, with human role limited to (a) requirements + (b) credentials**. Any project that breaks that contract MUST emit a warning at intake — not at sprint 3 retrospective.

This kills the "AEGIS for any project" oversell. AEGIS is now honest about what it can drive end-to-end vs. what becomes "code-suggestion infrastructure" (the report's term for Unity-AEGIS).

## Memories saved this session

| Slug | Purpose |
|---|---|
| [[aegis-coverage-contract]] | The 100% autonomy rule + warning-on-every-gap rule |
| [[plain-thai-voice]] | When user writes Thai, reply in everyday Thai readable by non-tech reader |

Both linked from `~/.claude/projects/.../memory/MEMORY.md`.

## Pattern this validates: "from memory to enforced code"

[[policy-without-test]] memory said:
> AEGIS rules claiming MUST/enforces/auto-REJECTs without matching hook/test/assertion code are the dominant bug class.

This round we applied that lesson recursively. The Contra-Thai report wrote rules. We didn't just save them as memories — we wrote tools + hooks + tests + persona docs. F-A/B/C/E are now enforceable by `bash` at the tool boundary, not by belief.

The next iteration of this pattern would be: scan AEGIS for OTHER memory rules that aren't enforced, and promote them to code in v15-21+.

## Open follow-ups

| Item | Sprint candidate |
|---|---|
| Hard ack gate (block sprint until gaps acknowledged) | v15-21 if soft proves ignored |
| Hook-level enforcement of sub-agent return tagging | v15-21 (PreToolUse on Task returns) |
| Auto-fire probe-gate on research-doc commits | v15-21 (PostToolUse hook) |
| Playtest result skeleton auto-creation at sprint plan | v15-22 |
| `runtime_helpers` array in install.sh → glob-discover | v15-22 (kill 2nd manifest-drift surface, parallel to v15-18A skill fix) |
| F-D (Unity asmdef cycle check) | deferred — transitively covered |

## Provenance

- Contra-Thai research report: `Contra-Thai/_aegis-output/incidents/2026-05-20-research-report-llm-aegis-unity-verification-failure.md`
- Sprint v15-19 plan + kanban: `.aegis/brain/sprints/sprint-v15-19-coverage-screen/`
- Sprint v15-20 plan + kanban: `.aegis/brain/sprints/sprint-v15-20-verified-not-produced/`
- PRs: #191 (v15-19), #192 (v15-20)
- Test counts at end: 67/67 PASS standalone in 140s; 39 skills installed via frontmatter auto-discovery
- Downstream sync: 8 projects (Auto-Affi, Contra-Thai, DriveWiki-MCP, GenGoogleForm, JingJai, RizzLab, kam-tong-ham, new-project-99) all received v15-19 + v15-20 tools post-merge
