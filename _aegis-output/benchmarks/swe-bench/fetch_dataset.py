#!/usr/bin/env python3
"""Fetch SWE-bench Verified and dump the first N instances to a JSONL subset.

Usage: python fetch_dataset.py [N]   (default N=50)

Each line is one instance with the fields the agent + harness need:
  instance_id, repo, base_commit, problem_statement, hints_text (if any).
The gold patch / test info stays in the dataset for the evaluation harness;
we only carry what the AGENT is allowed to see (no gold patch leakage).
"""
import json
import sys
from pathlib import Path

N = int(sys.argv[1]) if len(sys.argv) > 1 else 50
OUT = Path(__file__).parent / "subset.jsonl"

from datasets import load_dataset  # noqa: E402

print(f"Loading princeton-nlp/SWE-bench_Verified (test split)...", file=sys.stderr)
ds = load_dataset("princeton-nlp/SWE-bench_Verified", split="test")
print(f"Full set: {len(ds)} instances. Taking first {N}.", file=sys.stderr)

AGENT_FIELDS = ["instance_id", "repo", "base_commit", "problem_statement", "version"]

with OUT.open("w") as f:
    for i, row in enumerate(ds):
        if i >= N:
            break
        rec = {k: row.get(k, "") for k in AGENT_FIELDS}
        f.write(json.dumps(rec) + "\n")

print(f"Wrote {min(N, len(ds))} instances to {OUT}", file=sys.stderr)
