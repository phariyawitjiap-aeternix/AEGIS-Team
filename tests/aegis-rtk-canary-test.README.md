# RTK Canary Test — What to Check When RTK Arrives

## Purpose

`aegis-rtk-canary-test.sh` is a dormant test scaffold that validates RTK (Rust
Token Killer) does not cause signal loss in AEGIS tool output. It skips cleanly
on systems where `rtk` is not installed (exit 0 + SKIP message).

## When to Run

1. After installing RTK for the first time
2. After any RTK version upgrade
3. As part of the v10-03 ADOPT gate (all 5 conditions must pass)

## What It Tests

| Test | What | Pass Criteria |
|------|------|--------------|
| 1 | Error count preservation | 47 errors in = 47 errors out |
| 2 | Git diff byte-exact recovery | Tee file matches original input byte-for-byte |
| 3 | JSON structure preservation | JSON remains parseable, key fields intact |

## What Signal Loss Means

If any test FAILs, RTK is compressing away information that AEGIS hooks and
quality gates depend on. Specific consequences:

- **Test 1 fail**: Post-tool-use hook may undercount errors, leading to false
  TEST_PASS entries in activity.log
- **Test 2 fail**: Code review (Black Panther) may see truncated diffs, missing
  context for security-sensitive changes
- **Test 3 fail**: Token profiling (aegis-token-profile.sh) may receive
  corrupted JSON, breaking aggregation math

## Tee Directory

RTK stores uncompressed originals in `~/.local/share/rtk/tee/`. Test 2 verifies
this recovery path works. If RTK changes the tee location, update the `TEE_DIR`
variable in the test script.

## Prerequisites for v10-03 ADOPT Gate

All 5 conditions (from ADR-007) must pass:

1. aegis-rtk-canary-test.sh: 3/3 PASS
2. Token profile data from 3+ real sessions (Story A measurement)
3. Upstream issue #427 resolved (Story B watcher reports state=closed)
4. RTK version pinned in configuration (no auto-update)
5. Passthrough allowlist validated for gate-critical commands

## Sprint

Created in sprint-v10-02 / Story D (1pt).
