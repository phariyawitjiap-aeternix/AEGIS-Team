# Sprint v15-13 Close — install-remote.sh glob+pipefail silent-exit fix

**Status**: CLOSED (100%)
**Date**: 2026-05-18
**Driver**: User reproduction on Contra-Thai install
**Branch**: `claude/sprint-v15-13-install-glob-fix`

## What shipped

6 count-pipeline patterns now use `|| echo 0` fallback so failure of the
upstream `ls glob` doesn't propagate non-zero exit through `pipefail`
and trigger `set -e` script abort:

- `install-remote.sh`: AGENT_COUNT, ARCHIVED_COUNT, HOOK_COUNT, TOOL_COUNT, SKILL_COUNT
- `install.sh`: skill_count

## Reproduction (before fix)

```
$ bash /tmp/aegis.sh --profile full --project-name "Contra Thai"
# ... banner + dependency checks + Core docs installed ...
[OK] Core docs + VERSION file installed
# [script exits silently — no error, no completion]
```

`bash -x` trace showed exit at:
```
+ ARCHIVED_COUNT=0
# [no further commands traced]
```

## Verification

```
$ bash install-remote.sh --profile minimal --project-name "Smoke"
# ... full install ...
  Profile:   minimal
  Project:   Smoke
  Agents:    11 Marvel characters
  Skills:    7
  Commands:  16
[0;36mHappy building! — AEGIS v15.0[0m
```

## Lessons

- **`set -e` + `pipefail` + `ls glob` is a footgun** — bash 5+
  behavior propagates the glob's exit code through `$(...)` assignment.
  Any future glob-counting pattern needs the `|| echo 0` (or alternative)
  fallback.
- **Silent failures are the worst class** — the user spent multiple
  cycles debugging because no error message hit the terminal.
  `2>/dev/null` masked the diagnostic.
- **Follow-up for v15-14**: add a `tests/aegis-install-script-lint.sh`
  that scans for the unguarded pattern and fails the suite if any new
  count-pipelines slip in. Defense-in-depth.

## Roadmap impact

v15 net: 35pt → 37pt.

## Immediate impact for user

After this merges, Contra-Thai install will work end-to-end. User can
re-download `/tmp/aegis.sh` and rerun the original command without
the workaround patch.
