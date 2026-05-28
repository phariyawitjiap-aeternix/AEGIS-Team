# AEGIS × SWE-bench Verified — 50-issue Prototype

Benchmarks the AEGIS agent workflow (claude -p under the user's subscription)
against SWE-bench Verified — 500 human-validated real GitHub issues. This
prototype runs the first 50 to validate harness + methodology before any
full run.

**No extra cost:** agent runs via `claude -p` on the existing Claude
subscription (no API key). The `total_cost_usd` in logs is a metered-equivalent
figure, not money out of pocket. Real constraints are rate limits + wall-clock.

## Layout

| File | Purpose |
|------|---------|
| `.venv313/` | Python 3.13 venv (swebench needs 3.10+; system Python is 3.9) |
| `fetch_dataset.py` | Pull SWE-bench Verified, dump first N → `subset.jsonl` |
| `subset.jsonl` | 50 instances (agent-visible fields only — no gold patch) |
| `run_agent.py` | For each issue: clone+checkout, run claude -p, capture diff → `predictions.jsonl` |
| `evaluate.sh` | Official swebench Docker eval on predictions → resolved/unresolved |
| `clones/` | Cached repo clones (gitignored, heavy) |
| `predictions.jsonl` | Agent output patches (gitignored) |

## Run (from your terminal — NOT inside a Claude Code session)

The agent loop uses `git reset --hard` + `git clean -fd` to reset cloned repos
between issues. Those are denied inside AEGIS sessions (safety), so run here:

```bash
cd ~/Documents/AEGIS-Team/_aegis-output/benchmarks/swe-bench

# 0. (one-time) dataset already fetched → subset.jsonl (50 instances)
#    re-fetch with: .venv313/bin/python fetch_dataset.py 50

# 1. Smoke test ONE instance first (~3-8 min: clone astropy + 1 claude run)
.venv313/bin/python run_agent.py --instance astropy__astropy-12907

# 2. If the smoke test produced a non-empty diff, run all 50
#    (~3-5 hr wall-clock; respects subscription rate limits)
.venv313/bin/python run_agent.py --limit 50

# 3. Start Docker Desktop, then score the predictions
open -a Docker        # wait until it's running
bash evaluate.sh
```

## What "good" looks like

- Smoke test: non-empty `model_patch` in predictions.jsonl for astropy-12907
- Full 50: a resolved/unresolved count from `evaluate.sh`
- Reference: SOTA on full Verified is ~80% (Claude Opus 4.5); 50-issue subset
  is for methodology validation, not a headline number. Python-heavy bias means
  AEGIS (polyglot) may score lower here than on real polyglot work.

## Notes

- `run_agent.py` is idempotent-ish: skips instances already in predictions.jsonl,
  so you can resume an interrupted run.
- `--max-turns 60` / `--session-timeout 1200` are tunable per the budget.
- Clones are cached by repo, so multiple django/sympy issues reuse one clone.
