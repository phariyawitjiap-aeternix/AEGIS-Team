#!/usr/bin/env bash
# Run the official SWE-bench evaluation harness on predictions.jsonl.
# Requires Docker running (per-issue containers) + the py3.13 venv.
#
# Usage: bash evaluate.sh [run_id]
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PY="$HERE/.venv313/bin/python"
RUN_ID="${1:-aegis-proto-$(date +%Y%m%d-%H%M%S)}"

[[ -f "$HERE/predictions.jsonl" ]] || { echo "No predictions.jsonl — run run_agent.py first."; exit 1; }
docker info &>/dev/null || { echo "Docker not running. Start Docker Desktop first."; exit 1; }

echo "Evaluating $(wc -l < "$HERE/predictions.jsonl") predictions (run_id=$RUN_ID)..."
"$PY" -m swebench.harness.run_evaluation \
    --dataset_name princeton-nlp/SWE-bench_Verified \
    --predictions_path "$HERE/predictions.jsonl" \
    --max_workers 4 \
    --run_id "$RUN_ID" \
    --cache_level instance

echo ""
echo "Done. Report: $HERE/${RUN_ID}.*.json (resolved / unresolved counts)"
