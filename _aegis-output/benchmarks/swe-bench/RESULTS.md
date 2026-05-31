# SWE-bench Verified — Results

**Agent run:** `claude -p` (Claude Opus 4.8, subscription) via the minimal
`run_agent.py` harness. **Eval:** official swebench harness on x86_64 GitHub
Actions. Dates: agent run 2026-05-28→31, full-500 eval scored 2026-05-31.

## Headline — FULL 500 (VERIFIED)

**429 / 500 resolved = 85.8%** on the complete SWE-bench Verified set.
Scored by the official harness across 10 parallel x86 jobs (batched eval,
run 26701402710); verified by summing all 10 chunk reports.

- resolved 429 / completed 485 / submitted 500
- 15 instances did not complete the eval (env-build/harness errors) and are
  counted as UNRESOLVED in the 429/500 figure (conservative denominator).
- Consistency check: chunk-0 (first 50) scored 37/50 — exactly reproducing the
  earlier standalone first-50 eval. The harness is behaving correctly.

### ⚠️ What this number actually measures (read before quoting it)

- **It is Opus 4.8's raw coding capability through a THIN harness — not AEGIS
  orchestration.** `run_agent.py` is just "make the minimal fix, don't write
  tests" + `claude -p`. It does NOT use the AEGIS personas, quality gate, MBP,
  brain, or decision audit. So 85.8% reflects the MODEL via a simple wrapper,
  not AEGIS's multi-agent value-add.
- AEGIS's actual differentiation (trust / enforcement / audit) is about
  *reliability and verifiability*, not raw solve rate. This benchmark does not
  measure that.
- 85.8% sits at/above the SOTA references in our research (Opus 4.5 ~80.9%,
  Claude Code 80.8%) — plausible since this runs the newer Opus 4.8, but treat
  the gap cautiously: different model generation, and 15 eval-incompletes were
  counted against us (a stricter denominator than some leaderboards use).
- The 15 incomplete instances could be re-run to firm up the denominator;
  429/500 is the conservative number recorded without that.

## Earlier milestone — first-50 subset (VERIFIED)

37 / 50 resolved on the first 50 (astropy 16/22, django 21/28) — the
validation run before scaling to 500. Report: `reports/full-50-report.json`.
This is chunk-0 of the full run and reproduced exactly in the batched eval.

## Outcome

| Item | Status | Evidence |
|------|--------|----------|
| Agent generated patches | ✅ **VERIFIED** | 50/50 instances, 0 empty patches — `predictions.jsonl` |
| Patch quality (surgical, on-target) | ✅ **VERIFIED by inspection** | django-10999 (negative-duration regex), astropy-7336 (None return annotation), django-11292 (--skip-checks across code + docs) match known gold-fix shapes |
| Resolved/unresolved score | ✅ **VERIFIED** | 37/50 resolved — x86 GH Actions eval, `reports/full-50-report.json` |
| ~~Local arm64 eval~~ | ❌ superseded | Docker eval hung at 0/50 on Apple Silicon; moved to x86 GH Actions (`.github/workflows/swe-bench-eval.yml`) — that scored fine |

## Agent run stats

- 50/50 instances produced a non-empty patch
- Patch size: min 485b, median 835b, max 11808b
- Multi-file patches: 6 (e.g. django-11138 = 4 files, django-11292 = code+docs)
- One claude-code auto-update mid-run (15:36) crashed the loop at 27/50;
  fixed (absolute CLAUDE_BIN + retry on FileNotFoundError), resumed cleanly.

## Why scoring is blocked (NOT an AEGIS issue)

The official SWE-bench evaluation harness builds/pulls **x86_64** Docker images
per instance. This machine is **arm64 (Apple Silicon)**. The eval process hung:
- 10 min at 0/50, 0.0% CPU, no swebench images built, no child build processes
- Silent block (no error) — the known SWE-bench-on-Apple-Silicon limitation

This is an **infrastructure constraint**, not an agent-capability constraint.
The agent (AEGIS) did its job — generate fixes. The scoring needs x86 infra.

## To get a real score

Run the eval on an **x86_64 Linux** box (cloud VM) where swebench images
pull natively:

```bash
# on x86_64 Linux with Docker:
cd swe-bench
.venv313/bin/python -m pip install swebench datasets
# copy predictions.jsonl over, then:
bash evaluate.sh aegis-proto-50
```

`predictions.jsonl` (the 50 patches) is the portable artifact — carry it to
any x86 box to score. The agent run does NOT need to be repeated.

## Honest takeaway

The prototype proved the **harness + agent loop work end-to-end** and that the
AEGIS workflow produces surgical, plausible fixes for real GitHub issues across
two large codebases. The headline pass-rate number remains pending an x86 eval
run. Per AEGIS honesty contract: claims above are tagged VERIFIED (ran/inspected)
vs BLOCKED (could not execute) — no pass-rate is asserted without the eval.
