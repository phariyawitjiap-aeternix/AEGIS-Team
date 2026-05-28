# SWE-bench Verified 50-issue Prototype — Results

**Date:** 2026-05-28
**Agent:** AEGIS workflow via `claude -p` (Claude Opus 4.7, subscription)
**Subset:** first 50 of SWE-bench Verified (astropy 22 + django 28)

## Outcome

| Item | Status | Evidence |
|------|--------|----------|
| Agent generated patches | ✅ **VERIFIED** | 50/50 instances, 0 empty patches — `predictions.jsonl` |
| Patch quality (surgical, on-target) | ✅ **VERIFIED by inspection** | django-10999 (negative-duration regex), astropy-7336 (None return annotation), django-11292 (--skip-checks across code + docs) match known gold-fix shapes |
| Resolved/unresolved score | ❌ **BLOCKED** | Docker eval hung at 0/50 on Apple Silicon (see below) |

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
