# Sprint v10-05 Retrospective: Honest Cleanup

**Date**: 2026-05-01
**Velocity**: 8/8 (100%)
**PRs**: #81, #82, #83, #84

## What went well

1. **Clean decomposition**: on-stop.sh split into 5 modules without breaking any
   existing tests. The key insight was using python heredocs with `sys.argv` instead
   of bash variable interpolation to avoid regex escaping nightmares.

2. **Aggressive cleanup**: removed 18 shim files, 3 archived agents, tinman-heartbeat,
   sprint-tracker skill -- total of ~700 lines of dead code removed.

3. **ADR-008 honesty**: documenting Nick Fury as persona overlay (not daemon) resolves
   a fundamental architectural fiction that has been confusing since v8.

4. **Test relocation**: moving 30 test files to tests/ creates a clear separation of
   concerns. The test runner seamlessly works from the new location.

## What could improve

1. **settings.json edit**: the guard-write hook correctly blocked mid-session edits to
   settings.json, but this means the `Bash(./tests/*)` allowlist entry needs a manual
   human step. Future sprints should either: (a) add settings.json to the maintainer-mode
   allowlist, or (b) make the install script handle this during aegis-upgrade.

2. **Flaky brain-adversarial test**: the concurrent append test (scenario F) intermittently
   fails in suite but passes standalone. This is a pre-existing race condition that should
   be investigated in a future sprint.

## Action items

- [ ] Human: add `"Bash(./tests/*)"` to settings.json allow list
- [ ] Future: investigate brain-adversarial flaky test (race condition in concurrent append)
- [ ] Future: update install.sh to add tests/ allowlist entry for consumer projects
