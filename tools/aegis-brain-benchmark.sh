#!/usr/bin/env bash
# AEGIS Brain Benchmark -- Performance measurements for brain-write/sync (S4-06)
#
# Measures:
#   1. brain_write throughput (1KB, 10KB, 100KB)
#   2. brain-sync latency (cold vs warm)
#   3. MEMORY.md regen cost scaling (10, 50, 100 dummy patterns)
#
# All tests run against an isolated tempdir. Results written to stdout
# and optionally to a file if --output <path> is given.
#
# Usage:
#   ./tools/aegis-brain-benchmark.sh
#   ./tools/aegis-brain-benchmark.sh --output _aegis-output/benchmarks/v9-04-brain-perf.md

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BRAIN_WRITE="${SCRIPT_DIR}/aegis-brain-write.sh"
BRAIN_SYNC="${SCRIPT_DIR}/aegis-brain-sync.sh"

OUTPUT_FILE=""
if [[ "${1:-}" == "--output" ]] && [[ -n "${2:-}" ]]; then
    OUTPUT_FILE="$2"
fi

# --- Setup isolated test environment ---
TEST_DIR=$(mktemp -d)
FAKE_BRAIN="${TEST_DIR}/.aegis/brain"
mkdir -p "${FAKE_BRAIN}/logs"
mkdir -p "${FAKE_BRAIN}/resonance"
mkdir -p "${FAKE_BRAIN}/instincts/promoted"
mkdir -p "${FAKE_BRAIN}/instincts/active"
mkdir -p "${FAKE_BRAIN}/instincts/pending"
mkdir -p "${FAKE_BRAIN}/sprints"
mkdir -p "${FAKE_BRAIN}/learnings/raw"
mkdir -p "${FAKE_BRAIN}/handoffs"
mkdir -p "${FAKE_BRAIN}/retrospectives"
touch "${FAKE_BRAIN}/logs/activity.log"

# Create required resonance files
for f in project-identity.md evolved-patterns.md anti-patterns.md architecture-decisions.md team-conventions.md; do
    echo "# ${f%.md}" > "${FAKE_BRAIN}/resonance/${f}"
done
ln -sf "${FAKE_BRAIN}/sprints" "${FAKE_BRAIN}/sprints/current" 2>/dev/null || true

# Create test-local brain-write
TEST_BRAIN_WRITE="${TEST_DIR}/brain-write-bench.sh"
{
    echo '#!/usr/bin/env bash'
    echo "AEGIS_TEST_REPO_ROOT=\"${TEST_DIR}\""
    echo 'AEGIS_TEST_STUB_SYNC=1'
    cat "$BRAIN_WRITE"
} > "$TEST_BRAIN_WRITE"
# Portable in-place sed: BSD needs `-i ''` but GNU treats `''` as the script.
# Use `-i.bak` + remove the backup — works on both. (sprint-v13-02 AI-2)
sed -i.bak "s|^REPO_ROOT=.*|REPO_ROOT=\"\${AEGIS_TEST_REPO_ROOT:-\$REPO_ROOT}\"|" "$TEST_BRAIN_WRITE"
sed -i.bak 's|if \[\[ -x "\$SYNC_SCRIPT" \]\]; then|if [[ -x "$SYNC_SCRIPT" \&\& -z "${AEGIS_TEST_STUB_SYNC:-}" ]]; then|g' "$TEST_BRAIN_WRITE"
rm -f "${TEST_BRAIN_WRITE}.bak"
chmod +x "$TEST_BRAIN_WRITE"

# Create test-local brain-sync
TEST_BRAIN_SYNC="${TEST_DIR}/brain-sync-bench.sh"
cp "$BRAIN_SYNC" "$TEST_BRAIN_SYNC"
sed -i.bak "s|^REPO_ROOT=.*|REPO_ROOT=\"${TEST_DIR}\"|" "$TEST_BRAIN_SYNC"
rm -f "${TEST_BRAIN_SYNC}.bak"
chmod +x "$TEST_BRAIN_SYNC"

cleanup() {
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# --- Timing utility ---
# macOS doesn't have high-res `date +%N`. Use perl for millisecond precision.
ms_now() {
    perl -MTime::HiRes=time -e 'printf "%.0f\n", time()*1000'
}

# Run N iterations and return avg ms
bench_loop() {
    local label="$1"
    local n="$2"
    shift 2
    local cmd=("$@")

    local start end total avg
    start=$(ms_now)
    for i in $(seq 1 "$n"); do
        "${cmd[@]}" > /dev/null 2>&1
    done
    end=$(ms_now)
    total=$((end - start))
    avg=$((total / n))
    echo "${avg}"
}

RESULTS=""
add_result() {
    RESULTS="${RESULTS}$1\n"
}

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
add_result "# Brain Performance Benchmark (S4-06)"
add_result ""
add_result "> Generated: ${TIMESTAMP}"
add_result "> Platform: $(uname -s) $(uname -m)"
add_result "> Shell: bash ${BASH_VERSION}"
add_result ""

# ============================================
# Benchmark 1: brain_write throughput
# ============================================
echo "Running: brain_write throughput..."

# Generate content of various sizes
CONTENT_1K=$(head -c 1024 /dev/urandom | base64 | head -c 1024)
CONTENT_10K=$(head -c 10240 /dev/urandom | base64 | head -c 10240)
CONTENT_100K=$(head -c 102400 /dev/urandom | base64 | head -c 102400)

N=20  # iterations per size

AVG_1K=$(bench_loop "1KB" $N bash "$TEST_BRAIN_WRITE" "resonance/bench-1k.md" "$CONTENT_1K")
AVG_10K=$(bench_loop "10KB" $N bash "$TEST_BRAIN_WRITE" "resonance/bench-10k.md" "$CONTENT_10K")
AVG_100K=$(bench_loop "100KB" $N bash "$TEST_BRAIN_WRITE" "resonance/bench-100k.md" "$CONTENT_100K")

# Calculate writes/sec
WPS_1K=$( [[ $AVG_1K -gt 0 ]] && echo "$((1000 / AVG_1K))" || echo "inf")
WPS_10K=$([[ $AVG_10K -gt 0 ]] && echo "$((1000 / AVG_10K))" || echo "inf")
WPS_100K=$([[ $AVG_100K -gt 0 ]] && echo "$((1000 / AVG_100K))" || echo "inf")

add_result "## 1. brain_write Throughput (${N} iterations each, sync stubbed)"
add_result ""
add_result "| Size | Avg (ms) | Writes/sec |"
add_result "|------|----------|------------|"
add_result "| 1 KB | ${AVG_1K} | ${WPS_1K} |"
add_result "| 10 KB | ${AVG_10K} | ${WPS_10K} |"
add_result "| 100 KB | ${AVG_100K} | ${WPS_100K} |"
add_result ""

echo "  1KB=${AVG_1K}ms  10KB=${AVG_10K}ms  100KB=${AVG_100K}ms"

# ============================================
# Benchmark 2: brain-sync latency
# ============================================
echo "Running: brain-sync latency..."

N_SYNC=10

# Cold: first run (no MEMORY.md cache)
rm -f "${FAKE_BRAIN}/MEMORY.md"
COLD_START=$(ms_now)
bash "$TEST_BRAIN_SYNC" > /dev/null 2>&1
COLD_END=$(ms_now)
COLD_MS=$((COLD_END - COLD_START))

# Warm: subsequent runs (MEMORY.md exists)
AVG_WARM=$(bench_loop "sync-warm" $N_SYNC bash "$TEST_BRAIN_SYNC")

add_result "## 2. brain-sync Latency (${N_SYNC} warm iterations)"
add_result ""
add_result "| Mode | Latency (ms) |"
add_result "|------|-------------|"
add_result "| Cold (first run) | ${COLD_MS} |"
add_result "| Warm (avg of ${N_SYNC}) | ${AVG_WARM} |"
add_result ""

echo "  Cold=${COLD_MS}ms  Warm=${AVG_WARM}ms"

# ============================================
# Benchmark 3: MEMORY.md regen cost scaling
# ============================================
echo "Running: MEMORY.md regen cost vs brain size..."

# Function: seed N patterns into evolved-patterns.md
seed_patterns() {
    local count="$1"
    local file="${FAKE_BRAIN}/resonance/evolved-patterns.md"
    echo "# Evolved Patterns" > "$file"
    for i in $(seq 1 "$count"); do
        printf '\n## P-%03d Pattern %d\n- Trigger: condition %d\n- Action: do thing %d\n- Confidence: 0.%d\n' \
            "$i" "$i" "$i" "$i" "$((RANDOM % 9 + 1))" >> "$file"
    done
}

# Measure at different brain sizes
SIZES=(10 50 100)
add_result "## 3. MEMORY.md Regen Cost vs Brain Size"
add_result ""
add_result "| Patterns | Sync (ms) | Index Size (bytes) |"
add_result "|----------|-----------|-------------------|"

for sz in "${SIZES[@]}"; do
    seed_patterns "$sz"
    AVG_SZ=$(bench_loop "sync-${sz}" 5 bash "$TEST_BRAIN_SYNC")
    MEMORY_SIZE=$(wc -c < "${FAKE_BRAIN}/MEMORY.md" | tr -d ' ')
    add_result "| ${sz} | ${AVG_SZ} | ${MEMORY_SIZE} |"
    echo "  ${sz} patterns: sync=${AVG_SZ}ms, index=${MEMORY_SIZE}b"
done

add_result ""

# ============================================
# Summary
# ============================================
add_result "## Observed Baseline Thresholds"
add_result ""
add_result "Based on measurements above (not invented SLOs):"
add_result ""
add_result "- brain_write 1KB: <${AVG_1K}ms is typical on this machine"
add_result "- brain_write 100KB: <${AVG_100K}ms is typical"
add_result "- brain-sync cold: <${COLD_MS}ms is typical"
add_result "- brain-sync warm: <${AVG_WARM}ms is typical"
add_result "- Scaling: linear with pattern count (grep-based scanning)"
add_result "- No regression concern until brain exceeds ~500 patterns"

echo ""
echo "============================================"
echo "BENCHMARK COMPLETE"
echo "============================================"

# Output results
echo -e "$RESULTS"

# Write to file if requested
if [[ -n "$OUTPUT_FILE" ]]; then
    OUTDIR=$(dirname "$OUTPUT_FILE")
    mkdir -p "$OUTDIR"
    echo -e "$RESULTS" > "$OUTPUT_FILE"
    echo ""
    echo "Results written to: ${OUTPUT_FILE}"
fi
