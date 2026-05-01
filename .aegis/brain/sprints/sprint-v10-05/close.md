# Sprint v10-05 Close: Honest Cleanup

**Closed**: 2026-05-01
**Velocity**: 8/8 pts (100%)
**PRs**: #81, #82, #83, #84

## Delivered

1. **A+B (2pt)**: Removed 18 deprecated command shims, 3 archived agent files,
   sprint-tracker from skill catalog. Updated CLAUDE.md, command-chain.md,
   CLAUDE_skills.md, aegis-sprint.md. Test updated to verify removal (8/8 PASS).

2. **C (1pt)**: Added ADR-008 documenting Nick Fury as persona overlay (not daemon).
   Removed tinman-heartbeat.sh. Updated 9 files to remove all heartbeat.log references.
   Replaced with natural "no recent Agent dispatch" fallback pattern.

3. **D (3pt)**: Decomposed on-stop.sh from 375-line monolith into 60-line orchestrator
   + 4 modules (quality-check.sh, mbp-scan.sh, false-ready.sh, queue-banner.sh).
   Fixed regex escaping for heredoc-safe python. All 7 MBP tests + 76 full suite pass.

4. **E (2pt)**: Created tests/ directory, moved 30 test files + harness from tools/.
   Created scripts/ for one-time migration tools. Updated test runner to scan tests/.
   Note: settings.json needs manual Bash(./tests/*) addition.

## Learnings

- **Heredoc python regex**: when moving python code from bash-interpolated strings to
  heredocs, backslash escaping changes. Use `\x27` for single quotes, `sys.argv` instead
  of `$VAR` interpolation. This was the only regression caught during decomposition.

- **Guard-write is correct**: it properly blocked settings.json edits mid-session.
  Framework self-protection works as designed. The manual step is documented in the PR.

- **Flaky test detection**: brain-adversarial test intermittently fails in suite but
  passes standalone (race condition in concurrent append scenario). Pre-existing, not
  introduced by this sprint.

## Carry-over
None. All 8pt delivered.

## Manual step for human
Add `"Bash(./tests/*)"` to `.claude/settings.json` allow list (after the `"Bash(./tools/*)"` line).
