#!/usr/bin/env python3
"""AEGIS agent bridge for SWE-bench.

For each instance in subset.jsonl:
  1. Clone (cached) the repo, checkout base_commit in a clean state
  2. Run `claude -p` with the problem statement (acceptEdits, bounded turns)
  3. `git diff` the working tree -> the model_patch
  4. Append {instance_id, model_name_or_path, model_patch} to predictions.jsonl

Runs against the user's Claude subscription via `claude -p` (no API key, no
extra cost — draws from the same quota as autopilot).

Usage:
  python run_agent.py --instance astropy__astropy-12907   # one (smoke test)
  python run_agent.py --limit 50                          # first 50
  python run_agent.py --limit 50 --max-turns 60           # tune budget/turns

Idempotent-ish: skips instances already present in predictions.jsonl.
"""
import argparse
import json
import subprocess
import sys
import time
from pathlib import Path

HERE = Path(__file__).parent
SUBSET = HERE / "subset.jsonl"
CLONES = HERE / "clones"
PREDICTIONS = HERE / "predictions.jsonl"
MODEL_NAME = "aegis-claude-opus-4-7"

PROMPT_TEMPLATE = """You are fixing a real bug in the {repo} repository.

Below is a GitHub issue. Make the MINIMAL code change that resolves it.
Do not write tests — the project's existing test suite will verify your fix.
Do not touch unrelated files. Edit only what the fix requires.

--- ISSUE ---
{problem}
--- END ISSUE ---

Work directly in the current directory. When done, stop — your file edits
are the deliverable. Do not commit; the harness captures your diff."""


def run(cmd, cwd=None, timeout=None, check=False):
    return subprocess.run(
        cmd, cwd=cwd, timeout=timeout, check=check,
        capture_output=True, text=True,
    )


def load_subset():
    with SUBSET.open() as f:
        return [json.loads(line) for line in f if line.strip()]


def already_done():
    done = set()
    if PREDICTIONS.exists():
        with PREDICTIONS.open() as f:
            for line in f:
                if line.strip():
                    done.add(json.loads(line)["instance_id"])
    return done


def ensure_clone(repo):
    """Clone repo once into CLONES/<org__name>, return path."""
    safe = repo.replace("/", "__")
    dest = CLONES / safe
    if not dest.exists():
        CLONES.mkdir(parents=True, exist_ok=True)
        print(f"  cloning {repo} ...", file=sys.stderr)
        r = run(["git", "clone", "--quiet", f"https://github.com/{repo}.git", str(dest)], timeout=600)
        if r.returncode != 0:
            print(f"  clone failed: {r.stderr[:200]}", file=sys.stderr)
            return None
    return dest


def reset_repo(repo_dir, base_commit):
    run(["git", "reset", "--hard", "--quiet"], cwd=repo_dir)
    run(["git", "clean", "-fdq"], cwd=repo_dir)
    r = run(["git", "checkout", "--quiet", base_commit], cwd=repo_dir)
    if r.returncode != 0:
        # fetch the specific commit then retry
        run(["git", "fetch", "--quiet", "origin", base_commit], cwd=repo_dir, timeout=300)
        r = run(["git", "checkout", "--quiet", base_commit], cwd=repo_dir)
    return r.returncode == 0


def run_agent_on(inst, max_turns, session_timeout):
    repo = inst["repo"]
    repo_dir = ensure_clone(repo)
    if not repo_dir:
        return None
    if not reset_repo(repo_dir, inst["base_commit"]):
        print(f"  checkout {inst['base_commit'][:8]} failed", file=sys.stderr)
        return None

    prompt = PROMPT_TEMPLATE.format(repo=repo, problem=inst["problem_statement"])
    cmd = [
        "claude", "-p", prompt,
        "--permission-mode", "acceptEdits",
        "--max-turns", str(max_turns),
        "--output-format", "json",
    ]
    t0 = time.time()
    try:
        r = run(cmd, cwd=repo_dir, timeout=session_timeout)
    except subprocess.TimeoutExpired:
        print(f"  claude timed out after {session_timeout}s", file=sys.stderr)
        # still capture whatever diff exists
        r = None
    dt = time.time() - t0

    diff = run(["git", "diff"], cwd=repo_dir).stdout
    cost = "?"
    if r and r.stdout:
        try:
            cost = json.loads(r.stdout.strip().splitlines()[-1]).get("total_cost_usd", "?")
        except Exception:
            pass
    print(f"  done in {dt:.0f}s | diff {len(diff)} bytes | cost(metered) ${cost}", file=sys.stderr)
    return diff


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--instance", help="run a single instance_id")
    ap.add_argument("--limit", type=int, default=50)
    ap.add_argument("--max-turns", type=int, default=60)
    ap.add_argument("--session-timeout", type=int, default=1200)
    args = ap.parse_args()

    subset = load_subset()
    done = already_done()

    if args.instance:
        subset = [x for x in subset if x["instance_id"] == args.instance]
        if not subset:
            print(f"instance {args.instance} not in subset", file=sys.stderr)
            sys.exit(1)
    else:
        subset = subset[: args.limit]

    PREDICTIONS.parent.mkdir(parents=True, exist_ok=True)
    n_run = 0
    for inst in subset:
        iid = inst["instance_id"]
        if iid in done:
            print(f"[skip] {iid} (already in predictions)", file=sys.stderr)
            continue
        print(f"[run] {iid}", file=sys.stderr)
        diff = run_agent_on(inst, args.max_turns, args.session_timeout)
        if diff is None:
            diff = ""
        with PREDICTIONS.open("a") as f:
            f.write(json.dumps({
                "instance_id": iid,
                "model_name_or_path": MODEL_NAME,
                "model_patch": diff,
            }) + "\n")
        n_run += 1

    print(f"Ran {n_run} instance(s). Predictions -> {PREDICTIONS}", file=sys.stderr)


if __name__ == "__main__":
    main()
